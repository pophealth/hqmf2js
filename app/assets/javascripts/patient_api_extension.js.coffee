hQuery.Patient::procedureResults = -> this.results().concat(this.vitalSigns()).concat(this.procedures())
hQuery.Patient::allProcedures = -> this.procedures().concat(this.immunizations()).concat(this.medications())
hQuery.Patient::laboratoryTests = -> this.results().concat(this.vitalSigns())
hQuery.Patient::allMedications = -> this.medications().concat(this.immunizations())
hQuery.Patient::allProblems = -> this.conditions().concat(this.socialHistories()).concat(this.procedures())
hQuery.Patient::allDevices = -> this.conditions().concat(this.procedures()).concat(this.careGoals()).concat(this.medicalEquipment())
hQuery.Patient::activeDiagnoses = -> this.conditions().concat(this.socialHistories()).withStatuses(['active'])
hQuery.Patient::inactiveDiagnoses = -> this.conditions().concat(this.socialHistories()).withStatuses(['inactive'])
hQuery.Patient::resolvedDiagnoses = -> this.conditions().concat(this.socialHistories()).withStatuses(['resolved'])

hQuery.Patient::getAndCacheEvents = (key, that, fn, args...) ->
  this.cache ||= {}
  if !this.cache[key]
    this.cache[key] = fn.apply(that, args)
  this.cache[key]
hQuery.Patient::getEvents = (eventCriteria) ->
  cacheKey = eventCriteria.type
  events = this.getAndCacheEvents(cacheKey, this, this[eventCriteria.type])
  if eventCriteria.statuses && eventCriteria.statuses.length > 0
    cacheKey = cacheKey + "_" + String(eventCriteria.statuses)
    events = this.getAndCacheEvents(cacheKey, events, events.withStatuses, eventCriteria.statuses, eventCriteria.includeEventsWithoutStatus)
  cacheKey = cacheKey + "_" + String(eventCriteria.negated) + String(eventCriteria.negationValueSetId)
  if eventCriteria.negated
    codes = getCodes(eventCriteria.negationValueSetId)
    events = this.getAndCacheEvents(cacheKey, events, events.withNegation, codes)
  else
    events = this.getAndCacheEvents(cacheKey, events, events.withoutNegation)
  if eventCriteria.valueSetId
    cacheKey = cacheKey + "_" + String(eventCriteria.valueSetId) + "_" + String(eventCriteria.start) + "_" + String(eventCriteria.stop)
    codes = getCodes(eventCriteria.valueSetId)
    events = this.getAndCacheEvents(cacheKey, events, events.match, codes, eventCriteria.start, eventCriteria.stop, true)
  else if eventCriteria.valueSet
    events = events.match(eventCriteria.valueSet, eventCriteria.start, eventCriteria.stop, true)
  events = events.slice(0) # clone cached array before we add on specific occurrence
  if eventCriteria.specificOccurrence
    events.specific_occurrence = eventCriteria.specificOccurrence
  events
  
hQuery.Patient::deathdate = ->
    hQuery.dateFromUtcSeconds this.json["deathdate"]

hQuery.CodedEntry::asIVL_TS = ->
  tsLow = new TS()
  tsLow.date = this.startDate() || this.date() || null
  tsHigh = new TS()
  tsHigh.date = this.endDate() || this.date() || null
  new IVL_TS(tsLow, tsHigh)
hQuery.CodedEntry::asTS = ->
  ts = new TS()
  ts.date = this.timeStamp()
  ts

hQuery.Encounter::lengthOfStay = (unit) ->
  ivl_ts = this.asIVL_TS()
  ivl_ts.low.difference(ivl_ts.high, unit)

hQuery.Encounter::transferTime = () ->
  transfer = (@json['transferFrom'] || @json['transferTo'])
  time = transfer.time if transfer
  if time
    hQuery.dateFromUtcSeconds(time)
  else
    if @json['transferTo']
      @endDate()
    else
      @startDate()

hQuery.AdministrationTiming::dosesPerDay = () ->
  #figure out the units and value and calculate
  p = this.period()
  switch(p.unit())
    when "h" 
      24/p.value()
    when "d" 
      1/p.value()


hQuery.Fulfillment::daysInRange = (dateRange,dose, dosesPerDay) ->
  # this will give us the number of days this fullfilment was for
  totalDays = this.quantityDispensed().value()/dose/dosesPerDay
  totalDays = 0 if isNaN(totalDays)
  endDate = new Date(this.dispenseDate().getTime() + (totalDays*60*60*24*1000)) 
  high = if dateRange && dateRange.high then dateRange.high.asDate() else endDate
  low =  if dateRange && dateRange.low then dateRange.low.asDate() else this.dispenseDate()
  # from the date it was deispensed add the total number of days to 
  # get the end date of the fullfillment.  Note that this may not 
  # be the actual number of days the person took the meds but the 
  # measure developers and the guidance given around CMD have not been
  # thought out very well at all.  For reporting this should really just
  # be done based off of start and end dates and not any sort of tallying of 
  # doses.  
  startDiff = TS.daysDifference(low,this.dispenseDate())
  endDiff =   TS.daysDifference(endDate,high)
  # startDiff will be - if the start date was before the date range 
  # so we can trim those first days off the total
  totalDays += startDiff if startDiff < 0
  #endDiff will be negative if the end date was after the rage hi value
  # so we can trim those days off
  totalDays += endDiff if endDiff < 0
  #if we have a negative value set it to zero
  totalDays = 0 if isNaN(totalDays) || totalDays < 0 
  totalDays
  
# Determin sum the cmd for each fullFillment history based on the 
# date range
hQuery.Medication::fulfillmentTotals = (dateRange)->
  dpd = this.administrationTiming().dosesPerDay()
  dose = this.dose().scalar
  this.fulfillmentHistory().reduce (t, s) -> 
    t + s.daysInRange(dateRange,dose,dpd)
  , 0  
  
hQuery.Medication::cumulativeMedicationDuration = (dateRange) ->
  #assuming that the dose is the same across fills and that fills is  stated in individual
  #doses not total amount. Will need to flush this out more at a later point in time.
  #Considering that liquid meds are probaly dispensed as total volume ex 325ml with a dose of
  #say 25ml per dose.  Will definatley need to revisit this.
  this.fulfillmentTotals(dateRange) if this.administrationTiming() && this.dose() && @json['fulfillmentHistory']

class hQuery.Reference 
  constructor: (@json) ->
  referenced_id: -> @json["referenced_id"]
  referenced_type: -> @json["reference"]
  type: ->   @json["type"]


hQuery.CodedEntry::references = () ->
  for ref in (@json["references"] || [])
    new hQuery.Reference(ref)

hQuery.CodedEntry::referencesByType = (type) -> 
  e for e in @references() when e.type() == type

hQuery.CodedEntry::respondTo = (functionName) ->
  typeof(@[functionName]) == "function"

hQuery.CodedEntryList::isTrue = ->
  @length != 0

hQuery.CodedEntryList::isFalse = ->
  @length == 0

Array::isTrue = ->
  @length != 0

Array::isFalse = ->
  @length == 0

Boolean::isTrue = =>
  `this == true`
  
Boolean::isFalse = =>
  `this == false`
