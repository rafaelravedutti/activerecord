# -*- coding: utf-8 -*-

require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection :adapter  => "sqlite3",
                                        :database => "bookstore.sqlite3" 

ActiveRecord::Base.connection.create_table :books do |t|
  t.string  :title
  t.string  :subtitle
  t.float   :price
  t.integer :year
end

ActiveRecord::Base.connection.create_table :authors do |t|
  t.string  :identifier
  t.string  :name
  t.date    :birthdate
end

ActiveRecord::Base.connection.create_table :subjects do |t|
  t.string  :identifier
  t.string  :name
end

ActiveRecord::Base.connection.create_table :languages do |t|
  t.string  :identifier
  t.string  :name
end

ActiveRecord::Base.connection.create_table :authors_books do |t|  
  t.integer :book_id
  t.integer :author_id
end
