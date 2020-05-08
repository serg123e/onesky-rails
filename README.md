# Onesky::Rails

[![Build Status](https://travis-ci.org/onesky/onesky-rails.svg)](https://travis-ci.org/onesky/onesky-rails)

Integrate Rails app with [OneSky](http://www.oneskyapp.com) that provide `upload` and `download` rake command to sync string files

## Installation

Install a gem:

    $ gem install ./onesky-rails-1.4.1.zem.gem

Add this line to your application's Gemfile:

    gem 'onesky-rails', '1.4.1.zem'

And then execute:

    $ bundle

## Usage

**Basic setup**
```
rails generate onesky:init <api_key> <api_secret> <project_id>
```
Generate config file at `config/onesky.yml`

**Additional configuration**
In order to keep using custom locale names in your rails application, you can add something like this to your config file at `config/onesky.yml`:

```
locale_mapping:
  # rails_locale: onesky-locale
  es: es-ES
  ar: es-AR
  uk: en-GB
```

**Upload string files**
```
rake onesky:upload
```
Upload all string files of `I18n.default_locale` to [OneSky](http://www.oneskyapp.com). Note that default locale must match with base language of project.

**Download translations**
```
rake onesky:download
```
Download translations of files uploaded in all languages activated in project other than the base language.

**Download base language translations**
```
rake onesky:download_base
```
Download translations of files uploaded only for the base language.

**Download all languages translations**
```
rake onesky:download_all
```
Download translations of files uploaded for all the languages including the base language.

**Upload all languages translations**
```
rake onesky:upload_all
```
Upload all .yml files in config/locales and subdirectories.

You can filter specific files for upload in config file at `config/onesky.yml`:

```
upload:
  is_keeping_all_strings: true
  only:
    - testdir/ar.yml
    - es.yml

```

or just exclude some of them
```
upload:
  is_keeping_all_strings: true
  except:
    - devise.ec.yml
    - devise.de.yml

```


## TODO
- Specify file to upload
- Specify file and language to download
- Support different backend

## Contributing

1. Fork it ( http://github.com/onesky/onesky-rails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
