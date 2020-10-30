module PageCursor
  module ActionControllerExtension
    # paginate returns a cursor-enabled pagination.
    # It uses params[:after] and params[:before] request variables.
    # It assumes @record's primary key is sortable.
    #
    # opts[:primary_key] = string
    # opts[:limit] = n
    def paginate(c, direction = nil, **opts)
      opts.symbolize_keys!
      limit = opts[:limit]&.to_i || 10

      raise ArgumentError, "direction must be either nil, :asc or :desc" unless [nil, :asc, :desc].include?(direction)
      raise ArgumentError, "limit must be >= 1" unless limit >= 1
      raise ArgumentError, "only provide one, either params[:after] or params[:before]" if params[:after].present? && params[:before].present?

      # make sure we have a primary key
      pk_name = (opts[:primary_key] || c.primary_key).to_s
      if !c.column_names.include?(pk_name)
        if opts[:primary_key].present?
          raise ArgumentError, "column '#{opts[:primary_key]}' does not exist in table '#{c.table_name}'"
        else
          raise "table '#{c.table_name}' has no primary key"
        end
      end

      # reference the table's primary key
      pk = c.arel_table[pk_name]
      raise ArgumentError, "expect primary key to be Arel::Attributes:Attribute instead of #{pk.class}" unless pk.is_a?(Arel::Attributes::Attribute)

      # set cursor to :after/:before and the according pk_value from the params
      cursor = nil
      pk_value = nil
      if params[:after].present?
        cursor = :after
        pk_value = params[:after]
      elsif params[:before].present?
        cursor = :before
        pk_value = params[:before]
      end

      # always fetch limit + 1 to see if there are more records
      c = c.limit(limit + 1)

      all = []

      # check if c already has one or more order directives set
      unless already_has_order?(c)
        # easy, no existing order directives, we'll just order by our primary key
        comparison, order, reverse = ordering(direction || :asc, cursor)
        c = c.where(pk.send(comparison, pk_value)) if comparison
        c = c.reorder(pk.send(order)).all
        c = c.reverse if reverse
        all = c.to_a
      else
        # collection has order directives, we need to do a bit more work ...

        # replace existing order with new one
        c = reorder(c, cursor, pk, direction || :asc)

        # if a cursor is given, we need to fetch its row from the database
        # so that we can use the row's values for our where conditions.
        unless cursor.nil?
          row = find!(c, pk_name, pk_value)
          c = where(c, cursor, row)
        end

        all = c.all.to_a
        all = all.reverse if cursor == :before
      end

      has_more = all.size <= limit ? false : true

      # return new after/before cursor and all results if there are no more results to expect after this
      unless has_more
        if cursor.nil?
          return { :after => nil, :before => nil }, all # first and only page, no afters/befores
        elsif cursor == :after
          return { :after => nil, :before => all.first&.read_attribute(pk_name) }, all  # last page, no afters
        elsif cursor == :before
          return { :after => all.last&.read_attribute(pk_name), :before => nil }, all  # last page, no befores
        end
      end

      # return new after/before cursors and all results if there are more results to expect
      if cursor == :before
        all = all.last(all.size - 1)
      else
        all = all.first(all.size - 1)
      end

      if cursor.nil?
        return { :after => all.last&.read_attribute(pk_name), :before => nil }, all # first page, continue after
      elsif cursor == :after
        return { :after => all.last&.read_attribute(pk_name), :before => all.first&.read_attribute(pk_name) }, all
      elsif cursor == :before
        return { :after => all.last&.read_attribute(pk_name), :before => all.first&.read_attribute(pk_name) }, all
      end

      fail "never" # safeguard if cursor has a weird value
    end

    private

    # order = :asc|:desc
    # cursor = nil|:after|:before
    # returns comparison, order, reverse
    def ordering(order, cursor)
      raise ArgumentError, "'#{order}' must be either :asc or :desc" unless [:asc, :desc].include?(order)
      raise ArgumentError, "'#{cursor}' must be either nil, :after or :before" unless [nil, :after, :before].include?(cursor)

      if order == :asc
        if cursor.nil?
          return nil, :asc, false # asc - nil
        elsif cursor == :after
          return :gt, :asc, false # asc - after
        else
          return :lt, :desc, true # asc - before
        end
      else
        if cursor.nil?
          return nil, :desc, false # desc - nil
        elsif cursor == :after
          return :lt, :desc, false # desc - after
        else
          return :gt, :asc, true # desc - before
        end
      end
    end

    # reorder applies a new ordering to the collection considering
    # the cursor's :after or :before value
    def reorder(collection, cursor, pk, pk_direction)
      x = []
      collection.order_values.each do |v|
        if cursor == :after || cursor.nil?
          x << v
        elsif cursor == :before
          x << v.reverse
        end
      end

      # also add our primary key, if it's not yet included in the existing order directives
      unless order_includes_pk?(collection, pk)
        if cursor == :after || cursor.nil?
          x << pk.send(pk_direction)
        elsif cursor == :before
          x << pk.send(pk_direction).reverse
        end
      end

      collection.reorder(x)
    end

    # where returns a where clause which finds a row in an ordered collection
    def where(collection, cursor, row)
      parts = []
      values = []

      # recursively build where query elements
      i = collection.order_values.count
      while i > 0
        i -= 1
        subparts = []

        last = collection.order_values[i]
        chain = i > 0 ? collection.order_values.first(i) : []

        # iterate through and build elements from chain
        chain.each do |v|
          table_name, col_name = extract_column(v)
          quoted_col = quote(table_name, col_name)
          subparts << "#{quoted_col} = ?"
          values << row[col_name]
        end

        # build last element
        table_name, col_name = extract_column(last)
        quoted_col = quote(table_name, col_name)
        last = last.reverse if cursor == :before # reverse the reverse from reordering
        comparison, _, _ = ordering(last.direction, cursor)
        comparison_str = comparison_to_s(comparison)
        subparts << "#{quoted_col} #{comparison_str} ?"
        values << row[col_name]

        # merge subparts into all parts
        parts << "(" + subparts.join(" AND ") + ")"
      end

      # build final where clause
      query = parts.join(" OR ")
      collection.where(values.prepend(query))
    end

    def find!(collection, pk_name, pk_value)
      collection.reorder(nil).rewhere(pk_name => pk_value).take!
    end

    def quote(table, column)
      raise ArgumentError, "column can't be blank" if column.blank?
      c = ActiveRecord::Base.connection
      if table.present?
        c.quote_table_name(table.to_s) + "." + c.quote_column_name(column.to_s)
      else
        c.quote_column_name(column.to_s)
      end
    end

    # extract_column returns table_name and column_name for order directive
    def extract_column(v)
      if v.is_a? String
        # TODO We can't reliably parse table_name and column_name from string syntax?
        raise ArgumentError, "order(string) syntax is not supported"
      end

      if v.is_a?(Arel::Nodes::Ascending) || v.is_a?(Arel::Nodes::Descending)
        val = v.value

        if val.is_a?(Arel::Nodes::NamedFunction)
          if val.expressions && val.expressions.size > 0
            raise ArgumentError, "only one expression supported for #{val.class}" if val.expressions.size > 1 # TODO can we support more?
            x = val.expressions[0]
            if x.is_a?(Arel::Attributes::Attribute)
              return x.relation.table_name.to_s, x.name.to_s
            end
          end
        end

        if val.is_a?(Arel::Attributes::Attribute)
          return val.relation.table_name.to_s, val.name.to_s
        end
      end

      raise ArgumentError, "unsupported type '#{v.class}' for order directive '#{v}'"
    end

    # order_includes_pk returns true if collection's order directives contain pk
    def order_includes_pk?(collection, pk)
      raise ArgumentError, "nil primary key" if pk == nil
      raise ArgumentError, "missing table or column name for primary key" if pk.name.blank? || pk.relation.table_name.blank?

      collection.order_values.each do |v|
        table_name, col_name = extract_column(v)
        raise ArgumentError, "unable to extract table and column name from #{v}" if table_name.blank? || col_name.blank?
        return true if col_name.to_s == pk.name.to_s && table_name.to_s == pk.relation.table_name.to_s
      end
      return false
    end

    # already_has_order? returns true if collection has order directives set already
    def already_has_order?(collection)
      return false if collection.order_values.blank?
      collection.order_values.size > 0
    end

    def comparison_to_s(comparison)
      return "<" if comparison.to_sym == :lt # less than
      return ">" if comparison.to_sym == :gt # greater than
      raise ArgumentError, "'#{comparison}' must be either :lt or :gt"
    end
  end
end
