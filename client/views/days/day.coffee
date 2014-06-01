Template.day.helpers(
  heatmap: ()->
    #me
    me = this.parent.first[this.index]
    dayBeginning = me.timestamp
    dayEnd = me.timestamp + 86400
    mongoQuery = { parent: { $exists: false },  dueDate: { $gte: dayBeginning, $lt: dayEnd} }
    tasks = Tasks.find(mongoQuery, { sort: { due: -1 } }).fetch()
    totalTime = 0
    for task in tasks
      totalTime += task.duration
    color = switch
      when totalTime is 0 then 'free'
      when totalTime < 3601 then 'onehour'
      when totalTime < 7201 then 'twohours'
      when totalTime < 10801 then 'threehours'
      when totalTime < 14401 then 'fourhours'
      else 'fivehours'
    color

  todayTasks: ()->
    me = this.parent.first[this.index]
    dayBeginning = me.timestamp
    dayEnd = me.timestamp + 86400
    # build query
    mongoQuery = { parent: { $exists: false }, dueDate: { $gte: dayBeginning, $lt: dayEnd} }
    # find relevant tasks
    tasks = Tasks.find(mongoQuery, { sort: { due: -1 } }).fetch()
    this.count = tasks.length
    tasks

  today: ()->
    me = this.parent.first[this.index]
    if me.today
      ' TODAY'
    else
      ''

  name: ()->
    me = this.parent.first[this.index]
    me.name

  # taskCount: ()->
  #   # 5 - the number of tasks with a minimum of 1
  #   tmp = 5 - this.count
  #   if tmp <= 0
  #     [0...1]
  #   else
  #     [0...tmp]

)

swapBack = (e, which, timestamp)->
  if which is 'keypress'
    $day = $(e.currentTarget).parent().parent()
  else if which is 'cover'
    $day = $(e.currentTarget).parent()
  else
    console.log 'invalid'
    return

  $herp = $($day.children()[$day.children().length-3])
  $inputter = $($day.children()[$day.children().length-2])
  $cover = $($day.children()[$day.children().length-1])

  # get task info
  taskName = $inputter.children()[0].value
  taskDuration = $inputter.children()[1].value
  if taskName == ''
    # if no name, exit without doing anything
    $herp.show()
    $inputter.hide()
    $cover.hide()
  else
    if taskDuration == ''
      taskDuration = '1 hour'
    task =
      name: taskName
      dueDate: timestamp
      estimate: taskDuration

    # make a new task
    Meteor.call 'makeTask', task, (error, id)->
      if error
        Errors.throw(error.reason)

        if error.error is 302
          Meteor.Router.to('home', error.details)

    # task should be reactively inserted!! :O :O
    # heat should be reactively inserted!!

    # wrap up
    $($inputter.children()[0]).val('')
    $($inputter.children()[1]).val('')
    $herp.show()
    $inputter.hide()
    $cover.hide()

Template.day.events(
  'click .herp': (e)->
    $day = $(e.currentTarget).parent()
    $herp = $($day.children()[$day.children().length-3])
    $inputter = $($day.children()[$day.children().length-2])
    $cover = $($day.children()[$day.children().length-1])
    $herp.hide()
    $inputter.show()
    $inputter.children()[0].focus()
    $cover.show()

  'click .dayInputCover': (e)->
    me = this.parent.first[this.index]
    swapBack(e, 'cover', me.timestamp)

  'keypress .checker': (e)->
    me = this.parent.first[this.index]
    if (e.keyCode == 13)
      swapBack(e, 'keypress', me.timestamp)

)

Template.day.rendered = ()->
  me = this.data.parent.first[this.data.index]
  timestamp = me.timestamp
  $(this.find('.day')).droppable(
    accept: '.day .task'
    activeClass: 'ui-state-hover'
    hoverClass: 'ui-state-active'
    drop: (event, ui)->
      id = ui.draggable.attr('id')
      Tasks.update {_id: id}, { $set: { dueDate: timestamp + 43200 }}
  )
