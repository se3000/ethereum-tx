require 'digest/sha3'
require 'ffi'
require 'money-tree'
require 'rlp'
require 'rbsecp256k1'

module Eth
  BYTE_ZERO = "\x00".freeze
  UINT_MAX = 2**256 - 1

  autoload :Address, 'eth/address'
  autoload :Chains, 'eth/chains'
  autoload :Gas, 'eth/gas'
  autoload :Key, 'eth/key'
  autoload :PersonalMessage, 'eth/personal_message'
  autoload :RecoverableSignature, 'eth/recoverable_signature'
  autoload :Sedes, 'eth/sedes'
  autoload :Tx, 'eth/tx'
  autoload :Utils, 'eth/utils'

  class << self
    def configure
      yield(configuration)
    end

    def replayable_chain_id
      27
    end

    def chain_id
      configuration.chain_id
    end

    def v_base
      replayable_chain_id
    end

    def replayable_v?(v)
      [replayable_chain_id, replayable_chain_id + 1].include? v
    end

    def tx_data_hex?
      !!configuration.tx_data_hex
    end

    def chain_id_from_signature(signature)
      return nil if Eth.replayable_v?(signature[:v])

      cid = (signature[:v] - 35) / 2
      (cid < 1) ? nil : cid
    end

    private

    def configuration
      @configuration ||= Configuration.new
    end
  end

  class Configuration
    attr_accessor :chain_id, :tx_data_hex

    def initialize
      self.chain_id = nil
      self.tx_data_hex = true
    end
  end

  class ValidationError < StandardError; end
  class InvalidTransaction < ValidationError; end
end
