require 'yaml'

def merge_config(obj1, obj2)
  obj1.merge!(obj2) do |key, oldval, newval|
    if oldval.nil?
      newval
    elsif newval.nil?
      oldval
    elsif newval.is_a?(Array) || newval.is_a?(Hash)
      oldval | newval
    else 
      newval
    end
  end
end

def load_config(files)
  #puts "loading config #{files}"


  result = {}
  files.each do |config_file|
    if File.exist?(config_file)
      config = YAML.load_file(config_file)
      if config

        if config["include"]
          included = load_config(config["include"])
          merge_config(config, included)
       end
       merge_config(result, config)
      end
    end
  end

  result
end
