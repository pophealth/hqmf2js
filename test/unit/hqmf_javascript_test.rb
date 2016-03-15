require_relative '../test_helper'
require 'hquery-patient-api'

class HqmfJavascriptTest < Minitest::Test
  def setup
    # Open a path to all of our fixtures
    model = JSON.parse(File.open("test/fixtures/NQF59New.json").read)
    doc = HQMF::Document.from_json(model)

    codes_file_path = File.expand_path("../../fixtures/codes/codes.xml", __FILE__)
    
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
  
  def test_codes
    # Make sure we're recalling entries correctly
    assert_equal 1, @context.eval('OidDictionary["2.16.840.1.113883.3.464.1.14"]').count
    assert_equal "00110", @context.eval('OidDictionary["2.16.840.1.113883.3.464.1.14"]["HL7"][0]')
    
    # OIDs that are matched to multiple code systems should also work correctly
    # The list of supported OIDs will eventually be long, so this won't be an exhaustive test, just want to be sure the functionality is right
    assert_equal 3, @context.eval('OidDictionary["2.16.840.1.113883.3.464.1.72"]').count
    assert_equal 2, @context.eval('OidDictionary["2.16.840.1.113883.3.464.1.72"]["CPT"]').count
    assert_equal 3, @context.eval('OidDictionary["2.16.840.1.113883.3.464.1.72"]["LOINC"]').count
    assert_equal 9, @context.eval('OidDictionary["2.16.840.1.113883.3.464.1.72"]["SNOMED-CT"]').count
  end
  
  def test_to_js_method
    value = @converter.to_js(0,@codes_hash)
    local_context = V8::Context.new
    hqmf_utils = HQMF2JS::Generator::JS.library_functions
    local_context.eval("#{hqmf_utils}
                        #{value}")
                        
    assert_equal true, local_context.eval('typeof hqmfjs != undefined')
    assert_equal true, local_context.eval('typeof OidDictionary != undefined')
    assert_equal true, local_context.eval('typeof hqmfjs.IPP != undefined')
    assert_equal true, local_context.eval('typeof hqmfjs.NUMER != undefined')
    assert_equal true, local_context.eval('typeof hqmfjs.DENOM != undefined')
  end

  def test_to_js_method_without_codes
    value = @converter.to_js(0,nil)
    assert !value.match(/<%= oid_dictionary %>/).nil?
  end
  
  def test_converted_hqmf
    # Unspecified time bounds should be nil
    assert_equal nil, @context.eval("numeratorPatient.encounters()[0].asIVL_TS().low.asDate()")
    assert_equal 2010, @context.eval("numeratorPatient.encounters()[0].asIVL_TS().high.asDate().getUTCFullYear()")

    # Measure variables
    assert_equal 2011, @context.eval("MeasurePeriod.low.asDate().getUTCFullYear()")
    assert_equal 0, @context.eval("MeasurePeriod.low.asDate().getUTCMonth()")
    assert_equal 2011, @context.eval("MeasurePeriod.high.asDate().getUTCFullYear()")
    assert_equal 11, @context.eval("MeasurePeriod.high.asDate().getUTCMonth()")
    assert_equal 2011, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().low.asDate().getUTCFullYear()")
    assert_equal 0, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().low.asDate().getUTCMonth()")
    assert_equal 2011, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().high.asDate().getUTCFullYear()")
    assert_equal 11, @context.eval("hqmfjs.MeasurePeriod()[0].asIVL_TS().high.asDate().getUTCMonth()")
  
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
  
  def test_cached_access
    eventCriteria = '{"type": "results", "statuses": [], "includeEventsWithoutStatus": true, "negated": false, "valueSet": getCodes("2.16.840.1.113883.3.464.1.72")}'
    assert_equal 3, @context.eval("numeratorPatient.getEvents(#{eventCriteria}).length")
  end
  
  def test_measure_with_observ
    measure = HQMF::Document.from_json(JSON.parse(File.read(File.join('test','fixtures','json','0495.json'))))
    c = HQMF2JS::Generator::JS.new(measure)
    result = c.js_for('OBSERV',HQMF::PopulationCriteria::OBSERV)
    assert !result.match(/hqmfjs.OBSERV = function/).nil?
  end

  def test_converted_utils
    # Filter events by value - HbA1C as an example
    events = 'numeratorPatient.results().match(getCodes("2.16.840.1.113883.3.464.1.72"))'
    assert_equal 2, @context.eval("filterEventsByValue(#{events}, new IVL_PQ(new PQ(9, '%'), null))").count
    assert_equal 0, @context.eval("filterEventsByValue(#{events}, new IVL_PQ(new PQ(10, '%'), null))").count
    
    # getCode
    assert_equal 1, @context.eval('getCodes("2.16.840.1.113883.3.464.1.14")').count
    assert_equal "00110", @context.eval('getCodes("2.16.840.1.113883.3.464.1.14")["HL7"][0]')
    
    # adjustBoundsForField 
    @context.eval('var procedures = numeratorPatient.procedures()')
    assert_equal 7, @context.eval('procedures.length')
    assert_equal 2010, @context.eval('procedures[0].timeStamp().getFullYear()')
    assert_equal true, @context.eval('procedures[0].includesCodeFrom({"SNOMED-CT": ["401191002"]})')
    @context.eval('var updatedProcedures = adjustBoundsForField(procedures, "incisionTime")')
    assert_equal 1, @context.eval('updatedProcedures.length')
    assert_equal 2005, @context.eval('updatedProcedures[0].timeStamp().getFullYear()')
    assert_equal true, @context.eval('updatedProcedures[0].includesCodeFrom({"SNOMED-CT": ["401191002"]})')
    
    # denormalizeEventsByLocation
    @context.eval('var normalizedEncounters = denormalizeEventsByLocation(numeratorPatient.encounters(), "facilityArrival")')
    assert_equal 1, @context.eval('normalizedEncounters.length')
    assert_equal 10, @context.eval('normalizedEncounters[0].startDate().getUTCMonth()')
    assert_equal 19, @context.eval('normalizedEncounters[0].startDate().getUTCDate()')
    assert_equal 10, @context.eval('normalizedEncounters[0].endDate().getUTCMonth()')
    assert_equal 19, @context.eval('normalizedEncounters[0].endDate().getUTCDate()')
    assert_equal 'bar', @context.eval('normalizedEncounters[0].facility().code()')
    assert_equal 'SNOMED-CT', @context.eval('normalizedEncounters[0].facility().codeSystemName()')
    @context.eval('normalizedEncounters = denormalizeEventsByLocation(numeratorPatient.encounters(), "facilityDeparture")')
    assert_equal 1, @context.eval('normalizedEncounters.length')
    assert_equal 11, @context.eval('normalizedEncounters[0].startDate().getUTCMonth()')
    assert_equal 1, @context.eval('normalizedEncounters[0].startDate().getUTCDate()')
    assert_equal 11, @context.eval('normalizedEncounters[0].endDate().getUTCMonth()')
    assert_equal 1, @context.eval('normalizedEncounters[0].endDate().getUTCDate()')
  end
  
  def test_map_reduce_generation
    model = JSON.parse(File.open("test/fixtures/NQF59New.json").read)
    doc = HQMF::Document.from_json(model)
    
    map_reduce = HQMF2JS::Converter.generate_map_reduce(doc)
    
    # Extremely loose testing here. Just want to be sure for now that we're getting results of some kind.
    # We'll test for validity over on the hQuery Gateway side of things.
    assert map_reduce[:map].include? 'map'
    assert map_reduce[:reduce].include? 'reduce'
    # Check functions to include actual HQMF converted function, HQMF utility function, and OID dictionary
    assert map_reduce[:functions].include? 'IPP'
    assert map_reduce[:functions].include? 'atLeastOneTrue'
    assert map_reduce[:functions].include? 'OidDictionary'
  end
  
  
  def test_missing_id
    
    context = HQMF2JS::Generator::ErbContext.new({})
    criteria = HQMF::DataCriteria.new(nil,nil,nil,nil,nil,nil,nil,'patient_characteristic',nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil)
    
    exception = assert_raises RuntimeError do
      n = context.js_name(criteria)
    end
    assert exception.message.match(/^No identifier for .*/)
  end  

end