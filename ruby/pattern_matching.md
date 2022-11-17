# Ruby: Pattern Matching

A useful pattern when filtering and storing variables at the same time.

```ruby
class User
  attr_reader :name, :email, :role

  def initialize(name:, email:, role:)
    @name = name
    @email = email
    @role = role
  end

  def deconstruct_keys(keys)
    {name: @name, email: @email, role: @role}
  end
end

u1 = User.new(name: 'Paulo', email: 'paulo@example.com', role: 'admin')
u2 = User.new(name: 'John', email: 'john@example.com', role: 'manager')
u3 = User.new(name: 'Jane', email: 'john@example.com', role: 'admin')

[u1, u2, u3].each do |u|
  if u in { name: n, email: e, role: 'admin' }
    puts "Name: #{n}, email: #{e}"
  end
end

```
