require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutQueryConditions < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @numbers = @db["nums"]
    (1..100).each {|i| @numbers.insert(:num => i, :string => i.to_s)}
    @arrays = @db["arrays"]
    @arrays.insert({:value => [1,3]})
    @arrays.insert({:value => [1,3,5,7,9]})
    @arrays.insert({:value => [2,4,6,8]})
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name)
    end
  end
  
  def test_select_comparison
    assert_equal 10, @numbers.find({'num' => {'$gt' => 90}}).count, "Select gt is wrong"
    assert_equal 20, @numbers.find({'num' => {'$lt' => 21}}).count, "Select lt is wrong"
    assert_equal 11, @numbers.find({'num' => {'$gte' => 90}}).count, "Select gte is wrong"
    assert_equal 21, @numbers.find({'num' => {'$lte' => 21}}).count, "Select lte is wrong"
  end

  def test_select_ranges
    assert_equal 4, @numbers.find({'num' => {'$gt' => 90, '$lt' => 95}}).count, "Select gt/lt is wrong"
    assert_equal 6, @numbers.find({'num' => {'$gte' => 90, '$lte' => 95}}).count, "Select gte/lte is wrong"
  end
  
  def test_select_equal_not_equal
    assert_equal 1, @numbers.find({'num' => 90}).count, "Select equal is wrong"
    assert_equal 99, @numbers.find({'num' => {'$ne' => 90}}).count, "Select ne is wrong"
  end
  
  def test_select_not_equal_not_not_equal
	assert 'not operator not avail in this version'
    #assert_equal 99, @numbers.find({'num' => {'$not' => 90}}).count, "Select not equal is wrong"
    #assert_equal 1, @numbers.find({'num' => {'$not' => {'$ne' => 90}}}).count, "Select not ne is wrong"
  end

  def test_select_in_not_in
    assert_equal 3, @numbers.find({'num' => {'$in' => [1,3,5]}}).count, "Select in is wrong"
    assert_equal 97, @numbers.find({'num' => {'$nin' => [1,3,5]}}).count, "Select in is wrong"
  end

  def test_select_all
    assert_equal 1, @arrays.find({'value' => {'$all' => [1,3,5]}}).count, "Select all 1,3,5 is wrong"
    assert_equal 0, @arrays.find({'value' => {'$all' => [1,3,5,11]}}).count, "Select all 1,3,5,11 is wrong"
  end

  def test_select_size
    assert_equal 1, @arrays.find({'value' => {'$size' => 4}}).count, "Select size 4 is wrong"
    assert_equal 0, @arrays.find({'value' => {'$size' => 8}}).count, "Select size 8 is wrong"
  end

  def test_array_elements
    assert_equal 2, @arrays.find({'value' => 3}).count, "Select element 3 is wrong"
  end

  def test_elemMatch
    col = @db["arr"]
	col.insert({:name => 'post1', :ratings => [{:val => 'super', :count => 1}, {:val => 'boring', :count => 12}]})	
	if @mongo.server_info["version"] >= '1.3.1'  
      assert_equal 1, col.find('ratings' => {'$elemMatch' => {'val' => 'boring', 'count' => {'$gt' => 10} }}).count, 'elemMatch not working'
	else
	  assert @mongo.server_info["version"] < '1.3.1', 'Version of MongoDB does not include elemMatch'
	end
  end

  def test_dot_notation_arrays
    col = @db['std']
	col.insert("x" => [ { "a" => 1, "b" => 3 }, 7, { "b" => 99 }, { "a" => 11 } ])
	col.insert("x" => [ { "a" => 0, "b" => 3 }, 8 ])
	assert_equal 1, col.find( { "x.a" => 11, "x.b" => { '$gt' => 1 } } ).count, 'Array dot notation valid select not working'
	assert_equal 0, col.find( { "x.a" => 0, "x.b" => { '$gt' => 10 } } ).count, 'Array dot notation invalid select not working'
  end

  def test_field_exists
    assert_equal 100, @numbers.find({'num' => {'$exists' => true}}).count, "Field exists is wrong"
    assert_equal 0, @numbers.find({'NUM' => {'$exists' => true}}).count, "Field doesn't exist is wrong"
  end

  def test_select_with_regexp
    assert_equal 12, @numbers.find({'string' => /^1/}).count, "Select begins with 1 is wrong"
    assert_equal 10, @numbers.find({'string' => /3$/}).count, "Select ends with 3 is wrong"
  end

end