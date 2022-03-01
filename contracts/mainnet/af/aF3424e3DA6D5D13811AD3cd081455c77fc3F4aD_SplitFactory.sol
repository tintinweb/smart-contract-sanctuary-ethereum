pragma solidity 0.8.10;

import {Clones} from "../lib/Clones.sol";

interface ISplitter {
    function initialize(address wethAddress_, bytes32 merkleRoot_)
        external
        returns (address);
}

interface ISplitFactoryEvents {
    /// @notice New Split clone deployed
    /// @param sender The address sending the deploy transaction
    /// @param clone Deployed clone address
    event SplitDeployed(address sender, address clone);
}

/// @title SplitFactory
/// @notice The `SplitFactory` contract deploys split clones. After deployment, the
/// factory calls `initialize` to set up the split metadata
/// @author MirrorXYZ
contract SplitFactory is ISplitFactoryEvents {
    /// @notice Address that holds the clone implementation
    address public immutable implementation;

    /// @notice Creates SplitFactory
    /// @param implementation_ Split implementation address
    constructor(address implementation_) {
        implementation = implementation_;
    }

    /// @notice Deploys a new split
    /// @param wethAddress_ Wrapped ether address
    /// @param merkleRoot_ Merkle root containign split allocations
    function createSplit(address wethAddress_, bytes32 merkleRoot_)
        external
        returns (address clone)
    {
        clone = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(merkleRoot_, msg.sender))
        );

        ISplitter(clone).initialize(wethAddress_, merkleRoot_);

        emit SplitDeployed(msg.sender, clone);
    }

    /// @notice Predicts deterministic address
    /// @param implementation_ Implementation contract address
    /// @param salt Salt generated during deployment
    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                implementation_,
                salt,
                address(this)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev Copy of OpenZeppelin's Clones contract
 * https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
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
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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