require 'pathname'
require 'fileutils'

namespace :hqmf do
  desc 'Convert a HQMF file to JavaScript'
  task :convert, [:hqmf,:hqmf_version] do |t, args|
    
    raise "The path to the the hqmf xml must be specified" unless args.hqmf
    
    FileUtils.mkdir_p File.join(".","tmp",'js')
    file = File.expand_path(args.hqmf)
    version = args.hqmf_version || HQMF::Parser::HQMF_VERSION_1

    filename = Pathname.new(file).basename
    if (version == HQMF::Parser::HQMF_VERSION_1)
      doc = HQMF::Parser::V1Parser.new.parse(File.open(file).read, version)
    else
      doc = HQMF::Parser::V2Parser.new.parse(File.open(file).read, version)
    end

    gen = HQMF2JS::Generator::JS.new(doc)

    out_file = File.join(".","tmp",'js',"#{filename}.js")
    
    File.open(out_file, 'w') do |f| 

      f.write("// #########################\n")
      f.write("// ##### DATA CRITERIA #####\n")
      f.write("// #########################\n\n")
      f.write(gen.js_for_data_criteria())      
      
      f.write("// #########################\n")
      f.write("// ##### POPULATION CRITERIA #####\n")
      f.write("// #########################\n\n")
           
      f.write("// INITIAL PATIENT POPULATION\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::IPP))
      f.write("\n// DENOMINATOR\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::DENOM))
      f.write("\n// NUMERATOR\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::NUMER))
      f.write("\n// EXCLUSIONS\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::DENEX))
      f.write("\n// DENOMINATOR EXCEPTIONS\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::DENEXCEP))
      f.write("\n// MSRPOPL\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::MSRPOPL))
      f.write("\n// OBSERV\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::OBSERV))
      f.write("\n// MSRPOPLEX\n")
      f.write(gen.js_for(HQMF::PopulationCriteria::MSRPOPLEX))
    end
    
    puts "wrote javascript to: #{out_file}"
    
  end
end
    