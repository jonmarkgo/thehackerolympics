class LeaderBoardLayout extends Backbone.Marionette.Layout
    template: '#leader-layout'
    regions:
        list : '.leader-list'

    initialize: ->
        @leaders = new LeaderSheet
        @listenTo @leaders, 'sync', @showLeaders

    onRender: ->
        @leaders.fetch()

    showLeaders: ->
        @leaderData = []
        _.each @leaders.get('feed')['entry'], (cell, idx) =>
            score = (cell.content['$t']).replace '_cokwr: ', ''
            response = 
                place: idx
                name: cell.title['$t']
                score: score
            @leaderData.push response

        players = new Backbone.Collection @leaderData
        @list.show new LeaderList
            collection: players

class LeaderItemView extends Backbone.Marionette.ItemView
    template: '#leader-item'
    className: 'leader-deets'
    initialize: ->
        place = @model.get('place')
        @$el.addClass "p#{place}"

class LeaderList extends Backbone.Marionette.CollectionView
    itemView: LeaderItemView
    className: 'weiners'

class LeaderSheet extends Backbone.Model
    url: "https://spreadsheets.google.com/feeds/list/0AmkZRXO39XOSdFh6ZzFqWng1dHRLRXk0NmlTekdHYWc/2/public/basic?alt=json"


$(document).ready(
    ->
        lb = new LeaderBoardLayout
            el: "#leaderboard"
        lb.render()
)