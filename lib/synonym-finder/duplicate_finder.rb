class SynonymFinder
  class DuplicateFinder

    def initialize(synonym_finder)
      @synonym_finder = synonym_finder
      @db = @synonym_finder.db
      @matches = {}
    end

    def canonical_duplicates
      SynonymFinder.logger_write(@synonym_finder.object_id, "Processing canonical forms")
      @db.execute("select canonical from name_parts group by canonical having count(*) > 1").each_with_index do |canonical, i|
        i = i + 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Processing canonical form candidate %s" % i) if i % 100 == 0
        names = @db.execute("select name_id, path from name_parts where canonical = ?", canonical)
        find_pairs(names)
      end
      require 'ruby-debug'; debugger
      puts ''
    end

    def species_epithet_duplicates
      res = {}
      @db.execute("select distinct epithets from name_parts").each do |row|
        names = @db.execute("select name_id from species_strings_names where species_string_id = ?", row[0]).map {|n| n[0]}.join(",")
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id")
        data = organize_data(data, res)
      end
      @matches
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

    def get_pairs(names)
      names = names.map { |n| [n[0], n[1].to_s.split("|")] }
      pairs = []
      until names.empty?
        name = names.pop
        names.each {|n| pairs << [name, n].sort}
      end
      pairs
    end

    def species_epithet_duplicates(threshold_distance)
      SynonymFinder.logger_write(@synonym_finder.object_id, "Processing species epithets")
      @db.execute("select epithet_stem from name_parts group by epithet_stem having count(*) > 1").each_with_index do |stem, i|
        i = i + 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Processing species epithet candidate %s" % i) if i % 100 == 0
        names = @db.execute("select name_id, path from name_parts where epithet_stem = ?", stem)
        find_pairs(names, threshold_distance)
      end
      count = 0
      SynonymFinder.logger_write(@synonym_finder.object_id, "Assigning type to found matches")
      @matches.each do |key, value|
        next if value.has_key?(:type)
        count += 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Processing match %s" % count) if count % 10000 == 0
        if value[:total_distance] == 0
          epithets = @db.execute("select distinct epithet from name_parts where name_id in (#{key.join(",")})")
          if epithets.size == 1
            value[:type] = :misplaced_synonym
          else
            genera = @db.execute("select canonical from name_parts where name_id in (#{key.join(",")})").map { |c| c[0].split(" ")[0] }.uniq
            value[:type] = genera.size == 1 ? :lexical_variant : :misplaced_synonym
          end
        else
          value[:type] = :homotypic
        end
      end
      @matches
    end
  end
end
