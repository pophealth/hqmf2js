require_relative '../test_helper'
require 'hquery-patient-api'

class LibraryFunctionTest < Test::Unit::TestCase
  
  def setup
    @context = get_js_context(HQMF2JS::Generator::JS.library_functions)
    @context.eval("hqmf.SpecificsManager.initialize()")
  end


  def test_library_function_parses
    @context.eval('hQuery == undefined').must_equal false
    @context.eval('typeof hQuery.Patient').must_equal "function"
    @context.eval('typeof allTrue').must_equal "function"
    @context.eval('typeof atLeastOneTrue').must_equal "function"
  end
  
  def test_all_true
    @context.eval('allTrue(1,null,null,new Boolean(false),new Boolean(false),new Boolean(false))().isTrue()').must_equal false
    @context.eval('allTrue(1,null,null,new Boolean(false),new Boolean(true),new Boolean(false))().isTrue()').must_equal false
    @context.eval('allTrue(1,null,null,new Boolean(true),new Boolean(true),new Boolean(true))().isTrue()').must_equal true
    @context.eval('allTrue(1,null,null)().isTrue()').must_equal false
  end
  
  def test_at_least_one_true
    @context.eval('atLeastOneTrue(1,null,null,new Boolean(true),new Boolean(false),new Boolean(false))().isTrue()').must_equal true
    @context.eval('atLeastOneTrue(1,null,null,new Boolean(true),new Boolean(true),new Boolean(true))().isTrue()').must_equal true
    @context.eval('atLeastOneTrue(1,null,null,new Boolean(false),new Boolean(false),new Boolean(false))().isTrue()').must_equal false
    @context.eval('atLeastOneTrue(1,null,null)().isTrue()').must_equal false
  end
  
  def test_all_false
    @context.eval('allFalse(1,null,null,new Boolean(false),new Boolean(false),new Boolean(false))().isTrue()').must_equal true
    @context.eval('allFalse(1,null,null,new Boolean(false),new Boolean(true),new Boolean(false))().isTrue()').must_equal false
    @context.eval('allFalse(1,null,null,new Boolean(true),new Boolean(true),new Boolean(true))().isTrue()').must_equal false
    @context.eval('allFalse(1,null,null)().isTrue()').must_equal false
  end
  
  def test_at_least_one_false
    @context.eval('atLeastOneFalse(1,null,null,new Boolean(true),new Boolean(false),new Boolean(false))().isTrue()').must_equal true
    @context.eval('atLeastOneFalse(1,null,null,new Boolean(true),new Boolean(true),new Boolean(true))().isTrue()').must_equal false
    @context.eval('atLeastOneFalse(1,null,null,new Boolean(false),new Boolean(false),new Boolean(false))().isTrue()').must_equal true
    @context.eval('atLeastOneFalse(1,null,null)().isTrue()').must_equal false
  end
  
  def test_patient_extensions
    @context.eval('typeof hQuery.Patient.prototype.procedureResults').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.laboratoryTests').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.allMedications').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.allProblems').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.allDevices').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.activeDiagnoses').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.inactiveDiagnoses').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.resolvedDiagnoses').must_equal "function"
    @context.eval('typeof hQuery.Patient.prototype.getEvents').must_equal "function"
  end

  def test_code_list
    @context.eval('(new CodeList({"foo": [10,11]})).match(10)').must_equal true
    @context.eval('(new CodeList({"foo": [10,11]})).match({"code": 10})').must_equal true
    @context.eval('(new CodeList({"foo": [10,11]})).match(12)').must_equal false
    @context.eval('(new CodeList({"foo": [10,11]})).match({"code": 12})').must_equal false
  end
  
  def test_pq
    pq = "new PQ(1, 'mo')"
    pq2 = "new PQ(2, 'mo')"
    val = "{'scalar': 0}"
    val1 = "{'scalar': 1}"
    val2 = "{'scalar': 2}"
    assert_equal 1, @context.eval("#{pq}.value")
    assert_equal "mo", @context.eval("#{pq}.unit")
    assert @context.eval("#{pq}.lessThan(3)")
    assert @context.eval("#{pq}.greaterThan(0)")
    assert @context.eval("#{pq}.match(1)")
    assert @context.eval("#{pq}.lessThan(#{pq2})")
    assert @context.eval("#{pq2}.greaterThan(#{pq})")
    assert @context.eval("#{pq}.match(#{val1})")
    assert @context.eval("#{pq}.lessThan(#{val2})")
    assert @context.eval("#{pq}.greaterThan(#{val})")
  end
  
  def test_ts
    # TS - Timestamp 2010-01-01
    ts = 'new TS("20110101")'
    ts2 = 'new TS("20100101")'
    ts3 = 'new TS("20120101")'
    assert_equal 2011, @context.eval("#{ts}.asDate().getUTCFullYear()")
    assert_equal 0, @context.eval("#{ts}.asDate().getUTCMonth()")
    assert_equal 1, @context.eval("#{ts}.asDate().getUTCDate()")
    assert_equal 2012, @context.eval("#{ts}.add(new PQ(1, 'a')).asDate().getUTCFullYear()")
    assert_equal 2, @context.eval("#{ts}.add(new PQ(1, 'd')).asDate().getUTCDate()")
    assert_equal 8, @context.eval("#{ts}.add(new PQ(1, 'wk')).asDate().getUTCDate()")
    assert_equal 1, @context.eval("#{ts}.add(new PQ(1, 'h')).asDate().getUTCHours()")
    assert_equal 5, @context.eval("#{ts}.add(new PQ(5, 'min')).asDate().getUTCMinutes()")
    assert_equal 11, @context.eval("#{ts}.add(new PQ(-1, 'mo')).asDate().getUTCMonth()")
    assert @context.eval("#{ts2}.before(#{ts})")
    assert @context.eval("#{ts3}.after(#{ts})")
    assert !@context.eval("#{ts}.before(#{ts2})")
    assert !@context.eval("#{ts}.after(#{ts3})")
    assert @context.eval("#{ts}.beforeOrConcurrent(#{ts})")
    assert @context.eval("#{ts}.afterOrConcurrent(#{ts})")
    
    # The following tests are taken from the Joint Commission guidance on time difference
    # calculations
    
    # Year difference calculation
    ts1 = 'new TS("20120310220509")'
    ts2 = 'new TS("20130218191003")'
    assert_equal 0, @context.eval("#{ts1}.difference(#{ts2},'a')")
    
    ts1 = 'new TS("20120310220509")'
    ts2 = 'new TS("20130310080159")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'a')")
    
    ts1 = 'new TS("20120310220509")'
    ts2 = 'new TS("20130320040130")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'a')")
    
    ts1 = 'new TS("20120229")'
    ts2 = 'new TS("20140228")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'a')")
    
    ts1 = 'new TS("20120310111602")'
    ts2 = 'new TS("20130815213416")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'a')")
    
    ts1 = 'new TS("20120229101856")'
    ts2 = 'new TS("20140301190234")'
    assert_equal 2, @context.eval("#{ts1}.difference(#{ts2},'a')")
    
    # Month difference calculation
    ts1 = 'new TS("20120301140545")'
    ts2 = 'new TS("20120331230149")'
    assert_equal 0, @context.eval("#{ts1}.difference(#{ts2},'mo')")
    
    ts1 = 'new TS("20120310220509")'
    ts2 = 'new TS("20130630130023")'
    assert_equal 15, @context.eval("#{ts1}.difference(#{ts2},'mo')")
    
    ts1 = 'new TS("20120310220509")'
    ts2 = 'new TS("20130129071933")'
    assert_equal 10, @context.eval("#{ts1}.difference(#{ts2},'mo')")
    
    # Week difference calculation
    ts1 = 'new TS("20120310220509")'
    ts2 = 'new TS("20120320071933")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'wk')")
    
    # Day difference calculation
    ts1 = 'new TS("20120131123000")'
    ts2 = 'new TS("20120201090000")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'d')")
    
    ts1 = 'new TS("20120131123000")'
    ts2 = 'new TS("20120201140000")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'d')")
    
    # Hour difference calculation
    ts1 = 'new TS("201203010310")'
    ts2 = 'new TS("201203010510")'
    assert_equal 2, @context.eval("#{ts1}.difference(#{ts2},'h')")
    
    ts1 = 'new TS("201202292310")'
    ts2 = 'new TS("201203010010")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'h')")
    
    ts1 = 'new TS("201203010310")'
    ts2 = 'new TS("201203010400")'
    assert_equal 0, @context.eval("#{ts1}.difference(#{ts2},'h')")
    
    # Minute difference calculation
    ts1 = 'new TS("201203010310")'
    ts2 = 'new TS("201203010520")'
    assert_equal 130, @context.eval("#{ts1}.difference(#{ts2},'min')")

    ts1 = 'new TS("201202292310")'
    ts2 = 'new TS("201203010020")'
    assert_equal 70, @context.eval("#{ts1}.difference(#{ts2},'min')")
    
    ts1 = 'new TS("20120101101010")'
    ts2 = 'new TS("20120101101030")'
    assert_equal 0, @context.eval("#{ts1}.difference(#{ts2},'min')")
    
    ts1 = 'new TS("20120101100950")'
    ts2 = 'new TS("20120101101010")'
    assert_equal 1, @context.eval("#{ts1}.difference(#{ts2},'min')")

    # Additional tests from previous version of TJC guidance
    ts4 = 'new TS("20000310")'
    ts5 = 'new TS("20110405")'
    ts6 = 'new TS("20000229")'
    ts7 = 'new TS("20110228")'
    ts8 = 'new TS("20120228")'
    assert_equal 11, @context.eval("#{ts4}.difference(#{ts5},'a')")
    assert_equal 11, @context.eval("#{ts5}.difference(#{ts4},'a')")
    assert_equal 10, @context.eval("#{ts6}.difference(#{ts7},'a')")
    assert_equal 10, @context.eval("#{ts7}.difference(#{ts6},'a')")
    assert_equal 1, @context.eval("#{ts7}.difference(#{ts8},'a')")
    assert_equal 1, @context.eval("#{ts8}.difference(#{ts7},'a')")
    ts9 = 'new TS("20000229")'
    ts10 = 'new TS("20010330")'
    ts11 = 'new TS("20101228")'
    ts12 = 'new TS("20110217")'
    ts13 = 'new TS("20080320")'
    ts14 = 'new TS("20080401")'
    assert_equal 13, @context.eval("#{ts9}.difference(#{ts10},'mo')")
    assert_equal 1, @context.eval("#{ts11}.difference(#{ts12},'mo')")
    assert_equal 0, @context.eval("#{ts13}.difference(#{ts14},'mo')")
    ts15 = 'new TS("201203010310")'
    ts16 = 'new TS("201203010520")'
    ts17 = 'new TS("201202292310")'
    ts18 = 'new TS("201203010020")'
    assert_equal 130, @context.eval("#{ts15}.difference(#{ts16},'min')")
    assert_equal 70, @context.eval("#{ts17}.difference(#{ts18},'min')")
    ts19 = 'new TS("201203010310")'
    ts20 = 'new TS("201203010520")'
    ts21 = 'new TS("201202292310")'
    ts22 = 'new TS("201203010010")'
    ts23 = 'new TS("201203010310")'
    ts24 = 'new TS("201203010400")'
    assert_equal 2, @context.eval("#{ts19}.difference(#{ts20},'h')")
    assert_equal 1, @context.eval("#{ts21}.difference(#{ts22},'h')")
    assert_equal 0, @context.eval("#{ts23}.difference(#{ts24},'h')")
    ts25 = 'new TS("200002280900")'
    ts26 = 'new TS("200002292359")'
    ts27 = 'new TS("200012282300")'
    ts28 = 'new TS("200101010800")'
    ts29 = 'new TS("200002280900")'
    ts30 = 'new TS("200002282359")'
    assert_equal 1, @context.eval("#{ts25}.difference(#{ts26},'d')")
    assert_equal 4, @context.eval("#{ts27}.difference(#{ts28},'d')")
    assert_equal 0, @context.eval("#{ts29}.difference(#{ts30},'d')")
    ts31 = 'new TS("20120403")'
    ts32 = 'new TS("20120410")'
    ts33 = 'new TS("20120229")'
    ts34 = 'new TS("20120328")'
    assert_equal 0, @context.eval("#{ts31}.difference(#{ts31},'wk')")
    assert_equal 1, @context.eval("#{ts31}.difference(#{ts32},'wk')")
    assert_equal 4, @context.eval("#{ts33}.difference(#{ts34},'wk')")
  end
  
  def test_cd
    # CD - Code
    cd = "new CD('M')"
    assert_equal 'M', @context.eval("#{cd}.code")
    assert @context.eval("#{cd}.match('M')")
    assert !@context.eval("#{cd}.match('F')")
  end
  
  def test_iv_pq
    # IVL_PQ - Range
    ivl = "new IVL_PQ(new PQ(1, 'mo'), new PQ(10, 'mo'))"
    assert_equal 1, @context.eval("#{ivl}.low_pq.value")
    assert_equal 10, @context.eval("#{ivl}.high_pq.value")
    assert @context.eval("#{ivl}.match(5)")
    assert !@context.eval("#{ivl}.match(0)")
    assert !@context.eval("#{ivl}.match(11)")
    # IVL with null values on the ends
    assert @context.eval("new IVL_PQ(null, new PQ(10, 'mo')).match(5)")
    assert !@context.eval("new IVL_PQ(null, new PQ(10, 'mo')).match(11)")
    assert @context.eval("new IVL_PQ(new PQ(1, 'mo'), null).match(2)")
    assert !@context.eval("new IVL_PQ(new PQ(1, 'mo'), null).match(0)")
  end
  
  def test_ivl_ts
    # IVL_TS - Time Range
    ivl1 = 'new IVL_TS(new TS("20120310"), new TS("20120320"))'
    ivl2 = 'new IVL_TS(new TS("20120312"), new TS("20120320"))'
    assert @context.eval("#{ivl2}.DURING(#{ivl1})")
    assert_equal 2010, @context.eval('getIVL(new Date(Date.UTC(2010,1,1))).low.asDate().getUTCFullYear()')
  end
  
  def test_any_non_null
    # ANYNonNull
    ann = 'new ANYNonNull()'
    assert @context.eval("#{ann}.match('foo')")
    assert @context.eval("#{ann}.match(10)")
    assert @context.eval("#{ann}.match(0)")
    assert @context.eval("#{ann}.match({'scalar': 10})")
    assert @context.eval("#{ann}.match({'scalar': 0})")
    assert !@context.eval("#{ann}.match(null)")
    assert !@context.eval("#{ann}.match({'scalar': null})")
  end
  
  def test_matching_value
    # Matching value
    assert @context.eval("matchingValue(5, new IVL_PQ(PQ(3, 'mo'), new PQ(9, 'mo'))).isTrue()")
    assert !@context.eval("matchingValue(12, new IVL_PQ(PQ(3, 'mo'), new PQ(9, 'mo'))).isTrue()")
  end
  
  def test_count
    # COUNT
    events0 = '[]'
    events1 = '[1]'
    events2 = '[1,2]'
    exactly0 = 'new IVL_PQ(new PQ(0), new PQ(0))'
    exactly1 = 'new IVL_PQ(new PQ(1), new PQ(1))'
    moreThanZero = 'new IVL_PQ(new PQ(1))'
    lessThanTwo = 'new IVL_PQ(null, new PQ(1))'
    assert @context.eval("COUNT(#{events0}, #{exactly0}).isTrue()")
    assert !@context.eval("COUNT(#{events0}, #{exactly1}).isTrue()")
    assert !@context.eval("COUNT(#{events0}, #{moreThanZero}).isTrue()")
    assert @context.eval("COUNT(#{events0}, #{lessThanTwo}).isTrue()")
    assert !@context.eval("COUNT(#{events1}, #{exactly0}).isTrue()")
    assert @context.eval("COUNT(#{events1}, #{exactly1}).isTrue()")
    assert @context.eval("COUNT(#{events1}, #{moreThanZero}).isTrue()")
    assert @context.eval("COUNT(#{events1}, #{lessThanTwo}).isTrue()")
    assert !@context.eval("COUNT(#{events2}, #{exactly0}).isTrue()")
    assert !@context.eval("COUNT(#{events2}, #{exactly1}).isTrue()")
    assert @context.eval("COUNT(#{events2}, #{moreThanZero}).isTrue()")
    assert !@context.eval("COUNT(#{events2}, #{lessThanTwo}).isTrue()")
  end
  
  def test_union
    # UNION
    events0 = '[]'
    events1 = '[1]'
    events2 = '[2,3]'
    assert @context.eval("UNION().length===0")
    assert @context.eval("UNION(#{events0}).length===0")
    assert @context.eval("UNION(#{events1}).length===1")
    assert @context.eval("UNION(#{events1},#{events2}).length===3")
    assert @context.eval("UNION(#{events0},#{events2}).length===2")
  end

  def test_xproduct  
    # XPRODUCT
    events0 = '[]'
    events1 = '[1]'
    events2 = '[2,3]'
    assert_equal 0, @context.eval("XPRODUCT().length")
    assert_equal 0, @context.eval("XPRODUCT(#{events0}).length")
    assert_equal 1, @context.eval("XPRODUCT(#{events0}).eventLists.length")
    assert_equal 1, @context.eval("XPRODUCT(#{events1}).length")
    assert_equal 1, @context.eval("XPRODUCT(#{events1}).eventLists.length")
    assert_equal 3, @context.eval("XPRODUCT(#{events1},#{events2}).length")
    assert_equal 2, @context.eval("XPRODUCT(#{events1},#{events2}).eventLists.length")
    assert_equal 2, @context.eval("XPRODUCT(#{events0},#{events2}).length")
    assert_equal 2, @context.eval("XPRODUCT(#{events0},#{events2}).eventLists.length")
  end

  def test_intersection
    # XPRODUCT
    events0 = '[]'
    events1 = '[{id:1}]'
    events2 = '[{id:2},{id:3},{id:4}]'
    events3 = '[{id:3},{id:5}]'
    assert_equal 0, @context.eval("INTERSECT().length")
    assert_equal 0, @context.eval("INTERSECT(#{events0}).length")
    assert_equal 3, @context.eval("INTERSECT(#{events2}).length")
    assert_equal 0, @context.eval("INTERSECT(#{events1},#{events2}).length")
    assert_equal 0, @context.eval("INTERSECT(#{events0},#{events2}).length")
    assert_equal 1, @context.eval("INTERSECT(#{events2},#{events3}).length")
    assert_equal 0, @context.eval("INTERSECT(#{events2},#{events3},#{events1}).length")
  end
  
  def test_temporal_operators
    # Events and bounds for temporal operators
    @context.eval('var events1 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120105"), new TS("20120105"));}}]')
    @context.eval('var events2 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120102"), new TS("20120105"));}}]')
    @context.eval('var events3 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120105203030"), new TS("20120105203030"));}}]')
    @context.eval('var nullEndEvent = new IVL_TS(new TS("20110101"), new TS("20120105"));')
    @context.eval('nullEndEvent.high.date = null;')
    @context.eval('var events4 = [{"asIVL_TS": function() {return nullEndEvent;}}]')
    @context.eval('var events5 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20140101"), new TS("20140201"));}}]')
    @context.eval('var events6 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20101101"), new TS("20110101"));}}]')
    @context.eval('var events7 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20110101"), new TS("20110201"));}}]')
    @context.eval('var bound1 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120105"), new TS("20120105"));}}]')
    @context.eval('var bound2 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120107"), new TS("20120107"));}}]')
    @context.eval('var bound3 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120103"), new TS("20120107"));}}]')
    @context.eval('var bound4 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120106"), new TS("20120107"));}}]')
    @context.eval('var bound5 = {"asIVL_TS": function() {return new IVL_TS(new TS("20120106"), new TS("20120107"));}}')
    @context.eval('var nullStartBound = new IVL_TS(new TS("20120105"), new TS("20120105"));')
    @context.eval('nullStartBound.low.date = null;')
    @context.eval('var nullEndBound = new IVL_TS(new TS("20140601"), new TS("20140601"));')
    @context.eval('nullEndBound.high.date = null;')
    @context.eval('var bound6 = {"asIVL_TS": function() {return nullStartBound;}}')
    @context.eval('var bound7 = [{"asIVL_TS": function() {return new IVL_TS(new TS("20120105193030"), new TS("20120105193030"));}}]')
    @context.eval('var bound8 = {"asIVL_TS": function() {return nullEndBound;}}')
    @context.eval('var range1 = new IVL_PQ(null, new PQ(1, "d"))')
    @context.eval('var range2 = new IVL_PQ(new PQ(1, "d"), null)')
    @context.eval('var range3 = new IVL_PQ(new PQ(0, "d"), null)')
    @context.eval('var range4 = new IVL_PQ(null, new PQ(3, "d"))')
    
    # DURING
    assert_equal 1, @context.eval('DURING(events1, bound1)').count
    assert_equal 0, @context.eval('DURING(events1, bound2)').count
    assert_equal 1, @context.eval('DURING(events1, bound3)').count
    assert_equal 0, @context.eval('DURING(events1, bound4)').count
    assert_equal 0, @context.eval('DURING(events1, bound5)').count
    assert_equal 0, @context.eval('DURING(events1, bound6)').count
    assert_equal 0, @context.eval('DURING(events2, bound3)').count
    assert_equal 0, @context.eval('DURING(events2, bound4)').count
    assert_equal 0, @context.eval('DURING(events2, bound5)').count
    assert_equal 0, @context.eval('DURING(events2, bound6)').count
    assert_equal 0, @context.eval('DURING(events2, bound1)').count
    assert_equal 0, @context.eval('DURING(events2, bound2)').count
    assert_equal 1, @context.eval('DURING(events1, XPRODUCT(bound1))').count
    assert_equal 0, @context.eval('DURING(events1, XPRODUCT(bound2))').count
    assert_equal 0, @context.eval('DURING(events1, XPRODUCT(bound1, bound2))').count
    assert_equal 1, @context.eval('DURING(events1, XPRODUCT(bound3))').count
    assert_equal 1, @context.eval('DURING(events1, XPRODUCT(bound1, bound3))').count
    assert_equal 0, @context.eval('DURING(events1, XPRODUCT(bound4))').count
    assert_equal 0, @context.eval('DURING(events1, XPRODUCT(bound5))').count
    assert_equal 0, @context.eval('DURING(events1, XPRODUCT(bound6))').count
    assert_equal 0, @context.eval('DURING(events2, XPRODUCT(bound3))').count
    assert_equal 0, @context.eval('DURING(events2, XPRODUCT(bound4))').count
    assert_equal 0, @context.eval('DURING(events2, XPRODUCT(bound5))').count
    assert_equal 0, @context.eval('DURING(events2, XPRODUCT(bound6))').count
    assert_equal 0, @context.eval('DURING(events2, XPRODUCT(bound1))').count
    assert_equal 0, @context.eval('DURING(events2, XPRODUCT(bound2))').count
    
    # OVERLAP
    assert_equal 1, @context.eval('OVERLAP(events1, bound1)').count
    assert_equal 0, @context.eval('OVERLAP(events1, bound2)').count
    assert_equal 1, @context.eval('OVERLAP(events1, bound3)').count
    assert_equal 0, @context.eval('OVERLAP(events1, bound4)').count
    assert_equal 0, @context.eval('OVERLAP(events1, bound5)').count
    assert_equal 0, @context.eval('OVERLAP(events1, bound6)').count
    assert_equal 1, @context.eval('OVERLAP(events2, bound3)').count
    assert_equal 0, @context.eval('OVERLAP(events2, bound4)').count
    assert_equal 0, @context.eval('OVERLAP(events2, bound5)').count
    assert_equal 0, @context.eval('OVERLAP(events2, bound6)').count
    assert_equal 1, @context.eval('OVERLAP(events2, bound1)').count
    assert_equal 0, @context.eval('OVERLAP(events2, bound2)').count
    assert_equal 1, @context.eval('OVERLAP(events1, XPRODUCT(bound1))').count
    assert_equal 0, @context.eval('OVERLAP(events1, XPRODUCT(bound2))').count
    assert_equal 0, @context.eval('OVERLAP(events1, XPRODUCT(bound1, bound2))').count
    assert_equal 1, @context.eval('OVERLAP(events1, XPRODUCT(bound3))').count
    assert_equal 1, @context.eval('OVERLAP(events1, XPRODUCT(bound1, bound3))').count
    assert_equal 0, @context.eval('OVERLAP(events1, XPRODUCT(bound4))').count
    assert_equal 0, @context.eval('OVERLAP(events1, XPRODUCT(bound5))').count
    assert_equal 0, @context.eval('OVERLAP(events1, XPRODUCT(bound6))').count
    assert_equal 1, @context.eval('OVERLAP(events2, XPRODUCT(bound3))').count
    assert_equal 0, @context.eval('OVERLAP(events2, XPRODUCT(bound4))').count
    assert_equal 0, @context.eval('OVERLAP(events2, XPRODUCT(bound5))').count
    assert_equal 0, @context.eval('OVERLAP(events2, XPRODUCT(bound6))').count
    assert_equal 1, @context.eval('OVERLAP(events2, XPRODUCT(bound1))').count
    assert_equal 0, @context.eval('OVERLAP(events2, XPRODUCT(bound2))').count
    ## Overlap with null ending
    assert_equal 1, @context.eval('OVERLAP(events4, bound8)').count
    assert_equal 1, @context.eval('OVERLAP(events4, bound1)').count
    assert_equal 0, @context.eval('OVERLAP(events5, bound8)').count
    assert_equal 1, @context.eval('OVERLAP(events6, events4)').count
    assert_equal 1, @context.eval('OVERLAP(events4, events7)').count
    
    # SCW
    assert_equal 1, @context.eval('SCW(events1, bound1)').count
    assert_equal 0, @context.eval('SCW(events1, bound6)').count
    assert_equal 0, @context.eval('SCW(events1, bound2)').count

    # SBS
    assert_equal 0, @context.eval('SBS(events1, bound1)').count
    assert_equal 0, @context.eval('SBS(events2, bound1, range1)').count
    assert_equal 1, @context.eval('SBS(events2, bound1)').count
    assert_equal 1, @context.eval('SBS(events2, bound1, range2)').count
    assert_equal 0, @context.eval('SBS(events3, bound7, range3)').count
    
    #SBCW
    assert_equal 1, @context.eval('SBCW(events1, bound1)').count
    assert_equal 0, @context.eval('SBCW(events2, bound1, range1)').count
    assert_equal 1, @context.eval('SBCW(events2, bound1)').count
    assert_equal 1, @context.eval('SBCW(events2, bound1, range2)').count
    assert_equal 0, @context.eval('SBCW(events3, bound7, range3)').count
    assert_equal 0, @context.eval('SBCW(events1, bound6)').count
    assert_equal 1, @context.eval('SBCW(events1, bound2)').count

    # SAS
    assert_equal 0, @context.eval('SAS(events1, bound1)').count
    assert_equal 0, @context.eval('SAS(events2, bound1, range1)').count
    assert_equal 0, @context.eval('SAS(events2, bound1)').count
    assert_equal 0, @context.eval('SAS(events2, bound1, range2)').count
    
    #SACW
    assert_equal 1, @context.eval('SACW(events1, bound1)').count
    assert_equal 0, @context.eval('SACW(events2, bound1, range1)').count
    assert_equal 0, @context.eval('SACW(events2, bound1)').count
    assert_equal 0, @context.eval('SACW(events2, bound1, range2)').count
    assert_equal 0, @context.eval('SACW(events1, bound6)').count
    assert_equal 0, @context.eval('SACW(events1, bound2)').count


    # SBDU
    assert_equal 0, @context.eval('SBDU(events2, bound1, range1)').count
    assert_equal 1, @context.eval('SBDU(events2, bound1)').count
    assert_equal 1, @context.eval('SBDU(events2, bound1, range2)').count
    assert_equal 0, @context.eval('SBDU(events3, bound7, range3)').count
    assert_equal 1, @context.eval('SBDU(events1, bound1)').count
    assert_equal 1, @context.eval('SBDU(events1, bound2)').count

    # SBE
    assert_equal 0, @context.eval('SBE(events1, bound1)').count
    assert_equal 1, @context.eval('SBE(events1, bound2)').count
    
    # SAE
    assert_equal 0, @context.eval('SAE(events1, bound1)').count
    assert_equal 1, @context.eval('SAE(bound2, events1)').count
    
    # EBS
    assert_equal 0, @context.eval('EBS(events1, bound1)').count
    assert_equal 1, @context.eval('EBS(events1, bound2)').count
    
    # EAS
    assert_equal 0, @context.eval('EAS(events1, bound1)').count
    assert_equal 1, @context.eval('EAS(events1, bound3)').count
    
    # EBE
    assert_equal 0, @context.eval('EBE(events1, bound1)').count
    assert_equal 1, @context.eval('EBE(events1, bound2)').count
    
    # EAE
    assert_equal 0, @context.eval('EAE(events1, bound1)').count
    assert_equal 1, @context.eval('EAE(bound3, events2)').count
    
    # SDU
    assert_equal 1, @context.eval('SDU(events1, bound1)').count
    assert_equal 0, @context.eval('SDU(events1, bound2)').count
    
    # EDU
    assert_equal 1, @context.eval('EDU(events1, bound1)').count
    assert_equal 0, @context.eval('EDU(events1, bound2)').count
    
    # ECW
    assert_equal 1, @context.eval('ECW(events1, bound1)').count
    assert_equal 1, @context.eval('ECW(events1, bound6)').count
    assert_equal 0, @context.eval('ECW(events1, bound2)').count
    
    #EBCW
    assert_equal 1, @context.eval('ECW(events1, bound1)').count
    assert_equal 1, @context.eval('ECW(events1, bound6)').count
    assert_equal 0, @context.eval('ECW(events1, bound2)').count
    assert_equal 0, @context.eval('EBE(events1, bound1)').count
    assert_equal 1, @context.eval('EBE(events1, bound2)').count
    
    #EBCWS
    assert_equal 0, @context.eval('EBS(events1, bound1)').count
    assert_equal 1, @context.eval('EBS(events1, bound2)').count

    #EACW
    assert_equal 1, @context.eval('EACW(events1, bound1)').count
    assert_equal 1, @context.eval('EACW(events1, bound6)').count
    assert_equal 0, @context.eval('EACW(events1, bound2)').count
    assert_equal 1, @context.eval('EACW(bound3, events2)').count
    
    #EACWS
    assert_equal 1, @context.eval('EACWS(events1, bound1)').count
    assert_equal 1, @context.eval('EACWS(events1, bound3)').count
  
    #EBDU
    assert_equal 1, @context.eval('EBDU(events1, bound1)').count
    assert_equal 1, @context.eval('EBDU(events1, bound2)').count
    
    # ECWS
    assert_equal 1, @context.eval('ECWS(events1, bound1)').count
    assert_equal 0, @context.eval('ECWS(events1, bound6)').count
    assert_equal 0, @context.eval('ECWS(events1, bound2)').count
    
    # SCWE
    assert_equal 1, @context.eval('SCWE(events1, bound1)').count
    assert_equal 1, @context.eval('SCWE(events1, bound6)').count
    assert_equal 0, @context.eval('SCWE(events1, bound2)').count
    
    # SBCWE
    assert_equal 1, @context.eval('SBCWE(events1, bound1)').count
    assert_equal 1, @context.eval('SBCWE(events1, bound6)').count
    assert_equal 1, @context.eval('SBCWE(events1, bound2)').count
    
    # SACWE
    assert_equal 1, @context.eval('SACWE(events1, bound1)').count
    assert_equal 1, @context.eval('SACWE(events1, bound6)').count
    assert_equal 0, @context.eval('SACWE(events1, bound2)').count
    assert_equal 1, @context.eval('SACWE(bound2, events1)').count

    # CONCURRENT
    assert_equal 1, @context.eval('CONCURRENT(events1, bound1)').count
    assert_equal 0, @context.eval('CONCURRENT(events1, bound2)').count

    #DATEDIFF
    @context.eval('var diffEvent1 = {"asIVL_TS": function() {return new IVL_TS(new TS("20120105"), new TS("20120105"));}, "timeStamp": function() {return new Date(Date.UTC(2012, 1, 5, 0, 0));}}')
    @context.eval('var diffEvent2 = {"asIVL_TS": function() {return new IVL_TS(new TS("20120107"), new TS("20120107"));}, "timeStamp": function() {return new Date(Date.UTC(2012, 1, 7, 0, 0));}}')
    @context.eval('var diffEvent3 = {"asIVL_TS": function() {return new IVL_TS(new TS("20120111"), new TS("20120111"));}, "timeStamp": function() {return new Date(Date.UTC(2012, 1, 11, 0, 0));}}')
    
    assert_equal true, @context.eval('DATEDIFF([diffEvent1,diffEvent2],range4).isTrue()')
    assert_equal true, @context.eval('DATEDIFF([diffEvent2,diffEvent1],range4).isTrue()')
    assert_equal true, @context.eval('DATEDIFF([diffEvent1,diffEvent1],range4).isTrue()')

    assert_equal true, @context.eval('DATETIMEDIFF([diffEvent1,diffEvent2],range4).isTrue()')
    assert_equal true, @context.eval('DATETIMEDIFF([diffEvent2,diffEvent1],range4).isTrue()')
    assert_equal true, @context.eval('DATETIMEDIFF([diffEvent1,diffEvent1],range4).isTrue()')


    @context.eval("
      var ts1 = new TS('20100101100000');
      var ts2 = new TS('20100101101000');
      var ts3 = new TS('20100101103000');
      
      var ddEvents1 = [{'id': 1, 'asTS': function() {return ts1;}}];
      var ddEvents2 = [{'id': 20, 'asTS': function() {return ts2;}}];
      var ddEvents3 = [{'id': 30, 'asTS': function() {return ts3;}, 'timeStamp': function() {return ts3.date}}, {'id': 20, 'asTS': function() {return ts2;}, 'timeStamp': function() {return ts2.date}}];
    ");

    @context.eval('DATETIMEDIFF(XPRODUCT(ddEvents1,ddEvents2)).length').must_equal 1
    @context.eval('DATETIMEDIFF(XPRODUCT(ddEvents1,ddEvents2))[0]').must_equal 10
    @context.eval('DATETIMEDIFF(XPRODUCT(ddEvents1,ddEvents3)).length').must_equal 1
    @context.eval('DATETIMEDIFF(XPRODUCT(ddEvents1,ddEvents3))[0]').must_equal 30
    @context.eval('DATETIMEDIFF(XPRODUCT(ddEvents2,ddEvents3)).length').must_equal 1
    @context.eval('DATETIMEDIFF(XPRODUCT(ddEvents2,ddEvents3))[0]').must_equal 20
    
  end
  
  def test_ordinal_operators
    # Ordinal operators
    ts20100101 = '{"timeStamp": function() {return new Date(2010,0,1);}, "asIVL_TS": function() {return new IVL_TS(new TS("20100101"), new TS("20100101"));}}'
    ts20100201 = '{"timeStamp": function() {return new Date(2010,1,1);}, "asIVL_TS": function() {return new IVL_TS(new TS("20100201"), new TS("20100201"));}}'
    ts20100301 = '{"timeStamp": function() {return new Date(2010,2,1);}, "asIVL_TS": function() {return new IVL_TS(new TS("20100301"), new TS("20100301"));}}'
    ts20100401 = '{"timeStamp": function() {return new Date(2010,3,1);}, "asIVL_TS": function() {return new IVL_TS(new TS("20100401"), new TS("20100401"));}}'
    ts20100501 = '{"timeStamp": function() {return new Date(2010,4,1);}, "asIVL_TS": function() {return new IVL_TS(new TS("20100501"), new TS("20100501"));}}'
    events0 = "[]"
    events1 = "[#{ts20100101}]"
    events2 = "[#{ts20100101},#{ts20100201}]"
    events3 = "[#{ts20100101},#{ts20100201},#{ts20100301}]"
    events4 = "[#{ts20100101},#{ts20100201},#{ts20100301},#{ts20100401}]"
    events5 = "[#{ts20100101},#{ts20100201},#{ts20100301},#{ts20100401},#{ts20100501}]"
    events6 = "[#{ts20100501},#{ts20100401},#{ts20100301},#{ts20100201},#{ts20100101}]"
    
    assert_equal 0, @context.eval("RECENT(#{events0})").count
    assert_equal 0, @context.eval("LAST(#{events0})").count
    assert_equal 0, @context.eval("FIRST(#{events0})").count
    assert_equal 0, @context.eval("SECOND(#{events1})").count
    assert_equal 0, @context.eval("THIRD(#{events2})").count
    assert_equal 0, @context.eval("FOURTH(#{events3})").count
    assert_equal 0, @context.eval("FIFTH(#{events4})").count

    assert_equal 1, @context.eval("RECENT(#{events1})").count
    assert_equal 1, @context.eval("LAST(#{events1})").count
    assert_equal 1, @context.eval("FIRST(#{events1})").count
    assert_equal 1, @context.eval("SECOND(#{events2})").count
    assert_equal 1, @context.eval("THIRD(#{events3})").count
    assert_equal 1, @context.eval("FOURTH(#{events4})").count
    assert_equal 1, @context.eval("FIFTH(#{events5})").count

    assert_equal 1, @context.eval("LAST(#{events6})").count
    assert_equal 4, @context.eval("LAST(#{events6})[0].timeStamp().getMonth()")
    assert_equal 1, @context.eval("RECENT(#{events6})").count
    assert_equal 4, @context.eval("RECENT(#{events6})[0].timeStamp().getMonth()")
    assert_equal 1, @context.eval("FIRST(#{events6})").count
    assert_equal 0, @context.eval("FIRST(#{events6})[0].timeStamp().getMonth()")
    assert_equal 1, @context.eval("SECOND(#{events6})").count
    assert_equal 1, @context.eval("SECOND(#{events6})[0].timeStamp().getMonth()")
    assert_equal 1, @context.eval("THIRD(#{events6})").count
    assert_equal 2, @context.eval("THIRD(#{events6})[0].timeStamp().getMonth()")
    assert_equal 1, @context.eval("FOURTH(#{events6})").count
    assert_equal 3, @context.eval("FOURTH(#{events6})[0].timeStamp().getMonth()")
    assert_equal 1, @context.eval("FIFTH(#{events6})").count
    assert_equal 4, @context.eval("FIFTH(#{events6})[0].timeStamp().getMonth()")
  end
  
  def test_summary_operators  
    # MIN and MAX
    v10 = '{"value": function() {return {"scalar": 10};}}'
    v20 = '{"value": function() {return {"scalar": 20};}}'
    events0 = "[]"
    events2 = "[#{v10},#{v20}]"
    exactly10 = 'new IVL_PQ(new PQ(10), new PQ(10))'
    exactly20 = 'new IVL_PQ(new PQ(20), new PQ(20))'
    moreThan10 = 'new IVL_PQ(new PQ(11))'
    lessThan20 = 'new IVL_PQ(null, new PQ(19))'
    between15and25 = 'new IVL_PQ(new PQ(15), new PQ(25))'
    assert !@context.eval("MIN(#{events0},#{exactly10}).isTrue()")
    assert !@context.eval("MAX(#{events0},#{exactly10}).isTrue()")
    assert !@context.eval("MIN(#{events0},#{exactly20}).isTrue()")
    assert !@context.eval("MAX(#{events0},#{exactly20}).isTrue()")
    assert @context.eval("MIN(#{events2},#{exactly10}).isTrue()")
    assert !@context.eval("MAX(#{events2},#{exactly10}).isTrue()")
    assert !@context.eval("MIN(#{events2},#{exactly20}).isTrue()")
    assert @context.eval("MAX(#{events2},#{exactly20}).isTrue()")
    assert !@context.eval("MIN(#{events2},#{moreThan10}).isTrue()")
    assert @context.eval("MAX(#{events2},#{moreThan10}).isTrue()")
    assert @context.eval("MIN(#{events2},#{lessThan20}).isTrue()")
    assert !@context.eval("MAX(#{events2},#{lessThan20}).isTrue()")
    assert !@context.eval("MIN(#{events2},#{between15and25}).isTrue()")
    assert @context.eval("MAX(#{events2},#{between15and25}).isTrue()")
  end
  
  def test_respond_to
    assert @context.eval("(new hQuery.Allergy({})).respondTo('severity')")
    assert !@context.eval("(new hQuery.Allergy({})).respondTo('canHasCheeseburger')")
  end
end