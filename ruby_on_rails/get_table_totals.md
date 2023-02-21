# Ruby on Rails: Get table row totals

Simple script to get the count of rows on all tables.

```ruby
ActiveRecord::Base.connection.tables.map do |t|
  { t=>  ActiveRecord::Base.connection.execute("select count(*) from #{t}").first }
end
```
