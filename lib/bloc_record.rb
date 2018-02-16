module BlocRecord
  def self.connect_to(filename, db)
    @database_filename = filename
    @database_platform = db
  end

  def self.database_filename
    @database_filename
  end

  def self.database_platform
    @database_platform
  end
end
