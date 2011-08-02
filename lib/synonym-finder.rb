require 'json'
require 'sqlite3'
require 'taxamatch_rb'
require 'lingua/stemmer'

Dir["#{File.dirname(__FILE__)}/synonym-finder/**/*.rb"].each {|f| require f}

class SynonymFinder
  NO_AUTH_INFO = 0.1
  PARTIAL_AUTH_INFO = 0.2
  AUTH_MATCH = 1.0
  AUTH_NO_MATCH = 0.0

  attr :input, :db
  
  def initialize(input)
    @input = JSON.parse(input, :symbolize_names => true)
    @atomizer = Taxamatch::Atomizer.new
    @tm = Taxamatch::Base.new
    @stemmer = Lingua::Stemmer.new(:language => "latin")
    @db = init_db
    build_tree
    @duplicate_finder = DuplicateFinder.new(self)
  end

  def find_matches(threshold = 5)
    canonical_matches = @duplicate_finder.canonical_duplicates
    epithet_matches = @duplicate_finder.species_epithet_duplicates(threshold)
    matches = epithet_matches.merge(canonical_matches)
    matches = compare_authorship(matches)
    matches = clean_up(matches)
    create_duplication_groups(matches)
  end

  private

  def clean_up(matches)
    res = {}
    matches.each do |key, value|
      next if value[:type] != :chresonym && value[:auth_match] == 0
      res[key] = value
    end
  end

  def compare_authorship(matches)
    matches.each do |key, value|
      ids = key.join(",")
      res = @db.execute("select authors, years from names where id in (#{ids})")
      data1 = {:all_authors => Marshal.load(res[0][0]), :all_years =>Marshal.load(res[0][1])}
      data2 = {:all_authors => Marshal.load(res[1][0]), :all_years =>Marshal.load(res[1][1])}
      if (data1[:all_authors] + data1[:all_years] + data2[:all_authors] + data2 [:all_years]) == []
        value[:auth_match] = NO_AUTH_INFO
      elsif (data1[:all_authors] + data1[:all_years]).empty? || (data2[:all_authors] + data2[:all_years]).empty?
        value[:auth_match] = PARTIAL_AUTH_INFO
      else
        value[:auth_match] = @tm.match_authors(data1, data2) == 0 ? AUTH_NO_MATCH : AUTH_MATCH
      end
    end
    matches
  end

  def create_duplication_groups(matches)
    groups = {}
    matches.each do |key, value|
      last_id = @db.execute("select max(id) from groups")[0][0] + 1 rescue 1
      if groups.has_key?(key[0]) && groups.has_key?(key[1])
        if groups[key[0]] != groups[key[1]]
          old_group = @db.execute("select name_id from names_groups where group_id = ?", groups[key[1]]).map { |row| row[0] }
          old_group.each { |name_id| groups[name_id] = groups[key[0]] }
          @db.execute("update names_groups set group_id = ? where group_id = ?", [groups[key[0]], groups[key[1]]])
        end
      elsif groups.has_key? key[0]
        groups[key[1]] = groups[key[0]]
        @db.execute("insert into names_groups (name_id, group_id) values (?, ?)", [key[1], groups[key[0]]])
      elsif groups.has_key? key[1]
        groups[key[0]] = groups[key[1]]
        @db.execute("insert into names_groups (name_id, group_id) values (?, ?)", [key[0], groups[key[1]]])
      else
        @db.execute("insert into groups (id) values (?)", last_id)
        groups[key[0]] = last_id
        groups[key[0]] = last_id
        key.each do |id|
          @db.execute("insert into names_groups (name_id, group_id) values (?, ?)", [id, last_id])
        end
      end
    end
    require 'ruby-debug'; debugger
    puts ''
  end

  def build_tree
    tree = {}
    name_parts = {}
    @input.each do |row|
      atomized_name = @atomizer.parse row[:name]
      species_string = get_species(atomized_name)
      canonical_name = atomized_name[:genus][:string] + " " + species_string
      sp_ary = [canonical_name, species_string]
      name_parts[sp_ary] ? name_parts[sp_ary] << row[:id] : name_parts[sp_ary] = [row[:id]]
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
    name_parts.keys.each do |key|
      name_parts[key].each do |name_id|
        vals = key + [stem_epithet(key[-1]), name_id]
        @db.execute("insert into name_parts (canonical, epithet, epithet_stem, name_id) values (?, ?, ?, ?)", vals)
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
    db.execute("create table paths_names (path_id integer, name_id string, level integer)")
    db.execute("create table name_parts (canonical string, epithet string, epithet_stem string, name_id string)")
    db.execute("create table groups (id integer primary key)")
    db.execute("create table names_groups (name_id integer, group_id integer)")
    db
  end

  def get_species(atomized_name)
    species = [atomized_name[:species][:string]]
    species += atomized_name[:infraspecies].map {|i| i[:string]} if atomized_name[:infraspecies]
    species.join(" ")
  end

  def stem_epithet(epithet)
    epithet.split(" ").map { |e| @stemmer.stem(e) }.join(" ")
  end

end
