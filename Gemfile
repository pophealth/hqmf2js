source "http://rubygems.org"

gem 'rails', '3.2.14'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
end

gem 'hquery-patient-api', '1.0.4'
gem 'health-data-standards', :git => 'https://github.com/projectcypress/health-data-standards.git', :branch => 'master'

gem 'nokogiri'
gem 'sprockets'
gem 'coffee-script'
gem 'uglifier'
gem 'tilt'
gem 'rake'
gem 'pry'

group :test do
  gem 'simplecov', :require => false

  gem 'minitest'
  gem 'turn', :require => false
  gem 'awesome_print', :require => 'ap'
  
  platforms :ruby do
    gem "therubyracer", :require => 'v8'
  end
  
  platforms :jruby do
    gem "therubyrhino"
  end
end
