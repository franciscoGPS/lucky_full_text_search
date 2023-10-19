def iterate_columns(cols)
  cols.each_with_index do |col, index|
    yield col, index
  end
end

def append_searchable_columns(columns : Array(String))
  instructions = [] of String
  base_instruction = "array_to_tsvector(coalesce({{col}}::text[], '{}'::text[]))"

  iterate_columns(columns) do |col, index|
    instruction = base_instruction.gsub("{{col}}", col)

    instructions << instruction
  end

  instructions
end

def begin_process_with_string_cols(columns : String)
  params = columns.split(/\W+/).reject("")
  append_searchable_columns(params).join(" || ")
end

ARGV.try do |e|
  if e.size >= 1
    print begin_process_with_string_cols(e[0])
  end
end
