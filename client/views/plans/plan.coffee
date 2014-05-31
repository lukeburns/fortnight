Template.plan.helpers(
  checked: ()->
    plan = Tasks.findOne( { _id: @_id })
    if plan.completed is true
      'checked'
    else
      ''
)

Template.plan.events(
  'click .toggle': (e)->
    checked = $(e.currentTarget).next().hasClass('checked')

    unless checked
      # submit check
      Meteor.call('completeTask', @_id)
    else
      # submit uncheck
      Meteor.call('uncompleteTask', @_id)

  'click .deletePlan':(e)->
    Meteor.call('deleteTask', @_id)

)
