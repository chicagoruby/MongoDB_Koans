require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutGroups < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @numbers = @db["nums"]
    (1..100).each {|i| @numbers.insert(:num => i, :string => i.to_s)}
    @addresses = @db["addresses"]
    @addresses.insert({'city' => 'chicago', 'zip' => 60606, 'tags' => ['metra','cta_bus'], 'use' => {'commercial' => 80, 'residential' => 20}})
    @addresses.insert({'city' => 'chicago', 'zip' => 60611, 'tags' => ['cta_rail','cta_bus'], 'use' => {'commercial' => 60, 'residential' => 40}})
    @zips = @db["zips"]
    @zips.insert({:city => 'chicago', :state => 'IL', :zip => 60606, :population => 1000})
    @zips.insert({:city => 'chicago', :state => 'IL', :zip => 60607, :population => 1100})
    @zips.insert({:city => 'chicago', :state => 'IL', :zip => 60608, :population => 1200})
    @zips.insert({:city => 'decatur', :state => 'IL', :zip => 62521, :population => 1001})
    @zips.insert({:city => 'decatur', :state => 'IL', :zip => 62522, :population => 1002})
    @zips.insert({:city => 'decatur', :state => 'IL', :zip => 62523, :population => 1003})
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name) unless collection.name =~ /indexes$/
    end
  end
  
  def test_size_and_count
    assert_equal __, @numbers.find({}, {:limit => 1}).count, "Count all is wrong"
    assert_equal __, @numbers.find({ 'num' => {'$gt' => 50 }}, {:limit => 1}).count, "Count some is wrong"
    #Cursor.size does honor :limit but is not implemented in Ruby driver so limit is not usable
    #assert_equal 1, @numbers.find({}, {:limit => 1}).size(), "Size is wrong"
  end
  
  def test_distinct
    assert_equal __, @addresses.distinct('city').count, "Count distinct fields same wrong"
    assert_equal __, @addresses.distinct('zip').count, "Count distinct fields different wrong"
    assert_equal [60611].sort, @addresses.distinct('zip'), "Return distinct fields different wrong"
    assert_equal __, @addresses.distinct('zip', {'tags' => ['metra','cta_bus']}).count, "Count distinct selected fields different wrong"
  end
  
  def test_distinct_nested
    assert_equal __, @addresses.distinct('use.commercial').count, "Count distinct nested fields wrong"
    assert_equal [80, 40].sort, @addresses.distinct('use.commercial'), "Return distinct nested fields wrong"
  end

  def test_simple_group
    assert_equal __, @zips.group([:city], {}, {}, 'function() {}', true), "Group by one field"
  end
  
  def test_simple_aggregation
    assert_equal [{"city"=>"chicago", 'zsum' => 3300.0}, {"city"=>"decatur", 'zsum' => 0}], 
      @zips.group([:city], {}, { 'zsum' => 0 }, 'function(doc,out) { out.zsum += doc.population; }', true), "Group by one field"
    #The fourth parameter doesn't look like Ruby.  Why?  It's a string containing a JavaScript function.
  end
  
  def test_aggregation_two_results
    assert_equal [{"city"=>__, 'zsum' => 3300.0, 'zstr' => 'ILILIL'}, {"city"=>"decatur", 'zsum' => 3006.0, 'zstr' => 'ILILIL'}], 
      @zips.group([:city], {}, { 'zsum' => 0, 'zstr' => '' }, 'function(doc,out) { out.zsum += doc.population; out.zstr += doc.state; }', true), 
      "Group by one field, two aggregate fields"
  end
  
  def test_aggregation_with_finalize
    assert_equal [{"city"=>"chicago", "avg_pop"=>1100.0, "zsum"=>3300.0, "zc"=>3.0}, 
                  {"city"=>"springfield", "avg_pop"=>1002.0, "zsum"=>3006.0, "zc"=>3.0}], 
          @zips.group([:city], {}, { 'zsum' => 0, 'zc' => 0, 'avg_pop' => 0 }, 
                     'function(doc,out) { out.zsum += doc.population; out.zc += 1; }',  
                     'function(out){ out.avg_pop = out.zsum / out.zc}'), 
          "Group by one field with finalize"
  end

  def test_aggregation_with_condition
    assert_equal [{"city"=>"chicago", 'zsum' => 3000.0}], 
          @zips.group([:city], {"city"=>"chicago"}, { 'zsum' => 0 }, 'function(doc,out) { out.zsum += doc.population; }', true), 
          "Group by one field with condition"
  end  
  #In his blog, Kyle Banker said "group() is rather a beast".  Do you agree?

end
