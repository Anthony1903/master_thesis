
class CsvToHashesTest < ActiveSupport::TestCase
  
  test "load" do

      @fnames = [{:name => "hash.test", :path => "XXXX"}]
      h = CsvHasher.new(@fnames)
      b, r = h.load
      assert !b
      assert r == :read_error

      @fnames = [{:name => "hash.test", :path => File.expand_path("test/unit/import_manager/files/hash2.test")}]
      h = CsvHasher.new(@fnames)
      b, r = h.load
      assert !b
      assert r == :format_error

      @fnames = [{:name => "hash.test", :path => File.expand_path("test/unit/import_manager/files/hash.test")}]
      h = CsvHasher.new(@fnames)
      b, r = h.load
      assert b

      hash = r["hash.test"]

      assert hash!=nil

      assert hash.keys.sort == ["1","2","3"]
      assert hash["1"][0] == {"A"=>"1","B"=>"11","C"=>"12","D"=>"13"}
      assert hash["1"][1] == {"A"=>"1","B"=>"11_","C"=>"12_","D"=>"13_"}
      assert hash["2"][0] == {"A"=>"2","B"=>"21","C"=>"22","D"=>"23"}
      assert hash["3"][0] == {"A"=>"3","B"=>"31","C"=>"32","D"=>"33"}
      
  end

end

