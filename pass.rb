#!/usr/bin/ruby

require 'active_record'
require 'openssl'
require 'base64'
require 'io/console'
require 'pry'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: './database/passwords.sqlite'
)

class Service < ActiveRecord::Base
  self.table_name = 'services'
end

class Account < ActiveRecord::Base
  self.table_name = 'account'

  def pass_certify?(pass)
    pass == decrypt(name, password)
  end
end

def encrypt(salt, password)
  enc = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
  enc.encrypt
  enc.pkcs5_keyivgen(salt)
  return Base64.encode64(enc.update(password) + enc.final).encode('utf-8')
end

def decrypt(salt, password)
  dec = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
  dec.decrypt
  dec.pkcs5_keyivgen(salt)
  return dec.update(Base64.decode64(password.encode('ascii-8bit'))) + dec.final
end

def confirm(string)
  print string + '? y/n '
  gets.chomp
end

def input_name
  print 'input servise name: '
  name = gets.chomp
  raise if  confirm(name) != 'y'
  name
rescue
  retry
end

def input_user
  print 'input user: '
  user = gets.chomp
  raise if confirm(user) != 'y'
  user
rescue
  retry
end

def input_url
  print 'input url: '
  url = gets.chomp
  raise if confirm(url) != 'y'
  url
rescue
  retry
end

def input_comment
  print 'input comment: '
  comment = gets.chomp
  raise if confirm(comment) != 'y'
  comment
rescue
  retry
end

def input_password
  print 'input password: '
  password = gets
  print 'confirm password: '
  raise if (password != gets)
  password.chomp
rescue
  retry
end

def copy_user
  print 'input service name: '
  name = gets.chomp
  service = Service.find_by(name: name)
  raise unless service
  system("echo -n '#{service.user}' | pbcopy")
  puts "success copy #{service.name} user!"
rescue
  retry
end

def copy_pass
  print 'input service name: '
  name = gets.chomp
  service = Service.find_by(name: name)
  raise unless service
  system("echo -n '#{decrypt(account.salt, service.password)}' | pbcopy")
  puts "success copy #{service.name} password!"
rescue
  retry
end

def exec_mode?
  put_strong_line
  puts 'Please input exec mode'
  puts 'create    : create new service'
  puts 'all       : display all servise'
  puts 'list      : display all servise name'
  puts 'user      : copy servise user'
  puts 'pass      : copy servise password'
  puts 'input any : finish this app'
  put_strong_line
  exec(gets.chomp)
end

def create
  name = input_name
  user = input_user
  password = input_password
  url = input_url
  comment = input_comment
  service = Service.new(name: name,
                     user: user,
                     password: encrypt(account.salt, password),
                     url: url,
                     comment: comment)
  if service.save
    puts 'Saving new servise'
  else
    puts 'Error save to servise'
  end
end

def all
  put_strong_line
  put_line
  Service.all.each do |s|
    result = "name: #{s.name}\n"\
             "user: #{s.user}\n"\
             "password: #{decrypt(account.salt, s.password.chomp)}\n"
             "url: #{s.url}\n"\
             "comment: #{s.comment}\n"
    print result
    put_line
  end
  put_strong_line
end

def list 
  put_line
  Service.all.each do |s|
    puts "name: #{s.name}"
  end
  put_line
end

def put_line
  puts '--------------------'
end

def put_strong_line
  puts '===================='
end

def create_account
  puts 'Please create account'
  print 'input name: '
  name = gets
  print 'input password: '
  pass = STDIN.noecho(&:gets)
  print 'confirm password: '
  return false if (pass != STDIN.noecho(&:gets))
  acc = Account.new(name: name,
                    password: encrypt(name, pass),
                    salt: encrypt(pass, pass))
  if acc.save
    puts 'Saving account'
  else
    puts 'Error save to account'
  end
end

def account
  @account ||= Account.first
end

def check_account
  if account.blank?
    create_account
  else
    if @pass_try_count >= 3
      puts 'Fail time is over 3. Please try app from first. bye!'
      exit
    end
    puts 'Please input password'
    pass = STDIN.noecho(&:gets)
    unless account.pass_certify?(pass)
      puts 'Unfortunately not match password. please retry'
      raise
    end
  end
rescue
  @pass_try_count += 1
  retry
end

def continue?
  print 'continue? y/n : '
  if gets.chomp == 'y'
    exec_mode?
  else
    puts 'bye!'
  end
end

def exec(mode)
  case mode
  when /create/
    create
  when /all/
    all
    continue?
  when /list/
    list
    continue?
  when /user/
    copy_user
    continue?
  when /pass/
    copy_pass
    continue?
  else
    puts 'bye!'
  end
  rescue => e
  puts e
  puts 'error'
end

if __FILE__ == $0
  @pass_try_count = 0
  check_account
  exec_mode?
end
