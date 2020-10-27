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

class PageCursor::TestMulti < ActiveSupport::TestCase
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
