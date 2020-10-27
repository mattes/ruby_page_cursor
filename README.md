# page_cursor

Cursor-based pagination for Rails.

```ruby
gem 'page_cursor'
```

## Usage

```ruby
@cursor, @records = paginate(User.where(active: true)) # in controller

<%= pagination_nav @cursor %> # in view
```

Please note that you'll have to create the `pagination_nav` helper yourself. Have a look
at an [example helper](test/dummy/app/helpers/application_helper.rb) with its rendered
[example partial](test/dummy/app/views/layouts/_pagination_nav.html.erb).

