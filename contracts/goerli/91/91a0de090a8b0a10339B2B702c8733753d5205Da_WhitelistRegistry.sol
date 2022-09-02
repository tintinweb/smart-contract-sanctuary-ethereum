// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

contract WhitelistRegistry   {
    /**
     * @dev info, per address, of permissions. 0 = no permissions, 1 = whitelisted. This is only relevant for vaults with whitelists.
     */
    mapping(address => mapping(address => uint256)) public permissions;

    mapping(address => address) public whitelistManagers;

    /**
     * @dev add whitelist permissions for any number of addresses.
     * @param _vaultAddress the vault whose whitelist will be edited
     * @param _addresses the addresses to be added to the whitelist
     */
    function addPermissions(address _vaultAddress, address[] calldata _addresses) external   {
        // Make sure caller is authorized
        require(msg.sender == whitelistManagers[_vaultAddress], "Only whitelist manager can call this function");

        // Add permissions
        uint256 length = _addresses.length;
        for (uint i = 0; i != length; i++) {
            permissions[_vaultAddress][_addresses[i]] = 1;
        }
    }

    /**
     * @dev function meant to be called by contracts (usually in initializer) to register a whitelist manager for that contract
     * @param manager the address of the vault's whitelist manager
     * No access control, since any given contract can only modify their own data here.
     */
    function registerWhitelistManager(address manager) external   {
        whitelistManagers[msg.sender] = manager;
    }

    /**
     * @dev add whitelist permissions for any number of addresses.
     * @param _vaultAddress the vault whose whitelist will be edited
     * @param _addresses the addresses to be removed from the whitelist
     */
    function revokePermissions(address _vaultAddress, address[] calldata _addresses) external   {
        // Make sure caller is authorized
        require (msg.sender == whitelistManagers[_vaultAddress]);

        // Remove permissions
        uint256 length = _addresses.length;
        for (uint i = 0; i != length; i++) {
            permissions[_vaultAddress][_addresses[i]] = 0;
        }
    }
}