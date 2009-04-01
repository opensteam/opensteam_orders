module OrdersHelper


# sidebar navigation for orders
def order_navigation( order, opts = {} )
  active = opts[:active] || :general
  content_tag( :div, t(:order) + " Information", { :class => "dvEditorNaviHeadline" } ) +
    content_tag( :div, { :class => "dvEditorNaviItems" } ) do
  	link_to( t(:general_information), admin_sales_order_path( order ), :id => "general", :class => nav_link_class(active, :general) ) +
  	
  	Opensteam::Extension.extensions_for( :order ).collect { |ext| 
  	  link_to( t(ext.id), [:admin, :sales, order, ext.id ], :class => nav_link_class( active, ext.id ) )
  	}.join(" " )
#      link_to( t(:invoices), admin_sales_order_invoices_path( order ), :class => nav_link_class(active, :invoices ) ) +
#      link_to( t(:shipments), admin_sales_order_shipments_path( order ), :class => nav_link_class(active, :shipments ) )
  end
end

end