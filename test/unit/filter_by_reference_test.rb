require_relative '../test_helper'
require 'hquery-patient-api'

class FilterByReferenceTest < Minitest::Test
  
  def setup
    @context = get_js_context(HQMF2JS::Generator::JS.library_functions)
    @context.eval("hqmf.SpecificsManager.initialize()")
  end

  def test_filter
    @context.eval "var evts = [new hQuery.CodedEntry({'_id' : 'id1', 'references' : [{'referenced_id' : 'id4', 'type' : 'fulfills'}]}),
    new hQuery.CodedEntry({'_id' : 'id2','references' : [{'referenced_id' : 'id5', 'type' : 'some_reference'}]}),
    new hQuery.CodedEntry({'_id' : 'id3'})]

    var pos = [new hQuery.CodedEntry({'_id' : 'id4'}),
    new hQuery.CodedEntry({'_id' : 'id5'}),
    new hQuery.CodedEntry({'_id' : 'id6'})] 

    "

    assert_equal 1, @context.eval("filterEventsByReference(evts,'fulfills',pos).length")
    assert_equal 'id1' , @context.eval("filterEventsByReference(evts,'fulfills',pos)[0].id")
    assert_equal 1, @context.eval("filterEventsByReference(evts,'some_reference',pos).length")
    assert_equal 'id2' , @context.eval("filterEventsByReference(evts,'some_reference',pos)[0].id")
    assert_equal 0, @context.eval("filterEventsByReference(evts,'nonexistent_ref',pos).length")

  end

  def test_communicationFilter

    @context.eval "var communication_evts = [new hQuery.Communication({ 'direction' : 'communication_from_patient_to_provider' })]

    "

    assert_equal 1, @context.eval("filterEventsByCommunicationDirection(communication_evts,'communication_from_patient_to_provider').length")
    assert_equal 0, @context.eval("filterEventsByCommunicationDirection(communication_evts,'communication_from_provider_to_patient').length")
  end
end
