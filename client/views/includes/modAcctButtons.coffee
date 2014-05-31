UI.registerHelper "modAcctButtons", ->
    return new Spacebars.SafeString(Template.modAcctButtons)

Template.modAcctButtons.helpers
  profileUrl: ->
    return false unless AccountsEntry.settings.profileRoute
    AccountsEntry.settings.profileRoute

  wrapLinks: ->
    AccountsEntry.settings.wrapLinks
