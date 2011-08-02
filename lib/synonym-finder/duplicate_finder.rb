class SynonymFinder
  class DuplicateFinder

    def initialize(synonym_finder)
      @db = synonym_finder.db
    end

    def canonical_duplicates
      matches = {}
      canonical_name_ids = []
      @db.execute("select canonical from name_parts group by canonical having count(*) > 1").each do |canonical|
        names = @db.execute("select name_id from name_parts where canonical = ?", canonical).map {|n| n[0]}
        canonical_name_ids += names
        names = names.join(",")
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id")
        organize_data(data, matches)
        matches.each do |key, value|
          if value[:total_distance] == 0
            value[:type] = :chresonym
          else
            value[:type] = :alt_placement
          end
        end
      end
      matches
    end

    def species_epithet_duplicates(threshold_distance)
      matches = {}
      @db.execute("select epithet_stem from name_parts group by epithet_stem having count(*) > 1").each do |stem|
        names = @db.execute("select name_id from name_parts where epithet_stem = ?", stem).map {|n| n[0]}.join(",")
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id") # and (pn1.level + pn2.level) < ?", threshold_distance)
        organize_data(data, matches) 
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

    private
    
    def organize_data(data, matches)
      data.each do |datum|
        ids = datum[0..1].sort
        distances = (ids == datum[0..1]) ? datum[-2..-1] : datum[-2..-1].reverse
        total_distance = datum[-2] + datum[-1]
        if !matches[ids] || matches[ids][:total_distance] > total_distance
          matches[ids] = { :distances => distances, :total_distance => total_distance }
        end
      end
    end

  end
end
