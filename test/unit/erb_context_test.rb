require_relative '../test_helper'

class ErbContextTest < Minitest::Test

  def setup
  end

  def test_data_criteria_js
    
    context = HQMF2JS::Generator::ErbContext.new({})

    criteria = HQMF::DataCriteria.from_json(nil, JSON.parse(File.read(File.join('test','fixtures','json','data_criteria','temporals_with_anynonnull.json'))))

    get_codes = context.js_for_code_list(criteria)
    assert_equal "getCodes(\"2.16.840.1.113883.3.117.1.7.1.23\")", get_codes
    criteria.instance_variable_set(:@code_list_id, nil)
    get_codes = context.js_for_code_list(criteria)
    assert_equal "null", get_codes

    date_bound = context.js_for_date_bound(criteria)
    assert_equal "MeasurePeriod.high.asDate()", date_bound

    criteria.temporal_references[0].instance_variable_set(:@type,"FOO")
    exception = assert_raises RuntimeError do
      context.js_for_date_bound(criteria)
    end
    assert_equal "do not know how to get a date for this type", exception.message 
  end  

  def test_value_js
    context = HQMF2JS::Generator::ErbContext.new({})
    value = HQMF::Value.from_json({"type" => "ANYNonNull"})
    result = context.js_for_value(value)
    assert_equal "new ANYNonNull()", result 

    
    value = HQMF::Value.from_json({"type"=>"SCALAR", "unit"=>"mm[Hg]", "value"=>"90", "inclusive?"=>false, "derived?"=>false } ) 
    result = context.js_for_value(value)
    assert_equal "new SCALAR(90, \"mm[Hg]\", false)", result 

    value = HQMF::Value.from_json({"type"=>"SCALAR", "unit"=>nil, "value"=>"90", "inclusive?"=>true, "derived?"=>false } ) 
    result = context.js_for_value(value)
    assert_equal "new SCALAR(\"90\", null, true)", result

    value = HQMF::Value.from_json({"type"=>"SCALAR", "unit"=>nil, "value"=>"90", "inclusive?"=>nil, "derived?"=>false } )
    value.instance_variable_set(:@inclusive, nil)
    result = context.js_for_value(value)
    assert_equal "new SCALAR(\"90\")", result 

  end

  def test_field_library_method
    context = HQMF2JS::Generator::ErbContext.new({})
    result = context.field_library_method('ADMISSION_DATETIME')
    assert_equal "adjustBoundsForField", result 

    context = HQMF2JS::Generator::ErbContext.new({})
    result = context.field_library_method('FACILITY_LOCATION_ARRIVAL_DATETIME')
    assert_equal "denormalizeEventsByLocation", result 
  end

  

end