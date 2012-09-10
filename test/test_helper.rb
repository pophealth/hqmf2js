require 'cover_me'
require 'test/unit'
require 'turn'

if RUBY_PLATFORM=='java'
  require 'rhino'
else
  require 'v8'
end

# allows import of patient api without rails
module HqueryPatientApi 
  module Rails
    class Engine

    end
  end
end


PROJECT_ROOT = File.expand_path("../../", __FILE__)
require File.join(PROJECT_ROOT, 'lib', 'hqmf2js')

def get_js_context(javascript)
  if RUBY_PLATFORM=='java'
    @context = Rhino::Context.new
  else
    @context = V8::Context.new
  end
  @context.eval(javascript)
  @context
end

def initialize_javascript_context(hqmf_utils, codes_json, converted_hqmf)
  patient_api = File.open('test/fixtures/patient_api.js').read
  fixture_json = File.read('test/fixtures/patients/larry_vanderman.json')
  initialize_patient = 'var numeratorPatient = new hQuery.Patient(larry);'

  if RUBY_PLATFORM=='java'
    @context = Rhino::Context.new
  else
    @context = V8::Context.new
  end
  @context.eval("#{patient_api}
    #{hqmf_utils}
    var OidDictionary = #{codes_json};
    #{converted_hqmf}
    var larry = #{fixture_json};
    #{initialize_patient}")
  @context.eval("Specifics.initialize()")
end

def compile_coffee_script
  ctx = Sprockets::Environment.new(File.expand_path("../../..", __FILE__))
  Tilt::CoffeeScriptTemplate.default_bare = true 
  ctx.append_path "app/assets/javascripts"
  HQMF2JS::Generator::JS.library_functions
end
