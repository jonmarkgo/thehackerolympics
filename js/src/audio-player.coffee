define ['event-bus', 'text!templates/activities/audio-player.jade'], (EventBus, audioPlayerTemplate) ->
    class AudioPlayerBase extends Backbone.View
        # This variable is "static" in that it will be closed over by each new
        # instance of `AudioPlayerBase` so that each player will have a unique
        # ID attribute.
        audioPlayerNumber = 0

        defaults:
            showSegments: false
            skipTime: 10 #seconds

        events:
            'click .jp-rewind': 'skipBackward'
            'click .jp-ff': 'skipForward'

        initialize: () ->
            @options = _.defaults @options, @defaults
            @options.playerNumber = audioPlayerNumber++

            @audioUrl = @model.get 'audio_url'

            @template = _.template audioPlayerTemplate

            @mediaLoaded = false

        render: ->
            @$el.html @template(@options)
            @initPlayer()

        initPlayer: ->
            @$voxyPlayer = @$("#resource-jplayer-#{@options.playerNumber}").jPlayer
                preload: 'none'
                swfPath: "#{STATIC_URL}js/thirdparty/jQuery.jPlayer.2.2.0/"
                supplied: 'mp3'
                wmode: 'window'
                cssSelectorAncestor: "#resource-jplayer-container-#{@options.playerNumber}"
                size:
                    width: '0px'
                    height: '0px'
                ready: =>
                    @$voxyPlayer.jPlayer 'setMedia',
                        mp3: @audioUrl
                timeupdate: (event) =>
                    @customControls.progress.slider("value", event.jPlayer.status.currentPercentAbsolute)
                    @trigger 'timeupdate', event
                play: (event) =>
                    @isPlaying = true
                    @trigger 'play', event
                pause: (event) =>
                    @isPlaying = false
                    @trigger 'pause', event
                ended: (event) =>
                    @isPlaying = @wasPlaying = false
                    @trigger 'ended', event
                progress: @handlePlayerLoadedData
                loadeddata: @handlePlayerLoadedData

            @createCustomControls()

            # Need to watch the event-bus to see if other audio is trying to play or if 
            # the activity has begun. Should refactor hide() to be DISABLE instead.
            @listenTo EventBus, 'vocab:audio_play', =>
                @wasPlaying = @isPlaying
                @pause()
            @listenTo EventBus, 'vocab:audio_ended', =>
                @play() if @wasPlaying

        getControlAncestor: ->
            @$ "#resource-jplayer-container-#{@options.playerNumber}"

        stop: () ->
            @$voxyPlayer?.jPlayer 'stop'

        hide: () ->
            @$el.hide 'fast'

        pause: () ->
            @$voxyPlayer?.jPlayer 'pause'

        play: (time) ->
            if time?
                # Only pass the time argument to the player if it's specified,
                # otherwise the player restarts at the beginning.
                @$voxyPlayer?.jPlayer 'play', +time
            else
                @$voxyPlayer?.jPlayer 'play'

        movePlayhead: (time) ->
            currentTime = @voxyPlayerData.status.currentTime
            @$voxyPlayer.jPlayer "play", currentTime + time or 0
            return false

        # Handle the event when slide is moved
        createCustomControls: () ->

            # Need to define this variable for grabbing data
            @voxyPlayerData = @$voxyPlayer.data("jPlayer")

            @customControls =
                progress : @$(".jp-progress-slider")
                volume: @$(".jp-volume-slider")
                rewind: @$(".jp-rewind")
                forward: @$(".jp-ff")

            @customControls.progress.slider
                animate: "fast",
                max: 100,
                range: "min",
                step: 0.1,
                value : 0,
                slide: (event, ui) =>
                  sp = @voxyPlayerData.status.seekPercent
                  if sp > 0
                      # Move the play-head to the value and factor in the seek percent.
                      @$voxyPlayer.jPlayer "playHead", ui.value * (100 / sp)
                      # offset the handle so it doesn't overflow
                      handleWidth = 25
                      offset = handleWidth * (ui.value / 100)
                      $('.ui-slider-handle').css('margin-left', "-" + offset + "px")
                  else
                      # Create a timeout to reset this slider to zero.
                      setTimeout =>
                          @customControls.progress.slider("value", 0)
                      ,0

        skipBackward: () ->
            @movePlayhead -@options.skipTime

        skipForward: () ->
            @movePlayhead @options.skipTime

        handlePlayerLoadedData: (event) =>
            { duration, seekPercent } = event.jPlayer.status

            # IE9 doesn't report the media as fully-loaded until it has started
            # playing, so we want to trigger a play event here so the audio will
            # start playing. The transcript segments will load when `seekPercent`
            # is 100% (or greater... IE reports seek percentages geq 100%.)
            if seekPercent >= 100 and duration > 0
                @mediaDuration = duration

                if not @mediaLoaded
                    @trigger 'mediaLoaded', event
                    @mediaLoaded = true
