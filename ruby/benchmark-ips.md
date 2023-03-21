# Ruby: Benchmark-ips

My favourite benchmarking tool

```ruby
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'benchmark-ips', require: false
end

require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("action 1") { action_1! }
  x.report("action 2") { action_2! }
  x.compare!
end
```
