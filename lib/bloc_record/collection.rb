module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(num))
      self.any? ? self.first.class.take(num) : false
    end

    def where(arg)
      self.any? ? self.first.class.where(arg) : false
    end

    def not(*arg)
      expression = nil;

      case args.first
      when String
        expression = args.first.split("=").join("!=")
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}!=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end

      self.any? ? self.first.class.where(expression) : false
    end
  end
end
