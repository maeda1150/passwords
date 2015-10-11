# README #

## description
this application manage passwords interactive for mac commandline.  
1. create login account(input name and password).  
2. create new service with name, user, password, url, comment.  
3. display registered password list.  
4. copy user or password or url.  

all data is saved in `database/passwords.sqlite`.  
of cource password data is encrypted.

## need
ruby, bundler, pbcopy

## usage
install gem list
```
bundle install
```
* if you don't install `bundler`, input this. `gem install bundler`

create database
```
bundle exec rake db:migrate
```

use application
```
ruby pass.rb
```

## how to delete application
just do this.
```
rm -rf passwords
```

delete only data.  
```
rm -rf database
```

## reference
http://biwakonbu.com/?p=188

thanks!
