require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'
class InteractiveRecord
  #1. name table by taking own name, turning into string, downcasing, then making plural
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
      DB[:conn].results_as_hash = true
    #  binding.pry
      #query a table for its columns; only keep the column that says "name"
      sql = "pragma table_info('#{table_name}')"
      table_info = DB[:conn].execute(sql)
      column_names = []
      #gets the names of the columns; like "id", "name", "grade"
      table_info.each do |row|
        column_names << row["name"]
      end
      #gets rid of any nils
      column_names.compact
    end
#turns every column name string to a symbol and set an attr_accessor to them
  #   self.column_names.each do |col_name|
  #     attr_accessor col_nam.to_sym
  # end

#initialize takes in a hash iterate over hash; use self.send to do self.property = value;
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  #this is the table name; being referenced in an instance variable
    def table_name_for_insert
      self.class.table_name
    end
#collects the column names,
def values_for_insert
  values = []
  self.class.column_names.each do |col_name|
    values << "'#{send(col_name)}'" unless send(col_name).nil?
  end
  values.join(", ")
end
#columns names; removes the id column; adds in the comma to have "name, album"
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(options)
    attribute = options.keys.first.to_s
    value = options.values.first.to_s
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute} = '#{value}';"
    DB[:conn].execute(sql)
  end

end
