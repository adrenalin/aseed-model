define [], () ->
  class Model
    _fields:
      id:
        type: 'Number'
        value: 0
    
    ###
    Namespace that maps field type name into an object
    
    Usage:
      _namespace:
        "Person": Person
    
    where the type defined in _fields corresponds namespace key and class
    (with adjacent constructor) is its value.
    ###
    _namespace: {}
    
    ###
    Constructor accepts object data as the only constructor argument. Object
    keys should correspond to the keys defined in Model._fields or they will
    be automatically skipped. Values will be typecasted whenever possible.
    
    Usage:
    
    new Model({id: 1, name: "foobar", title: "Foobar"})
    ###
    constructor: (opts = null) ->
      @_fields = @getFields()
      
      unless opts then opts = {}
      
      # Set values given as a constructor argument
      @setValues(opts)
      
      # Get form data for form submissions
      @getFormData = ->
        formData = {}
        
        for k, v of @_fields
          unless v.formData then continue
          
          # Custom override function
          fn = "get" + k.substr(0, 1).toUpperCase() + k.substr(1) + "Value"
          if typeof @[fn] is 'function' or typeof @__proto__[fn] is 'function'
            formData[k] = @[fn]()
            continue
          
          if @[k] instanceof Model and typeof @[k].getFormData is 'function'
            formData[k] = @[k].getFormData()
          else if @[k] instanceof Array
            formData[k] = []
            
            for i in [0...@[k].length]
              if typeof @[k][i].getFormData is 'function' or typeof @[k][i].__proto__.getFormData is 'function'
                formData[k].push @[k][i].getFormData()
              else
                formData[k].push @[k][i]
          else if k.type is 'Boolean'
            if @[k]
              formData[k] = 1
            else
              formData[k] = 0
          else
            formData[k] = @[k]
        
        # Allow model based post process hooks
        if typeof @getFormDataPostProcess isnt 'undefined'
          @getFormDataPostProcess(formData)
        
        return formData
      
      @validateData = ->
        errors = []
        
        for k, v of @_fields
          value = @[k]
          
          if value and (typeof value.validateForm is 'function' or typeof typeof value.__proto__.validateForm is 'function')
            errors.concat(value.validateForm())
            continue
          
          if v.required and !value
            errors.push {
              object: @
              key: k
              value: value
              error: 'required'
            }
            continue
          
          if v.validation and value and !value.match(v.validation)
            errors.push {
              object: @
              key: k
              value: value
              error: 'validation failed'
            }
        return errors
    
    # Get fields
    getFields: () ->
      Angular = window.angular
      
      if typeof @_fields is 'undefined' or !Angular.isObject(@_fields)
        fields = {}
      else
        fields = @_fields
      
      defaults =
        type: null
        nullable: true
        default: null
        formData: true
        required: false
        validation: null
        serialize: null
      
      for k, v of fields
        if !Angular.isObject(v)
          fields[k] = Angular.extend({}, defaults)
          fields[k].type = v
        else
          fields[k] = Angular.extend({}, defaults, v)
        
        if typeof fields[k].serialize is 'function'
          fn = "get" + k.substr(0, 1).toUpperCase() + k.substr(1) + "Value"
          @__proto__[fn] = fields[k].serialize
      
      return fields
    
    # Get field type
    getType: (field) ->
      throw new Error("Field '#{field}' is undefined") if typeof @_fields[field] is 'undefined'
      
      if typeof @_fields[field].type isnt 'undefined' then return @_fields[field].type
      
      type = @_fields[field].toString()
      
      # Return type
      switch true
        when type.match(/^null$/) then return 'null'
        when type.match(/^array/i) then return 'array'
        when type.match(/^object:/i) then return type.replace(/object:/i, '')
        else return type
    
    # Typecast values
    typecast: (value, type) ->
      # Typecasting
      switch type
        when 'Number'
          if value then value = Number(value)
        when 'String'
          if value then value = String(value)
        when 'Boolean'
          value = !!(value)
      return value
    
    # Clone model object with optional recursive flag. When the cloning is not recursive, inner model objects will
    # be kept with the original pointers to the original objects. In a recursive copy the child objects will also
    # be cloned.
    clone: (recursive = false) ->
      return @__proto__.cloneModel(recursive)
    
    cloneModel: (recursive) ->
      data = {}
      
      for k, v of @_fields
        if k is 'id' then continue
        
        if typeof v.clone is 'function'
          data[k] = v.clone()
        else if v.clone is 'false'
          data[k] = null
        else
          data[k] = @cloneNode(v, recursive)
      
      clone = new @constructor(data)
      return clone
    
    cloneNode: (node, recursive) ->
      switch (typeof node).toLowerCase()
        when 'array'
          rval = []
          for i in [0...node.length]
            rval.push @cloneNode(node[i])
        else
          return node
            
      return node
    
    setValue: (k, value) ->
      # Get field information
      if typeof @_fields[k] isnt 'undefined'
        v = @_fields[k]
      else
        v = {}
      
      # Backwards compatibility with shorthands
      if typeof v.type isnt 'undefined'
        type = v.type
      else
        type = v
      
      key = type.toString().split(':')
      
      # Normalize for arrays and when key[1] is in namespace. This
      # convention provides backwards compatibility for older
      # projects
      t0 = key[0]
      
      if typeof @_namespace[t0] isnt 'undefined'
        key = [
          'Object'
          t0
        ]
      
      # Normalize when key[0] is in namespace
      if typeof key[1] is 'undefined'
        t1 = ''
      else
        t1 = key[1]
      if t0 is 'Array' and typeof @_namespace[t1] isnt 'undefined'
        key = [
          'Array'
          'Object'
          t1
        ]
      
      capitalized = k.toString().substring(0, 1).toUpperCase() + k.toString().substring(1)
      setter = "set#{k}"
      camelCase = 'set' + capitalized
      
      # Use setter if applicable
      if (typeof @[camelCase] is 'function' or typeof @__proto__[camelCase] is 'function') and camelCase isnt 'setValues'
        @[camelCase](value)
        return
      else if typeof @[setter] is 'function' or typeof @__proto__[setter] is 'function'
        @[setter](value)
        return
      
      switch key[0]
        when 'Array'
          @[k] = []
          if key[1] is 'Object'
            if typeof key[2] isnt 'undefined'
              className = key[2]
            else
              className = null
            
            for i in [0...value.length]
              val = value[i]
              
              if !className
                obj = val
              else if typeof window[className] isnt 'undefined'
                obj = new window[className]
              else if typeof @_namespace[className] isnt 'undefined'
                obj = new @_namespace[className](val)
              @[k].push obj
          else
            @[k] = @typecast value, key[1]
        when 'Object'
          if typeof key[1] isnt 'undefined'
            className = key[1]
          else
            className = null
          
          if !className
            obj = value
          else if typeof window[className] isnt 'undefined'
            obj = new window[className]
          else if typeof @_namespace[className] isnt 'undefined'
            obj = new @_namespace[className](value)
          @[k] = obj
        else
          @[k] = @typecast value, key[0]
    
    # Set values of the object as an object
    setValues: (values = null) ->
      try
        for k, v of @_fields
          if typeof values[k] isnt 'undefined'
            value = values[k]
          else if typeof v.default isnt 'undefined'
            value = v.default
          else
            value = null
          @setValue(k, value)
        if typeof @updateValues is 'function' or typeof @__proto__.updateValues is 'function'
          @updateValues()
      catch error
        console.error error.toString()
