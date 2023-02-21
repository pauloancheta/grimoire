# Ruby on Rails: Get table row totals

Simple script to get the count of rows on all tables.

```ruby
ActiveRecord::Base.connection.tables.inject({}) do |h,t|
  h[t] = ActiveRecord::Base.connection.execute("select count(*) from #{t}")[0].values.first
  h
end
```
