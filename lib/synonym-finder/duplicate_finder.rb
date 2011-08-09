class SynonymFinder
  class DuplicateFinder

    def initialize(synonym_finder)
      @synonym_finder = synonym_finder
      @db = @synonym_finder.db
    end

    def canonical_duplicates
      SynonymFinder.logger_write(@synonym_finder.object_id, "Processing canonical forms")
      matches = {}
      @db.execute("select canonical from name_parts group by canonical having count(*) > 1").each_with_index do |canonical, i|
        i = i + 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Processing canonical form candidate %s" % i) if i % 100 == 0
        names = @db.execute("select name_id from name_parts where canonical = ?", canonical).map {|n| n[0]}.join(",")
        data = @db.execute("select distinct min(res1, res2), max(res1, res2), min(total_distance) from (select pn1.name_id as res1, pn2.name_id as res2, (pn1.level + pn2.level) as total_distance from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id) as x group by x.res1, x.res2")
        data.each { |row| matches[row[0..1]] = { :total_distance => row[2] } }
      end
      matches.each do |key, value|
        if value[:total_distance] == 0
          value[:type] = :chresonym
        else
          value[:type] = :alt_placement
        end
      end
      matches
    end

    def species_epithet_duplicates(threshold_distance)
      SynonymFinder.logger_write(@synonym_finder.object_id, "Processing species epithets")
      matches = {}
      @db.execute("select epithet_stem from name_parts group by epithet_stem having count(*) > 1").each_with_index do |stem, i|
        i = i + 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Processing species epithet candidate %s" % i) if i % 100 == 0
        names = @db.execute("select name_id from name_parts where epithet_stem = ?", stem).map {|n| n[0]}.join(",")
        data = @db.execute("select distinct min(res1, res2), max(res1, res2), min(total_distance) from (select pn1.name_id as res1, pn2.name_id as res2,(pn1.level + pn2.level) as total_distance from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id and total_distance < ?) as x group by x.res1, x.res2", threshold_distance)
        data.each { |row| matches[row[0..1]] = { :total_distance => row[2] } }
      end
      matches.each do |key, value|
        if value[:total_distance] == 0
          epithets = @db.execute("select distinct epithet from name_parts where name_id in (#{key.join(",")})")
          if epithets.size == 1
            value[:type] = :chresonym
          else
            value[:type] = :lexical_variant
          end
        else
          value[:type] = :homotypic
        end
      end
      matches
    end
  end
end
