require 'json'
require 'opsview_rest'


class Hash
  def sort_by_key(recursive = false, &block)
    self.keys.sort(&block).reduce({}) do |seed, key|
      seed[key] = self[key]
      if recursive && seed[key].is_a?(Hash)
        seed[key] = seed[key].sort_by_key(true, &block)
      end
      seed
    end
  end
end

class Opsviewconfig
  def initialize(config)
    # Connect to opsview and return handler
    @connection = OpsviewRest.new("http://" + config['opsviewhost'] + "/", :username => config['opsviewuser'], :password => config['opsviewpassword'])
  end

  def connection
    return @connecton
  end

  def export(resource,folder)
    res = @connection.list(:type => resource)
    # Need to parse out junk we don't need to export
    res = export_parse(res)
    res.each do |resource|
      filename = resource['name']
      filename.gsub!(/[^0-9A-Za-z.\-]/, '_')
      #puts "Exporting #{resource['name']} to #{filename}"
      Dir.mkdir(folder) unless Dir.exist?(folder)
      File.write("#{folder}/#{filename}.json",JSON.pretty_generate(resource))
    end
    return true
  end

# Function to clean up the exported object
  def export_parse(export)
    cleanexport = Array.new()
    export.each do |resource|
      resource.delete("id")
      cleanexport << resource
    end
    return cleanexport.sort_by_key(true)
  end

  def import(type,filename=nil,folder=nil)
    resourceconfig = JSON.parse(File.read(filename))
    resourceconfig[:type] = :"#{type}"
    resourceconfig[:replace] = true
    res = @connection.create(resourceconfig)
    return true
  end

  def reload()
    @connection.initiate_reload()
    return true
  end
end
