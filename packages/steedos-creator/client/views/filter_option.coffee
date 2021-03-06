Template.filter_option.helpers Creator.helpers

Template.filter_option.helpers 
	schema:() -> 
		object_name = Template.instance().data?.object_name
		unless object_name
			object_name = Session.get("object_name")
		template = Template.instance()

		schema_key = template.schema_key.get()
		object_fields = Creator.getObject(object_name).fields

		filter_field_type = object_fields[schema_key]?.type
		schema=
			is_default:
				type: Boolean
				autoform:
					type: "steedos-boolean-checkbox"
			field:
				type: String
				label: "field"
				autoform:
					type: "select"
					defaultValue: ()->
						return "name"
					firstOption: ""
					options: ()->
						Creator.getObjectFilterFieldOptions object_name
			operation:
				type: String
				label: "operation"
				autoform:
					type: "select"
					defaultValue: ()->
						if filter_field_type && Creator.checkFieldTypeSupportBetweenQuery(filter_field_type)
							template.filter_item_operation.set('between')
							return 'between'
						else if ["textarea", "text", "code"].includes(filter_field_type)
							return 'contains'
						else
							return "="
					firstOption: ""
					options: ()->
						if object_fields[schema_key]
							return Creator.getFieldOperation(object_fields[schema_key].type)
						else
							return Creator.getFieldOperation("text")
		
		filter_item_operation = template.filter_item_operation.get()
		isBetweenOperation = Creator.isBetweenFilterOperation(filter_item_operation)
		if isBetweenOperation
			schema.start_value = 
				type: ->
					return template.schema_obj.get()?.type || String
				label: "start_value"
				autoform:
					type: "text"
			
			schema.end_value = _.clone schema.start_value
			schema.end_value.label = "end_value"
		else
			schema.value = 
				type: ->
					return template.schema_obj.get()?.type || String
				label: "value"
				autoform:
					type: "text"

		if schema_key
			new_schema = new SimpleSchema(Creator.getObjectSchema(Creator.getObject(object_name)))
			obj_schema = new_schema._schema
			if isBetweenOperation
				schema.start_value = _.clone obj_schema[schema_key]
				if schema.start_value.autoform
					schema.start_value.autoform = _.clone obj_schema[schema_key].autoform
					schema.start_value.autoform.readonly = false
					schema.start_value.autoform.disabled = false
					schema.start_value.autoform.omit = false
				schema.end_value = _.clone schema.start_value
				schema.end_value.label = "end_value"
				if schema.start_value.autoform
					schema.end_value.autoform = _.clone(schema.start_value.autoform)
			else
				schema.value = _.clone obj_schema[schema_key]
				if ["lookup", "master_detail", "select", "checkbox"].includes(object_fields[schema_key].type)
					schema.value.autoform.multiple = true
					schema.value.type = [String]

					if object_fields[schema_key].type == "select"
						schema.value.autoform.type = "steedosLookups"
						schema.value.autoform.showIcon = false

				if schema.value.autoform
					schema.value.autoform =  _.clone obj_schema[schema_key].autoform
					schema.value.autoform.readonly = false
					schema.value.autoform.disabled = false
					schema.value.autoform.omit = false
					delete schema.value.autoform.defaultValue
				delete schema.value.defaultValue

				if ["widearea", "textarea", "code"].includes(schema.value.autoform?.type)
					schema.value.autoform.type = 'text'

			# 参考【查找时，按日期类型字段来查 有问题 #896】未能实现outFormat功能
			if object_fields[schema_key].type == "date"
				if isBetweenOperation
					if schema.start_value.autoform
						schema.start_value.autoform.outFormat = 'yyyy-MM-dd';
					if schema.end_value.autoform
						schema.end_value.autoform.outFormat = 'yyyy-MM-ddT23:59:59.000Z';
				else
					if schema.value.autoform
						schema.value.autoform.outFormat = 'yyyy-MM-dd';
		new SimpleSchema(schema)

	filter_item: ()->
		# filter_item = Template.instance().data?.filter_item
		filter_item = Template.instance().filter_item?.get()
		return filter_item

	is_show_form: ()->
		filter_item = Template.instance().filter_item?.get()
		schema_key = Template.instance().schema_key?.get()
		if !filter_item.field
			return true
		else
			if schema_key
				return true
			else
				return false

	show_form: ()->
		return Template.instance().show_form.get()

	object_label: ()->
		object_name = Template.instance().data?.object_name
		unless object_name
			object_name = Session.get("object_name")
		return Creator.getObject(object_name).label

	is_scope_selected: (scope)->
		if scope == Session.get("filter_scope")
			return "checked"

	isBetweenOperation: ()->
		filter_item_operation = Template.instance().filter_item_operation.get()
		return Creator.isBetweenFilterOperation(filter_item_operation)

Template.filter_option.events 
	'click .save-filter': (event, template) ->
		fields = Creator.getObject(template.data.object_name).fields
		filter = AutoForm.getFormValues("filter-option").insertDoc
		isDateField = fields[filter.field]?.type == "date"
		unless filter.operation
			toastr.error(t("creator_filter_operation_required_error"))
			return
		isBetweenOperation = Creator.isBetweenFilterOperation(filter.operation)
		if isBetweenOperation
			if filter.start_value > filter.end_value
				toastr.error(t("creator_filter_option_start_end_error"))
				return
			filter.value = [filter.start_value, filter.end_value]
		index = this.index
		filter_items = Session.get("filter_items")
		filter_items[index] = filter

		Session.set("filter_items", filter_items)
		Meteor.defer ->
			Blaze.remove(template.view)

	'click .save-scope': (event, template) ->
		filter_scope = $("input[name='choose-filter-scope']:checked").val()
		Session.set("filter_scope", filter_scope)
		Meteor.defer ->
			Blaze.remove(template.view)

	'change select[name="field"]': (event, template) ->
		object_name = template.data?.object_name
		filter_item = template.filter_item.get()
		unless object_name
			object_name = Session.get("object_name")
		field = $(event.currentTarget).val()
		if field != filter_item?.field
			delete filter_item.operation
			filter_item.value = ""
			template.filter_item.set(filter_item)
			template.filter_item_operation.set(null)
		_schema = Creator.getSchema(object_name)._schema
		template.show_form.set(false)
		template.schema_key.set(field)
		template.schema_obj.set(_schema[field])
		Meteor.defer ->
			template.show_form.set(true)
	
	'change select[name="operation"]': (event, template) ->
		filter_item = template.filter_item.get()
		operation = $(event.currentTarget).val()
		if Creator.isBetweenFilterOperation(operation) || Creator.isBetweenFilterOperation(filter_item?.operation)
			template.filter_item_operation.set(operation)
			filter_item.operation = operation
			filter_item.value = ""
			template.filter_item.set(filter_item)

Template.filter_option.onCreated ->
	is_edit_scope = this.data.is_edit_scope
	unless is_edit_scope
		filter_item = this.data.filter_item
		object_name = this.data.object_name
		unless object_name
			object_name = Session.get("object_name")

		key = filter_item.field
		key_obj = Creator.getSchema(object_name)._schema[key]

		this.schema_key = new ReactiveVar(key)
		this.schema_obj = new ReactiveVar(key_obj)
		this.filter_item_operation = new ReactiveVar(filter_item.operation)
		this.filter_item = new ReactiveVar(filter_item)

		this.show_form = new ReactiveVar(true)