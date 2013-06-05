
class ReportTest < ActiveSupport::TestCase

    test "basics" do

        report = Report.new()

        assert report.to_s == ""

        assert report.empty?

        report.write("a",1)
        report.write("b",1)
        report.write("c",2)
        report.write("d",2)
        report.write("e",3)
        report.write("f",3)

        assert !report.empty?

        cat = report.categories?

        assert cat.sort == [1, 2, 3]

        c1 = report.get_category(1)
        assert c1.sort == ["a","b"]

        c2 = report.get_category(2)
        assert c2.sort == ["c","d"]

        c3 = report.get_category(3)
        assert c3.sort == ["e","f"]

        all = report.list
        assert all.sort == ["a","b","c","d","e","f"]

        assert report.to_s.is_a?(String)

        assert report.remove_category(1).sort == ["a","b"]

        assert report.categories?.sort == [2, 3]

    end

    test "merge" do

        r1 = Report.new()
        r2 = Report.new()

        assert r1.merge(r2)

        assert r1.empty?
        assert r2.empty?

        r1.write("a", 1)
        r2.write("b", 2)

        assert r1.categories?.sort == [1]
        assert r2.categories?.sort == [2]

        assert !r1.merge(nil)
        assert r1.merge(r2)

        assert r1.categories?.sort == [1,2]
        assert r2.categories?.sort == [2]

        assert r2.merge(r1)

        assert r1.categories?.sort == [1,2]
        assert r2.categories?.sort == [1,2]

    end

    test "list" do 

        report = Report.new()

        assert report.empty?
        assert report.list.size == 0

        report.write("a",1)
        report.write("b",1)
        report.write("c",2)
        report.write("d",2)
        report.write("e",3)
        report.write("f",3)

        assert report.list.sort == ["a","b","c","d","e","f"]

    end


end
