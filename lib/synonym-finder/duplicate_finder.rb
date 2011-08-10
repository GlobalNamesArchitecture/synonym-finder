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
      @matches.each do |key, value|
        if value[:total_distance] == 0
          value[:type] = :chresonym
        else
          value[:type] = :alt_placement
        end
      end
      @matches
    end

    def find_pairs(names, threshold = 0)
      pairs = get_pairs(names)
      pairs.each do |pair|
        key = [pair[0][0], pair[1][0]]
        total_distance = get_total_distance(pair[0][1], pair[1][1])
        value = {:total_distance => total_distance}
        @matches[key] = value if !@matches.has_key?(key) && (threshold == 0 || total_distance <= threshold)
      end
    end
      
    def get_total_distance(path1, path2)
      total_distance = path1.size + path2.size
      count = 0
      path1.zip(path2).each do |pair|
        break if pair[0] != pair[1]
        count += 1
      end
      total_distance - count * 2
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
