class SynonymFinder
  class GroupOrganizer

    def initialize(synonym_finder)
      @synonym_finder = synonym_finder
      @db = @synonym_finder.db
      @groups = {}
      @matches = @synonym_finder.matches
    end

    # Finds duplication groups for a name. A name can be one or more duplication groups: chresonym, lexical variant, homotypic, alt placement
    def organize
      @last_id = 1
      @matches.each do |key, value|
        gr1 = get_group(key[0], value[:type])
        gr2 = get_group(key[1], value[:type])
        if gr1 && gr2 
          update_group(gr1, gr2) if gr1 != gr2
          update_scores(key, value)
        elsif !gr1 && !gr2
          create_group(key, value)
        else
          add_to_group(key, value)
        end
      end
    end

    private

    def get_group(name_id, type)
      return nil unless @groups[name_id]
      @groups[name_id][type]
    end

    def create_group(key, value)
      @db.execute("insert into groups (id, type) values (?, ?)", [@last_id, type)
      key.each {|i| @groups[i] = {} unless defined?(@groups[i]) }
      score = get_score(value)
      groups[key[0]][value[:type]] = groups[key[1]][value[:type]] = @last_id
      @db.execute("insert into names_groups (group_id, name_id, score, score_num) values (?, ?, ?, 1)", [key[0], @last_id, score])
      @db.execute("insert into names_groups (group_id, name_id, score) values (?, ?, ?, 1)", [key[1], @last_id, score])
      @last_id += 1 
    end

    def update_group(gr1, gr2)
      @db.execute("update names_groups set group_id = ? where group_id = ?", [gr1, gr2])
      @db.execute("delete from groups where id = ?", gr2)
    end

    def add_to_group(key, value)
      gr1 = get_group(key[0], value[:type])
      gr2 = get_group(key[1], value[:type])
      name_id, group_id = gr1 ? [key[1], gr1] : [key[0], gr2]
      @groups[name_id] = {} unless defined?(@groups[name_id])
      @groups[name_id][value[:type]] = group_id
      @db.execute("insert into names_groups (group_id, name_id, score, score_num) values (?, ?, ?, 1)", [name_id, group_id, get_score(value)])
    end

    def update_scores(key, value)
      score = get_score(value)
      group_id = get_group(key[0], value[:type])
      key.each do |name_id|
        @db.execute("update names_groups set score_max = max(score, ?),  score_average = score_average + ?, score_num = score_num + 1 where name_id = ? and group_id = ?", [score, score, name_id, group_id])
      end
    end

    def get_score(value)
      
    end
    
  end
end

__END__
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
    end

    
  end
end
