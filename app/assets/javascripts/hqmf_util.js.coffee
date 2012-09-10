class TS
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
      @date = new Date(year, month, day, hour, minute)
    else
      @date = new Date()
  add: (pq) ->
    if pq.unit=="a"
      @date.setFullYear(@date.getFullYear()+pq.value)
    else if pq.unit=="mo"
      @date.setMonth(@date.getMonth()+pq.value)
    else if pq.unit=="wk"
      @date.setDate(@date.getDate()+(7*pq.value))
    else if pq.unit=="d"
      @date.setDate(@date.getDate()+pq.value)
    else if pq.unit=="h"
      @date.setHours(@date.getHours()+pq.value)
    else if pq.unit=="min"
      @date.setMinutes(@date.getMinutes()+pq.value)
    else
      throw "Unknown time unit: "+pq.unit
    this
  difference: (ts, granularity) ->
    earlier = later = null
    if @afterOrConcurrent(ts)
      earlier = ts.asDate()
      later = @date
    else
      earlier = @date
      later = ts.asDate()
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
  asDate: ->
    @date
  before: (other) -> 
    if @date==null || other.date==null
      return false
    if other.inclusive
      beforeOrConcurrent(other)
    else
      [a,b] = TS.dropSeconds(@date, other.date)
      a.getTime() < b.getTime()
  after: (other) ->
    if @date==null || other.date==null
      return false
    if other.inclusive
      afterOrConcurrent(other)
    else
      [a,b] = TS.dropSeconds(@date, other.date)
      a.getTime() > b.getTime()
  beforeOrConcurrent: (other) ->  
    if @date==null || other.date==null
      return false
    [a,b] = TS.dropSeconds(@date, other.date)
    a.getTime() <= b.getTime()
  afterOrConcurrent: (other) ->
    if @date==null || other.date==null
      return false
    [a,b] = TS.dropSeconds(@date, other.date)
    a.getTime() >= b.getTime()
  withinSameMinute: (other) ->
    [a,b] = TS.dropSeconds(@date, other.date)
    a.getTime()==b.getTime()
    
  # Number of whole years between the two time stamps (as Date objects)
  @yearsDifference: (earlier, later) ->
    if (later.getMonth() < earlier.getMonth())
      later.getFullYear()-earlier.getFullYear()-1
    else if (later.getMonth() == earlier.getMonth() && later.getDate() >= earlier.getDate())
      later.getFullYear()-earlier.getFullYear()
    else if (later.getMonth() == earlier.getMonth() && later.getDate() < earlier.getDate())
      later.getFullYear()-earlier.getFullYear()-1
    else
      later.getFullYear()-earlier.getFullYear()
      
  # Number of whole months between the two time stamps (as Date objects)
  @monthsDifference: (earlier, later) ->
    if (later.getDate() >= earlier.getDate())
      (later.getFullYear()-earlier.getFullYear())*12+later.getMonth()-earlier.getMonth()
    else
      (later.getFullYear()-earlier.getFullYear())*12+later.getMonth()-earlier.getMonth()-1
      
  # Number of whole minutes between the two time stamps (as Date objects)
  @minutesDifference: (earlier, later) ->
    Math.floor(((later.getTime()-earlier.getTime())/1000)/60)
    
  # Number of whole hours between the two time stamps (as Date objects)
  @hoursDifference: (earlier, later) ->
    Math.floor(TS.minutesDifference(earlier,later)/60)
  
  # Number of days betweem the two time stamps (as Date objects)
  @daysDifference: (earlier, later) ->
    # have to discard time portion for day difference calculation purposes
    e = new Date(earlier.getFullYear(), earlier.getMonth(), earlier.getDate())
    e.setUTCHours(0)
    l = new Date(later.getFullYear(), later.getMonth(), later.getDate())
    l.setUTCHours(0)
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

class CD
  constructor: (@code, @system) ->
  match: (codeOrHash) ->
    # We might be passed a simple code value like "M" or a CodedEntry
    # Do our best to get a code value but only get a code system name if one is
    # supplied
    codeToMatch = fieldOrContainerValue(codeOrHash, 'code')
    systemToMatch = fieldOrContainerValue(codeOrHash, 'codeSystemName', false)
    if @system && systemToMatch
      @code==codeToMatch && @system==systemToMatch
    else
      @code==codeToMatch
@CD = CD
    
class CodeList
  constructor: (@codes) ->
  match: (codeOrHash) ->
    # We might be passed a simple code value like "M" or a CodedEntry
    # Do our best to get a code value but only get a code system name if one is
    # supplied
    codeToMatch = fieldOrContainerValue(codeOrHash, 'code')
    systemToMatch = fieldOrContainerValue(codeOrHash, 'codeSystemName', false)
    result = false
    for codeSystemName, codeList of @codes
      for code in codeList
        if codeSystemName && systemToMatch # check that code systems match if both specified
          if code==codeToMatch && codeSystemName==systemToMatch
            result = true
        else if code==codeToMatch # no code systems to match to just match codes
          result = true
    result
@CodeList = CodeList
    
class PQ
  constructor: (@value, @unit, @inclusive=true) ->
  lessThan: (val) ->
    if @inclusive
      @lessThanOrEqual(val)
    else
      @value<val
  greaterThan: (val) ->
    if @inclusive
      @greaterThanOrEqual(val)
    else
      @value>val
  lessThanOrEqual: (val) ->
    @value<=val
  greaterThanOrEqual: (val) ->
    @value>=val
  match: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    @value==val
@PQ = PQ
  
class IVL_PQ
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
  match: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    (!@low_pq? || @low_pq.lessThan(val)) && (!@high_pq? || @high_pq.greaterThan(val))
@IVL_PQ = IVL_PQ
    
class IVL_TS
  constructor: (@low, @high) ->
  add: (pq) ->
    @low.add(pq)
    @high.add(pq)
    this
  DURING: (other) -> this.SDU(other) && this.EDU(other)
  OVERLAP: (other) -> this.SDU(other) || this.EDU(other) || (this.SBS(other) && this.EAE(other))
  SBS: (other) -> @low.before(other.low)
  SAS: (other) -> @low.after(other.low)
  SBE: (other) -> @low.before(other.high)
  SAE: (other) -> @low.after(other.high)
  EBS: (other) -> @high.before(other.low)
  EAS: (other) -> @high.after(other.low)
  EBE: (other) -> @high.before(other.high)
  EAE: (other) -> @high.after(other.high)
  SDU: (other) -> @low.afterOrConcurrent(other.low) && @low.beforeOrConcurrent(other.high)
  EDU: (other) -> @high.afterOrConcurrent(other.low) && @high.beforeOrConcurrent(other.high)
  ECW: (other) -> @high.asDate() && other.high.asDate() && @high.withinSameMinute(other.high)
  SCW: (other) -> @low.asDate() && other.low.asDate() && @low.withinSameMinute(other.low)
  ECWS: (other) -> @high.asDate() && other.low.asDate() && @high.withinSameMinute(other.low)
  SCWE: (other) -> @low.asDate() && other.high.asDate() && @low.withinSameMinute(other.high)
  CONCURRENT: (other) -> this.SCW(other) && this.ECW(other)
@IVL_TS = IVL_TS

class ANYNonNull
  constructor: ->
  match: (scalarOrHash) ->
    val = fieldOrContainerValue(scalarOrHash, 'scalar')
    val != null
@ANYNonNull = ANYNonNull

atLeastOneTrue = (values...) ->
  trueValues = (value for value in values when value && value.isTrue())
  trueValues.length>0
  Specifics.unionAll(new Boolean(trueValues.length>0), values)
@atLeastOneTrue = atLeastOneTrue
  
allTrue = (values...) ->
  trueValues = (value for value in values when value && value.isTrue())
  Specifics.intersectAll(new Boolean(trueValues.length>0 && trueValues.length==values.length), values)
@allTrue = allTrue
  
atLeastOneFalse = (values...) ->
  falseValues = (value for value in values when value.isFalse())
  Specifics.intersectAll(new Boolean(falseValues.length>0), values, true)
@atLeastOneFalse = atLeastOneFalse
  
allFalse = (values...) ->
  falseValues = (value for value in values when value.isFalse())
  Specifics.unionAll(new Boolean(falseValues.length>0 && falseValues.length==values.length), values, true)
@allFalse = allFalse
  
matchingValue = (value, compareTo) ->
  new Boolean(compareTo.match(value))
@matchingValue = matchingValue

anyMatchingValue = (event, valueToMatch) ->
  matchingValues = (value for value in event.values() when (valueToMatch.match(value)))
  matchingValues.length > 0
@anyMatchingValue = anyMatchingValue

filterEventsByValue = (events, value) ->
  matchingEvents = (event for event in events when (anyMatchingValue(event, value)))
  matchingEvents
@filterEventsByValue = filterEventsByValue

filterEventsByField = (events, field, value) ->
  respondingEvents = (event for event in events when event.respondTo(field))
  event for event in respondingEvents when value.match(event[field]())
@filterEventsByField = filterEventsByField

getCodes = (oid) ->
  OidDictionary[oid]
@getCodes = getCodes

# Used for representing XPRODUCTs of arrays, holds both a flattened array that contains
# all the elements of the compoent arrays and the component arrays themselves
class CrossProduct extends Array
  constructor: (allEventLists) ->
    super()
    @eventLists = []
    for eventList in allEventLists
      @eventLists.push eventList
      for event in eventList
        this.push(event)

XPRODUCT = (eventLists...) ->
  Specifics.intersectAll(new CrossProduct(eventLists), eventLists)
@XPRODUCT = XPRODUCT

UNION = (eventLists...) ->
  union = []
  for eventList in eventLists
    for event in eventList
      union.push(event)
  Specifics.unionAll(union, eventLists)
@UNION = UNION

COUNT = (events, range) ->
  count = events.length
  result = new Boolean(range.match(count))
  applySpecificOccurrenceSubset('COUNT', Specifics.maintainSpecifics(result, events), range)
@COUNT = COUNT

PREVSUM = (eventList) ->
  eventList
@PREVSUM = PREVSUM

getIVL = (eventOrTimeStamp) ->
  if eventOrTimeStamp.asIVL_TS
    eventOrTimeStamp.asIVL_TS()
  else
    ts = new TS()
    ts.date = eventOrTimeStamp
    new IVL_TS(ts, ts)
@getIVL = getIVL
    
# should DURING and CONCURRENT be an error ?
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
  'CONCURRENT': 'low'
}

# should DURING SDU, EDU, ECW, SCW and CONCURRENT be an error ?
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
  'CONCURRENT': 'low'
}
    
withinRange = (method, eventIVL, boundIVL, range) ->
  eventTS = eventIVL[eventAccessor[method]]
  boundTS = boundIVL[boundAccessor[method]]
  range.match(eventTS.difference(boundTS, range.unit()))
@withinRange = withinRange
    
eventMatchesBounds = (event, bounds, methodName, range) ->
  if bounds.eventLists
    # XPRODUCT set of bounds - event must match at least one bound in all members
    matchingBounds = []
    for boundList in bounds.eventLists
      currentMatches = eventMatchesBounds(event, boundList, methodName, range)
      return [] if (currentMatches.length == 0)
      matchingBounds = matchingBounds.concat(currentMatches)
    return Specifics.maintainSpecifics(matchingBounds,bounds)
  else
    eventIVL = getIVL(event)
    matchingBounds = (bound for bound in bounds when (
      boundIVL = getIVL(bound)
      result = eventIVL[methodName](boundIVL)
      if result && range
        result &&= withinRange(methodName, eventIVL, boundIVL, range)
      result
    ))
    Specifics.maintainSpecifics(matchingBounds, bounds)
@eventMatchesBounds = eventMatchesBounds
  
eventsMatchBounds = (events, bounds, methodName, range) ->
  if (bounds.length==undefined)
    bounds = [bounds]
  if (events.length==undefined)
    events = [events]
  
  specificContext = new Specifics()
  hasSpecificOccurrence = (events.specific_occurrence? || bounds.specific_occurrence?)
  matchingEvents = []
  matchingEvents.specific_occurrence = events.specific_occurrence
  for event in events
    matchingBounds=eventMatchesBounds(event, bounds, methodName, range)
    matchingEvents.push(event) if matchingBounds.length > 0

    if hasSpecificOccurrence
      matchingEvents.specific_occurrence = events.specific_occurrence
      # TODO: we'll need a temporary variable for non specific occurrences on the left so that we can do rejections based on restrictions in the data criteria
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

FIRST = (events) ->
  result = []
  result = [events.sort(dateSortAscending)[0]] if (events.length > 0)
  applySpecificOccurrenceSubset('FIRST',Specifics.maintainSpecifics(result, events))
@FIRST = FIRST

SECOND = (events) ->
  result = []
  result = [events.sort(dateSortAscending)[1]] if (events.length > 1)
  applySpecificOccurrenceSubset('SECOND',Specifics.maintainSpecifics(result, events))
@SECOND = SECOND

THIRD = (events) ->
  result = []
  result = [events.sort(dateSortAscending)[2]] if (events.length > 2)
  applySpecificOccurrenceSubset('THIRD',Specifics.maintainSpecifics(result, events))
@THIRD = THIRD

FOURTH = (events) ->
  result = []
  result = [events.sort(dateSortAscending)[3]] if (events.length > 3)
  applySpecificOccurrenceSubset('FOURTH',Specifics.maintainSpecifics(result, events))
@FOURTH = FOURTH

FIFTH = (events) ->
  result = []
  result = [events.sort(dateSortAscending)[4]] if (events.length > 4)
  applySpecificOccurrenceSubset('FIFTH',Specifics.maintainSpecifics(result, events))
@FIFTH = FIFTH

RECENT = (events) ->
  result = []
  result = [events.sort(dateSortDescending)[0]] if (events.length > 0)
  applySpecificOccurrenceSubset('RECENT',Specifics.maintainSpecifics(result, events))
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
  applySpecificOccurrenceSubset('MIN',Specifics.maintainSpecifics(result, events), range)
@MIN = MIN

MAX = (events, range) ->
  maxValue = -Infinity
  if (events.length > 0)
    maxValue = events.sort(valueSortDescending)[0].value()["scalar"]
  result = new Boolean(range.match(maxValue))
  applySpecificOccurrenceSubset('MAX',Specifics.maintainSpecifics(result, events), range)
@MAX = MAX

@OidDictionary = {};

hqmfjs = hqmfjs||{}
@hqmfjs = @hqmfjs||{};
