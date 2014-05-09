This software is the base package for the MicroPasts crowd-funding platform. We have cloned the Neighbor.ly platform (snapshot taken 9th May 2014) and will be working from there.

## An open source fundraising toolkit for heritage

This is the source code repository running [crowdfunded.micropasts.org](http://crowdfunded.micropasts.org). 

# Getting started

### Internationalization

This software was originally created as [Catarse](https://github.com/catarse/catarse), Brazil's first crowdfunding platform and then developed further by [Neighborly] (https://github.com/neighborly/neighborly). It was first made in Portuguese then later English support added by [Daniel Walmsley](http://purpose.com). Neighbor.ly focused on making all aspects of the interface in US English. There are still some patches of both languages throughout the software, but overall there is good infrastructure in place to internationalize to the language of your choice.

### Translations

We hope to offer many languages in the future. So if you decide to implement MicroPasts in your own language, please let us know so we can include your language here.

### Payment gateways

We are currently only going to be supporting PayPal.

## How to contribute

Thank you for your interest in helping to advance this project. We are actively working on a public roadmap. Meanwhile, please feel free to [open issues](https://github.com/micropasts/crowdfunding/issues/new) with your concerns and [fix/implement](https://github.com/micropasts/crowdfunding/issues) something using pull requests. Probably the better way to do this is commenting on the issue so we can give you the responsibility of it. This will prevent more than one person to contribute with the same change.

### Coding style

* We prefer `{foo: 'bar'}` over `{:foo => 'bar'}`
* We prefer `->(foo){ bar(foo) }` over `lambda{|foo| bar(foo) }`

### Best practices (or how to get your pull request accepted faster)

We use RSpec, Capybara and Jasmine for the tests, and the best practices are:
* Create one acceptance test for each scenario of the feature you are trying to implement.
* Create model and controller tests to keep 100% of code coverage at least in the new parts that you are writing.
* Feel free to add specs to the code that is already in the repository without the proper coverage ;)
* Try to isolate models from controllers as best as you can.
* Regard the existing tests for a style guide, we try to use implicit spec subjects and lazy evaluation as often as we can.

## Quick Installation

**IMPORTANT**: Make sure you have postgresql-contrib ([Aditional Modules](http://www.postgresql.org/docs/9.3/static/contrib.html)) installed on your system.

```bash
$ git clone https://github.com/neighborly/neighborly.git
$ cd neighborly
$ cp config/database.sample.yml config/database.yml
$ vim config/database.yml
# change username/password and save
$ bundle install
$ rake db:create db:migrate db:seed
$ rails server -p {portID} -d
```

To stop the server, search for port:

```bash
$ netstat -anp tcp | grep 3005
$ kill {proc id}
```


## Credits

Originally forked from [Catarse](https://github.com/catarse/catarse).
Adapted by [devton](https://github.com/devton), [josemarluedke](https://github.com/josemarluedke), and [luminopolis](https://github.com/luminopolis). Made possible by support from hundreds of code contributors, [financial support](http://www.knightfoundation.org/press-room/press-release/neighborly-expands-crowdfunding-service-civic-proj/) from the Knight Foundation, and lots of love & bbq sauce in downtown Kansas City, Missouri. Now being worked on by @portableant and Andrew Bevan.

## License

Copyright (c) 2012 - 2014 Neighbor.ly. Licensed as free and open source under the [MIT License](MIT-LICENSE)
