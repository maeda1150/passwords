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

# model

class Service < ActiveRecord::Base
  self.table_name = 'services'
end

class Account < ActiveRecord::Base
  self.table_name = 'account'

  def pass_certify?(pass)
    pass == decrypt(name, password)
  end
end

# view helper

def puts_line
  puts '------------------------------------------'
end

def puts_strong_line
  puts '=========================================='
end

def puts_success_line(time)
  time = time.presence || 20
  puts '#' * time
end

def puts_error_line(time)
  time = time.presence || 20
  puts '!' * time
end

def puts_warning_line(time)
  time = time.presence || 20
  puts '*' * time
end

def puts_success(message)
  success_mes = "Success : #{message}"
  puts_success_line(success_mes.length)
  puts success_mes
  puts_success_line(success_mes.length)
end

def puts_error(message)
  error_mes = "Error : #{message}"
  puts_error_line(error_mes.length)
  puts error_mes
  puts_error_line(error_mes.length)
end

def puts_warning(message)
  warning_mes = "Warning : #{message}"
  puts_warning_line(warning_mes.length)
  puts warning_mes
  puts_warning_line(warning_mes.length)
end

# form

def input(message)
  print "#{message} : "
  gets.chomp
end

def input_hide(message)
  print "#{message} : "
  result = STDIN.noecho(&:gets).chomp
  puts ''
  result
end

def input_password
  pass = input 'input password'
  confirm_pass = input 'confirm password'
  raise 'not match password. please correct password' if (pass != confirm_pass)
  pass
rescue RuntimeError => e
  puts_warning e.message
  retry
end

# controller

def check_account
  if account.blank?
    create_account
  else
    if pass_try_count >= 3
      puts_error 'fail time is over 3. please retry app from first.'
      bye
    end
    pass = input_hide 'please input password'
    unless account.pass_certify?(pass)
      raise 'unfortunately not match password. please retry'
    end
  end
rescue  RuntimeError => e
  puts e.message
  increment_pass_try_count
  retry
end

def create_account
  puts 'please create account'
  name = input 'input name'
  pass = input 'input password'
  confirm_pass = input 'confirm password'
  raise 'password is not match. please input correct password' if (pass != confirm_pass)
  acc = Account.new(name: name,
                    password: encrypt(name, pass),
                    salt: encrypt(pass, pass))
  if acc.save
    puts_success 'save account'
  else
    raise 'could not save account'
  end
rescue RuntimeError => e
  puts_warning e.message
  continue? ? retry : bye
end

def create
  params = {
    name: input('input name'),
    user: input('input user'),
    password: encrypt(account.salt, input_password),
    url: input('input url'),
    comment: input('input comment')
  }
  if Service.new(params).save
    puts_success 'save new servise'
  else
    puts_error 'can not save servise'
  end
end

def update
  service = Service.find_by(name: input('target service name'))
  raise 'nothing match data' unless service
  puts 'Please input change service params..'
  puts 'If you want to keep unchanged, just tap enter'
  name = input 'input name'
  user = input 'input user'
  i_pass = input_password
  pass = i_pass.present? ? encrypt(account.salt, i_pass) : ''
  url = input 'input url'
  comment = input 'input comment'
  params = {
    name: name.presence || service.name,
    user: user.presence || service.user,
    password: pass.presence ||  service.password,
    url: url.presence || service.url,
    comment: comment.presence || service.comment
  }
  raise 'abort update' unless are_you_sure? 
  if service.update(params)
    puts_success 'update servise'
  else
    puts_error 'could not update servise'
  end
rescue RuntimeError => e
  puts_error e.message
  retry if continue?
end

def delete
  service = Service.find_by(name: input('target service name'))
  raise 'not match data' unless service
  raise 'abort delete' unless are_you_sure? 
  service.destroy
  puts_success "delete #{service.name}"
rescue RuntimeError => e
  puts_warning e.message
  retry if continue?
end

def all
  puts_strong_line
  puts_line
  Service.all.each do |s|
    puts "name     : #{s.name}"
    puts "user     : #{s.user}"
    puts "password : #{decrypt(account.salt, s.password.chomp)}"
    puts "url      : #{s.url}"
    puts "comment  : #{s.comment}"
    puts_line
  end
  puts_strong_line
end

def list 
  puts_line
  Service.all.each do |s|
    puts "name : #{s.name}"
  end
  puts_line
end

def one
  s = Service.find_by(name: input('target service name'))
  raise 'not match data' unless s
  puts_line
  puts "name     : #{s.name}"
  puts "user     : #{s.user}"
  puts "password : #{decrypt(account.salt, s.password.chomp)}"
  puts "url      : #{s.url}"
  puts "comment  : #{s.comment}"
  puts_line
rescue RuntimeError => e
  puts_warning e.message
  retry if continue?
end

def copy(column)
  service = Service.find_by(name: input('target service name'))
  raise 'nothing match data' unless service
  if column == 'password'
    system("echo -n '#{decrypt(account.salt, service.password)}' | pbcopy")
  else
    target = eval("service.#{column}")
    system("echo -n '#{target}' | pbcopy")
  end
  puts_success "copy #{service.name} #{column}!"
rescue RuntimeError => e
  puts_warning e.message
  retry if continue?
end

def help
  puts_strong_line
  puts 'commend : short : future'
  puts_line
  puts 'create  :   c   : create new service'
  puts 'update  :   u   : update service'
  puts 'delete  :   d   : delete service'
  puts 'all     :   a   : display all servise'
  puts 'list    :   l   : display all servise name'
  puts 'one     :   o   : display one servise'
  puts 'user    :   s   : copy servise user'
  puts 'pass    :   p   : copy servise password'
  puts 'url     :   r   : copy servise url'
  puts 'help    :   h   : display help'
  puts 'bye     :   b   : finish this app'
  puts_strong_line
end

def bye
  puts 'bye!'
  exit
end

# helper methods

def encrypt(salt, password)
  enc = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
  enc.encrypt
  enc.pkcs5_keyivgen(salt)
  Base64.encode64(enc.update(password) + enc.final).encode('utf-8')
end

def decrypt(salt, password)
  dec = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
  dec.decrypt
  dec.pkcs5_keyivgen(salt)
  dec.update(Base64.decode64(password.encode('ascii-8bit'))) + dec.final
end

def choice_mode
  exec(input('input exec mode'))
end

def continue?
  input('continue? yes - tap enter : no - input any key').blank?
end

def are_you_sure?
  input('Are you sure really? y/n') == 'y'
end

def account
  @account ||= Account.first
end

def pass_try_count
  @pass_try_count ||= 0
end

def increment_pass_try_count
  @pass_try_count += 1
end

# routing

def exec(mode)
  case mode
  when 'create', 'c' then create
  when 'update', 'u' then update
  when 'all', 'a' then all
  when 'list', 'l' then list
  when 'one', 'o' then one
  when 'user', 's' then copy('user')
  when 'pass', 'p' then copy('password')
  when 'url', 'r' then copy('url')
  when 'delete', 'd' then delete
  when 'help', 'h' then help
  when 'bye', 'b' then bye
  else choice_mode
  end
  choice_mode
end

def run
  check_account
  help
  choice_mode
rescue Exception => e
  puts e.message if e.message
  exit
end

if __FILE__ == $0
  run
end
