# TODO: Write documentation for `LuckyFullTextSearch`

require "./helpers/**"

module LuckyFullTextSearch(T)
  VERSION = "0.1.1"
  
  def self.version
    "v#{VERSION} "
  end

  macro fast_full_text_search(name)

    def {{name.id}}(query, limit = 24)
      sql = <<-SQL
        SELECT #{table_name}.*
        FROM #{table_name}
        INNER JOIN (
          SELECT #{table_name}.id AS pg_search_id,
          (
            ts_rank(
            (#{table_name}.{{name.id}}),
            (websearch_to_tsquery('english', $1)), 0
            )::decimal
          ) AS rank
          FROM #{table_name}
          WHERE (
            ((#{table_name}.{{name.id}}) @@ (websearch_to_tsquery('english', $1)))
          )
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

  macro full_text_search(name, weighted = false, *columns)
    {% column_sattements = run("./helpers/command_helpers.cr", columns.join(","), weighted) %}

    def {{name.id}}_search(query, limit = 24)
      sql = <<-SQL
        SELECT #{table_name}.*
        FROM #{table_name}
        INNER JOIN (
          SELECT #{table_name}.id AS pg_search_id,
          (
            ts_rank(
            ( {{ column_sattements.id }} ),
            (websearch_to_tsquery('english', $1)), 0
            )::decimal
          ) AS rank
          FROM #{table_name}
          WHERE (
            ( ( {{ column_sattements.id }} ) @@ (websearch_to_tsquery('english', $1)))
          )
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
end