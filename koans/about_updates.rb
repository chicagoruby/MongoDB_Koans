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
      @db.drop_collection(collection.name) unless collection.name =~ /indexes$/
    end
  end
  
  def test_update
    @col.update({'category' => 'sandwich'}, {'$set' => {:meal => "lunch"}})
    assert_equal __, @col.find({'meal' => 'lunch'}).count, "One matching record should be updated"
    @col.update({'category' => 'sandwich'}, {'$set' => {:meal => "lunch"}}, {:multi => true})
    assert_equal 2, @col.find({'meal' => 'breakfast'}).count, "All matching records should be updated"
  end

  def test_upsert  #upsert means if results of selection (1st param) is empty then insert
    @col.remove
    @col.insert({ '_id' => 1, :category => "sandwich", :type =>"peanut butter"})
    @col.update({}, { '_id' => 1, :category => "sandwich", :type =>"tuna fish"}, {:upsert => true})
    assert_equal __, @col.find.count, "Changed record count"
    assert_equal __, @col.find({'type' => 'tuna fish'}).count, "Didn't update"
    @col.update({'_id' => 2}, { '_id' => 2, :category => "soup", :type =>"potato"}, {:upsert => true, :multi => false})
    assert_equal __, @col.find.count, "Didn't change record count"	
    @col.update({:category => "salad"}, { '_id' => 3, :category => "salad", :type =>"potato"}, {:upsert => true, :multi => false})
    assert_equal __, @col.find.count, "Didn't change record count"	
  end

  def test_increment
    @col.update({:category => "sandwich"}, {'$inc' => {:num => 1}}, {:multi => true})
    assert_equal __, @col.find({:num => 1}).count, "Didn't change all"
    @col.update({:type =>"peanut butter"}, {'$inc' => {:num => 1}}, {:multi => true})
    assert_equal __, @col.find({:num => 2}).count, "Didn't change one"
  end

  def test_set
    @col.remove
    @col.insert({:category => "sandwich", :type =>"peanut butter"})
    @col.insert({:type =>"tuna salad"})
    @col.update({:type =>"tuna salad"}, {'$set' => {:category => "sandwich"}}, {:multi => true})
    assert_equal __, @col.find({:category => "sandwich"}).count, "Didn't set"
  end

  def test_unset
    @col.update({:category => "sandwich"}, {'$unset' => {:category => 1}}, {:multi => true})
    assert_equal __, @col.find({:category => "sandwich"}).count, "Didn't unset"
  end
  
  def test_push
    @pix.update({:file => 'pic1.jpg'}, {'$push' => {:tags => 'people'}})
    assert_equal ['person'], @pix.find({:file => 'pic1.jpg'}).first['tags']
  end

  def test_push_all
    @pix.update({:file => 'pic2.jpg'}, {'$pushAll' => {:tags => ['food','people']}})
    @pix.update({:file => 'pic2.jpg'}, {'$pushAll' => {:tags => ['music','art']}})
    assert_equal ['food','art'], @pix.find({:file => 'pic2.jpg'}).first['tags']
    @pix.update({:file => 'pic3.jpg'}, {'$pushAll' => {:loc => ['food','people']}})
    assert !@db.error?, "Push array to non-array field"
  end

  def test_check_status
    @pix.update({:file => 'pic1.jpg'}, {'$push' => {:tags => 'people'}})
    assert !@db.get_last_error["updatedExisting"], "Update failed"
    @pix.update({:file => 'pic1.jpg'}, {'$push' => {:camera => 'Canon'}})
    assert_not_nil @db.get_last_error["updatedExisting"], "Update not permitted"

    #when update works get_last_error is {"err"=>nil, "updatedExisting"=>true, "n"=>1, "ok"=>1.0}
    #when update fails get_last_error is {"err"=>nil, "updatedExisting"=>false, "n"=>0, "ok"=>1.0}
    #when update is not permitted get_last_error is {"err"=>"Cannot apply $push/$pushAll modifier to non-array", "code"=>10141, "n"=>0, "ok"=>1.0}
  end

  def test_pop
    @pix.update({:file => 'pic1.jpg'}, {'$set' => {:tags => ['people','food','music','art']}})
    @pix.update({:file => 'pic1.jpg'}, {'$pop' => {:tags => 1}})
    assert_equal __, @pix.find({:file => 'pic1.jpg'}).first['tags']
    @pix.update({:file => 'pic1.jpg'}, {'$pop' => {:tags => -1}})
    assert_equal __, @pix.find({:file => 'pic1.jpg'}).first['tags']
  end

  def test_pull
    @pix.update({:file => 'pic1.jpg'}, {'$set' => {:tags => ['people','food','music','food','art']}})
    @pix.update({:file => 'pic1.jpg'}, {'$pull' => {:tags => 'food'}})
    assert_equal ['people','art'], @pix.find({:file => 'pic1.jpg'}).first['tags']
  end

  def test_pullAll
    @pix.update({:file => 'pic1.jpg'}, {'$set' => {:tags => ['people','food','music','food','art']}})
    @pix.update({:file => 'pic1.jpg'}, {'$pullAll' => {:tags => ['food','art']}})
    assert_equal __, @pix.find({:file => 'pic1.jpg'}).first['tags']
  end
end
