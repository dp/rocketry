# all measurements assumed in milimetres unless stated
# 
# any printable object needs to implement:
#   def print pdf, x=0, y=0, data= nil
#      (prints this object to supplied pdf at position x,y)
#      
#   def height 
#      (returns height of this object)
#


#-------------------------------------------------------------------------------
class Numeric
  def cm() self.to_f/10      end
  def mm() self              end
  def pt() self.to_f/72*25.4 end
end

#-------------------------------------------------------------------------------
class PrintObject
  attr_accessor :left, :base, :width, :height, :print_check
  
  def initialize params={}
    @left=   params[:left]  || 0
    @base=   params[:base]  || 0
    @width=  params[:width] || 0
    @height= params[:height]|| 0
    @print_check= params[:print_check] || true
  end
  
  def print_object? data
    return false unless print_check
    return print_check.call(data) if print_check.class== Proc
    true
  end
  
  def print pdf, offset_x=0, offset_y=0, data=nil
    if data || !hide_if_empty?
      pdf.rect offset_x+ left, offset_y+ base, width, height
    end
  end
  
  def get_data field, data=nil
    return data if field.nil?
    return field.call(data) if field.class== Proc
    return field if data.nil? || field.class!= Symbol
    return data[field] if data.class== Hash
    return data if data.class== String
    return data if data.class== Array

    data.send(field) 
  end
end

#-------------------------------------------------------------------------------
class PrintImage < PrintObject
  def initialize image, params
    super params
    @image= image
    @height= 1.333* width if height== 0
  end
end

#-------------------------------------------------------------------------------
class PrintShape < PrintObject
  def initialize shape_type, params
    super params
    @shape_type= shape_type
    @border_colour= params[:border_colour]
    @fill_colour=   params[:fill_colour]
  end

  def print pdf, offset_x=0, offset_y=0, data=nil
    pdf.rect offset_x+ left, offset_y+ base, width, height,
             :border_colour=> @border_colour,
             :fill_colour=>   @fill_colour
  end
end
  
#-------------------------------------------------------------------------------
class PrintText < PrintObject
  attr_accessor :text, :font, :align
  def initialize text, font, params={}
    super params
    @text, @font, @align = text, font, params[:align] || :left
  end
  
  def print pdf, offset_x=0, offset_y=0, data= nil
    if print_object? data
      pdf.text get_data(text, data), 
               offset_x+ left, 
               offset_y+ base, 
               :font=>   font,
               :align=>  align
    end
  end
  
  def height
    font.size.pt
  end
end

#-------------------------------------------------------------------------------
class PrintArea < PrintObject
  attr_accessor :cursor_x, :cursor_y
  
  def initialize width, height, params={}, &block
    super params.merge({:width=> width, :height=> height})
    @cursor_x= 0
    @cursor_y= @height
    @default_font= nil
    @default_align= :left
   
    @children= []

    self.instance_eval &block unless block.nil?
    return self
  end
  
  def text value, params={}
    new_text= PrintText.new(value,
                            params[:font] || @default_font,
                            :left=>  params[:left] || @cursor_x,
                            :base=>  params[:base] || @cursor_y,
                            :width=> params[:width],
                            :align=> params[:align]|| @default_align)
    @children << new_text
    @cursor_x= params[:left] if params[:left]
    if params[:base]
      @cursor_y= params[:base]
    else
      new_text.base-= new_text.height
      @cursor_y= new_text.base
    end
  end
  
  def shape shape_type, params
    @children << PrintShape.new(shape_type, params)
  end
  
  def top
    @cursor_y= @height
  end
  
  def font new_font
    @default_font= new_font
  end
  
  def image image, params
    @children << PrintImage.new(image, params)
  end
  
  def align new_align
    @default_align= new_align
  end

  def print pdf, offset_x=0, offset_y=0, data= nil
    if print_object? data
      @children.each{|child| child.print pdf, offset_x+left, offset_y+base, data}
    end
  end
  
  def height
    @height
  end
  
  def add print_object, params
    #uses params to set attribute values for print_object
    params.each do |field, value| 
      print_object.send "#{field}=".to_sym, value
    end
    @children << print_object
  end
end

#-------------------------------------------------------------------------------
class PrintGrid < PrintObject
#  :columns=>  2,
#  :rows=>     4,
#  :data=>     :pack_drugs,
#  :contents=> pack_drug
  def initialize params
    super params
    @width= params[:width]
    @height=params[:height]
    @cols= params[:columns] || 1
    @rows= params[:rows]    || 1
    @data= params[:data]
    @draw= params[:contents]|| PrintShape.new(:rect, :width=> width, :height=> height)
    @col_gap= params[:col_gap] || 0
    @row_gap= params[:row_gap] || 0
    
    if params[:width] && @cols> 1
      @col_gap= (@width-@cols*@draw.width)/ (@cols-1)
    else
      @width= @cols* @draw.width+ (@cols-1)* @col_gap
    end

    if params[:height] && @rows> 1
      @row_gap= (@height-@rows*@draw.height)/ (@rows-1)
    else
      @height= @rows* @draw.height+ (@rows-1)* @row_gap
    end
  end
  
  def print pdf, offset_x=0, offset_y=0, data=nil
    get_data(@data, data).each_with_index do |cell_data, i|
      # deliberately not checking that item count <= grid cells
      # ifto many will print extra which will then be obvious on stickers
      # instead of silently failing
      
      # fill by columns
      col= i/@rows
      row= i%@rows
      cell_left= col* (@draw.width+ @col_gap)
      cell_base= @height- @draw.height- (row* (@draw.height+ @row_gap))
  
      @draw.print pdf, offset_x+ left+ cell_left, 
                       offset_y+ base+ cell_base, 
                       cell_data
    end
  end
  
end

