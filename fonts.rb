require 'font_collection'
require 'print_area'
require 'prawn_wrapper'


#-------------------------------------------------------------------------------
fonts= FontCollection.new
fonts.add :name,
          :size=> 14
        
fonts.add :field_name,
          :colour=> '#808080'   # grey
        
fonts.add :field_data

fonts.add :shop,
          :colour=> '#000088'   # deep blue
          
fonts.add :shop_addr,
          :colour=> '#000088',  # deep blue
          :size=> 7
          
fonts.add :drug_name,
          :size=> 8

fonts.add :drug_dose,
          :colour=> '#808080',  # grey
          :size=> 8
          
fonts.add :alert_tag,
          :colour=> '#FFFFFF',  # white
          :size=> 11,
          :bold=> true
        
fonts.add :alert_msg

fonts.add :meals,
          :size=> 11,
          :bold=> true
        

#-------------------------------------------------------------------------------
shop= PrintArea.new 40, 15 do 
  font  fonts.shop
  align :right
  text  "Ross Cargill Chemist"
  text  "(08) 9451 1047"
  text  "Shop 2, Brownlie Towers", :font=> fonts.shop_addr
end

patient= PrintArea.new 100, 20 do 
  image :image, :width=> 13
  text  :name , :left=> 15, :base=> 14, :font=> fonts.name

  font  fonts.field_name
  align :right
  text  'Address',  :left=> 15, :base=> 9, :width=> 15
  text  'Area',     :width=> 15
  text  'Begin on', :width=> 15

  font  fonts.field_data
  align :left
  text  :address, :left=> 32, :base=> 9
  text  :area
  text  :begin_on
end

alert= PrintArea.new 154, 5 do
  shape :rect,   :left=> 0,   
                 :base=> 0, 
                 :width=>  self.width, 
                 :height=> self.height,
                 :border_colour=> '#307030',
                 :fill_colour=>   '#60D060'
               
  font  fonts.alert_tag
  y= 1.2
  text  '  ALERT', :base=> y
  text  'ALERT  ', :align=> :right, :base=> y
  
  text  :alert,    :align=> :centre, :base=> y,
                   :font=> fonts.alert_msg
end

pack_drug= PrintArea.new 50, 7 do
  image :drug_pic, :width=> 15, :height=> 6
  top
  text  :drug_name, :left=> 17, :font=> fonts.drug_name
  text  :drug_dose, :font=> fonts.drug_dose
end

drugs= PrintGrid.new :width=>    100, 
                     :height=>   35,
                     :columns=>  2,
                     :rows=>     4,
                     :data=>     :pack_drugs,
                     :contents=> pack_drug
                   
meal=  PrintArea.new 36, 5 do
  text  :meal_name, :left=> 18, :align=> :centre, :font=> fonts.meals
end

meals= PrintGrid.new :columns=>  4,
                     :col_gap=>  0,
                     :height=>   meal.height,
                     :data=>     :meals,
                     :contents=> meal

sticker= PrintArea.new 160, 70 do
  shape :rect,   :left=> 0,   :base=> 0, :width=>160, :height=> 70
  add   shop,    :left=> 117, :base=> 53
  add   patient, :left=> 3,   :base=> 50
  add   drugs,   :left=> 3,   :base=> 12
  add   alert,   :left=> 3,   :base=> 5,  
                 :print_check=> lambda{|data| data.alert && data.alert.size>0}
  add   meals,   :left=> 13,  :base=> 0
end

sheet= PrintGrid.new :rows=>     4,
                     :height=>   290,
                     :contents=> sticker


require 'ostruct'
pack= OpenStruct.new

pack.name=    'Jim Smith'
pack.address= '999 Nicholson Rd, Canningvale'
pack.area=    'D'
pack.begin_on='Tuesday 16 Sep 2008'
pack.pack_drugs= [['KARVEA TABS 300mg', '2 DAILY',     'T0776703.jpg'],
                  ['MONODUR TABS 60mg', '1 DAILY',     'T0762302.jpg'],
                  ['UREMIDE TABS 40mg', '2 BEDTIME',   'T0776703.jpg'],
                  ['RAMIPRIL CAPS 10mg','1/2 MORNINGS','T0776703.jpg'],
                  ['MAREVAN TABS 1mg',  'TWICE DAILY', 'T0762302.jpg'],
                  ['MINAX TABS 50mg',   '1/4 MORNINGS','T0776703.jpg'],
                  ['MINAX TABS 100mg',  '1 DAILY',     'T0776703.jpg']].map do |d|
                    {:drug_name=> d[0],
                     :drug_dose=> d[1],
                     :drug_pic=>  "drug images/#{d[2]}"
                     }
                  end
pack.meals= %w[Breakfast Lunch Dinner Bedtime]
pack.image= 'patients/1016 Margaret Lukowiak.JPG'

pack2= OpenStruct.new

pack2.name=    'Mary Jane'
pack2.address= '666 Gnangara Drive, Waikiki'
pack2.area=    'A'
pack2.begin_on='Friday 24 Oct 2008'
pack2.alert=   'Don\'t feed these to the cat'
pack2.pack_drugs= [['KARVEA TABS 300mg', '2 DAILY'],
                  ['RAMIPRIL CAPS 10mg','1/2 MORNINGS'],  
                  ['MONODUR TABS 60mg', '1 DAILY'],
                  ['UREMIDE TABS 40mg', '2 BEDTIME'],  
                  ['RAMIPRIL CAPS 10mg','1/2 MORNINGS'],  
                  ['MAREVAN TABS 1mg',  'TWICE DAILY'],  
                  ['MINAX TABS 50mg',   '1/4 MORNINGS'],
                  ['MINAX TABS 100mg',  '1 DAILY']].map do |d|
                    {:drug_name=> d[0],:drug_dose=> d[1]}
                  end
pack2.meals= %w[Breakfast Snack Afternoon Midnight]

list= [pack, pack2, pack, pack2]

PDF.new('prawn_test.pdf') do |pdf|
  sheet.print pdf, 3, 3,  list
end
