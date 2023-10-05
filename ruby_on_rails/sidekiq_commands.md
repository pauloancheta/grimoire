# Useful Sidekiq Commands

Get (or delete) all jobs from default queue with a class name
```ruby
queue = Sidekiq::Queue.new("default")
jobs = queue.map do |job|
  if job.klass == 'Slack::NotifierJob'
    # job.delete
    {job_id: job.jid, job_klass: job.klass, arguments: job.args}
  end
end.compact
```

Delete jobs with class name from a RetrySet
```ruby
Sidekiq::RetrySet.new.select { |j| j.display_class == "Slack::NotifierJob" }.count
```

