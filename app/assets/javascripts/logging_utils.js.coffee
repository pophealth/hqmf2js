class @Logger
  @logger: []
  @rationale: {}
  @info: (string) ->
    if @enable_logging
      @logger.push("#{Logger.indent()}#{string}")

  @record: (id, result) ->
    if @enable_rationale and result? and typeof(result.isTrue) == 'function'
      if result.isTrue() and result.length
        json_results = _.map(result,(item) -> {id: item.id, json: item.json})
        if result.specificContext?
          specific_ids = result.specificContext.flattenToIds()
        @rationale[id] = {results: json_results, specifics: specific_ids }
      else  
        @rationale[id] = result.isTrue()

  @enable_logging: true
  @enable_rationale: true
  @short_circuit: true
  @initialized: false
  @indentCount = 0
  @indent: ->
    indent = ''
    (indent+=' ' for num in [0..@indentCount*8])
    indent
  @stringify: (object) ->
    if object and !_.isUndefined(object) and !_.isUndefined(object.length)
      "#{object.length} entries" 
    else
      "#{object}"
  @asBoolean: (object) ->
    if object and !_.isUndefined(object) and !_.isUndefined(object.length)
      object.length>0 
    else
      object
  @toJson: (value) ->
    if (typeof(JSON) == 'object')
      JSON.stringify(value)
    else
      tojson(value)
  @classNameFor: (object) ->
    funcNameRegex = ///function (.+)\(///;
    results = funcNameRegex.exec(object.constructor.toString());
    if (results and results.length > 1)
      results[1]
    else
      ""
  @codedValuesAsString: (codedValues) ->
    "["+_.reduce(codedValues, (memo, entry) -> 
      memo.push("#{entry.codeSystemName()}:#{entry.code()}");
      memo
    , []).join(',')+"]"
  @formatSpecificEntry: (object, index) ->
    if object == hqmf.SpecificsManager.any
      object
    else
      "#{object.id}"
  @formatSpecificContext: (object) ->
    displayRows = []
    if object?.specificContext?.rows?.length
      displayRows.push(Logger.toJson(item.id for item in hqmf.SpecificsManager.occurrences))
      for row in object.specificContext.rows
        do (row) ->
          displayRow = []
          for entry, index in row.values
            do (entry) ->
              displayRow.push(Logger.formatSpecificEntry(entry, index))
          displayRows.push(Logger.toJson(displayRow))
    displayRows
  @logSpecificContext: (object) ->
    Logger.indentCount++
    for row in Logger.formatSpecificContext(object)
      do (row) ->
        Logger.info(row)
    Logger.indentCount--
    
    
@injectLogger = (hqmfjs, enable_logging, enable_rationale, short_circuit) ->
  Logger.enable_logging = enable_logging
  Logger.enable_rationale = enable_rationale
  Logger.short_circuit = short_circuit

  # Wrap all of the data criteria functions generated from HQMF
  _.each(_.functions(hqmfjs), (method) ->
    if method != 'initializeSpecifics'
      hqmfjs[method] = _.wrap(hqmfjs[method], (func) ->

        args = Array.prototype.slice.call(arguments,1)

        Logger.info("#{method}:")
        Logger.indentCount++
        result = func.apply(this, args)

        Logger.indentCount--
        Logger.info("#{method} -> #{Logger.asBoolean(result)}")
        if result.specificContext?.rows?.length
          Logger.info("Specific context")
          Logger.logSpecificContext(result)
          Logger.info("------")
        Logger.record(method,result)
        return result;
      );
  );

  if (!Logger.initialized)
    Logger.initialized=true
    
    # Wrap selected hQuery Patient API functions
    _.each(_.functions(hQuery.Patient.prototype), (method) ->
      if method != 'getEvents' && method != 'getAndCacheEvents'
        if (hQuery.Patient.prototype[method].length == 0)
          hQuery.Patient.prototype[method] = _.wrap(hQuery.Patient.prototype[method], (func) ->
            Logger.info("called patient.#{method}():")
            func = _.bind(func, this)
            result = func()
            Logger.info("patient.#{method}() -> #{Logger.stringify(result)}")
            return result;);
        else
          hQuery.Patient.prototype[method] = _.wrap(hQuery.Patient.prototype[method], (func) ->
            args = Array.prototype.slice.call(arguments,1)
            Logger.info("called patient.#{method}(#{args}):")
            result = func.apply(this, args)
            Logger.info("patient.#{method}(#{args}) -> #{Logger.stringify(result)}")
            return result;);
        
    );
    
    hQuery.CodedEntryList.prototype.match = _.wrap(hQuery.CodedEntryList.prototype.match, (func, codeSet, start, end) ->
      func = _.bind(func, this, codeSet,start,end)
      result = func(codeSet,start,end)
      Logger.info("matched -> #{Logger.stringify(result)}")
      return result;
    );
    
    # Wrap selected HQMF Util functions
    hqmf.SpecificsManagerSingleton.prototype.intersectAll = _.wrap(hqmf.SpecificsManagerSingleton.prototype.intersectAll, (func, boolVal, values, negate=false, episodeIndices, options) ->
      func = _.bind(func, this, boolVal, values, negate, episodeIndices, options)
      result = func(boolVal, values, negate, episodeIndices, options)
      Logger.info("Intersecting (#{values.length}):")
      for value in values
        Logger.logSpecificContext(value)
      Logger.info("Intersected result:")
      Logger.logSpecificContext(result)
      return result;
    );
    
    @getCodes = _.wrap(@getCodes, (func, oid) -> 
      codes = func(oid)
      Logger.info("accessed codes: #{oid}")
      codes
      )
  
    @atLeastOneTrue = _.wrap(@atLeastOneTrue, (func) -> 
      args = Array.prototype.slice.call(arguments,1)
      Logger.info("called atLeastOneTrue(#{args}):")
      Logger.indentCount++
      result = func.apply(this, args)
      Logger.indentCount--
      Logger.info("atLeastOneTrue -> #{result}")
      Logger.record("precondition_#{args[0]}",result)
      result
    )
    
    @allTrue = _.wrap(@allTrue, (func) -> 
      args = Array.prototype.slice.call(arguments,1)
      Logger.info("called allTrue(#{args}):")
      Logger.indentCount++
      result = func.apply(this, args)
      Logger.indentCount--
      Logger.info("allTrue -> #{result}")
      Logger.record("precondition_#{args[0]}",result)
      result
    )

    @allFalse = _.wrap(@allFalse, (func) -> 
      args = Array.prototype.slice.call(arguments,1)
      Logger.info("called allFalse(#{args}):")
      Logger.indentCount++
      result = func.apply(this, args)
      Logger.indentCount--
      Logger.info("allFalse -> #{result}")
      Logger.record("precondition_#{args[0]}",result)
      result
    )

    @eventsMatchBounds = _.wrap(@eventsMatchBounds, (func, events, bounds, methodName, range) -> 
      args = Array.prototype.slice.call(arguments,1)
      result = func(events, bounds, methodName, range)
      Logger.info("#{methodName}(Events: #{Logger.stringify(events)}, Bounds: #{Logger.stringify(bounds)}, Range: #{Logger.toJson(range)}) -> #{Logger.stringify(result)}")
      result
    )

    @atLeastOneFalse = _.wrap(@atLeastOneFalse, (func) -> 
      args = Array.prototype.slice.call(arguments,1)
      Logger.info("called atLeastOneFalse(#{args}):")
      Logger.indentCount++
      result = func.apply(this, args)
      Logger.indentCount--
      Logger.info("atLeastOneFalse -> #{result}")
      Logger.record("precondition_#{args[0]}",result)
      result
    )
    
