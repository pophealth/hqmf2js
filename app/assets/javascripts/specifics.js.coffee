@hqmf ||= {}

###
  {
    rows: [
      [1,3,5],
      [1,7,8],
    ]
  }

A singleton class the represents the table of all specific occurrences
###
class hqmf.SpecificsManagerSingleton
  constructor: ->
    @patient = null
    @any = '*'

  initialize: (patient, hqmfjs, occurrences...)->
    @occurrences = occurrences
    @keyLookup = {}
    @indexLookup = {}
    @typeLookup = {}
    @functionLookup = {}
    @patient = patient
    @hqmfjs = hqmfjs
    for occurrenceKey,i in occurrences
      @keyLookup[i] = occurrenceKey.id
      @indexLookup[occurrenceKey.id] = i
      @functionLookup[i] = occurrenceKey.function
      @typeLookup[occurrenceKey.type] ||= []
      @typeLookup[occurrenceKey.type].push(i)
  
  _generateCartisian: (allValues) ->
    _.reduce(allValues, (as, bs) -> 
      product = []
      for a in as
        for b in bs
          product.push(a.concat(b))
      product
    , [[]])
  
  identity: ->
    new hqmf.SpecificOccurrence([new Row(undefined)])

  setIfNull: (events) ->
    # Add specifics if missing, appropriately based on the truthiness
    if !events.specificContext?
      if events.isTrue()
        events.specificContext=hqmf.SpecificsManager.identity()
      else
        events.specificContext=hqmf.SpecificsManager.empty()
    events
      
  getColumnIndex: (occurrenceID) ->
    columnIndex = @indexLookup[occurrenceID]
    if typeof columnIndex == "undefined"
      throw new Error("Unknown occurrence identifier: "+occurrenceID)
    columnIndex

  empty: ->
    new hqmf.SpecificOccurrence([])

  # Extract events for leftmost of supplied rows, returning copies with a specificRow attribute set
  extractEventsForLeftMost: (rows) ->
    events = []
    for row in rows
      for event in row.leftMostEvents()
        event = new event.constructor(event.json)
        event.specificRow = row
        events.push(event)
    events

  intersectSpecifics: (nextPopulation, previousPopulation, occurrenceIDs) ->
    # we need to pass the episode indicies all the way down through the interesection to the match function
    # this must be done because we need to ensure that on intersection of populations the * does not allow an episode through
    # that was not part of a previous population
    episodeIndices = null
    episodeIndices = (@getColumnIndex(occurrenceID) for occurrenceID in occurrenceIDs) if occurrenceIDs?
    value = @intersectAll(new Boolean(nextPopulation.isTrue()), [nextPopulation, previousPopulation], false, episodeIndices)
    value
    
  # Returns a count of the unique events that match the criteria for the supplied
  # specific occurrence. Call after validating that population criteria are met. Returns
  # 1 if occurrenceID is null, for use with patient based measures. 
  countUnique: (occurrenceIDs, intersectedPopulation) ->
    if occurrenceIDs?
      columnIndices = (@getColumnIndex(occurrenceID) for occurrenceID in occurrenceIDs)
      intersectedPopulation.specificContext.uniqueEvents(columnIndices)
    else if @validate(intersectedPopulation)
      1
    else
      0
  
  # remove any rows from initial that have the same event id as a row in exclusions for 
  # the specified occurence id
  exclude: (occurrenceIDs, initial, exclusions) ->
    if occurrenceIDs?
      resultContext = initial.specificContext
      for occurrenceID in occurrenceIDs
        columnIndex = @getColumnIndex(occurrenceID)
        resultContext = resultContext.removeMatchingRows(columnIndex, exclusions.specificContext)
      result = new Boolean(resultContext.hasRows())
      result.specificContext = resultContext
      return result
    else if @validate(exclusions)
      return @maintainSpecifics(new Boolean(false), initial)
    else
      return initial

  # Returns a boolean indication of whether all of the supplied population criteria are
  # met
  validate: (intersectedPopulation) ->
    intersectedPopulation.isTrue() and intersectedPopulation.specificContext.hasRows()
  
  intersectAll: (boolVal, values, negate=false, episodeIndices, options = {}) ->
    result = new hqmf.SpecificOccurrence
    # add identity row
    result.addIdentityRow()
    for value in values
      if value.specificContext?
        result = result.intersect(value.specificContext, episodeIndices, options)
    if negate and (!result.hasRows() or result.hasSpecifics())
      result = result.negate()
      result = result.compactReusedEvents()
      # this is a little odd, but it appears when we have a negation with specifics we can
      # ignore the logical result of the negation. The reason we do this is because we may
      # get too many negated values.  Values that may be culled later via other specific 
      # occurrences.  Thus we do not want to return false out of a negation because the 
      # values we are evaluating as false may be dropped.
      # we need to verify that we actually have some occurrences
      boolVal = new Boolean(true) if @occurrences.length > 0
    boolVal.specificContext = result.compactReusedEvents()
    boolVal

  unionAll: (boolVal, values,negate=false) ->
    result = new hqmf.SpecificOccurrence
    for value in values
      if value.specificContext? and (value.isTrue() or negate)
        result = result.union(value.specificContext) if value.specificContext?
    
    if negate and (!result.hasRows() or result.hasSpecifics())
      result = result.negate() 
      # this is a little odd, but it appears when we have a negation with specifics we can 
      # ignore the logical result of the negation.  See comment in intersectAll.
      # we need to verify that we actually have some occurrences
      boolVal = new Boolean(true) if @occurrences.length > 0
    boolVal.specificContext = result
    boolVal

  # Given a set of events with a specificContext, filter the events to include only those
  # referenced in the specific context
  filterEventsAgainstSpecifics: (events) ->
    # If there are no specifics (ie identity) we return them all as-is
    return events unless events.specificContext.hasSpecifics()

    # Find all the events referenced in the specific context
    referencedEvents = hqmf.SpecificsManager.extractEventsForLeftMost(events.specificContext.rows)
    referencedEventIds = _(referencedEvents).pluck('id')

    # Filter original events to only return referenced ones (and ones without an ID, likely dates)
    result = _(events).select (e) -> !e.id || _(referencedEventIds).contains(e.id)

    # Copy the specifics over and return the result
    hqmf.SpecificsManager.maintainSpecifics(result, events)
    return result

  # copy the specifics parameters from an existing element onto the new value element
  maintainSpecifics: (newElement, existingElement) ->
    # We handle a special case: if the existing element is falsy (ie an empty result set), and the new element
    # is truthy (ie a boolean true), and the specific context is the empty set (no rows), we change it to the
    # identity; this can happen, for example, if the new element is checking COUNT=0 of the existing element
    if newElement.isTrue() && existingElement.isFalse() && existingElement.specificContext? && !existingElement.specificContext.hasRows()
      newElement.specificContext = hqmf.SpecificsManager.identity()
    else
      newElement.specificContext = existingElement.specificContext
    newElement.specific_occurrence = existingElement.specific_occurrence
    newElement

  flattenToIds: (specificContext) ->
    specificContext?.flattenToIds() || []

  storeFinal: (key, result, target) ->
    target[key] = hqmf.SpecificsManager.flattenToIds(result.specificContext)

    
@hqmf.SpecificsManager = new hqmf.SpecificsManagerSingleton

class hqmf.SpecificOccurrence
  constructor: (rows=[])->
    @rows = rows
  
  addRows: (rows) ->
    @rows = @rows.concat(rows)
    
  # Return a new SpecificOccurrence with any matching rows removed  
  removeMatchingRows: (columnIndex, other) ->
    removeAll = false
    idsToRemove = []
    for row in other.rows
      if row.values[columnIndex].id?
        idsToRemove.push(row.values[columnIndex].id)
      else if row.values[columnIndex] == hqmf.SpecificsManager.any
        removeAll = true
    rowsToAdd = []
    if not removeAll
      for row in @rows
        if not (row.values[columnIndex].id in idsToRemove)
          rowsToAdd.push(row)
    result = new hqmf.SpecificOccurrence(rowsToAdd)
    result
  
  removeDuplicateRows: () ->
    # Uniq rows based on each row's string transformation
    uniqRows = {}
    uniqRows[row.toHashKey()] = row for row in @rows
    new hqmf.SpecificOccurrence(_(uniqRows).values())
    
  # Returns a count of unique events for a supplied column index
  uniqueEvents: (columnIndices) ->
    eventIds = []
    for columnIndex in columnIndices
      for row in @rows
        event = row.values[columnIndex]
        if event != hqmf.SpecificsManager.any and not (event.id in eventIds)
          onlyOneMatch = true
          # we want to check that we do not have multiple episodes of care matching on this row.  If we do, then that means
          # that we have a reliance on multiple episodes of care for this row when we can only rely on one.  If we have multiple
          # then we want to disregard this row.
          if (columnIndices.length > 1)
            for columnIndexInside in columnIndices
              onlyOneMatch = false if (columnIndexInside != columnIndex and row.values[columnIndexInside] != hqmf.SpecificsManager.any)

          if onlyOneMatch
            eventIds.push(event.id)
    eventIds.length
  
  hasExactRow: (other) ->
    for row in @rows
      return true if row.equals(other)
    return false
  
  union: (other) ->
    value = new hqmf.SpecificOccurrence()
    value.rows = @rows.concat(other.rows)
    value.removeDuplicateRows()
  
  intersect: (other, episodeIndices, options = {}) ->
    value = new hqmf.SpecificOccurrence()
    for leftRow in @rows
      for rightRow in other.rows
        result = leftRow.intersect(rightRow, episodeIndices, options)
        value.rows.push(result) if result?
    value.removeDuplicateRows()
  
  getLeftMost: ->
    specificLeftMost = undefined
    for row in @rows
      specificLeftMost = row.specificLeftMost unless specificLeftMost?
      return undefined if specificLeftMost != row.specificLeftMost
    specificLeftMost

  negate: ->
    negatedRows = []
    keys = []
    allValues = []
    for index in @specificsWithValues()
      keys.push(hqmf.SpecificsManager.keyLookup[index])
      allValues.push(hqmf.SpecificsManager.hqmfjs[hqmf.SpecificsManager.functionLookup[index]](hqmf.SpecificsManager.patient))
    cartesian = hqmf.SpecificsManager._generateCartisian(allValues)
    for values in cartesian
      occurrences = {}
      for key, i in keys
        occurrences[key] = values[i]
      row = new Row(@getLeftMost(), occurrences)
      negatedRows.push(row) if !@hasRow(row)
    (new hqmf.SpecificOccurrence(negatedRows)).compactReusedEvents()
  
  # removes any rows that have the same value for OccurrenceA and OccurrenceB
  compactReusedEvents: ->
    newRows = []
    for myRow in @rows
      goodRow = true
      for type,indexes of hqmf.SpecificsManager.typeLookup
        ids = []
        for index in indexes
          ids.push(myRow.values[index].id) if myRow.values[index] != hqmf.SpecificsManager.any
        goodRow &&= ids.length == _.unique(ids).length
      newRows.push(myRow) if goodRow
    new hqmf.SpecificOccurrence(newRows)
  
  # Given a set of events, return new specifics removing any rows that *do not* refer to that set of events
  filterSpecificsAgainstEvents: (events) ->
    # If there are no specifics (ie identity) return what we have as-is
    return this unless @hasSpecifics()

    # Keep and return the rows that refer to any of the provided events (via a leftMost)
    rowsToKeep = _(@rows).select (row) ->
      _(row.leftMostEvents()).any (leftMostEvent) ->
        _(events).any (event) ->
          # We consider events the same if either 1) both have ids and the ids are the same, or 2) both are
          # dates, and the dates are the same
          (event instanceof Date && leftMostEvent instanceof Date && event.getTime() == leftMostEvent.getTime()) ||
          (event.id? && leftMostEvent.id? && event.id == leftMostEvent.id)

    new hqmf.SpecificOccurrence(rowsToKeep)

  hasRow: (row) ->
    found = false
    for myRow in @rows
      result = myRow.intersect(row)
      return true if result?
    return false
  
  hasRows: ->
    @rows.length > 0
  
  specificsWithValues: ->
    foundSpecificIndexes = []
    for row in @rows
      foundSpecificIndexes = foundSpecificIndexes.concat(row.specificsWithValues())
    _.unique(foundSpecificIndexes)
  
  hasSpecifics: ->
    anyHaveSpecifics = false
    for row in @rows
      anyHaveSpecifics ||= row.hasSpecifics()
    anyHaveSpecifics
  
  finalizeEvents: (eventsContext, boundsContext) ->
    result = this
    result = result.intersect(eventsContext) if eventsContext?
    result = result.intersect(boundsContext) if boundsContext?
    result.compactReusedEvents()
  
  # Group rows by everything except the leftmost to apply the subset only to the events from the specific
  # occurrence context rows on the leftmost column. eg for "MOST RECENT: Occurrence A of Lab Result during
  # Occurrence A of Encounter" we want to group by the encounter and apply the most recent to the set of
  # lab results per group (ie encounter)
  group: ->
    groupedRows = {}
    for row in @rows
      groupedRows[row.groupKeyForLeftMost()] ||= []
      groupedRows[row.groupKeyForLeftMost()].push(row)
    groupedRows
    
  COUNT: (range, fields) ->
    @applyRangeSubset(COUNT, range, fields)

  MIN: (range, fields) ->
    @applyRangeSubset(MIN, range, fields)

  MAX: (range, fields) ->
    @applyRangeSubset(MAX, range, fields)

  SUM: (range, fields) ->
    @applyRangeSubset(SUM, range, fields)

  MEDIAN: (range, fields) ->
    @applyRangeSubset(MEDIAN, range, fields)
    
  applyRangeSubset: (func, range, fields) ->
    return this if !@hasSpecifics()
    resultRows = []
    groupedRows = @group()
    for groupKey, group of groupedRows
      if func(hqmf.SpecificsManager.extractEventsForLeftMost(group), range, null, fields).isTrue()
        resultRows = resultRows.concat(group)
    new hqmf.SpecificOccurrence(resultRows)

  FIRST: ->
    @applySubset(FIRST)

  SECOND: ->
    @applySubset(SECOND)

  THIRD: ->
    @applySubset(THIRD)

  FOURTH: ->
    @applySubset(FOURTH)

  FIFTH: ->
    @applySubset(FIFTH)

  LAST: ->
    @applySubset(LAST)

  RECENT: ->
    @applySubset(RECENT)

  hasLeftMost: ->
    for row in @rows
      if row.specificLeftMost? || row.nonSpecificLeftMost?
        return true
    return false
    
  applySubset: (func) ->
    return this if !@hasSpecifics() || !@hasLeftMost()
    resultRows = []
    groupedRows = @group()
    for groupKey, group of groupedRows
      entries = func(hqmf.SpecificsManager.extractEventsForLeftMost(group))
      resultRows.push(entry.specificRow) for entry in entries
    new hqmf.SpecificOccurrence(resultRows)
  
  addIdentityRow: ->
    @addRows(hqmf.SpecificsManager.identity().rows)

  flattenToIds: ->
    result = []
    for row in @rows
      result.push(row.flattenToIds())
    result

class Row
  # {'OccurrenceAEncounter':1, 'OccurrenceBEncounter'2}
  constructor: (specificLeftMost, occurrences={}) ->
    @length = hqmf.SpecificsManager.occurrences.length
    @values = []
    @specificLeftMost = specificLeftMost
    @nonSpecificLeftMost = occurrences[undefined]
    for i in [0...@length]
      key = hqmf.SpecificsManager.keyLookup[i]
      value = occurrences[key] || hqmf.SpecificsManager.any
      @values[i] = value

  hasSpecifics: ->
    @length = hqmf.SpecificsManager.occurrences.length
    foundSpecific = false
    for i in [0...@length]
      return true if @values[i] != hqmf.SpecificsManager.any
    false

  specificsWithValues: ->
    @length = hqmf.SpecificsManager.occurrences.length
    foundSpecificIndexes = []
    for i in [0...@length]
      foundSpecificIndexes.push(i) if @values[i]? and @values[i] != hqmf.SpecificsManager.any
    foundSpecificIndexes

  equals: (other) ->
    equal = true;
    
    equal &&= Row.valuesEqual(@nonSpecificLeftMost, other.nonSpecificLeftMost)
    for value,i in @values
      equal &&= Row.valuesEqual(value, other.values[i])
    equal

  intersect: (other, episodeIndices, options = {}) ->

    # When we're calculating an actual intersection, where we're returning a set of events, we want to make sure that rows that reference
    # disjoint expressions aren't combined; this isn't true if we're calculating a boolean AND, chaining temporal operators, etc
    if options.considerLeftMost
      # If rows being intersected have different leftMost values, with neither null, then the rows reference disjoint expressions and can't be intersected
      return undefined if @specificLeftMost && other.specificLeftMost && !Row.valuesEqual(@specificLeftMost, other.specificLeftMost)
      return undefined if @nonSpecificLeftMost && other.nonSpecificLeftMost && !Row.valuesEqual(@nonSpecificLeftMost, other.nonSpecificLeftMost)
      # We can set the result row to leftMost + tempValue of whichever of row has it set, since they'll either be the same or one will be undefined
      intersectedRow = new Row(@specificLeftMost || other.specificLeftMost, {})
      intersectedRow.nonSpecificLeftMost = @nonSpecificLeftMost || other.nonSpecificLeftMost
    else
      intersectedRow = new Row(@specificLeftMost, {})
      intersectedRow.nonSpecificLeftMost = @nonSpecificLeftMost

    # if all the episodes are any, then they were not referenced by the parent population.  This occurs when an intersection is done 
    # against the identity row.  In this case we want to allow the specific occurrences through.  This happens when we intersect against a measure
    # without a denomninator, and on regular intersections since we start with the identity row in the context.
    allEpisodesAny = (episodeIndices? && (@allValuesAny(episodeIndices) || other.allValuesAny(episodeIndices)))

    for value,i in @values
      # check if the value is an episode of care.  If so it will be treated differently in the match function
      isEpisodeOfCare = (episodeIndices? && !allEpisodesAny && episodeIndices.indexOf(i) >= 0)
      result = Row.match(value, other.values[i], isEpisodeOfCare)
      if result?
        intersectedRow.values[i] = result 
      else
        return undefined
    intersectedRow
  
  allValuesAny: (indicies) ->
    for i in indicies
      return false if @values[i] != hqmf.SpecificsManager.any
    return true

  groupKeyForLeftMost: ->
    # Get the key(s) to group by, handling hash of specifics or single specific
    if _.isObject(@specificLeftMost)
      @groupKey(_(@specificLeftMost).chain().values().flatten().value())
    else
      @groupKey([@specificLeftMost])

  groupKey: (keys) ->
    keys = [keys] if _.isString(keys)
    keyForGroup = ''
    for i in [0...@length]
      if _(keys).include(hqmf.SpecificsManager.keyLookup[i])
        keyForGroup += "X_"
      else
        value = if @values[i] != hqmf.SpecificsManager.any then @values[i].id else hqmf.SpecificsManager.any
        keyForGroup += "#{value}_"
    keyForGroup
    
  
  @match: (left, right, isEpisodeOfCare) ->
    return @checkEpisodeOfCare(right, isEpisodeOfCare) if left == hqmf.SpecificsManager.any
    return @checkEpisodeOfCare(left, isEpisodeOfCare) if right == hqmf.SpecificsManager.any
    return left if left.id == right.id
    return undefined

  # if we are dealing with an episode of care we don't want to match against the any (*) indicator.  This is because
  # the any indicator from a previous population indicates that we did not evaluate against that occurrence in a positive path.
  # this is typically OK with specific occurrences, but not if they represent episodes of care.
  @checkEpisodeOfCare: (value, isEpisodeOfCare) ->
    # return the any indicator to signify that the episode of care was unobserved.  This will eliminate it from the counts.
    return hqmf.SpecificsManager.any if (isEpisodeOfCare)
    return value

  @valuesEqual: (left, right) ->
    return true if !left? and !right?
    return false if !left?
    return false if !right?
    return true if left == hqmf.SpecificsManager.any and right == hqmf.SpecificsManager.any
    return true if left.id == right.id
    return false
  
  # build specific for an entry given matching rows (with temporal references)
  @buildRowsForMatching: (entryKey, entry, matchesKey, matches) ->
    rows = []
    for match in matches

      # from unions and crossproducts we may have a matches key that is a hash of object ids mapped to the specific occurrence key.
      # this is because we may have multiple different specific occurrences on the right hand side if it came from a group
      # we may also have the same event mapping to multiple occurrences, so if we have a hash the value will be an array.
      # we make both the UNION and CROSS casses look the same as the standard case by turning the standard into an array
      matchKeys = (if _.isObject(matchesKey) then matchesKey[match.id] else [matchesKey])
      if (matchKeys)
        for matchKey in matchKeys
          occurrences = {}
          occurrences[entryKey] = entry
          occurrences[matchKey] = match if matchKey? # We don't want to track RHS unless it's a specific occurrence
          rows.push(new Row(entryKey, occurrences))
      else
        # Handle case where the match is not a specific occurrence (may have specific occurrences on the RHS)
        nonSpecificLeftMostRows = _(matches.specificContext.rows).select (r) -> r.nonSpecificLeftMost?.id == match.id
        entryOccurrences = {}
        entryOccurrences[entryKey] = entry
        for nonSpecificLeftMostRow in nonSpecificLeftMostRows
          result = nonSpecificLeftMostRow.intersect(new Row(entryKey, entryOccurrences))
          rows.push(result) if result?
    rows
    
  # build specific for a given entry (there are no temporal references)
  @buildForDataCriteria: (entryKey, entries) ->
    rows = []
    for entry in entries
      occurrences={}
      occurrences[entryKey] = entry
      rows.push(new Row(entryKey, occurrences))
    rows

  flattenToIds: ->
    result = []
    for value in @values
      if (value == hqmf.SpecificsManager.any)
        result.push(value)
      else
        result.push(value.id)
    result

  toHashKey: ->
    @flattenToIds().join(",") + ",#{@specificLeftMost}" + ",#{@nonSpecificLeftMost?.id}"

  # If the row references a leftmost, either specific or not, return the event(s)
  # (because a UNION can place multiple events in the specific leftMost, this can be > 1)
  leftMostEvents: ->
    if @nonSpecificLeftMost?
      return [@nonSpecificLeftMost]
    if @specificLeftMost? && _.isString(@specificLeftMost)
      specificIndex = hqmf.SpecificsManager.getColumnIndex(@specificLeftMost)
      return [@values[specificIndex]] if @values[specificIndex]? && @values[specificIndex] != hqmf.SpecificsManager.any
    if @specificLeftMost? && _.isObject(@specificLeftMost)
      events = []
      for id, occurrences of @specificLeftMost
        for occurrence in _.uniq(occurrences)
          specificIndex = hqmf.SpecificsManager.getColumnIndex(occurrence)
          events.push(@values[specificIndex]) if @values[specificIndex]? && @values[specificIndex] != hqmf.SpecificsManager.any
      return events
    return []

@Row = Row
  
###
  Wrap methods to maintain specificContext and specific_occurrence
###

hQuery.CodedEntryList::withStatuses = _.wrap(hQuery.CodedEntryList::withStatuses, (func, statuses, includeUndefined=true) ->
  context = this.specificContext
  occurrence = this.specific_occurrence
  func = _.bind(func, this)
  result = func(statuses,includeUndefined)
  result.specificContext = context
  result.specific_occurrence = occurrence
  return result;
);

hQuery.CodedEntryList::withNegation = _.wrap(hQuery.CodedEntryList::withNegation, (func, codeSet) ->
  context = this.specificContext
  occurrence = this.specific_occurrence
  func = _.bind(func, this)
  result = func(codeSet)
  result.specificContext = context
  result.specific_occurrence = occurrence
  return result;
);

hQuery.CodedEntryList::withoutNegation = _.wrap(hQuery.CodedEntryList::withoutNegation, (func) ->
  context = this.specificContext
  occurrence = this.specific_occurrence
  func = _.bind(func, this)
  result = func()
  result.specificContext = context
  result.specific_occurrence = occurrence
  return result;
);

hQuery.CodedEntryList::concat = _.wrap(hQuery.CodedEntryList::concat, (func, otherEntries) ->
  context = this.specificContext
  occurrence = this.specific_occurrence
  func = _.bind(func, this)
  result = func(otherEntries)
  result.specificContext = context
  result.specific_occurrence = occurrence
  return result;
);

hQuery.CodedEntryList::match = _.wrap(hQuery.CodedEntryList::match, (func, codeSet, start, end, includeNegated=false) ->
  context = this.specificContext
  occurrence = this.specific_occurrence
  func = _.bind(func, this)
  result = func(codeSet, start, end, includeNegated)
  result.specificContext = context
  result.specific_occurrence = occurrence
  return result;
);

