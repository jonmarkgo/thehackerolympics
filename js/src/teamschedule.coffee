class ScheduleLayout extends Backbone.Marionette.Layout
    template: '#schedule-layout'
    regions:
        list : '.schedule-list'

    initialize: ->
        @data = new ScheduleData
        @listenTo @data, 'sync', @showSchedule

    onRender: ->
        @data.fetch()

    showSchedule: ->
        @list.show new TimeSlots
            collection: @data

class TimeSlotView extends Backbone.Marionette.ItemView
    template: '#slot-item'
    className: 'time-slot'
    tagName: 'section'

class TimeSlots extends Backbone.Marionette.CollectionView
    itemView: TimeSlotView
    className: 'section-container accordion'
    attributes: 
        "data-section": "accordion"


class ScheduleData extends Backbone.Collection
    url: "http://thehackerolympics.com/js/src/schedule.json"
    initialize: ->
        @slots =
            slot1: '6:30'
            slot2: '6:45'
            slot3: '6:30'
            slot4: '6:45'
            slot5: '7:00'
            slot6: '7:15'
            slot7: '7:30'
            slot8: '7:45'
            slot9: '8:00'
            slot10: '8:15'
            slot11: '8:30'
            slot12: '8:45'
            slot13: '9:00'
            slot14: '9:15'
            slot15: '9:30'
            slot16: '9:45'
            slot17: '10:00'
    parse: (response) ->
        _.each response, (item) =>
            _.each item, (val, key) =>
                if typeof val != "number"
                    if val.indexOf("startupcharades") != -1
                        charadeBooth = val.split("_")[1]
                        item['charadeTime'] = @slots[key]
                        item['charadeBooth'] = charadeBooth
                    if key not in ['team', 'teamName']
                        item[val] = @slots[key]
                        console.log item

        return response


$(document).ready(
    ->
        sc = new ScheduleLayout
            el: "#schedule"
        sc.render()
)