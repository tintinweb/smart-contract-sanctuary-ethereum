/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/access/AdminControl.sol


pragma solidity ^0.8.10;

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    constructor(address _admin) {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}


// File contracts/common/ProxyAdmin.sol


pragma solidity ^0.8.0;

interface IProxy {
    function implementation() external returns (address);

    function admin() external returns (address);

    function changeAdmin(address newAdmin) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable;
}

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is AdminControl {
    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() AdminControl(msg.sender) {}

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(address proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            abi.encodeWithSelector(IProxy.implementation.selector)
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(address proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            abi.encodeWithSelector(IProxy.admin.selector)
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(address proxy, address newAdmin)
        public
        virtual
        onlyAdmin
    {
        IProxy(proxy).changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(address proxy, address implementation)
        public
        virtual
        onlyAdmin
    {
        IProxy(proxy).upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        address proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyAdmin {
        IProxy(proxy).upgradeToAndCall{value: msg.value}(implementation, data);
    }
}