
def iterate_columns(cols)
  cols.each_with_index do |col, index|
    yield col, index
  end
end

def append_searchable_columns(columns, weighted = false)

  add_weights = true if weighted == "true" || weighted == true 

  instructions = [] of String
  base_instruction = "to_tsvector('english', coalesce( {{col}}, ''))" 
  base_instruction = "setweight(to_tsvector('english', coalesce( {{col}}, '')), '{{weight}}')" if add_weights

  iterate_columns(columns) do |col, index|
    instruction = base_instruction.gsub("{{col}}", col)
    instruction = instruction.gsub("{{weight}}", ('A'..'Z').to_a[index]) if add_weights
    instructions << instruction
  end

  instructions
end

def append_searchable_columns(columns : String, weighted)
  params = columns.split(/\W+/).reject("")
  append_searchable_columns(params, weighted).join(" || ")
end
 
ARGV.try do |e|
  if e.size >= 2
    print append_searchable_columns(e[0], e[1])
  end
end