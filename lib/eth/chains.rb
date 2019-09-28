module Eth
  # Encapsulates utilities and constants for various Ethereum chains.
  module Chains
    # Chain IDs for various chains (from EIP-155)
    MAINNET = 1
    MORDEN = 2
    ROPSTEN = 3
    RINKEBY = 4
    KOVAN = 42
    ETC_MAINNET = 61
    ETC_TESTNET = 62

    # Indicates whether or not the given value represents a legacy chain v.
    #
    # @return [Boolean] true if the v represents a signature before the ETC
    #   fork, false if it does not.
    def self.legacy_recovery_id?(v)
      [27, 28].include?(v)
    end

    # Convert a v value into an ECDSA recovery id.
    #
    # See EIP-155 for more information the computations done in this method:
    # https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    #
    # @param v [Integer] v value from a signature.
    # @param chain_id [Integer] chain ID for the chain the signature was
    #   generated on.
    # @return [Integer] the recovery id corresponding to the given v value.
    # @raise [ArgumentError] if the given v value is invalid.
    def self.to_recovery_id(v, chain_id)
      # Handle the legacy network recovery ids
      return v - 27 if legacy_recovery_id?(v)

      raise ArgumentError, "Invalid legacy v value #{v}." if chain_id.nil?

      if [(2 * chain_id + 35), (2 * chain_id + 36)].include?(v)
        return v - 35 - 2 * chain_id
      end

      raise ArgumentError, "Invalid v value for chain #{chain_id}. Invalid chain_id?"
    end

    # Converts a recovery ID into the expected v value.
    #
    # @param recovery_id [Integer] signature recovery id (should be 0 or 1).
    # @param chain_id [Integer] Unique ID of the Ethereum chain.
    # @return [Integer] the v value for the recovery id.
    def self.to_v(recovery_id, chain_id)
      2 * chain_id + 35 + recovery_id
    end
  end
end
