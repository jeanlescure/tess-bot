# Tess
### Chat bot for HipChat and Campfire

### Features
- HipChat and Campfire support
- Supports both HTML output (through API) and room presence & text output (through XMPP) in HipChat
- Multi-room support
- Plugin support, see Plugins wiki page for writing new plugins
- Comes with many plugins with which to entertain yourself

### Requirements
- Ruby 1.9+

### Setup
1. Clone repository
1. Run `bundle install` to install dependencies
1. Copy `config.yml.example` to `config.yml`
1. Edit `config.yml` to include your HipChat or Campfire credentials, and
   choose plugins to enable
1. Launch Tess in foreground:  
    `bin/tess`  
   or launch daemonized:  
    `bin/tess-daemon start`