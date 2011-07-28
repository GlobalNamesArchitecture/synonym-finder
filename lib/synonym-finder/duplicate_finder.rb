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
      end
      matches
    end

    def species_epithet_duplicates(threshold_distance = 5)
      matches = {}
      @db.execute("select epithet from name_parts group by epithet having count(*) > 1").each do |epithet|
        names = @db.execute("select name_id from name_parts where epithet = ?", epithet).map {|n| n[0]}.join(",")
        require 'ruby-debug'; debugger
        data = @db.execute("select pn1.name_id, pn2.name_id, pn1.level, pn2.level from paths_names pn1 join paths_names pn2 on pn1.path_id = pn2.path_id where pn1.name_id in (#{names}) and pn2.name_id in (#{names}) and pn1.name_id != pn2.name_id") # and (pn1.level + pn2.level) < ?", threshold_distance)
        organize_data(data, matches) 
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
