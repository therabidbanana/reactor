# Reactor Change Log

0.11.1
-----------
Bug fix for namespaced Subscribable objects

0.11.0
-----------
Static Subscriber class names have changed to be more deterministic. THIS _MAY BE_ A BREAKING CHANGE.
See https://github.com/hired/reactor/issues/40 for background info.

Previously, when you added an `on_event :foo` block to an object, say `MyObject`, Reactor would dynamically generate a Sidekiq worker class named `Reactor::StaticSubscribers::FooHandler0`.

In 0.11.0, the naming of this dynamically generated worker class has changed to `Reactor::StaticSubscribers::MyObject::FooHandler`.
If you require more than one `on_event` block for the same event, you must name the handler so that it is unique and deterministic: i.e. `on_event :foo, handler_name: :do_better` otherwise an exception will be raised at load time.
This example would generate a `Reactor::StaticSubscribers::MyObject::DoBetter` class for the worker.

Because the worker class names are changing, when deploying this change it's important that your Sidekiq queue not have any pending jobs with the old naming scheme, otherwise they will fail to deserialize!
