# Vineti::Notifications
Short description and motivation.

## Usage
How to use my plugin.


Using the `Vineti::Notifications::Publish` API for internal services

`Vineti::Notifications::Publish.to_event(event_name, publish_type, event_data)`

`event_name` passed will create or fetch the existing notification event from DB

`publish_type` can be of 3 types: 
1. virtual_topic
2. topic
3. queue

`event_data` is not expecting a fixed structure
for eg:
```ruby
{
  tempelate: "some_data",
  metadata: "some_other_data",
}
```

We have the options for header and persist_transaction here as well.
## Installation
Add this line to your application's Gemfile:

```ruby
gem 'vineti-notifications', git: 'git@github.com:vinetiworks/vineti-events-service.git', tag: 'v1.0.0'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install vineti-notifications
```

## Contributing

### Install

From the `vineti-notifications` directory run `bundle`

```bash
bundle
```

#### Setup ActiveMQ

ActiveMQ is required to run the Vineti::Notifications app, you can install it using Homebrew or package manager of your choice:

```bash
brew install activemq
# Make sure it is running before setting up/running Platform app
brew services start activemq
```

### Test

`rspec` is the default `rake` task.

```bash
rake
```
