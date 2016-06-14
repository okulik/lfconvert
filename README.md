# lfconvert

lfconvert is a tool that extracts daily exchange rates for converting US Dollars to Euros. It does this by downloading rates from remote endpoint and caching them on a disk for offline access.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lfconvert', git: 'https://github.com/okulik/lfconvert.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install specific_install && gem specific_install https://github.com/okulik/lfconvert.git

## Usage

Two required parameters are -a <USD amount> which represent USD amount we want to convert to EUR and -d <rate date> i.e. date of the exchange rate. Note that the ECB file only includes days when they had agreed on the exchange rates ­(these are typically non­-holiday weekdays). To convert values on weekends and holidays we use the previously available exchange rate.

```
Usage: lfconvert -a <USD amount> -d <rate date> [options]
    -a, --amount AMOUNT              Use specific USD amount
    -d, --rate-date DATE             Use specific exchange rate's date
    -b, --batch DATA                 Convert all given amount/date pairs
    -p, --precision [PRECISION]      Use specific numeric precision for currency
    -f, --force-update               Force update of cached ECB rates file
    -v, --verbose                    Display verbose conversion results
    -h, --help                       Show this message
```

Here's a typical first-time usage:
```sh
lfconvert -a 123.45 -d 2016-05-31 -p 2
```

If we have a rather old exchange rates file, we might need to update it using the force switch:
```sh
lfconvert -a 123.45 -d 2016-05-31 -p 2 -f
```

When converting a batch of amounts for different exchange rates:
```sh
lfconvert -b "2016-05-20,1.0|2016-05-19,2.0"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/okulik/lfconvert.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

