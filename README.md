# opsviewconfig

Simple class for import and exporting OpsView configurations as JSON. This allows them to be version controlled, if you're into that sort of thing. It uses the very excellent OpsView Rest (https://github.com/cparedes/opsview_rest).

Installation:
```bash
gem install opsview_rest
gem install opsviewconfig
```

Initialize the object
```ruby
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
