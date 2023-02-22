// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxy } from "./interfaces/IPRBProxy.sol";
import { IPRBProxyFactory } from "./interfaces/IPRBProxyFactory.sol";
import { IPRBProxyRegistry } from "./interfaces/IPRBProxyRegistry.sol";

/*

██████╗ ██████╗ ██████╗ ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
██████╔╝██████╔╝██████╔╝██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝
██╔═══╝ ██╔══██╗██╔══██╗██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝
██║     ██║  ██║██████╔╝██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║
╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝

██████╗ ███████╗ ██████╗ ██╗███████╗████████╗██████╗ ██╗   ██╗
██╔══██╗██╔════╝██╔════╝ ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝
██████╔╝█████╗  ██║  ███╗██║███████╗   ██║   ██████╔╝ ╚████╔╝
██╔══██╗██╔══╝  ██║   ██║██║╚════██║   ██║   ██╔══██╗  ╚██╔╝
██║  ██║███████╗╚██████╔╝██║███████║   ██║   ██║  ██║   ██║
╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝

 */

/// @title PRBProxyRegistry
/// @author Paul Razvan Berg
/// @dev This contract implements the {IPRBProxyRegistry} interface.
contract PRBProxyRegistry is IPRBProxyRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    IPRBProxyFactory public immutable override factory;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal mapping of owners to current proxies.
    mapping(address owner => IPRBProxy currentProxy) internal currentProxies;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPRBProxyFactory factory_) {
        factory = factory_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Check that no proxy is currently registered for the owner.
    modifier noCurrentProxy(address owner) {
        IPRBProxy currentProxy = currentProxies[owner];
        if (address(currentProxy) != address(0) && currentProxy.owner() == owner) {
            revert PRBProxyRegistry_ProxyAlreadyExists(owner);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    function getCurrentProxy(address owner) external view override returns (IPRBProxy proxy) {
        proxy = currentProxies[owner];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    function deploy() external override returns (IPRBProxy proxy) {
        proxy = deployFor({ owner: msg.sender });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployFor(address owner) public override noCurrentProxy(owner) returns (IPRBProxy proxy) {
        // Deploy the proxy via the factory.
        proxy = factory.deployFor(owner);

        // Set or override the current proxy for the owner.
        currentProxies[owner] = proxy;
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndExecute(
        address target,
        bytes calldata data
    ) external override returns (IPRBProxy proxy, bytes memory response) {
        (proxy, response) = deployAndExecuteFor({ owner: msg.sender, target: target, data: data });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndExecuteFor(
        address owner,
        address target,
        bytes calldata data
    ) public override noCurrentProxy(owner) returns (IPRBProxy proxy, bytes memory response) {
        // Deploy the proxy via the factory, and delegate call to the target.
        (proxy, response) = factory.deployAndExecuteFor(owner, target, data);

        // Set or override the current proxy for the owner.
        currentProxies[owner] = proxy;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxyPlugin } from "./IPRBProxyPlugin.sol";

/// @title IPRBProxy
/// @author Paul Razvan Berg
/// @notice Proxy contract to compose transactions on owner's behalf.
interface IPRBProxy {
    /*//////////////////////////////////////////////////////////////////////////
                                    CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when execution reverted with no reason.
    error PRBProxy_ExecutionReverted();

    /// @notice Emitted when the caller is not the owner.
    error PRBProxy_ExecutionUnauthorized(address owner, address caller, address target, bytes4 selector);

    /// @notice Emitted when the caller is not the owner.
    error PRBProxy_NotOwner(address owner, address caller);

    /// @notice Emitted when the plugin has no listed methods.
    error PRBProxy_NoPluginMethods(IPRBProxyPlugin plugin);

    /// @notice Emitted when the owner is changed during the DELEGATECALL.
    error PRBProxy_OwnerChanged(address originalOwner, address newOwner);

    /// @notice Emitted when a plugin execution reverts with no reason.
    error PRBProxy_PluginReverted(IPRBProxyPlugin plugin);

    /// @notice Emitted when the fallback function does not find an installed plugin for the called method.
    error PRBProxy_PluginNotInstalledForMethod(address caller, bytes4 selector);

    /// @notice Emitted when passing an EOA or an undeployed contract as the target.
    error PRBProxy_TargetNotContract(address target);

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the proxy executes a delegate call to a target contract.
    event Execute(address indexed target, bytes data, bytes response);

    /// @notice Emitted when a plugin is installed.
    event InstallPlugin(IPRBProxyPlugin indexed plugin);

    /// @notice Emitted when a plugin is run for a given method.
    event RunPlugin(IPRBProxyPlugin indexed plugin, bytes data, bytes response);

    /// @notice Emitted when the owner sets the permission for an envoy.
    event SetPermission(address indexed envoy, address indexed target, bytes4 indexed selector, bool permission);

    /// @notice Emitted when the owner changes the proxy's owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    event UninstallPlugin(IPRBProxyPlugin indexed plugin);

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns a boolean flag that indicates whether the envoy has permission to call the given target
    /// contract and function selector.
    function getPermission(address envoy, address target, bytes4 selector) external view returns (bool permission);

    /// @notice Returns the address of the plugin installed for the the given method.
    /// @dev Returns the zero address if no plugin is installed.
    /// @param method The signature of the method to make the query for.
    function getPluginForMethod(bytes4 method) external view returns (IPRBProxyPlugin plugin);

    /// @notice The address of the owner account or contract.
    function owner() external view returns (address);

    /// @notice How much gas to reserve for running the remainder of the "execute" function after the DELEGATECALL.
    /// @dev This prevents the proxy from becoming unusable if EVM opcode gas costs change in the future.
    function minGasReserve() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Delegate calls to the given target contract by forwarding the data. It then returns the data it
    /// gets back, bubbling up any potential revert.
    ///
    /// @dev Emits an {Execute} event.
    ///
    /// Requirements:
    /// - The caller must be either an owner or an envoy with permission.
    /// - `target` must be a deployed contract.
    /// - The gas stipend must be greater than or equal to `minGasReserve`.
    /// - The owner must not be changed during the DELEGATECALL.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return response The response received from the target contract.
    function execute(address target, bytes calldata data) external payable returns (bytes memory response);

    /// @notice Installs a plugin contract, which provides a method list.
    ///
    /// @dev Emits an {InstallPlugin} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    /// - The plugin must have at least one listed method.
    /// - By design, the plugin cannot implement any method that is also implemented by the proxy itself.
    ///
    /// Notes:
    /// - Does not revert if the plugin is already installed.
    /// - Installing a plugin is a potentially dangerous operation, because anyone can call the plugin's methods.
    ///
    /// @param plugin The address of the plugin to install.
    function installPlugin(IPRBProxyPlugin plugin) external;

    /// @notice Gives or takes a permission from an envoy to call the given target contract and function selector
    /// on behalf of the owner.
    ///
    /// @dev It is not an error to reset a permission on the same (envoy,target,selector) tuple multiple types.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param envoy The address of the envoy account.
    /// @param target The address of the target contract.
    /// @param selector The 4 byte function selector on the target contract.
    /// @param permission The boolean permission to set.
    function setPermission(address envoy, address target, bytes4 selector, bool permission) external;

    /// @notice Transfers the owner of the contract to a new account.
    ///
    /// @dev Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newOwner The address of the new owner account.
    function transferOwnership(address newOwner) external;

    /// @notice Uninstalls a plugin contract, which provides a method list.
    ///
    /// @dev Emits an {UninstallPlugin} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
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

import { IPRBProxy } from "./IPRBProxy.sol";

/// @title IPRBProxyFactory
/// @author Paul Razvan Berg
/// @notice Deploys new proxies with CREATE2.
interface IPRBProxyFactory {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new proxy is deployed.
    event DeployProxy(
        address indexed origin,
        address indexed deployer,
        address indexed owner,
        bytes32 seed,
        bytes32 salt,
        IPRBProxy proxy
    );

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The release version of the {PRBProxy} protocol.
    /// @dev This is stored in the factory rather than the proxy to save gas for end users.
    function VERSION() external view returns (uint256);

    /// @notice Gets the next seed that will be used to deploy the proxy.
    /// @param eoa The externally owned account that will own the proxy.
    function getNextSeed(address eoa) external view returns (bytes32 result);

    /// @notice Checks if the given address is a deployed proxy.
    /// @param proxy The address of the proxy to make the query for.
    function isProxy(IPRBProxy proxy) external view returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new proxy with CREATE2 by setting the caller as the owner.
    /// @dev Emits a {DeployProxy} event.
    /// @return proxy The address of the newly deployed proxy contract.
    function deploy() external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy with CREATE2 for the given owner.
    /// @dev Emits a {DeployProxy} event.
    /// @param owner The owner of the proxy.
    /// @return proxy The address of the newly deployed proxy contract.
    function deployFor(address owner) external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy with CREATE2 by setting the caller as the owner, and delegate calls to the
    /// given target contract by forwarding the data. It returns the data it gets back, bubbling up any potential
    /// revert.
    ///
    /// @dev Emits a {DeployProxy} and an {Execute} event.
    ///
    /// Requirements:
    /// - All from {PRBProxy-execute}.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return proxy The address of the newly deployed proxy contract.
    /// @return response The response received from the target contract.
    function deployAndExecute(
        address target,
        bytes calldata data
    ) external returns (IPRBProxy proxy, bytes memory response);

    /// @notice Deploys a new proxy with CREATE2 for the given owner, and delegate calls to the given target
    /// contract by forwarding the data. It returns the data it gets back, bubbling up any potential revert.
    ///
    /// @dev Emits a {DeployProxy} and an {Execute} event.
    ///
    /// Requirements:
    /// - All from {PRBProxy-execute}.
    ///
    /// @param owner The owner of the proxy.
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return proxy The address of the newly deployed proxy contract.
    /// @return response The response received from the target contract.
    function deployAndExecuteFor(
        address owner,
        address target,
        bytes calldata data
    ) external returns (IPRBProxy proxy, bytes memory response);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxy } from "./IPRBProxy.sol";
import { IPRBProxyFactory } from "./IPRBProxyFactory.sol";

/// @title IPRBProxyRegistry
/// @author Paul Razvan Berg
/// @notice Deploys new proxies via the factory and keeps a registry of owners to proxies. Owners can only
/// have one proxy at a time.
interface IPRBProxyRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                    CUSTOM ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a proxy already exists for the given owner.
    error PRBProxyRegistry_ProxyAlreadyExists(address owner);

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the proxy factory contract.
    function factory() external view returns (IPRBProxyFactory proxyFactory);

    /// @notice Gets the current proxy of the given owner.
    /// @param owner The address of the owner of the current proxy.
    function getCurrentProxy(address owner) external view returns (IPRBProxy proxy);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new proxy via the proxy factory by setting the caller as the owner.
    ///
    /// @dev Emits a {DeployProxy} event.
    ///
    /// Requirements:
    /// - All from {deployFor}.
    ///
    /// @return proxy The address of the newly deployed proxy contract.
    function deploy() external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy via the proxy factory for the given owner.
    ///
    /// @dev Emits a {DeployProxy} event.
    ///
    /// Requirements:
    /// - The proxy must either not exist or its ownership must have been transferred by the owner.
    ///
    /// @param owner The owner of the proxy.
    /// @return proxy The address of the newly deployed proxy contract.
    function deployFor(address owner) external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy via the proxy factory by setting the caller as the owner, and delegate calls to the
    /// given target contract by forwarding the data. It returns the data it gets back, bubbling up any potential
    /// revert.
    ///
    /// @dev Emits a {DeployProxy} and an {Execute} event.
    ///
    /// Requirements:
    /// - All from {PRBProxyFactory-deployAndExecute}.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return proxy The address of the newly deployed proxy contract.
    /// @return response The response received from the target contract.
    function deployAndExecute(
        address target,
        bytes calldata data
    ) external returns (IPRBProxy proxy, bytes memory response);

    /// @notice Deploys a new proxy via the proxy factor for the given owner, and delegate calls to the given target
    /// contract by forwarding the data. It returns the data it gets back, bubbling up any potential revert.
    ///
    /// @dev Emits a {DeployProxy} and an {Execute} event.
    ///
    /// Requirements:
    /// - The proxy must either not exist or its ownership must have been transferred by the owner.
    /// - All from {PRBProxyFactory-deployAndExecuteFor}.
    ///
    /// @param owner The owner of the proxy.
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return proxy The address of the newly deployed proxy contract.
    /// @return response The response received from the target contract.
    function deployAndExecuteFor(
        address owner,
        address target,
        bytes calldata data
    ) external returns (IPRBProxy proxy, bytes memory response);
}