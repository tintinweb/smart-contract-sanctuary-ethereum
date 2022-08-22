// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { PayableProxyInterface } from "../interfaces/PayableProxyInterface.sol";

interface IUpgradeBeacon {
    /**
     * @notice An external view function that returns the implementation.
     *
     * @return The address of the implementation.
     */
    function implementation() external view returns (address);
}

/**
 * @title   PayableProxy
 * @author  OpenSea Protocol Team
 * @notice  PayableProxy is a beacon proxy which will immediately return if
 *          called with callvalue. Otherwise, it will delegatecall the beacon
 *          implementation.
 */
contract PayableProxy is PayableProxyInterface {
    // Address of the beacon.
    address private immutable _beacon;

    constructor(address beacon) payable {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Deployment must originate from an approved deployer."
        );
        // Set the initial beacon.
        _beacon = beacon;
    }

    function initialize(address ownerToSet) external {
        // Ensure the origin is an approved deployer.
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Initialize must originate from an approved deployer."
        );
        // Get the implementation address from the provided beacon.
        address implementation = IUpgradeBeacon(_beacon).implementation();

        // Create the initializationCalldata from the provided parameters.
        bytes memory initializationCalldata = abi.encodeWithSignature(
            "initialize(address)",
            ownerToSet
        );

        // Delegatecall into the implementation, supplying initialization
        // calldata.
        (bool ok, ) = implementation.delegatecall(initializationCalldata);

        // Revert and include revert data if delegatecall to implementation
        // reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by
     *      `_implementation()`. Will run if no other function in the contract
     *      matches the call data.
     */
    fallback() external payable override {
        _fallback();
    }

    /**
     * @dev Internal fallback function that delegates calls to the address
     *      returned by `_implementation()`. Will run if no other function
     *      in the contract matches the call data.
     */
    function _fallback() internal {
        // Delegate if call value is zero.
        if (msg.value == 0) {
            _delegate(_implementation());
        }
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will
     * return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this
            // inline assembly block because it will not return to
            // Solidity code. We overwrite the Solidity scratch pad
            // at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This function returns the address to which the fallback function
     *      should delegate.
     */
    function _implementation() internal view returns (address) {
        return IUpgradeBeacon(_beacon).implementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title   PayableProxyInterface
 * @author  OpenSea Protocol Team
 * @notice  PayableProxyInterface contains all external function interfaces
 *          for the payable proxy.
 */
interface PayableProxyInterface {
    /**
     * @dev Fallback function that delegates calls to the address returned by
     *      `_implementation()`. Will run if no other function in the contract
     *      matches the call data.
     */
    fallback() external payable;
}