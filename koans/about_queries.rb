require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutQueries < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @books = @db["books"]
    @books.insert({:name => "Pickaxe", :author => "Dave", :hard_cover => false})
    @books.insert({:name => "Patterns", :author => "Russ", :hard_cover => true})
    @books.insert({:name => "Refactoring", :author => "Jay", :hard_cover => true})
    @books.insert({:name => "Refactoring", :author => "William", :hard_cover => false})
    @people = @db["people"]
    @people.insert({:name => "Ada", :active => false})
    @people.insert({:name => "Bob", :active => false})
    @people.insert({:name => "Cathy", :active => true})
    @people.insert({:name => "Dan", :active => true})
    @articles = @db['articles']
    @articles.save( { :name => "Warm Weather", :author => "Steve", :tags => ['weather', 'hot', 'record', 'april'] } )
    @articles.save( { :name => "Winter", :author => "Steve", :tags => ['weather', 'cold', 'snow'] } )
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name)
    end
  end
  
  def test_find_all
    assert_equal @people.count, @people.find.count, "Find all wrong number returned"
  end

  def test_find_by_name
    assert_equal 1, @people.find(:name => 'Ada').count, "Count of name = Ada is wrong"
  end
  
  def test_create_index
    assert_equal 1, @people.index_information.count, "Number of indexes is wrong"
    @people.create_index('name')
    assert_equal 2, @people.index_information.count, "Number of indexes is wrong"
    #Why is there one index before we added our first index?
  end  

  def test_find_by_index_field
    @people.create_index('active')
    assert_equal 2, @people.find(:active => true).count, "Count of active is wrong"
    assert @people.find(:active => true).explain['nscanned'] < @people.count, "Find on indexed field read too many documents"
  end

  def test_find_by_name_and_boolean
    assert_equal 1, @books.find({:name => 'Refactoring', :hard_cover => true}).count, "Count for query on two fields is wrong"
  end

  def test_sorted_query    
    @books.create_index('name' => DESCENDING, 'author' => DESCENDING)
    assert_equal 'William', @books.find({:name => 'Refactoring'}).first['author']
    assert_equal 'Dave', @books.find.first['author']  
    #which index does each query use?
  end
  
  def test_distinct
    assert_equal 3, @books.distinct(:name).count, "Number of distinct names wrong"
  end

  def test_multikey_index
    @articles.create_index('tags')
    assert_equal 1, @articles.find('tags' => 'cold').count, "Can't find on array element"
    assert @articles.find('tags' => 'cold').explain['nscanned'] < @articles.count, "Find on indexed field read too many documents"
  end
  
end