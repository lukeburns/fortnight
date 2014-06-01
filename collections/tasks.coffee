@Tasks = new Meteor.Collection 'tasks'

Tasks.allow(
  update: ownsDocument
  remove: ownsDocument
)

Meteor.methods(
  makeTask: (taskAttributes)->
    user = Meteor.user()

    if taskAttributes.parent
      parent = Tasks.findOne({_id: taskAttributes.parent})

      # May not want the following if one wants to allocate multiple plans from a single task,
      # which will be useful when scheduling is implemented.
      #
      # taskWithSameDate = Tasks.findOne(
      #   dueDate: taskAttributes.dueDate + 43200
      #   parent: taskAttributes.parent
      # )
      #
      # if taskWithSameDate
      #   console.log 'Plan already exists!'
      #   return
      #   # TODO: Gracefully handle error popups
      #   # throw new Meteor.Error(302, 'Plan already exists!', planWithSameDate._id)

      taskAttributes.name = parent.name if !taskAttributes.name?

    # user must be logged in
    if not user
      throw new Meteor.Error(401, "You need to log in to create tasks")
    # task must have a name
    if not taskAttributes.name
      throw new Meteor.Error(422, "Please fill in task name")
    # this should not be possible
    if not taskAttributes.dueDate
      throw new Meteor.Error(422, "How did you even do that?")
    # set default task estimate time
    if not taskAttributes.estimate
      taskAttributes.estimate = '1 hour'

    # convert estimate to seconds
    taskAttributes.duration = parseDuration(taskAttributes.estimate)

    console.log(taskAttributes)

    task = _.extend(_.pick(taskAttributes, 'name', 'dueDate', 'estimate', 'duration', 'parent'),
      userId: user._id
      completed: false
      children: []
    )

    task.dueDate += 43200 # put it in the middle of the day because fuck DST

    taskId = Tasks.insert(task)

    if(parent)
      Tasks.update({_id: taskAttributes.parent}, {$push: {children: taskId}})

    taskId

  completeTask: (taskId)->
    user = Meteor.user()
    if not user
      throw new Meteor.Error(401, "You need to login to complete a task")

    Tasks.update({
      _id: taskId
    },{
      $set: {completed: true}
    })

  uncompleteTask: (taskId)->
    user = Meteor.user()
    if not user
      throw new Meteor.Error(401, "You need to login to uncomplete a task")

    Tasks.update({
      _id: taskId
    },{
      $set: {completed: false}
    })

  update: (taskId, new_name, new_estimate)->
    user = Meteor.user()
    if not user
      throw new Meteor.Error(401, "You need to login to uncomplete a task")

    if new_name is ''
      throw new Meteor.Error(422, "Please fill in task name")
    if new_estimate is ''
      new_estimate = '1 hour'
      new_duration = 3600
    else
      new_duration = parseDuration(new_estimate)

    Tasks.update({
      _id: taskId
    },{
      $set: {name: new_name, duration: new_duration, estimate: new_estimate}
    })

  deleteTask: (taskId)->
    user = Meteor.user()
    if not user
      throw new Meteor.Error(401, "You need to login to delete a task")

    # Remove children
    task = Tasks.findOne({_id: taskId});
    if task.children?
      task.children.forEach (child) ->
        Meteor.call('deleteTask', child)

    # Abandon parents
    Tasks.update({children: taskId}, {$pull: {children: taskId}})

    # Remove self
    Tasks.remove({_id: taskId})

)

# From http://sj26.com/2011/04/20/parse-natural-duration-javascript
# TODO: Write a better one
parseDuration = (duration) ->

  # .75
  if match = /^\.\d+$/.exec(duration)
    parseFloat("0" + match[0]) * 3600

  # 4 or 11.75
  else if match = /^\d+(?:\.\d+)?$/.exec(duration)
    parseFloat(match[0]) * 3600

  # 01:34
  else if match = /^(\d+):(\d+)$/.exec(duration)
    (parseInt(match[1]) or 0) * 3600 + (parseInt(match[2]) or 0) * 60

  # 1h30m or 7 hrs 1 min and 43 seconds
  else if match = /(?:(\d+)\s*d(?:ay?)?s?)?(?:(?:\s+and|,)?\s+)?(?:(\d+)\s*h(?:(?:ou)?rs?)?)?(?:(?:\s+and|,)?\s+)?(?:(\d+)\s*m(?:in(?:utes?))?)?(?:(?:\s+and|,)?\s+)?(?:(\d)\s*s(?:ec(?:ond)?s?)?)?/.exec(duration)
    (parseInt(match[1]) or 0) * 86400 + (parseInt(match[2]) or 0) * 3600 + (parseInt(match[3]) or 0) * 60 + (parseInt(match[4]) or 0)

  # Unknown!
  else
    3600
