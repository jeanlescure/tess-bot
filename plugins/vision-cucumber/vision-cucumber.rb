# vision-cucumber.rb
# Run vision tests

require 'active_support/inflector'

class VisionCucumber < Tess::Plugin::Base
  @@run_cucumber = false
  @@branch = false
  @@room = nil
  @@ctype = 'text'
  
  def initialize(bot)
    Thread.abort_on_exception = true
    start_thread
    super(bot)
    @@result = "http://#{@@bot.config['host']}/cucumber/"
  end
  
  def start_thread
    @vc_thread = Thread.new {
      loop do
        if @@run_cucumber
          result = `cd #{@@bot.config['cucumber_dir']} && git checkout master && git pull && git checkout #{@@branch}`
          if $?.to_i == 0
            Bundler.with_clean_env do
              result = `cd #{@@bot.config['cucumber_dir']} && git checkout master && git pull && git checkout #{@@branch} && git pull && cucumber 2>&1`
              @@result = "cucumber/#{Time.now().to_i}.html"
              File.open("tmp/#{@@result}", 'w') { |file| file.write("<pre>#{result}</pre>") }
            end
            result =~ /\d\d scenarios \([\s\S]*/i
            pre_result = "#{@@run_cucumber}, these are your results for branch #{@@branch}:"
            pre_result = (@@ctype == 'html') ? "<b>#{pre_result}</b>" : pre_result
            @@bot.speak("#{pre_result}<pre>\r\n#{$&}</pre>",@@ctype)
            @@run_cucumber = false
            @@branch = false
            @@result = "http://#{@@bot.config['host']}/#{@@result}"
          else
            @@bot.speak("Branch #{@@branch} does NOT exist!",@@ctype)
            @@run_cucumber = false
            @@branch = false
          end
        else
          sleep 5
        end
      end
    }
  end
  
  def respond_to_message?(message)
    @speaker = message.speaker.titleize.split[0]
    if (message.content =~ /^tess\s+.*?(last|full)\s+(tests{0,1}|cucumber)/i)
      last_result = "#{@speaker}, you can view the last cucumber results at:\r\n"
      last_result = (@@ctype == 'html') ? "#{last_result}<a href=\"#{@@result}\">#{@@result}</a>" : "#{last_result}#{@@result}"
      @@bot.speak(last_result, @@ctype)
      return false
    end
    if (message.content =~ /^tess\s+.*?(kill|stop|terminate)\s+(tests{0,1}|cucumber)/i)
      @@run_cucumber = false
      @@branch = false
      Bundler.with_clean_env do
        `pkill -KILL -f \`which cucumber\``
      end
      @@result = "Cucumber killed as per #{message.speaker}'s request!"
      Thread.kill(@vc_thread)
      @@bot.speak(@@result, @@ctype)
      start_thread
      return false
    end
    if (message.content =~ /branch\s+([a-zA-Z0-9\-_]+)/i && !@@run_cucumber)
      @@branch = $&.split[1]
    end
    message.content =~ /^tess\s+.*?((run\s+)|)(tests{0,1}|cucumber)/i
  end

  private

  def response_html
    return ["<b>Sorry #{@speaker}, you must specify a branch for me to #{dance}.</b>",
            "<i>e.g.:</i> tess run cucumber on branch DEC-404"] unless @@branch
    return ["<b>#{@speaker}, your request to test cannot be processed until I finish the test initiated by #{@@run_cucumber}.</b>",
            "(You can, alternatively, ask me to terminate the current test by typing: <i>tess kill cucumber</i>)"] unless !@@run_cucumber
    @@ctype = 'html'
    @@run_cucumber = @speaker
    ["#{aye} #{@speaker}!","<b>Running tests on @branch '#{@@branch}'</b>"]
  end

  def response_text
    return ["Sorry #{@speaker}, you must specify a branch for me to #{dance}.",
            "e.g.: tess run cucumber on branch DEC-404"] unless @@branch
    return ["#{@speaker}, your request to test cannot be processed until I finish the test initiated by #{@@run_cucumber == @speaker ? 'you' : @@run_cucumber}.",
            "(You can alternatively ask me to terminate the current test by typing: tess kill cucumber)"] unless !@@run_cucumber
    @@ctype = 'text'
    @@run_cucumber = @speaker
    ["#{aye} #{@speaker}!","Running tests on @branch '#{@@branch}'"]
  end
  
  def dance
    ['tango','do the cha cha','salsa','bounce to techno','do the twist','disco',
     'dance the dance','shake my bom bom','feel the mambo'].shuffle.sample
  end
  
  def aye
    ['Aye aye Cap\'n','You got it','Sure thing','With pleasure','Right away','You don\'t have to ask me twice',
     'I was coded for this','I was afraid you\'d never ask','Took you long enough'].shuffle.sample
  end
end
