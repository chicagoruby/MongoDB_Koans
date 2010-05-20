require 'rubygems'
require 'mongo'
require 'edgecase'

class AboutCRUD < EdgeCase::Koan
  include Mongo
  
  def setup
    @mongo = Connection.new
    @db = @mongo.db('hack0318')
    @col = @db["stuff"]
  end
  
  def teardown
    @db.collections.each do |collection|
      @db.drop_collection(collection.name)
    end
  end
  
  def test_create_empty_collection
    empty_coll = @db.create_collection("empty")
    assert_equal __, empty_coll.size, "New collection is not empty"
    assert_instance_of Mongo::Cursor, empty_coll, "empty_coll is not a Mongo Collection"
  end
  
  def test_create_and_insert_document
    doc = {:test => "hi there"}
    @col.insert(doc)
    assert_equal __, @col.size, "Collection size is wrong"    
    assert_equal doc[:testx], @col.find_one['test'], "Document in collection is wrong"
  end

  def test_fetch_document
    doc = {:test => "hi there"}
    @col.insert(doc)
    assert_equal doc[:testx], @col.find_one['test'], "Document in collection is wrong"
  end

  def test_replace_document
    doc1 = {:category => "sandwich"}
    @col.insert(doc1)
    doc2 = @col.find_one
    doc2["type"] = "peanut butter"
    @col.save(doc2)
    assert_equal __, @col.size, "Collection size is wrong"
    assert_equal doc1, @col.find_one, "Document not updated"
    assert_not_equal doc2, @col.find_one, "Document not updated correctly"
  end

  def test_update_document
    doc1 = {:category => "sandwich", :type =>"peanut butter"}
    @col.insert(doc1)
    @col.update({'category' => 'sandwich'}, {'$set' => {:type => "tuna fish"}})
    assert_equal doc1, @col.find_one, "Document not updated"
    assert_equal "tuna salad", @col.find_one['type'], "Document not updated correctly"
  end

  def test_delete_document
    doc1 = {:category => "sandwich", :type =>"peanut butter"}
    @col.insert(doc1)
    doc2 = {:category => "soup", :type =>"minestrone"}
    @col.insert(doc2)
    assert_equal __, @col.size, "Collection size is wrong"
    @col.remove({'category' => "sandwich"})
    assert_equal __, @col.size, "Document not deleted"
  end

  def test_hash_key
     doc1 = {:category => "sandwich", :type =>"peanut butter"}
     @col.insert(doc1)
     assert_equal doc1[:type], @col.find_one['typee']
     assert_nil doc1[:type]
     assert_not_nil @col.find_one[:type]
     #mongo driver only allows symbols as hash keys in some commands
  end
end