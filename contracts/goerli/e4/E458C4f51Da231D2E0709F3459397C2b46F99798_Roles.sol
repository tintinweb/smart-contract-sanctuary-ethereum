// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./AllowanceTracker.sol";
import "./PermissionBuilder.sol";
import "./PermissionChecker.sol";
import "./PermissionLoader.sol";

/**
 * @title Zodiac Roles Mod - granular, role-based, access control for your
 * on-chain avatar accounts (like Safe).
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 * @author Auryn Macmillan    - <[email protected]>
 * @author Nathan Ginnever    - <[email protected]>
 */
contract Roles is
    Modifier,
    AllowanceTracker,
    PermissionBuilder,
    PermissionChecker,
    PermissionLoader
{
    mapping(address => bytes32) public defaultRoles;

    event AssignRoles(address module, bytes32[] roleKeys, bool[] memberOf);
    event RolesModSetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address target
    );
    event SetDefaultRole(address module, bytes32 defaultRoleKey);

    error ArraysDifferentLength();

    /// Sender is allowed to make this call, but the internal transaction failed
    error ModuleTransactionFailed();

    /// @param _owner Address of the owner
    /// @param _avatar Address of the avatar (e.g. a Gnosis Safe)
    /// @param _target Address of the contract that will call exec function
    constructor(address _owner, address _avatar, address _target) {
        bytes memory initParams = abi.encode(_owner, _avatar, _target);
        setUp(initParams);
    }

    /// @dev There is no zero address check as solidty will check for
    /// missing arguments and the space of invalid addresses is too large
    /// to check. Invalid avatar or target address can be reset by owner.
    function setUp(bytes memory initParams) public override initializer {
        (address _owner, address _avatar, address _target) = abi.decode(
            initParams,
            (address, address, address)
        );
        __Ownable_init();

        avatar = _avatar;
        target = _target;

        _transferOwnership(_owner);
        setupModules();

        emit RolesModSetup(msg.sender, _owner, _avatar, _target);
    }

    /// @dev Assigns and revokes roles to a given module.
    /// @param module Module on which to assign/revoke roles.
    /// @param roleKeys Roles to assign/revoke.
    /// @param memberOf Assign (true) or revoke (false) corresponding roleKeys.
    function assignRoles(
        address module,
        bytes32[] calldata roleKeys,
        bool[] calldata memberOf
    ) external onlyOwner {
        if (roleKeys.length != memberOf.length) {
            revert ArraysDifferentLength();
        }
        for (uint16 i; i < roleKeys.length; ++i) {
            roles[roleKeys[i]].members[module] = memberOf[i];
        }
        if (!isModuleEnabled(module)) {
            enableModule(module);
        }
        emit AssignRoles(module, roleKeys, memberOf);
    }

    /// @dev Sets the default role used for a module if it calls execTransactionFromModule() or execTransactionFromModuleReturnData().
    /// @param module Address of the module on which to set default role.
    /// @param roleKey Role to be set as default.
    function setDefaultRole(
        address module,
        bytes32 roleKey
    ) external onlyOwner {
        defaultRoles[module] = roleKey;
        emit SetDefaultRole(module, roleKey);
    }

    /// @dev Passes a transaction to the modifier.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public override moduleOnly returns (bool success) {
        Consumption[] memory consumptions = _authorize(
            defaultRoles[msg.sender],
            to,
            value,
            data,
            operation
        );
        _flushPrepare(consumptions);
        success = exec(to, value, data, operation);
        _flushCommit(consumptions, success);
    }

    /// @dev Passes a transaction to the modifier, expects return data.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @notice Can only be called by enabled modules
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    )
        public
        override
        moduleOnly
        returns (bool success, bytes memory returnData)
    {
        Consumption[] memory consumptions = _authorize(
            defaultRoles[msg.sender],
            to,
            value,
            data,
            operation
        );
        _flushPrepare(consumptions);
        (success, returnData) = execAndReturnData(to, value, data, operation);
        _flushCommit(consumptions, success);
    }

    /// @dev Passes a transaction to the modifier assuming the specified role.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param roleKey Identifier of the role to assume for this transaction
    /// @param shouldRevert Should the function revert on inner execution returning success false?
    /// @notice Can only be called by enabled modules
    function execTransactionWithRole(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        bytes32 roleKey,
        bool shouldRevert
    ) public moduleOnly returns (bool success) {
        Consumption[] memory consumptions = _authorize(
            roleKey,
            to,
            value,
            data,
            operation
        );
        _flushPrepare(consumptions);
        success = exec(to, value, data, operation);
        if (shouldRevert && !success) {
            revert ModuleTransactionFailed();
        }
        _flushCommit(consumptions, success);
    }

    /// @dev Passes a transaction to the modifier assuming the specified role. Expects return data.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param roleKey Identifier of the role to assume for this transaction
    /// @param shouldRevert Should the function revert on inner execution returning success false?
    /// @notice Can only be called by enabled modules
    function execTransactionWithRoleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        bytes32 roleKey,
        bool shouldRevert
    ) public moduleOnly returns (bool success, bytes memory returnData) {
        Consumption[] memory consumptions = _authorize(
            roleKey,
            to,
            value,
            data,
            operation
        );
        _flushPrepare(consumptions);
        (success, returnData) = execAndReturnData(to, value, data, operation);
        if (shouldRevert && !success) {
            revert ModuleTransactionFailed();
        }
        _flushCommit(consumptions, success);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Modifier Interface - A contract that sits between a Module and an Avatar and enforce some additional logic.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "./Module.sol";

abstract contract Modifier is Module, IAvatar {
    address internal constant SENTINEL_MODULES = address(0x1);
    /// Mapping of modules.
    mapping(address => address) internal modules;

    /// `sender` is not an authorized module.
    /// @param sender The address of the sender.
    error NotAuthorized(address sender);

    /// `module` is invalid.
    error InvalidModule(address module);

    /// `module` is already disabled.
    error AlreadyDisabledModule(address module);

    /// `module` is already enabled.
    error AlreadyEnabledModule(address module);

    /// @dev `setModules()` was already called.
    error SetupModulesAlreadyCalled();

    /*
    --------------------------------------------------
    You must override at least one of following two virtual functions,
    execTransactionFromModule() and execTransactionFromModuleReturnData().
    */

    /// @dev Passes a transaction to the modifier.
    /// @notice Can only be called by enabled modules.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public virtual override moduleOnly returns (bool success) {}

    /// @dev Passes a transaction to the modifier, expects return data.
    /// @notice Can only be called by enabled modules.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    )
        public
        virtual
        override
        moduleOnly
        returns (bool success, bytes memory returnData)
    {}

    /*
    --------------------------------------------------
    */

    modifier moduleOnly() {
        if (modules[msg.sender] == address(0)) revert NotAuthorized(msg.sender);
        _;
    }

    /// @dev Disables a module on the modifier.
    /// @notice This can only be called by the owner.
    /// @param prevModule Module that pointed to the module to be removed in the linked list.
    /// @param module Module to be removed.
    function disableModule(
        address prevModule,
        address module
    ) public override onlyOwner {
        if (module == address(0) || module == SENTINEL_MODULES)
            revert InvalidModule(module);
        if (modules[prevModule] != module) revert AlreadyDisabledModule(module);
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Enables a module that can add transactions to the queue
    /// @param module Address of the module to be enabled
    /// @notice This can only be called by the owner
    function enableModule(address module) public override onlyOwner {
        if (module == address(0) || module == SENTINEL_MODULES)
            revert InvalidModule(module);
        if (modules[module] != address(0)) revert AlreadyEnabledModule(module);
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(
        address _module
    ) public view override returns (bool) {
        return SENTINEL_MODULES != _module && modules[_module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view override returns (address[] memory array, address next) {
        /// Init array with max page size.
        array = new address[](pageSize);

        /// Populate return array.
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (
            currentModule != address(0x0) &&
            currentModule != SENTINEL_MODULES &&
            moduleCount < pageSize
        ) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        /// Set correct size of returned array.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }

    /// @dev Initializes the modules linked list.
    /// @notice Should be called as part of the `setUp` / initializing function and can only be called once.
    function setupModules() internal {
        if (modules[SENTINEL_MODULES] != address(0))
            revert SetupModulesAlreadyCalled();
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        address currentGuard = guard;
        if (currentGuard != address(0)) {
            IGuard(currentGuard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
            success = IAvatar(target).execTransactionFromModule(
                to,
                value,
                data,
                operation
            );
            IGuard(currentGuard).checkAfterExecution(bytes32("0x"), success);
        } else {
            success = IAvatar(target).execTransactionFromModule(
                to,
                value,
                data,
                operation
            );
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        address currentGuard = guard;
        if (currentGuard != address(0)) {
            IGuard(currentGuard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
            (success, returnData) = IAvatar(target)
                .execTransactionFromModuleReturnData(
                    to,
                    value,
                    data,
                    operation
                );
            IGuard(currentGuard).checkAfterExecution(bytes32("0x"), success);
        } else {
            (success, returnData) = IAvatar(target)
                .execTransactionFromModuleReturnData(
                    to,
                    value,
                    data,
                    operation
                );
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    address public guard;

    event ChangedGuard(address guard);

    /// `guard_` does not implement IERC165.
    error NotIERC165Compliant(address guard_);

    /// @dev Set a guard that checks transactions before execution.
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard.
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            if (!BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId))
                revert NotIERC165Compliant(_guard);
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IMultiSend {
    function multiSend(bytes memory transactions) external payable;
}

struct UnwrappedTransaction {
    Enum.Operation operation;
    address to;
    uint256 value;
    // We wanna deal in calldata slices. We return location, let invoker slice
    uint256 dataLocation;
    uint256 dataSize;
}

interface ITransactionUnwrapper {
    function unwrap(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external view returns (UnwrappedTransaction[] memory result);
}

interface ICustomCondition {
    function check(
        uint256 value,
        bytes calldata data,
        uint256 location,
        uint256 size,
        bytes12 extra
    ) external pure returns (bool success, bytes32 reason);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Core.sol";

/**
 * @title AllowanceTracker - a component of the Zodiac Roles Mod that is
 * responsible for loading and calculating allowance balances. Persists
 * consumptions back to storage.
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 */
abstract contract AllowanceTracker is Core {
    event ConsumeAllowance(
        bytes32 allowanceKey,
        uint128 consumed,
        uint128 newBalance
    );

    function _accruedAllowance(
        Allowance memory allowance,
        uint256 timestamp
    ) internal pure override returns (uint128 balance, uint64 refillTimestamp) {
        if (
            allowance.refillInterval == 0 ||
            timestamp < allowance.refillTimestamp + allowance.refillInterval
        ) {
            return (allowance.balance, allowance.refillTimestamp);
        }

        uint64 elapsedIntervals = (uint64(timestamp) -
            allowance.refillTimestamp) / allowance.refillInterval;

        uint128 uncappedBalance = allowance.balance +
            allowance.refillAmount *
            elapsedIntervals;

        balance = uncappedBalance < allowance.maxBalance
            ? uncappedBalance
            : allowance.maxBalance;

        refillTimestamp =
            allowance.refillTimestamp +
            elapsedIntervals *
            allowance.refillInterval;
    }

    /**
     * @dev Flushes the consumption of allowances back into storage, before
     * execution. This flush is not final
     * @param consumptions The array of consumption structs containing
     * information about allowances and consumed amounts.
     */
    function _flushPrepare(Consumption[] memory consumptions) internal {
        uint256 count = consumptions.length;

        for (uint256 i; i < count; ) {
            Consumption memory consumption = consumptions[i];

            bytes32 key = consumption.allowanceKey;
            uint128 consumed = consumption.consumed;

            // Retrieve the allowance and calculate its current updated balance
            // and next refill timestamp.
            Allowance storage allowance = allowances[key];
            (uint128 balance, uint64 refillTimestamp) = _accruedAllowance(
                allowance,
                block.timestamp
            );

            assert(balance == consumption.balance);
            assert(consumed <= balance);
            // Flush
            allowance.balance = balance - consumed;
            allowance.refillTimestamp = refillTimestamp;

            // Emit an event to signal the total consumed amount.
            emit ConsumeAllowance(key, consumed, balance - consumed);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Finalizes or reverts the flush of allowances, after transaction
     * execution
     * @param consumptions The array of consumption structs containing
     * information about allowances and consumed amounts.
     * @param success a boolean that indicates whether transaction execution
     * was successful
     */
    function _flushCommit(
        Consumption[] memory consumptions,
        bool success
    ) internal {
        uint256 count = consumptions.length;
        for (uint256 i; i < count; ) {
            Consumption memory consumption = consumptions[i];
            bytes32 key = consumption.allowanceKey;
            if (success) {
                emit ConsumeAllowance(
                    key,
                    consumption.consumed,
                    consumption.balance - consumption.consumed
                );
            } else {
                allowances[key].balance = consumption.balance;
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Types.sol";

/**
 * @title Consumptions - a library that provides helper functions for dealing
 * with collection of Consumptions.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Consumptions {
    function clone(
        Consumption[] memory consumptions
    ) internal pure returns (Consumption[] memory result) {
        uint256 length = consumptions.length;

        result = new Consumption[](length);
        for (uint256 i; i < length; ) {
            result[i].allowanceKey = consumptions[i].allowanceKey;
            result[i].balance = consumptions[i].balance;
            result[i].consumed = consumptions[i].consumed;

            unchecked {
                ++i;
            }
        }
    }

    function find(
        Consumption[] memory consumptions,
        bytes32 key
    ) internal pure returns (uint256, bool) {
        uint256 length = consumptions.length;

        for (uint256 i; i < length; ) {
            if (consumptions[i].allowanceKey == key) {
                return (i, true);
            }

            unchecked {
                ++i;
            }
        }

        return (0, false);
    }

    function merge(
        Consumption[] memory c1,
        Consumption[] memory c2
    ) internal pure returns (Consumption[] memory result) {
        if (c1.length == 0) return c2;
        if (c2.length == 0) return c1;

        result = new Consumption[](c1.length + c2.length);

        uint256 length = c1.length;

        for (uint256 i; i < length; ) {
            result[i].allowanceKey = c1[i].allowanceKey;
            result[i].balance = c1[i].balance;
            result[i].consumed = c1[i].consumed;

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < c2.length; ) {
            (uint256 index, bool found) = find(c1, c2[i].allowanceKey);
            if (found) {
                result[index].consumed += c2[i].consumed;
            } else {
                result[length].allowanceKey = c2[i].allowanceKey;
                result[length].balance = c2[i].balance;
                result[length].consumed = c2[i].consumed;
                length++;
            }

            unchecked {
                ++i;
            }
        }

        if (length < result.length) {
            assembly {
                mstore(result, length)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "./Types.sol";

/**
 * @title Core is the base contract for the Zodiac Roles Mod, which defines
 * the common abstract connection points between Builder, Loader, and Checker.
 * @author Cristóvão Honorato - <[email protected]>
 */
abstract contract Core is Modifier {
    mapping(bytes32 => Role) internal roles;
    mapping(bytes32 => Allowance) public allowances;

    function _store(
        Role storage role,
        bytes32 key,
        ConditionFlat[] memory conditions,
        ExecutionOptions options
    ) internal virtual;

    function _load(
        Role storage role,
        bytes32 key
    ) internal view virtual returns (Condition memory, Consumption[] memory);

    function _accruedAllowance(
        Allowance memory allowance,
        uint256 timestamp
    ) internal pure virtual returns (uint128 balance, uint64 refillTimestamp);

    function _key(
        address targetAddress,
        bytes4 selector
    ) internal pure returns (bytes32) {
        /*
         * Unoptimized version:
         * bytes32(abi.encodePacked(targetAddress, selector))
         */
        return bytes32(bytes20(targetAddress)) | (bytes32(selector) >> 160);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Topology.sol";

/**
 * @title Decoder - a library that discovers parameter locations in calldata
 * from a list of conditions.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Decoder {
    error CalldataOutOfBounds();

    /**
     * @dev Maps the location and size of parameters in the encoded transaction data.
     * @param data The encoded transaction data.
     * @param condition The condition of the parameters.
     * @return result The mapped location and size of parameters in the encoded transaction data.
     */
    function inspect(
        bytes calldata data,
        Condition memory condition
    ) internal pure returns (ParameterPayload memory result) {
        /*
         * In the parameter encoding area, there is a region called the head
         * that is divided into 32-byte chunks. Each parameter has its own
         * corresponding chunk in the head region:
         * - Static parameters are encoded inline.
         * - Dynamic parameters have an offset to the tail, which is the start
         *   of the actual encoding for the dynamic parameter. Note that the
         *   offset does not include the 4-byte function signature."
         *
         */
        Topology.TypeTree memory node = Topology.typeTree(condition);
        __block__(data, 4, node, node.children.length, false, result);
        result.location = 0;
        result.size = data.length;
    }

    /**
     * @dev Walks through a parameter encoding tree and maps their location and
     * size within calldata.
     * @param data The encoded transaction data.
     * @param location The current offset within the calldata buffer.
     * @param node The current node being traversed within the parameter tree.
     * @param result The location and size of the parameter within calldata.
     */
    function _walk(
        bytes calldata data,
        uint256 location,
        Topology.TypeTree memory node,
        ParameterPayload memory result
    ) private pure {
        ParameterType paramType = node.paramType;

        if (paramType == ParameterType.Static) {
            result.size = 32;
        } else if (paramType == ParameterType.Dynamic) {
            result.size = 32 + _ceil32(uint256(word(data, location)));
        } else if (paramType == ParameterType.Tuple) {
            __block__(
                data,
                location,
                node,
                node.children.length,
                false,
                result
            );
        } else if (paramType == ParameterType.Array) {
            __block__(
                data,
                location + 32,
                node,
                uint256(word(data, location)),
                true,
                result
            );
            result.size += 32;
        } else if (paramType == ParameterType.AbiEncoded) {
            __block__(
                data,
                location + 32 + 4,
                node,
                node.children.length,
                false,
                result
            );
            result.size = 32 + _ceil32(uint256(word(data, location)));
        }
        result.location = location;
    }

    /**
     * @dev Recursively walk through the TypeTree to decode a block of parameters.
     * @param data The encoded transaction data.
     * @param location The current location of the parameter block being processed.
     * @param node The current TypeTree node being processed.
     * @param length The number of parts in the block.
     * @param template whether first child is type descriptor for all parts.
     * @param result The decoded ParameterPayload.
     */
    function __block__(
        bytes calldata data,
        uint256 location,
        Topology.TypeTree memory node,
        uint256 length,
        bool template,
        ParameterPayload memory result
    ) private pure {
        result.children = new ParameterPayload[](length);
        bool isInline;
        if (template) isInline = Topology.isInline(node.children[0]);

        uint256 offset;
        for (uint256 i; i < length; ) {
            if (!template) isInline = Topology.isInline(node.children[i]);

            _walk(
                data,
                _locationInBlock(data, location, offset, isInline),
                node.children[template ? 0 : i],
                result.children[i]
            );

            uint256 childSize = result.children[i].size;
            result.size += isInline ? childSize : childSize + 32;
            offset += isInline ? childSize : 32;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns the location of a block part, which may be located inline
     * within the block - at the HEAD - or at an offset relative to the start
     * of the block - at the TAIL.
     *
     * @param data The encoded transaction data.
     * @param location The location of the block within the calldata buffer.
     * @param offset The offset of the block part, relative to the start of the block.
     * @param isInline Whether the block part is located inline within the block.
     *
     * @return The location of the block part within the calldata buffer.
     */
    function _locationInBlock(
        bytes calldata data,
        uint256 location,
        uint256 offset,
        bool isInline
    ) private pure returns (uint256) {
        uint256 headLocation = location + offset;
        if (isInline) {
            return headLocation;
        } else {
            return location + uint256(word(data, headLocation));
        }
    }

    /**
     * @dev Plucks a slice of bytes from calldata.
     * @param data The calldata to pluck the slice from.
     * @param location The starting location of the slice.
     * @param size The size of the slice.
     * @return A slice of bytes from calldata.
     */
    function pluck(
        bytes calldata data,
        uint256 location,
        uint256 size
    ) internal pure returns (bytes calldata) {
        return data[location:location + size];
    }

    /**
     * @dev Loads a word from calldata.
     * @param data The calldata to load the word from.
     * @param location The starting location of the slice.
     * @return result 32 byte word from calldata.
     */
    function word(
        bytes calldata data,
        uint256 location
    ) internal pure returns (bytes32 result) {
        if (location + 32 > data.length) {
            revert CalldataOutOfBounds();
        }
        assembly {
            result := calldataload(add(data.offset, location))
        }
    }

    function _ceil32(uint256 size) private pure returns (uint256) {
        // pad size. Source: http://www.cs.nott.ac.uk/~psarb2/G51MPC/slides/NumberLogic.pdf
        return ((size + 32 - 1) / 32) * 32;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Topology.sol";

/**
 * @title Integrity, A library that validates condition integrity, and
 * adherence to the expected input structure and rules.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Integrity {
    error UnsuitableRootNode();

    error NotBFS();

    error UnsuitableParameterType(uint256 index);

    error UnsuitableCompValue(uint256 index);

    error UnsupportedOperator(uint256 index);

    error UnsuitableParent(uint256 index);

    error UnsuitableChildCount(uint256 index);

    error UnsuitableChildTypeTree(uint256 index);

    function enforce(ConditionFlat[] memory conditions) external pure {
        _root(conditions);
        for (uint256 i = 0; i < conditions.length; ++i) {
            _node(conditions[i], i);
        }
        _tree(conditions);
    }

    function _root(ConditionFlat[] memory conditions) private pure {
        uint256 count;

        for (uint256 i; i < conditions.length; ++i) {
            if (conditions[i].parent == i) ++count;
        }
        if (count != 1 || conditions[0].parent != 0) {
            revert UnsuitableRootNode();
        }
    }

    function _node(ConditionFlat memory condition, uint256 index) private pure {
        Operator operator = condition.operator;
        ParameterType paramType = condition.paramType;
        bytes memory compValue = condition.compValue;
        if (operator == Operator.Pass) {
            if (condition.compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator >= Operator.And && operator <= Operator.Nor) {
            if (paramType != ParameterType.None) {
                revert UnsuitableParameterType(index);
            }
            if (condition.compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.Matches) {
            if (
                paramType != ParameterType.Tuple &&
                paramType != ParameterType.Array &&
                paramType != ParameterType.AbiEncoded
            ) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (
            operator == Operator.ArraySome ||
            operator == Operator.ArrayEvery ||
            operator == Operator.ArraySubset
        ) {
            if (paramType != ParameterType.Array) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.EqualToAvatar) {
            if (paramType != ParameterType.Static) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.EqualTo) {
            if (
                paramType != ParameterType.Static &&
                paramType != ParameterType.Dynamic &&
                paramType != ParameterType.Tuple &&
                paramType != ParameterType.Array
            ) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length == 0 || compValue.length % 32 != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (
            operator == Operator.GreaterThan ||
            operator == Operator.LessThan ||
            operator == Operator.SignedIntGreaterThan ||
            operator == Operator.SignedIntLessThan
        ) {
            if (paramType != ParameterType.Static) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.Bitmask) {
            if (
                paramType != ParameterType.Static &&
                paramType != ParameterType.Dynamic
            ) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.Custom) {
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.WithinAllowance) {
            if (paramType != ParameterType.Static) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (
            operator == Operator.EtherWithinAllowance ||
            operator == Operator.CallWithinAllowance
        ) {
            if (paramType != ParameterType.None) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else {
            revert UnsupportedOperator(index);
        }
    }

    function _tree(ConditionFlat[] memory conditions) private pure {
        uint256 length = conditions.length;
        // check BFS
        for (uint256 i = 1; i < length; ++i) {
            if (conditions[i - 1].parent > conditions[i].parent) {
                revert NotBFS();
            }
        }

        for (uint256 i = 0; i < length; ++i) {
            if (
                (conditions[i].operator == Operator.EtherWithinAllowance ||
                    conditions[i].operator == Operator.CallWithinAllowance) &&
                conditions[conditions[i].parent].paramType !=
                ParameterType.AbiEncoded
            ) {
                revert UnsuitableParent(i);
            }
        }

        Topology.Bounds[] memory childrenBounds = Topology.childrenBounds(
            conditions
        );

        for (uint256 i = 0; i < conditions.length; i++) {
            ConditionFlat memory condition = conditions[i];
            Topology.Bounds memory childBounds = childrenBounds[i];

            if (condition.paramType == ParameterType.None) {
                if (
                    (condition.operator == Operator.EtherWithinAllowance ||
                        condition.operator == Operator.CallWithinAllowance) &&
                    childBounds.length != 0
                ) {
                    revert UnsuitableChildCount(i);
                }
                if (
                    (condition.operator >= Operator.And &&
                        condition.operator <= Operator.Nor)
                ) {
                    if (childBounds.length == 0) {
                        revert UnsuitableChildCount(i);
                    }
                }
            } else if (
                condition.paramType == ParameterType.Static ||
                condition.paramType == ParameterType.Dynamic
            ) {
                if (childBounds.length != 0) {
                    revert UnsuitableChildCount(i);
                }
            } else if (
                condition.paramType == ParameterType.Tuple ||
                condition.paramType == ParameterType.AbiEncoded
            ) {
                if (childBounds.length == 0) {
                    revert UnsuitableChildCount(i);
                }
            } else {
                assert(condition.paramType == ParameterType.Array);

                if (childBounds.length == 0) {
                    revert UnsuitableChildCount(i);
                }

                if (
                    (condition.operator == Operator.ArraySome ||
                        condition.operator == Operator.ArrayEvery) &&
                    childBounds.length != 1
                ) {
                    revert UnsuitableChildCount(i);
                } else if (
                    condition.operator == Operator.ArraySubset &&
                    childBounds.length > 256
                ) {
                    revert UnsuitableChildCount(i);
                }
            }
        }

        for (uint256 i = 0; i < conditions.length; i++) {
            ConditionFlat memory condition = conditions[i];
            if (
                ((condition.operator >= Operator.And &&
                    condition.operator <= Operator.Nor) ||
                    condition.paramType == ParameterType.Array) &&
                childrenBounds[i].length > 1
            ) {
                compatiblechildTypeTree(conditions, i, childrenBounds);
            }
        }

        Topology.TypeTree memory typeTree = Topology.typeTree(
            conditions,
            0,
            childrenBounds
        );

        if (typeTree.paramType != ParameterType.AbiEncoded) {
            revert UnsuitableRootNode();
        }
    }

    function compatiblechildTypeTree(
        ConditionFlat[] memory conditions,
        uint256 index,
        Topology.Bounds[] memory childrenBounds
    ) private pure {
        uint256 start = childrenBounds[index].start;
        uint256 end = childrenBounds[index].end;

        bytes32 id = typeTreeId(
            Topology.typeTree(conditions, start, childrenBounds)
        );
        for (uint256 j = start + 1; j < end; ++j) {
            if (
                id !=
                typeTreeId(Topology.typeTree(conditions, j, childrenBounds))
            ) {
                revert UnsuitableChildTypeTree(index);
            }
        }
    }

    function typeTreeId(
        Topology.TypeTree memory node
    ) private pure returns (bytes32) {
        uint256 childCount = node.children.length;
        if (childCount > 0) {
            bytes32[] memory ids = new bytes32[](node.children.length);
            for (uint256 i = 0; i < childCount; ++i) {
                ids[i] = typeTreeId(node.children[i]);
            }

            return keccak256(abi.encodePacked(node.paramType, "-", ids));
        } else {
            return bytes32(uint256(node.paramType));
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "../Types.sol";

/**
 * @title BufferPacker a library that provides packing and unpacking functions
 * for conditions. It allows packing externally provided ConditionsFlat[] into
 * a storage-optimized buffer, and later unpack it into memory.
 * @author Cristóvão Honorato - <[email protected]>
 */
library BufferPacker {
    // HEADER (stored as a single word in storage)
    // 2   bytes -> count (Condition count)
    // 1   bytes -> options (ExecutionOptions)
    // 1   bytes -> isWildcarded
    // 8   bytes -> unused
    // 20  bytes -> pointer (address containining packed conditions)
    uint256 private constant OFFSET_COUNT = 240;
    uint256 private constant OFFSET_OPTIONS = 224;
    uint256 private constant OFFSET_IS_WILDCARDED = 216;
    uint256 private constant MASK_COUNT = 0xffff << OFFSET_COUNT;
    uint256 private constant MASK_OPTIONS = 0xff << OFFSET_OPTIONS;
    uint256 private constant MASK_IS_WILDCARDED = 0x1 << OFFSET_IS_WILDCARDED;
    // CONDITION (stored as runtimeBytecode at pointer address kept in header)
    // 8    bits -> parent
    // 3    bits -> type
    // 5    bits -> operator
    uint256 private constant BYTES_PER_CONDITION = 2;
    uint16 private constant OFFSET_PARENT = 8;
    uint16 private constant OFFSET_PARAM_TYPE = 5;
    uint16 private constant OFFSET_OPERATOR = 0;
    uint16 private constant MASK_PARENT = uint16(0xff << OFFSET_PARENT);
    uint16 private constant MASK_PARAM_TYPE = uint16(0x07 << OFFSET_PARAM_TYPE);
    uint16 private constant MASK_OPERATOR = uint16(0x1f << OFFSET_OPERATOR);

    function packedSize(
        ConditionFlat[] memory conditions
    ) internal pure returns (uint256 result) {
        uint256 count = conditions.length;

        result = count * BYTES_PER_CONDITION;
        for (uint256 i; i < count; ++i) {
            if (conditions[i].operator >= Operator.EqualTo) {
                result += 32;
            }
        }
    }

    function packHeader(
        uint256 count,
        ExecutionOptions options,
        address pointer
    ) internal pure returns (bytes32) {
        return
            bytes32(count << OFFSET_COUNT) |
            (bytes32(uint256(options)) << OFFSET_OPTIONS) |
            bytes32(uint256(uint160(pointer)));
    }

    function packHeaderAsWildcarded(
        ExecutionOptions options
    ) internal pure returns (bytes32) {
        return
            bytes32(uint256(options) << OFFSET_OPTIONS) |
            bytes32(MASK_IS_WILDCARDED);
    }

    function unpackHeader(
        bytes32 header
    ) internal pure returns (uint256 count, address pointer) {
        count = (uint256(header) & MASK_COUNT) >> OFFSET_COUNT;
        pointer = address(bytes20(uint160(uint256(header))));
    }

    function unpackOptions(
        bytes32 header
    ) internal pure returns (bool isWildcarded, ExecutionOptions options) {
        isWildcarded = uint256(header) & MASK_IS_WILDCARDED != 0;
        options = ExecutionOptions(
            (uint256(header) & MASK_OPTIONS) >> OFFSET_OPTIONS
        );
    }

    function packCondition(
        bytes memory buffer,
        uint256 index,
        ConditionFlat memory condition
    ) internal pure {
        uint256 offset = index * BYTES_PER_CONDITION;
        buffer[offset] = bytes1(condition.parent);
        buffer[offset + 1] = bytes1(
            (uint8(condition.paramType) << uint8(OFFSET_PARAM_TYPE)) |
                uint8(condition.operator)
        );
    }

    function packCompValue(
        bytes memory buffer,
        uint256 offset,
        ConditionFlat memory condition
    ) internal pure {
        bytes32 word = condition.operator == Operator.EqualTo
            ? keccak256(condition.compValue)
            : bytes32(condition.compValue);

        assembly {
            mstore(add(buffer, offset), word)
        }
    }

    function unpackBody(
        bytes memory buffer,
        uint256 count
    )
        internal
        pure
        returns (ConditionFlat[] memory result, bytes32[] memory compValues)
    {
        result = new ConditionFlat[](count);
        compValues = new bytes32[](count);

        bytes32 word;
        uint256 offset = 32;
        uint256 compValueOffset = 32 + count * BYTES_PER_CONDITION;

        for (uint256 i; i < count; ) {
            assembly {
                word := mload(add(buffer, offset))
            }
            offset += BYTES_PER_CONDITION;

            uint16 bits = uint16(bytes2(word));
            ConditionFlat memory condition = result[i];
            condition.parent = uint8((bits & MASK_PARENT) >> OFFSET_PARENT);
            condition.paramType = ParameterType(
                (bits & MASK_PARAM_TYPE) >> OFFSET_PARAM_TYPE
            );
            condition.operator = Operator(bits & MASK_OPERATOR);

            if (condition.operator >= Operator.EqualTo) {
                assembly {
                    word := mload(add(buffer, compValueOffset))
                }
                compValueOffset += 32;
                compValues[i] = word;
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "@gnosis.pm/zodiac/contracts/core/Modifier.sol";

import "./BufferPacker.sol";

/**
 * @title Packer - a library that coordinates the process of packing
 * conditionsFlat into a storage optimized buffer.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Packer {
    function pack(
        ConditionFlat[] memory conditionsFlat
    ) external pure returns (bytes memory buffer) {
        _removeExtraneousOffsets(conditionsFlat);

        buffer = new bytes(BufferPacker.packedSize(conditionsFlat));

        uint256 count = conditionsFlat.length;
        uint256 offset = 32 + count * 2;
        for (uint256 i; i < count; ++i) {
            BufferPacker.packCondition(buffer, i, conditionsFlat[i]);
            if (conditionsFlat[i].operator >= Operator.EqualTo) {
                BufferPacker.packCompValue(buffer, offset, conditionsFlat[i]);
                offset += 32;
            }
        }
    }

    /**
     * @dev This function removes unnecessary offsets from compValue fields of
     * the `conditions` array. Its purpose is to ensure a consistent API where
     * every `compValue` provided for use in `Operations.EqualsTo` is obtained
     * by calling `abi.encode` directly.
     *
     * By removing the leading extraneous offsets this function makes
     * abi.encode(...) match the output produced by Decoder inspection.
     * Without it, the encoded fields would need to be patched externally
     * depending on whether the payload is fully encoded inline or not.
     *
     * @param conditionsFlat Array of ConditionFlat structs to remove extraneous
     * offsets from
     */
    function _removeExtraneousOffsets(
        ConditionFlat[] memory conditionsFlat
    ) private pure {
        uint256 count = conditionsFlat.length;
        for (uint256 i; i < count; ++i) {
            if (
                conditionsFlat[i].operator == Operator.EqualTo &&
                !_isInline(conditionsFlat, i)
            ) {
                bytes memory compValue = conditionsFlat[i].compValue;
                uint256 length = compValue.length;
                assembly {
                    compValue := add(compValue, 32)
                    mstore(compValue, sub(length, 32))
                }
                conditionsFlat[i].compValue = compValue;
            }
        }
    }

    function _isInline(
        ConditionFlat[] memory conditions,
        uint256 index
    ) private pure returns (bool) {
        ParameterType paramType = conditions[index].paramType;
        if (paramType == ParameterType.Static) {
            return true;
        } else if (
            paramType == ParameterType.Dynamic ||
            paramType == ParameterType.Array ||
            paramType == ParameterType.AbiEncoded
        ) {
            return false;
        } else {
            uint256 length = conditions.length;

            for (uint256 j = index + 1; j < length; ++j) {
                uint8 parent = conditions[j].parent;
                if (parent < index) {
                    continue;
                }

                if (parent > index) {
                    break;
                }

                if (!_isInline(conditions, j)) {
                    return false;
                }
            }
            return true;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "./adapters/Types.sol";

/**
 * @title Periphery - a coordinating component that facilitates plug-and-play
 * functionality for the Zodiac Roles Mod through the use of adapters.
 * @author Cristóvão Honorato - <[email protected]>
 */
abstract contract Periphery is OwnableUpgradeable {
    event SetUnwrapAdapter(
        address to,
        bytes4 selector,
        ITransactionUnwrapper adapter
    );

    mapping(bytes32 => ITransactionUnwrapper) public unwrappers;

    function setTransactionUnwrapper(
        address to,
        bytes4 selector,
        ITransactionUnwrapper adapter
    ) external onlyOwner {
        unwrappers[bytes32(bytes20(to)) | (bytes32(selector) >> 160)] = adapter;
        emit SetUnwrapAdapter(to, selector, adapter);
    }

    function getTransactionUnwrapper(
        address to,
        bytes4 selector
    ) internal view returns (ITransactionUnwrapper) {
        return unwrappers[bytes32(bytes20(to)) | (bytes32(selector) >> 160)];
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Core.sol";
import "./Integrity.sol";

import "./packers/BufferPacker.sol";

/**
 * @title PermissionBuilder - a component of the Zodiac Roles Mod that is
 * responsible for constructing, managing, granting, and revoking all types
 * of permission data.
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 */
abstract contract PermissionBuilder is Core {
    error UnsuitableMaxBalanceForAllowance();
    event AllowTarget(
        bytes32 roleKey,
        address targetAddress,
        ExecutionOptions options
    );
    event RevokeTarget(bytes32 roleKey, address targetAddress);
    event ScopeTarget(bytes32 roleKey, address targetAddress);

    event AllowFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector,
        ExecutionOptions options
    );
    event RevokeFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector
    );
    event ScopeFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector,
        ConditionFlat[] conditions,
        ExecutionOptions options
    );

    event SetAllowance(
        bytes32 allowanceKey,
        uint128 balance,
        uint128 maxBalance,
        uint128 refillAmount,
        uint64 refillInterval,
        uint64 refillTimestamp
    );

    /// @dev Allows transactions to a target address.
    /// @param roleKey identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function allowTarget(
        bytes32 roleKey,
        address targetAddress,
        ExecutionOptions options
    ) external onlyOwner {
        roles[roleKey].targets[targetAddress] = TargetAddress({
            clearance: Clearance.Target,
            options: options
        });
        emit AllowTarget(roleKey, targetAddress, options);
    }

    /// @dev Removes transactions to a target address.
    /// @param roleKey identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    function revokeTarget(
        bytes32 roleKey,
        address targetAddress
    ) external onlyOwner {
        roles[roleKey].targets[targetAddress] = TargetAddress({
            clearance: Clearance.None,
            options: ExecutionOptions.None
        });
        emit RevokeTarget(roleKey, targetAddress);
    }

    /// @dev Designates only specific functions can be called.
    /// @param roleKey identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    function scopeTarget(
        bytes32 roleKey,
        address targetAddress
    ) external onlyOwner {
        roles[roleKey].targets[targetAddress] = TargetAddress({
            clearance: Clearance.Function,
            options: ExecutionOptions.None
        });
        emit ScopeTarget(roleKey, targetAddress);
    }

    /// @dev Specifies the functions that can be called.
    /// @param roleKey identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param selector 4 byte function selector.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function allowFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector,
        ExecutionOptions options
    ) external onlyOwner {
        roles[roleKey].scopeConfig[_key(targetAddress, selector)] = BufferPacker
            .packHeaderAsWildcarded(options);

        emit AllowFunction(roleKey, targetAddress, selector, options);
    }

    /// @dev Removes the functions that can be called.
    /// @param roleKey identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param selector 4 byte function selector.
    function revokeFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector
    ) external onlyOwner {
        delete roles[roleKey].scopeConfig[_key(targetAddress, selector)];
        emit RevokeFunction(roleKey, targetAddress, selector);
    }

    /// @dev Sets conditions to enforce on calls to the specified target.
    /// @param roleKey identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param selector 4 byte function selector.
    /// @param conditions The conditions to enforce.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function scopeFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector,
        ConditionFlat[] memory conditions,
        ExecutionOptions options
    ) external onlyOwner {
        Integrity.enforce(conditions);

        _store(
            roles[roleKey],
            _key(targetAddress, selector),
            conditions,
            options
        );

        emit ScopeFunction(
            roleKey,
            targetAddress,
            selector,
            conditions,
            options
        );
    }

    function setAllowance(
        bytes32 key,
        uint128 balance,
        uint128 maxBalance,
        uint128 refillAmount,
        uint64 refillInterval,
        uint64 refillTimestamp
    ) external onlyOwner {
        maxBalance = maxBalance > 0 ? maxBalance : type(uint128).max;

        if (balance > maxBalance) {
            revert UnsuitableMaxBalanceForAllowance();
        }

        allowances[key] = Allowance({
            refillAmount: refillAmount,
            refillInterval: refillInterval,
            refillTimestamp: refillTimestamp,
            balance: balance,
            maxBalance: maxBalance
        });
        emit SetAllowance(
            key,
            balance,
            maxBalance,
            refillAmount,
            refillInterval,
            refillTimestamp
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

import "./Consumptions.sol";
import "./Core.sol";
import "./Decoder.sol";
import "./Periphery.sol";

import "./packers/BufferPacker.sol";

/**
 * @title PermissionChecker - a component of Zodiac Roles Mod responsible
 * for enforcing and authorizing actions performed on behalf of a role.
 *
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 */
abstract contract PermissionChecker is Core, Periphery {
    function _authorize(
        bytes32 roleKey,
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) internal view returns (Consumption[] memory) {
        // We never authorize the zero role, as it could clash with the
        // unassigned default role
        if (roleKey == 0) {
            revert NoMembership();
        }

        Role storage role = roles[roleKey];
        if (!role.members[msg.sender]) {
            revert NoMembership();
        }

        ITransactionUnwrapper adapter = getTransactionUnwrapper(
            to,
            bytes4(data)
        );

        Status status;
        Result memory result;
        if (address(adapter) == address(0)) {
            (status, result) = _transaction(
                role,
                to,
                value,
                data,
                operation,
                result.consumptions
            );
        } else {
            (status, result) = _multiEntrypoint(
                ITransactionUnwrapper(adapter),
                role,
                to,
                value,
                data,
                operation
            );
        }
        if (status != Status.Ok) {
            revert ConditionViolation(status, result.info);
        }

        return result.consumptions;
    }

    function _multiEntrypoint(
        ITransactionUnwrapper adapter,
        Role storage role,
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) private view returns (Status status, Result memory result) {
        try adapter.unwrap(to, value, data, operation) returns (
            UnwrappedTransaction[] memory transactions
        ) {
            for (uint256 i; i < transactions.length; ) {
                UnwrappedTransaction memory transaction = transactions[i];
                uint256 left = transaction.dataLocation;
                uint256 right = left + transaction.dataSize;
                (status, result) = _transaction(
                    role,
                    transaction.to,
                    transaction.value,
                    data[left:right],
                    transaction.operation,
                    result.consumptions
                );
                if (status != Status.Ok) {
                    return (status, result);
                }
                unchecked {
                    ++i;
                }
            }
        } catch {
            revert MalformedMultiEntrypoint();
        }
    }

    /// @dev Inspects an individual transaction and performs checks based on permission scoping.
    /// Wildcarded indicates whether params need to be inspected or not. When true, only ExecutionOptions are checked.
    /// @param role Role to check for.
    /// @param to Destination address of transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function _transaction(
        Role storage role,
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        Consumption[] memory consumptions
    ) private view returns (Status, Result memory) {
        if (data.length != 0 && data.length < 4) {
            revert FunctionSignatureTooShort();
        }

        TargetAddress storage target = role.targets[to];
        if (target.clearance == Clearance.Target) {
            return (
                _executionOptions(value, operation, target.options),
                Result({consumptions: consumptions, info: 0})
            );
        } else if (target.clearance == Clearance.Function) {
            bytes32 key = _key(to, bytes4(data));
            bytes32 header = role.scopeConfig[key];
            if (header == 0) {
                return (
                    Status.FunctionNotAllowed,
                    Result({
                        consumptions: consumptions,
                        info: bytes32(bytes4(data))
                    })
                );
            }

            (bool isWildcarded, ExecutionOptions options) = BufferPacker
                .unpackOptions(header);

            Status status = _executionOptions(value, operation, options);
            if (status != Status.Ok) {
                return (status, Result({consumptions: consumptions, info: 0}));
            }

            if (isWildcarded) {
                return (
                    Status.Ok,
                    Result({consumptions: consumptions, info: 0})
                );
            }

            return _scopedFunction(role, key, value, data, consumptions);
        } else {
            return (
                Status.TargetAddressNotAllowed,
                Result({consumptions: consumptions, info: 0})
            );
        }
    }

    /// @dev Examines the ether value and operation for a given role target.
    /// @param value Ether value of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    /// @param options Determines if a transaction can send ether and/or delegatecall to target.
    function _executionOptions(
        uint256 value,
        Enum.Operation operation,
        ExecutionOptions options
    ) private pure returns (Status) {
        // isSend && !canSend
        if (
            value > 0 &&
            options != ExecutionOptions.Send &&
            options != ExecutionOptions.Both
        ) {
            return Status.SendNotAllowed;
        }

        // isDelegateCall && !canDelegateCall
        if (
            operation == Enum.Operation.DelegateCall &&
            options != ExecutionOptions.DelegateCall &&
            options != ExecutionOptions.Both
        ) {
            return Status.DelegateCallNotAllowed;
        }

        return Status.Ok;
    }

    function _scopedFunction(
        Role storage role,
        bytes32 key,
        uint256 value,
        bytes calldata data,
        Consumption[] memory prevConsumptions
    ) private view returns (Status, Result memory) {
        (Condition memory condition, Consumption[] memory consumptions) = _load(
            role,
            key
        );
        ParameterPayload memory payload = Decoder.inspect(data, condition);

        return
            _walk(
                value,
                data,
                condition,
                payload,
                prevConsumptions.length == 0
                    ? consumptions
                    : Consumptions.merge(prevConsumptions, consumptions)
            );
    }

    function _walk(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        Operator operator = condition.operator;

        if (operator < Operator.EqualTo) {
            if (operator == Operator.Pass) {
                return (
                    Status.Ok,
                    Result({consumptions: consumptions, info: 0})
                );
            } else if (operator == Operator.Matches) {
                return _matches(value, data, condition, payload, consumptions);
            } else if (operator == Operator.And) {
                return _and(value, data, condition, payload, consumptions);
            } else if (operator == Operator.Or) {
                return _or(value, data, condition, payload, consumptions);
            } else if (operator == Operator.Nor) {
                return _nor(value, data, condition, payload, consumptions);
            } else if (operator == Operator.ArraySome) {
                return
                    _arraySome(value, data, condition, payload, consumptions);
            } else if (operator == Operator.ArrayEvery) {
                return
                    _arrayEvery(value, data, condition, payload, consumptions);
            } else {
                assert(operator == Operator.ArraySubset);
                return
                    _arraySubset(value, data, condition, payload, consumptions);
            }
        } else {
            if (operator <= Operator.LessThan) {
                return (
                    _compare(data, condition, payload),
                    Result({consumptions: consumptions, info: 0})
                );
            } else if (operator <= Operator.SignedIntLessThan) {
                return (
                    _compareSignedInt(data, condition, payload),
                    Result({consumptions: consumptions, info: 0})
                );
            } else if (operator == Operator.Bitmask) {
                return (
                    _bitmask(data, condition, payload),
                    Result({consumptions: consumptions, info: 0})
                );
            } else if (operator == Operator.Custom) {
                return _custom(value, data, condition, payload, consumptions);
            } else if (operator == Operator.WithinAllowance) {
                return _withinAllowance(data, condition, payload, consumptions);
            } else if (operator == Operator.EtherWithinAllowance) {
                return _etherWithinAllowance(value, condition, consumptions);
            } else {
                assert(operator == Operator.CallWithinAllowance);
                return _callWithinAllowance(condition, consumptions);
            }
        }
    }

    function _matches(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status status, Result memory) {
        Result memory result = Result({consumptions: consumptions, info: 0});

        if (condition.children.length != payload.children.length) {
            return (Status.ParameterNotAMatch, result);
        }

        for (uint256 i; i < condition.children.length; ) {
            (status, result) = _walk(
                value,
                data,
                condition.children[i],
                payload.children[i],
                result.consumptions
            );
            if (status != Status.Ok) {
                return (
                    status,
                    Result({consumptions: consumptions, info: result.info})
                );
            }
            unchecked {
                ++i;
            }
        }

        return (Status.Ok, result);
    }

    function _and(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status status, Result memory result) {
        result = Result({consumptions: consumptions, info: 0});

        for (uint256 i; i < condition.children.length; ) {
            (status, result) = _walk(
                value,
                data,
                condition.children[i],
                payload,
                result.consumptions
            );
            if (status != Status.Ok) {
                return (
                    status,
                    Result({consumptions: consumptions, info: result.info})
                );
            }
            unchecked {
                ++i;
            }
        }
        return (Status.Ok, result);
    }

    function _or(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        for (uint256 i; i < condition.children.length; ) {
            (Status status, Result memory result) = _walk(
                value,
                data,
                condition.children[i],
                payload,
                consumptions
            );
            if (status == Status.Ok) {
                return (status, result);
            }
            unchecked {
                ++i;
            }
        }

        return (
            Status.OrViolation,
            Result({consumptions: consumptions, info: 0})
        );
    }

    function _nor(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        for (uint256 i; i < condition.children.length; ) {
            (Status status, ) = _walk(
                value,
                data,
                condition.children[i],
                payload,
                consumptions
            );
            if (status == Status.Ok) {
                return (
                    Status.NorViolation,
                    Result({consumptions: consumptions, info: 0})
                );
            }
            unchecked {
                ++i;
            }
        }
        return (Status.Ok, Result({consumptions: consumptions, info: 0}));
    }

    function _arraySome(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        for (uint256 i; i < payload.children.length; ) {
            (Status status, Result memory result) = _walk(
                value,
                data,
                condition.children[0],
                payload.children[i],
                consumptions
            );
            if (status == Status.Ok) {
                return (status, result);
            }
            unchecked {
                ++i;
            }
        }
        return (
            Status.NoArrayElementPasses,
            Result({consumptions: consumptions, info: 0})
        );
    }

    function _arrayEvery(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status status, Result memory result) {
        result = Result({consumptions: consumptions, info: 0});
        for (uint256 i; i < payload.children.length; ) {
            (status, result) = _walk(
                value,
                data,
                condition.children[0],
                payload.children[i],
                result.consumptions
            );
            if (status != Status.Ok) {
                return (
                    Status.NotEveryArrayElementPasses,
                    Result({consumptions: consumptions, info: 0})
                );
            }
            unchecked {
                ++i;
            }
        }
        return (Status.Ok, result);
    }

    function _arraySubset(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory result) {
        result = Result({consumptions: consumptions, info: 0});

        if (
            payload.children.length == 0 ||
            payload.children.length > condition.children.length
        ) {
            return (Status.ParameterNotSubsetOfAllowed, result);
        }

        uint256 taken;
        for (uint256 i; i < payload.children.length; ++i) {
            bool found = false;
            for (uint256 j; j < condition.children.length; ++j) {
                if (taken & (1 << j) != 0) continue;

                (Status status, Result memory _result) = _walk(
                    value,
                    data,
                    condition.children[j],
                    payload.children[i],
                    result.consumptions
                );
                if (status == Status.Ok) {
                    found = true;
                    taken |= 1 << j;
                    result = _result;
                    break;
                }
            }
            if (!found) {
                return (
                    Status.ParameterNotSubsetOfAllowed,
                    Result({consumptions: consumptions, info: 0})
                );
            }
        }

        return (Status.Ok, result);
    }

    function _compare(
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload
    ) private pure returns (Status) {
        Operator operator = condition.operator;
        bytes32 compValue = condition.compValue;
        bytes32 value = operator == Operator.EqualTo
            ? keccak256(Decoder.pluck(data, payload.location, payload.size))
            : Decoder.word(data, payload.location);

        if (operator == Operator.EqualTo && value != compValue) {
            return Status.ParameterNotAllowed;
        } else if (operator == Operator.GreaterThan && value <= compValue) {
            return Status.ParameterLessThanAllowed;
        } else if (operator == Operator.LessThan && value >= compValue) {
            return Status.ParameterGreaterThanAllowed;
        } else {
            return Status.Ok;
        }
    }

    function _compareSignedInt(
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload
    ) private pure returns (Status) {
        Operator operator = condition.operator;
        int256 compValue = int256(uint256(condition.compValue));
        int256 value = int256(uint256(Decoder.word(data, payload.location)));

        if (operator == Operator.SignedIntGreaterThan && value <= compValue) {
            return Status.ParameterLessThanAllowed;
        } else if (
            operator == Operator.SignedIntLessThan && value >= compValue
        ) {
            return Status.ParameterGreaterThanAllowed;
        } else {
            return Status.Ok;
        }
    }

    /**
     * Applies a shift and bitmask on the payload bytes and compares the
     * result to the expected value. The shift offset, bitmask, and expected
     * value are specified in the compValue parameter, which is tightly
     * packed as follows:
     * <2 bytes shift offset><15 bytes bitmask><15 bytes expected value>
     */
    function _bitmask(
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload
    ) private pure returns (Status) {
        bytes32 compValue = condition.compValue;
        bool isInline = condition.paramType == ParameterType.Static;
        bytes calldata value = Decoder.pluck(
            data,
            payload.location + (isInline ? 0 : 32),
            payload.size - (isInline ? 0 : 32)
        );

        uint256 shift = uint16(bytes2(compValue));
        if (shift >= value.length) {
            return Status.BitmaskOverflow;
        }

        bytes32 rinse = bytes15(0xffffffffffffffffffffffffffffff);
        bytes32 mask = (compValue << 16) & rinse;
        // while its necessary to apply the rinse to the mask its not strictly
        // necessary to do so for the expected value, since we get remaining
        // 15 bytes anyway (shifting the word by 17 bytes)
        bytes32 expected = (compValue << (16 + 15 * 8)) & rinse;
        bytes32 slice = bytes32(value[shift:]);

        return
            (slice & mask) == expected ? Status.Ok : Status.BitmaskNotAllowed;
    }

    function _custom(
        uint256 value,
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        // 20 bytes on the left
        ICustomCondition adapter = ICustomCondition(
            address(bytes20(condition.compValue))
        );
        // 12 bytes on the right
        bytes12 extra = bytes12(uint96(uint256(condition.compValue)));

        (bool success, bytes32 info) = adapter.check(
            value,
            data,
            payload.location,
            payload.size,
            extra
        );
        return (
            success ? Status.Ok : Status.CustomConditionViolation,
            Result({consumptions: consumptions, info: info})
        );
    }

    function _withinAllowance(
        bytes calldata data,
        Condition memory condition,
        ParameterPayload memory payload,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        uint256 value = uint256(Decoder.word(data, payload.location));
        return __consume(value, condition, consumptions);
    }

    function _etherWithinAllowance(
        uint256 value,
        Condition memory condition,
        Consumption[] memory consumptions
    ) private pure returns (Status status, Result memory result) {
        (status, result) = __consume(value, condition, consumptions);
        return (
            status == Status.Ok ? Status.Ok : Status.EtherAllowanceExceeded,
            result
        );
    }

    function _callWithinAllowance(
        Condition memory condition,
        Consumption[] memory consumptions
    ) private pure returns (Status status, Result memory result) {
        (status, result) = __consume(1, condition, consumptions);
        return (
            status == Status.Ok ? Status.Ok : Status.CallAllowanceExceeded,
            result
        );
    }

    function __consume(
        uint256 value,
        Condition memory condition,
        Consumption[] memory consumptions
    ) private pure returns (Status, Result memory) {
        (uint256 index, bool found) = Consumptions.find(
            consumptions,
            condition.compValue
        );
        assert(found);

        if (
            value + consumptions[index].consumed > consumptions[index].balance
        ) {
            return (
                Status.AllowanceExceeded,
                Result({
                    consumptions: consumptions,
                    info: consumptions[index].allowanceKey
                })
            );
        } else {
            consumptions = Consumptions.clone(consumptions);
            consumptions[index].consumed += uint128(value);
            return (Status.Ok, Result({consumptions: consumptions, info: 0}));
        }
    }

    struct Result {
        Consumption[] consumptions;
        bytes32 info;
    }

    enum Status {
        Ok,
        /// Role not allowed to delegate call to target address
        DelegateCallNotAllowed,
        /// Role not allowed to call target address
        TargetAddressNotAllowed,
        /// Role not allowed to call this function on target address
        FunctionNotAllowed,
        /// Role not allowed to send to target address
        SendNotAllowed,
        /// Or conition not met
        OrViolation,
        /// Nor conition not met
        NorViolation,
        /// Parameter value is not equal to allowed
        ParameterNotAllowed,
        /// Parameter value less than allowed
        ParameterLessThanAllowed,
        /// Parameter value greater than maximum allowed by role
        ParameterGreaterThanAllowed,
        /// Parameter value does not match
        ParameterNotAMatch,
        /// Array elements do not meet allowed criteria for every element
        NotEveryArrayElementPasses,
        /// Array elements do not meet allowed criteria for at least one element
        NoArrayElementPasses,
        /// Parameter value not a subset of allowed
        ParameterNotSubsetOfAllowed,
        /// Bitmask exceeded value length
        BitmaskOverflow,
        /// Bitmask not an allowed value
        BitmaskNotAllowed,
        CustomConditionViolation,
        AllowanceExceeded,
        CallAllowanceExceeded,
        EtherAllowanceExceeded
    }

    /// Sender is not a member of the role
    error NoMembership();

    /// Function signature too short
    error FunctionSignatureTooShort();

    /// Calldata unwrapping failed
    error MalformedMultiEntrypoint();

    error ConditionViolation(Status status, bytes32 info);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "./Consumptions.sol";
import "./Core.sol";
import "./Topology.sol";
import "./WriteOnce.sol";

import "./packers/Packer.sol";

/**
 * @title PermissionLoader - a component of the Zodiac Roles Mod that handles
 * the writing and reading of permission data to and from storage.
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 */
abstract contract PermissionLoader is Core {
    function _store(
        Role storage role,
        bytes32 key,
        ConditionFlat[] memory conditions,
        ExecutionOptions options
    ) internal override {
        bytes memory buffer = Packer.pack(conditions);
        address pointer = WriteOnce.store(buffer);

        role.scopeConfig[key] = BufferPacker.packHeader(
            conditions.length,
            options,
            pointer
        );
    }

    function _load(
        Role storage role,
        bytes32 key
    )
        internal
        view
        override
        returns (Condition memory condition, Consumption[] memory consumptions)
    {
        (uint256 count, address pointer) = BufferPacker.unpackHeader(
            role.scopeConfig[key]
        );
        bytes memory buffer = WriteOnce.load(pointer);
        (
            ConditionFlat[] memory conditionsFlat,
            bytes32[] memory compValues
        ) = BufferPacker.unpackBody(buffer, count);

        uint256 allowanceCount;

        for (uint256 i; i < conditionsFlat.length; ) {
            Operator operator = conditionsFlat[i].operator;
            if (operator >= Operator.WithinAllowance) {
                ++allowanceCount;
            } else if (operator == Operator.EqualToAvatar) {
                // patch Operator.EqualToAvatar which in reality works as
                // a placeholder
                conditionsFlat[i].operator = Operator.EqualTo;
                compValues[i] = keccak256(abi.encode(avatar));
            }
            unchecked {
                ++i;
            }
        }

        _conditionTree(
            conditionsFlat,
            compValues,
            Topology.childrenBounds(conditionsFlat),
            0,
            condition
        );

        return (
            condition,
            allowanceCount > 0
                ? _consumptions(conditionsFlat, compValues, allowanceCount)
                : consumptions
        );
    }

    function _conditionTree(
        ConditionFlat[] memory conditionsFlat,
        bytes32[] memory compValues,
        Topology.Bounds[] memory childrenBounds,
        uint256 index,
        Condition memory treeNode
    ) private pure {
        // This function populates a buffer received as an argument instead of
        // instantiating a result object. This is an important gas optimization

        ConditionFlat memory conditionFlat = conditionsFlat[index];
        treeNode.paramType = conditionFlat.paramType;
        treeNode.operator = conditionFlat.operator;
        treeNode.compValue = compValues[index];

        if (childrenBounds[index].length == 0) {
            return;
        }

        uint256 start = childrenBounds[index].start;
        uint256 length = childrenBounds[index].length;

        treeNode.children = new Condition[](length);
        for (uint j; j < length; ) {
            _conditionTree(
                conditionsFlat,
                compValues,
                childrenBounds,
                start + j,
                treeNode.children[j]
            );
            unchecked {
                ++j;
            }
        }
    }

    function _consumptions(
        ConditionFlat[] memory conditions,
        bytes32[] memory compValues,
        uint256 maxAllowanceCount
    ) private view returns (Consumption[] memory result) {
        uint256 count = conditions.length;
        result = new Consumption[](maxAllowanceCount);

        uint256 insert;

        for (uint256 i; i < count; ++i) {
            if (conditions[i].operator < Operator.WithinAllowance) {
                continue;
            }

            bytes32 key = compValues[i];
            (, bool contains) = Consumptions.find(result, key);
            if (contains) {
                continue;
            }

            result[insert].allowanceKey = key;
            (result[insert].balance, ) = _accruedAllowance(
                allowances[key],
                block.timestamp
            );
            insert++;
        }

        if (insert < maxAllowanceCount) {
            assembly {
                mstore(result, insert)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Types.sol";

/**
 * @title Topology - a library that provides helper functions for dealing with
 * the flat representation of conditions.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Topology {
    struct TypeTree {
        ParameterType paramType;
        TypeTree[] children;
    }

    struct Bounds {
        uint256 start;
        uint256 end;
        uint256 length;
    }

    function childrenBounds(
        ConditionFlat[] memory conditions
    ) internal pure returns (Bounds[] memory result) {
        uint256 count = conditions.length;
        assert(count > 0);

        // parents are breadth-first
        result = new Bounds[](count);
        result[0].start = type(uint256).max;

        // first item is the root
        for (uint256 i = 1; i < count; ) {
            result[i].start = type(uint256).max;
            Bounds memory parentBounds = result[conditions[i].parent];
            if (parentBounds.start == type(uint256).max) {
                parentBounds.start = i;
            }
            parentBounds.end = i + 1;
            parentBounds.length = parentBounds.end - parentBounds.start;
            unchecked {
                ++i;
            }
        }
    }

    function isInline(TypeTree memory node) internal pure returns (bool) {
        ParameterType paramType = node.paramType;
        if (paramType == ParameterType.Static) {
            return true;
        } else if (
            paramType == ParameterType.Dynamic ||
            paramType == ParameterType.Array ||
            paramType == ParameterType.AbiEncoded
        ) {
            return false;
        } else {
            uint256 length = node.children.length;

            for (uint256 i; i < length; ) {
                if (!isInline(node.children[i])) {
                    return false;
                }
                unchecked {
                    ++i;
                }
            }
            return true;
        }
    }

    function typeTree(
        Condition memory condition
    ) internal pure returns (TypeTree memory result) {
        if (
            condition.operator >= Operator.And &&
            condition.operator <= Operator.Nor
        ) {
            assert(condition.children.length > 0);
            return typeTree(condition.children[0]);
        }

        result.paramType = condition.paramType;
        if (condition.children.length > 0) {
            uint256 length = condition.paramType == ParameterType.Array
                ? 1
                : condition.children.length;
            result.children = new TypeTree[](length);

            for (uint256 i; i < length; ) {
                result.children[i] = typeTree(condition.children[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function typeTree(
        ConditionFlat[] memory conditions,
        uint256 index,
        Bounds[] memory bounds
    ) internal pure returns (TypeTree memory result) {
        ConditionFlat memory condition = conditions[index];
        if (
            condition.operator >= Operator.And &&
            condition.operator <= Operator.Nor
        ) {
            assert(bounds[index].length > 0);
            return typeTree(conditions, bounds[index].start, bounds);
        }

        result.paramType = condition.paramType;
        if (bounds[index].length > 0) {
            uint256 start = bounds[index].start;
            uint256 end = condition.paramType == ParameterType.Array
                ? bounds[index].start + 1
                : bounds[index].end;
            result.children = new TypeTree[](end - start);
            for (uint256 i = start; i < end; ) {
                result.children[i - start] = typeTree(conditions, i, bounds);
                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

/**
 * @title Types - a file that contains all of the type definitions used throughout
 * the Zodiac Roles Mod.
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 */
enum ParameterType {
    None,
    Static,
    Dynamic,
    Tuple,
    Array,
    AbiEncoded
}

enum Operator {
    // 00:    EMPTY EXPRESSION (default, always passes)
    //          paramType: Static / Dynamic / Tuple / Array
    //          ❓ children (only for paramType: Tuple / Array to describe their structure)
    //          🚫 compValue
    /* 00: */ Pass,
    // ------------------------------------------------------------
    // 01-04: LOGICAL EXPRESSIONS
    //          paramType: None
    //          ✅ children
    //          🚫 compValue
    /* 01: */ And,
    /* 02: */ Or,
    /* 03: */ Nor,
    /* 04: */ _Placeholder04,
    // ------------------------------------------------------------
    // 05-14: COMPLEX EXPRESSIONS
    //          paramType: AbiEncoded / Tuple / Array,
    //          ✅ children
    //          🚫 compValue
    /* 05: */ Matches,
    /* 06: */ ArraySome,
    /* 07: */ ArrayEvery,
    /* 08: */ ArraySubset,
    /* 09: */ _Placeholder09,
    /* 10: */ _Placeholder10,
    /* 11: */ _Placeholder11,
    /* 12: */ _Placeholder12,
    /* 13: */ _Placeholder13,
    /* 14: */ _Placeholder14,
    // ------------------------------------------------------------
    // 15:    SPECIAL COMPARISON (without compValue)
    //          paramType: Static
    //          🚫 children
    //          🚫 compValue
    /* 15: */ EqualToAvatar,
    // ------------------------------------------------------------
    // 16-31: COMPARISON EXPRESSIONS
    //          paramType: Static / Dynamic / Tuple / Array
    //          ❓ children (only for paramType: Tuple / Array to describe their structure)
    //          ✅ compValue
    /* 16: */ EqualTo, // paramType: Static / Dynamic / Tuple / Array
    /* 17: */ GreaterThan, // paramType: Static
    /* 18: */ LessThan, // paramType: Static
    /* 19: */ SignedIntGreaterThan, // paramType: Static
    /* 20: */ SignedIntLessThan, // paramType: Static
    /* 21: */ Bitmask, // paramType: Static / Dynamic
    /* 22: */ Custom, // paramType: Static / Dynamic / Tuple / Array
    /* 23: */ _Placeholder23,
    /* 24: */ _Placeholder24,
    /* 25: */ _Placeholder25,
    /* 26: */ _Placeholder26,
    /* 27: */ _Placeholder27,
    /* 28: */ WithinAllowance, // paramType: Static
    /* 29: */ EtherWithinAllowance, // paramType: None
    /* 30: */ CallWithinAllowance, // paramType: None
    /* 31: */ _Placeholder31
}

enum ExecutionOptions {
    None,
    Send,
    DelegateCall,
    Both
}

enum Clearance {
    None,
    Target,
    Function
}

// This struct is a flattened version of Condition
// used for ABI encoding a scope config tree
// (ABI does not support recursive types)
struct ConditionFlat {
    uint8 parent;
    ParameterType paramType;
    Operator operator;
    bytes compValue;
}

struct Condition {
    ParameterType paramType;
    Operator operator;
    bytes32 compValue;
    Condition[] children;
}
struct ParameterPayload {
    uint256 location;
    uint256 size;
    ParameterPayload[] children;
}

struct TargetAddress {
    Clearance clearance;
    ExecutionOptions options;
}

struct Role {
    mapping(address => bool) members;
    mapping(address => TargetAddress) targets;
    mapping(bytes32 => bytes32) scopeConfig;
}

struct Allowance {
    // refillInterval - duration of the period in seconds, 0 for one-time allowance
    // refillAmount - amount that will be replenished "at the start of every period" (replace with: per period)
    // refillTimestamp - timestamp of the last interval refilled for;
    // maxBalance - max accrual amount, replenishing stops once the unused allowance hits this value
    // balance - unused allowance;

    // order matters
    uint128 refillAmount;
    uint128 maxBalance;
    uint64 refillInterval;
    // only these these two fields are updated on accrual, should live in the same word
    uint128 balance;
    uint64 refillTimestamp;
}

struct Consumption {
    bytes32 allowanceKey;
    uint128 balance;
    uint128 consumed;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

interface ISingletonFactory {
    function deploy(
        bytes memory initCode,
        bytes32 salt
    ) external returns (address);
}

library WriteOnce {
    address public constant SINGLETON_FACTORY =
        0xce0042B868300000d44A59004Da54A005ffdcf9f;

    bytes32 public constant SALT =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    /**
    @notice Stores `data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `data` as code
    @param data to be written
    @return pointer Pointer to the written `data`
  */
    function store(bytes memory data) internal returns (address pointer) {
        bytes memory creationBytecode = creationBytecodeFor(data);
        address calculatedAddress = addressFor(creationBytecode);

        uint256 size;
        assembly {
            size := extcodesize(calculatedAddress)
        }

        address actualAddress;
        if (size == 0) {
            actualAddress = ISingletonFactory(SINGLETON_FACTORY).deploy(
                creationBytecode,
                SALT
            );
        } else {
            actualAddress = calculatedAddress;
        }

        assert(calculatedAddress == actualAddress);

        pointer = calculatedAddress;
    }

    /**
    @notice Reads the contents of the `pointer` code as data, skips the first byte
    @dev The function is intended for reading pointers generated by `store`
    @param pointer to be read
    @return runtimeBytecode read from `pointer` contract
  */
    function load(
        address pointer
    ) internal view returns (bytes memory runtimeBytecode) {
        uint256 rawSize;
        assembly {
            rawSize := extcodesize(pointer)
        }
        assert(rawSize > 1);

        // jump over the prepended 00
        uint256 offset = 1;
        // don't count with the 00
        uint256 size = rawSize - 1;

        runtimeBytecode = new bytes(size);
        assembly {
            extcodecopy(pointer, add(runtimeBytecode, 32), offset, size)
        }
    }

    function addressFor(
        bytes memory creationBytecode
    ) private pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                SINGLETON_FACTORY,
                SALT,
                keccak256(creationBytecode)
            )
        );
        // get the right most 20 bytes
        return address(uint160(uint256(hash)));
    }

    /**
    @notice Generate a creation code that results on a contract with `data` as bytecode
    @param data the buffer to be stored
    @return creationBytecode (constructor) for new contract
    */
    function creationBytecodeFor(
        bytes memory data
    ) private pure returns (bytes memory) {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(data.length + 1),
                hex"80_60_0E_60_00_39_60_00_F3",
                // Prepend 00 to data so contract can't be called
                hex"00",
                data
            );
    }
}