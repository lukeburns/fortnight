Template.task.helpers(
  # return 'checked' if task is completed
  # return nothing is task is incomplete
  checked: ()->
    task = Tasks.findOne({ _id: @_id })
    if task.completed is true
      'checked'
    else
      ''

  parentId: ->
    this.parent

)

Template.task.events(
  'mouseover': (e)->
    family = $(e.target).parents('.task').data('family');
    if family
      $.each family.split(' '), (i, sibling)->
        siblingElements = $('*[data-family*='+sibling+']')
        siblingElements.addClass('family-highlight')

        estimate = siblingElements.each (i, siblingElement)->
          estimate = $(siblingElement).find('.estimateEdit').val();
          duration = parseDuration(estimate);
          $(siblingElement).addClass(color(duration));

    $('td .color').addClass('over');


  'mouseout': (e)->
    $('.family-highlight').removeClass('free onehour twohours threehours fourhours fivehours'); # use jquery's hover and toggleClass instead?
    $('.family-highlight').removeClass('family-highlight')
    $('td .color').removeClass('over');

  'click .toggle': (e)->
    checked = $(e.currentTarget).next().hasClass('checked')

    unless checked
      # submit check
      Meteor.call('completeTask', @_id)
    else
      # submit uncheck
      Meteor.call('uncompleteTask', @_id)

  'dblclick .taskName': (e)->
    $this_el = $(e.currentTarget).parent()
    $task_name = $($this_el.children()[1])
    $edit_field = $($this_el.children()[2])
    $input_cover = $($this_el.children()[3])
    if $edit_field.css('display','none')
      $task_name.hide()
      $edit_field.show()
      $input_cover.show()
      $edit_field.focus()

  'click .taskInputCover': (e)->
    swapBack(this, e, 'cover')

  'keypress .nameEdit': (e)->
    if (e.keyCode == 13)
      swapBack(this, e, 'key')

  'keypress .estimateEdit': (e)->
    if (e.keyCode == 13)
      swapBack(this, e, 'key')

  'click .deleteTask':(e)->
    Meteor.call('deleteTask', @_id)
)

swapBack = (task, event, which)->
  if which is 'cover'
    $this_el = $(event.currentTarget).parent()
  else
    $this_el = $(event.currentTarget).parent().parent()

  ho = $this_el.children()
  $task_name = $(ho[1])
  $edit_fields = $(ho[2])
  $input_cover = $(ho[3])

  new_name = $($edit_fields.children()[0])
  new_estimate = $($edit_fields.children()[1])

  Meteor.call('update', task._id, new_name.val(), new_estimate.val())
  $task_name.show()
  $edit_fields.hide()
  $input_cover.hide()

Template.task.rendered = ()->
  # $(this.find('.task')).sortable()
  # $(this.find('.task')).parent().selectable({ filter: '.task' })
  $(this.find('.task')).draggable(
    revert: true
    revertDuration: 0
    # multiple: true
  )

color = (time) ->
  switch
    when time is 0 then 'free'
    when time < 3601 then 'onehour'
    when time < 7201 then 'twohours'
    when time < 10801 then 'threehours'
    when time < 14401 then 'fourhours'
    else 'fivehours'

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