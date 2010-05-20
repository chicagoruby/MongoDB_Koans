require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutEmbeddedDocuments < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @embedded = @db["embedded"]
    @embedded.remove
    @embedded.insert({:order_num => 101, :customer => 'Acme', :ship_via => 'UPS',
        :shipto => {:street => "123 E Chicago Ave",
                    :city => "Chicago", :state => "IL", :zip => 60611},
        :lines => [ {:line_num => 1, :item => 'widget', :quantity => 2},
	            {:line_num => 2, :item => 'gizmo', :quantity => 4},
		    {:line_num => 3, :item => 'thingy', :quantity => 6}  ]})
    @embedded.insert({:order_num => 102, :customer => 'Ace',  :ship_via => 'UPS',
        :shipto => {:street => "123 N Wabash St",
                    :city => "Chicago", :state => "IL", :zip => 60611},    
        :lines => [ {:line_num => 1, :item => 'widget', :quantity => 10},
	            {:line_num => 2, :item => 'gizmo', :quantity => 1}   ]})	
    @embedded.insert({:order_num => 103, :customer => 'Acme', :ship_via => 'FedEx',
        :shipto => {:street => "123 E Wacker Dr",
                    :city => "Chicago", :state => "IL", :zip => 60611},    
        :lines => [ {:line_num => 1, :item => 'thingy', :quantity => 5}  ]})	
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name)
    end
  end

  def test_query
    assert_equal __, @embedded.find({'order_num' => 103}).count 
    assert_equal __, @embedded.find({'lines.line_num' => 3}).count
    assert_equal __, @embedded.find({'lines.line_num' => 2}).count 
    assert_equal __, @embedded.find({'shipto.zip' => 60611}).count 
  end
 
  def test_update_add
    line_list = @embedded.find({:order_num => 103}).first['lines']
    assert_equal __, @embedded.find({:order_num => 103}).first['lines'].count 
    @embedded.update({:order_num => 103}, {'$set' => {:lines => (line_list << {:line_num => 2, :item => 'gizmo', :quantity => 10})}})
    assert_equal __, @embedded.find({:order_num => 103}).first['lines'].count 
  end
  
  def test_update_change_lines_array
    assert_equal __, @embedded.find({:order_num => 103}).first['lines'][0]['quantity']
    @embedded.update(({:order_num => 103}), {'$set' => {'lines.0.quantity' => 1}})
    assert_equal __, @embedded.find({:order_num => 103}).first['lines'][0]['quantity'] 
    @embedded.update(({:order_num => 103}), {'$inc' => {'lines.0.quantity' => 1}})
    assert_equal __, @embedded.find({:order_num => 103}).first['lines'][0]['quantity'] 
  end
  
  def test_update_change_address
    assert_equal __, @embedded.find({:order_num => 103}).first['shipto']['zip']
    @embedded.update(({:order_num => 103}), {'$set' => {'shipto.zip' => 60606}})
    assert_equal __, @embedded.find({:order_num => 103}).first['shipto']['zip']
  end
  
  def test_indexed_query
    @embedded.create_index('lines.item')
    assert_equal __, @embedded.find({'lines.item' => 'widget'}).count 
    assert_equal __, @embedded.find({'lines.item' => 'widget'}).explain['indexBounds'][0][0]['lines.item']
  end

end
