module PageCursor
  module ActionControllerExtension
    # paginate returns a cursor-enabled pagination.
    # It uses params[:after] and params[:before] request variables.
    # It assumes @record's primary key is sortable.
    #
    # Example usage:
    # ```
    # @cursor, @records = paginate(@records) # in controller
    # <%= pagination_nav @cursor %>          # in view
    # ```
    #
    # @cursor is a hash returning the next (`after`)
    # and previous (`before`) primary key, if more records are available.
    #
    # Caveat: All collection's order statements are overwritten by paginate.
    def paginate(collection, direction = :asc, **opts)
      opts.symbolize_keys!
      limit = opts[:limit] || 10

      fail "direction must be :asc or :desc" unless [:asc, :desc].include?(direction)
      fail "limit must be >= 1" unless limit >= 1

      after = params[:after]
      before = params[:before]
      fail "only provide one, either params[:after] or params[:before]" if after.present? && before.present?

      # reference the table's primary key attribute
      pk = collection.arel_table[opts[:primary_key] || collection.primary_key]

      # return limit + 1 to see if there are more records
      collection = collection.limit(limit + 1)

      if after.present?
        if direction == :asc
          collection = collection.where(pk.send("gt", after)).reorder(pk.send(:asc))
        elsif direction == :desc
          collection = collection.where(pk.send("lt", after)).reorder(pk.send(:desc))
        end
        r = collection.all

        return { :after => nil, :before => r.first&.id }, r if r.size <= limit
        r = r.first(r.size - 1)
        return { :after => r.last&.id, :before => r.first&.id }, r

        # ---
      elsif before.present?
        if direction == :asc
          collection = collection.where(pk.send("lt", before)).reorder(pk.send(:desc))
        elsif direction == :desc
          collection = collection.where(pk.send("gt", before)).reorder(pk.send(:asc))
        end
        r = collection.all.reverse

        return { :after => r.last&.id, :before => nil }, r if r.size <= limit
        r = r.last(r.size - 1)
        return { :after => r.last&.id, :before => r.first&.id }, r

        # ---
      else
        # if after and before are both missing
        r = collection.reorder(pk.send(direction)).all
        return { :after => nil, :before => nil }, r if r.size <= limit
        r = r.first(r.size - 1)
        return { :after => r.last&.id, :before => nil }, r
      end
    end
  end
end
