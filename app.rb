# app.rb
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'active_record'
require 'erb'
# Load configuration file
config_path = File.expand_path('../config.yml', __FILE__)
config = YAML.load_file(config_path)
# Set up database
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'blog.db'
)

# Create articles table
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE articles (
    id TEXT PRIMARY KEY,
    title TEXT,
    content TEXT,
    date_published DATETIME
  );
SQL

# Define Article model
class Article < ActiveRecord::Base
end

# Set up session
use Rack::Session::Cookie, secret: '8b575142db8f2b0a6330fe09e723d507725aa25e640397c786acc0f57f6b65ec95f96ff37bc63f1f1d074bec8f916f3be9505337c9f4ada9ec60f1e7844a5c3aaa13a2642e640e58a015e23786c5033f55a4250ac37feff50c779eba33050dce194528e7100e0502583175aa56fca88e636eb5f24df66e20d0cc4d42431e502a'

# Basic Authentication
USERNAME = config['admin']['username']
PASSWORD = config['admin']['password']

helpers do
  def authenticated?
    session[:admin]
  end

  def login_required
    redirect '/login' unless authenticated?
  end
end

# Routes

set :views, 'views'
set :layout, :layout

# Home page - list of articles
get '/' do
  @articles = Article.all
  erb :index
end

# Article page
get '/article/:id' do
  @article = Article.find(params[:id])
  erb :article
end

# Admin dashboard
get '/admin' do
  login_required
  @articles = Article.all
  erb :admin
end

# Add new article
get '/admin/new' do
  login_required
  erb :new_article
end

post '/admin/new' do
  login_required
  article = Article.new(
    id: SecureRandom.uuid,
    title: params[:title],
    content: params[:content],
    date_published: Time.now
  )
  article.save
  redirect '/admin'
end

# Edit article
get '/admin/edit/:id' do
  login_required
  @article = Article.find(params[:id])
  erb :edit_article
end

post '/admin/edit/:id' do
  login_required
  article = Article.find(params[:id])
  article.title = params[:title]
  article.content = params[:content]
  article.save
  redirect '/admin'
end

# Delete article
post '/admin/delete/:id' do
  login_required
  article = Article.find(params[:id])
  article.destroy
  redirect '/admin'
end

# Login
get '/login' do
  erb :login
end

# Login route (this is where you authenticate the admin)
post '/login' do
  if params[:username] == USERNAME && params[:password] == PASSWORD
    session[:admin] = true
    redirect '/admin'
  else
    @error = "Invalid credentials"
    erb :login
  end
end

# Logout route
get '/logout' do
  session[:admin] = nil
  redirect '/'
end