// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Clones} from "./helpers/Clones.sol";
import {IENSBoundBadge} from "./interfaces/IENSBoundBadge.sol";

error OnlyOwner(); // Caller is not owner

/// @title ENSBoundBadgeFactory
/// @notice A simple factory contract used to clone the ENSBoundBadge contracts

contract ENSBoundBadgeFactory {
    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    address public implementation;
    address public immutable owner;
    address public immutable ensAddress;

    mapping(uint256 => address) public ensBoundBadgeAddresses;
    uint256 public count;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event NewENSBoundBadgeCreated(
        address indexed _ensBoundBadgeAddress,
        string _name,
        string _symbol,
        uint256 _supply
    );

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _implementation, address _ensAddress) {
        implementation = _implementation;
        owner = msg.sender;
        ensAddress = _ensAddress;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /// @notice Used to create a new ENS bound badge contract
    /// @param _name Name of the badge
    /// @param _symbol Symbol for the badge
    /// @param _supply Max supply for the badge
    /// @param _canHoldMultiple Used to specify if an ENS domain can hold multiple badges
    function createENSBoundBadge(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        bool _canHoldMultiple
    ) external {
        IENSBoundBadge _ensBoundBadgeAddress = IENSBoundBadge(
            Clones.clone(implementation)
        );

        _ensBoundBadgeAddress.initialize(
            _name,
            _symbol,
            ensAddress,
            msg.sender,
            _supply,
            _canHoldMultiple
        );

        ensBoundBadgeAddresses[++count] = address(_ensBoundBadgeAddress);

        emit NewENSBoundBadgeCreated(
            address(_ensBoundBadgeAddress),
            _name,
            _symbol,
            _supply
        );
    }

    /// @notice Used to update the address of ENSBoundBadge implementation contract
    /// @param _newImplementation Address of the updated contract
    function setImplementationAddress(address _newImplementation) external {
        if (msg.sender != owner) revert OnlyOwner();
        implementation = _newImplementation;
    }
}

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
            mstore(
                0x00,
                or(
                    shr(0xe8, shl(0x60, implementation)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(
                0x20,
                or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
            )
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
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(
                0x00,
                or(
                    shr(0xe8, shl(0x60, implementation)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(
                0x20,
                or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
            )
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

/// @notice Interface for ENSBoundBadge contract
interface IENSBoundBadge {
    struct BadgeInfo {
        string title; /// Title of the Badge
        string description; /// Description for the badge
        string metadataURI; /// Metadata URI for the badge
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _ensAddress,
        address _issuer,
        uint256 _supply,
        bool _canHoldMultiple
    ) external;
}