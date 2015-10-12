# README #

## description
this application manage passwords interactive for mac commandline.  

```
------------------------------------------
commend : short : future
------------------------------------------
create  :   c   : create new service
update  :   u   : update service
delete  :   d   : delete service
all     :   a   : display all servise
list    :   l   : display all servise name
one     :   o   : display one servise
user    :   s   : copy servise user
pass    :   p   : copy servise password
url     :   r   : copy servise url
help    :   h   : display help
bye     :   b   : finish this app
------------------------------------------
```

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
