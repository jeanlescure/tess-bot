module Tess
  class Language
    def aye
      ['Aye aye Cap\'n','You got it','Sure thing','With pleasure','Right away','You don\'t have to ask me twice',
       'I was coded for this','I was afraid you\'d never ask','Took you long enough'].shuffle.sample
    end

    def dance
      ['tango','do the cha cha','salsa','bounce to techno','do the twist','disco',
       'dance the dance','shake my bom bom','feel the mambo'].shuffle.sample
    end

    def enumerate items
      case items.length
        when 1 then items.first
        when 2..Float::INFINITY then "#{items[0..-2].join ", "} and #{items[-1]}"
      end 
    end
  end
end
