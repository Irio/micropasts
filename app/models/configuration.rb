class Configuration < ActiveRecord::Base
  validates_presence_of :name
  class << self
    # This method returns the values of the config simulating a Hash, like:
    #   Configuration[:foo]
    # It can also bring Arrays of keys, like:
    #   Configuration[:foo, :bar]
    # ... so you can pass it to a method using *.
    # It is memoized, so it will be correctly cached.
    def [] *keys
      if keys.size == 1
        get keys.shift
      else
        keys.map{|key| get key }
      end
    end

    def fetch(key)
      find_by!(name: key).value
    rescue ActiveRecord::RecordNotFound
      raise "No \"#{key}\" configuration defined."
    end

    def []= key, value
      set key, value
    end
    private

    def get key
      find_by(name: key).try(:value)
    end

    def set key, value
      begin
        find_by_name(key).update_attribute :value, value
      rescue
        create!(name: key, value: value)
      end
      Rails.cache.write("/configurations/#{key}", value)
      value
    end

  end
end
