Creator.Objects.love_invite_codes =
	name: "love_invite_codes"
	label: "邀请码表"
	icon: "event"
	enable_search: true
	fields:
		code:
			type:'text'
			label:"邀请码"
		expired:
			type:'datetime'
			label:"截止日期"
	list_views:
		all:
			label: "所有"
			columns: ["code", "expired", "owner"]
			filter_scope: "space"
		
	permission_set:
		user:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: false
			modifyAllRecords: false
			viewAllRecords: false
		admin:
			allowCreate: true
			allowDelete: true
			allowEdit: true
			allowRead: true
			modifyAllRecords: true
			viewAllRecords: true
		member:
			allowCreate: false
			allowDelete: false
			allowEdit: true
			allowRead: true
			modifyAllRecords: false
			viewAllRecords: false
		guest:
			allowCreate: false
			allowDelete: false
			allowEdit: false
			allowRead: false
			modifyAllRecords: false
			viewAllRecords: false