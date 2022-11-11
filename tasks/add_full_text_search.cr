require "lucky_task"
require "teeplate"

class GenerateMigrationTemplate < Teeplate::FileTree
  directory "#{__DIR__}/templates/"

  @base_model : String
  @scope_name : String
  @filename   : String
  @time       : String
  @columns    : String

  def initialize(@base_model, @scope_name, @searchable_cols : Array(String))
    @time =  Time.utc.to_s("%G%m%e%H%M%S")
    @scope_filename = @scope_name.underscore
    @filename = Wordsmith::Inflector.pluralize(@base_model).underscore
    @columns = @searchable_cols.join(" || ")
  end
end

class AddFtSearchToModel < LuckyTask::Task

  summary "Add models and columns for full text search"
  name "add.searchable"
  
  positional_arg :model, "The name of the model", format: /^[A-Z]/
  positional_arg :scope_name, "The name of the scope", format: /^[a-z]/
  positional_arg :weighted, "add default ordering weights to the columns.",
                  format: /[true-false-weighted]/
  positional_arg :columns,
                  "The columns for this model in format: col:type",
                  to_end: true, 
                  format: /^\w+$/

  def call
    @add_weights = false
    @add_weights = true if weighted == "true" || weighted == "weighted"
    @searchable_name = scope_name
    @searchable_name = "" if @searchable_name.nil?


    run_insert_function_and_trigger
    print_next_steps

    template = GenerateMigrationTemplate.new(model, @searchable_name.not_nil!, append_searchable_columns(columns, @add_weights))
    template.render "db/migrations", interactive: true, list: true, color: true
  end

  def run_insert_function_and_trigger
    #add_searchable_column
  end

  def print_next_steps
    puts "########################################################"
    puts "############## Multisearch - NEXT STEPS ################"
    puts 
    puts " 1.- Add the following to your #{model} model:          "
    puts 
    puts "   Inside class declaration, after includes, if not added yet:              "
    puts 
    puts "      alias TSVector = String                           "
    puts
    puts "  2.- add the new column to your table bloc:            "
    puts 
    puts "      column #{@searchable_name} : #{model}::TSVector?  "
    puts "                                                        "
    puts "  3.- Include and call the macro method inside the #{model.capitalize}Query class like  " 
    puts
    puts "      include FullTextSearch(#{model.capitalize})       "
    puts "      full_text_search \"#{@searchable_name}\"          "
    puts "                                                        "
    puts "  You have a new query method:                          "
    puts "                                                        "
    puts "    #{model.capitalize}Query.new.#{@searchable_name}_search(\"search term\") "
    puts "                                                        "
    puts "                                                        "
    puts "########################################################"
  end

  def add_searchable_column
    AppDatabase.exec "
      ALTER TABLE #{Wordsmith::Inflector.pluralize(model)}
      DROP COLUMN IF EXISTS #{@searchable_name};
    "

    AppDatabase.exec "
      ALTER TABLE #{Wordsmith::Inflector.pluralize(model)}
      ADD COLUMN IF NOT EXISTS #{@searchable_name} tsvector GENERATED ALWAYS AS (
        #{append_searchable_columns(columns).join(" || ")}
      ) STORED;
    "

    AppDatabase.exec "
      DROP INDEX IF EXISTS #{model.downcase }_#{@searchable_name};
    "
    AppDatabase.exec "
      CREATE INDEX CONCURRENTLY #{model.downcase }_#{@searchable_name} ON #{Wordsmith::Inflector.pluralize(model)} USING GIN(#{@searchable_name});
    "
  end
end