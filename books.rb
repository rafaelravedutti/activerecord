# -*- coding: utf-8 -*-
require 'active_record'

I18n.enforce_available_locales = false

ActiveRecord::Base.establish_connection :adapter => "sqlite3",
                                        :database => "bookstore.sqlite3" 

class Book < ActiveRecord::Base;
  validates_presence_of :title
  belongs_to :subject
  belongs_to :volume_set
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

class VolumeSet < ActiveRecord::Base;
  validates_presence_of :identifier, :name
  validates_uniqueness_of :identifier
  has_many :books
end

def get_table_by_name(string)
  if string == "book"
    Book
  elsif string == "author"
    Author
  elsif string == "subject"
    Subject
  elsif string == "volume_set"
    VolumeSet
  else
    nil
  end
end

def attribute_cast(attr, value)
  if attr == "subject"
    Subject.where(:identifier => value).first
  elsif attr == "author"
    Author.where(:identifier => value).first
  elsif attr == "volume_set"
    VolumeSet.where(:identifier => value).first
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
      attr[0].scan(/([a-zA-Z0-9\_]*)\s*=\s*"([a-zA-Z0-9\.\/\-\'\!\?\(\)\_\: ]*)"/).each do |key, value|
        result[key] = value
      end
    end
  end

  result
end

def print_books
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
end

while true
  print "> "
  input = STDIN.gets.chomp().squeeze(' ')
  first_space = input.index(' ')
  second_space = nil
  table_name = nil
  attributes = nil

  if first_space != nil
    second_space = input.index(' ', first_space + 1)
    oper = input[0 .. first_space - 1]

    if second_space != nil
      table_name = input[first_space + 1 .. second_space - 1]
      attributes = input[second_space + 1 .. -1].scan(/([a-zA-Z0-9\_]*\s*=\s*"[a-zA-Z0-9\.\/\-\'\!\?\(\)\_\: ]*")*/)
    else
      table_name = input[first_space + 1 .. -1]
    end
  else
    oper = input
  end

  if not oper.empty?
    break if oper == "exit"

    if oper == "insert"
      table = get_table_by_name(table_name)

      if table != nil
        target = table.new()

        if target != nil
          scan_attributes(attributes).each do |attr, value|
            if attr == "author"
              target.authors << attribute_cast(attr, value)
            elsif attr == "subject"
              target.subject = attribute_cast(attr, value)
            elsif attr == "volume_set"
              target.volume_set = attribute_cast(attr, value)
            else
              begin
                target[attr.to_sym] = attribute_cast(attr, value)
              rescue ActiveModel::MissingAttributeError, NoMethodError
                puts "Invalid attribute: \"#{attr}\""
              end
            end
          end
        end

        begin
          target.save!
        rescue ActiveModel::MissingAttributeError, NoMethodError
        rescue ActiveRecord::RecordInvalid
          puts "Record validation failed, does all the necessary attributes for the table are specified?"
        end
      else
        puts "Table \"#{table_name}\" doesn't exist!"
      end

    elsif oper == "edit"
      table = get_table_by_name(table_name)

      if table != nil
        target = table.all
        last_attr = nil
        last_value = nil

        scan_attributes(attributes).each do |attr, value|
          if last_attr != nil
            if last_attr == "author"
              list = []

              target.each do |t|
                if not t.authors.where(:identifier => last_value).empty?
                  list.push(t.id)
                end
              end

              target = table.where(:id => list)
            else
              target = target.where(last_attr.to_sym => attribute_cast(last_attr, last_value))
            end
          end

          last_attr = attr
          last_value = value
        end

        if last_attr == "author"
          target.each do |t|
            t.authors << attribute_cast(last_attr, last_value)
            t.save!
          end
        elsif last_attr == "subject"
          target.each do |t|
            t.subject = attribute_cast(last_attr, last_value)
            t.save!
          end
        elsif last_attr == "volume_set"
          target.each do |t|
            t.volume_set = attribute_cast(last_attr, last_value)
            t.save!
          end
        else
          begin
            target.update_all(last_attr.to_sym => attribute_cast(last_attr, last_value))
          rescue ActiveRecord::StatementInvalid
            puts "Invalid attribute specification!"
          end
        end
      else
        puts "Table \"#{table_name}\" doesn't exist!"
      end

    elsif oper == "delete"
      table = get_table_by_name(table_name)

      if table != nil
        target = table.all

        scan_attributes(attributes).each do |attr, value|
          if attr == "author"
            list = []

            target.each do |t|
              if not t.authors.where(:identifier => value).empty?
                list.push(t.id)
              end
            end

            target = table.where(:id => list)
          else
            target = target.where(attr.to_sym => attribute_cast(attr, value))
          end
        end

        begin
          target.destroy_all
        rescue ActiveRecord::StatementInvalid
          puts "Invalid attribute specification!"
        end
      else
        puts "Table \"#{table_name}\" doesn't exist!"
      end

    elsif oper == "print"
      if table_name == "book"
        print_books
      elsif table_name == "author"
        Author.all.each do |a|
          print "#{a.name}"
          if a.birthdate != nil
            print " (#{a.birthdate.strftime("%m/%d/%Y")})"
          end

          puts " [#{a.identifier}]"
        end
      elsif table_name == "subject"
        Subject.all.each do |s|
          puts "#{s.name} [#{s.identifier}]"
        end
      elsif table_name == "volume_set"
        VolumeSet.all.each do |vs|
          print "#{vs.name} : "
          first = true

          vs.books.each do |b|
            if not first
              print ", "
            end

            first = false
            print "#{b.title}"
          end

          puts " "
        end
      else
        puts "Table \"#{table_name}\" doesn't exist!"
      end
    else
      puts "Invalid command: #{oper}"
    end
  end
end
