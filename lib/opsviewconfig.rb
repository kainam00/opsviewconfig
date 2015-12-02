require 'json'
require 'opsview_rest'

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
      File.write("#{folder}/#{resource['name']}.json",JSON.pretty_generate(resource))
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
    return cleanexport
  end

  def import(type,filename=nil,folder=nil)
    resourceconfig = JSON.parse(File.read(filename))
    resourceconfig[:type] = :host
    p resourceconfig
    res = @connection.create(resourceconfig)
  end
end
