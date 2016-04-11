# -*- coding: utf-8 -*-
require 'active_record'

I18n.enforce_available_locales = false

ActiveRecord::Base.establish_connection :adapter => "sqlite3",
                                        :database => "bookstore.sqlite3" 

class Book < ActiveRecord::Base;
  validates_presence_of :title
  belongs_to :subject
  has_many :languages
  has_and_belongs_to_many :authors
end

class Author < ActiveRecord::Base;
  validates_presence_of :identifier, :name
  validates_uniqueness_of :identifier
  has_and_belongs_to_many :books
end

class Subject < ActiveRecord::Base;
  validates_presence_of :identifier, :name
  validates_uniqueness_of :identifier
  has_many :books
end

class Language < ActiveRecord::Base;
  validates_presence_of :identifier, :name
  validates_uniqueness_of :identifier
  belongs_to :books
end

def get_table_by_name(string)
  if string == "book"
    Book
  elsif string == "author"
    Author
  elsif string == "subject"
    Subject
  elsif string == "language"
    Language
  else
    nil
  end
end

def attribute_cast(attr, value)
  if attr == "subject"
    Subject.where(:identifier => value).first
  elsif attr == "author"
    Author.where(:identifier => value).first
  elsif attr == "language"
    Language.where(:identifier => value).first
  elsif attr == "birthdate"
    DateTime.parse(value)
  elsif attr == "price"
    value.to_f
  elsif attr == "year"
    value.to_i
  else
    value
  end
end

def scan_attributes(attributes)
  result = {}

  attributes.each do |attr|
    if attr[0] != nil
      attr[0].scan(/([a-zA-Z0-9]*)\s*=\s*"([a-zA-Z0-9\.\/\-\' ]*)"/).each do |key, value|
        result = { key => value }
      end
    end
  end

  result
end

while true
  print "> "
  input = STDIN.gets.chomp().squeeze(' ')
  first_space = input.index(' ')

  if first_space != nil
    second_space = input.index(' ', first_space + 1)
    oper = input[0 .. first_space - 1]

    if second_space != nil
      table_name = input[first_space + 1 .. second_space - 1]
      attributes = input[second_space + 1 .. -1].scan(/([a-zA-Z0-9]*\s*=\s*"[a-zA-Z0-9\.\/\-\' ]*")*/)
    end
  else
    oper = input
  end

  break if oper == "exit"

  if not oper.empty?
    if oper == "create"
      jlh = Author.new(:name => "John LeRoy Hennessy")
      dap = Author.new(:name => "David Andrew Patterson")
      ast = Author.new(:name => "Andrew Stuart Tanenbaum")

      ca = Subject.new(:name => "Computer Architecture")
      os = Subject.new(:name => "Operating Systems")

      book = Book.new(:title    => "Computer Architecture, 5th Edition",
                      :subtitle => "A Quantitative Approach",
                      :price    => 107.34,
                      :year     => 2011)

      jlh.save()
      dap.save()
      ast.save()
      ca.save()
      os.save()

      book.subject = ca
      book.authors << jlh
      book.authors << dap

      book.save()

    elsif oper == "insert"
      table = get_table_by_name(table_name)

      if table != nil
        target = table.new()

        if target != nil
          scan_attributes(attributes).each do |attr, value|
            if attr == "author"
              target[attr.to_sym] << attribute_cast(attr, value)
            else
              target[attr.to_sym] = attribute_cast(attr, value)
            end
          end
        end

        target.save()
      else
        print "Table \"#{table_name}\" doesn't exist!"
      end

    elsif oper == "edit"
      table = get_table_by_name(table_name)

      if table != nil
        target = table.all
        last_attr = nil
        last_value = nil

        scan_attributes(attributes).each do |attr, value|
          if last_attr != nil
            target = target.where(last_attr.to_sym => attribute_cast(last_attr, last_value))
          end

          last_attr = attr
          last_value = value
        end

        target.update_all(last_attr.to_sym => attribute_cast(last_attr, last_value))
      else
        print "Table \"#{table_name}\" doesn't exist!"
      end

    elsif oper == "delete"
      table = get_table_by_name(table_name)

      if table != nil
        target = table.all

        scan_attributes(attributes).each do |attr, value|
          target = target.where(attr.to_sym => attribute_cast(attr, value))
        end

        target.destroy_all
      else
        print "Table \"#{table_name}\" doesn't exist!"
      end

    elsif oper == "print"
      Book.all.each do |b|
        print "Title: #{b.title} - #{b.subtitle}"

        if b.year != nil
          puts " (#{b.year})"
        else
          puts " "
        end

        if b.authors != nil and b.authors.first != nil
          first = true 
          print "Author(s):"

          b.authors.each do |a|
            if not first
              print ","
            end

            first = false
            print " #{a.name}"
          end

          puts " "
        end

        puts "Subject: #{b.subject.name}" if b.subject != nil
        puts "Price: $#{b.price}" if b.price != nil
      end
    else
      puts "Invalid command: #{oper}"
    end
  end
end
