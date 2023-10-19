# TODO: Write documentation for `LuckyFullTextSearch`

require "./helpers/**"

module LuckyFullTextSearch(T)
  VERSION = "0.1.2"

  def self.version
    "v#{VERSION} "
  end

  macro fast_full_text_search(name)

    def {{name.id}}(query, limit = 24)
      sql = <<-SQL
        SELECT #{table_name}.*
        FROM #{table_name}
        INNER JOIN (
          SELECT DISTINCT #{table_name}.id AS pg_search_id,
          (
            ts_rank(
            (#{table_name}.{{name.id}}),
            (to_tsquery('english', $1))
            )::decimal
          ) AS rank
          FROM #{table_name}
          WHERE (
            ((#{table_name}.{{name.id}}) @@ (to_tsquery('english', $1)))
          )
          LIMIT $2
        ) pg_search ON #{table_name}.id = pg_search.pg_search_id
        ORDER BY pg_search.rank DESC
        LIMIT $2
      SQL
      result = [] of T
      begin
        result = database.query_all(sql, query, limit, as: T )
      rescue exception
        result = [] of T
        pp exception
      end  
      
        ids = result.map{|item| item.id }
        id.in(ids)
    end
  end

  macro full_text_search(name, weighted = false, text_columns = [] of String, array_columns = [] of String)
    {% column_statements = run("./helpers/command_helpers.cr", text_columns.join(","), weighted) %}
    {% col_statements = run("./helpers/array_command_helpers.cr", array_columns.join(",")) %}
    def {{name.id}}(query, limit = 24)
      sql = <<-SQL
        SELECT #{table_name}.*
        FROM #{table_name}
        INNER JOIN (
          SELECT DISTINCT #{table_name}.id AS pg_search_id,
          {% unless column_statements.id.empty? %}

          (
            ts_rank(
            ( {{ column_statements.id }} ),
            (to_tsquery('english', $1))
            )::decimal
          ) AS rank
          {% end %}
          {% unless col_statements.id.empty? %}
          {% unless column_statements.id.empty? %}
            ,
          {% end %}
          (
            ts_rank(
            ( {{ col_statements.id }} ),
            (to_tsquery('english', $1))
            )::decimal
          ) AS array_search_rank
          {% end %}

          FROM #{table_name}
          WHERE (
            ( (
              {% unless column_statements.id.empty? %}
                {{ column_statements.id }} 
              {% end %}
              {% unless col_statements.id.empty? %}
                {% unless column_statements.id.empty? %}
                  ||
                {% end %}

                {{ col_statements.id }} 
  
              {% end %}
              
              ) @@ (to_tsquery('english', $1)))
          )
          limit $2
        ) pg_search ON #{table_name}.id = pg_search.pg_search_id
        ORDER BY
        {% if !col_statements.id.empty? && !column_statements.id.empty? %}
          array_search_rank DESC, rank DESC
        {% elsif !column_statements.id.empty? %}
          rank DESC
        {% else %}
          array_search_rank DESC
        {% end %}

        LIMIT $2
      SQL
      result = [] of T
      begin
        
        result = database.query_all(sql, query, limit, as: T )
      rescue exception
        result = [] of T
        pp exception
      end  
      
        ids = result.map{|item| item.id }
        id.in(ids)
    end
  end
end
