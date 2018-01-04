# opsviewconfig

Simple class for import and exporting OpsView configurations as JSON. This allows them to be version controlled, if you're into that sort of thing. It uses the very excellent OpsView Rest (https://github.com/cparedes/opsview_rest).

Installation:
```bash
gem install opsview_rest
gem install opsviewconfig
```

Initialize the object
```ruby
require 'opsviewconfig'

# configuration hash
config = { 'opsviewhost' => 'hostname.of.your.server.tld', 'opsviewuser' => 'usernametouse', 'opsviewpassword' => 'yourSuperSecretPassword' }

# Initialize the object
opsviewcfg = Opsviewconfig.new(@config)
```

Export
Takes the following arguments:
 * resource (array of strings)
 ** Possible values for resource are:
      attribute
      contact
      host
      hostcheckcommand
      hostgroup
      hosttemplate
      keyword
      monitoringserver
      notificationmethod
      role
      servicecheck
      servicegroup
      timeperiod
 * destination directory (string)
The configuration will be exported into the following directory structure: dir/<resource-type>/<resource-name>.json

```ruby
opsviewcfg.export(resource, dir)
```

Import
Takes the following arguments:
  * resource (string). Possible values are same as for export above
  * source file (string). Source json file
```ruby
opsviewcfg.import(resource, file)
```

Reload the OpsView server and apply the configuration
```ruby 
opsviewcfg.reload()
```

A more comprehensive example:
```ruby
#!/usr/bin/env ruby
require 'yaml'
require 'getoptlong'
require 'json'
require 'opsviewconfig'

#### Util Functions #####
# Simple error function
def errorexit(description)
  puts description
  exit 1
end

# Check args
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
	[ '--file', '-f', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--directory','-d', GetoptLong::REQUIRED_ARGUMENT ],
	[ '--export', '-e', GetoptLong::NO_ARGUMENT ],
	[ '--import', '-i', GetoptLong::NO_ARGUMENT ],
	[ '--resource', '-r', GetoptLong::REQUIRED_ARGUMENT ],
	[ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT ],
)

opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
script.rb [OPTION] ...

-h, --help:
   show help

-e, --export
    *EXPORT mode* -- exports OpsView configuration to JSON files

-i, --import
    *IMPORT mode* -- imports OpsView configuration from JSON files.
    IMPORTANT: OpsView will be reloaded after the operation is complete, applying all of currently unapplied changes.

-r, --resource
    Specify resources to import/export. This option does different things depending on mode:
      export mode - optional, will export everything if not spefied
      import mode - required, will import JSON as specified resource type. Choosing wrongly may cause undesired behavior.

    Possible values are:
      attribute
      contact
      host
      hostcheckcommand
      hostgroup
      hosttemplate
      keyword
      monitoringserver
      notificationmethod
      role
      servicecheck
      servicegroup
      timeperiod

-f, --file
    *import mode only*
      Specify the full or relative path to the source JSON file to be imported.
      Cannot be used if --directory is specified.

-d, --directory
    Cannot be used if --file is specified.
    This option acts as a source or destination, depending on whether import or export mode is being used.
    *Import mode*
      The directory must contain json files of for the resources specified by the "resource" option.
    *Export mode*
      Subdirectories will be created in this directory for each different resource. The .json files named <resource-name>.json will be placed into those subdirectories.

-c, --config
    Configuration for the OpsView server connection in the following YAML format:
      opsviewhost: hostname.of.opsview.summon.pqe
      opsviewuser: username
      opsviewpassword: password

      EOF
      exit 0
    when '--file'
      @file = arg
    when '--directory'
      @directory = arg
    when '--export'
      @mode = 'export'
    when '--import'
      @mode = 'import'
    when '--resource'
      @resource = arg
		when '--config'
      @config = YAML.load(File.read(arg))
  end
end

# Do some parsing of the mode specific arguments
if @mode == 'import'
  if @directory && @file
    errorexit("Cannot specify both --file and --directory. Please see --help")
  end
  errorexit("--resource required for import mode. Please see --help") if @resource.nil?
  errorexit("--directory or --file is required. Please see --help") if @directory.nil? && @file.nil?
elsif @mode == 'export'
  errorexit("--file invalid for export mode. Please see --help") if @file
  if @resource.nil?
    @resource = [ "attribute","contact","host","hostcheckcommand","hostgroup","hosttemplate","keyword","monitoringserver","notificationmethod","role","servicecheck","servicegroup", "timeperiod" ]
  end
else
  errorexit("Invalid mode: #{@mode}, you need to specify --export or --import. Please see --help")
end

# Init the object / connect to opsview
opsviewcfg = Opsviewconfig.new(@config)

# Export mode
if @mode == 'export'
  if @resource.kind_of?(String)
    @resources = [ @resource ]
  elsif @resource.kind_of?(Array)
    @resources = @resource
  else
    errorexit("Invalid resource variable type. Maybe see --help ?")
  end

  @resources.each do |resource|
    puts "Working on #{resource}"
    dir = "./#{@directory}/#{resource}"
    Dir.mkdir(dir) unless Dir.exist?(dir)
    opsviewcfg.export(resource, dir)
  end

# Import mode
elsif @mode == 'import'
  # Directory import mode
  if @directory
    Dir.chdir(@directory) do
      Dir["*.json"].each do |file|
        puts "Importing #{@directory}/#{file} of type #{@resource}"
        opsviewcfg.import(@resource, file)
      end
    end
  # File import mode
  elsif @file
    puts "Importing #{@file} of type #{@resource}"
    opsviewcfg.import(@resource, @file)
  end
  puts "Reloading OpsView. Hold on to your butts!"
  opsviewcfg.reload()
end
```
