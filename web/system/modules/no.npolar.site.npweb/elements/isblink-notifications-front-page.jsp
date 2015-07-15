<%-- 
    Document   : isblink-notifications-front-page (based loosely on events-upcoming)
                 Collects events occuring today (read from a special folder) and displays them.
                 Recurring events are also injected.
    Created on : Nov 10, 2014, 1:07:05 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.opencms.file.CmsResourceFilter,
                org.opencms.workplace.explorer.CmsResourceUtil,
                org.opencms.workplace.CmsWorkplaceManager,
                org.opencms.workplace.CmsWorkplaceSettings,
                org.opencms.main.OpenCms,
                com.google.ical.iter.RecurrenceIteratorFactory,
                com.google.ical.iter.RecurrenceIterator,
                com.google.ical.values.DateValueImpl,
                com.google.ical.values.DateValue,
                java.util.*,
                java.text.SimpleDateFormat,
                no.npolar.common.eventcalendar.*,
                no.npolar.util.*,
                org.opencms.file.CmsResource,
                org.opencms.file.CmsObject,
                org.opencms.jsp.CmsJspActionElement,
                org.opencms.main.CmsException,
                org.opencms.xml.A_CmsXmlDocument,
                org.opencms.xml.content.*"  session="true" 
%><%!
    /**
     * Checks if a given test date is on a day before the day a given matcher date represents.
     */
    public boolean isBeforeDate(Date d, Date matcherDate) {
        Calendar dateStartCal = getDateStartCal(matcherDate);
        
        if (d.before(dateStartCal.getTime()))
            return true;
        
        return false;
    }
    /**
     * Checks if a given test date is on the same day as a given matcher date.
     */
    public boolean isOnDate(Date d, Date matcherDate) {
        Calendar dateStartCal = getDateStartCal(matcherDate);
        dateStartCal.add(Calendar.SECOND, -1);
        
        Calendar dateEndCal = getDateEndCal(matcherDate);
        dateEndCal.add(Calendar.SECOND, 1);
        
        if (d.after(dateStartCal.getTime()) && d.before(dateEndCal.getTime())) {
            return true;
        }
        return false;
    }
    /**
     * Checks if a given test date is on a day after the day a given matcher date represents.
     */
    public boolean isAfterDate(Date d, Date matcherDate) {
        Calendar dateEndCal = getDateEndCal(matcherDate);
        
        if (d.after(dateEndCal.getTime()))
            return true;
        
        return false;
    }
    /**
     * Gets a Calendar that represents the START of the day defined by the 
     * given date.
     */
    public Calendar getDateStartCal(Date d) {
        Calendar dateStartCal = new GregorianCalendar();
        dateStartCal.setTime(d);
        dateStartCal.set(Calendar.HOUR_OF_DAY, 0);
        dateStartCal.set(Calendar.MINUTE, 0);
        dateStartCal.set(Calendar.SECOND, 0);
        return dateStartCal;
    }
    /**
     * Gets a Calendar that represents the END of the day defined by the 
     * given date.
     */
    public Calendar getDateEndCal(Date d) {
        Calendar dateEndCal = new GregorianCalendar();
        dateEndCal.setTime(d);
        dateEndCal.set(Calendar.HOUR_OF_DAY, 23);
        dateEndCal.set(Calendar.MINUTE, 59);
        dateEndCal.set(Calendar.SECOND, 59);
        return dateEndCal;
    }
    /**
     * Checks if the given event starts and ends during the same month.
     */
    public boolean isOneMonthEvent(EventEntry event) {
        if (!event.hasEndTime())
            return true;
        
        Calendar cStart = new GregorianCalendar();
        Calendar cEnd = new GregorianCalendar();
        cStart.setTime(new Date(event.getStartTime()));
        cEnd.setTime(new Date(event.getEndTime()));
        
        return cStart.get(Calendar.YEAR) == cEnd.get(Calendar.YEAR) 
                && cStart.get(Calendar.MONTH) == cEnd.get(Calendar.MONTH);
    }
    /**
     * Gets the event's time span, as ready-to-use HTML.
     * @return 
     */
    public String getTimespanHtml(CmsJspActionElement cms, EventEntry event) throws CmsException {
        Locale locale = cms.getRequestContext().getLocale();
        /*SimpleDateFormat datetime = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
        SimpleDateFormat dateonly = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
        SimpleDateFormat timeonly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
        SimpleDateFormat month = new SimpleDateFormat(cms.label("label.event.dateformat.month"), locale);*/
        SimpleDateFormat full = new SimpleDateFormat("d. MMM yyyy H:mm", locale);
        SimpleDateFormat datenotime = new SimpleDateFormat("d. MMM yyyy", locale);
        SimpleDateFormat dateonly = new SimpleDateFormat("d.", locale);
        SimpleDateFormat timeonly = new SimpleDateFormat("H:mm", locale);
        SimpleDateFormat dfIso = event.getDatetimeAttributeFormat(locale);
        
        // Select initial date format
        SimpleDateFormat df = event.isDisplayDateOnly() ? datenotime : full;
        
        String begins = null;
        String ends = null;
        String beginsIso = null;
        String endsIso = null;
        try {
            SimpleDateFormat beginFormat = df;
            beginsIso = dfIso.format(new Date(event.getStartTime()));
            // If there is an end-time
            if (event.hasEndTime()) {
                SimpleDateFormat endFormat = df;
                if (event.isOneDayEvent()) {
                    if (!event.isDisplayDateOnly()) {
                        // End time is on the same day as begin time, format only the hour/minute
                        endFormat = timeonly;
                    } 
                    else {
                        // Shouldn't happen
                        endFormat = new SimpleDateFormat("");
                    }
                } 
                else {
                    // Not one-day event, but maybe same month?
                    if (isOneMonthEvent(event) && event.isDisplayDateOnly()) {
                        endFormat = datenotime;
                        beginFormat = dateonly;
                    }
                }
                ends = endFormat.format(new Date(event.getEndTime())).replaceAll("\\s", "&nbsp;");
                endsIso = dfIso.format(new Date(event.getEndTime()));
            }
            begins = beginFormat.format(new Date(event.getStartTime())).replaceAll("\\s", "&nbsp;");
        } catch (NumberFormatException nfe) {
            // Keep ends=null
        }
        
        String s = "";
        
        s += "<time itemprop=\"startDate\" datetime=\"" + beginsIso + "\">" + begins + "</time>";
        if (ends != null)
            s += " &ndash; <time itemprop=\"endDate\" datetime=\"" + endsIso + "\">" + ends + "</time>";
        
        return s;
    }

    /**
     * Gets the workplace timestamp as a Date instance. If time warp is active, 
     * the returned datetime will be the "warped" time. Else, NOW is returned.
     *
     * @param s The current request's session object.
     * @return Date The current workplace timestamp, as a Date instance.
     */
    public Date getNowDate(HttpSession s) {
        Date now = new Date();
        try {
            // Try to set the current date to the warped time (if active), fallback to the "actual" now
            CmsWorkplaceSettings settings = (CmsWorkplaceSettings)s.getAttribute(CmsWorkplaceManager.SESSION_WORKPLACE_SETTINGS);
            long timewarp = settings.getUserSettings().getTimeWarp();
            if (timewarp > 1) {
                return new Date(timewarp);
            }
        } catch (Exception e) {

        }
        return now;
    }
    /**
     * Converts the given Date instance to a DateValue instance.
     */
    public DateValue toDateValue(Date d) {
        Calendar helperCal = new GregorianCalendar(TimeZone.getTimeZone("GMT+1:00"), new Locale("no"));
        helperCal.setTime(d);
        return new DateValueImpl(helperCal.get(Calendar.YEAR), helperCal.get(Calendar.MONTH)+1, helperCal.get(Calendar.DATE));
    }
    /**
     * Converts the given DateValue instance to a Date instance.
     * As DateValue know no clock time, it is set to 12:00:00 in the returned Date instance.
     */
    public Date toDate(DateValue dv) {
        Calendar helperCal = new GregorianCalendar(TimeZone.getTimeZone("GMT+1:00"), new Locale("no"));
        helperCal.set(dv.year(), dv.month()-1, dv.day(), 12, 0, 0);
        return helperCal.getTime();
    }
    /**
     * Gets the recurrence rule (RRULE) for the given event, or null if no rule
     * exists.
     */
    public String getRecurrenceRule(CmsObject cmso, EventEntry event) {
        try {
            String rule = cmso.readPropertyObject(cmso.readResource(event.getStructureId()), "rrule", false).getValue(null);
            return "RRULE:".concat(rule);
        } catch (Exception e) {
            return null;
        }
    }
    public Date getClosestPastStartDate(DateValue marker, CmsAgent cms, EventEntry event) {
        try {
            RecurrenceIterator iRecur = getRecurrenceIterator(cms, event);
            if (iRecur == null)
                return new Date(event.getStartTime()); // Not a recurring event, return initial start time
            
            Date markerDate = toDate(marker); // The marker date
            Date endMarkerDate = new Date(getDateEndCal(markerDate).getTimeInMillis()); // Timestamp: The end of the marker date
            Date closest = null;
            
            // Safety 
            int iterations = 0;
            int maxIterations = 1000;
            
            // Loop recurrences
            while (iRecur.hasNext() && iterations++ < maxIterations) {
                Date recStartDate = toDate((DateValue)iRecur.next());
                if (recStartDate.after(endMarkerDate)) // Is the recurrence start date after the marker date?
                    break; // Yes: break
                /*if (event.hasEndTime() && !event.isOneDayEvent()) { // Is the recurrence a multiple-day event?
                    if (new Date(recStartDate.getTime() + (event.getEndTime() - event.getStartTime())).after(endMarkerDate)) // Is the recurrence end time after the 
                        break;
                }*/
                closest = recStartDate; // No - then so far it has the closest start date
            }
            
            if (closest == null)
                return new Date(event.getStartTime()); // Found nothing, return the event's initial start time

            return closest; // Found a date in the past, return it
            
        } catch(Exception e) {
            return new Date(event.getStartTime());
        }
    }
    public RecurrenceIterator getRecurrenceIterator(CmsAgent cms, EventEntry event) throws java.text.ParseException {
        // Get the recurrence rule
        String recRule = getRecurrenceRule(cms.getCmsObject(), event);
        if (recRule == null) {
            // Not recurring - return the initial start time
            return null;
        }
        // Get the initial begin timestamp
        Date initialStartTime = new Date(event.getStartTime());
        // Get the iterator for the recurrence dates, using the recurrence rule (RRULE) found on the event
        RecurrenceIterator iRecur = RecurrenceIteratorFactory.createRecurrenceIterator(recRule
                                                                                        , toDateValue(initialStartTime)
                                                                                        , TimeZone.getTimeZone("GMT+1:00")
                                                                                        );
        return iRecur;
    }
    /**
     * Gets an event's begin time, as a Date instance. If the event is non-
     * recurring, the regular begin time is returned. If the event is recurring,
     * the closest "next" begin time is returned. (Could be "today".)
     */
    public Date getBegin(CmsAgent cms, EventEntry event) {        
        // Get the initial begin timestamp
        Date initialStartTime = new Date(event.getStartTime());

        // This event is set to recur
        try {
            RecurrenceIterator iRecur = getRecurrenceIterator(cms, event);
            if (iRecur == null) {
                // Not recurring - return the initial start time
                return initialStartTime;
            }
                
            // Set up local time zone
            TimeZone tz = TimeZone.getTimeZone("GMT+1:00");
            // Get the current workplace time (possibly "warped", if time warp is active)
            Date currentTime = getNowDate(cms.getRequest().getSession());
            
            if (!event.isOneDayEvent() && event.hasEndTime()) {
                // Advance to the closest start date in the past (relative to current workplace time)
                iRecur.advanceTo(toDateValue(getClosestPastStartDate(toDateValue(currentTime), cms, event)));
            } else { // One-day event (or no end time specified)
                // Advance to the current workplace date
                iRecur.advanceTo(toDateValue(currentTime));
            }

            if (iRecur.hasNext()) {
                // Get the event's "next" recurring date (could be "today")
                DateValue dv = (DateValue)iRecur.next();
                Calendar cal = new GregorianCalendar(tz, cms.getRequestContext().getLocale());
                // First, set the time to the *initial* start time, so that any "event begin" clock time is preserved
                cal.setTime(initialStartTime);
                // Then update year, month and day
                cal.set(dv.year(), dv.month()-1, dv.day());
                // And return the Date instance representing the "next" beginning date
                return cal.getTime();
            }
        } catch (Exception e) {
            //out.println("<!-- Error processing recurring event: " + e.getMessage() + " -->");
        }
        return null;
    }
    /**
     * Gets the "event end" timestamp (as a Date), based on the given eventStart
     * timestamp.
     * <p>
     * The intended use case for this method is to get the end time for a
     * specific recurrence (defined by eventStart) of the given event.
     * <p>
     * If the given event is non-recurring, or if the given eventStart timestamp 
     * is identical to the given event's initial start time, then the initial 
     * end time is returned.
     * <p>
     * If the given event is a recurring one, and the given eventStart timestamp
     * differs from the given event's initial start time, then a new end time
     * is calculated.
     * <p>
     * If no end time is set at all, the returned value will always be 
     * "new Date(0)".
     */
    public Date getEnd(CmsAgent cms, EventEntry event, Date eventStart) {
        long longBeginOri = event.getStartTime();
        long longBegin = eventStart.getTime();

        if (longBeginOri < longBegin && getRecurrenceRule(cms.getCmsObject(), event) != null) {
            // The given event's initial start time is before the given 
            // eventStart AND a recurrence rule exists for the given event: 
            //      Assume that the given eventStart is the start time for a later 
            //      recurrence of the given event: Adjust the end time equally
            long diff = longBegin - longBeginOri;
            return new Date(event.hasEndTime() ? (event.getEndTime() + diff) : 0);
        }
        // No recurrence rule OR the no difference in start times: Just return
        // the event's initial end time
        return new Date(event.getEndTime());
    }
%><%
final boolean DEBUG = false;
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
Locale locale = cms.getRequestContext().getLocale();
//String requestFileUri                   = cms.getRequestContext().getUri();
//String requestFolderUri                 = cms.getRequestContext().getFolderUri();
EventCalendar calendar      = new EventCalendar(TimeZone.getDefault());
HttpSession sess = cms.getRequest().getSession(true);

// Get current workplace time
Date currentDate = getNowDate(sess);

if (DEBUG) out.println("<p>Current date set to " + new SimpleDateFormat("d. MMM yyyy hh:mm", locale).format(currentDate) + "</p>");

final String EVENTS_FOLDER  = locale.toString().equalsIgnoreCase("no") ? "/no/varsler/" : "/en/events/";

//final String DF_FULL = "d. MMM yyyy hh:mm";
//SimpleDateFormat datetime = new SimpleDateFormat(cms.label("label.event.dateformat.datetime"), locale);
//SimpleDateFormat dateonly = new SimpleDateFormat(cms.label("label.event.dateformat.dateonly"), locale);
//SimpleDateFormat timeonly = new SimpleDateFormat(cms.label("label.event.dateformat.timeonly"), locale);
//SimpleDateFormat dfIso = getDatetimeAttributeFormat(locale);

// Collect events "normally" (these events won't include any recurrences)
List events = calendar.getEvents(
                            getDateStartCal(currentDate).getTimeInMillis() // start
                            , getDateEndCal(currentDate).getTimeInMillis() // end
                            , cms // Required CMS obj
                            , EVENTS_FOLDER // Where to collect from 
                            , null // Undated folders
                            , null // Excluded folders
                            , null // Categories
                            , false // Exclude expired?
                            , false // Sort descending?
                            , true // Overlap lenient?
                            , true // Category inclusive?
                            , 1000 // Limit
                            );
							
if (events == null) {
	out.println("<!-- ERROR: Fetching events returned null -->");
	return;
}

if (DEBUG) out.println("<p>getEvents returned " + events.size() + " events.</p>");


List<EventEntry> recurrences = new ArrayList<EventEntry>();

//
// Inject recurrences of events
//

// Collect all events that are set to recur from the specified folder
List recurringEventResources = cmso.readResourcesWithProperty(EVENTS_FOLDER, "rrule");

if (recurringEventResources == null) {
	out.println("<!-- ERROR: Fetching recurring events returned null -->");
	return;
}


// Loop all events set to recur
if (!recurringEventResources.isEmpty()) {
    if (DEBUG) out.println("<p>Found a total of " + recurringEventResources.size() +  " event(s) set to recur.</p>");
    Iterator<CmsResource> iRecurringEventResources = recurringEventResources.iterator();
    while (iRecurringEventResources.hasNext()) {
        // Get the resource (of the event set to recur)
        CmsResource recurringEventResource = iRecurringEventResources.next();
        // Get the recurrence rule
        String rrule = cmso.readPropertyObject(recurringEventResource, "rrule", false).getValue(null);
        
        //
        // Create a recurrence of the event (if called for):
        //
        if (rrule != null) {
			try {
            // Don't forget this ;)
            rrule = "RRULE:" + rrule;
            
            // Get the event set to recur as an EventEntry
            EventEntry recurringEvent = new EventEntry(cmso, recurringEventResource);
            if (DEBUG) out.println("<p>'" + recurringEvent.getTitle() + "' isOneDayEvent(): " + recurringEvent.isOneDayEvent() + "</p>");
            // Then get its "next" begin time
            Date nextBeginTime = getBegin(cms, recurringEvent);
            // ... and end time
            Date nextEndTime = getEnd(cms, recurringEvent, nextBeginTime);
            
            Date cpd = getClosestPastStartDate(toDateValue(currentDate), cms, recurringEvent);
            if (DEBUG) out.println("<p>getClosestPastStartDate returned " + new SimpleDateFormat("d MMM yyyy").format(cpd) + "</p>");
            if (DEBUG) out.println("<p>nextBeginTime set to " + new SimpleDateFormat("d MMM yyyy").format(nextBeginTime) + "</p>");
            
            // Get the recurring event's initial start date (read from its regular "start time" field)
            Date recurringEventInitialStartTime = new Date(recurringEvent.getStartTime());
            
            // If the recurring event's initial start time is before the calculated "next" begin time, we're dealing with a recurrence
            boolean isRecurrence = recurringEventInitialStartTime.getTime() < nextBeginTime.getTime();
            if (isRecurrence) {
                try {
                    // Create the recurrence event (it's identical to the original event, but with begin/end dates adjusted)
                    EventEntry recurrence = new EventEntry(nextBeginTime.getTime()
                                                , nextEndTime.getTime()
                                                , recurringEvent.getTitle()
                                                , recurringEvent.getDescription()
                                                , recurringEvent.getResourceId()
                                                , recurringEvent.getStructureId()
                                                , locale);
                    if (DEBUG) out.println("<p>Recurrence event '" + recurrence.getTitle() + "' created.</p>");
                    // If the timespan of the recurrence event overlaps today ...
                    if (recurrence.overlapsRange(getDateStartCal(currentDate).getTimeInMillis(), getDateEndCal(currentDate).getTimeInMillis())) {
                        if (DEBUG) out.println("<p>Recurrence event '" + recurrence.getTitle() + "' DOES overlap current time: adding it.</p>");
                        events.add(0, recurrence);
                        recurrences.add(recurrence);
                        //break; // Don't iterate over any more 
                    } else {
                        if (DEBUG) out.println("<p>Recurrence event '" + recurrence.getTitle() + "' does NOT overlap current time: ignoring it.</p>");
                    }
                } catch (Exception e) {
                    out.println("<!-- Error processing recurrence of event: " + e.getMessage() + " -->");
                }
            }
            
            
            /*
            //if (!isOnDate(recurringStartDate, currentDate) && recurringEvent.isDisplayDateOnly()) { // Before we continue, make sure the initial start date is not in fact today, and make sure the event is set to display date only
            if (!isOnDate(recurringEventInitialStartTime, currentDate)) { // Events that has the initial start time today are already collected by getEvents(...)
                try {
                    // If the recurring date is today, create a new event for the recurrence
                    if (isOnDate(nextBeginTime, currentDate)) {
                        // Create an "new" event - identical to the original event, but with begin/end time settings adjusted
                        EventEntry recurrence = new EventEntry(nextBeginTime.getTime()
                                                                    , nextEndTime.getTime()
                                                                    , recurringEvent.getTitle()
                                                                    , recurringEvent.getDescription()
                                                                    , recurringEvent.getResourceId()
                                                                    , recurringEvent.getStructureId()
                                                                    , locale);
                        // Add it to the list of already collected events
                        events.add(0, recurrence);
                        recurrences.add(recurrence);
                        break;
                    }
                } catch (Exception e) {
                    out.println("<!-- Error processing recurrence of event: " + e.getMessage() + " -->");
                }
            }
            //*/
			} catch (Exception ee) {
				out.println("<!-- ERROR on event '" + recurringEventResource.getRootPath() + "': " + ee.getMessage() + " -->");
			}
        }
    }
    if (recurrences.isEmpty()) {
        if (DEBUG) out.println("<p>No recurrences of events were added to this view.</p>");
    }
}
// Done injecting recurrences of events



if (!events.isEmpty()) {
    Collections.sort(events, EventEntry.COMPARATOR_START_TIME);
    Collections.reverse(events);
    Iterator iEvents = events.iterator();

        %>
        <!--<ul style="display:block; margin:0; padding:0; list-style:none;">-->
        <!--<div class="notifications warn" style="background-color: #ff7; padding: 0.2em 1em 0.5em 1em; box-shadow: 0 2px 4px rgba(0,0,0,0.5);">-->
        <div>
            <!--<h2 style="text-align: center; margin-top:0;">Varsler</h2>-->
            <!--<ul class="notifications">-->
            <ul class="postit">
        <%
        while (iEvents.hasNext()) {
            EventEntry event = (EventEntry)iEvents.next();
            /*
            Date startDate = new Date(event.getStartTime());
            SimpleDateFormat startDateFormat = datetime;

            if (event.hasEndTime() && event.isDisplayDateOnly()) {
                // Format start date (i.e. either "18 Dec 2014", "18 Dec" or just "18") depending on end date
                Date endDate = new Date(event.getEndTime());

            }
            //*/
            %>
            <!--<div class="item" style="background-color:#fff; padding:0.5em; margin-bottom: 0.5em; box-shadow: 0 0 2px rgba(0,0,0,0.1) inset;">-->
            <!--<li class="notification">-->
            <li>
                <a class="" href="<%= cms.link(event.getUri(cmso)) %>">
                    <h3 class=""><%= event.getTitle() %></h3>
                </a>
                <% if (!recurrences.contains(event)) { %>
                <!--<div class="timestamp"><i class="icon-calendar"></i><%= getTimespanHtml(cms, event) %></div>-->
                <% } %>
                <p><%= event.getDescription() %></p>
            </li>
            <!--</div>-->
            <%
        }
        %>
            </ul>

        </div>
        <%

} else {
    %>
    <!--<p>Ingen varsler å vise for i dag.</p>-->
    <%
}
%>