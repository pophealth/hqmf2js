require_relative '../test_helper'

class HqmfFromJsonJavascriptTest < Test::Unit::TestCase
  def setup
    json_measure = File.open("test/fixtures/json/59New.json").read
    measure_hash = JSON.parse(json_measure)

    doc = HQMF::Document.from_json(measure_hash)
    
    codes_file_path = File.expand_path("../../fixtures/codes/codes.xml", __FILE__)
    # This patient is identified from Cypress as in the denominator and numerator for NQF59
    numerator_patient_json = File.read('test/fixtures/patients/larry_vanderman.json')
    
    # First compile the CoffeeScript that enables our converted HQMF JavaScript
    hqmf_utils = compile_coffee_script
    
    # Parse the code systems that are mapped to the OIDs we support
    @codes_hash = HQMF2JS::Generator::CodesToJson.from_xml(codes_file_path)
    codes_json = HQMF2JS::Generator::CodesToJson.hash_to_js(@codes_hash)
    
    # Convert the HQMF document included as a fixture into JavaScript
    @converter = HQMF2JS::Generator::JS.new(doc)
    converted_hqmf = "#{@converter.js_for_data_criteria}
      #{@converter.js_for('IPP')}
      #{@converter.js_for('DENOM')}
      #{@converter.js_for('NUMER')}
      #{@converter.js_for('DENEXCEP')}
      #{@converter.js_for('DUMMY')}"

    initialize_javascript_context(hqmf_utils, codes_json, converted_hqmf)
  end

  def test_converted_hqmf
    # Unspecified time bounds should be nil
    assert_equal nil, @context.eval("numeratorPatient.encounters()[0].asIVL_TS().low.asDate()")
    assert_equal 2010, @context.eval("numeratorPatient.encounters()[0].asIVL_TS().high.asDate().getFullYear()")

    # Measure variables
    assert_equal 2011, @context.eval("MeasurePeriod.low.asDate().getFullYear()")
    assert_equal 0, @context.eval("MeasurePeriod.low.asDate().getMonth()")
    assert_equal 2011, @context.eval("MeasurePeriod.high.asDate().getFullYear()")
    assert_equal 11, @context.eval("MeasurePeriod.high.asDate().getMonth()")
    assert_equal 2011, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().low.asDate().getFullYear()")
    assert_equal 0, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().low.asDate().getMonth()")
    assert_equal 2011, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().high.asDate().getFullYear()")
    assert_equal 11, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().high.asDate().getMonth()")
  
    # Age functions - Fixture is 37.1
    assert @context.eval("hqmfjs.ageBetween17and64(numeratorPatient).isTrue()")
    assert @context.eval("hqmfjs.ageBetween30and39(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.ageBetween17and21(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.ageBetween22and29(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.ageBetween40and49(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.ageBetween50and59(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.ageBetween60and64(numeratorPatient).isTrue()")
    
    # Birthdate function
    assert_equal 1, @context.eval("hqmfjs.birthdateThirtyYearsBeforeMeasurementPeriod(numeratorPatient)").count
    assert_equal 0, @context.eval("hqmfjs.birthdateFiftyYearsBeforeMeasurementPeriod(numeratorPatient)").count

    # Gender functions - Fixture is male
    assert @context.eval("hqmfjs.genderMale(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.genderFemale(numeratorPatient).isTrue()")
    
    # Be sure the actual mechanic of code lists being returned works correctly - Using HasDiabetes as an example
    results = @context.eval("hqmfjs.HasDiabetes(numeratorPatient)[0]")['json']
    assert_equal 3, results['codes'].count
    assert_equal '250', results['codes']['ICD-9-CM'].first
    assert_equal 1270094400, results['time']
    
    # Encounters
    assert_equal 0, @context.eval("hqmfjs.EDorInpatientEncounter(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.AmbulatoryEncounter(numeratorPatient).length")
    
    # Conditions
    assert_equal 1, @context.eval("hqmfjs.HasDiabetes(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.HasGestationalDiabetes(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.HasPolycysticOvaries(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.HasSteroidInducedDiabetes(numeratorPatient).length")
    
    # Results
    assert_equal 2, @context.eval("hqmfjs.HbA1C(numeratorPatient).length")
    
    # Medications
    assert_equal 1, @context.eval("hqmfjs.DiabetesMedAdministered(numeratorPatient).length")
    assert_equal 1, @context.eval("hqmfjs.DiabetesMedAdministeredFor7Days(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.DiabetesMedAdministeredFor9Days(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.DiabetesMedIntended(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.DiabetesMedSupplied(numeratorPatient).length")
    assert_equal 0, @context.eval("hqmfjs.DiabetesMedOrdered(numeratorPatient).length")
    
    # Standard population health query buckets
    assert @context.eval("hqmfjs.IPP(numeratorPatient).isTrue()")
    assert @context.eval("hqmfjs.DENOM(numeratorPatient).isTrue()")
    assert @context.eval("hqmfjs.NUMER(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.DENEXCEP(numeratorPatient).isTrue()")
    
    # COUNTing
    assert @context.eval("hqmfjs.moreThanTwoHbA1CTests(numeratorPatient).isTrue()")
    assert !@context.eval("hqmfjs.moreThanFourHbA1CTests(numeratorPatient).isTrue()")

    # UNIONing
    assert_equal 1, @context.eval("hqmfjs.anyDiabetes(numeratorPatient).length")

    # XPRODUCTing
    assert_equal 1, @context.eval("hqmfjs.allDiabetes(numeratorPatient).length")
  end
end