require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'db/databas'

enable :sessions

# Startsida
get '/' do
  featured_products = DB.execute("SELECT * FROM Products ORDER BY RANDOM() LIMIT 4")
  slim :home, locals: { products: featured_products }
end

#Produktsida
get '/shop' do
  products = DB.execute("SELECT * FROM Products")
  slim :"products/index", locals: { products: products }
end

#Enskild produktsida
get '/products/:id' do
  product = DB.execute("SELECT * FROM Products WHERE Product_Id = ?", params[:id]).first
  slim :"products/show", locals: { product: product }
end

#Registrering
get '/register' do
  slim :"users/register"
end

post '/register' do
  username = params[:username]
  password = params[:password]
  password_digest = BCrypt::Password.create(password)

  DB.execute("INSERT INTO Users (Username, Password) VALUES (?, ?)", [username, password_digest])
  redirect '/login'
end

#Inloggning
get '/login' do
  slim :"users/login"
end

post '/login' do
  username = params[:username]
  password = params[:password]
  
  user = DB.execute("SELECT * FROM Users WHERE Username = ?", [username]).first
  if user && BCrypt::Password.new(user["Password"]) == password
    session[:user_id] = user["User_Id"]
    redirect '/shop'
  else
    redirect '/login'
  end
end

#Utloggning
get '/logout' do
  session.clear
  redirect '/'
end
