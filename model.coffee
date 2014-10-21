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
          unless @_fields.formData then continue
          
          if @[k] instanceof Model and typeof @[k].getFormData is 'function'
            formData[k] = @[k].getFormData()
          else if @[k] instanceof Array
            formData[k] = []
            
            for i in [0...@[k].length]
              if typeof @[k][i].getFormData is 'function'
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
      
      for k, v of fields
        if !Angular.isObject(v)
          fields[k] = Angular.extend({}, defaults)
          fields[k].type = v
        else
          fields[k] = Angular.extend({}, defaults, v)
      
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
    
    # Set values of the object as an object
    setValues: (values = null) ->
      try
        for k, v of @_fields
          if v is null
            v = ''
          
          # Set default value if available
          if typeof v.default isnt 'undefined'
            def = v.default
          else
            def = null
          
          # Backwards compatibility with shorthands
          if typeof v.type isnt 'undefined'
            type = v.type
          else
            type = v
          
          key = type.toString().split(':')
          
          if typeof values[k] is 'undefined'
            if key[0] is 'Array'
              values[k] = []
            else
              values[k] = def
          
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
          if typeof @[camelCase] is 'function' and camelCase isnt 'setValues'
            @[camelCase](values[k])
            continue
          else if typeof @[setter] is 'function'
            @[setter](values[k])
            continue
          
          switch key[0]
            when 'Array'
              @[k] = []
              if key[1] is 'Object'
                if typeof key[2] isnt 'undefined'
                  className = key[2]
                else
                  className = null
                
                for i in [0...values[k].length]
                  value = values[k][i]
                  
                  if !className
                    obj = value
                  else if typeof window[className] isnt 'undefined'
                    obj = new window[className]
                  else if typeof @_namespace[className] isnt 'undefined'
                    obj = new @_namespace[className](value)
                  @[k].push obj
              else
                @[k] = @typecast values[k], key[1]
            when 'Object'
              if typeof key[1] isnt 'undefined'
                className = key[1]
              else
                className = null
              
              value = values[k]
              if !className
                obj = value
              else if typeof window[className] isnt 'undefined'
                obj = new window[className]
              else if typeof @_namespace[className] isnt 'undefined'
                obj = new @_namespace[className](value)
              @[k] = obj
            else
              @[k] = @typecast values[k], key[0]
        if typeof @updateValues is 'function' then @updateValues()
      catch error
        console.error error.toString()
