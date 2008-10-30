class PrintFont
  attr_accessor :tag, :name, :size, :colour, :bold, :italic
  
  def initialize tag, params
    @tag=    tag
    @name=   params[:font]   || '/Library/Fonts/Trebuchet MS.ttf' #'Times-Roman' #'Palatino-Roman'#  'Lucida-Grande'
    @size=   params[:size]   || 9 
    @colour= params[:colour] || '#000000' # black
    @bold=   params[:bold]   || false
    @italic= params[:italic] || false
  end
end

class FontCollection
  def initialize
    @fonts= {}
  end
  
  def add font_name, params= {}
    @fonts[font_name]= PrintFont.new(font_name, params)
  end
  
  def method_missing font_name
    if @fonts[font_name]
      @fonts[font_name]
    else
      raise "No such font '#{font_name}'"
    end
  end
  
  def to_a
    @fonts.values
  end
end
