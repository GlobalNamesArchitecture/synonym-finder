class SynonymFinder
  class GroupOrganizer

    def initialize(synonym_finder)
      @synonym_finder = synonym_finder
      @db = @synonym_finder.db
      @groups = {}
    end

    # Finds duplication groups for a name. A name can be one or more duplication groups: chresonym, lexical variant, homotypic, alt placement
    def organize
      @last_id = 1
      @synonym_finder.matches.each do |key, value|
        gr1 = get_group(key[0], value[:type])
        gr2 = get_group(key[1], value[:type])
        if gr1 && gr2 
          update_group(gr1, gr2) if gr1 != gr2
          key.each { |name_id| update_score(name_id, value) }
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
      @db.execute("insert into groups (id, type) values (?, ?)", [@last_id, value[:type].to_s])
      key.each {|i| @groups[i] = {} unless @groups.has_key?(i) }
      score = get_score(value)
      @groups[key[0]][value[:type]] = @groups[key[1]][value[:type]] = @last_id
      @db.execute("insert into names_groups (name_id, group_id, score_max, score_sum, score_num) values (?, ?, ?, ?, 1)", [key[0], @last_id, score, score])
      @db.execute("insert into names_groups (name_id, group_id, score_max, score_sum, score_num) values (?, ?, ?, ?, 1)", [key[1], @last_id, score, score])
      @last_id += 1 
    end

    def update_group(gr1, gr2)
      @db.execute("update names_groups set group_id = ? where group_id = ?", [gr1, gr2])
      @db.execute("delete from groups where id = ?", gr2)
    end

    def add_to_group(key, value)
      gr1 = get_group(key[0], value[:type])
      gr2 = get_group(key[1], value[:type])
      name_id1, name_id2, group_id = gr1 ? [key[1], key[0], gr1] : [key[0], key[1], gr2]
      update_score(name_id2, value)
      score = get_score(value)
      @groups[name_id1] = {} unless @groups.has_key?(name_id1)
      @groups[name_id1][value[:type]] = group_id
      @db.execute("insert into names_groups (name_id, group_id, score_max, score_sum, score_num) values (?, ?, ?, ?, 1)", [name_id1, group_id, score, score])
    end

    def update_score(name_id, value)
      score = get_score(value)
      group_id = get_group(name_id, value[:type])
      @db.execute("update names_groups set score_max = max(score_max, ?),  score_sum = score_sum + ?, score_num = score_num + 1 where name_id = ? and group_id = ?", [score, score, name_id, group_id])
    end

    def get_score(value)
      return 100 if value[:type] == :chresonym
      return 10  if value[:alt_placement] && value[:total_length] > 8
      score = value[:auth_match]
    end
    
  end
end
