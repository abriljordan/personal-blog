# app.rb
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
enable :sessions

# Basic Authentication
USERNAME = 'admin'
PASSWORD = 'password'

helpers do
  def authenticated?
    session[:logged_in]
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
  @articles = Dir.glob("articles/*.json").map do |file|
    JSON.parse(File.read(file))
  end
  erb :index
end

# Article page
get '/article/:id' do
  file_path = "articles/#{params[:id]}.json"
  halt(404, "Article not found") unless File.exist?(file_path)

  @article = JSON.parse(File.read(file_path))
  erb :article
end

# Admin dashboard
get '/admin' do
  login_required
  @articles = Dir.glob("articles/*.json").map { |file| JSON.parse(File.read(file)) }
  erb :admin
end

# Add new article
get '/admin/new' do
  login_required
  erb :new_article
end

post '/admin/new' do
  login_required
  article = {
    "id" => SecureRandom.uuid,
    "title" => params[:title],
    "content" => params[:content],
    "date_published" => Time.now.to_s
  }

  File.write("articles/#{article['id']}.json", JSON.pretty_generate(article))
  redirect '/admin'
end

# Edit article
get '/admin/edit/:id' do
  login_required
  file_path = "articles/#{params[:id]}.json"
  @article = JSON.parse(File.read(file_path))
  erb :edit_article
end

post '/admin/edit/:id' do
  login_required
  file_path = "articles/#{params[:id]}.json"
  article = JSON.parse(File.read(file_path))
  article["title"] = params[:title]
  article["content"] = params[:content]

  File.write(file_path, JSON.pretty_generate(article))
  redirect '/admin'
end

# Delete article
post '/admin/delete/:id' do
  login_required
  file_path = "articles/#{params[:id]}.json"
  File.delete(file_path) if File.exist?(file_path)
  redirect '/admin'
end

# Login
get '/login' do
  erb :login
end
# Login route (this is where you authenticate the admin)
post '/login' do
  if params[:username] == 'admin' && params[:password] == 'password' # Example credentials
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