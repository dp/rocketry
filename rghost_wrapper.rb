# wrapper for the pdf library we choose

require 'rubygems'
require 'rghost'


class PDF
  def initialize filename
    @filename= filename
    # keep a track of fonts defined (just their names)so we can add new ones
    @fonts= []
    RGhost::Config::GS[:path]= '/opt/local/bin/gs'
    RGhost::Config::GS[:unit]= RGhost::Units::Cm
    # Additional Fonts
    # RGhost::Config::GS[:extensions] << '/Users/sharon/Documents/Dave/ruby/multidose/fonts'
    
    @pdf= RGhost::Document.new
    if block_given?
      yield self 
      save
    end
    self
  end
  
  def save
    @pdf.render :pdf , :filename=> @filename
  end
  
  # RGhost requires all fonts be defines as tags
  def add_font font
    unless @fonts.include? font.tag
      @pdf.define_tags do 
        tag font.tag, 
            :name => font.name, 
            :size => font.size,
            :color=> font.colour
      end

      @fonts << font.tag
    end
  end
  
  def text value, x, y, params={}
    add_font params[:font] if params[:font]
    @pdf.moveto :x=> x.cm, :y=> y.cm
    align= case params[:align]
      when :left   then :show_left
      when :centre then :show_center
      when :right  then :show_right
    end
    @pdf.show value, :align=> align , :with=> params[:font].tag
  end
  
  def rect x, y, w, h, params={}
    border_colour= params[:border_colour] || '#000000'
    fill_colour=   params[:fill_colour]
    content= fill_colour ? {:color=> fill_colour} : {:fill=> false}
    @pdf.frame :x      => x.cm,
               :y      => y.cm,
               :width  => w.cm,
               :height => h.cm,
               :border => {:color=> border_colour},
               :content=> content
  end
end

