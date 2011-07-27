class SynonymFinder
  class DuplicateFinder

    def initialize(synonym_finder)
      @db = synonym_finder.db
    end

    def canonical_duplicates
      res = {}
      @db.execute("select canonical from name_parts group by canonical having count(*) > 1").each do |canonical|
        names = @db.execute("select name_id from name_parts where canonical = ?", canonical).map {|n| n[0]}.join(",")
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id")
        require 'ruby-debug'; debugger
        puts ''
      end
    end

    def species_epithet_duplicates
      res = {}
      @db.execute("select distinct epithets from name_parts").each do |row|
        names = @db.execute("select name_id from species_strings_names where species_string_id = ?", row[0]).map {|n| n[0]}.join(",")
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id")
        data = organize_data(data, res)
      end
      require 'ruby-debug'; debugger
      puts ''
    end

    private
    
    def organize_data(data, res)
      data.each do |datum|
        ids = datum[0..1].sort
        distances = (ids == datum[0..1]) ? datum[-2..-1] : datum[-2..-1].reverse
        total_distance = datum[-2] + datum[-1]
        if !res[ids] || res[ids][:total_distance] > total_distance
          res[ids] = { :distances => distances, :total_distance => total_distance }
        end
      end
      res 
    end

  end
end
