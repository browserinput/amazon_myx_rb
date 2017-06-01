#!/usr/bin/env ruby
# amazon_myx - Unofficial Ruby library for the undocumented "myx" Kindle JSON API
# Copyright (C) 2017 Browser Input<browserinput@users.noreply.github.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'amazon_myx/client'
require 'time'

module AmazonMYX
  class Client
    DEFAULT_GET_PURCHASE_OPTIONS = {
      'sortOrder' => 'ASCENDING',
      'sortIndex' => 'DATE',
      'startIndex' => 0,
      'batchSize' => 18,
      'contentType' => 'Ebook',
      'itemStatus' => ['Active', 'Expired'],
      'excludeExpiredItemsFor' => [
        'KOLL',
        'Purchase',
        'Pottermore',
        'FreeTrial',
        'DeviceRegistration',
        'ku',
        'Sample',
        'Prime'
      ],
      'originType' => [
        'Purchase',
        'PublicLibraryLending',
        'PersonalLending',
        'KOLL',
        'RFFLending',
        'Pottermore',
        'Rental',
        'DeviceRegistration',
        'FreeTrial',
        'ku',
        'Sample',
        'Prime'
      ],
      'isExtendedMYK' => false,
      'showSharedContent' => true
    }.freeze
    DEFAULT_PURCHASE_GET_SIZE = 18
    MAX_PURCHASE_GET_SIZE = 100

    def get_books(start=0, count=DEFAULT_PURCHASE_GET_SIZE, options={})
      raise ArgumentError, 'start must be an Integer' unless start.is_a? Integer
      raise ArgumentError, 'count must be an Integer' unless count.is_a? Integer
      if block_given? then
        raise 'not done'
      else
        if count == 0 then
          objects,x,total = [],0,nil
          loop do
            break unless (not total or total >= DEFAULT_PURCHASE_GET_SIZE)
            options2 = options.dup

            # Amazon being dodgey here :/
            options2['queryToken'] = objects.last.acquired_time_raw if (objects.last.class == AmazonMYX::Purchase)

            #items, results = get_purchases((start+(x*DEFAULT_PURCHASE_GET_SIZE)), DEFAULT_PURCHASE_GET_SIZE, options2)
            items, results = get_purchases((start+objects.length), DEFAULT_PURCHASE_GET_SIZE, options2)
            if not total then
              total = results['numberOfItems']
              raise 'No book total found!' unless total
              raise "Start index greater than total: #{start} vs #{total}" unless start < total
              total = total - start
            end
            raise 'get_books is empty of books!' if items.empty?
            objects += items
            total -= items.length
            x += 1
          end
          if total > 0 then
            results = raw_get_purchases_persistent((start+(x*DEFAULT_PURCHASE_GET_SIZE)), total, options)
            raise 'get_books is empty!' unless results
            items = results['items']
            raise 'get_books is empty of books!' unless (items and items.is_a? Array and not items.empty?)
            objects += items.map {|x| AmazonMYX::Purchase.new(x)}
          end
          objects
        elsif count > DEFAULT_PURCHASE_GET_SIZE then
          objects = []
          old_count = count
          (count/DEFAULT_PURCHASE_GET_SIZE).times do |x|
            results = raw_get_purchases_persistent((start+(x*DEFAULT_PURCHASE_GET_SIZE)), DEFAULT_PURCHASE_GET_SIZE, options)
            raise 'get_books is empty!' unless results
            items = results['items']
            raise 'get_books is empty of books!' unless (items and items.is_a? Array and not items.empty?)
            objects += items.map {|x| AmazonMYX::Purchase.new(x)}
            count -= DEFAULT_PURCHASE_GET_SIZE
          end
          if count > 0 then
            results = raw_get_purchases_persistent((start+((old_count/DEFAULT_PURCHASE_GET_SIZE)*DEFAULT_PURCHASE_GET_SIZE)), count, options)
            raise 'get_books is empty!' unless results
            items = results['items']
            raise 'get_books is empty of books!' unless (items and items.is_a? Array and not items.empty?)
            objects += items.map {|x| AmazonMYX::Purchase.new(x)}
          end
          objects
        else
          results = raw_get_purchases_persistent(start, count, options)
          raise 'get_books is empty!' unless results
          items = results['items']
          raise 'get_books is empty of books!' unless (items and items.is_a? Array and not items.empty?)
          items.map {|x| AmazonMYX::Purchase.new(x)}
        end
      end
    end

    def raw_get_purchases(start=0,count=DEFAULT_PURCHASE_GET_SIZE,options={})
      raise ArgumentError, 'start must be an Integer' unless start.is_a? Integer
      raise ArgumentError, 'count must be an Integer' unless count.is_a? Integer
      raise ArgumentError, "count cannot be more than #{MAX_PURCHASE_GET_SIZE}" unless count <= MAX_PURCHASE_GET_SIZE
      request = {
        'param' => {
          'OwnershipData' => DEFAULT_GET_PURCHASE_OPTIONS.dup
        }
      }
      options.each do |key,val|
        if val.is_a? Hash then
          val.each do |key2, val2|
            request['param']['OwnershipData'][key][key2] = val2
          end
        else
          request['param']['OwnershipData'][key] = val
        end
      end
      request['param']['OwnershipData']['startIndex'] = start
      request['param']['OwnershipData']['batchSize'] = count
      response = (self.json_query JSON.generate(request)).body
      raise 'OwnershipData returned an empty string!' if response.strip.empty?
      response = JSON.parse(response)
      raise RuntimeError, response['OwnershipData']['error'] if response['OwnershipData']['error']
      response['OwnershipData']
    end

    def get_purchases(start=0,count=DEFAULT_PURCHASE_GET_SIZE,options={})
      # Amazon being dodgey again.
      if start >= 1e3 then
        raise 'get_purchases query over 1e3 and wasn\'t given a queryToken' unless options['queryToken']
        options['queryTokenOffset'] = 1
      else
        options.delete 'queryToken'
      end
      results = nil
      5.times do
        begin
          results = raw_get_purchases(start,count,options)
          break
        rescue RuntimeError => e
          raise e unless e.message == 'GENERIC_ERROR'
          STDERR.puts "Temporary failure at #{start} #{count} #{options['queryToken']}"
          results = nil
          sleep(10)
        end
      end
      raise RuntimeError,'GENERIC_ERROR' unless results
      return results.delete('items').map {|x| AmazonMYX::Purchase.new(x) }, results
    end
  end

  class Purchase
    TYPE_KINDLE = 'KindleEBook'.freeze
    attr_reader :order_id, :is_nell_optimized, :title, :authors_sortable, :is_purchased,
                :excluded_device_map, :is_size_greater_than_50mb, :get_order_details,
                :product_image, :acquired_date, :order_detail_url, :is_content_valid,
                :can_loan, :render_download_elements, :acquired_time_raw, :title_sortable,
                :origin_type, :capabilities, :dp_url, :collection_count, :asin,
                :is_kcr_supported, :type, :authors, :file_size, :target_devices,
                :read_along_support

    def initialize(purchase)
      begin
        @order_id = purchase['orderId'].dup.freeze
        @is_nell_optimized = purchase['isNellOptimized']
        @title = purchase['title'].dup.freeze
        @authors_sortable = purchase['sortableAuthors'].dup.freeze
        @is_purchased = purchase['isPurchased']
        @excluded_device_map = purchase['excludedDeviceMap'].dup.freeze
        @is_size_greater_than_50mb = purchase['isSizeGreaterThan50Mb']
        @get_order_details = purchase['getOrderDetails']
        @product_image = purchase['productImage'].dup.freeze
        @acquired_date = Date.parse(purchase['acquiredDate']).freeze
        @order_detail_url = purchase['orderDetailURL'].dup.freeze
        @is_content_valid = purchase['isContentValid']
        @can_loan = purchase['canLoan']
        @render_download_elements = purchase['renderDownloadElements']
        @acquired_time_raw = purchase['acquiredTime'].to_s.freeze
        @title_sortable = purchase['sortableTitle'].dup.freeze
        @origin_type = purchase['originType'].dup.freeze
        @capabilities = purchase['capabilityList'].dup.freeze
        @dp_url = purchase['dpURL'].dup.freeze
        @collection_count = purchase['collectionCount']
        @asin = purchase['asin'].dup.freeze
        @is_kcr_supported = purchase['isKCRSupported']
        @type = purchase['category'].dup.freeze
        @authors = purchase['authors'].dup.freeze
        @read_along_support = purchase['readAlongSupport'].dup.freeze
        @target_devices = purchase['targetDevices'].dup.freeze
        @file_size = purchase['numericFileSize']
      rescue e
        raise TypeError, e.message + ": #{device.inspect}"
      end
    end

    def is_kindle?
      (self.type == TYPE_KINDLE) ? true : false
    end
  end
end
