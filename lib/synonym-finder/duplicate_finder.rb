class SynonymFinder
  class DuplicateFinder

    def initialize(synonym_finder)
      @db = synonym_finder.db
    end

    def species_epithet_duplicates
      matches = {}
      epithets = @db.execute("select * from species_strings").each do |row|
        names = @db.execute("select name_id from species_strings_names where species_string_id = ?", row[0]).map {|n| n[0]}.join(",")
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id")
        unless data.empty?
          data.each do |row|
            name_ids = row[0..1]
            levels = row[2..3]
            distance = levels.inject(0) {|res, level| res += level; res}
            if name_ids != name_ids.sort
              name_ids = name_ids.reverse
              levels = levels.reverse
            end
            if !matches[name_ids] || matches[name_ids][:distance] > distance
              matches[name_ids] = {levels: levels, distance: distance}
            end
          end
        end
      end
      require 'ruby-debug'; debugger
      puts ''
    end
  end
end
