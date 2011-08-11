#!/usr/bin/env ruby
#
# Copyright (c) 2009 Carson McDonald
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

require 'hs_transfer'
require 'logger'
require 'yaml'

class HSConfig
  def self.load( config_file )
    HSConfig.new( config_file )
  end

  def initialize(config_file)
    @config = YAML::load( File.open(config_file) )
    sanity_check(@config)
  end

  def [](index)
    @config[index]
  end

  def self.log_setup(config)
    if config['log_type'] == 'FILE'
      log = Logger.new(config['log_file'])
    else
      log = Logger.new(STDOUT)
    end

    case config['log_level']
    when 'DEBUG'
      log.level = Logger::DEBUG
    when 'INFO'
      log.level = Logger::INFO
    when 'WARN'
      log.level = Logger::WARN
    when 'ERROR'
      log.level = Logger::ERROR
    else
      log.level = Logger::DEBUG
    end

    return log
  end

  private

  def sanity_check(config)
    log = HSConfig::log_setup(config)

    if config['log_type'] == 'FILE' and !File.writable? config['log_file']
      log.error("The given log file can not be written to: #{config['log_file']}")
      raise
    end

    if !File.directory? config['temp_dir'] or !File.writable? config['temp_dir']
      log.error("Temp directory does not exist or can not be written to: #{config['temp_dir']}")
      raise
    end

    if !File.readable? config['input_location']
      log.error("The input file can not be read: #{config['input_location']}")
      raise
    end

    if config['segment_length'] < 3
      log.error("Segment length can not be less than 3 seconds: #{config['segment_length']}")
      raise
    end

    if config['encoding_profile'].is_a?(Array)
      config['encoding_profile'].each do |ep|
        if config[ep].nil?
          log.error("The given encoding profile was not found in the config: #{ep}")
          raise
        end
      end
    else
      if config[config['encoding_profile']].nil?
        log.error("The given encoding profile was not found in the config: #{config['encoding_profile']}")
        raise
      end
    end

    tp = config['transfer_profile']
    if tp.is_a?(Array)
      tps = tp
    else
      tps = [tp]
    end

    tps.each do |tp|
      if config[tp].nil?
        log.error("The given transfer profile was not found in the config: #{tp}")
        raise
      end

      if config[tp]['transfer_type'] != 'ftp' and config[tp]['transfer_type'] != 'scp' and
      config[tp]['transfer_type'] != 's3' and config[tp]['transfer_type'] != 'copy'
        log.error("The given transfer type is not known: #{config[tp]['transfer_type']}")
        raise
      end

      if !HSTransfer::can_ftp and config[tp]['transfer_type'] == 'ftp'
        log.error("The given transfer type is not available: #{config[tp]['transfer_type']}")
        raise
      end

      if !HSTransfer::can_scp and config[tp]['transfer_type'] == 'scp'
        log.error("The given transfer type is not available: #{config[tp]['transfer_type']}")
        raise
      end

      if !HSTransfer::can_s3 and config[tp]['transfer_type'] == 's3'
        log.error("The given transfer type is not available: #{config[tp]['transfer_type']}")
        raise
      end
    end

  end

end
