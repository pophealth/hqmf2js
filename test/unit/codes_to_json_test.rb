require_relative '../test_helper'

class CodesToJsonTest < Minitest::Test
  
  def setup
  end


  def test_parsing_from_xml
    
    codes_file_path = File.expand_path("../../fixtures/codes/codes.xml", __FILE__)
    # Parse the code systems that are mapped to the OIDs we support
    codes_json = HQMF2JS::Generator::CodesToJson.hash_to_js(HQMF2JS::Generator::CodesToJson.from_xml(codes_file_path))
    
    @context = get_js_context("var dictionary = #{codes_json}")
    
    assert_equal 19, @context.eval("dictionary").entries.length
    assert_equal "CPT", @context.eval("dictionary['2.16.840.1.113883.3.464.1.42']").entries.first[0]
    assert_equal 19, @context.eval("dictionary['2.16.840.1.113883.3.464.1.42']").entries.first[1].length
    
  end

  def test_codes_to_json
    value_sets = JSON.parse(File.read(File.join('test','fixtures','codes','codes.json'))).map {|vs| HealthDataStandards::SVS::ValueSet.new(vs)}
    oid_map = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets)

    assert_equal ["1.2.3.4.5","1.2.3.4.6"], oid_map.keys.sort
    assert_equal ["ICD-9-CM","SNOMED-CT"], oid_map["1.2.3.4.5"].keys.sort
    assert_equal ["126", "127"], oid_map["1.2.3.4.5"]["ICD-9-CM"].sort
    assert_equal ["123", "124", "125"], oid_map["1.2.3.4.5"]["SNOMED-CT"].sort
    assert_equal ["CPT","SNOMED-CT"], oid_map["1.2.3.4.6"].keys.sort
    assert_equal ["125C", "126D", "127E"], oid_map["1.2.3.4.6"]["CPT"].sort
    assert_equal ["123A", "124B"], oid_map["1.2.3.4.6"]["SNOMED-CT"].sort

  # def self.from_value_sets(value_sets)
  #   # make sure we have a string keyed hash
  #   value_sets = JSON.parse(value_sets.to_json)
  #   translation = {}
  #   value_sets.each do |value_set|
  #     code_sets = {}
  #     value_set["concepts"].each do |code_set|
  #       code_sets[code_set["code_system_name"]] ||= []
  #       code_sets[code_set["code_system_name"]].concat(code_set["code"].to_a)
  #     end
      
  #     translation[value_set["oid"]] = code_sets
  #   end
    
  #   translation
  # end


  end


end
