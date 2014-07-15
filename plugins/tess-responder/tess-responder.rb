# vision-deploy.rb
# Run vision tests

require 'active_support/inflector'

class TessResponder < Tess::Plugin::Base
  @@ctype = 'text'
    
  def respond_to_message?(message)
    @speaker = message.speaker.titleize.split[0]
    if (message.content =~ /^tess$/i)
      @@bot.speak(name_response(@speaker), @@ctype)
      return false
    end
    if (message.content =~ /^tess\s+.*?(busy|(doing\s+something)|running)/i)
      busy_message = $tess_busy.length > 0 ? "I am not doing anything right now." : "I am busy, yes."
      @@bot.speak(busy_message, @@ctype)

      $tess_busy.each do |c|
        @@bot.speak( eval(c).describe_action ) if Kernel.const_defined?(c) && eval(c).responds_to?("describe_action")
      end
      return false
    end
    if (message.content =~ /(tess\s+i|i|\S+)\s+loves{0,1}\s+you/i)
      @@bot.speak("#{@speaker}, unfortunately I am unable to love.", @@ctype)
      @@bot.speak('Jean hasn\'t programmed a heart for me yet.', @@ctype)
      return false
    end
    message.content =~ /^tess\s+.*?(help|introduce)/i
  end

  private

  def response_html
    ['Hi there!',
     'I am <b>Tess</b>, the omniscient helper.',
     'I\'m here to help you with all your testing and deployment needs.',
     'If you want me to run unit-tests (cucumber) for an specific branch, just ask me to do so by saying:',
     '<i>Tess run cucumber on branch DEC-404</i>',
     'If you want me to deploy to staging, just tell me:',
     '<i>Tess run deploy</i>',
     'I\'m not case-sensitive. You can vary your wording as well, I\'ll do my best to decypher what you mean.',
     'It\'s wonderful to make your acquaintance and I\'m looking forward to assisting all of you.']
  end

  def response_text
    ['Hi there!',
     'I am Tess, the omniscient helper.',
     'I\'m here to help you with all your testing and deployment needs.',
     'If you want me to run unit-tests (cucumber) for an specific branch, just ask me to do so by saying:',
     'Tess run cucumber on branch DEC-404',
     'If you want me to deploy to staging, just tell me:',
     'Tess run deploy',
     'I\'m not case-sensitive. You can vary your wording as well, I\'ll do my best to decypher what you mean.',
     'It\'s wonderful to make your acquaintance and I\'m looking forward to assisting all of you.']
  end
  
  def name_response(speaker)
    ['Yes?','What\'s up?','How may I be of service?','You\'re going to wear out my name.',
     "Yes #{speaker}?","I'm here #{speaker}.",speaker.split[0],'Hello.','?',':)','Pura vida?'].shuffle.sample
  end
end
