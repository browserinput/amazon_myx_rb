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

module AmazonMYX
  class Client
    def get_devices()
      devices_hash = JSON.parse((json_query '{"param":{"GetDevices":{}}}').body)
      raise devices_hash['error'] if (devices_hash['success'] and not devices_hash['success'])
      devices_hash['GetDevices']['devices'].map {|x|
        AmazonMYX::Device.new(x)
      }
    end
  end
  
  class Device
    DEVICE_CLASS_APP = 'APPS'.freeze
    DEVICE_CLASS_DEVICE = 'DEVICES'.freeze
    DEVICE_GROUP_KINDLE = 'Kindle'.freeze
    DEVICE_GROUP_AUDIBLE = 'Audible'.freeze

    attr_reader :device_type, :device_type_string, :initial_connection_date, :device_image_url,
                :device_alias, :device_name, :software_capabilities, :device_class,
                :initial_connection_raw, :device_class_string, :device_serial,
                :wireless_help_node, :warranties, :device_image, :device_type_human,
                :device_group_name, :device_class_full, :device_account_id, :software_version,
                :device_capabilities, :bound_warranty, :dtcp_result, :software_update_node

    def initialize(device={})
      begin
        @device_type = device['deviceType'].dup.freeze
        @device_type_string = device['deviceTypeStringId'].dup.freeze
        @device_alias = device['deviceAlias'].dup.freeze
        @device_image_url = device['deviceImageUrl'].dup.freeze
        @device_name = device['deviceAccountName'].dup.freeze
        @software_capabilities = device['softwareVersionDeviceCapabilities'].dup.freeze
        @device_class = device['deviceFilter'].dup.freeze
        @device_class_string = device['deviceClassificationString'].dup.freeze
        @device_serial = device['deviceSerialNumber'].dup.freeze
        @wireless_help_node = device['wirelessHelpNode']
        @warranties = device['warranties'].dup.freeze
        @device_image = device['deviceImage'].dup.freeze
        @device_type_human = device['deviceTypeString'].dup.freeze
        @device_group_name = device['deviceGroupName'].dup.freeze
        @device_class_full = device['deviceClassification'].dup.freeze
        @device_account_id = device['deviceAccountId'].dup.freeze
        @softwareVersion = device['softwareVersion']
        @device_capabilities = device['deviceCapabilities'].dup.freeze
        @bound_warranty = device['boundWarranty'].dup.freeze
        @dtcp_result = device['dtcpResult'].dup.freeze
        @software_update_node = device['softwareUpdateNode']

        begin
          @initial_connection_date = Time.parse(device['firstRadioOnDate']).utc.freeze
        rescue ArgumentError => e
          raise TypeError, e.message
        end
        @initial_connection_raw = device['firstRadioOn']


      rescue e
        raise TypeError, e.message + ": #{device.inspect}"
      end
      nil
    end

    def is_kindle?()
      (self.device_group_name == DEVICE_GROUP_KINDLE) ? true : false
    end

    def is_audible?()
      (self.device_group_name == DEVICE_GROUP_AUDIBLE) ? true : false
    end

    def is_device?()
      (self.device_class == DEVICE_CLASS_DEVICE) ? true : false
    end

    def is_app?()
      (self.device_class == DEVICE_CLASS_APP) ? true : false
    end

    def to_s()
      "<Device #{self.device_group_name}:#{self.device_class} name:\"#{self.device_name}\" " +
      "initial_connection_date=\"#{self.initial_connection_date}\">"
    end

    alias_method :inspect, :to_s
  end
end
