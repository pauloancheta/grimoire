# Ruby on Rails: dead_code

Sometimes it is very difficult to see if a method is still active. The best solution I have
encountered was to use a helper method that can be sprinkled around.

```ruby
class NotDeadError < StandardError; end

def dead_code!(msg=nil)
  msg ||= caller.find { |s| s.include? Rails.root.to_s }.try(:gsub, Rails.root.to_s, '')
  raise NotDeadError, msg

rescue NotDeadCodeYetError => e
  raise e if Rails.env.development?
  ErrorNotifier.send_error(e)
end
```

When application runs in development, error is raised. And in production or staging environment,
send a notice to an error logging service like Rollbar or NewRelic
