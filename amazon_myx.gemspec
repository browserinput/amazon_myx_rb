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

spec = Gem::Specification.new do |spec|
  spec.name = 'amazon_myx'
  spec.summary = 'Unofficial Ruby library for the undocumented "myx" Kindle JSON API'
  spec.description = %{Aims to provide an interactive client, a low level API, and
  a high level API. Completely unaffiliated with Amazon.}
  spec.author = 'Browser Input'
  spec.email = 'browserinput@users.noreply.github.com'
  spec.homepage = 'http://www.example.com'
  spec.licenses = ['GPL-3.0']
  spec.version = '0.0.0'

  spec.files = ['LICENSE', 'LICENSE.md', 'README.md'] + Dir['lib/*.rb']
  spec.require_paths = ['lib']

  spec.rdoc_options = ['--main', 'README.md']
  spec.required_ruby_version = Gem::Requirement.new('>= 1.9.3')

  spec.add_dependency('nokogiri')
  spec.add_dependency('mechanize')
end
