source "http://rubygems.org"

gem 'rails', '>= 4.0.0'

group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
end

gem 'hquery-patient-api', :git => 'https://github.com/projecttacoma/patientapi.git', :branch => 'master'
#gem 'hquery-patient-api', :path => '../patientapi'
gem 'health-data-standards', :git => 'https://github.com/projectcypress/health-data-standards.git', :branch => 'master'
#gem 'health-data-standards', :path => '../health-data-standards'

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
