# vision-deploy.rb
# Run vision tests

require 'active_support/inflector'

class TessResponder < Tess::Plugin::Base
  @@ctype = 'text'
    
  def respond_to_message?(message)
    @speaker = message.speaker.titleize.split[0]
    if (message.content =~ /^tess$/i)
      @@bot.speak(name_response(message.speaker), @@ctype)
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