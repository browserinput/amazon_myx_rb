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

require 'mechanize'
require 'json'

module AmazonMYX
  AMAZON = 'https://www.amazon.com/'.freeze
  MYX_MATCH = /myx\.html/.freeze
  MYX_HTML = 'https://www.amazon.com/mn/dcw/myx.html/ref=nav_youraccount_myk'.freeze
  MYX_AJAX = 'https://www.amazon.com/mn/dcw/myx/ajax-activity/ref=myx_ajax'.freeze
  EMAIL_VALID_EXCLUDE = '[^ @]+'.freeze
  EMAIL_VALID = /^#{EMAIL_VALID_EXCLUDE}@#{EMAIL_VALID_EXCLUDE}\.#{EMAIL_VALID_EXCLUDE}$/.freeze
  CSRF_MATCH = /csrfToken\W+?=\W+?["'](.+?)["']/.freeze

  class Client
    attr_reader :email, :agent, :csrfToken

    def initialize(email='', password='')
      raise ArgumentError, "not a valid e-mail address: #{email}" unless Client.is_email? email
      @email = email.freeze
      raise ArgumentError, "password is not a String: #{password}" unless password.is_a? String
      @password = password.freeze
      self.setup_agent
      nil
    end

    def setup_agent(force_new_agent=false)
      raise '@agent already exists!' if self.agent and not force_new_agent
      @agent = Mechanize.new {|agent|
        agent.cookie_jar.clear!
        agent.user_agent_alias = 'Linux Firefox'
        agent.follow_meta_refresh = true
        agent.redirect_ok = true
      }
      @agent.get AMAZON
      nil
    end

    def raw_login()
      page = @agent.get MYX_HTML
      signin_f = page.form('signIn')
      signin_f.email = self.email
      signin_f.password = @password
      page = @agent.submit signin_f
      raise RuntimeError, 'Login error: ' + page.uri.to_s unless page.uri.to_s =~ MYX_MATCH
      self.get_csrfToken(page.body)
      page
      nil
    end

    def login()
      5.times { |count|
        begin
          self.raw_login
          return
        rescue RuntimeError => e
          STDERR.puts "Login failed #{count+1} times"
        end
        sleep 0.5
      }
      raise RuntimeError, 'Login failed!'
    end

    def logged_in?()
      ((@agent.get MYX_HTML).uri.to_s =~ MYX_MATCH) ? true : false
    end

    def json_query(data)
      self.agent.post MYX_AJAX, { 'data' => data, 'csrfToken' => self.csrfToken }, {
        'Accept' => 'Accept: application/json, text/plain, */*',
        'client' => 'MYX',
        'Referer' => MYX_HTML,
        'DNT' => 1,
        'Connection' => 'keep-alive'}
    end

    def get_csrfToken(page_body='')
      if page_body.empty? then
        page_body = (@agent.get MYX_HTML).body
      end
      matcher = page_body.match CSRF_MATCH
      raise "Something is wrong; myx.html didn't contain a csrfToken!" unless matcher
      @csrfToken = matcher[1].freeze
    end

    def Client.is_email?(email)
      raise ArgumentError, "email is not a String: #{email}" unless email.is_a? String
      (email =~ EMAIL_VALID) ? true : false
    end
  end
end
