require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutQueryOptions < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @col = @db["num_strings"]
    (1..100).each {|i| @col.insert(:item => i, :item_string => i.to_s)}
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name) unless collection.name =~ /indexes$/
    end
  end
  
  def test_select_fields
    assert_equal __, @col.find({'item' => 33}, {:fields => 'item'}).first.size, "Select one field is wrong"
    assert_equal __, @col.find({'item' => 33}).first.size, "Select all fields is wrong"
    #Why are the expected results one more than you really expected?
  end

  def test_limit_returned_docs
    result_array = @col.find({}, {:limit => 2}).to_a
    assert_equal __, result_array.size, "Limited count is wrong #{result_array.inspect}"
    
    assert_equal __, @col.find({}, {:limit => 2}).count, "Limited count does not honor :limit"  
    #assert_equal 2, @col.find({}, {:limit => 2}).size, "Limited count is buggy"  
    #Cursor.size honors :limit but is not implemented in Ruby driver
  end

  def test_skip_returned_docs
    assert_equal '11', @col.find({}, {:skip => 1}).first['item_string'], "Skipped wrong docs"
  end

  def test_sort_returned_docs
    assert_equal __, @col.find.to_a[99]['item_string'], "String last item wrong"
    assert_equal __, @col.find({}, {:sort => ['item_string', :desc]}).first['item_string'], "String descending sort wrong"

    assert_equal __, @col.find.to_a[99]['item'], "Num last item wrong"
    assert_equal __, @col.find({}, {:sort => ['item', :desc]}).first['item'], "Num descending sort wrong"

    #Why are these different?
  end
  
end
