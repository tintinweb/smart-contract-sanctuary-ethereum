/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File contracts/proxy/TicketProxy.sol

contract TicketProxy {
    address private immutable beacon;

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function _implementation() internal view virtual returns (address) {
        return IBeacon(beacon).implementation();
    }

    fallback() external payable {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}