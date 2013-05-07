define ['event-bus'],
(EventBus) ->
    class UtilityPane extends Backbone.View
        events:
            'click .pane-toggle': 'togglePane'

        constructor: ->
            @events = _.extend @events, UtilityPane.prototype.events

            @visible = false
            @enabled = true

            super

        initialize: ->
            @listenTo EventBus, 'utility-pane:show', (pane) =>
                if pane isnt this
                    @togglePane undefined, false

            @listenTo EventBus, 'utility-pane:hideall activity:start', =>
                @togglePane undefined, false

            @listenTo EventBus, 'utility-pane:set-enabled', (paneId, enabled) =>
                if paneId is @paneId or paneId is 'all'
                    @setEnabled enabled

        positionPane: ->
            @toggleLink = @$ '.pane-toggle'
            @utilPane = @$ '.toggleable-pane'

            linkWidth = @toggleLink.outerWidth()
            paneWidth = @utilPane.outerWidth()

            @utilPane.css 'margin-left', -(paneWidth - linkWidth) / 2

        togglePane: (event, state = not @visible) ->
            if not @enabled
                return

            @visible = state

            if @visible
                EventBus.trigger 'utility-pane:show', this
                @positionPane()
                (@$ '.pane-toggle').addClass 'active'
                (@$ '.toggleable-pane').show()
            else
                (@$ '.pane-toggle').removeClass 'active'
                (@$ '.toggleable-pane').hide()

        setEnabled: (@enabled) ->
            (@$ '.pane-toggle').toggleClass 'disabled', not enabled
            (@$ '.pane-toggle i').toggleClass 'icon-blue', enabled
            (@$ '.pane-toggle i').toggleClass 'icon-gray', not enabled

    class TranslatePopup extends UtilityPane
        tagName: 'li'
        paneId: 'translate'
        events: 
            'click .btn-search': 'sendToGoogle'
            'click .btn-switch': 'switchLang'
            'keydown input.native-term': 'clearTranslation'

        baseUrl: 'https://www.googleapis.com/language/translate/v2'

        initialize: ->
            super
            @template = _.template translatePopupTemplate
            @reversed = off

        render: ->
            @$el.html $(@template userProfile: CONFIG_GLOBAL.userProfile)

            { lang } = CONFIG_GLOBAL.userProfile

            @langDict = $.parseJSON @$('#langDict').html()

            @$transContainer = @$ 'input.trans-term'
            @$form = @$ 'form#translate-form'

            @nativeCode = lang.native
            @learningCode = lang.learning

            @$('.native-lang').html @langDict[@nativeCode]
            @$('.trans-lang').html @langDict[@learningCode]

        sendToGoogle: ->
            @searchTerm = @$('input.native-term').val()
            $.ajax
                url: @baseUrl, 
                dataType: 'jsonp',
                data: 
                    key: 'AIzaSyD0EKvENV3KQG8S2fHVMONrChGSILK8kX4',
                    q: @searchTerm,
                    source: @nativeCode,
                    target: @learningCode,

                success: @showTranslation

                error: @showError

        clearTranslation: () =>
            @$transContainer.val ''
            @$transContainer.removeClass 'success'

        showTranslation: (result) =>
            @translation = result.data.translations[0].translatedText
            @$transContainer.val @translation

            @$transContainer.addClass 'success'

        showError: (errorMsg) =>
            # We should fire an event here through EventBus telling dev that something isn't working?
            @$form.append(errorMsg)

        switchLang: () =>
            # Switch position on click.
            @$('.trans-lang').toggleClass('left');
            @$('.native-lang').toggleClass('right');

            # Switch native/learning code for sendToGoogle
            if @reversed isnt on
                @nativeCode = CONFIG_GLOBAL.userProfile.lang.learning
                @learningCode = CONFIG_GLOBAL.userProfile.lang.native
                @reversed = on
            else
                @nativeCode = CONFIG_GLOBAL.userProfile.lang.native
                @learningCode = CONFIG_GLOBAL.userProfile.lang.learning
                @reversed = off