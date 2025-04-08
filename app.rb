require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'db/databas'

enable :sessions

# Initiera kundvagn innan varje request
before do
  session[:cart] ||= []
end

# Startsida
get '/' do
  featured_products = DB.execute("SELECT * FROM Products ORDER BY RANDOM() LIMIT 4")

  if session[:user_id]
    user = DB.execute("SELECT Username FROM Users WHERE User_Id = ?", [session[:user_id]]).first
    username = user ? user["Username"] : nil
  else
    username = nil
  end

  slim :home, locals: { products: featured_products, username: username }
end

# Produktsida
get '/shop' do
  products = DB.execute("SELECT * FROM Products")
  slim :"products/index", locals: { products: products }
end

# Enskild produktsida
get '/products/:id' do
  product = DB.execute("SELECT * FROM Products WHERE Product_Id = ?", params[:id]).first
  slim :"products/show", locals: { product: product }
end

# Lägg till i kundvagn – endast för inloggade
post '/cart/add/:id' do
  unless session[:user_id]
    session[:message] = "Du måste logga in för att fortsätta."
    redirect '/login'
  end

  session[:cart] << params[:id]
  redirect '/cart'
end

# Ta bort från kundvagn
post '/cart/remove/:id' do
  session[:cart].delete_at(session[:cart].index(params[:id]) || session[:cart].length)
  redirect '/cart'
end

# Visa kundvagn
get '/cart' do
  if session[:cart].empty?
    cart_products = []
  else
    placeholders = session[:cart].map { '?' }.join(',')
    query = "SELECT * FROM Products WHERE Product_Id IN (#{placeholders})"
    cart_products = DB.execute(query, session[:cart])
  end

  slim :"cart/cart", locals: { cart_products: cart_products }
end

# Registrering
get '/register' do
  slim :"auth/register"
end

post '/register' do
  username = params[:username]
  password = params[:password]

  if username.empty? || password.empty?
    redirect '/register'
  end

  password_digest = BCrypt::Password.create(password)

  begin
    DB.execute("INSERT INTO Users (Username, Password) VALUES (?, ?)", [username, password_digest])
    redirect '/login'
  rescue SQLite3::ConstraintException
    redirect '/register'
  end
end

# Inloggning
get '/login' do
  slim :"auth/login"
end

post '/login' do
  username = params[:username]
  password = params[:password]

  user = DB.execute("SELECT * FROM Users WHERE Username = ?", [username]).first

  if user && BCrypt::Password.new(user["Password"]) == password
    session[:user_id] = user["User_Id"]
    session[:message] = nil # Rensa ev. gammalt meddelande
    redirect '/'
  else
    redirect '/login'
  end
end

# Utloggning
get '/logout' do
  session.clear
  redirect '/'
end
