# Ruby on Rails: find_each

When dealing with a lot of data, especially on a migration, using `each` is not very efficient
because it loads everything in memory. In order to not overload the database, use `find_each`.

For example:
```ruby
Post.where(something: "here").each do |post|
  # This is not efficient because it loads everything
end

Post.where(something: "here").find_each do |post|
  # This is better since it has 1000 limit
end
```

To edit the limit, we can pass `batch_size` to the enumerator:
```ruby
Post.where(something: "here").find_each(batch_size: 10) do |post|
  # batches request in 10's
end
```
