# Ruby on Rails: Task vs Seed vs ServiceObject

In theory, if I want to create default data for my rails application, I could use any of these patterns.
But having context on what it does and what it best used for, in my opinion, makes a difference on
how to use these patterns

## ServiceObject
These objects should be dumb. If we follow the SOLID principle, these objects do one thing. Most
rails application that I've seen use it to create resources that are dependent from each other.
While this could be used for seeding, ServiceObjects would be better fitted to create resource or
one resource with all its dependents. For example:

```ruby
company = Company!(name: "My Company")
user = User.create!(name: "Paulo", email: "paulo@example.com", company: company)
user.send_email_notification
```

If for example our user needs a default `post`, one way we can achieve this is by creating
`after_create` actions, which could become unweildy in the future. Tests would start become slower,
it would be painful to write tests just because we have a side effect to a model. My recommendation
is to use ServiceObjects instead so that they can be tested in isolation and creating a state of the
world would be done through the objects

```ruby
company = Company!(name: "My Company")
User::Create.call(company: company, name: "Paulo", email: "paulo@example.com")

class User::Create
  def self.call(...)
    u = User.create!(...)
    u.posts.create(title: "Default Post")
    u.send_email_notification
  end
end
```

## Seed
Seeds are found in `db/seed.rb` and can be executed by running `rails db:seed`. The first rule of
seeds is that they never run in production. Second rule of seeds is that they create a state of the
world with no/minimal interaction outside your application. We don't want any business side effects
like sending email notification since we don't need it. Ideally, it doesn't hit any outside API since
that can cause our seeds to run slower. Can seeds just call service objects? Absolutely! As long as
it can be run alone with minimal setup. Remember that the intention of the seeds to is to populate
the database with dumb data that developers can use for development.

```ruby
# db/seeds.rb

# create Company
company = FactoryBot.create(:company)

# create roles
admin_role = FactoryBot.create(:role, :admin)

# create users
admin = FactoryBot.create(:user, company: company, role: admin_role)
user_1 = FactoryBot.create(user, company: company, role: :editor)
user_2 = FactoryBot.create(user, company: company, role: :viewer)

# create default posts
default_title = "Default Post"
admin.posts.create!(title: default_title)
user_1.posts.create!(title: default_title)
```

In this example, I'm using a gem called FactoryBot. It is a very powerful tool but same with models,
it is very hard to maintain when coupled with after effects like `before(:create)` or
`after(:create)`. But the problem with this is that there is no explicitness within the seed. It
has a concept of user personas but the intention is not very clear. It was merely going through the
motions of creating resources without direction.

```ruby
# create default company
company = FactoryBot.create(:company, name: "Test Company 1")
admin = FactoryBot.create(:user, company: company, role: :admin, name: "Admin", email: "admin@example.com")
user_1 = FactoryBot.create(:user, company: company, role: :editor, name: "User", email: "user_1@example.com")
user_2 = FactoryBot.create(:user, company: company, role: :viewer, name: "User", email: "user_1@example.com")

# create company with no editors or viewers
company = FactoryBot.create(:company, name: "Lonely Company")
admin = FactoryBot.create(:user, company: company, role: :admin, name: "Admin", email: "admin@example.com")

# create company with multiple admin
...
# create company with editors no viewers
...

# create default posts
...
```

## Task
When a service needs to run more than once, it is useful to create a `rake task` for them. Tasks are
ideally report it's own progress as well. For example

```ruby
task :send_email_notification do
  user_count = User.count
  User.find_each(batch_size: 100).with_index do |u, i|
    print "#{i+1}/#{user_count} Sending email notification to #{u.id} "
    u.send_email!
    puts "DONE!"
    NotificationService.call("Sent message to #{u}")
  end
end
```

### Cron
One of the patterns I've seen that is really useful handling different `rake tasks` that rely on
cron to run, is that it is namespaced through their increments:

```ruby
namespace :monthly do
  task :send_email_notification do
    user_count = User.count
    User.find_each(batch_size: 100).with_index do |u, i|
      ...
    end
  end
end

namespace :daily do
  ...
end
```

With this, it is more intuitive debugging different tasks running on different times.

### Migrations
In most cases, migrations are written in `db/migrate/` folder. These migrations are inheriting from
`ActiveRecord::Migration` and have a specific DSL. The best practice for this folder is that they
don't use any class inside the migration because by doing so, we are coupling these immutable files
to a class that should be easy to change or delete. Which is why, when migrating data, it is best
to do it as a rake task.



## Tying them all together
