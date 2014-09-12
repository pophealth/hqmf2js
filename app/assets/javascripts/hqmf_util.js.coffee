# Represents an HL7 timestamp
class TS
  
  # Create a new TS instance
  # hl7ts - an HL7 TS value as a string, e.g. 20121023131023 for
  # Oct 23, 2012 at 13:10:23.
  constructor: (hl7ts, @inclusive=false) ->
    if hl7ts
      year = parseInt(hl7ts.substring(0, 4))
      month = parseInt(hl7ts.substring(4, 6), 10)-1
      day = parseInt(hl7ts.substring(6, 8), 10)
      hour = parseInt(hl7ts.substring(8, 10), 10)
      if isNaN(hour)
        hour = 0
      minute = parseInt(hl7ts.substring(10,12), 10)
      if isNaN(minute)
        minute = 0
      @date = new Date(Date.UTC(year, month, day, hour, minute))
    else
      @date = new Date()
  
  # Add a time period to th and return it
  # pq - a time period as an instance of PQ. Supports units of a (year), mo (month),
  # wk (week), d (day), h (hour) and min (minute).
  add: (pq) ->
    if pq.unit=="a"
      @date.setUTCFullYear(@date.getUTCFullYear()+pq.value)
    else if pq.unit=="mo"
      @date.setUTCMonth(@date.getUTCMonth()+pq.value)
    else if pq.unit=="wk"
      @date.setUTCDate(@date.getUTCDate()+(7*pq.value))
    else if pq.unit=="d"
      @date.setUTCDate(@date.getUTCDate()+pq.value)
    else if pq.unit=="h"
      @date.setUTCHours(@date.getUTCHours()+pq.value)
    else if pq.unit=="min"
      @date.setUTCMinutes(@date.getUTCMinutes()+pq.value)
    else
      throw "Unknown time unit: "+pq.unit
    this
    
  # Returns the difference between this TS and the supplied TS as an absolute
  # number using the supplied granularity. E.g. if granularity is specified as year
  # then it will return the number of years between this TS and the supplied TS.
  # granularity - specifies the granularity of the difference. Supports units 
  # of a (year), mo (month), wk (week), d (day), h (hour) and min (minute).
  difference: (ts, granularity) ->
    earlier = later = null
    if @afterOrConcurrent(ts)
      earlier = ts.asDate()
      later = @date
    else
      earlier = @date
      later = ts.asDate()
    return Number.MAX_VALUE if !earlier? || !later?
    if granularity=="a"
      TS.yearsDifference(earlier,later)
    else if granularity=="mo"
      TS.monthsDifference(earlier,later)
    else if granularity=="wk"
      TS.weeksDifference(earlier,later)
    else if granularity=="d"
      TS.daysDifference(earlier,later)
    else if granularity=="h"
      TS.hoursDifference(earlier,later)
    else if granularity=="min"
      TS.minutesDifference(earlier,later)
    else
      throw "Unknown time unit: "+granularity
  
  # Get the value of this TS as a JS Date
  asDate: ->
    @date
    
  # Returns whether this TS is before the supplied TS ignoring seconds
  before: (other) -> 
    if @date==null || other.date==null
      return false
    if other.inclusive
      @beforeOrConcurrent(other)
    else
      [a,b] = TS.dropSeconds(@date, other.date)
      a.getTime() < b.getTime()

  # Returns whether this TS is after the supplied TS ignoring seconds
  after: (other) ->
    if @date==null || other.date==null
      return false
    if other.inclusive
      @afterOrConcurrent(other)
    else
      [a,b] = TS.dropSeconds(@date, other.date)
      a.getTime() > b.getTime()

  equals: (other) ->
    (@date==null && other.date==null) || (@date.getTime()==other.date.getTime())

  # Returns whether this TS is before or concurrent with the supplied TS ignoring seconds
  beforeOrConcurrent: (other) ->  
    if @date==null || other.date==null
      return false
    [a,b] = TS.dropSeconds(@date, other.date)
    a.getTime() <= b.getTime()

  # Returns whether this TS is after or concurrent with the supplied TS ignoring seconds
  afterOrConcurrent: (other) ->
    if @date==null || other.date==null
      return false
    [a,b] = TS.dropSeconds(@date, other.date)
    a.getTime() >= b.getTime()
    
  # Return whether this TS and the supplied TS are within the same minute (i.e.
  # same timestamp when seconds are ignored)
  withinSameMinute: (other) ->
    [a,b] = TS.dropSeconds(@date, other.date)
    a.getTime()==b.getTime()
    
  # Number of whole years between the two time stamps (as Date objects)
  @yearsDifference: (earlier, later) ->
    if (later.getUTCMonth() < earlier.getUTCMonth())
      later.getUTCFullYear()-earlier.getUTCFullYear()-1
    else if (later.getUTCMonth() == earlier.getUTCMonth() && later.getUTCDate() >= earlier.getUTCDate())
      later.getUTCFullYear()-earlier.getUTCFullYear()
    else if (later.getUTCMonth() == earlier.getUTCMonth() && later.getUTCDate() < earlier.getUTCDate())
      later.getUTCFullYear()-earlier.getUTCFullYear()-1
    else
      later.getUTCFullYear()-earlier.getUTCFullYear()
      
  # Number of whole months between the two time stamps (as Date objects)
  @monthsDifference: (earlier, later) ->
    if (later.getUTCDate() >= earlier.getUTCDate())
      (later.getUTCFullYear()-earlier.getUTCFullYear())*12+later.getUTCMonth()-earlier.getUTCMonth()
    else
      (later.getUTCFullYear()-earlier.getUTCFullYear())*12+later.getUTCMonth()-earlier.getUTCMonth()-1
      
  # Number of whole minutes between the two time stamps (as Date objects)
  @minutesDifference: (earlier, later) ->
    [e,l] = TS.dropSeconds(earlier,later)
    Math.floor(((l.getTime()-e.getTime())/1000)/60)
    
  # Number of whole hours between the two time stamps (as Date objects)
  @hoursDifference: (earlier, later) ->
    Math.floor(TS.minutesDifference(earlier,later)/60)
  
  # Number of days betweem the two time stamps (as Date objects)
  @daysDifference: (earlier, later) ->
    # have to discard time portion for day difference calculation purposes
    e = new Date(Date.UTC(earlier.getUTCFullYear(), earlier.getUTCMonth(), earlier.getUTCDate()))
    l = new Date(Date.UTC(later.getUTCFullYear(), later.getUTCMonth(), later.getUTCDate()))
    Math.floor(TS.hoursDifference(e,l)/24)
    
  # Number of whole weeks between the two time stmaps (as Date objects)
  @weeksDifference: (earlier, later) ->
    Math.floor(TS.daysDifference(earlier,later)/7)
    
  # Drop the seconds from the supplied timeStamps (as Date objects)
  # returns the new time stamps with seconds set to 0 as an array
  @dropSeconds: (timeStamps...) ->
    timeStampsNoSeconds = for timeStamp in timeStamps
      noSeconds = new Date(timeStamp.getTime())
      noSeconds.setSeconds(0)
      noSeconds
    timeStampsNoSeconds
@TS = TS

# Utility function used to extract data from a supplied object, hash or simple value
# First looks for an accessor function, then an object property or hash key. If
# defaultToValue is specified it will return the supplied value if neither an accessor
# or hash entry exists, if false it will return null.
fieldOrContainerValue = (value, fieldName, defaultToValue=true) ->
  if value?
    if typeof value[fieldName] == 'function'
      value[fieldName]()
    else if typeof value[fieldName] != 'undefined'
      value[fieldName]
    else if defaultToValue
      value
    else
      null
  else
    null
@fieldOrContainerValue = fieldOrContainerValue

# Represents an HL7 CD value
class CD
  constructor: (@code, @system) ->
  
  # Returns whether the supplied code matches this one.
  match: (codeOrHash) ->
    # We might be passed a simple code value like "M" or a CodedEntry
    # Do our best to get a code value but only get a code system name if one is
    # supplied
    codeToMatch = fieldOrContainerValue(codeOrHash, 'code')
    systemToMatch = fieldOrContainerValue(codeOrHash, 'codeSystemName', false)
    c1 = hQuery.CodedValue.normalize(codeToMatch)
    c2 = hQuery.CodedValue.normalize(@code)
    if @system && systemToMatch
      c1==c2 && @system==systemToMatch
    else
      c1==c2
@CD = CD
    
# Represents a list of codes 
class CodeList
  constructor: (@codes) ->
  
  # Returns whether the supplied code matches any of the contained codes
  match: (codeOrHash) ->
    # We might be passed a simple code value like "M" or a CodedEntry
    # Do our best to get a code value but only get a code system name if one is
    # supplied
    codeToMatch = fieldOrContainerValue(codeOrHash, 'code')
    c1 = hQuery.CodedValue.normalize(codeToMatch)
    systemToMatch = fieldOrContainerValue(codeOrHash, 'codeSystemName', false)
    result = false
    for codeSystemName, codeList of @codes
      for code in codeList
        c2 = hQuery.CodedValue.normalize(code)
        if codeSystemName && systemToMatch # check that code systems match if both specified
          if c1==c2 && codeSystemName==systemToMatch
            result = true
        else if c1==c2 # no code systems to match to just match codes
          result = true
    result
@CodeList = CodeList
    
# Represents and HL7 physical quantity
class PQ
  constructor: (@value, @unit, @inclusive=true) ->
  
  # Helper method to make a PQ behave like a patient API value
  scalar: -> @value
  
  # Returns whether this is less than the supplied value
  lessThan: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    if @inclusive
      @lessThanOrEqual(val)
    else
      @value<val

  # Returns whether this is greater than the supplied value
  greaterThan: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    if @inclusive
      @greaterThanOrEqual(val)
    else
      @value>val

  # Returns whether this is less than or equal to the supplied value
  lessThanOrEqual: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    @value<=val

  # Returns whether this is greater than or equal to the supplied value
  greaterThanOrEqual: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    @value>=val
    
  # Returns whether this is equal to the supplied value or hash
  match: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    @value==val
@PQ = PQ
  
# Represents an HL7 interval
class IVL_PQ
  # Create a new instance, must supply either a lower or upper bound and if both
  # are supplied the units must match.
  constructor: (@low_pq, @high_pq) ->
    if !@low_pq && !@high_pq
      throw "Must have a lower or upper bound"
    if @low_pq && @low_pq.unit && @high_pq && @high_pq.unit && @low_pq.unit != @high_pq.unit
      throw "Mismatched low and high units: "+@low_pq.unit+", "+@high_pq.unit
  unit: ->
    if @low_pq
      @low_pq.unit
    else
      @high_pq.unit
      
  # Return whether the supplied scalar or patient API hash value is within this range
  match: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    (!@low_pq? || @low_pq.lessThan(val)) && (!@high_pq? || @high_pq.greaterThan(val))
@IVL_PQ = IVL_PQ
    
# Represents an HL7 time interval
class IVL_TS
  constructor: (@low, @high) ->
  
  # add an offset to the upper and lower bounds
  add: (pq) ->
    if @low
      @low.add(pq)
    if @high
      @high.add(pq)
    this
  
  # During: this low is after other low and this high is before other high
  DURING: (other) -> this.SDU(other) && this.EDU(other)
  
  # Overlap: this overlaps with other
  OVERLAP: (other) ->
    if @high.date == null && other.high.date == null
      true # If neither have ends, they inherently overlap on the timeline
    else if @high.date == null
      !this.SAE(other)
    else if other.high.date == null
      !this.EBS(other)
    else
      this.SDU(other) || this.EDU(other) || (this.SBS(other) && this.EAE(other))
  
  # Concurrent: this low and high are the same as other low and high
  CONCURRENT: (other) -> this.SCW(other) && this.ECW(other)
  
  # Starts Before Start: this low is before other low
  SBS: (other) -> 
    if @low && other.low
      @low.before(other.low)
    else
      false
      
  # Starts After Start: this low is after other low
  SAS: (other) -> 
    if @low && other.low
      @low.after(other.low)
    else
      false
      
  # Starts Before End: this low is before other high
  SBE: (other) ->
    if @low && other.high
      @low.before(other.high)
    else
      false
      
  # Starts After End: this low is after other high
  SAE: (other) -> 
    if @low && other.high
      @low.after(other.high)
    else
      false

  # Starts During: this low is between other low and high
  SDU: (other) -> 
    if @low && other.low && other.high
      @low.afterOrConcurrent(other.low) && @low.beforeOrConcurrent(other.high)
    else
      false

  #starts before or during: this low is less than the other low or the other high. 
  #if other does not have a high or does not have a low this will return false
  SBDU: (other) ->
     this.SBS(other) ||  this.SDU(other)

  # Starts Concurrent With: this low is the same as other low ignoring seconds
  SCW: (other) -> 
    if @low && other.low
      @low.asDate() && other.low.asDate() && @low.withinSameMinute(other.low)
    else
      false

   # Starts Concurrent With End: this low is the same as other high ignoring seconds
  SCWE: (other) -> 
    if @low && other.high
      @low.asDate() && other.high.asDate() && @low.withinSameMinute(other.high)
    else
      false

    #Starts Before or Concurrent with: this low is <= other low
  SBCW: (other) ->
     this.SBS(other) ||  this.SCW(other)  

  SBCWE: (other) -> 
     this.SBE(other) ||  this.SCWE(other)
  # Starts After or Concurrent with other: this low is >= other low
  SACW: (other) ->
     this.SAS(other) ||  this.SCW(other)

  # Starts After or Concurrent with End : This low is >= other high
  SACWE: (other) ->
     this.SAE(other) ||  this.SCWE(other)   


  # Ends Before Start: this high is before other low
  EBS: (other) ->
    if @high && other.low
      @high.before(other.low)
    else
      false

  # Ends After Start: this high is after other low
  EAS: (other) -> 
    if @high && other.low
      @high.after(other.low)
    else
      false
      
  # Ends Before End: this high is before other high
  EBE: (other) -> 
    if @high && other.high
      @high.before(other.high)
    else
      false
      
  # Ends After End: this high is after other high
  EAE: (other) ->
    if @high && other.high
      @high.after(other.high)
    else
      false

  # Ends During: this high is between other low and high
  EDU: (other) -> 
    if @high && other.low && other.high
      @high.afterOrConcurrent(other.low) && @high.beforeOrConcurrent(other.high)
    else
      false
      
  # Ends Concurrent With: this high is the same as other high ignoring seconds
  ECW: (other) -> 
    if @high && other.high
      @high.asDate() && other.high.asDate() && @high.withinSameMinute(other.high)
    else
      false
      
  # Ends Concurrent With Start: this high is the same as other low ignoring seconds
  ECWS: (other) ->
    if @high && other.low
      @high.asDate() && other.low.asDate() && @high.withinSameMinute(other.low)
    else
      false

  EBDU: (other) ->
     this.EBS(other) ||  this.EDU(other)

  EBCW: (other) ->
     this.EBE(other) ||  this.ECW(other)

  EACW: (other) ->
     this.EAE(other) ||  this.ECW(other)  

  EBCWS: (other) ->
     this.EBS(other) ||  this.ECWS(other)

  EACWS: (other) ->  
     this.EAS(other) ||  this.ECWS(other)

  equals: (other) ->
    (@low==null && other.low==null) || (@low.equals(other.low)) && (@high==null && other.high==null) || (@high.equals(other.high))

@IVL_TS = IVL_TS

# Used to represent a value that will match any other value that is not null.
class ANYNonNull
  constructor: ->
  match: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    val != null
@ANYNonNull = ANYNonNull

invokeOne = (patient, initialSpecificContext, fn) ->
  if typeof(fn.isTrue)=='function' || typeof(fn)=='boolean'
    fn
  else
    fn(patient, initialSpecificContext)
@invokeOne = invokeOne

evalUnlessShortCircuit = (fn) ->
  # if we are short circuiting then return the function uncalled, if we are not then call the function and
  # evaluate the tree.  If uncalled, from here the function will only be called if required
  if (Logger.short_circuit) then fn else fn()
@evalUnlessShortCircuit = evalUnlessShortCircuit

invokeAll = (patient, initialSpecificContext, fns) ->
  (invokeOne(patient, initialSpecificContext, fn) for fn in fns)
@invokeAll = invokeAll
  
# Returns true if one or more of the supplied values is true
atLeastOneTrue = (precondition, patient, initialSpecificContext, valueFns...) ->
  evalUnlessShortCircuit ->
    values = invokeAll(patient, initialSpecificContext, valueFns)
    trueValues = (value for value in values when value && value.isTrue())
    hqmf.SpecificsManager.unionAll(new Boolean(trueValues.length>0), values)
@atLeastOneTrue = atLeastOneTrue

# Returns true if all of the supplied values are true
allTrue = (precondition, patient, initialSpecificContext, valueFns...) ->
  evalUnlessShortCircuit ->
    values = []
    for valueFn in valueFns
      value = invokeOne(patient, initialSpecificContext, valueFn)
      # break if the we have a false value and we're short circuiting.  
      #If we're not short circuiting then we want to calculate everything
      break if value.isFalse() && Logger.short_circuit
      values.push(value)
    trueValues = (value for value in values when value && value.isTrue())
    if trueValues.length==valueFns.length
      hqmf.SpecificsManager.intersectAll(new Boolean(trueValues.length>0), trueValues)
    else
      # only intersect on false if we are not short circuiting.
      # if we are not short circuiting then we want to have the specifics context returned for rationale
      if Logger.short_circuit
        value = new Boolean(false)
        value.specificContext = hqmf.SpecificsManager.empty()
        value
      else
        hqmf.SpecificsManager.intersectAll(new Boolean(false), values)


@allTrue = allTrue
  
# Returns true if one or more of the supplied values is false
atLeastOneFalse = (precondition, patient, initialSpecificContext, valueFns...) ->
#   values = invokeAll(patient, initialSpecificContext, valueFns)
#   falseValues = (value for value in values when value.isFalse())
#   hqmf.SpecificsManager.intersectAll(new Boolean(falseValues.length>0), values, true)
  evalUnlessShortCircuit ->
    values = []
    hasFalse = false
    for valueFn in valueFns
      value = invokeOne(patient, initialSpecificContext, valueFn)
      values.push(value)
      if value.isFalse()
        hasFalse = true
        break if Logger.short_circuit
    hqmf.SpecificsManager.intersectAll(new Boolean(values.length>0 && hasFalse), values, true)
@atLeastOneFalse = atLeastOneFalse
  
# Returns true if all of the supplied values are false
allFalse = (precondition, patient, initialSpecificContext, valueFns...) ->
  evalUnlessShortCircuit ->
    values = invokeAll(patient, initialSpecificContext, valueFns)
    falseValues = (value for value in values when value.isFalse())
    hqmf.SpecificsManager.unionAll(new Boolean(falseValues.length>0 && falseValues.length==values.length), values, true)
@allFalse = allFalse
  
# Return true if compareTo matches value
matchingValue = (value, compareTo) ->
  new Boolean(compareTo.match(value))
@matchingValue = matchingValue

# Return true if valueToMatch matches any event value
anyMatchingValue = (event, valueToMatch) ->
  matchingValues = (value for value in event.values() when (valueToMatch.match(value)))
  matchingValues.length > 0
@anyMatchingValue = anyMatchingValue

# Return only those events whose value matches the supplied value
filterEventsByValue = (events, value) ->
  matchingEvents = (event for event in events when (anyMatchingValue(event, value)))
  hqmf.SpecificsManager.maintainSpecifics(matchingEvents, events)
@filterEventsByValue = filterEventsByValue

# Return only those events with a field that matches the supplied value
filterEventsByField = (events, field, value) ->
  respondingEvents = (event for event in events when event.respondTo(field))
  unit = value.unit() if value.unit?
  result = (event for event in respondingEvents when value.match(event[field](unit)))
  hqmf.SpecificsManager.maintainSpecifics(result, events)
@filterEventsByField = filterEventsByField

shiftTimes = (event, field) ->
  shiftedEvent = new event.constructor(event.json)
  shiftedEvent.setTimestamp(shiftedEvent[field]())
  shiftedEvent
@shiftTimes = shiftTimes

adjustBoundsForField = (events, field) ->
  validEvents = (event for event in events when (event.respondTo(field) and event[field]()))
  shiftedEvents = (shiftTimes(event, field) for event in validEvents)
  hqmf.SpecificsManager.maintainSpecifics(shiftedEvents, events)
@adjustBoundsForField = adjustBoundsForField

# Clone the supplied event and replace any facilities with just the supplied one
narrowEventForFacility = (event, facility) ->
  narrowed = new event.constructor(event.json)
  # uncomment the following line when patient API is modified to support multiple
  # facilities
  # narrowed._facilities = [facility]
  narrowed
@narrowEventForFacility = narrowEventForFacility

# Return a cloned set of events, each with just one of the original facilities
denormalizeEvent = (event) ->
  # the following line should be changed when the patient API is modified to support
  # more than one facility per encounter
  # narrowed = (narrowEventForFacility(event, facility) for facility in event.facilities)
  narrowed = (narrowEventForFacility(event, facility) for facility in [event.facility])
@denormalizeEvent = denormalizeEvent

# Creates a new set of events with one location per event. Input events with more than
# one location will be duplicated once per location and each resulting event will
# be assigned one location. Start and end times of the event will be adjusted to match the
# value of the supplied field
denormalizeEventsByLocation = (events, field) ->
  respondingEvents = (event for event in events when event.respondTo("facility") and event.facility())
  denormalizedEvents = (denormalizeEvent(event) for event in respondingEvents)
  denormalizedEvents = [].concat denormalizedEvents...
  result = adjustBoundsForField(denormalizedEvents, field)
  hqmf.SpecificsManager.maintainSpecifics(result, events)
@denormalizeEventsByLocation = denormalizeEventsByLocation

# Utility method to obtain the value set for an OID
getCodes = (oid) ->
  codes = OidDictionary[oid]
  throw "value set oid could not be found: #{oid}" unless codes?
  codes
@getCodes = getCodes

# Used for representing XPRODUCTs of arrays, holds both a flattened array that contains
# all the elements of the compoent arrays and the component arrays themselves
class CrossProduct extends Array
  constructor: (allEventLists) ->
    super()
    @eventLists = []
    # keep track of the specific occurrences by encounter ID.  This is used in eventsMatchBounds (specifically in buildRowsForMatching down the _.isObject path)
    @specific_occurrence = {}
    for eventList in allEventLists
      @eventLists.push eventList
      for event in eventList
        this.push(event)
        @specific_occurrence[event.id] = eventList.specific_occurrence if eventList.specific_occurrence
  listCount: -> @eventLists.length
  childList: (index) -> @eventLists[index]
  intersect: ->
    result = @childList(0) || []
    for index in [1...@listCount()] by 1
      currentIds = @childList(index).map((event) -> event.id)
      result = result.filter((event) -> currentIds.indexOf(event.id) >= 0)
    result

# Create a CrossProduct of the supplied event lists.
XPRODUCT = (eventLists...) ->
  hqmf.SpecificsManager.intersectAll(new CrossProduct(eventLists), eventLists)
@XPRODUCT = XPRODUCT

# Create a new list containing all the events from the supplied event lists
UNION = (eventLists...) ->
  union = []
  # keep track of the specific occurrences by encounter ID.  This is used in 
  # eventsMatchBounds (specifically in buildRowsForMatching down the _.isObject path)
  specific_occurrence = {}
  for eventList in eventLists
    for event in eventList
      if eventList.specific_occurrence
        specific_occurrence[event.id] ||= []
        specific_occurrence[event.id].push eventList.specific_occurrence 
      union.push(event)
  union.specific_occurrence = specific_occurrence unless _.isEmpty(specific_occurrence)
  hqmf.SpecificsManager.unionAll(union, eventLists)
@UNION = UNION

# Create a CrossProduct of the supplied event lists.
INTERSECT = (eventLists...) ->
  hqmf.SpecificsManager.intersectAll((new CrossProduct(eventLists)).intersect(), eventLists)
@INTERSECT = INTERSECT

# Return true if the number of events matches the supplied range
COUNT = (events, range) ->
  count = events.length
  result = new Boolean(range.match(count))
  applySpecificOccurrenceSubset('COUNT', hqmf.SpecificsManager.maintainSpecifics(result, events), range)
@COUNT = COUNT

# Convert an hQuery.CodedEntry or JS Date into an IVL_TS
getIVL = (eventOrTimeStamp) ->
  if eventOrTimeStamp.asIVL_TS
    eventOrTimeStamp.asIVL_TS()
  else
    ts = new TS()
    ts.date = eventOrTimeStamp
    new IVL_TS(ts, ts)
@getIVL = getIVL

eventAccessor = {  
  'DURING': 'low',
  'OVERLAP': 'low',
  'SBS': 'low',
  'SAS': 'low',
  'SBE': 'low',
  'SAE': 'low',
  'EBS': 'high',
  'EAS': 'high',
  'EBE': 'high',
  'EAE': 'high',
  'SDU': 'low',
  'EDU': 'high',
  'ECW': 'high'
  'SCW': 'low',
  'ECWS': 'high'
  'SCWE': 'low',
  'SBCW': 'low',
  'SBCWE': 'low',
  'SACW': 'low',
  'SACWE': 'low',
  'SBDU': 'low',
  'EBCW': 'high',
  'EBCWS': 'high',
  'EACW': 'high',
  'EACWS': 'high',
  'EADU': 'high',
  'CONCURRENT': 'low',
  'DATEDIFF': 'low'
}

boundAccessor = {  
  'DURING': 'low',
  'OVERLAP': 'low',
  'SBS': 'low',
  'SAS': 'low',
  'SBE': 'high',
  'SAE': 'high',
  'EBS': 'low',
  'EAS': 'low',
  'EBE': 'high',
  'EAE': 'high',
  'SDU': 'low',
  'EDU': 'low',
  'ECW': 'high'
  'SCW': 'low',
  'ECWS': 'low'
  'SCWE': 'high',
  'SBCW': 'low',
  'SBCWE': 'high',
  'SACW': 'low',
  'SACWE': 'high',
  'SBDU': 'high',
  'EBCW': 'high',
  'EBCWS': 'low',
  'EACW': 'high',
  'EACWS': 'low',
  'EADU': 'low',
  'CONCURRENT': 'low',
  'DATEDIFF': 'low'
}
    
# Determine whether the supplied event falls within range of the supplied bound
# using the method to determine which property of the event and bound to use in
# the comparison. E.g. if method is SBS then check whether the start of the event
# is within range of the start of the bound.
withinRange = (method, eventIVL, boundIVL, range) ->
  eventTS = eventIVL[eventAccessor[method]]
  boundTS = boundIVL[boundAccessor[method]]
  range.match(eventTS.difference(boundTS, range.unit()))
@withinRange = withinRange
    
# Determine which bounds an event matches
eventMatchesBounds = (event, bounds, methodName, range) ->
  if bounds.eventLists
    # XPRODUCT set of bounds - event must match at least one bound in all members
    matchingBounds = []
    for boundList in bounds.eventLists
      currentMatches = eventMatchesBounds(event, boundList, methodName, range)
      return [] if (currentMatches.length == 0)
      matchingBounds = matchingBounds.concat(currentMatches)
    return hqmf.SpecificsManager.maintainSpecifics(matchingBounds,bounds)
  else
    eventIVL = getIVL(event)
    matchingBounds = (bound for bound in bounds when (
      boundIVL = getIVL(bound)
      result = eventIVL[methodName](boundIVL)
      if result && range
        result &&= withinRange(methodName, eventIVL, boundIVL, range)
      result
    ))
    hqmf.SpecificsManager.maintainSpecifics(matchingBounds, bounds)
@eventMatchesBounds = eventMatchesBounds
  
# Determine which event match one of the supplied bounds
eventsMatchBounds = (events, bounds, methodName, range) ->
  if (bounds.length==undefined)
    bounds = [bounds]
  if (events.length==undefined)
    events = [events]
  
  specificContext = new hqmf.SpecificOccurrence()
  hasSpecificOccurrence = (events.specific_occurrence? || bounds.specific_occurrence?)
  matchingEvents = []
  matchingEvents.specific_occurrence = events.specific_occurrence
  for event in events
    continue unless event
    matchingBounds=eventMatchesBounds(event, bounds, methodName, range)
    matchingEvents.push(event) if matchingBounds.length > 0

    if hasSpecificOccurrence
      matchingEvents.specific_occurrence = events.specific_occurrence
      # we use a temporary variable for non specific occurrences on the left so that we can do rejections based on restrictions in the data criteria
      specificContext.addRows(Row.buildRowsForMatching(events.specific_occurrence, event, bounds.specific_occurrence, matchingBounds))
    else
      # add all stars
      specificContext.addIdentityRow()
  
  matchingEvents.specificContext = specificContext.finalizeEvents(events.specificContext, bounds.specificContext)
  
  matchingEvents
@eventsMatchBounds = eventsMatchBounds
  
DURING = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "DURING", offset)
@DURING = DURING

OVERLAP = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "OVERLAP", offset)
@OVERLAP = OVERLAP

SBS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SBS", offset)
@SBS = SBS

SAS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SAS", offset)
@SAS = SAS

SBE = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SBE", offset)
@SBE = SBE

SAE = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SAE", offset)
@SAE = SAE

EBS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EBS", offset)
@EBS = EBS

EAS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EAS", offset)
@EAS = EAS

EBE = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EBE", offset)
@EBE = EBE

EAE = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EAE", offset)
@EAE = EAE

SDU = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SDU", offset)
@SDU = SDU

EDU = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EDU", offset)
@EDU = EDU

ECW = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "ECW", offset)
@ECW = ECW
  
SCW = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SCW", offset)
@SCW = SCW

ECWS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "ECWS", offset)
@ECWS = ECWS
  
SCWE = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SCWE", offset)
@SCWE = SCWE

EBDU = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EBDU", offset)
@EBDU = EBDU

EBCW = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EBCW", offset)
@EBCW = EBCW
EACW = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EACW", offset)
@EACW =EACW

EBCWS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EBCWS", offset)
@EBCWS = EBCWS

EACWS = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "EACWS", offset)
@EACWS = EACWS

SBDU= (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SBDU", offset)
@SBDU = SBDU

SBCW= (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SBCW", offset)
@SBCW = SBCW

SBCWE= (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SBCWE", offset)
@SBCWE = SBCWE

SACW= (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SACW", offset)
@SACW = SACW

SACWE= (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "SACWE", offset)
@SACWE = SACWE

CONCURRENT = (events, bounds, offset) ->
  eventsMatchBounds(events, bounds, "CONCURRENT", offset)
@CONCURRENT = CONCURRENT

dateSortDescending = (a, b) ->
  b.timeStamp().getTime() - a.timeStamp().getTime()
@dateSortDescending= dateSortDescending

dateSortAscending = (a, b) ->
  a.timeStamp().getTime() - b.timeStamp().getTime()
@dateSortAscending = dateSortAscending

applySpecificOccurrenceSubset = (operator, result, range, calculateSpecifics) ->
  # the subset operators are re-used in the specifics calculation of those operators.  Checking for a specificContext
  # prevents entering into an infinite loop here.
  if (result.specificContext?)
    if (range?)
      result.specificContext = result.specificContext[operator](range)
    else
      result.specificContext = result.specificContext[operator]()
  result

uniqueEvents = (events) ->
  hash = {}
  (hash[event.id] = event for event in events)
  _.values(hash)
@uniqueEvents = uniqueEvents

# if we have multiple events at the same exact time and they happen to be the one selected by FIRST, RECENT, etc
# then we want to select all of these issues as the first, most recent, etc.
selectConcurrent = (target, events) ->
  targetIVL = target.asIVL_TS()
  uniqueEvents((result for result in events when result.asIVL_TS().equals(targetIVL)))
@selectConcurrent = selectConcurrent

FIRST = (events) ->
  result = []
  result = selectConcurrent(events.sort(dateSortAscending)[0], events) if (events.length > 0)
  applySpecificOccurrenceSubset('FIRST',hqmf.SpecificsManager.maintainSpecifics(result, events))
@FIRST = FIRST

SECOND = (events) ->
  result = []
  result = selectConcurrent(events.sort(dateSortAscending)[1], events) if (events.length > 1)
  applySpecificOccurrenceSubset('SECOND',hqmf.SpecificsManager.maintainSpecifics(result, events))
@SECOND = SECOND

THIRD = (events) ->
  result = []
  result = selectConcurrent(events.sort(dateSortAscending)[2], events) if (events.length > 2)
  applySpecificOccurrenceSubset('THIRD',hqmf.SpecificsManager.maintainSpecifics(result, events))
@THIRD = THIRD

FOURTH = (events) ->
  result = []
  result = selectConcurrent(events.sort(dateSortAscending)[3], events) if (events.length > 3)
  applySpecificOccurrenceSubset('FOURTH',hqmf.SpecificsManager.maintainSpecifics(result, events))
@FOURTH = FOURTH

FIFTH = (events) ->
  result = []
  result = selectConcurrent(events.sort(dateSortAscending)[4], events) if (events.length > 4)
  applySpecificOccurrenceSubset('FIFTH',hqmf.SpecificsManager.maintainSpecifics(result, events))
@FIFTH = FIFTH

RECENT = (events) ->
  result = []
  result = selectConcurrent(events.sort(dateSortDescending)[0], events) if (events.length > 0)
  applySpecificOccurrenceSubset('RECENT',hqmf.SpecificsManager.maintainSpecifics(result, events))
@RECENT = RECENT
  
LAST = (events) ->
  RECENT(events)
@LAST = LAST
  
valueSortDescending = (a, b) ->
  va = vb = Infinity
  if a.value
    va = a.value()["scalar"]
  if b.value 
    vb = b.value()["scalar"]
  if va==vb
    0
  else
    vb - va
@valueSortDescending = valueSortDescending

valueSortAscending = (a, b) ->
  va = vb = Infinity
  if a.value
    va = a.value()["scalar"]
  if b.value 
    vb = b.value()["scalar"]
  if va==vb
    0
  else
    va - vb
@valueSortAscending = valueSortAscending

MIN = (events, range) ->
  minValue = Infinity
  if (events.length > 0)
    minValue = events.sort(valueSortAscending)[0].value()["scalar"]
  result = new Boolean(range.match(minValue))
  applySpecificOccurrenceSubset('MIN',hqmf.SpecificsManager.maintainSpecifics(result, events), range)
@MIN = MIN

MAX = (events, range) ->
  maxValue = -Infinity
  if (events.length > 0)
    maxValue = events.sort(valueSortDescending)[0].value()["scalar"]
  result = new Boolean(range.match(maxValue))
  applySpecificOccurrenceSubset('MAX',hqmf.SpecificsManager.maintainSpecifics(result, events), range)
@MAX = MAX

DATEDIFF = (events, range) ->
  return hqmf.SpecificsManager.maintainSpecifics(new Boolean(false), events) if events.length < 2
  events = events.sort(dateSortAscending)
  # events are now sorted, DATEDIFF is between first and last event
  # throw "cannot calculate against more than 2 events" if events.length > 2
  hqmf.SpecificsManager.maintainSpecifics(new Boolean(withinRange('DATEDIFF', getIVL(events[0]), getIVL(events[events.length - 1]), range)), events)
@DATEDIFF = DATEDIFF

# Calculate the set of time differences in minutes between pairs of events
# events - a XPRODUCT of two event lists
# range - ignored
# initialSpecificContext - the specific context containing one row per permissible
# combination of events
TIMEDIFF = (events, range, initialSpecificContext) ->
  if events.listCount() != 2
    throw "TIMEDIFF can only process 2 lists of events"
  eventList1 = events.childList(0)
  eventList2 = events.childList(1)
  eventIndex1 = hqmf.SpecificsManager.getColumnIndex(eventList1.specific_occurrence) if eventList1.specific_occurrence
  eventIndex2 = hqmf.SpecificsManager.getColumnIndex(eventList2.specific_occurrence) if eventList2.specific_occurrence
  if (eventIndex1? && eventIndex2?)
    eventMap1 = {}
    eventMap2 = {}
    for event in eventList1
      eventMap1[event.id] = event
    for event in eventList2
      eventMap2[event.id] = event
    results = []
    for row in initialSpecificContext.rows
      event1 = row.values[eventIndex1]
      event2 = row.values[eventIndex2]
      if event1 and event2 and event1 != hqmf.SpecificsManager.any and event2 != hqmf.SpecificsManager.any 
        # The maps contain the actual events we want to work with since these may contain
        # time shifted clones of the events in the specificContext, e.g. via adjustBoundsForField
        shiftedEvent1 = eventMap1[event1.id]
        shiftedEvent2 = eventMap2[event2.id]
        if shiftedEvent1 and shiftedEvent2
          results.push(shiftedEvent1.asTS().difference(shiftedEvent2.asTS(), 'min'))
  else
    if (eventList1.length > 0 && eventList2.length > 0)
      event1 = eventList1.sort(dateSortAscending)[0]
      event2 = eventList2.sort(dateSortAscending)[eventList2.length - 1]
      results = [event1.asTS().difference(event2.asTS(), 'min')]
  results
@TIMEDIFF = TIMEDIFF

DATETIMEDIFF = (events, range, initialSpecificContext) ->
  if range
    DATEDIFF(events, range)
  else
    TIMEDIFF(events, range, initialSpecificContext)
@DATETIMEDIFF = DATETIMEDIFF

@OidDictionary = {};

hqmfjs = hqmfjs||{}
@hqmfjs = @hqmfjs||{};
