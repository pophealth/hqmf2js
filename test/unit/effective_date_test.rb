require_relative '../test_helper'

class EffectiveDateTest < Minitest::Test
  def setup
    # Open a path to all of our fixtures
    model = JSON.parse(File.open("test/fixtures/NQF59New.json").read)
    doc = HQMF::Document.from_json(model)
    
    # First compile the CoffeeScript that enables our converted HQMF JavaScript
    ctx = Sprockets::Environment.new(File.expand_path("../../..", __FILE__))
    Tilt::CoffeeScriptTemplate.default_bare = true 
    ctx.append_path "app/assets/javascripts"
    hqmf_utils = HQMF2JS::Generator::JS.library_functions
    
    # Convert the HQMF document included as a fixture into JavaScript
    @converter = HQMF2JS::Generator::JS.new(doc)
    converted_hqmf = "var effective_date = 1277870400; // June 30th 2010
      #{@converter.js_for_data_criteria}
      #{@converter.js_for('IPP')}
      #{@converter.js_for('DENOM')}
      #{@converter.js_for('NUMER')}
      #{@converter.js_for('DENEXCEP')}
      #{@converter.js_for('DUMMY')}"

    # Now we can wrap and compile all of our code as one little JavaScript context for all of the tests below
    if RUBY_PLATFORM=='java'
      @context = Rhino::Context.new
    else
      @context = V8::Context.new
    end
    @context.eval("#{hqmf_utils}
      #{converted_hqmf}")
  end
  
  def test_override_hqmf_measure_period
    # Measure variables
    assert_equal 2009, @context.eval("MeasurePeriod.low.asDate().getFullYear()")
    assert_equal 5, @context.eval("MeasurePeriod.low.asDate().getMonth()")
    assert_equal 2010, @context.eval("MeasurePeriod.high.asDate().getFullYear()")
    assert_equal 5, @context.eval("MeasurePeriod.high.asDate().getMonth()")
    assert_equal 2009, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().low.asDate().getFullYear()")
    assert_equal 5, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().low.asDate().getMonth()")
    assert_equal 2010, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().high.asDate().getFullYear()")
    assert_equal 5, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().high.asDate().getMonth()")
  end

end