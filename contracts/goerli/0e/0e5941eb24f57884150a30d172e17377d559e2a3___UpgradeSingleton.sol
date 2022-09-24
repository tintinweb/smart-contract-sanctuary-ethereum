/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title __UpgradeSingleton - Helper contract to upgrade the singleton
contract __UpgradeSingleton {
    address internal singleton;

    /// @dev Upgrade function updates the singleton.
    ///      Must be called using Operation.DelegateCall.
    ///      Use with care, may brick the contract forever!
    /// @param _singleton New singleton address.
    function __upgradeSingleton(address _singleton) external {
        singleton = _singleton;
    }
}