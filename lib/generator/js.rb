module HQMF2JS
  module Generator
    
    def self.render_template(name, params)
      template_path = File.expand_path(File.join('..', "#{name}.js.erb"), __FILE__)
      template_str = File.read(template_path)
      template = ERB.new(template_str, nil, '-', "_templ#{TemplateCounter.instance.new_id}")
      context = ErbContext.new(params)
      template.result(context.get_binding)        
    end
  
    # Utility class used to supply a binding to Erb. Contains utility functions used
    # by the erb templates that are used to generate code.
    class ErbContext < OpenStruct
    
      # Create a new context
      # @param [Hash] vars a hash of parameter names (String) and values (Object).
      # Each entry is added as an accessor of the new Context
      def initialize(vars)
        super(vars)
      end
    
      # Get a binding that contains all the instance variables
      # @return [Binding]
      def get_binding
        binding
      end
      
      def js_for_measure_period(measure_period)
        HQMF2JS::Generator.render_template('measure_period', {'measure_period' => measure_period})
      end
      
      def js_for_characteristic(criteria)
        HQMF2JS::Generator.render_template('characteristic', {'criteria' => criteria})
      end
      
      def js_for_patient_data(criteria)
        HQMF2JS::Generator.render_template('patient_data', {'criteria' => criteria})
      end
      
      def js_for_derived_data(criteria)
        HQMF2JS::Generator.render_template('derived_data', {'criteria' => criteria})
      end
      
      def field_method(field_name)
        HQMF::DataCriteria::FIELDS[field_name][:coded_entry_method].to_s.camelize(:lower)
      end
      
      def js_for_value(value)
        if value
          if value.respond_to?(:derived?) && value.derived?
            value.expression
          else
            if value.type=='CD'
              if value.code_list_id
                "new CodeList(getCodes(\"#{value.code_list_id}\"))"
              else
                "new CD(\"#{value.code}\", \"#{value.system}\")"
              end
            elsif value.type=='ANYNonNull'
              "new #{value.type}()"
            elsif value.respond_to?(:unit) && value.unit != nil
              "new #{value.type}(#{value.value}, \"#{value.unit}\", #{value.inclusive?})"
            elsif value.respond_to?(:inclusive?) and !value.inclusive?.nil?
              "new #{value.type}(\"#{value.value}\", null, #{value.inclusive?})"
            else
              "new #{value.type}(\"#{value.value}\")"
            end
          end
        else
          'null'
        end
      end

      def js_for_bounds(bounds)
        if (bounds.respond_to?(:low) && bounds.respond_to?(:high))
          "new IVL_PQ(#{js_for_value(bounds.low)}, #{js_for_value(bounds.high)})"
        else
          "#{js_for_value(bounds)}"
        end
      end
      
      def js_for_date_bound(criteria)
        bound = nil
        if criteria.effective_time
          if criteria.effective_time.high
            bound = criteria.effective_time.high
          elsif criteria.effective_time.low
            bound = criteria.effective_time.low
          end
        elsif criteria.temporal_references
          # this is a check for age against the measurement period
          measure_period_reference = criteria.temporal_references.select {|reference| reference.reference and reference.reference.id == HQMF::Document::MEASURE_PERIOD_ID}.first
          if (measure_period_reference)
            case measure_period_reference.type
            when 'SBS','SAS','EBS','EAS'
              return 'MeasurePeriod.low.asDate()'
            when 'SBE','SAE','EBE','EAE'
              return 'MeasurePeriod.high.asDate()'
            else
              raise "do not know how to get a date for this type"
            end
          end
        end
        
        if bound
          "#{js_for_value(bound)}.asDate()"
        else
          'MeasurePeriod.high.asDate()'
        end
      end
      
      def js_for_code_list(criteria)
        if criteria.inline_code_list
          criteria.inline_code_list.to_json
        else
          "getCodes(\"#{criteria.code_list_id}\")"
        end
      end
      
      # Returns the JavaScript generated for a HQMF::Precondition
      def js_for_precondition(precondition, indent)
        HQMF2JS::Generator.render_template('precondition', {'doc' => doc, 'precondition' => precondition, 'indent' => indent})
      end
      
      def patient_api_method(criteria)
        criteria.patient_api_function
      end
      
      def conjunction_code_for(precondition)
        precondition.conjunction_code_with_negation
      end
      
      # Returns a Javascript compatable name based on an entity's identifier
      def js_name(entity)
        if !entity.id
          raise "No identifier for #{entity.to_json}"
        end
        entity.id.gsub(/\W/, '_')
      end
      
    end

    class JS
  
      # Entry point to JavaScript generator
      def initialize(doc)
        @doc = doc
      end
      
      def to_js(codes, population_index=0)
        population_index ||= 0
        population = @doc.populations[population_index]
        "
        // #########################
        // ##### DATA ELEMENTS #####
        // #########################

        OidDictionary = #{HQMF2JS::Generator::CodesToJson.hash_to_js(codes)};
        #{js_for_data_criteria()}

        // #########################
        // ##### MEASURE LOGIC #####
        // #########################
        
        #{js_initialize_specifics(@doc.source_data_criteria)}

        // INITIAL PATIENT POPULATION
        #{js_for(population['IPP'], 'IPP', true)}
        // DENOMINATOR
        #{js_for(population['DENOM'], 'DENOM', true)}
        // NUMERATOR
        #{js_for(population['NUMER'], 'NUMER')}
        #{js_for(population['EXCL'], 'EXCL')}
        #{js_for(population['DENEXCEP'], 'DENEXCEP')}
        "
      end
      
      def js_initialize_specifics(data_criteria)
        specific_occurrences = []
        data_criteria.each do |criteria|
          if (criteria.specific_occurrence)
            specific_occurrences << {id: "#{criteria.id}", type: "#{criteria.specific_occurrence_const}", function: "#{criteria.source_data_criteria}"}
          end
        end
        json_list = specific_occurrences.map {|occurrence| occurrence.to_json}
        specifics_list = json_list.join(',')
        specifics_list = ",#{specifics_list}" unless specifics_list.empty?
        "hqmfjs.initializeSpecifics = function(patient_api, hqmfjs) { Specifics.initialize(patient_api,hqmfjs#{specifics_list}) }"
      end
      
      # Generate JS for a HQMF2::PopulationCriteria
      def js_for(criteria_code, type=nil, when_not_found=false)
        # for multiple populations, criteria code will be something like IPP_1 and type will be IPP
        type ||= criteria_code
        criteria = @doc.population_criteria(criteria_code)
        if criteria && criteria.preconditions && criteria.preconditions.length > 0
          HQMF2JS::Generator.render_template('population_criteria', {'doc' => @doc, 'criteria' => criteria, 'type'=>type})
        else
          "hqmfjs.#{type} = function(patient) { return new Boolean(#{when_not_found}); }"
        end
      end
      
      # Generate JS for a HQMF2::DataCriteria
      def js_for_data_criteria
        HQMF2JS::Generator.render_template('data_criteria', {'all_criteria' => @doc.specific_occurrence_source_data_criteria.concat(@doc.all_data_criteria), 'measure_period' => @doc.measure_period})
      end
      
      def self.library_functions
        ctx = Sprockets::Environment.new(File.expand_path("../../..", __FILE__))
        Tilt::CoffeeScriptTemplate.default_bare = true 
        ctx.append_path "app/assets/javascripts"
        
        ["// #########################\n// ###### PATIENT API #######\n// #########################\n",
         HqueryPatientApi::Generator.patient_api_javascript.to_s,
         "// #########################\n// ### LIBRARY FUNCTIONS ####\n// #########################\n",
         ctx.find_asset('hqmf_util').to_s, 
         "// #########################\n// ### PATIENT EXTENSION ####\n// #########################\n",
         ctx.find_asset('patient_api_extension').to_s,
         "// #########################\n// ##### LOGGING UTILS ######\n// #########################\n",
         ctx.find_asset('logging_utils').to_s,
         "// #########################\n// ## SPECIFIC OCCURRENCES ##\n// #########################\n",
         ctx.find_asset('specifics').to_s].join("\n")
      end
  
    end
  
    # Simple class to issue monotonically increasing integer identifiers
    class Counter
      def initialize
        @count = 0
      end
      
      def new_id
        @count+=1
      end
    end
      
    # Singleton to keep a count of function identifiers
    class FunctionCounter < Counter
      include Singleton
    end
    
    # Singleton to keep a count of template identifiers
    class TemplateCounter < Counter
      include Singleton
    end
  end
end