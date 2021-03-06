# vision-deploy.rb
# Run vision tests

require 'active_support/inflector'

class VisionDeploy < Tess::Plugin::Base
  @@run_deploy = false
  @@room = nil
  @@ctype = 'text'
  
  def initialize(bot)
    Thread.abort_on_exception = true
    start_thread
    super(bot)
    @@result = "http://#{@@bot.config['host']}/deploy/"
  end

  def cap_command
    case @@action 
      when "deploy" then "cap #{ @@server } -sbranch=\"#{ @@branch }\" deploy"
      when "restart" then "cap #{ @@server } deploy:restart"
    end
  end
  
  def self.describe_action
    case @@action
      when 'deploy' then "Deploying #{ @@branch } to #{ @@server }."
      when 'restart' then "Restarting #{@@server}"
    end
  end
  
  def start_thread
    @vc_thread = Thread.new {
      loop do
        if @@run_deploy
          result = ''
          Bundler.with_clean_env do
            $tess_busy << self.class
            result = `cd #{@@bot.config['deploy_dir']} && git checkout #{@@branch}; git pull && eval \`ssh-agent -s\` && ssh-add ~/.ssh/id_dsa && #{ cap_command } 2>&1`.chomp
            $tess_busy.delete self.class
	    @@result = "deploy/#{Time.now().to_i}.html"
            File.open("tmp/#{@@result}", 'w') { |file| file.write("<pre>#{result}</pre>") }
          end
          # result =~ /sftp download complete$/i
          if ($?.success?)
            pre_result = "#{@@run_deploy}'s #{@@action} task completed successfully!"
            pre_result = (@@ctype == 'html') ? "<b>#{pre_result}</b>" : pre_result
            @@bot.speak("#{pre_result}",@@ctype)
          else
            pre_result = "#{@@run_deploy}, I failed to #{ @@action }. :("
            pre_result = (@@ctype == 'html') ? "<b>#{pre_result}</b>" : pre_result
            @@bot.speak("#{pre_result}",@@ctype)
          end
          @@run_deploy = false
          @@result = "http://#{@@bot.config['host']}/#{@@result}"
        else
          sleep 5
        end
      end
    }
  end
  
  def respond_to_message?(message)
    available_servers = [ 'dev', 'staging', 'production', 'testing' ]
    @speaker = message.speaker.titleize.split[0]
    if (message.content =~ /^tess\s+.*?(last|full)\s+deploy/i)
      last_result = "#{@speaker}, you can view the last deployment results at:\r\n"
      last_result = (@@ctype == 'html') ? "#{last_result}<a href=\"#{@@result}\">#{@@result}</a>" : "#{last_result}#{@@result}"
      @@bot.speak(last_result, @@ctype)
      return false
    end
    if (message.content =~ /^tess\s+.*?(kill|stop|terminate)\s+deploy/i)
      @@run_deploy = false
      Bundler.with_clean_env do
        `pkill -KILL -f \`which cap\``
      end
      Thread.kill(@vc_thread)
      $tess_busy.delete self.class
      @@bot.speak("Deployment process killed as per #{message.speaker}'s request!", @@ctype)
      start_thread
      return false
    end
    @@branch = $1 if ! @@run_deploy && message.content =~ /^tess.* (?:version|branch) ([a-zA-Z0-9\-_]+)/i
    @@server = $1 if ! @@run_deploy && message.content =~ /^tess.* (?:to|into|restart) (#{ available_servers.join "|" })/i
    @@action = $1 if ! @@run_deploy && message.content =~ /^tess\s+.*?(?:(?:run\s+)|)(deploy|restart)/

    @@branch ||= 'master'
    @@server ||= 'staging'
    @@action ||= 'deploy'

    message.content =~ /^tess\s+.*?((run\s+)|)(?:deploy|restart)/i
  end

  private

  def response_html
    return ["<b>#{@speaker}, your request to deploy to staging cannot be processed until I finish the deployment initiated by #{@@run_deploy == @speaker ? 'you' : @@run_deploy}.</b>",
            "(You can, alternatively, ask me to terminate the current deployment by typing: <i>tess kill deploy</i>)"] unless !@@run_deploy
    @@ctype = 'html'
    @@run_deploy = @speaker
    ["#{aye} #{@speaker}!","<b>#{ VisionDeploy.describe_action }</b>"]
  end

  def response_text
    return ["#{@speaker}, your request to deploy to staging cannot be processed until I finish the deployment initiated by #{@@run_deploy}.",
            "(You can alternatively ask me to terminate the current deployment by typing: tess kill deploy)"] unless !@@run_deploy
    @@ctype = 'text'
    @@run_deploy = @speaker
    ["#{aye} #{@speaker}!","#{ VisionDeploy.describe_action }"]
  end
  
  def aye
    ['Aye aye Cap\'n','You got it','Sure thing','With pleasure','Right away','You don\'t have to ask me twice',
     'I was coded for this','I was afraid you\'d never ask','Took you long enough'].shuffle.sample
  end
end
