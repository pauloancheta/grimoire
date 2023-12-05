# Ruby: Acts Like Array

It's sometimes helpful for a class to act like an array instead of `#select` or `#find`

```ruby
class Hello
  def self.[](key)
    {first: 'one', second: 'two'}.fetch(key.to_sym)
  end
end

Hello['first'] #=> 'one'
Hello['second'] #=> 'two'
```
