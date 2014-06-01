Template.planday.helpers(
  todayPlans: ()->
    me = this.parent.first[this.index]
    # `this` is the data object passed from day
    dayBeginning = me.timestamp
    dayEnd = me.timestamp + 86400
    # build query
    mongoQuery = { parent: {$exists: true}, dueDate: { $gte: dayBeginning, $lt: dayEnd} }
    # find relevant tasks
    plans = Tasks.find(mongoQuery, { sort: { dueDate: -1 } }).fetch()
    plans

  name: ()->
    me = this.parent.first[this.index]
    me.name
)

Template.planday.rendered = ()->
  me = this.data.parent.first[this.data.index]
  timestamp = me.timestamp
  $(this.find('.planday')).droppable(
    activeClass: 'ui-state-hover'
    hoverClass: 'ui-state-active'
    drop: (event, ui)->
      id = ui.draggable.attr('id')
      if ui.draggable.parent().hasClass('planday')
        Tasks.update {_id: id}, { $set: { dueDate: timestamp + 43200 }}
      else
        plan =
          parent: id
          dueDate: timestamp
        Meteor.call('makeTask', plan, (error,id)->
          if error
            Errors.throw(error.reason)

            if error.error is 302
              Meteor.Router.to('home', error.details)
        )
  )
