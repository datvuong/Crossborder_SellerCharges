SELECT DISTINCT
	 so.order_nr
	,soi.id_sales_order_item
	,scsoi.id_sales_order_item SC_SOI_ID
	,if(soi.fk_marketplace_merchant is null, 
		 'Retail', 'MP') business_unit
	,soi.sku
	,REPLACE(REPLACE(soi.name,'\n',''), ',', ' ') description
	,soi.unit_price
	,itemStatus.name Item_Status
	,shipped.created_at Shipped_Date
	,cancelled.created_at Cancelled_Date
	,delivered.created_at Delivered_Date
	,pkgDispatch.tracking_number
	,pkg.package_number
	,REPLACE(deliveryCompany.shipment_provider_name,',',' ') shipment_provider_name
	,seller.short_code 'Seller_Code'
	,seller.name 'Seller'
	,seller.tax_class
FROM oms_live.ims_sales_order_item soi
LEFT JOIN screport.sales_order_item scsoi ON soi.id_sales_order_item=scsoi.src_id
LEFT JOIN screport.seller seller ON scsoi.fk_seller=seller.id_seller
INNER JOIN oms_live.ims_sales_order so ON soi.fk_sales_order=so.id_sales_order
INNER JOIN oms_live.ims_sales_order_item_status itemStatus ON soi.fk_sales_order_item_status=itemStatus.id_sales_order_item_status
INNER JOIN oms_live.ims_sales_order_item_status_history rts ON soi.id_sales_order_item=shipped.fk_sales_order_item AND shipped.fk_sales_order_item_status IN (50,76)
LEFT JOIN oms_live.ims_sales_order_item_status_history shipped ON soi.id_sales_order_item=shipped.fk_sales_order_item AND shipped.fk_sales_order_item_status=5
LEFT JOIN oms_live.ims_sales_order_item_status_history delivered ON soi.id_sales_order_item=delivered.fk_sales_order_item AND delivered.fk_sales_order_item_status=27
LEFT JOIN oms_live.ims_sales_order_item_status_history cancelled ON soi.id_sales_order_item=cancelled.fk_sales_order_item AND cancelled.fk_sales_order_item_status=9
INNER JOIN oms_live.oms_package_item pkgItem ON soi.id_sales_order_item=pkgItem.fk_sales_order_item
INNER JOIN oms_live.oms_package pkg ON pkgItem.fk_package=pkg.id_package
INNER JOIN oms_live.oms_package_dispatching pkgDispatch ON pkg.id_package=pkgDispatch.fk_package
INNER JOIN oms_live.oms_shipment_provider deliveryCompany ON pkgDispatch.fk_shipment_provider=deliveryCompany.id_shipment_provider
WHERE 
	(cancelled.created_at between '2015-09-01' and '2015-09-30' OR
		delivered.created_at between '2015-09-01' and '2015-09-30')AND
	soi.fk_marketplace_merchant is NOT NULL AND
	seller.tax_class='international'