// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/access-control/IRBAC.sol";

import "../libs/arrays/ArrayHelper.sol";
import "../libs/arrays/SetHelper.sol";

/**
 *  @notice The Role Based Access Control (RBAC) module
 *
 *  This is advanced module that handles role management for huge systems. One can declare specific permissions
 *  for specific resources (contracts) and aggregate them into roles for further assignment to users.
 *
 *  Each user can have multiple roles and each role can manage multiple resources. Each resource can posses a set of
 *  permissions (CREATE, DELETE) that are only valid for that specific resource.
 *
 *  The RBAC model supports antipermissions as well. One can grant antipermissions to users to restrict their access level.
 *  There also is a special wildcard symbol "*" that means "everything". This symbol can be applied either to the
 *  resources or permissions.
 */
abstract contract RBAC is IRBAC, Initializable {
    using StringSet for StringSet.Set;
    using SetHelper for StringSet.Set;
    using ArrayHelper for string;

    string public constant MASTER_ROLE = "MASTER";

    string public constant ALL_RESOURCE = "*";
    string public constant ALL_PERMISSION = "*";

    string public constant CREATE_PERMISSION = "CREATE";
    string public constant READ_PERMISSION = "READ";
    string public constant UPDATE_PERMISSION = "UPDATE";
    string public constant DELETE_PERMISSION = "DELETE";

    string public constant RBAC_RESOURCE = "RBAC_RESOURCE";

    mapping(string => mapping(bool => mapping(string => StringSet.Set))) private _rolePermissions;
    mapping(string => mapping(bool => StringSet.Set)) private _roleResources;

    mapping(address => StringSet.Set) private _userRoles;

    modifier onlyPermission(string memory resource_, string memory permission_) {
        require(
            hasPermission(msg.sender, resource_, permission_),
            string(
                abi.encodePacked("RBAC: no ", permission_, " permission for resource ", resource_)
            )
        );
        _;
    }

    /**
     *  @notice The init function
     */
    function __RBAC_init() internal onlyInitializing {
        _addPermissionsToRole(MASTER_ROLE, ALL_RESOURCE, ALL_PERMISSION.asArray(), true);
    }

    /**
     *  @notice The function to grant roles to a user
     *  @param to_ the user to grant roles to
     *  @param rolesToGrant_ roles to grant
     */
    function grantRoles(
        address to_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        require(rolesToGrant_.length > 0, "RBAC: empty roles");

        _grantRoles(to_, rolesToGrant_);
    }

    /**
     *  @notice The function to revoke roles
     *  @param from_ the user to revoke roles from
     *  @param rolesToRevoke_ the roles to revoke
     */
    function revokeRoles(
        address from_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        require(rolesToRevoke_.length > 0, "RBAC: empty roles");

        _revokeRoles(from_, rolesToRevoke_);
    }

    /**
     *  @notice The function to add resource permission to role
     *  @param role_ the role to add permissions to
     *  @param permissionsToAdd_ the array of resources and permissions to add to the role
     *  @param allowed_ indicates whether to add permissions to an allowlist or disallowlist
     */
    function addPermissionsToRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToAdd_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToAdd_.length; i++) {
            _addPermissionsToRole(
                role_,
                permissionsToAdd_[i].resource,
                permissionsToAdd_[i].permissions,
                allowed_
            );
        }
    }

    /**
     *  @notice The function to remove permissions from role
     *  @param role_ the role to remove permissions from
     *  @param permissionsToRemove_ the array of resources and permissions to remove from the role
     *  @param allowed_ indicates whether to remove permissions from the allowlist or disallowlist
     */
    function removePermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToRemove_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToRemove_.length; i++) {
            _removePermissionsFromRole(
                role_,
                permissionsToRemove_[i].resource,
                permissionsToRemove_[i].permissions,
                allowed_
            );
        }
    }

    /**
     *  @notice The function to get the list of user roles
     *  @param who_ the user
     *  @return roles_ the roes of the user
     */
    function getUserRoles(address who_) public view override returns (string[] memory roles_) {
        return _userRoles[who_].values();
    }

    /**
     *  @notice The function to get the permissions of the role
     *  @param role_ the role
     *  @return allowed_ the list of allowed permissions of the role
     *  @return disallowed_ the list of disallowed permissions of the role
     */
    function getRolePermissions(
        string memory role_
    )
        public
        view
        override
        returns (
            ResourceWithPermissions[] memory allowed_,
            ResourceWithPermissions[] memory disallowed_
        )
    {
        StringSet.Set storage _allowedResources = _roleResources[role_][true];
        StringSet.Set storage _disallowedResources = _roleResources[role_][false];

        mapping(string => StringSet.Set) storage _allowedPermissions = _rolePermissions[role_][
            true
        ];
        mapping(string => StringSet.Set) storage _disallowedPermissions = _rolePermissions[role_][
            false
        ];

        allowed_ = new ResourceWithPermissions[](_allowedResources.length());
        disallowed_ = new ResourceWithPermissions[](_disallowedResources.length());

        for (uint256 i = 0; i < allowed_.length; i++) {
            allowed_[i].resource = _allowedResources.at(i);
            allowed_[i].permissions = _allowedPermissions[allowed_[i].resource].values();
        }

        for (uint256 i = 0; i < disallowed_.length; i++) {
            disallowed_[i].resource = _disallowedResources.at(i);
            disallowed_[i].permissions = _disallowedPermissions[disallowed_[i].resource].values();
        }
    }

    /**
     *  @notice The function to check the user's possesion of the role
     *  @param who_ the user
     *  @param resource_ the resource the user has to have the permission of
     *  @param permission_ the permission the user has to have
     *  @return true_ if user has the permission, false otherwise
     */
    function hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) public view override returns (bool) {
        StringSet.Set storage _roles = _userRoles[who_];

        uint256 length_ = _roles.length();
        bool isAllowed_;

        for (uint256 i = 0; i < length_; i++) {
            string memory role_ = _roles.at(i);

            StringSet.Set storage _allDisallowed = _rolePermissions[role_][false][ALL_RESOURCE];
            StringSet.Set storage _allAllowed = _rolePermissions[role_][true][ALL_RESOURCE];

            StringSet.Set storage _disallowed = _rolePermissions[role_][false][resource_];
            StringSet.Set storage _allowed = _rolePermissions[role_][true][resource_];

            if (
                _allDisallowed.contains(ALL_PERMISSION) ||
                _allDisallowed.contains(permission_) ||
                _disallowed.contains(ALL_PERMISSION) ||
                _disallowed.contains(permission_)
            ) {
                return false;
            }

            if (
                _allAllowed.contains(ALL_PERMISSION) ||
                _allAllowed.contains(permission_) ||
                _allowed.contains(ALL_PERMISSION) ||
                _allowed.contains(permission_)
            ) {
                isAllowed_ = true;
            }
        }

        return isAllowed_;
    }

    /**
     *  @notice The internal function to grant roles
     *  @param to_ the user to grant roles to
     *  @param rolesToGrant_ the roles to grant
     */
    function _grantRoles(address to_, string[] memory rolesToGrant_) internal {
        _userRoles[to_].add(rolesToGrant_);

        emit GrantedRoles(to_, rolesToGrant_);
    }

    /**
     *  @notice The internal function to revoke roles
     *  @param from_ the user to revoke roles from
     *  @param rolesToRevoke_ the roles to revoke
     */
    function _revokeRoles(address from_, string[] memory rolesToRevoke_) internal {
        _userRoles[from_].remove(rolesToRevoke_);

        emit RevokedRoles(from_, rolesToRevoke_);
    }

    /**
     *  @notice The internal function to add permission to the role
     *  @param role_ the role to add permissions to
     *  @param resourceToAdd_ the resource to which the permissions belong
     *  @param permissionsToAdd_ the permissions of the resource
     *  @param allowed_ whether to add permissions to the allowlist or the disallowlist
     */
    function _addPermissionsToRole(
        string memory role_,
        string memory resourceToAdd_,
        string[] memory permissionsToAdd_,
        bool allowed_
    ) internal {
        StringSet.Set storage _resources = _roleResources[role_][allowed_];
        StringSet.Set storage _permissions = _rolePermissions[role_][allowed_][resourceToAdd_];

        _permissions.add(permissionsToAdd_);
        _resources.add(resourceToAdd_);

        emit AddedPermissions(role_, resourceToAdd_, permissionsToAdd_, allowed_);
    }

    /**
     *  @notice The internal function to remove permissions from the role
     *  @param role_ the role to remove permissions from
     *  @param resourceToRemove_ the resource to which the permissions belong
     *  @param permissionsToRemove_ the permissions of the resource
     *  @param allowed_ whether to remove permissions from the allowlist or the disallowlist
     */
    function _removePermissionsFromRole(
        string memory role_,
        string memory resourceToRemove_,
        string[] memory permissionsToRemove_,
        bool allowed_
    ) internal {
        StringSet.Set storage _resources = _roleResources[role_][allowed_];
        StringSet.Set storage _permissions = _rolePermissions[role_][allowed_][resourceToRemove_];

        _permissions.remove(permissionsToRemove_);

        if (_permissions.length() == 0) {
            _resources.remove(resourceToRemove_);
        }

        emit RemovedPermissions(role_, resourceToRemove_, permissionsToRemove_, allowed_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./proxy/ProxyUpgrader.sol";
import "./AbstractDependant.sol";

/**
 *  @notice The ContractsRegistry module
 *
 *  The purpose of this module is to provide an organized registry of the project's smartcontracts
 *  together with the upgradeability and dependency injection mechanisms.
 *
 *  The ContractsRegistry should be used as the highest level smartcontract that is aware of any other
 *  contract present in the system. The contracts that demand other system's contracts would then inherit
 *  special `AbstractDependant` contract and override `setDependencies()` function to enable ContractsRegistry
 *  to inject dependencies into them.
 *
 *  The ContractsRegistry will help with the following usecases:
 *
 *  1) Making the system upgradeable
 *  2) Making the system contracts-interchangeable
 *  3) Simplifying the contracts management and deployment
 *
 *  The ContractsRegistry acts as a Transparent proxy deployer. One can add proxy-compatible implementations to the registry
 *  and deploy proxies to them. Then these proxies can be upgraded easily using the ContractsRegistry.
 *  The ContractsRegistry itself can be deployed behind a proxy as well.
 *
 *  The dependency injection system may come in handy when one wants to substitute a contract `A` with a contract `B`
 *  (for example contract `A` got exploited) without a necessity of redeploying the whole system. One would just add
 *  a new `B` contract to a ContractsRegistry and re-inject all the required dependencies. Dependency injection mechanism
 *  also works with factories.
 *
 *  The management is simplified because all of the contracts are now located in a single place.
 */
abstract contract AbstractContractsRegistry is Initializable {
    ProxyUpgrader private _proxyUpgrader;

    mapping(string => address) private _contracts;
    mapping(address => bool) private _isProxy;

    event AddedContract(string name, address contractAddress, bool isProxy);
    event RemovedContract(string name);

    /**
     *  @notice The proxy initializer function
     */
    function __ContractsRegistry_init() internal onlyInitializing {
        _proxyUpgrader = new ProxyUpgrader();
    }

    /**
     *  @notice The function that returns an associated contract with the name
     *  @param name_ the name of the contract
     *  @return the address of the contract
     */
    function getContract(string memory name_) public view returns (address) {
        address contractAddress_ = _contracts[name_];

        require(contractAddress_ != address(0), "ContractsRegistry: this mapping doesn't exist");

        return contractAddress_;
    }

    /**
     *  @notice The function that check if a contract with a given name has been added
     *  @param name_ the name of the contract
     *  @return true if the contract is present in the registry
     */
    function hasContract(string memory name_) public view returns (bool) {
        return _contracts[name_] != address(0);
    }

    /**
     *  @notice The function that returns the admin of the added proxy contracts
     *  @return the proxy admin address
     */
    function getProxyUpgrader() public view returns (address) {
        return address(_proxyUpgrader);
    }

    /**
     *  @notice The function that returns an implementation of the given proxy contract
     *  @param name_ the name of the contract
     *  @return the implementation address
     */
    function getImplementation(string memory name_) public view returns (address) {
        address contractProxy_ = _contracts[name_];

        require(contractProxy_ != address(0), "ContractsRegistry: this mapping doesn't exist");
        require(_isProxy[contractProxy_], "ContractsRegistry: not a proxy contract");

        return _proxyUpgrader.getImplementation(contractProxy_);
    }

    /**
     *  @notice The function that injects the dependencies into the given contract
     *  @param name_ the name of the contract
     */
    function _injectDependencies(string memory name_) internal {
        _injectDependenciesWithData(name_, bytes(""));
    }

    /**
     *  @notice The function that injects the dependencies into the given contract with data
     *  @param name_ the name of the contract
     *  @param data_ the extra context data
     */
    function _injectDependenciesWithData(string memory name_, bytes memory data_) internal {
        address contractAddress_ = _contracts[name_];

        require(contractAddress_ != address(0), "ContractsRegistry: this mapping doesn't exist");

        AbstractDependant dependant_ = AbstractDependant(contractAddress_);
        dependant_.setDependencies(address(this), data_);
    }

    /**
     *  @notice The function to upgrade added proxy contract with a new implementation
     *  @param name_ the name of the proxy contract
     *  @param newImplementation_ the new implementation the proxy should be upgraded to
     *
     *  It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContract(string memory name_, address newImplementation_) internal {
        _upgradeContractAndCall(name_, newImplementation_, bytes(""));
    }

    /**
     *  @notice The function to upgrade added proxy contract with a new implementation, providing data
     *  @param name_ the name of the proxy contract
     *  @param newImplementation_ the new implementation the proxy should be upgraded to
     *  @param data_ the data that the new implementation will be called with. This can be an ABI encoded function call
     *
     *  It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContractAndCall(
        string memory name_,
        address newImplementation_,
        bytes memory data_
    ) internal {
        address contractToUpgrade_ = _contracts[name_];

        require(contractToUpgrade_ != address(0), "ContractsRegistry: this mapping doesn't exist");
        require(_isProxy[contractToUpgrade_], "ContractsRegistry: not a proxy contract");

        _proxyUpgrader.upgrade(contractToUpgrade_, newImplementation_, data_);
    }

    /**
     *  @notice The function to add pure contracts to the ContractsRegistry. These should either be
     *  the contracts the system does not have direct upgradeability control over, or the contracts that are not upgradeable
     *  @param name_ the name to associate the contract with
     *  @param contractAddress_ the address of the contract
     */
    function _addContract(string memory name_, address contractAddress_) internal {
        require(contractAddress_ != address(0), "ContractsRegistry: zero address is forbidden");

        _contracts[name_] = contractAddress_;

        emit AddedContract(name_, contractAddress_, false);
    }

    /**
     *  @notice The function to add the contracts and deploy the proxy above them. It should be used to add
     *  contract that the ContractsRegistry should be able to upgrade
     *  @param name_ the name to associate the contract with
     *  @param contractAddress_ the address of the implementation
     */
    function _addProxyContract(string memory name_, address contractAddress_) internal {
        require(contractAddress_ != address(0), "ContractsRegistry: zero address is forbidden");

        address proxyAddr_ = address(
            new TransparentUpgradeableProxy(contractAddress_, address(_proxyUpgrader), bytes(""))
        );

        _contracts[name_] = proxyAddr_;
        _isProxy[proxyAddr_] = true;

        emit AddedContract(name_, proxyAddr_, true);
    }

    /**
     *  @notice The function to add the already deployed proxy to the ContractsRegistry. This might be used
     *  when the system migrates to a new ContractRegistry. This means that the new ProxyUpgrader must have the
     *  credentials to upgrade the added proxies
     *  @param name_ the name to associate the contract with
     *  @param contractAddress_ the address of the proxy
     */
    function _justAddProxyContract(string memory name_, address contractAddress_) internal {
        require(contractAddress_ != address(0), "ContractsRegistry: zero address is forbidden");

        _contracts[name_] = contractAddress_;
        _isProxy[contractAddress_] = true;

        emit AddedContract(name_, contractAddress_, true);
    }

    /**
     *  @notice The function to remove the contract from the ContractsRegistry
     *  @param name_ the associated name with the contract
     */
    function _removeContract(string memory name_) internal {
        address contractAddress_ = _contracts[name_];

        require(contractAddress_ != address(0), "ContractsRegistry: this mapping doesn't exist");

        delete _isProxy[contractAddress_];
        delete _contracts[name_];

        emit RemovedContract(name_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice The ContractsRegistry module
 *
 *  This is a contract that must be used as dependencies accepter in the dependency injection mechanism.
 *  Upon the injection, the Injector (ContractsRegistry most of the time) will call the `setDependencies()` function.
 *  The dependant contract will have to pull the required addresses from the supplied ContractsRegistry as a parameter.
 *
 *  The AbstractDependant is fully compatible with proxies courtesy of custom storage slot.
 */
abstract contract AbstractDependant {
    /**
     *  @notice The slot where the dependency injector is located.
     *  @dev bytes32(uint256(keccak256("eip6224.dependant.slot")) - 1)
     *
     *  Only the injector is allowed to inject dependencies.
     *  The first to call the setDependencies() (with the modifier applied) function becomes an injector
     */
    bytes32 private constant _INJECTOR_SLOT =
        0x3d1f25f1ac447e55e7fec744471c4dab1c6a2b6ffb897825f9ea3d2e8c9be583;

    modifier dependant() {
        _checkInjector();
        _;
        _setInjector(msg.sender);
    }

    /**
     *  @notice The function that will be called from the ContractsRegistry (or factory) to inject dependencies.
     *  @param contractsRegistry_ the registry to pull dependencies from
     *  @param data_ the extra data that might provide additional context
     *
     *  The Dependant must apply dependant() modifier to this function
     */
    function setDependencies(address contractsRegistry_, bytes calldata data_) external virtual;

    /**
     *  @notice The function is made external to allow for the factories to set the injector to the ContractsRegistry
     *  @param injector_ the new injector
     */
    function setInjector(address injector_) external {
        _checkInjector();
        _setInjector(injector_);
    }

    /**
     *  @notice The function to get the current injector
     *  @return injector_ the current injector
     */
    function getInjector() public view returns (address injector_) {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            injector_ := sload(slot_)
        }
    }

    /**
     *  @notice Internal function that sets the injector
     */
    function _setInjector(address injector_) internal {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            sstore(slot_, injector_)
        }
    }

    /**
     *  @notice Internal function that checks the injector credentials
     */
    function _checkInjector() internal view {
        address injector_ = getInjector();

        require(injector_ == address(0) || injector_ == msg.sender, "Dependant: not an injector");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../libs/arrays/Paginator.sol";

import "../../contracts-registry/AbstractDependant.sol";

import "./proxy/ProxyBeacon.sol";

/**
 *  @notice The PoolContractsRegistry module
 *
 *  This contract can be used as a pool registry that keeps track of deployed pools by the system.
 *  One can integrate factories to deploy and register pools or add them manually
 *
 *  The registry uses BeaconProxy pattern to provide upgradeability and Dependant pattern to provide dependency
 *  injection mechanism into the pools. This module should be used together with the ContractsRegistry module.
 *
 *  The users of this module have to override `_onlyPoolFactory()` method and revert in case a wrong msg.sender is
 *  trying to add pools into the registry.
 *
 *  The contract is ment to be used behind a proxy itself.
 */
abstract contract AbstractPoolContractsRegistry is Initializable, AbstractDependant {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;
    using Math for uint256;

    address internal _contractsRegistry;

    mapping(string => ProxyBeacon) private _beacons;
    mapping(string => EnumerableSet.AddressSet) internal _pools; // name => pool

    /**
     *  @notice The proxy initializer function
     */
    function __PoolContractsRegistry_init() internal onlyInitializing {}

    /**
     *  @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
     *  @param contractsRegistry_ the dependency registry
     */
    function setDependencies(
        address contractsRegistry_,
        bytes calldata
    ) public virtual override dependant {
        _contractsRegistry = contractsRegistry_;
    }

    /**
     *  @notice The function to get implementation of the specific pools
     *  @param name_ the name of the pools
     *  @return address_ the implementation these pools point to
     */
    function getImplementation(string memory name_) public view returns (address) {
        require(
            address(_beacons[name_]) != address(0),
            "PoolContractsRegistry: this mapping doesn't exist"
        );

        return _beacons[name_].implementation();
    }

    /**
     *  @notice The function to get the BeaconProxy of the specific pools (mostly needed in the factories)
     *  @param name_ the name of the pools
     *  @return address the BeaconProxy address
     */
    function getProxyBeacon(string memory name_) public view returns (address) {
        address beacon_ = address(_beacons[name_]);

        require(beacon_ != address(0), "PoolContractsRegistry: bad ProxyBeacon");

        return beacon_;
    }

    /**
     *  @notice The function to count pools by specified name
     *  @param name_ the associated pools name
     *  @return the number of pools with this name
     */
    function countPools(string memory name_) public view returns (uint256) {
        return _pools[name_].length();
    }

    /**
     *  @notice The paginated function to list pools by their name (call `countPools()` to account for pagination)
     *  @param name_ the associated pools name
     *  @param offset_ the starting index in the pools array
     *  @param limit_ the number of pools
     *  @return pools_ the array of pools proxies
     */
    function listPools(
        string memory name_,
        uint256 offset_,
        uint256 limit_
    ) public view returns (address[] memory pools_) {
        return _pools[name_].part(offset_, limit_);
    }

    /**
     *  @notice The function that sets pools' implementations. Deploys ProxyBeacons on the first set.
     *  This function is also used to upgrade pools
     *  @param names_ the names that are associated with the pools implementations
     *  @param newImplementations_ the new implementations of the pools (ProxyBeacons will point to these)
     */
    function _setNewImplementations(
        string[] memory names_,
        address[] memory newImplementations_
    ) internal {
        for (uint256 i = 0; i < names_.length; i++) {
            if (address(_beacons[names_[i]]) == address(0)) {
                _beacons[names_[i]] = new ProxyBeacon();
            }

            if (_beacons[names_[i]].implementation() != newImplementations_[i]) {
                _beacons[names_[i]].upgrade(newImplementations_[i]);
            }
        }
    }

    /**
     *  @notice The paginated function that injects new dependencies to the pools
     *  @param name_ the pools name that will be injected
     *  @param offset_ the starting index in the pools array
     *  @param limit_ the number of pools
     */
    function _injectDependenciesToExistingPools(
        string memory name_,
        uint256 offset_,
        uint256 limit_
    ) internal {
        _injectDependenciesToExistingPoolsWithData(name_, bytes(""), offset_, limit_);
    }

    /**
     *  @notice The paginated function that injects new dependencies to the pools with the data
     *  @param name_ the pools name that will be injected
     *  @param data_ the extra context data
     *  @param offset_ the starting index in the pools array
     *  @param limit_ the number of pools
     */
    function _injectDependenciesToExistingPoolsWithData(
        string memory name_,
        bytes memory data_,
        uint256 offset_,
        uint256 limit_
    ) internal {
        EnumerableSet.AddressSet storage _namedPools = _pools[name_];

        uint256 to_ = (offset_ + limit_).min(_namedPools.length()).max(offset_);

        require(to_ != offset_, "PoolContractsRegistry: no pools to inject");

        address contractsRegistry_ = _contractsRegistry;

        for (uint256 i = offset_; i < to_; i++) {
            AbstractDependant(_namedPools.at(i)).setDependencies(contractsRegistry_, data_);
        }
    }

    /**
     *  @notice The function to add new pools into the registry
     *  @param name_ the pool's associated name
     *  @param poolAddress_ the proxy address of the pool
     */
    function _addProxyPool(string memory name_, address poolAddress_) internal {
        _pools[name_].add(poolAddress_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 *  @notice The PoolContractsRegistry module
 *
 *  This is a utility lightweighted ProxyBeacon contract this is used as a beacon that BeaconProxies point to.
 */
contract ProxyBeacon is IBeacon {
    using Address for address;

    address private immutable _OWNER;

    address private _implementation;

    event Upgraded(address implementation);

    modifier onlyOwner() {
        require(_OWNER == msg.sender, "ProxyBeacon: not an owner");
        _;
    }

    constructor() {
        _OWNER = msg.sender;
    }

    function upgrade(address newImplementation_) external onlyOwner {
        require(newImplementation_.isContract(), "ProxyBeacon: not a contract");

        _implementation = newImplementation_;

        emit Upgraded(newImplementation_);
    }

    function implementation() external view override returns (address) {
        return _implementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../AbstractContractsRegistry.sol";

/**
 *  @notice The Ownable preset of ContractsRegistry
 */
contract OwnableContractsRegistry is AbstractContractsRegistry, OwnableUpgradeable {
    function __OwnableContractsRegistry_init() public initializer {
        __Ownable_init();
        __ContractsRegistry_init();
    }

    function injectDependencies(string calldata name_) external onlyOwner {
        _injectDependencies(name_);
    }

    function injectDependenciesWithData(
        string calldata name_,
        bytes calldata data_
    ) external onlyOwner {
        _injectDependenciesWithData(name_, data_);
    }

    function upgradeContract(
        string calldata name_,
        address newImplementation_
    ) external onlyOwner {
        _upgradeContract(name_, newImplementation_);
    }

    function upgradeContractAndCall(
        string calldata name_,
        address newImplementation_,
        bytes calldata data_
    ) external onlyOwner {
        _upgradeContractAndCall(name_, newImplementation_, data_);
    }

    function addContract(string calldata name_, address contractAddress_) external onlyOwner {
        _addContract(name_, contractAddress_);
    }

    function addProxyContract(string calldata name_, address contractAddress_) external onlyOwner {
        _addProxyContract(name_, contractAddress_);
    }

    function justAddProxyContract(
        string calldata name_,
        address contractAddress_
    ) external onlyOwner {
        _justAddProxyContract(name_, contractAddress_);
    }

    function removeContract(string calldata name_) external onlyOwner {
        _removeContract(name_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 *  @notice The ContractsRegistry module
 *
 *  This is the helper contract that is used by an AbstractContractsRegistry as a proxy admin.
 *  It is essential to distinguish between the admin and the registry due to the Transparent proxies nature
 */
contract ProxyUpgrader {
    using Address for address;

    address private immutable _OWNER;

    event Upgraded(address proxy, address implementation);

    modifier onlyOwner() {
        require(_OWNER == msg.sender, "ProxyUpgrader: not an owner");
        _;
    }

    constructor() {
        _OWNER = msg.sender;
    }

    function upgrade(address what_, address to_, bytes calldata data_) external onlyOwner {
        if (data_.length > 0) {
            TransparentUpgradeableProxy(payable(what_)).upgradeToAndCall(to_, data_);
        } else {
            TransparentUpgradeableProxy(payable(what_)).upgradeTo(to_);
        }

        emit Upgraded(what_, to_);
    }

    function getImplementation(address what_) external view onlyOwner returns (address) {
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success_, bytes memory returndata_) = address(what_).staticcall(hex"5c60da1b");
        require(success_);

        return abi.decode(returndata_, (address));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libs/data-structures/StringSet.sol";

/**
 *  @notice The RBAC module
 */
interface IRBAC {
    struct ResourceWithPermissions {
        string resource;
        string[] permissions;
    }

    event GrantedRoles(address to, string[] rolesToGrant);
    event RevokedRoles(address from, string[] rolesToRevoke);

    event AddedPermissions(string role, string resource, string[] permissionsToAdd, bool allowed);
    event RemovedPermissions(
        string role,
        string resource,
        string[] permissionsToRemove,
        bool allowed
    );

    function grantRoles(address to_, string[] memory rolesToGrant_) external;

    function revokeRoles(address from_, string[] memory rolesToRevoke_) external;

    function addPermissionsToRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToAdd_,
        bool allowed_
    ) external;

    function removePermissionsFromRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToRemove_,
        bool allowed_
    ) external;

    function getUserRoles(address who_) external view returns (string[] memory roles_);

    function getRolePermissions(
        string calldata role_
    )
        external
        view
        returns (
            ResourceWithPermissions[] calldata allowed_,
            ResourceWithPermissions[] calldata disallowed_
        );

    function hasPermission(
        address who_,
        string calldata resource_,
        string calldata permission_
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice A simple library to work with arrays
 */
library ArrayHelper {
    /**
     *  @notice The function to reverse an array
     *  @param arr_ the array to reverse
     *  @return reversed_ the reversed array
     */
    function reverse(uint256[] memory arr_) internal pure returns (uint256[] memory reversed_) {
        reversed_ = new uint256[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(address[] memory arr_) internal pure returns (address[] memory reversed_) {
        reversed_ = new address[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(string[] memory arr_) internal pure returns (string[] memory reversed_) {
        reversed_ = new string[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     *  @notice The function to insert an array into the other array
     *  @param to_ the array to insert into
     *  @param index_ the insertion starting index
     *  @param what_ the array to be inserted
     *  @return the index to start the next insertion from
     */
    function insert(
        uint256[] memory to_,
        uint256 index_,
        uint256[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        address[] memory to_,
        uint256 index_,
        address[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        string[] memory to_,
        uint256 index_,
        string[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     *  @notice The function to transform an element into an array
     *  @param elem_ the element
     *  @return array_ the element as an array
     */
    function asArray(uint256 elem_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = elem_;
    }

    function asArray(address elem_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = elem_;
    }

    function asArray(string memory elem_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = elem_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../data-structures/StringSet.sol";

/**
 *  @notice Library for pagination.
 *
 *  Supports the following data types `uin256[]`, `address[]`, `bytes32[]`, `UintSet`,
 *  `AddressSet`, `BytesSet`, `StringSet`.
 *
 */
library Paginator {
    using EnumerableSet for *;
    using StringSet for StringSet.Set;

    /**
     *  @notice Returns part of an array.
     *  @dev All functions below have the same description.
     *
     *  Examples:
     *  - part([4, 5, 6, 7], 0, 4) will return [4, 5, 6, 7]
     *  - part([4, 5, 6, 7], 2, 4) will return [6, 7]
     *  - part([4, 5, 6, 7], 2, 1) will return [6]
     *
     *  @param arr Storage array.
     *  @param offset_ Offset, index in an array.
     *  @param limit_ Number of elements after the `offset`.
     */
    function part(
        uint256[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (uint256[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(arr.length, offset_, limit_);

        list_ = new uint256[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    function part(
        address[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (address[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(arr.length, offset_, limit_);

        list_ = new address[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    function part(
        bytes32[] storage arr,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (bytes32[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(arr.length, offset_, limit_);

        list_ = new bytes32[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = arr[i];
        }
    }

    function part(
        EnumerableSet.UintSet storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (uint256[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new uint256[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function part(
        EnumerableSet.AddressSet storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (address[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new address[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function part(
        EnumerableSet.Bytes32Set storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (bytes32[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new bytes32[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function part(
        StringSet.Set storage set,
        uint256 offset_,
        uint256 limit_
    ) internal view returns (string[] memory list_) {
        uint256 to_ = _handleIncomingParametersForPart(set.length(), offset_, limit_);

        list_ = new string[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = set.at(i);
        }
    }

    function _handleIncomingParametersForPart(
        uint256 length_,
        uint256 offset_,
        uint256 limit_
    ) private pure returns (uint256 to_) {
        to_ = offset_ + limit_;

        if (to_ > length_) {
            to_ = length_;
        }

        if (offset_ > to_) {
            to_ = offset_;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../data-structures/StringSet.sol";

/**
 *  @notice A simple library to work with sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    /**
     *  @notice The function to insert an array of elements into the set
     *  @param set the set to insert the elements into
     *  @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     *  @notice The function to remove an array of elements from the set
     *  @param set the set to remove the elements from
     *  @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice Example:
 *
 *  using StringSet for StringSet.Set;
 *
 *  StringSet.Set internal set;
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     *  @notice The function add value to set
     *  @param set the set object
     *  @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function remove value to set
     *  @param set the set object
     *  @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastvalue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastvalue_;
                set._indexes[lastvalue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function returns true if value in the set
     *  @param set the set object
     *  @param value_ the value to search in set
     *  @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     *  @notice The function returns length of set
     *  @param set the set object
     *  @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     *  @notice The function returns value from set by index
     *  @param set the set object
     *  @param index_ the index of slot in set
     *  @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     *  @notice The function that returns values the set stores, can be very expensive to call
     *  @param set the set object
     *  @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant PRECISION = 10 ** 25;
uint256 constant DECIMAL = 10 ** 18;
uint256 constant PERCENTAGE_100 = 10 ** 27;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/utils/Globals.sol";

string constant MASTER_ROLE = "MASTER";

string constant CREATE_PERMISSION = "CREATE";
string constant UPDATE_PERMISSION = "UPDATE";
string constant EXECUTE_PERMISSION = "EXECUTE";
string constant DELETE_PERMISSION = "DELETE";

string constant CREATE_VOTING_PERMISSION = "CREATE";

string constant VOTE_PERMISSION = "VOTE";
string constant VETO_PERMISSION = "VETO";

string constant REGISTRY_RESOURCE = "REGISTRY_RESOURCE";

string constant DAO_MAIN_PANEL_NAME = "DAO_CONSTITUTION";

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "@dlsl/dev-modules/contracts-registry/AbstractContractsRegistry.sol";

import "../Globals.sol";

abstract contract RoleManagedRegistry is AbstractContractsRegistry, UUPSUpgradeable {
    string public constant PERMISSION_MANAGER_NAME = "PERMISSION_MANAGER";

    function __RoleManagedRegistry_init(address permissionManager_) internal onlyInitializing {
        __ContractsRegistry_init();
        _addProxyContract(PERMISSION_MANAGER_NAME, permissionManager_);
    }

    modifier onlyCreatePermission() virtual {
        _;
    }

    modifier onlyUpdatePermission() virtual {
        _;
    }

    modifier onlyDeletePermission() virtual {
        _;
    }

    function injectDependencies(string calldata name_) external onlyCreatePermission {
        _injectDependencies(name_);
    }

    function upgradeContract(
        string calldata name_,
        address newImplementation_
    ) external onlyUpdatePermission {
        _upgradeContract(name_, newImplementation_);
    }

    function upgradeContractAndCall(
        string calldata name_,
        address newImplementation_,
        bytes calldata data_
    ) external onlyUpdatePermission {
        _upgradeContractAndCall(name_, newImplementation_, data_);
    }

    function addContract(
        string calldata name_,
        address contractAddress_
    ) external onlyCreatePermission {
        _addContract(name_, contractAddress_);
    }

    function addProxyContract(
        string calldata name_,
        address contractAddress_
    ) external onlyCreatePermission {
        _addProxyContract(name_, contractAddress_);
    }

    function justAddProxyContract(
        string calldata name_,
        address contractAddress_
    ) external onlyCreatePermission {
        _justAddProxyContract(name_, contractAddress_);
    }

    function removeContract(string calldata name_) external onlyDeletePermission {
        _removeContract(name_);
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyCreatePermission {}
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/contracts-registry/presets/OwnableContractsRegistry.sol";

import "../interfaces/IDAORegistry.sol";
import "../interfaces/IDAORestriction.sol";
import "../interfaces/IDAOMemberStorage.sol";

import "../core/registry/RoleManagedRegistry.sol";
import "../core/Globals.sol";

import "./PermissionManager.sol";

// TODO: Add fields for DAO general information
contract DAORegistry is IDAORegistry, RoleManagedRegistry {
    string public constant TOKEN_FACTORY_NAME = "TOKEN_FACTORY";
    string public constant TOKEN_REGISTRY_NAME = "TOKEN_REGISTRY";
    string public constant VOTING_FACTORY_NAME = "VOTING_FACTORY";
    string public constant VOTING_REGISTRY_NAME = "VOTING_REGISTRY";

    string public constant DAO_MEMBER_STORAGE_NAME = "DAO_MEMBER_STORAGE";
    string public constant DAO_PARAMETER_STORAGE_NAME = "DAO_PARAMETER_STORAGE";

    string public DAO_REGISTRY_RESOURCE;

    PermissionManager internal _permissionManager;

    function __DAORegistry_init(
        address permissionManager_,
        address masterAccess_,
        string calldata registryResource_
    ) external initializer {
        __RoleManagedRegistry_init(permissionManager_);

        _permissionManager = PermissionManager(getContract(PERMISSION_MANAGER_NAME));

        string memory managerResource_ = string(
            abi.encodePacked(PERMISSION_MANAGER_NAME, ":", address(_permissionManager))
        );

        _permissionManager.__PermissionManager_init(masterAccess_, managerResource_);

        DAO_REGISTRY_RESOURCE = registryResource_;

        emit Initialized();
    }

    modifier onlyCreatePermission() override {
        _requirePermission(CREATE_PERMISSION);
        _;
    }

    modifier onlyUpdatePermission() override {
        _requirePermission(UPDATE_PERMISSION);
        _;
    }

    modifier onlyDeletePermission() override {
        _requirePermission(DELETE_PERMISSION);
        _;
    }

    function getDAOParameterStorage(string memory panelName_) public view returns (address) {
        return getContract(getDAOPanelResource(DAO_PARAMETER_STORAGE_NAME, panelName_));
    }

    function getDAOMemberStorage(string memory panelName_) public view returns (address) {
        return getContract(getDAOPanelResource(DAO_MEMBER_STORAGE_NAME, panelName_));
    }

    function getDAOPanelResource(
        string memory moduleType_,
        string memory panelName_
    ) public pure returns (string memory) {
        return string.concat(moduleType_, ":", panelName_);
    }

    function checkPermission(
        address member_,
        string calldata permission_,
        bool restrictedOnly
    ) external view returns (bool) {
        bool isExpertsExist_ = IDAOMemberStorage(getDAOMemberStorage(DAO_MAIN_PANEL_NAME))
            .getMembers()
            .length > 0;

        if (!restrictedOnly && !isExpertsExist_) {
            return true;
        }

        return _permissionManager.hasPermission(member_, DAO_REGISTRY_RESOURCE, permission_);
    }

    function getPermissionManager() external view returns (address) {
        return getContract(PERMISSION_MANAGER_NAME);
    }

    function getTokenFactory() external view returns (address) {
        return getContract(TOKEN_FACTORY_NAME);
    }

    function getTokenRegistry() external view returns (address) {
        return getContract(TOKEN_REGISTRY_NAME);
    }

    function getVotingFactory() external view returns (address) {
        return getContract(VOTING_FACTORY_NAME);
    }

    function getVotingRegistry() external view returns (address) {
        return getContract(VOTING_REGISTRY_NAME);
    }

    function _requirePermission(string memory permission_) internal view {
        require(
            _permissionManager.hasPermission(msg.sender, DAO_REGISTRY_RESOURCE, permission_),
            "MasterDAORegistry: access denied"
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/access-control/RBAC.sol";
import "@dlsl/dev-modules/contracts-registry/AbstractDependant.sol";

import "../interfaces/IPermissionManager.sol";

import "../libs/StaticArrayHelper.sol";

import "../core/Globals.sol";

contract PermissionManager is IPermissionManager, RBAC {
    using StaticArrayHelper for *;
    using ArrayHelper for string;

    string public PERMISSION_MANAGER_RESOURCE;

    function __PermissionManager_init(
        address master_,
        string calldata resource_
    ) external initializer {
        __RBAC_init();
        _grantRoles(master_, MASTER_ROLE.asArray());

        PERMISSION_MANAGER_RESOURCE = resource_;
    }

    function addCombinedPermissionsToRole(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) public override {
        addPermissionsToRole(role_, allowed_, true);
        addPermissionsToRole(role_, disallowed_, false);

        emit AddedRoleWithDescription(role_, description_);
    }

    function removeCombinedPermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) public override {
        removePermissionsFromRole(role_, allowed_, true);
        removePermissionsFromRole(role_, disallowed_, false);
    }

    function updateRolePermissions(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowedToRemove_,
        ResourceWithPermissions[] memory disallowedToRemove_,
        ResourceWithPermissions[] memory allowedToAdd_,
        ResourceWithPermissions[] memory disallowedToAdd_
    ) external override {
        removeCombinedPermissionsFromRole(role_, allowedToRemove_, disallowedToRemove_);
        addCombinedPermissionsToRole(role_, description_, allowedToAdd_, disallowedToAdd_);
    }

    function updateUserRoles(
        address user_,
        string[] memory rolesToRevoke_,
        string[] memory rolesToGrant_
    ) external override {
        revokeRoles(user_, rolesToRevoke_);
        grantRoles(user_, rolesToGrant_);
    }

    function hasDAORegistryCreatePermission(address account_) external view returns (bool) {
        return hasPermission(account_, REGISTRY_RESOURCE, CREATE_PERMISSION);
    }

    function hasDAORegistryUpdatePermission(address account_) external view returns (bool) {
        return hasPermission(account_, REGISTRY_RESOURCE, UPDATE_PERMISSION);
    }

    function hasDAORegistryDeletePermission(address account_) external view returns (bool) {
        return hasPermission(account_, REGISTRY_RESOURCE, DELETE_PERMISSION);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/contracts-registry/pools/AbstractPoolContractsRegistry.sol";

import "../../interfaces/factory/IFactoryDAORegistry.sol";

import "../../core/Globals.sol";

import "../../DAO/PermissionManager.sol";
import "../../DAO/DAORegistry.sol";

contract TokenRegistry is IFactoryDAORegistry, AbstractPoolContractsRegistry {
    string public constant TOKEN_REGISTRY_RESOURCE = "TOKEN_REGISTRY_RESOURCE";

    string public constant TOKEN_FACTORY_DEP = "TOKEN_FACTORY";

    string public constant TERC20_NAME = "TERC20";
    string public constant TERC721_NAME = "TERC721";

    PermissionManager internal _permissionManager;

    address internal _tokenFactory;

    modifier onlyCreatePermission() {
        _requirePermission(CREATE_PERMISSION);
        _;
    }

    modifier onlyTokenFactory() {
        require(_tokenFactory == msg.sender, "TokenRegistry: caller is not a factory");
        _;
    }

    function setDependencies(address registryAddress_, bytes calldata data_) public override {
        super.setDependencies(registryAddress_, data_);

        DAORegistry registry_ = DAORegistry(registryAddress_);

        _permissionManager = PermissionManager(registry_.getPermissionManager());
        _tokenFactory = registry_.getContract(TOKEN_FACTORY_DEP);
    }

    function setNewImplementations(
        string[] calldata names_,
        address[] calldata newImplementations_
    ) external override onlyCreatePermission {
        _setNewImplementations(names_, newImplementations_);
    }

    function injectDependenciesToExistingPools(
        string calldata name_,
        uint256 offset_,
        uint256 limit_
    ) external override onlyCreatePermission {
        _injectDependenciesToExistingPools(name_, offset_, limit_);
    }

    function injectDependenciesToExistingPoolsWithData(
        string calldata name_,
        bytes calldata data_,
        uint256 offset_,
        uint256 limit_
    ) external override onlyCreatePermission {
        _injectDependenciesToExistingPoolsWithData(name_, data_, offset_, limit_);
    }

    function addProxyPool(string calldata name_, address poolAddress_) external onlyTokenFactory {
        _addProxyPool(name_, poolAddress_);
    }

    function _requirePermission(string memory permission_) internal view {
        require(
            _permissionManager.hasPermission(msg.sender, TOKEN_REGISTRY_RESOURCE, permission_),
            "TokenRegistry: access denied"
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

interface IFactoryDAORegistry {
    function setNewImplementations(
        string[] calldata names_,
        address[] calldata newImplementations_
    ) external;

    function injectDependenciesToExistingPools(
        string calldata name_,
        uint256 offset_,
        uint256 limit_
    ) external;

    function injectDependenciesToExistingPoolsWithData(
        string calldata name_,
        bytes calldata data_,
        uint256 offset_,
        uint256 limit_
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "../libs/ParameterSet.sol";

import "./IDAORestriction.sol";

interface IDAOMemberStorage is IDAORestriction {
    struct ConstructorParams {
        address daoRegistry;
    }

    function addMember(address member_) external;

    function addMembers(address[] calldata members_) external;

    function removeMember(address member_) external;

    function getMembers() external view returns (address[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "./tokens/ITERC20.sol";

import "./IDAOVoting.sol";
import "./IDAORestriction.sol";

interface IDAORegistry is IDAORestriction {
    // TODO: 2 arrays should be equal
    struct ConstructorParams {
        address masterAccess;
        string[] tokenNames;
        address[] tokenAddresses;
        string[] votingNames;
        address[] votingAddresses;
        ITERC20.ConstructorParams tokenParams;
        IDAOVoting.ConstructorParams votingParams;
    }

    event Initialized();

    function getDAOPanelResource(
        string memory moduleType_,
        string memory panelName_
    ) external pure returns (string memory);

    function getDAOParameterStorage(string memory panelName_) external view returns (address);

    function getDAOMemberStorage(string memory panelName_) external view returns (address);

    function getPermissionManager() external view returns (address);

    function getTokenFactory() external view returns (address);

    function getTokenRegistry() external view returns (address);

    function getVotingFactory() external view returns (address);

    function getVotingRegistry() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

enum VotingType {
    RESTRICTED,
    NON_RESTRICTED
}

interface IDAORestriction {
    function checkPermission(
        address member_,
        string calldata permission_,
        bool restrictedOnly
    ) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "./IDAORestriction.sol";

interface IDAOVoting {
    enum ProposalStatus {
        NONE,
        PENDING,
        REJECTED,
        ACCEPTED,
        PASSED,
        EXECUTED,
        OBSOLETE,
        EXPIRED
    }

    enum VotingOption {
        NONE,
        FOR,
        AGAINST
    }

    enum VoteType {
        NONE,
        WEIGHTED,
        COUNTED
    }

    struct DAOVotingKeys {
        string votingPeriodKey;
        string vetoPeriodKey;
        string proposalExecutionPKey;
        string requiredQuorumKey;
    }

    struct DAOVotingValues {
        uint256 votingPeriod;
        uint256 vetoPeriod;
        uint256 proposalExecutionPeriod;
        uint256 requiredQuorum;
    }

    struct ConstructorParams {
        VotingType votingType;
        DAOVotingKeys votingKeys;
        DAOVotingValues votingValues;
        string panelName;
        string votingName;
        string votingDescription;
        address votingToken;
        address[] initialMembers;
    }

    struct VotingParams {
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 vetoEndTime;
        uint256 proposalExecutionP;
        uint256 requiredQuorum;
    }

    struct VotingCounters {
        uint256 votedFor;
        uint256 votedAgainst;
        uint256 vetoesCount;
    }

    struct VotingStats {
        uint256 requiredQuorum;
        uint256 currentQuorum;
        uint256 currentVetoPercentage;
    }

    struct DAOProposal {
        string remark;
        bytes callData;
        address target;
        VotingParams params;
        VotingCounters counters;
        bool executed;
    }

    event ProposalCreated(uint256 indexed id, DAOProposal proposal);

    function createProposal(
        address target_,
        string memory remark_,
        bytes memory callData_
    ) external returns (uint256);

    function voteFor(uint256 proposalId_) external;

    function voteAgainst(uint256 proposalId_) external;

    function veto(uint256 proposalId_) external;

    function executeProposal(uint256 proposalId_) external;

    function getProposal(uint256 proposalId_) external view returns (DAOProposal memory);

    function getProposalStatus(uint256 proposalId_) external view returns (ProposalStatus);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/interfaces/access-control/IRBAC.sol";

interface IPermissionManager is IRBAC {
    struct ConstructorParams {
        address master;
    }

    event AddedRoleWithDescription(string role, string description);

    function addCombinedPermissionsToRole(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) external;

    function removeCombinedPermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory allowed_,
        ResourceWithPermissions[] memory disallowed_
    ) external;

    function updateRolePermissions(
        string memory role_,
        string calldata description_,
        ResourceWithPermissions[] memory allowedToRemove_,
        ResourceWithPermissions[] memory disallowedToRemove_,
        ResourceWithPermissions[] memory allowedToAdd_,
        ResourceWithPermissions[] memory disallowedToAdd_
    ) external;

    function updateUserRoles(
        address user_,
        string[] memory rolesToRevoke_,
        string[] memory rolesToGrant_
    ) external;

    function hasDAORegistryCreatePermission(address account_) external view returns (bool);

    function hasDAORegistryUpdatePermission(address account_) external view returns (bool);

    function hasDAORegistryDeletePermission(address account_) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITERC20 is IERC20Upgradeable {
    struct ConstructorParams {
        string name;
        string symbol;
        string contractURI;
        uint8 decimals;
        uint256 totalSupplyCap;
    }

    function mintTo(address account_, uint256 amount_) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

enum ParameterType {
    NONE,
    ADDRESS,
    UINT,
    STRING,
    BYTES32,
    BOOL
}

struct Parameter {
    string name;
    bytes value;
    ParameterType solidityType;
}

library ParameterCodec {
    error InvalidParameterType(string name, ParameterType expected, ParameterType actual);

    function decodeAddress(Parameter memory parameter) internal pure returns (address) {
        _checkType(parameter, ParameterType.ADDRESS);

        return abi.decode(parameter.value, (address));
    }

    function decodeUint(Parameter memory parameter) internal pure returns (uint256) {
        _checkType(parameter, ParameterType.UINT);

        return abi.decode(parameter.value, (uint256));
    }

    function decodeString(Parameter memory parameter) internal pure returns (string memory) {
        _checkType(parameter, ParameterType.STRING);

        return abi.decode(parameter.value, (string));
    }

    function decodeBytes32(Parameter memory parameter) internal pure returns (bytes32) {
        _checkType(parameter, ParameterType.BYTES32);

        return abi.decode(parameter.value, (bytes32));
    }

    function decodeBool(Parameter memory parameter) internal pure returns (bool) {
        _checkType(parameter, ParameterType.BOOL);

        return abi.decode(parameter.value, (bool));
    }

    function encodeUint(
        uint256 value,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value), ParameterType.UINT);
    }

    function encodeAddress(
        address value,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value), ParameterType.ADDRESS);
    }

    function encodeString(
        string memory value,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value), ParameterType.STRING);
    }

    function encodeBytes32(
        bytes32 value,
        string memory name_
    ) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value), ParameterType.BYTES32);
    }

    function encodeBool(bool value, string memory name_) internal pure returns (Parameter memory) {
        return Parameter(name_, abi.encode(value), ParameterType.BOOL);
    }

    function _checkType(Parameter memory parameter, ParameterType expected) private pure {
        if (parameter.solidityType != expected) {
            revert InvalidParameterType(parameter.name, expected, parameter.solidityType);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "./Parameters.sol";

/**
 *  @notice A library for managing a set of parameters
 */
library ParameterSet {
    struct Set {
        Parameter[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     *  @notice The function add value to set
     *  @param set the set object
     *  @param parameter_ the parameter to add
     *  @return true if the value was added to the set, that is if it was not
     */
    function add(Set storage set, Parameter calldata parameter_) internal returns (bool) {
        if (!contains(set, parameter_.name)) {
            set._values.push(
                Parameter(parameter_.name, parameter_.value, parameter_.solidityType)
            );
            set._indexes[parameter_.name] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function change value in the set
     *  @param set the set object
     *  @param parameter_ the parameter to change
     *  @return true if the value was changed in the set, that is if it was not
     */
    function change(Set storage set, Parameter calldata parameter_) internal returns (bool) {
        if (contains(set, parameter_.name)) {
            set._values[set._indexes[parameter_.name] - 1] = parameter_;
            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function remove value to set
     *  @param set the set object
     *  @param name_ the name of the parameter to remove
     */
    function remove(Set storage set, string memory name_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[name_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                Parameter memory lastvalue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastvalue_;
                set._indexes[lastvalue_.name] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[name_];

            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice The function check if the parameter exists
     *  @param set the set object
     *  @param name_ the name of the parameter to check
     */
    function contains(Set storage set, string memory name_) internal view returns (bool) {
        return set._indexes[name_] != 0;
    }

    /**
     *  @notice The function returns value from set by name
     *  @param set the set object
     *  @param name_ the name of the parameter to get
     *  @return the value at name
     */
    function get(Set storage set, string memory name_) internal view returns (Parameter memory) {
        return set._values[set._indexes[name_] - 1];
    }

    /**
     *  @notice The function returns length of set
     *  @param set the set object
     *  @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     *  @notice The function returns value from set by index
     *  @param set the set object
     *  @param index_ the index of slot in set
     *  @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (Parameter memory) {
        return set._values[index_];
    }

    /**
     *  @notice The function that returns values the set stores, can be very expensive to call
     *  @param set the set object
     *  @return the memory array of values
     */
    function values(Set storage set) internal view returns (Parameter[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.18;

import "@dlsl/dev-modules/interfaces/access-control/IRBAC.sol";

import "./ParameterSet.sol";

library StaticArrayHelper {
    function asArray(string[1] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = elements_[0];
    }

    function asArray(string[2] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](2);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
    }

    function asArray(string[3] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](3);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
    }

    function asArray(string[4] memory elements_) internal pure returns (string[] memory array_) {
        array_ = new string[](4);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[1] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](1);
        array_[0] = elements_[0];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[2] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](2);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[3] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](3);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
    }

    function asArray(
        IRBAC.ResourceWithPermissions[4] memory elements_
    ) internal pure returns (IRBAC.ResourceWithPermissions[] memory array_) {
        array_ = new IRBAC.ResourceWithPermissions[](4);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
    }

    function asArray(
        Parameter[1] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](1);
        array_[0] = elements_[0];
    }

    function asArray(
        Parameter[2] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](2);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
    }

    function asArray(
        Parameter[3] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](3);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
    }

    function asArray(
        Parameter[4] memory elements_
    ) internal pure returns (Parameter[] memory array_) {
        array_ = new Parameter[](4);
        array_[0] = elements_[0];
        array_[1] = elements_[1];
        array_[2] = elements_[2];
        array_[3] = elements_[3];
    }
}