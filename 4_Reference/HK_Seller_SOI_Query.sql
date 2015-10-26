	select
		 so.order_nr
		,soi.bob_id_sales_order_item
		,scsoi.id_sales_order_item as SC_id_sales_order_item
		,scseller.short_code as SC_ID
		,scseller.name as Seller
		,soi.sku
		,soi.name as description
		,soi.unit_price
		,soi_status.name as soi_status
		,cancel_reason.name as cancel_reason
		,so_process.name as payment
		,venture.name as country
		,if(max(soi_rts.created_at) is not null,'ready to ship',null) as rst_status
		,if(max(soi_ship.created_at) is not null,'shipped',null) as ship_status
		,user_ship.username as user_ship
		,if(max(soi_deliver.created_at) is not null,'delivered',null) as deliver_status
		,user_deliver.username as user_deliver
		,if(max(soi_cancel.created_at) is null,null,'canceled') as cancel_status
		,if(max(soi_brt.created_at) is not null,'being_returned',null) as being_returned_status
		,if(max(soi_ret.created_at) is not null,'returned',null) as returned_status
		,pacd.tracking_number
		,ship_com.shipment_provider_name
		,merchant.name as merchant_name
        ,scseller.src_id as bob_id_merchant
		,pac.package_number
		-- FOR CALCULATION
		,soi.created_at as date_create
		,max(soi_hmp.created_at) as date_hmp
		,max(soi_rts.created_at) as date_rts
		,max(soi_cancel.created_at) as date_cancel
		,max(soi_fail.created_at) as date_fail
		,max(soi_ship.created_at) as date_ship
		,ifnull(soi.real_delivery_date,(soi_deliver.created_at)) as date_deliver
		,max(soi_hist.created_at) as date_last_status
		,if(cust_resp.fk_package is null, 'No Response',if(is_deliverd = 1,'Yes','No')) as 'Response'
		,cust_resp.created_at as date_cust_resp
	from ims_sales_order_item as soi
	inner join ims_supplier as merchant on merchant.bob_id_supplier = soi.fk_marketplace_merchant
	inner join screport.seller as scseller on scseller.src_id = soi.fk_marketplace_merchant and scseller.tax_class = 'international'
	left join screport.sales_order_item scsoi on scsoi.src_id=soi.id_sales_order_item
	inner join ims_sales_order_item_status as soi_status on soi_status.id_sales_order_item_status = soi.fk_sales_order_item_status
	inner join ims_sales_order_item_status_history as soi_ov
		on soi_ov.fk_sales_order_item = soi.id_sales_order_item
		and soi_ov.fk_sales_order_item_status = 67 -- finance_verified
	inner join ims_sales_order as so on so.id_sales_order = soi.fk_sales_order
		left join ims_sales_order_process as so_process on so_process.id_sales_order_process = so.fk_sales_order_process
	left join ims_cancel_reason as cancel_reason on cancel_reason.id_cancel_reason = soi.fk_cancel_reason
	left join ims_sales_order_item_status_history as soi_rts
		on soi_rts.fk_sales_order_item = soi.id_sales_order_item
		and soi_rts.fk_sales_order_item_status = 84 -- ready_to_ship_by_marketplace
	left join ims_sales_order_item_status_history as soi_hmp
		on soi_hmp.fk_sales_order_item = soi.id_sales_order_item
		and soi_hmp.fk_sales_order_item_status = 71 -- handled_by_marketplace
	left join ims_sales_order_item_status_history as soi_ship
		on soi_ship.fk_sales_order_item = soi.id_sales_order_item 
		and soi_ship.fk_sales_order_item_status = 5 -- shipped
	left join ims_user as user_ship 
		on user_ship.id_user = soi_ship.fk_user
	left join ims_sales_order_item_status_history as soi_cancel
		on soi_cancel.fk_sales_order_item = soi.id_sales_order_item
		and soi_cancel.fk_sales_order_item_status = 9 -- canceled
	left join ims_sales_order_item_status_history as soi_deliver
		on soi_deliver.fk_sales_order_item = soi.id_sales_order_item
		and soi_deliver.fk_sales_order_item_status = 27 -- delivered
	left join ims_user as user_deliver
		on user_deliver.id_user = soi_deliver.fk_user
	left join ims_sales_order_item_status_history as soi_brt
		on soi_brt.fk_sales_order_item = soi.id_sales_order_item
		and soi_brt.fk_sales_order_item_status = 68 -- being_returned
	left join ims_sales_order_item_status_history as soi_ret
		on soi_ret.fk_sales_order_item = soi.id_sales_order_item
		and soi_ret.fk_sales_order_item_status in (8) -- returned
	left join ims_sales_order_item_status_history as soi_fail
		on soi_fail.fk_sales_order_item = soi.id_sales_order_item
		and soi_fail.fk_sales_order_item_status in (44) -- not_delivered
	left join ims_sales_order_item_status_history as soi_hist
		on soi_hist.fk_sales_order_item = soi.id_sales_order_item
	left join oms_package_item as paci
		on paci.fk_sales_order_item = soi.id_sales_order_item and paci.isdeleted = 0
	left join oms_package as pac
		on pac.id_package = paci.fk_package -- and pac.isdeleted = 0
	left join oms_package_dispatching as pacd
		on pacd.fk_package = pac.id_package
	left join oms_customer_feedback_package_delivery as cust_resp
		on cust_resp.fk_package = pac.id_package
	left join oms_shipment_provider as ship_com
		on ship_com.id_shipment_provider = pacd.fk_shipment_provider
	inner join (select name from oms_country where is_default = 1 limit 1) as venture on 0=0
	where date(soi.created_at) >= date(date_sub(current_timestamp(),interval 2 month)) and date(soi.created_at) < date(current_timestamp())
	group by bob_id_sales_order_item