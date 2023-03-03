// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxy } from "./interfaces/IPRBProxy.sol";
import { IPRBProxyPlugin } from "./interfaces/IPRBProxyPlugin.sol";
import { IPRBProxyRegistry } from "./interfaces/IPRBProxyRegistry.sol";

/// @title PRBProxy
/// @dev This contract implements the {IPRBProxy} interface.
contract PRBProxy is IPRBProxy {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxy
    IPRBProxyRegistry public immutable override registry;

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxy
    address public override owner;

    /// @inheritdoc IPRBProxy
    uint256 public override minGasReserve;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps plugin methods to plugin implementation.
    mapping(bytes4 method => IPRBProxyPlugin plugin) internal plugins;

    /// @dev Maps envoys to target contracts to function selectors to boolean flags.
    mapping(address envoy => mapping(address target => bool permission)) internal permissions;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the proxy by fetching the constructor parameters from the registry.
    /// @dev This is implemented like this to make it easy to precompute the CREATE2 address of the proxy.
    constructor() {
        minGasReserve = 5000;
        registry = IPRBProxyRegistry(msg.sender);
        owner = IPRBProxyRegistry(msg.sender).transientProxyOwner();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  FALLBACK FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Used for running plugins.
    /// @dev Called when the call data is not empty.
    fallback(bytes calldata data) external payable returns (bytes memory response) {
        // Check if the function signature exists in the installed plugin methods mapping.
        IPRBProxyPlugin plugin = plugins[msg.sig];
        if (address(plugin) == address(0)) {
            revert PRBProxy_PluginNotInstalledForMethod(msg.sender, msg.sig);
        }

        // Delegate call to the plugin.
        bool success;
        (success, response) = _safeDelegateCall(address(plugin), data);

        // Log the plugin run.
        emit RunPlugin(plugin, data, response);

        // Check if the call has been successful or not.
        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (response.length > 0) {
                assembly {
                    let returndata_size := mload(response)
                    revert(add(32, response), returndata_size)
                }
            } else {
                revert PRBProxy_PluginReverted(plugin);
            }
        }
    }

    /// @dev Called when the call data is empty.
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxy
    function getPermission(address envoy, address target) external view override returns (bool permission) {
        permission = permissions[envoy][target];
    }

    /// @inheritdoc IPRBProxy
    function getPluginForMethod(bytes4 method) external view override returns (IPRBProxyPlugin plugin) {
        plugin = plugins[method];
    }

    /*/////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxy
    function execute(address target, bytes calldata data) external payable override returns (bytes memory response) {
        // Check that the caller is either the owner or an envoy with permission.
        if (owner != msg.sender && !permissions[msg.sender][target]) {
            revert PRBProxy_ExecutionUnauthorized({ owner: owner, caller: msg.sender, target: target });
        }

        // Check that the target is a valid contract.
        if (target.code.length == 0) {
            revert PRBProxy_TargetNotContract(target);
        }

        // Delegate call to the target contract.
        bool success;
        (success, response) = _safeDelegateCall(target, data);

        // Log the execution.
        emit Execute(target, data, response);

        // Check if the call has been successful or not.
        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error.
            if (response.length > 0) {
                assembly {
                    // The length of the data is at `response`, while the actual data is at `response + 32`.
                    let returndata_size := mload(response)
                    revert(add(response, 32), returndata_size)
                }
            } else {
                revert PRBProxy_ExecutionReverted();
            }
        }
    }

    /// @inheritdoc IPRBProxy
    function transferOwnership(address newOwner) external override {
        // Check that the caller is the registry.
        if (address(registry) != msg.sender) {
            revert PRBProxy_CallerNotRegistry({ registry: registry, caller: msg.sender });
        }

        // Effects: update the owner.
        owner = newOwner;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Performs a DELEGATECALL to the provided address with the provided data.
    /// @dev Shared logic between the {execute} and the {fallback} functions.
    function _safeDelegateCall(address to, bytes memory data) internal returns (bool success, bytes memory response) {
        // Save the owner address in memory. This variable cannot be modified during the DELEGATECALL.
        address owner_ = owner;

        // Reserve some gas to ensure that the function has enough to finish the execution.
        uint256 stipend = gasleft() - minGasReserve;

        // Delegate call to the provided contract.
        (success, response) = to.delegatecall{ gas: stipend }(data);

        // Check that the owner has not been changed.
        if (owner_ != owner) {
            revert PRBProxy_OwnerChanged(owner_, owner);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IPRBProxy } from "./interfaces/IPRBProxy.sol";
import { IPRBProxyRegistry } from "./interfaces/IPRBProxyRegistry.sol";
import { PRBProxy } from "./PRBProxy.sol";

/// @title PRBProxyRegistry
/// @dev This contract implements the {IPRBProxyRegistry} interface.
contract PRBProxyRegistry is IPRBProxyRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    string public constant override VERSION = "4.0.0-beta.2";

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    address public override transientProxyOwner;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal mapping between owners and proxies.
    mapping(address owner => IPRBProxy proxy) internal proxies;

    /// @dev Internal mapping to track the next seed to be used by an EOA.
    mapping(address eoa => bytes32 seed) internal nextSeeds;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Check that the owner does not have a proxy.
    modifier noProxy(address owner) {
        IPRBProxy proxy = proxies[owner];
        if (address(proxy) != address(0)) {
            revert PRBProxyRegistry_OwnerHasProxy(owner, proxy);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    function getNextSeed(address origin) external view override returns (bytes32 nextSeed) {
        nextSeed = nextSeeds[origin];
    }

    /// @inheritdoc IPRBProxyRegistry
    function getProxy(address owner) external view override returns (IPRBProxy proxy) {
        proxy = proxies[owner];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPRBProxyRegistry
    function deploy() external override noProxy(msg.sender) returns (IPRBProxy proxy) {
        proxy = _deploy({ owner: msg.sender });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployFor(address owner) public override noProxy(owner) returns (IPRBProxy proxy) {
        proxy = _deploy(owner);
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndExecute(
        address target,
        bytes calldata data
    )
        external
        override
        noProxy(msg.sender)
        returns (IPRBProxy proxy, bytes memory response)
    {
        (proxy, response) = _deployAndExecute({ owner: msg.sender, target: target, data: data });
    }

    /// @inheritdoc IPRBProxyRegistry
    function deployAndExecuteFor(
        address owner,
        address target,
        bytes calldata data
    )
        public
        override
        noProxy(owner)
        returns (IPRBProxy proxy, bytes memory response)
    {
        (proxy, response) = _deployAndExecute(owner, target, data);
    }

    /// @inheritdoc IPRBProxyRegistry
    function transferOwnership(address newOwner) external override noProxy(newOwner) {
        // Check that the caller has a proxy.
        IPRBProxy proxy = proxies[msg.sender];
        if (address(proxy) == address(0)) {
            revert PRBProxyRegistry_OwnerDoesNotHaveProxy({ owner: msg.sender });
        }

        // Delete the proxy for the caller.
        delete proxies[msg.sender];

        // Set the proxy for the new owner.
        proxies[newOwner] = proxy;

        // Transfer the proxy.
        proxy.transferOwnership(newOwner);

        // Log the transfer of the proxy ownership.
        emit TransferOwnership({ proxy: proxy, oldOwner: msg.sender, newOwner: newOwner });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _deploy(address owner) internal returns (IPRBProxy proxy) {
        // Load the next seed.
        bytes32 seed = nextSeeds[tx.origin];

        // Prevent front-running the salt by hashing the concatenation of "tx.origin" and the user-provided seed.
        bytes32 salt = keccak256(abi.encode(tx.origin, seed));

        // Deploy the proxy with CREATE2.
        transientProxyOwner = owner;
        proxy = new PRBProxy{ salt: salt }();
        delete transientProxyOwner;

        // Set the proxy for the owner.
        proxies[owner] = proxy;

        // Increment the seed.
        // We're using unchecked arithmetic here because this cannot realistically overflow, ever.
        unchecked {
            nextSeeds[tx.origin] = bytes32(uint256(seed) + 1);
        }

        // Log the proxy via en event.
        // forgefmt: disable-next-line
        emit DeployProxy({
            origin: tx.origin,
            operator: msg.sender,
            owner: owner,
            seed: seed,
            salt: salt,
            proxy: proxy
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _deployAndExecute(
        address owner,
        address target,
        bytes calldata data
    )
        internal
        returns (IPRBProxy proxy, bytes memory response)
    {
        // Load the next seed.
        bytes32 seed = nextSeeds[tx.origin];

        // Prevent front-running the salt by hashing the concatenation of "tx.origin" and the user-provided seed.
        bytes32 salt = keccak256(abi.encode(tx.origin, seed));

        // Deploy the proxy with CREATE2. The registry will temporarily be the owner of the proxy.
        transientProxyOwner = address(this);
        proxy = new PRBProxy{ salt: salt }();
        delete transientProxyOwner;

        // Set the proxy for the owner.
        proxies[owner] = proxy;

        // Increment the seed.
        // We're using unchecked arithmetic here because this cannot realistically overflow, ever.
        unchecked {
            nextSeeds[tx.origin] = bytes32(uint256(seed) + 1);
        }

        // Delegate call to the target contract.
        response = proxy.execute(target, data);

        // Transfer the ownership to the specified owner.
        proxy.transferOwnership(owner);

        // Log the proxy via en event.
        // forgefmt: disable-next-line
        emit DeployProxy({
            origin: tx.origin,
            operator: msg.sender,
            owner: owner,
            seed: seed,
            salt: salt,
            proxy: proxy
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IPRBProxyPlugin } from "./IPRBProxyPlugin.sol";
import { IPRBProxyRegistry } from "./IPRBProxyRegistry.sol";

/// @title IPRBProxy
/// @notice Proxy contract to compose transactions on owner's behalf.
interface IPRBProxy {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the caller is not the registry.
    error PRBProxy_CallerNotRegistry(IPRBProxyRegistry registry, address caller);

    /// @notice Thrown when execution reverted with no reason.
    error PRBProxy_ExecutionReverted();

    /// @notice Thrown when the caller is not the owner.
    error PRBProxy_ExecutionUnauthorized(address owner, address caller, address target);

    /// @notice Thrown when the owner is changed during the DELEGATECALL.
    error PRBProxy_OwnerChanged(address originalOwner, address newOwner);

    /// @notice Thrown when a plugin execution reverts with no reason.
    error PRBProxy_PluginReverted(IPRBProxyPlugin plugin);

    /// @notice Thrown when the fallback function does not find an installed plugin for the called method.
    error PRBProxy_PluginNotInstalledForMethod(address caller, bytes4 selector);

    /// @notice Thrown when passing an EOA or an undeployed contract as the target.
    error PRBProxy_TargetNotContract(address target);

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the proxy executes a delegate call to a target contract.
    event Execute(address indexed target, bytes data, bytes response);

    /// @notice Emitted when a plugin is run for a provided method.
    event RunPlugin(IPRBProxyPlugin indexed plugin, bytes data, bytes response);

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns a boolean flag that indicates whether the envoy has permission to call the provided target
    /// contract.
    function getPermission(address envoy, address target) external view returns (bool permission);

    /// @notice Returns the address of the plugin installed for the the provided method.
    /// @dev Returns the zero address if no plugin is installed.
    /// @param method The signature of the method to make the query for.
    function getPluginForMethod(bytes4 method) external view returns (IPRBProxyPlugin plugin);

    /// @notice How much gas to reserve for running the remainder of the "execute" function after the DELEGATECALL.
    /// @dev This prevents the proxy from becoming unusable if EVM opcode gas costs change in the future.
    function minGasReserve() external view returns (uint256);

    /// @notice The address of the owner account or contract.
    function owner() external view returns (address);

    /// @notice The address of the registry that has deployed this proxy.
    function registry() external view returns (IPRBProxyRegistry);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Delegate calls to the provided target contract by forwarding the data. It then returns the data it
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

    /// @notice Transfers the owner of the contract to a new account.
    ///
    /// @dev Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newOwner The address of the new owner account.
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

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
pragma solidity >=0.8.4;

import { IPRBProxy } from "./IPRBProxy.sol";

/// @title IPRBProxyRegistry
/// @notice Deploys new proxies with CREATE2 and keeps a registry of owners to proxies. Owners can only
/// have one proxy at a time.
interface IPRBProxyRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                       ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when some function requires the owner to not have a proxy.
    error PRBProxyRegistry_OwnerHasProxy(address owner, IPRBProxy proxy);

    /// @notice Thrown when some function requires the owner to have a proxy.
    error PRBProxyRegistry_OwnerDoesNotHaveProxy(address owner);

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new proxy is deployed.
    event DeployProxy(
        address indexed origin,
        address indexed operator,
        address indexed owner,
        bytes32 seed,
        bytes32 salt,
        IPRBProxy proxy
    );

    /// @notice Emitted when the owner transfers ownership of the proxy.
    event TransferOwnership(IPRBProxy proxy, address indexed oldOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The semantic version of the {PRBProxy} release.
    /// @dev This is stored in the registry rather than the proxy to save gas for end users.
    function VERSION() external view returns (string memory);

    /// @notice Returns the next seed that will be used to deploy the proxy.
    /// @param origin The externally owned account (EOA) that is part of the CREATE2 salt.
    function getNextSeed(address origin) external view returns (bytes32 result);

    /// @notice Gets the current proxy of the provided owner.
    /// @param proxy The address of the current proxy.
    function getProxy(address owner) external view returns (IPRBProxy proxy);

    /// @notice Gets the owner to be used in constructing the proxy, set transiently during proxy deployment.
    /// @dev This is called by the proxy to fetch the address of the owner.
    /// @return owner The address of the owner of the proxy.
    function transientProxyOwner() external view returns (address owner);

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys a new proxy with CREATE2 by setting the caller as the owner.
    ///
    /// @dev Emits a {DeployProxy} event.
    ///
    /// Requirements:
    /// - The owner must not have a proxy.
    ///
    /// @return proxy The address of the newly deployed proxy contract.
    function deploy() external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy with CREATE2 for the provided owner.
    ///
    /// @dev Emits a {DeployProxy} event.
    ///
    /// Requirements:
    /// - The owner must not have a proxy.
    ///
    /// @param owner The owner of the proxy.
    /// @return proxy The address of the newly deployed proxy contract.
    function deployFor(address owner) external returns (IPRBProxy proxy);

    /// @notice Deploys a new proxy via [email protected] by setting the caller as the owner, and delegate calls to the provided
    /// target contract by forwarding the data. It returns the data it gets back, bubbling up any potential revert.
    ///
    /// @dev Emits a {DeployProxy} and an {Execute} event.
    ///
    /// Requirements:
    /// - The owner must not have a proxy.
    /// - All from {PRBProxy-execute}.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return proxy The address of the newly deployed proxy contract.
    /// @return response The response received from the target contract.
    function deployAndExecute(
        address target,
        bytes calldata data
    )
        external
        returns (IPRBProxy proxy, bytes memory response);

    /// @notice Deploys a new proxy with CREATE2 for the provided owner, and delegate calls to the provided target
    /// contract by forwarding the data. It returns the data it gets back, bubbling up any potential revert.
    ///
    /// @dev Emits a {DeployProxy} and an {Execute} event.
    ///
    /// Requirements:
    /// - The owner must not have a proxy.
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
    )
        external
        returns (IPRBProxy proxy, bytes memory response);

    /// @notice Transfers the owner of the proxy to a new account.
    ///
    /// @dev Emits a {TransferOwnership} event.
    ///
    /// Requirements:
    /// - The caller must have a proxy.
    /// - The new owner must not have a proxy.
    ///
    /// @param newOwner The address of the new owner account.
    function transferOwnership(address newOwner) external;
}