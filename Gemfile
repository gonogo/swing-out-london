source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.1.8'

gem 'jquery-rails'

gem 'twitter'

gem 'geokit'

# Hosting on heroku
gem 'heroku'
gem 'taps'

#Caching
gem 'memcachier'
gem 'dalli'
gem 'api_cache'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

# To use debugger
# gem 'ruby-debug'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'awesome_print'
  gem 'pry'
  #gem 'webrat'
  gem 'rspec-rails'
  gem 'spork'
  gem 'factory_girl_rails', '~> 1.2'
  gem 'rb-fsevent'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'guard-livereload'
end

group :production do
  gem 'pg'
  gem 'thin'
  gem 'newrelic_rpm'
end
