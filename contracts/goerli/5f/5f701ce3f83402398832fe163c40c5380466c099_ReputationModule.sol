// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationEngineInterface } from "./interfaces/ReputationEngineInterface.sol";
import { ReputationModuleInterface } from "./interfaces/ReputationModuleInterface.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract ReputationModule is ReputationModuleInterface {
    using Clones for address;

    address public network;

    mapping(address => ReputationMarketConfig) public laborMarketRepConfig;

    event ReputationEngineCreated (
          address indexed reputationEngine
        , address indexed baseToken
        , uint256 indexed baseTokenId
        , address owner
        , uint256 decayRate
        , uint256 decayInterval
    );

    event MarketReputationConfigured (
          address indexed market
        , address indexed reputationEngine
        , uint256 signalStake
        , uint256 providerThreshold
        , uint256 maintainerThreshold
    );

    constructor(
        address _network
    ) {
        network = _network;
    }

    /**
     * @notice Create a new Reputation Token.
     * @param _implementation The address of ReputationEngine implementation.
     * @param _baseToken The address of the base ERC1155.
     * @param _baseTokenId The tokenId of the base ERC1155.
     * @param _decayRate The amount of reputation decay per epoch.
     * @param _decayInterval The block length of an epoch.
     * Requirements:
     * - Only the network can call this function in the factory.
     */
    function createReputationEngine(
          address _implementation
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        override
        external
        returns (
            address
        )
    {
        address reputationEngineAddress = _implementation.clone();

        ReputationEngineInterface reputationEngine = ReputationEngineInterface(
            reputationEngineAddress
        );

        reputationEngine.initialize(
              address(this)
            , _baseToken
            , _baseTokenId
            , _decayRate
            , _decayInterval
        );

        emit ReputationEngineCreated(
              reputationEngineAddress
            , _baseToken
            , _baseTokenId
            , msg.sender
            , _decayRate
            , _decayInterval
        );

        return reputationEngineAddress;
    }

    /**
     * @notice Initialize a new Labor Market as using Reputation.
     * @param _laborMarket The address of the new Labor Market.
     * @param _repConfig The Labor Market level config of Reputation.
     * Requirements:
     * - Only the network can call this function in the factory.
     */
    function useReputationModule(
          address _laborMarket
        , ReputationMarketConfig calldata _repConfig
    )
        override
        public
    {
        require(msg.sender == network, "ReputationModule: Only network can call this.");

        laborMarketRepConfig[_laborMarket] = _repConfig;

        emit MarketReputationConfigured(
              _laborMarket
            , _repConfig.reputationEngine
            , _repConfig.signalStake
            , _repConfig.providerThreshold
            , _repConfig.maintainerThreshold
        );
    }

    /**
     * @notice Change the parameters of the Labor Market Reputation config.
     * @param _repConfig The Labor Market level config of Reputation.
     * @dev This function is only callable by Labor Markets that have already been
     *      initialized with the Reputation module by the Network.
     * Requirements:
     * - The Labor Market must already have a configuration.
     */
    function setMarketRepConfig(
        ReputationMarketConfig calldata _repConfig
    )
        override
        public 
    {
        require(_callerReputationEngine() != address(0), "ReputationModule: This Labor Market does not exist.");

        laborMarketRepConfig[msg.sender] = _repConfig;

        emit MarketReputationConfigured(
              msg.sender
            , _repConfig.reputationEngine
            , _repConfig.signalStake
            , _repConfig.providerThreshold
            , _repConfig.maintainerThreshold
        );
    }

    /**
     * @dev See {reputationEngine-freezeReputation}.
     */
    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    ) 
        override
        public
    {
        _freezeReputation(_callerReputationEngine(), _account, _frozenUntilEpoch);
    }

    /**
     * @dev See {ReputationEngine-lockReputation}.
     * @dev The internal call makes the module the msg.sender which is permissioned
     *      to make balance changes within the ReputationEngine.
     */
    function _freezeReputation(
          address _reputationEngine
        , address _account
        , uint256 _frozenUntilEpoch
    )
        internal
    {
        ReputationEngineInterface(_reputationEngine).freezeReputation(
              _account
            , _frozenUntilEpoch
        );
    }

    /**
     * @dev See {ReputationEngine-lockReputation}.
     */
    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        public
    {
        _lockReputation(_callerReputationEngine(), _account, _amount);
    }

    /**
     * @dev See {ReputationEngine-lockReputation}.
     * @dev The internal call makes the module the msg.sender which is permissioned
     *      to make balance changes within the ReputationEngine.
     */
    function _lockReputation(
          address _reputationEngine
        , address _account
        , uint256 _amount
    ) 
        internal
    {
        ReputationEngineInterface(_reputationEngine).lockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationEngine-unlockReputation}.
     */
    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        public
    {
        _unlockReputation(_callerReputationEngine(), _account, _amount);
    }
    
    /**
     * @dev The internal call makes the module the msg.sender which is permissioned
     *      to make balance changes within the ReputationEngine.
     */
    function _unlockReputation(
          address _reputationEngine
        , address _account
        , uint256 _amount
    ) 
        internal
    {
        ReputationEngineInterface(_reputationEngine).unlockReputation(
              _account
            , _amount
        );
    }

    /**
     * @dev See {ReputationEngine-getAvailableReputation}.
     */
    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationEngineInterface(
            getReputationEngine(_laborMarket)
        ).getAvailableReputation(_account);
    }

    /**
     * @dev See {ReputationEngine-getPendingDecay}.
     */
    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            uint256
        )
    {
        return ReputationEngineInterface(
            getReputationEngine(_laborMarket)
        ).getPendingDecay(_account);
    }

    /**
     * @dev See {ReputationEngine-getReputationAccountInfo}.
     */
    function getReputationAccountInfo(
          address _laborMarket
        , address _account
    )
        override
        public
        view
        returns (
            ReputationEngineInterface.ReputationAccountInfo memory
        )
    {
        return ReputationEngineInterface(
            getReputationEngine(_laborMarket)
        ).getReputationAccountInfo(_account);
    }

    /**
     * @notice Retreive the reputation configuration parameters for the Labor Market.
     * @param _laborMarket The address of the Labor Market.
     */
    function getMarketReputationConfig(address _laborMarket)
        override
        public
        view
        returns (
            ReputationMarketConfig memory
        )
    {
        return laborMarketRepConfig[_laborMarket];
    }

    /**
     * @notice Retreive the ReputationEngine implementation for the Labor Market.
     * @param _laborMarket The address of the Labor Market.
     */
    function getReputationEngine(address _laborMarket)
        override
        public
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[_laborMarket].reputationEngine;
    }

    /**
     * @dev Helper function to get the ReputationEngine address for the caller.
     * @dev By limiting the caller to a Labor Market, we can ensure that the
     *      caller is a valid Labor Market and can only interact with its own
     *      ReputationEngine.
     */
    function _callerReputationEngine()
        internal
        view
        returns (
            address
        )
    {
        return laborMarketRepConfig[msg.sender].reputationEngine;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ReputationEngineInterface {
    struct ReputationAccountInfo {
        uint256 locked;
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function initialize(
          address _module
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external;

    function setDecayConfig(
        uint256 _decayRate,
        uint256 _decayInterval
    ) 
        external;

    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        external;


    function lockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function unlockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function getAvailableReputation(address _account)
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(address _account)
        external
        view
        returns (
            uint256
        );

    function getReputationAccountInfo(address _account)
        external
        view
        returns (
            ReputationAccountInfo memory
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationEngineInterface } from "./ReputationEngineInterface.sol";

interface ReputationModuleInterface {
    struct ReputationMarketConfig {
        address reputationEngine;
        uint256 signalStake;
        uint256 providerThreshold;
        uint256 maintainerThreshold;
    }

    function createReputationEngine(
          address _implementation
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external
        returns (
            address
        );

    function useReputationModule(
          address _laborMarket
        , ReputationMarketConfig calldata _repConfig
    )
        external;

    function setMarketRepConfig(
        ReputationMarketConfig calldata _repConfig
    )
        external;

    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        external;


    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        external;

    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        external;

    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getReputationAccountInfo(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            ReputationEngineInterface.ReputationAccountInfo memory
        );

    function getMarketReputationConfig(address _laborMarket)
        external
        view
        returns (
            ReputationMarketConfig memory
        );

    function getReputationEngine(address _laborMarket) 
        external
        view
        returns (
            address
        );
}