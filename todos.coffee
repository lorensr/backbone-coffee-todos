$ ->
  ENTER = 13

  class Todo extends Backbone.Model

    defaults: ->
      title: 'empty'
      order: Todos.nextOrder()
      done: false

    initialize: ->
      unless @get 'title'
        @set title: @defaults().title

    toggle: ->
      @save done: !@get 'done'

    clear: ->
      @destroy()

  class TodoList extends Backbone.Collection

    model: Todo

    localStorage: new Store 'todos-backbone'

    done: ->
      @filter (todo) ->
        todo.get 'done'

    remaining: ->
      @without.apply @, @done()

    nextOrder: ->
      if @length
        @last().get 'order' + 1
      else
        1

    comparator: (todo) ->
      todo.get 'order'

  Todos = new TodoList

  class TodoView extends Backbone.View

    tagName: 'li'

    template: _.template $('#item-template').html()

    events:
      'click .toggle'   : 'toggleDone'
      'dblclick .view'  : 'edit'
      'click a.destroy' : 'clear'
      'keypress .edit'  : 'updateOnEnter'
      'blur .edit'      : 'close'

    initialize: ->
      @model.bind 'change', @render
      @model.bind 'destroy', @remove, @

    render: =>
      $(@el).html @template @model.toJSON()
      $(@el).toggleClass 'done', @model.get 'done'
      @input = @.$('.edit');
      @

    toggleDone: ->
      @model.toggle()

    edit: ->
      $(@el).addClass 'editing';
      @input.focus();

    close: ->
      value = @input.val()
      unless value
        @clear()
      @model.save title: value
      $(@el).removeClass 'editing'

    updateOnEnter: (e) ->
      if e.keyCode is ENTER
        @close()

    clear: ->
      @model.clear()

  class AppView extends Backbone.View

    el: $("#todoapp")

    statsTemplate: _.template $('#stats-template').html()

    events:
      'keypress #new-todo':  'createOnEnter'
      'click #clear-completed': 'clearCompleted'
      'click #toggle-all': 'toggleAllComplete'

    initialize: ->
      @input = $ '#new-todo'
      @allCheckbox = $('#toggle-all')[0]

      Todos.bind 'add', @addOne
      Todos.bind 'reset', @addAll
      Todos.bind 'all', @render

      @footer = $ 'footer'
      @main = $ '#main'

      Todos.fetch()

    render: =>
      done = Todos.done().length
      remaining = Todos.remaining().length

      if Todos.length
        @main.show()
        @footer.show()
        @footer.html @statsTemplate {done, remaining}
      else
        @main.hide()
        @footer.hide()

      @allCheckbox.checked = !remaining

    addOne: (todo) =>
      view = new TodoView model: todo
      $('#todo-list').append view.render().el

    addAll: =>
      Todos.each @addOne

    createOnEnter: (e) ->
      if e.keyCode isnt ENTER or !@input.val()
        return

      Todos.create title: @input.val()
      @input.val ''

    clearCompleted: ->
      _.each(Todos.done(), (todo) ->
        todo.clear()
      )
      false

    toggleAllComplete: ->
      done = @allCheckbox.checked
      Todos.each (todo) ->
        todo.save {done}

  App = new AppView
  
      