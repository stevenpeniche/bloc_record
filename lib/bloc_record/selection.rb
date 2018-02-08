require 'sqlite3'

module Selection
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      if validate_num(ids) === false
        puts 'Please enter valid id\'s'
        return
      end

      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    if validate_num(id) === false
      puts 'Please enter a valid id'
      return
    end

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    if validate_str(attribute)
      puts 'Please enter a valid attribute'
      return
    end

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sqlstrings(value)};
    SQL

    init_object_from_row(row)
  end

  def find_each(start = first.id, batch_size = all.length)
    if validate_num(start) === false || validate_num(batch_size) === false
      puts 'Please pass in valid start and batch_size arguements'
      return
    elsif start + batch_size > all.length
      puts 'Batch would exceed record count: Please change your start or batch_size'
      return
    end

    i = start
    while i <= batch_size
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{i};
      SQL
      i += 1
      yield row
    end
  end

  def find_in_batches(start = first.id, batch_size = all.length)
    if validate_num(start) === false || validate_num(batch_size) === false
      puts 'Please pass in valid start and batch_size arguements'
      return
    end

    rows = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id LIMIT #{batch_size} OFFSET #{start};
    SQL

    yield rows_to_array(rows)
  end

  def take(num=1)
    if validate_num(num)
      puts 'Please enter a valid number of entries to take'
      return
    end

    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    expression = nil

    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    order = nil

    args.map! do |arg|
      case arg
      when String
        arg
      when Symbol
        arg.to_s
      when Hash
        hash = BlocRecord::Utility.convert_keys(arg)
        hash.map {|key, value| "#{key} #{BlocRecord::Utility.sql_strings(value)}"}.first
      end
    end

    if args.count > 1
      order = args.join(", ")
    else
      order = args.first
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    joins = args.map do |arg|
      case arg
      when String
        arg
      when Symbol
        "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"
      when Hash
        hash = BlocRecord::Utility.convert_keys(arg)
        hash.map { |key, value |
          "INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id INNER JOIN #{value} ON #{value}.#{table}_id = #{table}.id"
        }.first
      end
    end

    if joins.count > 1
      joins.join(" ")
    else
      joins = joins.first
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table} #{joins}
    SQL

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

  def validate_num(value)
    if value.is_a? Numeric
      return true
    elsif value.is_a? Array
      for item in value
        if !(item.is_a? Numeric)
          return false
        end
      end
      return true
    else
      return false
    end
  end

  def validate_str(value)
    if value.is_a? String || value.is_a? Symbol
      return true
    else
      return false
    end
  end

  def method_missing(method, arg)
    # Convert method to string then use RegEx to parse out the desired attribute
    attribute = method.to_s.scan(/by_([^*]*)/).first.first.split('_').join(' ')
    value = arg

    find_by(attribute, value)
  end
end
