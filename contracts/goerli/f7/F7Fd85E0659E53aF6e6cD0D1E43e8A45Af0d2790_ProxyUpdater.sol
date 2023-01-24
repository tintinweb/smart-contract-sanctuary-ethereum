// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ProxyUpdater
 * @notice The ProxyUpdater contains the logic that sets storage slots within the proxy contract
 *         when an action is executed in the ChugSplashManager. When a `setStorage` action is
 *         executed, the ChugSplashManager temporarily sets the proxy's implementation to be this
 *         contract so that the proxy can delegatecall into it.
 */
contract ProxyUpdater {
    /**
     * @notice Modifies some storage slot within the proxy contract. Gives us a lot of power to
     *         perform upgrades in a more transparent way.
     *
     * @param _key   Storage key to modify.
     * @param _value New value for the storage key.
     */
    function setStorage(bytes32 _key, bytes32 _value) external {
        assembly {
            sstore(_key, _value)
        }
    }
}