require_relative '../test_helper'
require 'hquery-patient-api'

class CmdTest < Minitest::Test
  
  def setup
    @context = get_js_context(HQMF2JS::Generator::JS.library_functions)
  end

  def test_does_per_day
    #administrative timeing in days
    assert_equal (1/3.0),@context.eval("new hQuery.AdministrationTiming({'period' : {'unit': 'd' , 'value': 3 }}).dosesPerDay()"), "Administrative Timing every 3 days should == 1/3"
    assert_equal 3,@context.eval("new hQuery.AdministrationTiming({'period' : {'unit': 'h' , 'value': 8 }}).dosesPerDay()"), "Administrative Timing every 8 hours should == 3 doses"
    assert_equal (24.0/5),@context.eval("new hQuery.AdministrationTiming({'period' : {'unit': 'h' , 'value': 5 }}).dosesPerDay()"), "Administrative Timing every 5 hours should == 3 doses"
    assert_equal (24.0/30),@context.eval("new hQuery.AdministrationTiming({'period' : {'unit': 'h' , 'value': 30 }}).dosesPerDay()"), "Administrative Timing every 30 hours should == 24/30 doses"
  end

  def test_days_in_range

    @context.eval("var range = new IVL_TS(new TS('20100101'), new TS('20101231'))")
    @context.eval("var perDay = 3;")
    scs =  @context.eval(%{var scs = new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2010,01,01).to_i} , "quantityDispensed" : {"value" :"30"}}) })
    during =  @context.eval(%{var during =   new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2010,02,02).to_i} , "quantityDispensed" : {"value" :"30"}})})
    sbs =  @context.eval(%{ var sbs =  new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2009,12,25).to_i} , "quantityDispensed" : {"value" :"30"}}) })
    sae =  @context.eval(%{ var sae = new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2011,01,01).to_i} , "quantityDispensed" :{"value" :"30"}}) })
    eae =  @context.eval(%{ var eae = new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2010,12,25).to_i} , "quantityDispensed" : {"value" :"30"}}) })
    ebs =  @context.eval(%{ var ebs =  new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2009,02,02).to_i} , "quantityDispensed" : {"value" :"30"}}) })
    ece =  @context.eval(%{ var ece = new hQuery.Fulfillment({"dispenseDate": #{Time.utc(2010,12,21).to_i} , "quantityDispensed" : {"value" :"30"}}) })
    
    assert_equal 10 , @context.eval("during.daysInRange(range, 1,  perDay)"), "Should be 10 days during"
    assert_equal 10 ,  @context.eval("scs.daysInRange(range,  1,  perDay)"), "Should be 10 days starting concurrent with the start range"
    assert_equal  3, @context.eval("sbs.daysInRange(range,  1,  perDay)"), "Should be 4 days overlap for starting before the start of the range"
    assert_equal  0, @context.eval("sae.daysInRange(range, 1,  perDay)"), "Should be 0 days starting after end"
    assert_equal  6, @context.eval("eae.daysInRange(range, 1,  perDay)"), "Should be 6 days overlap ending after the end of date range"
    assert_equal  0, @context.eval("ebs.daysInRange(range, 1,  perDay)"), "Should be 0 days  overlap ending before the start of the date range"
    assert_equal  10, @context.eval("ece.daysInRange(range, 1,   perDay)"), "Should be 10 days when ending concurrent with the end"

    @context.eval("var perDay = 1/3;") #every 3 days

    assert_equal 90 , @context.eval("during.daysInRange(range, 1,   perDay)"), "Should be 10 days during"
    assert_equal 90 , @context.eval("scs.daysInRange(range, 1,   perDay)"), "Should be 10 days starting concurrent with the start range"
    assert_equal  90-7,  @context.eval("sbs.daysInRange(range, 1,   perDay)"), "Should be 4 days overlap for starting before the start of the range"
    assert_equal  0,  @context.eval("sae.daysInRange(range, 1,  perDay)"), "Should be 0 days starting after end"
    assert_equal  6,  @context.eval("eae.daysInRange(range, 1,  perDay)"), "Should be 6 days overlap starting after the end of date range"
    assert_equal  0,  @context.eval("ebs.daysInRange(range, 1,  perDay)"), "Should be 0 days  overlap ending before the start of the date range"
    assert_equal  10, @context.eval("ece.daysInRange(range, 1,   perDay)"), "Should be 10 days when ending concurrent with the end"

    @context.eval("range = new IVL_TS(null, new TS('20101231'))")
    assert_equal 90, @context.eval("during.daysInRange(range, 1,   perDay)"), "Should be 90 when not supplied a start date"
    
    @context.eval("range = new IVL_TS(new TS('20100301'), null)")
    assert_equal 63, @context.eval("during.daysInRange(range, 1,   perDay)"), "Should be 90 when not supplied an end date date"
    
  end

  def test_cumulativeMedicationDuration
    medication1 = %{
      {
        "dose" : {"unit" : "mg", "value" : "5"},
        "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
        "fulfillmentHistory": [
          {"dispenseDate": #{Time.utc(2010,01,01).to_i} , "quantityDispensed" : {"value" :"150", "unit" : "mg"}}
         ]
      }
    }

    medication2 = %{
        {
          "dose" : {"unit" : "mg", "value" : "1"},
          "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
          "fulfillmentHistory": [
            {"dispenseDate": #{Time.utc(2010,01,01).to_i} , "quantityDispensed" : {"value" :"30"}},
            {"dispenseDate": #{Time.utc(2010,10,01).to_i} , "quantityDispensed" : {"value" :"90"}}
           ]
        }
      }

    no_history = %{
        {
          "dose" : {"unit" : "mg", "value" : "5"},
          "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
          "fulfillmentHistory": []
        }
      }
    @context.eval("var med = new hQuery.Medication(#{medication1})")
    @context.eval("var med2 = new hQuery.Medication(#{medication2})")
    @context.eval("var no_meds = new hQuery.Medication(#{no_history})")
    @context.eval("var range = new IVL_TS(new TS('20100101'), new TS('20101231'))")
    assert_equal 10, @context.eval("med.cumulativeMedicationDuration(range)"), "CMD should be 10"
    assert_equal 40, @context.eval("med2.cumulativeMedicationDuration(range)"), "CMD should be 10"
    assert_equal 0, @context.eval("no_meds.cumulativeMedicationDuration(range)"), "CMD should be 10"
  end


def test_fullfillment_based_cmd
    medication1 = %{
      {
        "dose" : {"unit" : "mg", "value" : "5"},
        "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
        "fulfillmentHistory": [
          {"dispenseDate": #{Time.utc(2010,01,01).to_i} , "quantityDispensed" : {"value" :"150", "unit" : "mg"}}
         ]
      }
    }

    medication2 = %{
        {
          "dose" : {"unit" : "mg", "value" : "1"},
          "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
          "fulfillmentHistory": [
            {"dispenseDate": #{Time.utc(2010,01,01).to_i} , "quantityDispensed" : {"value" :"30"}},
            {"dispenseDate": #{Time.utc(2010,10,01).to_i} , "quantityDispensed" : {"value" :"90"}}
           ]
        }
      }

    no_history = %{
        {
          "dose" : {"unit" : "mg", "value" : "5"},
          "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
          "fulfillmentHistory": []
        }
      }
    @context.eval("var med = new hQuery.Medication(#{medication1})")
    @context.eval("var med2 = new hQuery.Medication(#{medication2})")
    @context.eval("var no_meds = new hQuery.Medication(#{no_history})")
    @context.eval("var range = new IVL_TS(new TS('20100101'), new TS('20101231'))")
    @context.eval("var cmd1 = new CMD([med],'fullfillment')")
    @context.eval("var cmd2 = new CMD([med2],'fullfillment')")
    @context.eval("var cmd3 = new CMD([no_meds],'fullfillment')")
    assert_equal 10, @context.eval("cmd1.days_active(range.low,range.high).length"), "CMD should be 10"
    assert_equal 40, @context.eval("cmd2.days_active(range.low,range.high).length"), "CMD should be 40"
    assert_equal 0, @context.eval("cmd3.days_active(range.low,range.high).length"), "CMD should be 0"
  end


def test_order_based_cmd
    medication1 = %{
      {
        "dose" : {"unit" : "mg", "value" : "5"},
        "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
        "orderInformation": [
          {"orderDateTime": #{Time.utc(2010,01,01).to_i} , "quantityOrdered" : {"value" :"150", "unit" : "mg"}, "fills": 2}
         ]
      }
    }

    medication2 = %{
        {
          "dose" : {"unit" : "mg", "value" : "1"},
          "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
          "orderInformation": [
            {"orderDateTime": #{Time.utc(2010,01,01).to_i} , "quantityOrdered" : {"value" :"30"}},
            {"orderDateTime": #{Time.utc(2010,10,01).to_i} , "quantityOrdered" : {"value" :"90"}}
           ]
        }
      }

    no_history = %{
        {
          "dose" : {"unit" : "mg", "value" : "5"},
          "administrationTiming" :{'period' : {'unit': 'h' , 'value': 8 }},
          "orderInformation": []
        }
      }
    @context.eval("var med = new hQuery.Medication(#{medication1})")
    @context.eval("var med2 = new hQuery.Medication(#{medication2})")
    @context.eval("var no_meds = new hQuery.Medication(#{no_history})")
    @context.eval("var range = new IVL_TS(new TS('20100101'), new TS('20101231'))")
    @context.eval("var cmd1 = new CMD([med],'order')")
    @context.eval("var cmd2 = new CMD([med2],'order')")
    @context.eval("var cmd3 = new CMD([no_meds],'order')")
    assert_equal 20, @context.eval("cmd1.days_active(range.low,range.high).length"), "CMD should be 10"
    assert_equal 40, @context.eval("cmd2.days_active(range.low,range.high).length"), "CMD should be 40"
    assert_equal 0, @context.eval("cmd3.days_active(range.low,range.high).length"), "CMD should be 0"
  end

  def test_active_days

    @context.eval("var active = new ActiveDays()")
    @context.eval("var ivl = new IVL_TS(new TS('20101001'), new TS('20101031'))")
    @context.eval("active.add_ivlts(ivl)")
    assert_equal 31, @context.eval("active.days_active(ivl.low,ivl.high).length")

    @context.eval(" ivl = new IVL_TS(new TS('20101001'), new TS('20101010'))")
    assert_equal 10, @context.eval("active.days_active(ivl.low,ivl.high).length")

    @context.eval(" ivl = new IVL_TS(new TS('20101001'), new TS('20101110'))")
    assert_equal 31, @context.eval("active.days_active(ivl.low,ivl.high).length")

    @context.eval(" ivl = new IVL_TS(new TS('20101031'), new TS('20101110'))")
    assert_equal 1, @context.eval("active.days_active(ivl.low,ivl.high).length")
    
    @context.eval(" ivl = new IVL_TS(new TS('20101110'), new TS('20110110'))")
    @context.eval("active.add_ivlts(ivl)")

    @context.eval(" ivl = new IVL_TS(new TS('20101031'), new TS('20101113'))")
    assert_equal 5, @context.eval("active.days_active(ivl.low,ivl.high).length")
    

    @context.eval(" ivl = new IVL_TS(new TS('20101102'), new TS('20101113'))")
    assert_equal 4, @context.eval("active.days_active(ivl.low,ivl.high).length")


    @context.eval(" ivl = new IVL_TS(new TS('20100101'), new TS('20110113'))")
    assert_equal 93, @context.eval("active.days_active(ivl.low,ivl.high).length")

    @context.eval("ivl = new IVL_TS(new TS('20101110'), new TS('20110110'))")
    @context.eval("active.add_ivlts(ivl)")

    @context.eval(" ivl = new IVL_TS(new TS('20100101'), new TS('20110113'))")
    assert_equal 93, @context.eval("active.days_active(ivl.low,ivl.high).length")



  end

end
