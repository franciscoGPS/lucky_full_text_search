# lucky_full_text_search

TODO: Write a description here

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lucky_full_text_search:
       github: franciscoGPS/lucky_full_text_search
   ```

2. Run `shards install`

## Usage

```crystal

in tasks.cr
require "lucky_full_text_search/tasks/**"

```

 ### Run generator, example:

  For a model ```Post```, with title, author and content string columns

 ``` 
 lucky add.searchable Post search_full weighted title content
 ```

 There will be created a new column called "search_full" and new scope method to query for both columns used
 The ``` weighted```  param, stands for the descendent priority in the search for the columns to be used
 ```
  title:   'A',
  content: 'B'  
  ```
Will prioritize records in which the match is higher in the column A than the B 

If the priority is irrelevant, then a ```false``` ignores it

 ``` 
 lucky add.searchable Post search_full false title content
 ```
Follow the steps provided by the task when it's done.

1. Create the TTSVector alais
2. Include the library and call the macro
3. Use the new search scope, eg: 
```
 PostQuery.new.search_full("Lucky") #=> PostQuery instance
```


## Next steps
In order to achieve multisearchable capacity, we could follow the approach similar to the one used PGSearch gem
(<https://github.com/Casecommons/pg_search#multi-search >)

Create a table pg_search_documents 
   ```
  create_table :pg_search_documents do |t|
    t.text :content
    t.references :scope, index: true
    t.belongs_to :searchable, polymorphic: true, index: true
    t.timestamps null: false
  end
   ```

  We'll have to manage polimorphism in the crystal way
    For every model there should be a column for class to hold the id the record.
```
  def deprecated_create_polymorphic_relation
    AppDatabase.exec "
      ALTER TABLE pg_search_documents
      ADD IF NOT EXISTS #{model.downcase}_id bigint;
    "
  end  
```
## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/franciscoGPS/lucky_full_text_search/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [F. Cordero.](https://github.com/franciscoGPS) - creator and maintainer
