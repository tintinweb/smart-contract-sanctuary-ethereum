// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "Clones.sol";
import "InitializableTransparentUpgradeableProxy.sol";

/**
 * @title Pawnfi's CreateProxyFactory Contract
 * @author Pawnfi
 */
contract CreateProxyFactory {

    /// @notice Proxy contract of logic address
    address public implementation;

    /// @notice Emitted when create proxy contract
    event ProxyCreated(address proxy);

    /**
     * @notice Initialize contract parameters
     */
    constructor() {
        implementation = address(new InitializableTransparentUpgradeableProxy());
    }

    /**
     * @notice Deploy proxy contract
     * @param logic logic contract address
     * @param admin admin address
     * @param data The call parameters when deploying
     */
    function deployMinimal(address logic, address admin, bytes memory data) public returns (address proxy) {
        proxy = Clones.clone(implementation);
        InitializableTransparentUpgradeableProxy(payable(proxy)).initialize(logic, admin, data);
        emit ProxyCreated(proxy);
    }

    /**
     * @notice Deploy the proxy contract based on salt
     * @param logic logic contract address
     * @param admin admin address
     * @param data The call parameters when deploying
     * @param salt salt
     * @return proxy proxy address
     */
    function deploy(address logic, address admin, bytes memory data, bytes32 salt) public returns (address proxy) {
        proxy = Clones.cloneDeterministic(implementation, salt);
        InitializableTransparentUpgradeableProxy(payable(proxy)).initialize(logic, admin, data);
        emit ProxyCreated(proxy);
    }

    /**
     * @notice Determine the proxy address based on salt
     * @param salt salt
     * @return address proxy address
     */
    function computeAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(implementation, salt);
    }
}