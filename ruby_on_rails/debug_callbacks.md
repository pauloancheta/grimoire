# Ruby on Rails: Debug Callbacks

List all callbacks that will occur.

```ruby
class User < ApplicationRecord; end

User._validation_callbacks
User._save_callbacks
User._destroy_callbacks
User._commit_callbacks
```
