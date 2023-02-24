// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IPRBProxyHelpers } from "./interfaces/IPRBProxyHelpers.sol";
import { IPRBProxyPlugin } from "./interfaces/IPRBProxyPlugin.sol";
import { PRBProxyStorage } from "./PRBProxyStorage.sol";

/// @title PRBProxyHelpers
/// @dev This contract implements the {IPRBProxyHelpers} interface.
contract PRBProxyHelpers is
    IPRBProxyHelpers, // no dependencies
    PRBProxyStorage // no dependencies
{
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyHelpers
    uint256 public constant override VERSION = 3;

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyHelpers
    function installPlugin(IPRBProxyPlugin plugin) external override {
        // Get the method list to install.
        bytes4[] memory methodList = plugin.methodList();

        // The plugin must have at least one listed method.
        uint256 length = methodList.length;
        if (length == 0) {
            revert PRBProxy_NoPluginMethods(plugin);
        }

        // Enable every method in the list.
        for (uint256 i = 0; i < length; ) {
            plugins[methodList[i]] = plugin;
            unchecked {
                i += 1;
            }
        }

        // Log the plugin installation.
        emit InstallPlugin(plugin);
    }

    /// @inheritdoc IPRBProxyHelpers
    function setPermission(address envoy, address target, bool permission) external override {
        permissions[envoy][target] = permission;
        emit SetPermission(envoy, target, permission);
    }

    /// @inheritdoc IPRBProxyHelpers
    function uninstallPlugin(IPRBProxyPlugin plugin) external {
        // Get the method list to uninstall.
        bytes4[] memory methodList = plugin.methodList();

        // The plugin must have at least one listed method.
        uint256 length = methodList.length;
        if (length == 0) {
            revert PRBProxy_NoPluginMethods(plugin);
        }

        // Disable every method in the list.
        for (uint256 i = 0; i < length; ) {
            delete plugins[methodList[i]];
            unchecked {
                i += 1;
            }
        }

        // Log the plugin uninstallation.
        emit UninstallPlugin(plugin);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IPRBProxyPlugin } from "./interfaces/IPRBProxyPlugin.sol";

/// @notice Abstract contract with the storage layout of the {PRBProxy} contract.
/// @dev This contract is an exact copy of the storage layout of {PRBProxy}, and it exists so that it can
/// be inherited in target contracts. However, to avoid overcomplicating the inheritance structure, this is
/// not inherited by the {PRBProxy} contract itself.
abstract contract PRBProxyStorage {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the owner account or contract.
    address public owner;

    /// @notice How much gas to reserve for running the remainder of the "execute" function after the DELEGATECALL.
    /// @dev This prevents the proxy from becoming unusable if EVM opcode gas costs change in the future.
    uint256 public minGasReserve;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps plugin methods to plugin implementation.
    mapping(bytes4 method => IPRBProxyPlugin plugin) internal plugins;

    /// @dev Maps envoys to target contracts to function selectors to boolean flags.
    mapping(address envoy => mapping(address target => bool permission)) internal permissions;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IPRBProxyPlugin } from "./IPRBProxyPlugin.sol";

/// @title IPRBProxyHelpers
/// @notice The enshrined target contract, with essential helper functions for:
/// - Permitting envoys to call target contracts on behalf of the proxy.
/// - Installing plugins on the proxy.
/// - Uninstalling plugins on the proxy.
interface IPRBProxyHelpers {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the plugin has no listed methods.
    error PRBProxy_NoPluginMethods(IPRBProxyPlugin plugin);

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a plugin is installed.
    event InstallPlugin(IPRBProxyPlugin indexed plugin);

    /// @notice Emitted when the owner sets the permission for an envoy.
    event SetPermission(address indexed envoy, address indexed target, bool permission);

    /// @notice Emitted when a plugin is uninstalled.
    event UninstallPlugin(IPRBProxyPlugin indexed plugin);

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The release version of the {PRBProxy} protocol.
    /// @dev This is stored in the factory rather than the proxy to save gas for end users.
    function VERSION() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Installs the provided plugin contract.
    ///
    /// @dev Emits an {InstallPlugin} event.
    ///
    /// Requirements:
    /// - The plugin must have at least one listed method.
    /// - By design, the plugin cannot implement any method that is also implemented by the proxy itself.
    ///
    /// Notes:
    /// - Does not revert if the plugin is already installed.
    /// - Installing a plugin is a potentially dangerous operation, because anyone can then call the plugin's methods.
    ///
    /// @param plugin The address of the plugin to install.
    function installPlugin(IPRBProxyPlugin plugin) external;

    /// @notice Gives or takes a permission from an envoy to call the provided target contract and function selector
    /// on behalf of the owner.
    ///
    /// @dev It is not an error to reset a permission on the same (envoy,target) tuple multiple types.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param envoy The address of the envoy account.
    /// @param target The address of the target contract.
    /// @param permission The boolean permission to set.
    function setPermission(address envoy, address target, bool permission) external;

    /// @notice Uninstalls the provided plugin contract.
    ///
    /// @dev Emits an {UninstallPlugin} event.
    ///
    /// Requirements:
    /// - The plugin must have at least one listed method.
    ///
    /// Notes:
    /// - Does not revert if the plugin is not already installed.
    ///
    /// @param plugin The address of the plugin to uninstall.
    function uninstallPlugin(IPRBProxyPlugin plugin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/// @title IPRBProxyPlugin
/// @notice Interface for the plugins that can be installed on a proxy.
interface IPRBProxyPlugin {
    /// @notice Lists the methods that the plugin implements.
    /// @dev These methods are installed and uninstalled by the proxy.
    ///
    /// Requirements:
    /// - The plugin needs at least one method to be listed.
    ///
    /// @return methods The methods that the plugin implements.
    function methodList() external returns (bytes4[] memory methods);
}