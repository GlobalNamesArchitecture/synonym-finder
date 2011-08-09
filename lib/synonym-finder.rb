require 'logger'
require 'json'
require 'sqlite3'
require 'taxamatch_rb'
require 'lingua/stemmer'

Dir["#{File.dirname(__FILE__)}/synonym-finder/**/*.rb"].each {|f| require f}

class SynonymFinder
  NO_AUTH_INFO = 10
  PARTIAL_AUTH_INFO = 20
  AUTH_MATCH = 100
  AUTH_NO_MATCH = 0

  attr :input, :db, :matches
  
  def self.logger
    @@logger ||= Logger.new(nil)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger_reset
    self.logger = Logger.new(nil)
  end

  def self.logger_write(obj_id, message, method = :info)
    self.logger.send(method, "|%s|%s|" % [obj_id, message])
  end

  
  def initialize(input, in_memory = true)
    @input = JSON.parse(input, :symbolize_names => true)
    @atomizer = Taxamatch::Atomizer.new
    @tm = Taxamatch::Base.new
    @stemmer = Lingua::Stemmer.new(:language => "latin")
    @db = init_db(in_memory)
    tmp_populate
    build_tree unless @db.execute("select count(*) from names")[0][0].to_i > 0
    @matches = {}
    @duplicate_finder = DuplicateFinder.new(self)
    @group_organizer = GroupOrganizer.new(self)
  end

  def find_matches(threshold = 5)
    canonical_matches = @duplicate_finder.canonical_duplicates
    epithet_matches = @duplicate_finder.species_epithet_duplicates(threshold)
    matches = epithet_matches.merge(canonical_matches)
    matches = compare_authorship(matches)
    @matches = clean_up(matches)
    @group_organizer.organize
  end

  private

  def clean_up(matches)
    res = {}
    matches.each do |key, value|
      next if value[:type] != :chresonym && value[:auth_match] == 0
      res[key] = value
    end
    res
  end

  def compare_authorship(matches)
    SynonymFinder.logger(self.object_id, "Matching authorship")
    count = 0
    matches.each do |key, value|
      count += 1
      SynonymFinder.logger(self.object_id, "Matching authors %s" % count) if count % 1000 == 0
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

  
  def build_tree
    tree = {}
    name_parts = {}
    @input.each_with_index do |row, i|
      i += 1
      SynonymFinder.logger_write(self, "Ingesting record %s" % i) if i % 10000 == 0
      atomized_name = @atomizer.parse row[:name] rescue nil
      next unless atomized_name && atomized_name[:species]
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
    name_parts.keys.each_with_index do |key, i|
      i += 1
      SynonymFinder.logger_write(self, "Processing parsed_name %s" % i) if i % 10000 == 0
      name_parts[key].each do |name_id|
        vals = key + [stem_epithet(key[-1]), name_id]
        @db.execute("insert into name_parts (canonical, epithet, epithet_stem, name_id) values (?, ?, ?, ?)", vals)
      end
    end
    tree.keys.each_with_index do |key, i|
      i += 1
      SynonymFinder.logger_write(self, "Processing path %s" % i) if i % 10000 == 0
      @db.execute("insert into paths (path) values (?)", key.to_s)
      path_id = @db.execute("select last_insert_rowid()")[0][0]
      tree[key].each do |row|
        name_id = row[:id]
        level = row[:level]
        @db.execute("insert into paths_names (path_id, name_id, level) values (?, ?, ?)", [path_id, name_id, level])
      end
    end
  end

  def init_db(in_memory)
    if in_memory == true
      db = SQLite3::Database.new( ":memory:" )
      create_tables(db)
    else
      db_file = "/tmp/syn_finder.sql"
      db_exist = File.exist?(db_file)
      db = SQLite3::Database.new("/tmp/syn_finder.sql")
      unless db_exist
        create_tables(db)
      end
    end
    db
  end

  def create_tables(db)
    db.execute("create table names (id string primary key, name string, authors, years)")
    db.execute("create table paths (id integer primary key autoincrement, path)")
    db.execute("create table paths_names (path_id integer, name_id string, level integer, primary key (path_id, name_id))")
    db.execute("create table name_parts (canonical string, epithet string, epithet_stem string, name_id string)")
    db.execute("create index idx_name_parts_1 on name_parts (canonical)")
    db.execute("create index idx_name_parts_2 on name_parts (epithet_stem)")
    db.execute("create index idx_name_parts_3 on name_parts (name_id)")
    db.execute("create table groups (id integer primary key, type)")
    db.execute("create table names_groups (name_id integer, group_id integer, score_max integer, score_sum integer, score_num integer, primary key (name_id, group_id))")
    db.execute("create index idx_names_groups_2 on names_groups (group_id)")
  end

  def get_species(atomized_name)
    species = [atomized_name[:species][:string]]
    species += atomized_name[:infraspecies].map {|i| i[:string]} if atomized_name[:infraspecies]
    species.join(" ")
  end

  def stem_epithet(epithet)
    epithet.split(" ").map { |e| @stemmer.stem(e) }.join(" ")
  end

  def tmp_populate
    f = open("/tmp/dump.sql")
    f.each_with_index do |line, i|
      i += 1
      puts "loading from dump line %s" % i if i % 10000 == 0
      if line.match /INSERT/
        @db.execute(line.strip)
      end
    end
  end

end
