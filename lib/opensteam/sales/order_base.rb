#	openSteam - http://www.opensteam.net
#  Copyright (C) 2009  DiamondDogs Webconsulting
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

module Opensteam::Sales
	
	
  # OrderBase Module
  #
  # Holds the Order Logic for an Order-Model
  # All classes, where this module gets included, are registered via Opensteam::Dependencies in Opensteam::Models
  module OrderBase


    # States Namespace
    module States #:nodoc:

    end

    module OrderExtension
      # checks if all items are finished (if state == :finished)
      def all_finished? ; empty? ? false : collect(&:finished?).all? ; end
    end
    
    module OrderItemsExtension
      # checks if all items are shipped
      def all_shipped? ; collect { |s| s.shipment != nil }.all? ; end
      
      # checks if all items have an invoice
      def all_invoiced? ; collect { |s| s.invoice != nil }.all? ; end
    end

    require 'uuidtools'


    
    def self.included(base) #:nodoc:
      
      Opensteam::Dependencies.set_order_model( base )
      
      
      base.send(:extend , ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        include Opensteam::StateMachine
        #   include Opensteam::UUIDHelper

        #== ASSOCIATIONS
        has_many :items,
          :class_name => "Opensteam::Container::Item",
          :foreign_key => "container_id",
          :extend => OrderItemsExtension

         belongs_to :customer,
           :class_name => 'Opensteam::UserBase::User',
           :foreign_key => 'user_id'

        belongs_to :payment_address,
          :class_name => 'Opensteam::Models::Address',
          :foreign_key => 'payment_address_id'

        belongs_to :shipping_address,
          :class_name => 'Opensteam::Models::Address',
          :foreign_key => 'shipping_address_id'

        has_many :payments,
          :class_name => 'Opensteam::Payment::Base' ,
          :extend => Opensteam::Payment::OrderExtension,
          :dependent => :destroy


        #== VALIDATIONS
        validates_presence_of :payment_type, :shipping_type
        validates_associated :shipping_address, :payment_address
        validates_associated :payments
#        validates_associated :customer

        alias :real_customer= :customer=

        def guest_customer=( cust ) #:nodoc:
          cust[:password] = cust[:password_confirmation] = "opensteam" unless cust[:password]
          cust[:profile] = "Guest"
          self.real_customer = Opensteam::UserBase::User.create( cust )
        end


        def existing_customer=(cust) #:nodoc:
          self.real_customer = Opensteam::UserBase::User.find( cust )
        end



        alias :real_payment_address= :payment_address=
        # find or create payment-address and associate it with the order
        def payment_address= addr
          self.real_payment_address = get_address( addr )
        end


        alias :real_shipping_address= :shipping_address=
        # find or create shipping-address and associate it with the order
        def shipping_address= addr
          self.real_shipping_address = get_address( addr )
        end
      

      end
    end

    module ClassMethods #:nodoc:
      def per_page ; 20 ; end
    end


    module InstanceMethods
      # override to_xml method
      def to_xml( options = {} ) #:nodoc:
        super options.merge( :root => "orders" )
      end


      # update the calculated tax of all items and the total_tax, total_price of the container (order)
      def update_price_and_tax!
        country = shipping_address ? shipping_address.country : Opensteam::Config::DEFAULT_COUNTRY

        items.each do |item|
          item.update_attribute( :tax, item.calculate_tax( :country => country ) )
        end

        returning( self ) do |s|
          s.total_price = items.collect(&:total_price).sum
          s.total_tax = items.collect(&:tax).sum
        end
      end


      private

      # finds or initialize address
      def get_address addr
        Opensteam::Models::Address.find(:first, :conditions => addr ) ||
          Opensteam::Models::Address.new( addr )
      end

      # validates payment_type
      # if payament_type == 'bogus', return true
      def validate
        return if self.payment_type == "bogus"
        unless (p = Opensteam::Payment::Types.find_by_name( self.payment_type ) ) && p.active?
          errors.add( :payment_type, "#{self.payment_type} currently not supported!")
        end
      end
      

      
    end
		
			
  end
	
end

