# page_cursor

Cursor-based pagination for Rails.

* Does not use `OFFSET/LIMIT` queries.
* Cursors are primary keys, i.e. `{before: "<pk>", after: "<pk>"}` and are expected to be present as
  `params[:after]` and/or `params[:before]`.
  Primary keys must be unique and __sortable__.
* Multiple columns can be used for ordering (see examples below).

Works great in combination with [KSUID](https://github.com/mattes/ksuid-ruby)s as primary keys, but
any other sortable key will do.


```ruby
gem 'page_cursor'
```

## Usage

```ruby
@cursor, @users = paginate(User.where(active: true)) # in controller

<%= pagination_nav @cursor %> # in view
```

Please note that you'll have to create the `pagination_nav` helper yourself. Have a look
at an [example helper](test/dummy/app/helpers/application_helper.rb) with its rendered
[example partial](test/dummy/app/views/layouts/_pagination_nav.html.erb).

## More examples

```ruby
# Example 1
@users = User.where(active: true)
@cursor, @users = paginate(@users, limit: 25)

# Example 2
@cursor, @users = paginate(User)

# Example 3
@users = User.where(active: true)
@cursor, @users = paginate(@users, :desc) # order primary key descending (defaults to :asc)

# Example 4
@users = User.where(active: true).order(:city => :desc)
@cursor, @users = paginate(@users)

# Example 5
@users = User.where(active: true).order(:lastname => :asc, :firstname => :asc, :city => :desc)
@cursor, @users = paginate(@users, :desc) # :desc orders primary key descending

# Example 6 - change position of primary key in sort order
@users = User.where(active: true).order(:city => :asc, :id => :desc, :city => :asc)
@cursor, @users = paginate(@users)

# Example 7
@cursor, @users = paginate(User, primary_key: "custom")
```

