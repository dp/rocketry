# wrapper for the pdf library we choose
# assumes all measurements in points (1/72")

require 'rubygems'
require 'prawn'


class PDF
  def initialize filename
    @filename= filename
    # keep a track of fonts defined (just their names)so we can add new ones
    @fonts= []
    Prawn::Document.new :page_size=> 'A4',
                        :top_margin=> 0,
                        :bottom_margin=> 0,
                        :left_margin=> 0,
                        :right_margin=> 0 do |pdf|
      @pdf= pdf
      if block_given?
        yield self 
        save
      end
    end
    self
  end
  
  def save
    @pdf.render_file @filename
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
    #add_font params[:font] if params[:font]
    #@pdf.moveto :x=> x.cm, :y=> y.cm
    align= case params[:align]
      when :left   then :left
      when :centre then :center
      when :right  then :right
    end
    @pdf.fill_color= (params[:font].colour || 'ffffff').gsub('#','')
    @pdf.font params[:font].name
    @pdf.bounding_box [x.to_pt, y.to_pt+ params[:font].size], :width=> params[:width].to_pt do
      @pdf.text value, #:at=> [0,0],# [x, y], 
                       :align=> align, 
                       :size=> params[:font].size
    end
  end
  
  def rect x, y, w, h, params={}
    border_colour= params[:border_colour] || '#B0B0B0'
    fill_colour=   params[:fill_colour]
    @pdf.line_width=1
    @pdf.stroke_color= border_colour.gsub('#','') 
    if fill_colour
      @pdf.fill_and_stroke do
        @pdf.fill_color= fill_colour.gsub('#','')
        @pdf.rectangle [x.to_pt, (y+h).to_pt], w.to_pt, h.to_pt
      end
    else
      @pdf.stroke do
        @pdf.rectangle [x.to_pt, (y+h).to_pt], w.to_pt, h.to_pt
      end
    end
  end

  def image filename, x, y, w, h
    filename= File.join('/Users/sharon/Desktop/multidose packs', filename)
    target_proportion= w.to_f/ h
    # can't seem to get image width without printing to page,
    # so we'll print off page and then get measurements
    temp_img= @pdf.image filename, :at=> [0, -10], :width=> w.to_pt

    image_proportion= temp_img.width.to_f/ temp_img.height

    if target_proportion> image_proportion
      @pdf.image filename,
                 :at=> [x.to_pt, (y+h).to_pt],
                 :height=> h.to_pt
    else
      @pdf.image filename,
                 :at=> [x.to_pt, (y+h).to_pt],
                 :width=> w.to_pt
    end
  end
end


