require_relative '../test_helper'
require 'hquery-patient-api'

class SpecificsTest < Minitest::Test
  
  def setup
    @context = get_js_context(HQMF2JS::Generator::JS.library_functions)
    test_initialize_js = 
    "
      hqmf.SpecificsManager.initialize({},hqmfjs, {'id':'OccurrenceAEncounter', 'type':'Encounter', 'function':'SourceOccurrenceAEncounter'},{'id':'OccurrenceBEncounter', 'type':'Encounter', 'function':'SourceOccurrenceBEncounter'})
      hqmfjs.SourceOccurrenceAEncounter = function(patient) {
        return [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5}]
      }
      hqmfjs.SourceOccurrenceBEncounter = function(patient) {
        return [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5}]
      }
    "
    @context.eval(test_initialize_js)
  end


  def test_specifics_initialized_properly
    
    assert_equal 'OccurrenceAEncounter', @context.eval('hqmf.SpecificsManager.keyLookup[0]')
    assert_equal 'OccurrenceBEncounter', @context.eval('hqmf.SpecificsManager.keyLookup[1]')
    assert_equal 0, @context.eval("hqmf.SpecificsManager.indexLookup['OccurrenceAEncounter']")
    assert_equal 1, @context.eval("hqmf.SpecificsManager.indexLookup['OccurrenceBEncounter']")
    assert_equal 'SourceOccurrenceAEncounter', @context.eval('hqmf.SpecificsManager.functionLookup[0]')
    assert_equal 'SourceOccurrenceBEncounter', @context.eval('hqmf.SpecificsManager.functionLookup[1]')
    assert_equal 2, @context.eval("hqmf.SpecificsManager.typeLookup['Encounter'].length")
    assert_equal 0, @context.eval("hqmf.SpecificsManager.typeLookup['Encounter'][0]")
    assert_equal 1, @context.eval("hqmf.SpecificsManager.typeLookup['Encounter'][1]")
  end
  
  def test_specifics_row_union
    
    union_rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var specific1 = new hqmf.SpecificOccurrence([row1]);
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceBEncounter':{'id':2}});
      var specific2 = new hqmf.SpecificOccurrence([row2]);
      result = specific1.union(specific2);
      result.rows.length;
    "
    
    assert_equal 2, @context.eval(union_rows)
    assert_equal 1, @context.eval("result.rows[0].values[0].id")
    assert_equal '*', @context.eval("result.rows[0].values[1]")
    assert_equal '*', @context.eval("result.rows[1].values[0]")
    assert_equal 2, @context.eval("result.rows[1].values[1].id")
    
  end

  def test_row_creation
    
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row(undefined, {});
    "
    
    @context.eval(rows)
    assert_equal 1, @context.eval("row1.values[0].id")
    assert_equal '*', @context.eval("row1.values[1]")
    assert_equal '*', @context.eval("row2.values[0]")
    assert_equal 2, @context.eval("row2.values[1].id")
    assert_equal 1, @context.eval("row3.values[0].id")
    assert_equal 2, @context.eval("row3.values[1].id")
    assert_equal '*', @context.eval("row4.values[0]")
    assert_equal '*', @context.eval("row4.values[1]")
  end
    
  
  def test_row_match
    rows = "
      var row1 = new Row(undefined, {});
    "
    @context.eval(rows)
    assert_equal 1, @context.eval("Row.match('*', {'id':1}).id")
    assert_equal 2, @context.eval("Row.match({'id':2}, '*').id")
    assert_equal 1, @context.eval("Row.match({'id':1}, {'id':1}).id")
    assert_equal '*', @context.eval("Row.match('*', '*')")
    assert_equal true, @context.eval("typeof(Row.match({'id':3}, {'id':2})) === 'undefined'")
    
  end
  
  
  def test_row_equal
    
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':3}});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row(undefined,{});
    "
    
    @context.eval(rows)
    assert_equal true, @context.eval("row1.equals(row1)")
    assert_equal false, @context.eval("row1.equals(row2)")
    assert_equal true, @context.eval("row2.equals(row2)")
    assert_equal false, @context.eval("row3.equals(row4)")
    assert_equal true, @context.eval("row4.equals(row5)")
    assert_equal true, @context.eval("row6.equals(row6)")
    
  end
  
  
  def test_row_intersect
    
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':2}});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row(undefined,{});
    "
    
    @context.eval(rows)
    assert_equal 1, @context.eval("row1.intersect(row2).values[0].id")
    assert_equal 2, @context.eval("row1.intersect(row2).values[1].id")
    assert_equal 1, @context.eval("row2.intersect(row1).values[0].id")
    assert_equal 2, @context.eval("row2.intersect(row1).values[1].id")
    assert_equal 1, @context.eval("row1.intersect(row3).values[0].id")
    assert_equal 2, @context.eval("row1.intersect(row3).values[1].id")
    assert_equal 1, @context.eval("row2.intersect(row3).values[0].id")
    assert_equal 2, @context.eval("row2.intersect(row3).values[1].id")
    assert_equal true, @context.eval("typeof(row1.intersect(row4)) === 'undefined'")
    assert_equal 2, @context.eval("row2.intersect(row4).values[0].id")
    assert_equal 2, @context.eval("row2.intersect(row4).values[1].id")
    assert_equal true, @context.eval("typeof(row1.intersect(row5)) === 'undefined'")
    assert_equal true, @context.eval("typeof(row2.intersect(row5)) === 'undefined'")
    assert_equal true, @context.eval("typeof(row3.intersect(row4)) === 'undefined'")
    assert_equal 1, @context.eval("row1.intersect(row6).values[0].id")
    assert_equal '*', @context.eval("row1.intersect(row6).values[1]")
    assert_equal '*', @context.eval("row2.intersect(row6).values[0]")
    assert_equal 2, @context.eval("row2.intersect(row6).values[1].id")
    assert_equal '*', @context.eval("row6.intersect(row6).values[0]")
    assert_equal '*', @context.eval("row6.intersect(row6).values[1]")
    
  end
  
  def test_specifics_row_intersection
    
    intersect_rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':2}});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1]);
      var specific2 = new hqmf.SpecificOccurrence([row2]);
      var specific3 = new hqmf.SpecificOccurrence([row3,row4]);
      var specific4 = new hqmf.SpecificOccurrence([row3,row6]);
      var specific5 = new hqmf.SpecificOccurrence([row5,row6]);
      
      var allSpecific1 = new hqmf.SpecificOccurrence();
      allSpecific1.addIdentityRow();
      allSpecific1.addIdentityRow();
      allSpecific1.addIdentityRow();
      var allSpecific2 = new hqmf.SpecificOccurrence();
      allSpecific2.addIdentityRow();
      allSpecific2.addIdentityRow();
      allSpecific2.addIdentityRow();
      
    "
    
    @context.eval(intersect_rows)
    assert_equal 1, @context.eval("specific1.intersect(specific2).rows.length")
    assert_equal 1, @context.eval("specific1.intersect(specific2).rows[0].values[0].id")
    assert_equal 2, @context.eval("specific1.intersect(specific2).rows[0].values[1].id")
  
    assert_equal 1, @context.eval("specific1.intersect(specific3).rows.length")
    assert_equal 1, @context.eval("specific1.intersect(specific3).rows[0].values[0].id")
    assert_equal 2, @context.eval("specific1.intersect(specific3).rows[0].values[1].id")
  
    assert_equal 2, @context.eval("specific1.intersect(specific4).rows.length")
    assert_equal 1, @context.eval("specific1.intersect(specific4).rows[0].values[0].id")
    assert_equal 2, @context.eval("specific1.intersect(specific4).rows[0].values[1].id")
    assert_equal 1, @context.eval("specific1.intersect(specific4).rows[1].values[0].id")
    assert_equal 3, @context.eval("specific1.intersect(specific4).rows[1].values[1].id")
  
    assert_equal 2, @context.eval("specific2.intersect(specific3).rows.length")
    assert_equal 1, @context.eval("specific2.intersect(specific3).rows[0].values[0].id")
    assert_equal 2, @context.eval("specific2.intersect(specific3).rows[0].values[1].id")
    assert_equal 2, @context.eval("specific2.intersect(specific3).rows[1].values[0].id")
    assert_equal 2, @context.eval("specific2.intersect(specific3).rows[1].values[1].id")
    
    assert_equal 0, @context.eval("specific2.intersect(specific5).rows.length")
    
    assert_equal 1, @context.eval("specific4.intersect(specific5).rows.length")
    assert_equal 1, @context.eval("specific4.intersect(specific5).rows[0].values[0].id")
    assert_equal 3, @context.eval("specific4.intersect(specific5).rows[0].values[1].id")


    assert_equal 1, @context.eval("allSpecific1.intersect(allSpecific2).rows.length")
    
  end
  
  def test_specifics_timediff
    init_rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':20}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':20}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':30}});
      
      var specific = new hqmf.SpecificOccurrence([row1,row2,row3]);
      
      var ts1 = new TS('20100101100000');
      var ts2 = new TS('20100101101000');
      
      var events1 = [{'id': 1, 'asTS': function() {return ts1;}}];
      events1.specific_occurrence = 'OccurrenceAEncounter';
      var events2 = [{'id': 20, 'asTS': function() {return ts2;}},{'id': 30, 'asTS': function() {return ts2;}}];
      events2.specific_occurrence = 'OccurrenceBEncounter';
      var timediffs = TIMEDIFF(XPRODUCT(events1, events2), null, specific);
    "
    
    @context.eval(init_rows)
    assert_equal 1, @context.eval("timediffs.length")
    assert_equal 10, @context.eval("timediffs[0]")
  end

  def test_specifics_datetimediff
    init_rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':20}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':20}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':30}});
      
      var specific = new hqmf.SpecificOccurrence([row1,row2,row3]);
      
      var ts1 = new TS('20100101100000');
      var ts2 = new TS('20100101101000');
      
      var events1 = [{'id': 1, 'asTS': function() {return ts1;}}];
      events1.specific_occurrence = 'OccurrenceAEncounter';
      var events2 = [{'id': 20, 'asTS': function() {return ts2;}},{'id': 30, 'asTS': function() {return ts2;}}];
      events2.specific_occurrence = 'OccurrenceBEncounter';
      var timediffs = DATETIMEDIFF(XPRODUCT(events1, events2), null, specific);
    "
    
    @context.eval(init_rows)
    assert_equal 1, @context.eval("timediffs.length")
    assert_equal 10, @context.eval("timediffs[0]")
  end
  
  def test_specifics_event_counting
    
    init_rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':20}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':20}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':30}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':'*'});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':'*'});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':'*'});
      
      var specific = new hqmf.SpecificOccurrence([row1,row2,row3,row4,row5,row6]);
      specific.addIdentityRow();

      var pop = new Boolean(true);
      pop.specificContext = specific;  
    "
    
    @context.eval(init_rows)
    assert_equal 3, @context.eval("specific.uniqueEvents([0])")
    assert_equal 2, @context.eval("specific.uniqueEvents([1])")
    assert_equal 0, @context.eval('hqmf.SpecificsManager.indexLookup["OccurrenceAEncounter"]')
    assert_equal 1, @context.eval('hqmf.SpecificsManager.indexLookup["OccurrenceBEncounter"]')
    assert_equal 0, @context.eval('hqmf.SpecificsManager.getColumnIndex("OccurrenceAEncounter")')
    assert_equal 1, @context.eval('hqmf.SpecificsManager.getColumnIndex("OccurrenceBEncounter")')
    assert_raises V8::JSError do
      @context.eval('hqmf.SpecificsManager.getColumnIndex("OccurrenceCEncounter")')
    end
    assert_equal true, @context.eval('hqmf.SpecificsManager.validate(pop)')
    assert_equal 3, @context.eval('hqmf.SpecificsManager.countUnique(["OccurrenceAEncounter"], pop)')
    assert_equal 2, @context.eval('hqmf.SpecificsManager.countUnique(["OccurrenceBEncounter"], pop)')
    # this should be 3 and not 5 because we are doing a multiple encounter episode check.  The OccurrenceB rows should be dropped since
    # we cannot have multiple values defined on a single row for a multi encounter episode check for unique.
    assert_equal 3, @context.eval('hqmf.SpecificsManager.countUnique(["OccurrenceAEncounter", "OccurrenceBEncounter"], pop)')
    assert_equal 1, @context.eval('hqmf.SpecificsManager.countUnique(null, pop)')
  end

  def test_specifics_event_exclusion
    
    init_rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':20}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':20}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':30}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2,row3]);
      var specific2 = new hqmf.SpecificOccurrence([row1]);
      var specific3 = new hqmf.SpecificOccurrence([]);
      specific3.addIdentityRow();

      var pop1 = new Boolean(true);
      pop1.specificContext = specific1;
      var pop2 = new Boolean(true);
      pop2.specificContext = specific2;
      var pop3 = new Boolean(true);
      pop3.specificContext = specific3;
      var pop4 = new Boolean(false);
      pop4.specificContext = specific3;
    "
    
    @context.eval(init_rows)
    @context.eval('var resultSpecific = specific1.removeMatchingRows(0, specific2)')
    assert_equal 2, @context.eval('resultSpecific.rows.length')
    assert_equal 2, @context.eval('resultSpecific.rows[0].values[0].id')
    assert_equal 3, @context.eval('resultSpecific.rows[1].values[0].id')
    @context.eval('resultSpecific = specific1.removeMatchingRows(1, specific2)')
    assert_equal 1, @context.eval('resultSpecific.rows.length')
    assert_equal 3, @context.eval('resultSpecific.rows[0].values[0].id')
    @context.eval('var result = hqmf.SpecificsManager.exclude(["OccurrenceAEncounter"], pop1, pop2)')
    assert_equal true, @context.eval('result.isTrue()')
    assert_equal 2, @context.eval('result.specificContext.rows.length')
    assert_equal 2, @context.eval('result.specificContext.rows[0].values[0].id')
    assert_equal 3, @context.eval('result.specificContext.rows[1].values[0].id')
    @context.eval('result = hqmf.SpecificsManager.exclude(["OccurrenceBEncounter"], pop1, pop2)')
    assert_equal true, @context.eval('result.isTrue()')
    assert_equal 1, @context.eval('result.specificContext.rows.length')
    assert_equal 3, @context.eval('result.specificContext.rows[0].values[0].id')
    @context.eval('result = hqmf.SpecificsManager.exclude(["OccurrenceAEncounter","OccurrenceBEncounter"], pop1, pop2)')
    assert_equal true, @context.eval('result.isTrue()')
    assert_equal 1, @context.eval('result.specificContext.rows.length')
    assert_equal 3, @context.eval('result.specificContext.rows[0].values[0].id')
    @context.eval('result = hqmf.SpecificsManager.exclude(null, pop3, pop3)')
    assert_equal false, @context.eval('result.isTrue()')
    @context.eval('result = hqmf.SpecificsManager.exclude(null, pop3, pop4)')
    assert_equal true, @context.eval('result.isTrue()')
    @context.eval('result = hqmf.SpecificsManager.exclude(null, pop4, pop3)')
    assert_equal false, @context.eval('result.isTrue()')
    @context.eval('result = hqmf.SpecificsManager.exclude(null, pop4, pop4)')
    assert_equal false, @context.eval('result.isTrue()')
  end

  def test_negation
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':3}});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':4}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});
  
      var specific1 = new hqmf.SpecificOccurrence([row1]);
      var specific2 = new hqmf.SpecificOccurrence([row2]);
      var specific3 = new hqmf.SpecificOccurrence([row3,row4]);
      var specific4 = new hqmf.SpecificOccurrence([row3,row6]);
      var specific5 = new hqmf.SpecificOccurrence([row5,row6]);
      var specific6 = new hqmf.SpecificOccurrence([row1,row2])
    "
    
    # test negation single specific
    # test negation multiple specifics
    
    @context.eval(rows)
    
    # has row checks
    assert_equal true, @context.eval('specific1.hasRow(row1)')
    assert_equal true, @context.eval('specific1.hasRow(row2)')
    assert_equal true, @context.eval('specific1.hasRow(row3)')
    assert_equal false, @context.eval('specific1.hasRow(row4)')
    assert_equal false, @context.eval('specific1.hasRow(row5)')
    
    # cartesian checks
    assert_equal 3, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3]]).length')
    assert_equal 6, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]]).length')
    assert_equal 1, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]])[0][0]')
    assert_equal 5, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]])[0][1]')
    assert_equal 1, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]])[1][0]')
    assert_equal 6, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]])[1][1]')
    assert_equal 2, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]])[2][0]')
    assert_equal 5, @context.eval('hqmf.SpecificsManager._generateCartisian([[1,2,3],[5,6]])[2][1]')
    
    # specificsWithValue on Row
    assert_equal 0, @context.eval('row1.specificsWithValues()[0]')
    assert_equal 1, @context.eval('row2.specificsWithValues()[0]')
    assert_equal 0, @context.eval('row3.specificsWithValues()[0]')
    assert_equal 1, @context.eval('row3.specificsWithValues()[1]')
  
    # specificsWithValue on Specific
    assert_equal 0, @context.eval('specific1.specificsWithValues()[0]')
    assert_equal 1, @context.eval('specific2.specificsWithValues()[0]')
    assert_equal 0, @context.eval('specific3.specificsWithValues()[0]')
    assert_equal 1, @context.eval('specific3.specificsWithValues()[1]')
    assert_equal 0, @context.eval('specific6.specificsWithValues()[0]')
    assert_equal 1, @context.eval('specific6.specificsWithValues()[1]')
    
    assert_equal 4, @context.eval('specific1.negate().rows.length')
    assert_equal 2, @context.eval('specific1.negate().rows[0].values[0].id')
    assert_equal 3, @context.eval('specific1.negate().rows[1].values[0].id')
    assert_equal 4, @context.eval('specific1.negate().rows[2].values[0].id')
    assert_equal 5, @context.eval('specific1.negate().rows[3].values[0].id')
    
    # 5*5 values = 25 in the cartesian - 2 in the non-negated = 23 negated - 5 rows with OccurrA and OccurrB equal = 18!
    assert_equal 18, @context.eval('specific5.negate().rows.length')
    
  end
  
  def test_add_rows_has_rows_has_specifics
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row(undefined, {});
  
      var specific1 = new hqmf.SpecificOccurrence();
      var specific2 = new hqmf.SpecificOccurrence([row2]);
    "
    
    # test negation single specific
    # test negation multiple specifics
    
    @context.eval(rows)
    
    assert_equal false, @context.eval('specific1.hasRows()')
    assert_equal true, @context.eval('specific2.hasRows()')
    assert_equal false, @context.eval('specific1.hasSpecifics()')
    assert_equal true, @context.eval('specific2.hasSpecifics()')
    assert_equal false, @context.eval('row3.hasSpecifics()')
    assert_equal true, @context.eval('row2.hasSpecifics()')
    
    assert_equal 0, @context.eval('specific1.rows.length')
    @context.eval('specific1.addRows([row2])')
    assert_equal 1, @context.eval('specific1.rows.length')
    assert_equal 1, @context.eval('specific2.rows.length')
    @context.eval('specific2.addRows([row3])')
    assert_equal 2, @context.eval('specific2.rows.length')
    
  end
  
  def test_maintain_specfics
    @context.eval('var x = new Boolean(true)')
    @context.eval("x.specificContext = 'specificContext'")
    @context.eval("x.specific_occurrence = 'specific_occurrence'")
    @context.eval('var a = new Boolean(true)')
    @context.eval("a = hqmf.SpecificsManager.maintainSpecifics(a,x)")
    assert_equal true, @context.eval("typeof(a.specificContext) != 'undefined'")
    assert_equal true, @context.eval("typeof(a.specific_occurrence) != 'undefined'")
    
  end
  
  def test_compact_reused_events
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':2}});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':3},'OccurrenceBEncounter':{'id':3}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2,row3,row4,row5,row6]);
    "
    
    @context.eval(rows)
    
    assert_equal 6, @context.eval('specific1.rows.length')
    assert_equal 4, @context.eval('specific1.compactReusedEvents().rows.length')
    
  end

  def test_compact_reused_events_different_specifics
    
    @context = get_js_context(HQMF2JS::Generator::JS.library_functions)
    
    test_initialize_js = 
    "
      hqmf.SpecificsManager.initialize({},hqmfjs, {'id':'OccurrenceAEncounter1', 'type':'Encounter1', 'function':'SourceOccurrenceAEncounter1'},{'id':'OccurrenceAEncounter2', 'type':'Encounter2', 'function':'SourceOccurrenceAEncounter2'})
      hqmfjs.SourceOccurrenceAEncounter1 = function(patient) {
        return [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5}]
      }
      hqmfjs.SourceOccurrenceAEncounter2 = function(patient) {
        return [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5}]
      }
    "
    @context.eval(test_initialize_js)
    
    rows = "
      var row1 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter2',{'OccurrenceAEncounter2':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':1},'OccurrenceAEncounter2':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':2},'OccurrenceAEncounter2':{'id':2}});
      var row5 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':3},'OccurrenceAEncounter2':{'id':3}});
      var row6 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':1},'OccurrenceAEncounter2':{'id':3}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2,row3,row4,row5,row6]);
    "
    
    @context.eval(rows)
    
    assert_equal 6, @context.eval('specific1.rows.length')
    assert_equal 6, @context.eval('specific1.compactReusedEvents().rows.length')
    
  end

  def test_remove_duplicate_rows

    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});

      var specific = new hqmf.SpecificOccurrence([row1,row2,row3,row4]);
    "

    @context.eval(rows)

    assert_equal 4, @context.eval('specific.rows.length')
    assert_equal 2, @context.eval('specific.removeDuplicateRows().rows.length')

  end

  def test_remove_duplicate_rows_no_duplicates

    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':3}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});

      var specific = new hqmf.SpecificOccurrence([row1,row2,row3,row4]);
    "

    @context.eval(rows)

    assert_equal 4, @context.eval('specific.rows.length')
    assert_equal 4, @context.eval('specific.removeDuplicateRows().rows.length')

  end

  def test_remove_duplicate_rows_temp_value

    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1},undefined:{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1},undefined:{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2},undefined:{'id':1}});
      var row4 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2},undefined:{'id':2}});
      var row5 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1},undefined:{'id':1}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':1},undefined:{'id':2}});
      var row7 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2},undefined:{'id':1}});
      var row8 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':2},undefined:{'id':2}});

      var specific = new hqmf.SpecificOccurrence([row1,row2,row3,row4,row5,row6,row7,row8]);
    "

    @context.eval(rows)

    assert_equal 8, @context.eval('specific.rows.length')
    assert_equal 4, @context.eval('specific.removeDuplicateRows().rows.length')

  end

  def test_row_build_rows_for_matching
    
    events = "
      var entryKey = 'OccurrenceAEncounter';
      var boundsKey = 'OccurrenceBEncounter';
      var entry = {'id':3};
      var bounds = [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5},{'id':6},{'id':7},{'id':8}];
    "
  
    @context.eval(events)
    @context.eval('var rows = Row.buildRowsForMatching(entryKey,entry,boundsKey,bounds)')
    assert_equal 8, @context.eval('rows.length')
    assert_equal 2, @context.eval('rows[0].values.length')
    assert_equal 3, @context.eval('rows[0].values[0].id')
    assert_equal 1, @context.eval('rows[0].values[1].id')
    assert_equal 3, @context.eval('rows[7].values[0].id')
    assert_equal 8, @context.eval('rows[7].values[1].id')
    @context.eval('var specific = new hqmf.SpecificOccurrence(rows)')
    assert_equal 8, @context.eval('specific.rows.length')
    assert_equal 7, @context.eval('specific.compactReusedEvents().rows.length')
    @context.eval('var rows = Row.buildRowsForMatching(undefined,entry,boundsKey,bounds)')
    assert_equal 8, @context.eval('rows.length')
    assert_equal 3, @context.eval("rows[0].nonSpecificLeftMost.id")
    assert_equal 3, @context.eval("rows[5].nonSpecificLeftMost.id")
    assert_equal 3, @context.eval("rows[0].nonSpecificLeftMost.id")
    assert_equal 1, @context.eval("rows[0].values[1].id")
    assert_equal 6, @context.eval("rows[5].values[1].id")
  end
  
  def test_row_build_for_data_criteria
  
    events = "
      var entryKey = 'OccurrenceAEncounter';
      var entries = [{'id':1},{'id':2},{'id':3},{'id':4},{'id':5},{'id':6},{'id':7},{'id':8}];
    "
  
    @context.eval(events)
    @context.eval('var rows = Row.buildForDataCriteria(entryKey,entries)')
    assert_equal 8, @context.eval('rows.length')
    assert_equal 2, @context.eval('rows[0].values.length')
    assert_equal 1, @context.eval('rows[0].values[0].id')
    assert_equal '*', @context.eval('rows[0].values[1]')
    assert_equal 8, @context.eval('rows[7].values[0].id')
    assert_equal '*', @context.eval('rows[7].values[1]')
    
  end
  
  def test_finalize_events
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2]);
      var specific2 = new hqmf.SpecificOccurrence([row3,row4,row5]);
      var specific3 = new hqmf.SpecificOccurrence([row6,row7,row8]);
    "
    @context.eval(rows)
    @context.eval('var result = specific1.finalizeEvents(specific2,specific3)')
    assert_equal 3, @context.eval('result.rows.length')
    assert_equal 1, @context.eval('result.rows[0].values[0].id')
    assert_equal 4, @context.eval('result.rows[0].values[1].id')
    assert_equal 1, @context.eval('result.rows[1].values[0].id')
    assert_equal 5, @context.eval('result.rows[1].values[1].id')
    assert_equal 2, @context.eval('result.rows[2].values[0].id')
    assert_equal 4, @context.eval('result.rows[2].values[1].id')
  
    @context.eval('var result = specific2.finalizeEvents(specific1,specific3)')
    assert_equal 3, @context.eval('result.rows.length')
  
    @context.eval('var result = specific1.finalizeEvents(null,specific3)')
    assert_equal 3, @context.eval('result.rows.length')
    
    # result if 5 and not 6 becasue the 2/2 row gets dropped
    @context.eval('var result = specific1.finalizeEvents(specific2, null)')
    assert_equal 5, @context.eval('result.rows.length')
    
  end
  
  def test_validate
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
  
      var row9 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':6}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2]);
      var specific2 = new hqmf.SpecificOccurrence([row3,row4,row5]);
      var specific3 = new hqmf.SpecificOccurrence([row6,row7,row8]);
      var specific4 = new hqmf.SpecificOccurrence([row9]);
      var specific5 = new hqmf.SpecificOccurrence();
      
      var pop1 = new Boolean(true)
      pop1.specificContext = specific1
  
      var pop2 = new Boolean(true)
      pop2.specificContext = specific2
  
      var pop3 = new Boolean(true)
      pop3.specificContext = specific3
  
      var pop4 = new Boolean(true)
      pop4.specificContext = specific4
  
      var pop5 = new Boolean(true)
      pop5.specificContext = specific5
      
      var pop3f = new Boolean(false)
      pop3f.specificContext = specific3
            
    "
    @context.eval(rows)
    
    assert_equal true, @context.eval('hqmf.SpecificsManager.validate(hqmf.SpecificsManager.intersectSpecifics(pop1, hqmf.SpecificsManager.intersectSpecifics(pop2,pop3)))')
    assert_equal false, @context.eval('hqmf.SpecificsManager.validate(hqmf.SpecificsManager.intersectSpecifics(pop1, hqmf.SpecificsManager.intersectSpecifics(pop2,pop4)))')
    assert_equal false, @context.eval('hqmf.SpecificsManager.validate(hqmf.SpecificsManager.intersectSpecifics(pop1, hqmf.SpecificsManager.intersectSpecifics(pop2,pop5)))')
    assert_equal false, @context.eval('hqmf.SpecificsManager.validate(hqmf.SpecificsManager.intersectSpecifics(pop3f,hqmf.SpecificsManager.intersectSpecifics(pop1,pop2)))')
    
  end

  def test_episode_of_care_restrictions

    rows = "
      hqmf.SpecificsManager.initialize({},hqmfjs, {'id':'OccurrenceAEncounter1', 'type':'Encounter', 'function':'SourceOccurrenceAEncounter1'},
                                                  {'id':'OccurrenceAEncounter2', 'type':'Encounter', 'function':'SourceOccurrenceAEncounter2'},
                                                  {'id':'OccurrenceAEncounter3', 'type':'Encounter', 'function':'SourceOccurrenceAEncounter3'})


      var row1 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter2',{'OccurrenceAEncounter2':{'id':3}});
      var row3 = new Row('OccurrenceAEncounter1',{'OccurrenceAEncounter1':{'id':1},'OccurrenceAEncounter2':{'id':3}});
      var identityRow = hqmf.SpecificsManager.identity().rows[0];
      
      var pop1 = new Boolean(true);
      var pop2 = new Boolean(true);
      var pop3 = new Boolean(true);
      var pop4 = new Boolean(true);

      pop1.specificContext = new hqmf.SpecificOccurrence([row1]);
      pop2.specificContext = new hqmf.SpecificOccurrence([row2]);
      pop3.specificContext = new hqmf.SpecificOccurrence([row3]);
      pop4.specificContext = new hqmf.SpecificOccurrence([identityRow]);

      var result = null;

    "
    @context.eval(rows)

    # test allValuesAny
    assert_equal false, @context.eval('row1.allValuesAny([0,1,2])')
    assert_equal true, @context.eval('row1.allValuesAny([1,2])')
    assert_equal true, @context.eval('row1.allValuesAny([2])')
    assert_equal true, @context.eval('row1.allValuesAny([1])')
    assert_equal true, @context.eval('row1.allValuesAny([])')
    assert_equal true, @context.eval('identityRow.allValuesAny([0,1,2])')

    # test checkEpisodeOfCare
    assert_equal true, @context.eval('Row.checkEpisodeOfCare({id: 1}, true) == hqmf.SpecificsManager.any')
    assert_equal false, @context.eval('Row.checkEpisodeOfCare({id: 1}, false) == hqmf.SpecificsManager.any')
    assert_equal true, @context.eval('Row.checkEpisodeOfCare({id: 1}, false).id == 1')

    # test intersect
    assert_equal true, @context.eval('row1.intersect(row2,[0,1]).allValuesAny([0,1,2])') # this is the critical check.  Make sure we drop bad episode of care intersections
    assert_equal true, @context.eval('row1.intersect(row2,[0]).allValuesAny([2])')
    assert_equal true, @context.eval('row1.intersect(row2,[0]).values[0].id == 1')
    assert_equal true, @context.eval('row1.intersect(row2,[0]).values[1].id == 3')
    assert_equal true, @context.eval('row1.intersect(row2,[1]).allValuesAny([2])')
    assert_equal true, @context.eval('row1.intersect(row2,[1]).values[0].id == 1')
    assert_equal true, @context.eval('row1.intersect(row2,[1]).values[1].id == 3')

    assert_equal true, @context.eval('identityRow.intersect(row1,[0]).values[0].id == 1')
    assert_equal true, @context.eval('identityRow.intersect(row1,[0]).allValuesAny([1,2])')
    assert_equal true, @context.eval('row1.intersect(identityRow,[0]).values[0].id == 1')
    assert_equal true, @context.eval('row1.intersect(identityRow,[0]).allValuesAny([1,2])')

    # make sure we drop a bad strggler for encounter 2
    assert_equal true, @context.eval('row1.intersect(row3,[0,1]).allValuesAny([1,2])')
    assert_equal true, @context.eval('row1.intersect(row3,[0,1]).values[0].id == 1')
    
    # test intersectSpecifics

    assert_equal true, @context.eval('hqmf.SpecificsManager.intersectSpecifics(pop1,pop2).specificContext.rows[0].values[0].id == 1')
    assert_equal true, @context.eval('hqmf.SpecificsManager.intersectSpecifics(pop1,pop2).specificContext.rows[0].values[1].id == 3')
    assert_equal true, @context.eval('hqmf.SpecificsManager.intersectSpecifics(pop1,pop2).specificContext.rows[0].values[2] == hqmf.SpecificsManager.any')
    assert_equal true, @context.eval("hqmf.SpecificsManager.intersectSpecifics(pop1,pop2,['OccurrenceAEncounter1','OccurrenceAEncounter2','OccurrenceAEncounter3']).specificContext.rows[0].allValuesAny([0,1,2])")
    @context.eval("result = hqmf.SpecificsManager.intersectSpecifics(pop1,pop2,['OccurrenceAEncounter1']).specificContext.rows[0]")
    assert_equal true, @context.eval('result.allValuesAny([2])')
    assert_equal true, @context.eval('result.values[0].id == 1')
    assert_equal true, @context.eval('result.values[1].id == 3')
    @context.eval("result = hqmf.SpecificsManager.intersectSpecifics(pop1,pop2,['OccurrenceAEncounter2']).specificContext.rows[0]")
    assert_equal true, @context.eval('result.allValuesAny([2])')
    assert_equal true, @context.eval('result.values[0].id == 1')
    assert_equal true, @context.eval('result.values[1].id == 3')

    @context.eval("result = hqmf.SpecificsManager.intersectSpecifics(pop1,pop4,['OccurrenceAEncounter1']).specificContext.rows[0]")
    assert_equal true, @context.eval('result.values[0].id == 1')
    assert_equal true, @context.eval('result.allValuesAny([1,2])')

    @context.eval("result = hqmf.SpecificsManager.intersectSpecifics(pop4,pop1,['OccurrenceAEncounter1']).specificContext.rows[0]")
    assert_equal true, @context.eval('result.values[0].id == 1')
    assert_equal true, @context.eval('result.allValuesAny([1,2])')

    @context.eval("result = hqmf.SpecificsManager.intersectSpecifics(pop1,pop3,['OccurrenceAEncounter1','OccurrenceAEncounter2']).specificContext.rows[0]")
    assert_equal true, @context.eval('result.allValuesAny([1,2])')
    assert_equal true, @context.eval('result.values[0].id == 1')

  end
  
  def test_intersect_all
  
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2]);
      var specific2 = new hqmf.SpecificOccurrence([row3,row4,row5]);
      var specific3 = new hqmf.SpecificOccurrence([row6,row7,row8]);
      
      var pop1 = new Boolean(true)
      pop1.specificContext = specific1
  
      var pop2 = new Boolean(true)
      pop2.specificContext = specific2
  
      var pop3 = new Boolean(true)
      pop3.specificContext = specific3
      
            
    "
    @context.eval(rows)
    
    @context.eval('var intersection = hqmf.SpecificsManager.intersectAll(new Boolean(true), [pop1,pop2,pop3])')
    assert @context.eval('intersection.isTrue()')
    @context.eval('var result = intersection.specificContext')
    
    assert_equal 3, @context.eval('result.rows.length')
  
    assert_equal 1, @context.eval('result.rows[0].values[0].id')
    assert_equal 4, @context.eval('result.rows[0].values[1].id')
    assert_equal 1, @context.eval('result.rows[1].values[0].id')
    assert_equal 5, @context.eval('result.rows[1].values[1].id')
    assert_equal 2, @context.eval('result.rows[2].values[0].id')
    assert_equal 4, @context.eval('result.rows[2].values[1].id')
  
    @context.eval('var intersection = hqmf.SpecificsManager.intersectAll(new Boolean(true), [pop1,pop2,pop3], true)')
    @context.eval('var result = intersection.specificContext')
    
    # 5*5 = 25 - 5 equal rows - 3 non-negated = 17
    assert_equal 17, @context.eval('result.rows.length')
    
  end
  
  def test_union_all
  
    rows = "
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2}});
      var row3 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row4 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':4}});
      var row5 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':5}});
      var row6 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row7 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':5}});
      var row8 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':2},'OccurrenceBEncounter':{'id':4}});
      
      var specific1 = new hqmf.SpecificOccurrence([row1,row2]);
      var specific2 = new hqmf.SpecificOccurrence([row3,row4,row5]);
      var specific3 = new hqmf.SpecificOccurrence([row6,row7,row8]);
      
      var pop1 = new Boolean(true)
      pop1.specificContext = specific1
  
      var pop2 = new Boolean(true)
      pop2.specificContext = specific2
  
      var pop3 = new Boolean(true)
      pop3.specificContext = specific3
      
            
    "
    @context.eval(rows)
    
    @context.eval('var union = hqmf.SpecificsManager.unionAll(new Boolean(true), [pop1,pop2,pop3])')
    assert @context.eval('union.isTrue()')
    @context.eval('var result = union.specificContext')
    
    assert_equal 8, @context.eval('result.rows.length')
  
    @context.eval('var union = hqmf.SpecificsManager.unionAll(new Boolean(true), [pop1,pop2,pop3], true)')
    assert @context.eval('union.isTrue()')
    @context.eval('var result = union.specificContext')
    
    # originally 5*5, but we remove 1,2 from the left and 2,4,5 from the right
    # that leaves [3,4,5] x [1,3] which is 6 rows... minus the 3,3 row we get 5 rows
    
    assert_equal 5, @context.eval('result.rows.length')
  
  end

  def test_row_grouping_key
  
    rows = "
      hqmf.SpecificsManager.initialize({},hqmfjs, {'id':'OccurrenceAEncounter', 'type':'Encounter', 'function':'SourceOccurrenceAEncounter'},{'id':'OccurrenceBEncounter', 'type':'Encounter', 'function':'SourceOccurrenceBEncounter'},{'id':'OccurrenceAProcedure', 'type':'Procedure', 'function':'SourceOccurrenceAProcedure'})
      
      var row1 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1}});
      var row2 = new Row('OccurrenceBEncounter',{'OccurrenceBEncounter':{'id':2}});
      var row3 = new Row('OccurrenceAEncounter',{'OccurrenceAEncounter':{'id':1},'OccurrenceBEncounter':{'id':4}});
      var row4 = new Row(undefined, {});
      
    "
    @context.eval(rows)
    
    assert_equal "1_*_*_", @context.eval("row1.groupKey()")
    assert_equal "X_*_*_", @context.eval("row1.groupKey('OccurrenceAEncounter')")
    assert_equal "1_*_X_", @context.eval("row1.groupKey('OccurrenceAProcedure')")
    assert_equal "*_2_*_", @context.eval("row2.groupKey()")
    assert_equal "*_2_X_", @context.eval("row2.groupKey('OccurrenceAProcedure')")
    assert_equal "1_4_*_", @context.eval("row3.groupKey()")
    assert_equal "X_4_*_", @context.eval("row3.groupKey('OccurrenceAEncounter')")
    assert_equal "1_X_*_", @context.eval("row3.groupKey('OccurrenceBEncounter')")
    assert_equal "1_4_X_", @context.eval("row3.groupKey('OccurrenceAProcedure')")
    assert_equal "*_*_*_", @context.eval("row4.groupKey()")
    assert_equal "*_X_*_", @context.eval("row4.groupKey('OccurrenceBEncounter')")
    
  end
  
  def test_group_specifics
  
    rows = "
      var non_specific_rows = [new Row(undefined, {undefined: {id:10}, 'OccurrenceAEncounter':{'id':1}}),
                               new Row(undefined, {undefined: {id:11}, 'OccurrenceAEncounter':{'id':1}}),
                               new Row(undefined, {undefined: {id:12}, 'OccurrenceAEncounter':{'id':2}}),
                               new Row(undefined, {undefined: {id:13}, 'OccurrenceAEncounter':{'id':2}}),
                               new Row(undefined, {undefined: {id:14}, 'OccurrenceAEncounter':{'id':2}}),
                               new Row(undefined, {undefined: {id:15}, 'OccurrenceAEncounter':{'id':3}})]
      
      var specific_rows = [new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': {id:10}, 'OccurrenceBEncounter':{'id':1}}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': {id:11}, 'OccurrenceBEncounter':{'id':1}}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': {id:12}, 'OccurrenceBEncounter':{'id':2}}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': {id:13}, 'OccurrenceBEncounter':{'id':2}}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': {id:14}, 'OccurrenceBEncounter':{'id':2}}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': {id:15}, 'OccurrenceBEncounter':{'id':3}})]
      
      var specific1 = new hqmf.SpecificOccurrence(non_specific_rows);
      var specific2 = new hqmf.SpecificOccurrence(specific_rows);
      
    "
    @context.eval(rows)
    
    assert_equal 2, @context.eval("specific1.group()['1_*_'].length")
    assert_equal 3, @context.eval("specific1.group()['2_*_'].length")
    assert_equal 1, @context.eval("specific1.group()['3_*_'].length")

    assert_equal 2, @context.eval("specific2.group('OccurrenceAEncounter')['X_1_'].length")
    assert_equal 3, @context.eval("specific2.group('OccurrenceAEncounter')['X_2_'].length")
    assert_equal 1, @context.eval("specific2.group('OccurrenceAEncounter')['X_3_'].length")
    
  end
  
  def test_extract_events
    rows = "
      var non_specific_rows = [new Row(undefined, {undefined: new hQuery.CodedEntry({_id:10}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':1})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:11}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':1})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:12}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':2})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:13}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':2})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:14}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':2})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:15}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':3})})]
      
      var specific_rows = [new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:10}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':1})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:11}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':1})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:12}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':2})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:13}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':2})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:14}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':2})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:15}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':3})})]
    "
    @context.eval(rows)
    assert_equal 6, @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows).length')
    assert_equal '10', @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows)[0].id')
    assert_equal '11', @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows)[1].id')
    assert_equal '12', @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows)[2].id')
    assert_equal '13', @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows)[3].id')
    assert_equal '14', @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows)[4].id')
    assert_equal '15', @context.eval('hqmf.SpecificsManager.extractEvents(undefined, non_specific_rows)[5].id')
    
    assert_equal 6, @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows).length")
    assert_equal '10', @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows)[0].id")
    assert_equal '11', @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows)[1].id")
    assert_equal '12', @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows)[2].id")
    assert_equal '13', @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows)[3].id")
    assert_equal '14', @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows)[4].id")
    assert_equal '15', @context.eval("hqmf.SpecificsManager.extractEvents('OccurrenceAEncounter', specific_rows)[5].id")
    
  end

  def test_specifics_subset_operators
  
    rows = "
    
      getTime = function(year,month,day) {
        return (new Date(year,month,day)).getTime()/1000
      }
      
      var non_specific_rows = [new Row(undefined, {undefined: new hQuery.CodedEntry({_id:10,time:getTime(2010,0,5)}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':1})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:11,time:getTime(2010,0,1)}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':1})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:12,time:getTime(2010,0,1)}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':2})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:13,time:getTime(2010,0,5)}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':2})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:14,time:getTime(2010,0,2)}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':2})}),
                               new Row(undefined, {undefined: new hQuery.CodedEntry({_id:15,time:getTime(2010,0,2)}), 'OccurrenceAEncounter':new hQuery.CodedEntry({'_id':3})})]
    
      var specific_rows = [new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:10,time:getTime(2010,0,5)}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':1})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:11,time:getTime(2010,0,1)}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':1})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:12,time:getTime(2010,0,1)}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':2})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:13,time:getTime(2010,0,5)}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':2})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:14,time:getTime(2010,0,2)}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':2})}),
                           new Row('OccurrenceAEncounter',{'OccurrenceAEncounter': new hQuery.CodedEntry({_id:15,time:getTime(2010,0,2)}), 'OccurrenceBEncounter':new hQuery.CodedEntry({'_id':3})})]

      var specific1 = new hqmf.SpecificOccurrence(non_specific_rows);
      var specific2 = new hqmf.SpecificOccurrence(specific_rows);
      var specific3 = new hqmf.SpecificOccurrence([new Row(undefined)]);
      var specific4 = new hqmf.SpecificOccurrence()
      
    "
    @context.eval(rows)
    
    ###
    ##### COUNT
    ###
    
    moreThanOne = 'new IVL_PQ(new PQ(2))'
    lessThanThree = 'new IVL_PQ(null, new PQ(2))'
    exactly1 = 'new IVL_PQ(new PQ(1), new PQ(1))'
    
    assert_equal 5, @context.eval("specific1.COUNT(#{moreThanOne}).rows.length")
    assert_equal '10', @context.eval("specific1.COUNT(#{moreThanOne}).rows[0].nonSpecificLeftMost.id")
    assert_equal '11', @context.eval("specific1.COUNT(#{moreThanOne}).rows[1].nonSpecificLeftMost.id")
    assert_equal '12', @context.eval("specific1.COUNT(#{moreThanOne}).rows[2].nonSpecificLeftMost.id")
    assert_equal '13', @context.eval("specific1.COUNT(#{moreThanOne}).rows[3].nonSpecificLeftMost.id")
    assert_equal '14', @context.eval("specific1.COUNT(#{moreThanOne}).rows[4].nonSpecificLeftMost.id")
    assert_equal 3, @context.eval("specific1.COUNT(#{lessThanThree}).rows.length")
    assert_equal '10', @context.eval("specific1.COUNT(#{lessThanThree}).rows[0].nonSpecificLeftMost.id")
    assert_equal '11', @context.eval("specific1.COUNT(#{lessThanThree}).rows[1].nonSpecificLeftMost.id")
    assert_equal '15', @context.eval("specific1.COUNT(#{lessThanThree}).rows[2].nonSpecificLeftMost.id")
    assert_equal 1, @context.eval("specific1.COUNT(#{exactly1}).rows.length")
    assert_equal '15', @context.eval("specific1.COUNT(#{exactly1}).rows[0].nonSpecificLeftMost.id")
    
    assert_equal 5, @context.eval("specific2.COUNT(#{moreThanOne}).rows.length")
    assert_equal '10', @context.eval("specific2.COUNT(#{moreThanOne}).rows[0].values[0].id")
    assert_equal '11', @context.eval("specific2.COUNT(#{moreThanOne}).rows[1].values[0].id")
    assert_equal '12', @context.eval("specific2.COUNT(#{moreThanOne}).rows[2].values[0].id")
    assert_equal '13', @context.eval("specific2.COUNT(#{moreThanOne}).rows[3].values[0].id")
    assert_equal '14', @context.eval("specific2.COUNT(#{moreThanOne}).rows[4].values[0].id")
    assert_equal 3, @context.eval("specific2.COUNT(#{lessThanThree}).rows.length")
    assert_equal '10', @context.eval("specific2.COUNT(#{lessThanThree}).rows[0].values[0].id")
    assert_equal '11', @context.eval("specific2.COUNT(#{lessThanThree}).rows[1].values[0].id")
    assert_equal '15', @context.eval("specific2.COUNT(#{lessThanThree}).rows[2].values[0].id")
    assert_equal 1, @context.eval("specific2.COUNT(#{exactly1}).rows.length")
    assert_equal '15', @context.eval("specific2.COUNT(#{exactly1}).rows[0].values[0].id")

    assert_equal 1, @context.eval("specific3.COUNT(#{exactly1}).rows.length")
    assert_equal 0, @context.eval("specific4.COUNT(#{moreThanOne}).rows.length")


    ###
    ##### FIRST
    ###
    assert_equal 3, @context.eval("specific1.FIRST().rows.length")
    assert_equal '11', @context.eval("specific1.FIRST().rows[0].nonSpecificLeftMost.id")
    assert_equal '12', @context.eval("specific1.FIRST().rows[1].nonSpecificLeftMost.id")
    assert_equal '15', @context.eval("specific1.FIRST().rows[2].nonSpecificLeftMost.id")
    
    assert_equal 3, @context.eval("specific2.FIRST().rows.length")
    assert_equal '11', @context.eval("specific2.FIRST().rows[0].values[0].id")
    assert_equal '12', @context.eval("specific2.FIRST().rows[1].values[0].id")
    assert_equal '15', @context.eval("specific2.FIRST().rows[2].values[0].id")

    assert_equal 1, @context.eval("specific3.FIRST().rows.length")
    assert_equal 0, @context.eval("specific4.FIRST().rows.length")

    ###
    ##### MOST RECENT
    ###

    assert_equal 3, @context.eval("specific1.RECENT().rows.length")
    assert_equal '10', @context.eval("specific1.RECENT().rows[0].nonSpecificLeftMost.id")
    assert_equal '13', @context.eval("specific1.RECENT().rows[1].nonSpecificLeftMost.id")
    assert_equal '15', @context.eval("specific1.RECENT().rows[2].nonSpecificLeftMost.id")
    
    assert_equal 3, @context.eval("specific2.RECENT().rows.length")
    assert_equal '10', @context.eval("specific2.RECENT().rows[0].values[0].id")
    assert_equal '13', @context.eval("specific2.RECENT().rows[1].values[0].id")
    assert_equal '15', @context.eval("specific2.RECENT().rows[2].values[0].id")

    assert_equal 1, @context.eval("specific3.RECENT().rows.length")
    assert_equal 0, @context.eval("specific4.RECENT().rows.length")

    
  end
  
end
