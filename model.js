// Generated by CoffeeScript 1.8.0
(function() {
  define([], function() {
    var Model;
    return Model = (function() {
      Model.prototype._fields = {
        id: {
          type: 'Number',
          value: 0
        }
      };


      /*
      Namespace that maps field type name into an object
      
      Usage:
        _namespace:
          "Person": Person
      
      where the type defined in _fields corresponds namespace key and class
      (with adjacent constructor) is its value.
       */

      Model.prototype._namespace = {};


      /*
      Constructor accepts object data as the only constructor argument. Object
      keys should correspond to the keys defined in Model._fields or they will
      be automatically skipped. Values will be typecasted whenever possible.
      
      Usage:
      
      new Model({id: 1, name: "foobar", title: "Foobar"})
       */

      function Model(opts) {
        if (opts == null) {
          opts = null;
        }
        this._fields = this.getFields();
        if (!opts) {
          opts = {};
        }
        this.setValues(opts);
        this.getFormData = function() {
          var fn, formData, i, k, v, _i, _ref, _ref1;
          formData = {};
          _ref = this._fields;
          for (k in _ref) {
            v = _ref[k];
            if (!v.formData) {
              continue;
            }
            fn = "get" + k.substr(0, 1).toUpperCase() + k.substr(1) + "Value";
            if (typeof this[fn] === 'function' || typeof this.__proto__[fn] === 'function') {
              formData[k] = this[fn]();
              continue;
            }
            if (this[k] instanceof Model && typeof this[k].getFormData === 'function') {
              formData[k] = this[k].getFormData();
            } else if (this[k] instanceof Array) {
              formData[k] = [];
              for (i = _i = 0, _ref1 = this[k].length; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
                if (typeof this[k][i].getFormData === 'function' || typeof this[k][i].__proto__.getFormData === 'function') {
                  formData[k].push(this[k][i].getFormData());
                } else {
                  formData[k].push(this[k][i]);
                }
              }
            } else if (k.type === 'Boolean') {
              if (this[k]) {
                formData[k] = 1;
              } else {
                formData[k] = 0;
              }
            } else {
              formData[k] = this[k];
            }
          }
          if (typeof this.getFormDataPostProcess !== 'undefined') {
            this.getFormDataPostProcess(formData);
          }
          return formData;
        };
        this.validateData = function() {
          var errors, k, v, value, _ref;
          errors = [];
          _ref = this._fields;
          for (k in _ref) {
            v = _ref[k];
            value = this[k];
            if (value && (typeof value.validateForm === 'function' || typeof typeof value.__proto__.validateForm === 'function')) {
              errors.concat(value.validateForm());
              continue;
            }
            if (v.required && !value) {
              errors.push({
                object: this,
                key: k,
                value: value,
                error: 'required'
              });
              continue;
            }
            if (v.validation && value && !value.match(v.validation)) {
              errors.push({
                object: this,
                key: k,
                value: value,
                error: 'validation failed'
              });
            }
          }
          return errors;
        };
      }

      Model.prototype.getFields = function() {
        var Angular, defaults, fields, fn, k, v;
        Angular = window.angular;
        if (typeof this._fields === 'undefined' || !Angular.isObject(this._fields)) {
          fields = {};
        } else {
          fields = this._fields;
        }
        defaults = {
          type: null,
          nullable: true,
          "default": null,
          formData: true,
          required: false,
          validation: null,
          serialize: null
        };
        for (k in fields) {
          v = fields[k];
          if (!Angular.isObject(v)) {
            fields[k] = Angular.extend({}, defaults);
            fields[k].type = v;
          } else {
            fields[k] = Angular.extend({}, defaults, v);
          }
          if (typeof fields[k].serialize === 'function') {
            fn = "get" + k.substr(0, 1).toUpperCase() + k.substr(1) + "Value";
            this.__proto__[fn] = fields[k].serialize;
          }
        }
        return fields;
      };

      Model.prototype.getType = function(field) {
        var type;
        if (typeof this._fields[field] === 'undefined') {
          throw new Error("Field '" + field + "' is undefined");
        }
        if (typeof this._fields[field].type !== 'undefined') {
          return this._fields[field].type;
        }
        type = this._fields[field].toString();
        switch (true) {
          case type.match(/^null$/):
            return 'null';
          case type.match(/^array/i):
            return 'array';
          case type.match(/^object:/i):
            return type.replace(/object:/i, '');
          default:
            return type;
        }
      };

      Model.prototype.typecast = function(value, type) {
        switch (type) {
          case 'Number':
            if (value) {
              value = Number(value);
            }
            break;
          case 'String':
            if (value) {
              value = String(value);
            }
            break;
          case 'Boolean':
            value = !!value;
        }
        return value;
      };

      Model.prototype.setValues = function(values) {
        var camelCase, capitalized, className, def, error, i, k, key, obj, setter, t0, t1, type, v, value, _i, _ref, _ref1;
        if (values == null) {
          values = null;
        }
        try {
          _ref = this._fields;
          for (k in _ref) {
            v = _ref[k];
            if (v === null) {
              v = '';
            }
            if (typeof v["default"] !== 'undefined') {
              def = v["default"];
            } else {
              def = null;
            }
            if (typeof v.type !== 'undefined') {
              type = v.type;
            } else {
              type = v;
            }
            key = type.toString().split(':');
            if (typeof values[k] === 'undefined') {
              if (key[0] === 'Array') {
                values[k] = [];
              } else {
                values[k] = def;
              }
            }
            t0 = key[0];
            if (typeof this._namespace[t0] !== 'undefined') {
              key = ['Object', t0];
            }
            if (typeof key[1] === 'undefined') {
              t1 = '';
            } else {
              t1 = key[1];
            }
            if (t0 === 'Array' && typeof this._namespace[t1] !== 'undefined') {
              key = ['Array', 'Object', t1];
            }
            capitalized = k.toString().substring(0, 1).toUpperCase() + k.toString().substring(1);
            setter = "set" + k;
            camelCase = 'set' + capitalized;
            if ((typeof this[camelCase] === 'function' || typeof this.__proto__[camelCase] === 'function') && camelCase !== 'setValues') {
              this[camelCase](values[k]);
              continue;
            } else if (typeof this[setter] === 'function' || typeof this.__proto__[setter] === 'function') {
              this[setter](values[k]);
              continue;
            }
            switch (key[0]) {
              case 'Array':
                this[k] = [];
                if (key[1] === 'Object') {
                  if (typeof key[2] !== 'undefined') {
                    className = key[2];
                  } else {
                    className = null;
                  }
                  for (i = _i = 0, _ref1 = values[k].length; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
                    value = values[k][i];
                    if (!className) {
                      obj = value;
                    } else if (typeof window[className] !== 'undefined') {
                      obj = new window[className];
                    } else if (typeof this._namespace[className] !== 'undefined') {
                      obj = new this._namespace[className](value);
                    }
                    this[k].push(obj);
                  }
                } else {
                  this[k] = this.typecast(values[k], key[1]);
                }
                break;
              case 'Object':
                if (typeof key[1] !== 'undefined') {
                  className = key[1];
                } else {
                  className = null;
                }
                value = values[k];
                if (!className) {
                  obj = value;
                } else if (typeof window[className] !== 'undefined') {
                  obj = new window[className];
                } else if (typeof this._namespace[className] !== 'undefined') {
                  obj = new this._namespace[className](value);
                }
                this[k] = obj;
                break;
              default:
                this[k] = this.typecast(values[k], key[0]);
            }
          }
          if (typeof this.updateValues === 'function' || typeof this.__proto__.updateValues === 'function') {
            return this.updateValues();
          }
        } catch (_error) {
          error = _error;
          return console.error(error.toString());
        }
      };

      return Model;

    })();
  });

}).call(this);

//# sourceMappingURL=model.js.map
