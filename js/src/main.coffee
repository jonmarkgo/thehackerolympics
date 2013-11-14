public_spreadsheet_url = 'https://docs.google.com/spreadsheet/pub?key=0AuGqzqpyR-eVdF8tbWUxMFhhMTRjYzBtSHJLVEswU1E&output=html';

class MainApp extends Backbone.Marionette.Application

app = new MainApp

app.addInitializer ->
    router = new MainRouter
    Backbone.history.start
        root: '/Backbone/index.html'

class MainRouter extends Backbone.Router
    routes:
        '': 'showHome'
        'rules/': 'showChallenges'
        'leaderboard/': 'showLeaderboard'

    initialize: ->
        @data = new GoogleModel

    loadGo: (slug) ->
        if not @data.get('challenges')
            @listenTo @data, 'sync', @buildLayout
            @data.fetch()
        _.defer =>
            switch slug
                when 'home' then @mainLayout.showHome()
                when 'rules' then @mainLayout.showChallenges()


    buildLayout: =>
        @mainLayout = new MainLayout
            el: "#main-content"
            router: this
            data: @data
        @mainLayout.render()

    showHome: ->
        @loadGo 'home'

    showChallenges: ->
        @loadGo 'rules'

    showLeaderboard: ->
        @loadGo 'leaderboard'

class GoogleModel extends Backbone.Model
    url: 'js/ho.json'

class MainLayout extends Backbone.Marionette.Layout
    template: '#main-layout'
    regions:
        nav: '.nav-content'
        content: '.content'

    initialize: (options) ->
        {@router, @data} = options
        @navView = new NavItems
            router: @router

    onRender: (slug) ->
        @nav.show @navView

    showHome: ->
        @content.show new HomePage
            data: @data

    showChallenges: ->
        @content.show new ChallengesPage
            data: @data

class HomePage extends Backbone.Marionette.Layout
    template: '#home-page'

    regions:
        welcome: '.welcome-container'
        format: '.format-container'
        schedule: '.schedule-container'

    initialize: (options) ->
        {@data} = options
        @scheduleData = new Backbone.Collection @data.get('schedule')
        @eventData = new Backbone.Model @data.get('event_info')[0]

        @scheduleView = new ScheduleView
            model: @scheduleData
            view: ScheduleListView
        @eventInfoView = new EventView
            model: @eventData
            view: EventInfoView

    onShow: ->
        @schedule.show @scheduleView
        @format.show @eventInfoView
        

class SubCollectionView extends Backbone.Marionette.Layout
    regions:
        content: '.content'

    initialize: (options) ->
        {@model, @view} = options

    onShow: ->
        @renderView()

    renderView: ->
        @myview = new @view
            collection: @model
        @content.show @myview

class SubView extends Backbone.Marionette.Layout
    regions:
        content: '.content'

    initialize: (options) ->
        {@model, @view} = options

    onShow: ->
        @renderView()

    renderView: ->
        @myview = new @view
            model: @model
        @content.show @myview

class ScheduleView extends SubCollectionView
    template: '#sub-view'

class EventView extends SubView
    template: '#sub-view'

class ChallengesPage extends Backbone.Marionette.Layout
    template: '#challenges-page'

    regions:
        rules: '.rules-container'
        challenges: '.challenges-container'

    initialize: (options) ->
        {@data} = options
        @rulesData = new Backbone.Collection @data.get('rules')
        @challengesData = new Backbone.Collection @data.get('challenges')

        @rulesView = new RulesView
            collection: @rulesData
        @challengesView = new ChallengesView
            collection: @challengesData

    onShow: ->
        @rules.show @rulesView
        @challenges.show @challengesView


class ChallengeItemView extends Backbone.Marionette.ItemView
    template: '#challenge-item'
    
class ChallengesView extends Backbone.Marionette.CollectionView
    itemView: ChallengeItemView
    className: 'challenges'

class RulesItemView extends Backbone.Marionette.ItemView
    template: '#rules-item'
    
class RulesView extends Backbone.Marionette.CollectionView
    itemView: RulesItemView
    className: 'rules'

class ScheduleItemView extends Backbone.Marionette.ItemView
    template: '#schedule-item'
    
class ScheduleListView extends Backbone.Marionette.CollectionView
    itemView: ScheduleItemView
    className: 'schedule'

class EventInfoView extends Backbone.Marionette.ItemView
    template: '#format-info'
    className: 'info'

class NavItems extends Backbone.Marionette.ItemView
    template: '#navbar'
    events:
        'click a': 'goToPage'

    initialize: (options) ->
        {@router} = options
        @delegateEvents()

    goToPage: (event) ->
        event.preventDefault()
        event.stopPropagation()
        (@$ 'li').removeClass 'active'
        (@$ event.currentTarget).parent('li').addClass 'active'
        slug = (@$ event.currentTarget).data('slug')
        if slug is 'home'
            @router.navigate '', trigger: true, replace:true
        else
            @router.navigate "#{slug}/", trigger: true, replace:true


$(document).ready ->
    app.start()