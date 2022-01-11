# Ruby on Rails: Sanitize Sql Query

It is sometimes easier (and faster) to have a SQL query instead of using active record. But
it is always important to sanitize the queries to prevent SQL injection

For example:
This is very inefficient and harder to read:
```ruby
user = User.left_outer_joins(:spouse)
           .where(first_name: params[:first_name])
           .or( User.left_outer_joins(:spouse).where(spouse { first_name: params[:first_name] }) )
           .first
```

Compared to
```ruby
query = <<~SQL
  users.first_name=:first_name OR spouse.first_name=:first_name
SQL

sanitized_query = ActiveRecord::Base.sanitize_sql([query, {fist_name: params[:first_name]}])

User.where(sanitized_query)
```

This is an oversimplification but when queries get complicated, this is pretty useful.
