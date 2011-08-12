class SynonymFinder
  class GroupOrganizer

    def initialize(synonym_finder)
      @synonym_finder = synonym_finder
      @db = @synonym_finder.db
      @groups = {}
    end

    # Finds duplication groups for a name. A name can be one or more duplication groups: chresonym, lexical variant, homotypic, alt placement
    def organize
      SynonymFinder.logger_write(@synonym_finder.object_id, "Grouping results")
      organize_matches
      #organize_partial_matches
      get_output
    end

    private

    def organize_matches
      @last_id = 1
      count = 0
      @synonym_finder.matches.each do |key, value|
        count += 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Grouping match %s" % count) if count % 10000 == 0
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

    def organize_partial_matches
      added = {}
      count = 0
      @synonym_finder.part_matches.each do |key, value|
        count += 1
        SynonymFinder.logger_write(@synonym_finder.object_id, "Adding partial matches %s" % count) if count % 10000 == 0
        gr1 = get_group(key[0], value[:type])
        gr2 = get_group(key[1], value[:type])
        if  gr1 || gr2
          group_id, name_id, name_id_db = gr1 ? [gr1, key[1], key[0]] : [gr2, key[0], key[1]] #name without authorship
          unless added[name_id] && added[name_id][name_id_db]
            score = get_score(value)
            @db.execute("insert into names_groups (name_id, group_id, score_max, score_sum, score_num) values (?, ?, ?, ?, 1)", [name_id, group_id, score, score])
            added[name_id] = { name_id_db => 1 }
          end
        else
          create_group(key, value)
        end
      end
    end

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

    def get_output
      data = @db.execute("select x.group_id, g.type, ng.name_id from (select group_id from names_groups group by group_id order by count(*), group_id) x join names_groups ng on x.group_id = ng.group_id join names n on n.id = ng.name_id join groups g on g.id = ng.group_id")
      group = 0
      res = []
      current_group = nil
      data.each do |group_id, type, name_id|
        if group_id != group
          res << current_group if current_group
          group = group_id
          current_group = { :type => type, :name_ids => [name_id] }
        else
          current_group[:name_ids] << name_id
        end
      end
      res
    end

  end
end
