window.SSN = {} unless SSN?

SSN.Analytics =
    settings:
        yandex: '22464010'

    trackEvent: (event) ->
        #yandex
        yandexEvent = event.category+'_'+event.action.replace(/\s+/g, '_')
        yandexEvent+= '_'+event.label if event.label

        yaCounter = window['yaCounter'+@settings.yandex]
        yaCounter.reachGoal(yandexEvent, {value: (event.value || 0)})
