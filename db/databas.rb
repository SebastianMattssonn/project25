require 'sqlite3'

DB = SQLite3::Database.new("db/databas.db")

DB.results_as_hash = true
