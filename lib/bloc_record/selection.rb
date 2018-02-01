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
    attribute = method[8..-1].split('_').join(' ')
    value = arg

    find_by(attribute, value)
  end
end
