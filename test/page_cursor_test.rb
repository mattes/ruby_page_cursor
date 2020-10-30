require "test_helper"

class PageCursor::TestBasics < ActiveSupport::TestCase
  setup do
    @ctrl = ApplicationController.new
    @ctrl.params = {}
  end

  test "paginate accepts a plain model class" do
    c = [Company.create!(name: "Nissan")]
    cursor, companies = @ctrl.paginate(Company)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal c, companies
  end

  test "paginate accepts a scoped model" do
    c = [Company.create!(name: "Nissan"),
         Company.create!(name: "Honda")]
    cursor, companies = @ctrl.paginate(Company.where(name: "Honda"))
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal [c[1]], companies
  end

  test "paginate accepts primary key option" do
    c = [Company.create!(id: "1fVnq51CLbR1oGl8l9VLEytTMRd", name: "Nissan")]
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 10, primary_key: "id")
    assert_equal c, companies

    assert_raise do
      @ctrl.paginate(Company, :asc, limit: 10, primary_key: "bogus_attr")
    end
  end

  test "paginate accepts an already loaded model" do
    c = [Company.create!(name: "Nissan")]
    cursor, companies = @ctrl.paginate(Company.all)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal c, companies
  end

  test "paginate :asc returns zero records" do
    assert_equal 0, Company.count
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 10)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal [], companies
  end

  test "paginate :asc returns one record" do
    c = [Company.create!(name: "Nissan")]
    assert_equal 1, Company.count
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 10)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal c, companies
  end

  test "paginate :asc returns two records" do
    c = [Company.create!(id: "1fVnq51CLbR1oGl8l9VLEytTMRd", name: "Nissan")]
    c << Company.create!(id: "1fVnqLJfABz5HnVvRluJOicwekR", name: "Honda")
    assert_equal 2, Company.count
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 10)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal c, companies
  end

  test "paginate :desc returns zero records" do
    assert_equal 0, Company.count
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 10)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal [], companies
  end

  test "paginate :desc returns one record" do
    c = [Company.create!(name: "Nissan")]
    assert_equal 1, Company.count
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 10)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal c, companies
  end

  test "paginate :desc returns two records" do
    c = [Company.create!(id: "1fVnq51CLbR1oGl8l9VLEytTMRd", name: "Nissan")]
    c << Company.create!(id: "1fVnqLJfABz5HnVvRluJOicwekR", name: "Honda")
    assert_equal 2, Company.count
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 10)
    assert_nil cursor[:before]
    assert_nil cursor[:after]
    assert_equal c.reverse, companies
  end
end

class PageCursor::TestOrderingByPrimaryKeyOnly < ActiveSupport::TestCase
  setup do
    @ctrl = ApplicationController.new
    @ctrl.params = {}

    # ordered by id asc
    @c = []
    @c << Company.create!(id: "1fVnq95sNrWAIcwUzvOqRcMerLm", name: "Nissan")
    @c << Company.create!(id: "1fVnqLJfABz5HnVvRluJOicwekR", name: "Honda")
    @c << Company.create!(id: "1fVrgt6mCU6t9Cns9dcrx64n57u", name: "Audi")
    @c << Company.create!(id: "1fVrkBAlmISlxt20jSpebrMm8rF", name: "Mercedes")
    @c << Company.create!(id: "1fVro9fUyly3VJQeuThvQ4zVE3Y", name: "BMW")
  end

  test "paginate :asc returns the first page" do
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[1].id, cursor[:after]
    assert_equal @c[0..1], companies
  end

  test "paginage :asc returns after the second page" do
    @ctrl.params[:after] = @c[1].id
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal @c[2..3], companies
  end

  test "paginage :asc returns after the third page (with odd number of results)" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal [@c[4]], companies
  end

  test "paginage :asc returns after the third page (with even number of results)" do
    @c << Company.create!(id: "1fVrqSZOP3Fhh6MPnBMLj4dGeXK", name: "Porsche")
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal @c[4..5], companies
  end

  test "paginate :asc returns before the first page" do
    @ctrl.params[:before] = @c[2].id
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[1].id, cursor[:after]
    assert_equal @c[0..1], companies
  end

  test "paginate :asc returns before the second page (with odd number of results)" do
    @ctrl.params[:before] = @c[4].id
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal @c[2..3], companies
  end

  test "paginate :asc returns before the second page (with even number of results)" do
    @c << Company.create!(id: "1fVrqSZOP3Fhh6MPnBMLj4dGeXK", name: "Porsche")
    @ctrl.params[:before] = @c[4].id
    cursor, companies = @ctrl.paginate(Company, :asc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal @c[2..3], companies
  end

  test "paginage :desc returns the first page" do
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal @c[3..4].reverse, companies
  end

  test "paginage :desc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[1].id, cursor[:after]
    assert_equal @c[1..2].reverse, companies
  end

  test "paginage :desc returns after the third page (with odd number of results)" do
    @ctrl.params[:after] = @c[1].id
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_equal @c[0].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal [@c[0]], companies
  end

  test "paginage :desc returns after the third page (with even number of results)" do
    @c.prepend(Company.create!(id: "1fVnq51CLbR1oGl8l9VLEytTMRd", name: "Kia"))
    @ctrl.params[:after] = @c[2].id # increase by 1, because we prepend to @c
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before] # increase by 1, because we prepend to @c
    assert_nil cursor[:after]
    assert_equal @c[0..1].reverse, companies
  end

  test "paginage :desc returns before the first page" do
    @ctrl.params[:before] = @c[2].id
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal @c[3..4].reverse, companies
  end

  test "paginage :desc returns before the second page (with odd number of results)" do
    @ctrl.params[:before] = @c[0].id
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[1].id, cursor[:after]
    assert_equal @c[1..2].reverse, companies
  end

  test "paginage :desc returns before the second page (with even number of results)" do
    @c << Company.create!(id: "1fVnq51CLbR1oGl8l9VLEytTMRd", name: "Kia")
    @ctrl.params[:before] = @c[1].id # increase by 1, because we prepend to @c
    cursor, companies = @ctrl.paginate(Company, :desc, limit: 2)
    assert_equal @c[3].id, cursor[:before] # increase by 1, because we prepend to @c
    assert_equal @c[2].id, cursor[:after]
    assert_equal @c[2..3].reverse, companies
  end
end

class PageCursor::TestOrderingByPrimaryKeyAndOneExraColumn < ActiveSupport::TestCase
  setup do
    @ctrl = ApplicationController.new
    @ctrl.params = {}

    # ordered by id asc
    @c = []
    @c << Company.create!(id: "1fVnq95sNrWAIcwUzvOqRcMerLm", name: "Nissan", city: "Munich")
    @c << Company.create!(id: "1fVnqLJfABz5HnVvRluJOicwekR", name: "Honda", city: "Berlin")
    @c << Company.create!(id: "1fVrgt6mCU6t9Cns9dcrx64n57u", name: "Audi", city: "Munich")
    @c << Company.create!(id: "1fVrkBAlmISlxt20jSpebrMm8rF", name: "Mercedes", city: "Berlin")
    @c << Company.create!(id: "1fVro9fUyly3VJQeuThvQ4zVE3Y", name: "BMW", city: "Munich")
    @c << Company.create!(id: "1jUO7NcSPsf7DP0PZUyc1chlFlq", name: "Tesla", city: "Berlin")
    @c << Company.create!(id: "1jUOCUeupo5f2k3pURXT8hXMXjg", name: "Lexus", city: "Munich")
  end

  # ordered by city asc, id asc: Honda 1, Mercedes 3, Tesla 5, Nissan 0, Audi 2, BMW 4, Lexus 6

  test "paginate city :asc, id :asc returns the first page" do
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[1], @c[3]], companies
  end

  test "paginage city :asc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[5], @c[0]], companies
  end

  test "paginage city :asc, id :asc returns after the third page" do
    @ctrl.params[:after] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[4].id, cursor[:after]
    assert_equal [@c[2], @c[4]], companies
  end

  test "paginage city :asc, id :asc returns after the fourth page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_equal @c[6].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal [@c[6]], companies
  end

  test "paginate city :asc, id :asc returns before the first page" do
    @ctrl.params[:before] = @c[5].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[1], @c[3]], companies
  end

  test "paginate city :asc, id :asc returns before the second page" do
    @ctrl.params[:before] = @c[2].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[5], @c[0]], companies
  end

  test "paginate city :asc, id :asc returns before the fourth page" do
    @ctrl.params[:before] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :asc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[4].id, cursor[:after]
    assert_equal [@c[2], @c[4]], companies
  end

  # ordered by city asc, id desc: Tesla 5, Mercedes 3, Honda 1, Lexus 6, BMW 4, Audi 2, Nissan 0

  test "paginate city :asc, id :desc returns the first page" do
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[5], @c[3]], companies
  end

  test "paginage city :asc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  test "paginage city :asc, id :desc returns after the third page" do
    @ctrl.params[:after] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[4], @c[2]], companies
  end

  test "paginage city :asc, id :desc returns after the fourth page" do
    @ctrl.params[:after] = @c[2].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_equal @c[0].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal [@c[0]], companies
  end

  test "paginate city :asc, id :desc returns before the first page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[5], @c[3]], companies
  end

  test "paginate city :asc, id :desc returns before the second page" do
    @ctrl.params[:before] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  test "paginate city :asc, id :desc returns before the fourth page" do
    @ctrl.params[:before] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc), :desc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[4], @c[2]], companies
  end

  # ordered by city desc, id asc: Nissan 0, Audi 2, BMW 4, Lexus 6, Honda 1, Mercedes 3, Tesla 5

  test "paginage city :desc, id :asc returns the first page" do
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[0], @c[2]], companies
  end

  test "paginage city :desc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[2].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[4], @c[6]], companies
  end

  test "paginage city :desc, id :asc returns after the third page" do
    @ctrl.params[:after] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[1], @c[3]], companies
  end

  test "paginage city :desc, id :asc returns after the forth page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal [@c[5]], companies
  end

  test "paginage city :desc, id :asc returns before the first page" do
    @ctrl.params[:before] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[0], @c[2]], companies
  end

  test "paginage city :desc, id :asc returns before the second page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[4], @c[6]], companies
  end

  test "paginage city :desc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[5].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[1], @c[3]], companies
  end

  # ordered by city desc, id desc: Lexus 6, BMW 4, Audi 2, Nissan 0, Tesla 5, Mercedes 3, Honda 1

  test "paginage city :desc, id :desc returns the first page" do
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[4].id, cursor[:after]
    assert_equal [@c[6], @c[4]], companies
  end

  test "paginage city :desc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[2], @c[0]], companies
  end

  test "paginage city :desc, id :desc returns after the third page" do
    @ctrl.params[:after] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[5], @c[3]], companies
  end

  test "paginage city :desc, id :desc returns after the forth page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_nil cursor[:after]
    assert_equal [@c[1]], companies
  end

  test "paginage city :desc, id :desc returns before the first page" do
    @ctrl.params[:before] = @c[2].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_nil cursor[:before]
    assert_equal @c[4].id, cursor[:after]
    assert_equal [@c[6], @c[4]], companies
  end

  test "paginage city :desc, id :desc returns before the second page" do
    @ctrl.params[:before] = @c[5].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_equal @c[2].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[2], @c[0]], companies
  end

  test "paginage city :desc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc), :desc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[3].id, cursor[:after]
    assert_equal [@c[5], @c[3]], companies
  end
end

class PageCursor::TestOrderingByPrimaryKeyAndMultipleColumns < ActiveSupport::TestCase
  setup do
    @ctrl = ApplicationController.new
    @ctrl.params = {}

    # ordered by id asc
    @c = []
    @c << Company.create!(id: "1fVnq95sNrWAIcwUzvOqRcMerLm", name: "Nissan", city: "Munich")
    @c << Company.create!(id: "1fVnqLJfABz5HnVvRluJOicwekR", name: "Honda", city: "Berlin")
    @c << Company.create!(id: "1fVrgt6mCU6t9Cns9dcrx64n57u", name: "Audi", city: "Munich")
    @c << Company.create!(id: "1fVrkBAlmISlxt20jSpebrMm8rF", name: "Mercedes", city: "Berlin")
    @c << Company.create!(id: "1fVro9fUyly3VJQeuThvQ4zVE3Y", name: "BMW", city: "Munich")
    @c << Company.create!(id: "1jUO7NcSPsf7DP0PZUyc1chlFlq", name: "Tesla", city: "Berlin")
    @c << Company.create!(id: "1jUOCUeupo5f2k3pURXT8hXMXjg", name: "Lexus", city: "Munich")
  end

  # ordered by name, city, id
  # -------------------------

  # ordered by name asc, city asc, id asc: Audi 2, BMW 4, Honda 1, Lexus 6, Mercedes 3, Nissan 0, Tesla 5

  test "paginate name :asc, city :asc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :asc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  test "paginage name :asc, city :asc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :asc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  # ordered by name asc, city asc, id desc: Audi 2, BMW 4, Honda 1, Lexus 6, Mercedes 3, Nissan 0, Tesla 5

  test "paginate name :asc, city :asc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :asc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  test "paginage name :asc, city :asc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :asc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  # ordered by name asc, city desc, id asc: Audi 2, BMW 4, Honda 1, Lexus 6, Mercedes 3, Nissan 0, Tesla 5

  test "paginate name :asc, city :desc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :desc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  test "paginage name :asc, city :desc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :desc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  # ordered by name desc, city asc, id asc: Tesla 5, Nissan 0, Mercedes 3, Lexus 6, Honda 1, BMW 4, Audi 2

  test "paginate name :desc, city :asc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :asc), :asc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  test "paginage name :desc, city :asc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :asc), :asc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  # ordered by name asc, city desc, id desc: Audi 2, BMW 4, Honda 1, Lexus 6, Mercedes 3, Nissan 0, Tesla 5

  test "paginate name :asc, city :desc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :desc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  test "paginage name :asc, city :desc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :asc, :city => :desc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[1], @c[6]], companies
  end

  # ordered by name desc, city asc, id desc: Tesla 5, Nissan 0, Mercedes 3, Lexus 6, Honda 1, BMW 4, Audi 2

  test "paginate name :desc, city :asc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :asc), :desc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  test "paginage name :desc, city :asc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :asc), :desc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  # ordered by name desc, city desc, id asc: Tesla 5, Nissan 0, Mercedes 3, Lexus 6, Honda 1, BMW 4, Audi 2

  test "paginate name :desc, city :desc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :desc), :asc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  test "paginage name :desc, city :desc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :desc), :asc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  # ordered by name desc, city desc, id desc: Tesla 5, Nissan 0, Mercedes 3, Lexus 6, Honda 1, BMW 4, Audi 2

  test "paginate name :desc, city :desc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[0].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :desc), :desc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  test "paginage name :desc, city :desc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:name => :desc, :city => :desc), :desc, limit: 2)
    assert_equal @c[3].id, cursor[:before]
    assert_equal @c[6].id, cursor[:after]
    assert_equal [@c[3], @c[6]], companies
  end

  # ordered by city, name, id
  # -------------------------

  # ordered by city asc, name asc, id asc: Honda 1, Mercedes 3, Tesla 5, Audi 2, BMW 4, Lexus 6, Nissan 0

  test "paginate city :asc, name :asc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :asc), :asc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[5], @c[2]], companies
  end

  test "paginage city :asc, name :asc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :asc), :asc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[5], @c[2]], companies
  end

  # ordered by city asc, name asc, id desc: Honda 1, Mercedes 3, Tesla 5, Audi 2, BMW 4, Lexus 6, Nissan 0

  test "paginate city :asc, name :asc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :asc), :desc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[5], @c[2]], companies
  end

  test "paginage city :asc, name :asc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :asc), :desc, limit: 2)
    assert_equal @c[5].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[5], @c[2]], companies
  end

  # ordered by city asc, name desc, id asc: Tesla 5, Mercedes 3, Honda 1, Nissan 0, Lexus 6, BMW 4, Audi 2

  test "paginate city :asc, name :desc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :desc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[1], @c[0]], companies
  end

  test "paginage city :asc, name :desc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :desc), :asc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[1], @c[0]], companies
  end

  # ordered by city desc, name asc, id asc: Audi 2, BMW 4, Lexus 6, Nissan 0, Honda 1, Mercedes 3, Tesla 5

  test "paginate city :desc, name :asc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :asc), :asc, limit: 2)
    assert_equal @c[6].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[6], @c[0]], companies
  end

  test "paginage city :desc, name :asc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :asc), :asc, limit: 2)
    assert_equal @c[6].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[6], @c[0]], companies
  end

  # ordered by city asc, name desc, id desc: Tesla 5, Mercedes 3, Honda 1, Nissan 0, Lexus 6, BMW 4, Audo 2

  test "paginate city :asc, name :desc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[3].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :desc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[1], @c[0]], companies
  end

  test "paginage city :asc, name :desc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :asc, :name => :desc), :desc, limit: 2)
    assert_equal @c[1].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[1], @c[0]], companies
  end

  # ordered by city desc, name asc, id desc: Audi 2, BMW 4, Lexus 6, Nissan 0, Honda 1, Mercedes 3, Tesla 5

  test "paginate city :desc, name :asc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[4].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :asc), :desc, limit: 2)
    assert_equal @c[6].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[6], @c[0]], companies
  end

  test "paginage city :desc, name :asc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[1].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :asc), :desc, limit: 2)
    assert_equal @c[6].id, cursor[:before]
    assert_equal @c[0].id, cursor[:after]
    assert_equal [@c[6], @c[0]], companies
  end

  # ordered by city desc, name desc, id asc: Nissan 0, Lexus 6, BMW 4, Audi 2, Tesla 5, Mercedes 3, Honda 1

  test "paginate city :desc, name :desc, id :asc returns after the second page" do
    @ctrl.params[:after] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :desc), :asc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[4], @c[2]], companies
  end

  test "paginage city :desc, name :desc, id :asc returns before the third page" do
    @ctrl.params[:before] = @c[5].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :desc), :asc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[4], @c[2]], companies
  end

  # ordered by city desc, name desc, id desc: Nissan 0, Lexus 6, BMW 4, Audi 2, Tesla 5, Mercedes 3, Honda 1

  test "paginate city :desc, name :desc, id :desc returns after the second page" do
    @ctrl.params[:after] = @c[6].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :desc), :desc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[4], @c[2]], companies
  end

  test "paginage city :desc, name :desc, id :desc returns before the third page" do
    @ctrl.params[:before] = @c[5].id
    cursor, companies = @ctrl.paginate(Company.order(:city => :desc, :name => :desc), :desc, limit: 2)
    assert_equal @c[4].id, cursor[:before]
    assert_equal @c[2].id, cursor[:after]
    assert_equal [@c[4], @c[2]], companies
  end
end
