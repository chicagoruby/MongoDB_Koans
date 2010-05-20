require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutMapReduce < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @comments = @db["stuff"]
    @comments.remove

    @comments.insert({ :text => "lmao! great article!", :author => 'kbanker', :votes => 4 })
    @comments.insert({ :text => "boring", :author => 'ghendry', :votes => 1 })
    @comments.insert({ :text => "tl:dr", :author => 'kbanker', :votes => 3 })
    @comments.insert({ :text => "best article ever", :author => 'ghendry', :votes => 2 })
    @comments.insert({ :text => "very weird", :author => 'kbanker', :votes => 2 })
    @comments.insert({ :text => "pretty good", :author => 'ghendry', :votes => 3 })
    @comments.insert({ :text => "lmao! great article!", :author => 'nstowe', :votes => 4 })
    @comments.insert({ :text => "boring", :author => 'nstowe', :votes => 1 })
    @comments.insert({ :text => "tl:dr", :author => 'nstowe', :votes => 3 })
    @comments.insert({ :text => "best article ever", :author => 'nstowe', :votes => 2 })
    @comments.insert({ :text => "very weird", :author => 'nstowe', :votes => 2 })
    @comments.insert({ :text => "pretty good", :author => 'nstowe', :votes => 3 })
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name)
    end
  end
  
  def test_map_reduce
    map = "function() { emit(this.author, {votes: this.votes}); }"
    reduce = "function(key, values) { var sum = 0; values.forEach(function(doc) { sum += doc.votes; }); return {votes: sum}; }"

    assert_equal 3, @comments.map_reduce(map, reduce).count
    assert_equal __, @comments.map_reduce(map, reduce).find.first['_id']
    assert_equal __, @comments.map_reduce(map, reduce).find.first['value']['votes']
  end
  
  def test_map_reduce_with_query
    map = "function() { emit(this.author, {votes: this.votes}); }"
    reduce = "function(key, values) { var sum = 0; values.forEach(function(doc) { sum += doc.votes; }); return {votes: sum}; }"

    assert_equal 3, @comments.map_reduce(map, reduce, {:query => {:votes => {'$gt' => 1}}}).count
    assert_equal 'ghendry', @comments.map_reduce(map, reduce, {:query => {:votes => {'$gt' => 1}}}).find.first['value']
    assert_equal __, @comments.map_reduce(map, reduce, {:query => {:votes => {'$gt' => 1}}}).find.first['value']['votes']
  end

end
