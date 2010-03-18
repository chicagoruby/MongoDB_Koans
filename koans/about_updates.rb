require 'rubygems'
require 'mongo'
require 'edgecase'

# Make sure you start up mongod first :)

class AboutUpdates < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @col = @db["stuff"]
	@col.remove
    @col.insert({:category => "sandwich", :type =>"peanut butter"})
	@col.insert({:category => "sandwich", :type =>"tuna salad"})
	
	@pix = @db['photos']
	@pix.remove
	@pix.insert({:file => 'pic1.jpg', :loc => 'beach', :camera => 'Nikon'})
	@pix.insert({:file => 'pic2.jpg', :loc => 'beach', :camera => 'Nikon'})
	@pix.insert({:file => 'pic3.jpg', :loc => 'city', :camera => 'Nikon'})
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name)
    end
  end
  
  def test_update
    @col.update({'category' => 'sandwich'}, {'$set' => {:meal => "lunch"}})
    assert_equal 1, @col.find({'meal' => 'lunch'}).count, "One matching record should be updated"
    @col.update({'category' => 'sandwich'}, {'$set' => {:meal => "lunch"}}, {:multi => true})
    assert_equal 2, @col.find({'meal' => 'lunch'}).count, "All matching records should be updated"
  end
  def test_upsert  #upsert means if results of selection (1st param) is empty then insert
    @col.remove
    @col.insert({ '_id' => 1, :category => "sandwich", :type =>"peanut butter"})
    @col.update({}, { '_id' => 1, :category => "sandwich", :type =>"tuna fish"}, {:upsert => true})
	assert_equal 1, @col.find.count, "Changed record count"
	assert_equal 1, @col.find({'type' => 'tuna fish'}).count, "Didn't update"
    @col.update({'_id' => 2}, { '_id' => 2, :category => "soup", :type =>"potato"}, {:upsert => true, :multi => false})
	assert_equal 2, @col.find.count, "Didn't change record count"	
	@col.update({:category => "salad"}, { '_id' => 3, :category => "salad", :type =>"potato"}, {:upsert => true, :multi => false})
	assert_equal 3, @col.find.count, "Didn't change record count"	
  end
  def test_increment
    @col.update({:category => "sandwich"}, {'$inc' => {:num => 1}}, {:multi => true})
	assert_equal 2, @col.find({:num => 1}).count, "Didn't change all"
	@col.update({:type =>"peanut butter"}, {'$inc' => {:num => 1}}, {:multi => true})
	assert_equal 1, @col.find({:num => 2}).count, "Didn't change one"
  end
  def test_set
    @col.remove
	@col.insert({:category => "sandwich", :type =>"peanut butter"})
	@col.insert({:type =>"tuna salad"})
    @col.update({:type =>"tuna salad"}, {'$set' => {:category => "sandwich"}}, {:multi => true})
	assert_equal 2, @col.find({:category => "sandwich"}).count, "Didn't set"
  end
  def new_test_unset
    #unset is available in version 1.3.1
    @col.update({:category => "sandwich"}, {'$unset' => {:category => 1}}, {:multi => true})
	assert_equal 0, @col.find({:category => "sandwich"}).count, "Didn't unset"
  end
  
  def test_push
    @pix.update({:file => 'pic1.jpg'}, {'$push' => {:tags => 'people'}})
	assert_equal ['people'], @pix.find({:file => 'pic1.jpg'}).first['tags']
  end
  def test_push_all
    @pix.update({:file => 'pic2.jpg'}, {'$pushAll' => {:tags => ['food','people']}})
    @pix.update({:file => 'pic2.jpg'}, {'$pushAll' => {:tags => ['music','art']}})
	assert_equal ['food','people','music','art'], @pix.find({:file => 'pic2.jpg'}).first['tags']
	@pix.update({:file => 'pic3.jpg'}, {'$pushAll' => {:loc => ['food','people']}})
	assert @db.error?, "Push array to non-array field"
  end
  def test_check_status
    @pix.update({:file => 'pic1.jpg'}, {'$push' => {:tags => 'people'}})
	assert @db.last_status["updatedExisting"], "Update failed"
	@pix.update({:file => 'pic1.jpg'}, {'$push' => {:camera => 'Canon'}})
	assert_nil @db.last_status["updatedExisting"], "Update not permitted"
	#when it works last_status is {"err"=>nil, "updatedExisting"=>true, "n"=>1, "ok"=>1.0}
	#when update fails last_status is {"err"=>nil, "updatedExisting"=>false, "n"=>0, "ok"=>1.0}
	#when update is not permitted last_status is {"err"=>"Cannot apply $push/$pushAll modifier to non-array", "n"=>0, "ok"=>1.0}
  end
  def test_pop
    @pix.update({:file => 'pic1.jpg'}, {'$set' => {:tags => ['people','food','music','art']}})
	@pix.update({:file => 'pic1.jpg'}, {'$pop' => {:tags => 1}})
	assert_equal ['people','food','music'], @pix.find({:file => 'pic1.jpg'}).first['tags']
	@pix.update({:file => 'pic1.jpg'}, {'$pop' => {:tags => -1}})
	assert_equal ['food','music'], @pix.find({:file => 'pic1.jpg'}).first['tags']
  end
  def test_pull
    @pix.update({:file => 'pic1.jpg'}, {'$set' => {:tags => ['people','food','music','food','art']}})
	@pix.update({:file => 'pic1.jpg'}, {'$pull' => {:tags => 'food'}})
	assert_equal ['people','music','art'], @pix.find({:file => 'pic1.jpg'}).first['tags']
  end
  def test_pullAll
    @pix.update({:file => 'pic1.jpg'}, {'$set' => {:tags => ['people','food','music','food','art']}})
	@pix.update({:file => 'pic1.jpg'}, {'$pullAll' => {:tags => ['food','art']}})
	assert_equal ['people','music'], @pix.find({:file => 'pic1.jpg'}).first['tags']
  end
end