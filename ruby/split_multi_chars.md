# Ruby: Split Multi Chars

Using regex, it's possible to split a string using multiple characters

```ruby
uri = "postgres://user:password@host:5432/postgres"
user, pass, host, port, db = uri.gsub("postgres://", "").split(%r([@:/]))

user #=> "user"
pass #=> "password"
host #=> "host"
port #=> "5432"
db #=> "postgres"
```
