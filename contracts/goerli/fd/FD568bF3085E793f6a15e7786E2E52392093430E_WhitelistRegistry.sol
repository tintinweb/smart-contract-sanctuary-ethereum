// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;
import "./interfaces/IWhitelistRegistry.sol";

contract WhitelistRegistry is IWhitelistRegistry {
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
    function addPermissions(
        address _vaultAddress,
        address[] calldata _addresses
    ) external {
        // Make sure caller is authorized
        require(
            msg.sender == whitelistManagers[_vaultAddress],
            "Only Whitelist Manager"
        );
        mapping(address => uint256) storage _permissions = permissions[
            _vaultAddress
        ];
        // Add permissions
        uint256 addressCount = _addresses.length;
        for (uint256 i; i != addressCount; ++i) {
            _permissions[_addresses[i]] = 1;
        }
        emit PermissionsAdded(msg.sender, _vaultAddress, _addresses);
    }

    /**
     * @dev function meant to be called by contracts (usually in initializer) to register a whitelist manager for that contract
     * @param manager the address of the vault's whitelist manager
     * No access control, since any given contract can only modify their own data here.
     */
    function registerWhitelistManager(address manager) external {
        whitelistManagers[msg.sender] = manager;
        emit ManagerAdded(msg.sender, manager);
    }

    /**
     * @dev add whitelist permissions for any number of addresses.
     * @param _vaultAddress the vault whose whitelist will be edited
     * @param _addresses the addresses to be removed from the whitelist
     */
    function revokePermissions(
        address _vaultAddress,
        address[] calldata _addresses
    ) external {
        // Make sure caller is authorized
        require(
            msg.sender == whitelistManagers[_vaultAddress],
            "Only Whitelist Manager"
        );

        mapping(address => uint256) storage _permissions = permissions[
            _vaultAddress
        ];
        // Add permissions
        uint256 addressCount = _addresses.length;
        for (uint256 i; i != addressCount; ++i) {
            _permissions[_addresses[i]] = 0;
        }
        emit PermissionsRemoved(msg.sender, _vaultAddress, _addresses);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

interface IWhitelistRegistry {
    event PermissionsAdded(
        address whitelistManager,
        address vault,
        address[] addressesAdded
    );
    event PermissionsRemoved(
        address whitelistManager,
        address vault,
        address[] addressesRemoved
    );
    event ManagerAdded(address vaultAddress, address manager);

    function addPermissions(
        address _vaultAddress,
        address[] calldata _addresses
    ) external;

    function registerWhitelistManager(address manager) external;

    function revokePermissions(
        address _vaultAddress,
        address[] calldata _addresses
    ) external;
}