Creator.Objects.vip_billing =
	name: "vip_billing"
	label: "消费记录"
	icon: "apps"
	fields:
		amount:
			label:'消费金额'
			type:'number'
			scale: 2
		location:
			label:'位置'
			type:'location'
		store:
			label:'门店'
			type:'lookup'
			reference_to:'vip_store'
		card:
			label:'会员卡'
			type:'master_detail'
			reference_to:'vip_card'
		description:
			label:'备注'
			type:'textarea'
		balance:
			label: '余额'
			type: 'number'
			scale: 2
			omit: true
			hidden: true
	list_views:
		all:
			label: "消费记录"
			columns: ["card", "store", "amount","description"]
			filter_scope: "space"