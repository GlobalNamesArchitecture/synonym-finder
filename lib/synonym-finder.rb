require 'json'
require 'sqlite3'
require 'taxamatch_rb'

Dir["#{File.dirname(__FILE__)}/synonym-finder/**/*.rb"].each {|f| require f}

class SynonymFinder
  attr :input, :db
  
  def initialize(input)
    @input = JSON.parse(input, :symbolize_names => true)
    @atomizer = Taxamatch::Atomizer.new
    @db = init_db
    build_tree
    @duplicate_finder = DuplicateFinder.new(self)
  end

  def find_genera_moves
  end

  def species_epithet_duplicates
    @duplicate_finder.species_epithet_duplicates
  end
  
  private
  
  def build_tree
    tree = {}
    species = {}
    genera = {}
    @input.each do |row|
      atomized_name = @atomizer.parse row[:name]
      species_string = get_species(atomized_name)
      genus = atomized_name[:genus][:string]
      species[species_string.to_sym] ? species[species_string.to_sym] << row[:id] : species[species_string.to_sym] = [row[:id]]
      genera[genus.to_sym] ? genera[genus.to_sym] << row[:id] : genera[genus.to_sym] = [row[:id]]
      @db.execute("insert into names (id, name, authors, years) values (?, ?, ?, ?)", [row[:id], row[:name], Marshal.dump(atomized_name[:all_authors]), Marshal.dump(atomized_name[:all_years])])
      path = row[:path].split("|")
      path_part = path[0]
      level = path.size - 1
      path[1..-1].each do |taxa|
        level -= 1
        path_part << "|"
        path_part << taxa
        key = path_part.to_sym
        tree[key] ? tree[key] << {id: row[:id], level: level} : tree[key] = [{id: row[:id], level: level}]
      end
    end
    species.keys.each do |key|
      @db.execute("insert into species_strings (species_string) values (?)", key.to_s)
      species_string_id = @db.execute("select last_insert_rowid()")[0][0]
      species[key].each do |name_id|
        @db.execute("insert into species_strings_names (species_string_id, name_id) values (?, ?)", [species_string_id, name_id])
      end
    end
    genera.keys.each do |key|
      @db.execute("insert into genera (genus) values (?)", key.to_s)
      genus_id = @db.execute("select last_insert_rowid()")[0][0]
      genera[key].each do |name_id|
        @db.execute("insert into genera_names (genus_id, name_id) values (?, ?)", [genus_id, name_id])
      end
    end
    tree.keys.each do |key|
      @db.execute("insert into paths (path) values (?)", key.to_s)
      path_id = @db.execute("select last_insert_rowid()")[0][0]
      tree[key].each do |row|
        name_id = row[:id]
        level = row[:level]
        @db.execute("insert into paths_names (path_id, name_id, level) values (?, ?, ?)", [path_id, name_id, level])
      end
    end
  end

  def init_db
    db = SQLite3::Database.new( ":memory:" )
    db.execute("create table names (id string primary key, name string, authors, years)")

    db.execute("create table paths (id integer primary key autoincrement, path)")
    db.execute("create table species_strings (id integer primary key autoincrement, species_string string)")
    db.execute("create table genera (id integer primary key autoincrement, genus string)")
    
    db.execute("create table paths_names (path_id integer, name_id string, level integer)")
    db.execute("create table species_strings_names (species_string_id integer, name_id string)")
    db.execute("create table genera_names (genus_id integer, name_id string)")
    db
  end

  def get_species(atomized_name)
    species = [atomized_name[:species][:string]]
    species += atomized_name[:infraspecies].map {|i| i[:string]} if atomized_name[:infraspecies]
    species.join(" ")
  end


end
