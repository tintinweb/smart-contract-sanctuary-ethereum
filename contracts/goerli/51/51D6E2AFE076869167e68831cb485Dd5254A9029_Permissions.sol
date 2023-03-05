/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Modifier Interface - A contract that sits between a Module and an Avatar and enforce some additional logic.

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

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

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
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
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
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
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
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
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

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
    function disableModule(address prevModule, address module)
        public
        override
        onlyOwner
    {
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
    function isModuleEnabled(address _module)
        public
        view
        override
        returns (bool)
    {
        return SENTINEL_MODULES != _module && modules[_module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        override
        returns (address[] memory array, address next)
    {
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
}

enum ParameterType {
    Static,
    Dynamic,
    Dynamic32
}

enum Comparison {
    EqualTo,
    GreaterThan,
    LessThan,
    OneOf
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

struct TargetAddress {
    Clearance clearance;
    ExecutionOptions options;
}

struct Role {
    mapping(address => bool) members;
    mapping(address => TargetAddress) targets;
    mapping(bytes32 => uint256) functions;
    mapping(bytes32 => bytes32) compValues;
    mapping(bytes32 => bytes32[]) compValuesOneOf;
}

library Permissions {
    uint256 internal constant SCOPE_MAX_PARAMS = 48;

    event AllowTarget(
        uint16 role,
        address targetAddress,
        ExecutionOptions options
    );
    event RevokeTarget(uint16 role, address targetAddress);
    event ScopeTarget(uint16 role, address targetAddress);
    event ScopeAllowFunction(
        uint16 role,
        address targetAddress,
        bytes4 selector,
        ExecutionOptions options,
        uint256 resultingScopeConfig
    );
    event ScopeRevokeFunction(
        uint16 role,
        address targetAddress,
        bytes4 selector,
        uint256 resultingScopeConfig
    );
    event ScopeFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        bool[] isParamScoped,
        ParameterType[] paramType,
        Comparison[] paramComp,
        bytes[] compValue,
        ExecutionOptions options,
        uint256 resultingScopeConfig
    );
    event ScopeFunctionExecutionOptions(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        ExecutionOptions options,
        uint256 resultingScopeConfig
    );
    event ScopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint256 index,
        ParameterType paramType,
        Comparison paramComp,
        bytes compValue,
        uint256 resultingScopeConfig
    );
    event ScopeParameterAsOneOf(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint256 index,
        ParameterType paramType,
        bytes[] compValues,
        uint256 resultingScopeConfig
    );
    event UnscopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint256 index,
        uint256 resultingScopeConfig
    );

    /// Sender is not a member of the role
    error NoMembership();

    /// Arrays must be the same length
    error ArraysDifferentLength();

    /// Function signature too short
    error FunctionSignatureTooShort();

    /// Role not allowed to delegate call to target address
    error DelegateCallNotAllowed();

    /// Role not allowed to call target address
    error TargetAddressNotAllowed();

    /// Role not allowed to call this function on target address
    error FunctionNotAllowed();

    /// Role not allowed to send to target address
    error SendNotAllowed();

    /// Role not allowed to use bytes for parameter
    error ParameterNotAllowed();

    /// Role not allowed to use bytes for parameter
    error ParameterNotOneOfAllowed();

    /// Role not allowed to use bytes less than value for parameter
    error ParameterLessThanAllowed();

    /// Role not allowed to use bytes greater than value for parameter
    error ParameterGreaterThanAllowed();

    /// only multisend txs with an offset of 32 bytes are allowed
    error UnacceptableMultiSendOffset();

    /// OneOf Comparison must be set via dedicated function
    error UnsuitableOneOfComparison();

    /// Not possible to define gt/lt for Dynamic types
    error UnsuitableRelativeComparison();

    /// CompValue for static types should have a size of exactly 32 bytes
    error UnsuitableStaticCompValueSize();

    /// CompValue for Dynamic32 types should be a multiple of exactly 32 bytes
    error UnsuitableDynamic32CompValueSize();

    /// Exceeds the max number of params supported
    error ScopeMaxParametersExceeded();

    /// OneOf Comparison requires at least two compValues
    error NotEnoughCompValuesForOneOf();

    /// The provided calldata for execution is too short, or an OutOfBounds scoped parameter was configured
    error CalldataOutOfBounds();

    /*
     *
     * CHECKERS
     *
     */

    /// @dev Entry point for checking the scope of a transaction.
    function check(
        Role storage role,
        address multisend,
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) public view {
        if (!role.members[msg.sender]) {
            revert NoMembership();
        }
        if (multisend == to) {
            checkMultisendTransaction(role, data);
        } else {
            checkTransaction(role, to, value, data, operation);
        }
    }

    /// @dev Splits a multisend data blob into transactions and forwards them to be checked.
    /// @param data the packed transaction data (created by utils function buildMultiSendSafeTx).
    /// @param role Role to check for.
    function checkMultisendTransaction(Role storage role, bytes memory data)
        internal
        view
    {
        Enum.Operation operation;
        address to;
        uint256 value;
        bytes memory out;
        uint256 dataLength;

        uint256 offset;
        assembly {
            offset := mload(add(data, 36))
        }
        if (offset != 32) {
            revert UnacceptableMultiSendOffset();
        }

        // transaction data (1st tx operation) reads at byte 100,
        // 4 bytes (multisend_id) + 32 bytes (offset_multisend_data) + 32 bytes multisend_data_length
        // increment i by the transaction data length
        // + 85 bytes of the to, value, and operation bytes until we reach the end of the data
        for (uint256 i = 100; i < data.length; i += (85 + dataLength)) {
            assembly {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                operation := shr(0xf8, mload(add(data, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                to := shr(0x60, mload(add(data, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                value := mload(add(data, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                dataLength := mload(add(data, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                out := add(data, add(i, 0x35))
            }
            checkTransaction(role, to, value, out, operation);
        }
    }

    /// @dev Inspects an individual transaction and performs checks based on permission scoping.
    /// Wildcarded indicates whether params need to be inspected or not. When true, only ExecutionOptions are checked.
    /// @param role Role to check for.
    /// @param targetAddress Destination address of transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function checkTransaction(
        Role storage role,
        address targetAddress,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal view {
        if (data.length != 0 && data.length < 4) {
            revert FunctionSignatureTooShort();
        }

        TargetAddress storage target = role.targets[targetAddress];
        if (target.clearance == Clearance.None) {
            revert TargetAddressNotAllowed();
        }

        if (target.clearance == Clearance.Target) {
            checkExecutionOptions(value, operation, target.options);
            return;
        }

        if (target.clearance == Clearance.Function) {
            uint256 scopeConfig = role.functions[
                keyForFunctions(targetAddress, bytes4(data))
            ];

            if (scopeConfig == 0) {
                revert FunctionNotAllowed();
            }

            (ExecutionOptions options, bool isWildcarded, ) = unpackFunction(
                scopeConfig
            );

            checkExecutionOptions(value, operation, options);

            if (!isWildcarded) {
                checkParameters(role, scopeConfig, targetAddress, data);
            }
            return;
        }

        assert(false);
    }

    /// @dev Examines the ether value and operation for a given role target.
    /// @param value Ether value of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    /// @param options Determines if a transaction can send ether and/or delegatecall to target.
    function checkExecutionOptions(
        uint256 value,
        Enum.Operation operation,
        ExecutionOptions options
    ) internal pure {
        // isSend && !canSend
        if (
            value > 0 &&
            options != ExecutionOptions.Send &&
            options != ExecutionOptions.Both
        ) {
            revert SendNotAllowed();
        }

        // isDelegateCall && !canDelegateCall
        if (
            operation == Enum.Operation.DelegateCall &&
            options != ExecutionOptions.DelegateCall &&
            options != ExecutionOptions.Both
        ) {
            revert DelegateCallNotAllowed();
        }
    }

    /// @dev Will revert if a transaction has a parameter that is not allowed
    /// @param role reference to role storage.
    /// @param scopeConfig packed bytes representing the scope for a role.
    /// @param targetAddress Address to check.
    /// @param data the transaction data to check
    function checkParameters(
        Role storage role,
        uint256 scopeConfig,
        address targetAddress,
        bytes memory data
    ) internal view {
        bytes4 functionSig = bytes4(data);
        (, , uint256 length) = unpackFunction(scopeConfig);

        for (uint256 i = 0; i < length; i++) {
            (
                bool isScoped,
                ParameterType paramType,
                Comparison paramComp
            ) = unpackParameter(scopeConfig, i);

            if (!isScoped) {
                continue;
            }

            bytes32 value;
            if (paramType != ParameterType.Static) {
                value = pluckDynamicValue(data, paramType, i);
            } else {
                value = pluckStaticValue(data, i);
            }

            bytes32 key = keyForCompValues(targetAddress, functionSig, i);
            if (paramComp != Comparison.OneOf) {
                compare(paramComp, role.compValues[key], value);
            } else {
                compareOneOf(role.compValuesOneOf[key], value);
            }
        }
    }

    /// @dev Will revert if a transaction has a parameter value that is not specifically allowed.
    /// @param paramComp the type of comparision: equal, greater, or less than.
    /// @param compValue the value to compare a param against.
    /// @param value the param to be compared against the allowed value.
    function compare(
        Comparison paramComp,
        bytes32 compValue,
        bytes32 value
    ) internal pure {
        if (paramComp == Comparison.EqualTo && value != compValue) {
            revert ParameterNotAllowed();
        } else if (paramComp == Comparison.GreaterThan && value <= compValue) {
            revert ParameterLessThanAllowed();
        } else if (paramComp == Comparison.LessThan && value >= compValue) {
            revert ParameterGreaterThanAllowed();
        }
    }

    /// @dev Will revert if a transaction has a parameter value that is not allowed in an allowlist.
    /// @param compValue array of allowed params.
    /// @param value the param to be compared against the allowlist.
    function compareOneOf(bytes32[] storage compValue, bytes32 value)
        internal
        view
    {
        for (uint256 i = 0; i < compValue.length; i++) {
            if (value == compValue[i]) return;
        }
        revert ParameterNotOneOfAllowed();
    }

    /*
     *
     * SETTERS
     *
     */

    /// @dev Allows transactions to a target address.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function allowTarget(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        ExecutionOptions options
    ) external {
        role.targets[targetAddress] = TargetAddress(Clearance.Target, options);
        emit AllowTarget(roleId, targetAddress, options);
    }

    /// @dev Removes transactions to a target address.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    function revokeTarget(
        Role storage role,
        uint16 roleId,
        address targetAddress
    ) external {
        role.targets[targetAddress] = TargetAddress(
            Clearance.None,
            ExecutionOptions.None
        );
        emit RevokeTarget(roleId, targetAddress);
    }

    /// @dev Designates only specific functions can be called.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    function scopeTarget(
        Role storage role,
        uint16 roleId,
        address targetAddress
    ) external {
        role.targets[targetAddress] = TargetAddress(
            Clearance.Function,
            ExecutionOptions.None
        );
        emit ScopeTarget(roleId, targetAddress);
    }

    /// @dev Specifies the functions that can be called.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function scopeAllowFunction(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig,
        ExecutionOptions options
    ) external {
        /*
         * packLeft(
         *    0           -> start from a fresh scopeConfig
         *    options     -> externally provided options
         *    true        -> mark the function as wildcarded
         *    0           -> length
         * )
         */
        uint256 scopeConfig = packLeft(0, options, true, 0);
        role.functions[
            keyForFunctions(targetAddress, functionSig)
        ] = scopeConfig;
        emit ScopeAllowFunction(
            roleId,
            targetAddress,
            functionSig,
            options,
            scopeConfig
        );
    }

    /// @dev Removes the functions that can be called.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    function scopeRevokeFunction(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig
    ) external {
        role.functions[keyForFunctions(targetAddress, functionSig)] = 0;
        emit ScopeRevokeFunction(roleId, targetAddress, functionSig, 0);
    }

    /// @dev Defines the values that can be called for a given function for each param.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    /// @param isScoped marks which parameters are value restricted.
    /// @param paramType provides information about the type of parameter.
    /// @param paramComp the type of comparison for each parameter
    /// @param compValue the values to compare a param against.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function scopeFunction(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig,
        bool[] memory isScoped,
        ParameterType[] memory paramType,
        Comparison[] memory paramComp,
        bytes[] calldata compValue,
        ExecutionOptions options
    ) external {
        uint256 length = isScoped.length;

        if (
            length != paramType.length ||
            length != paramComp.length ||
            length != compValue.length
        ) {
            revert ArraysDifferentLength();
        }

        if (length > SCOPE_MAX_PARAMS) {
            revert ScopeMaxParametersExceeded();
        }

        for (uint256 i = 0; i < length; i++) {
            if (isScoped[i]) {
                enforceComp(paramType[i], paramComp[i]);
                enforceCompValue(paramType[i], compValue[i]);
            }
        }

        /*
         * packLeft(
         *    0           -> start from a fresh scopeConfig
         *    options     -> externally provided options
         *    false       -> mark the function as not wildcarded
         *    length      -> length
         * )
         */
        uint256 scopeConfig = packLeft(0, options, false, length);
        for (uint256 i = 0; i < length; i++) {
            scopeConfig = packRight(
                scopeConfig,
                i,
                isScoped[i],
                paramType[i],
                paramComp[i]
            );
        }

        //set scopeConfig
        role.functions[
            keyForFunctions(targetAddress, functionSig)
        ] = scopeConfig;

        //set compValues
        for (uint256 i = 0; i < length; i++) {
            role.compValues[
                keyForCompValues(targetAddress, functionSig, i)
            ] = compressCompValue(paramType[i], compValue[i]);
        }
        emit ScopeFunction(
            roleId,
            targetAddress,
            functionSig,
            isScoped,
            paramType,
            paramComp,
            compValue,
            options,
            scopeConfig
        );
    }

    /// @dev Sets the execution options for a given function.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    /// @param options designates if a transaction can send ether and/or delegatecall to target.
    function scopeFunctionExecutionOptions(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig,
        ExecutionOptions options
    ) external {
        bytes32 key = keyForFunctions(targetAddress, functionSig);

        //set scopeConfig
        uint256 scopeConfig = packOptions(role.functions[key], options);

        role.functions[
            keyForFunctions(targetAddress, functionSig)
        ] = scopeConfig;

        emit ScopeFunctionExecutionOptions(
            roleId,
            targetAddress,
            functionSig,
            options,
            scopeConfig
        );
    }

    /// @dev Defines the value that can be called for a given function for single param.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    /// @param index the index of the param to scope.
    /// @param paramType provides information about the type of parameter.
    /// @param paramComp the type of comparison for each parameter.
    /// @param compValue the value to compare a param against.
    function scopeParameter(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig,
        uint256 index,
        ParameterType paramType,
        Comparison paramComp,
        bytes calldata compValue
    ) external {
        if (index >= SCOPE_MAX_PARAMS) {
            revert ScopeMaxParametersExceeded();
        }

        enforceComp(paramType, paramComp);
        enforceCompValue(paramType, compValue);

        // set scopeConfig
        bytes32 key = keyForFunctions(targetAddress, functionSig);
        uint256 scopeConfig = packParameter(
            role.functions[key],
            index,
            true, // isScoped
            paramType,
            paramComp
        );
        role.functions[key] = scopeConfig;

        // set compValue
        role.compValues[
            keyForCompValues(targetAddress, functionSig, index)
        ] = compressCompValue(paramType, compValue);

        emit ScopeParameter(
            roleId,
            targetAddress,
            functionSig,
            index,
            paramType,
            paramComp,
            compValue,
            scopeConfig
        );
    }

    /// @dev Defines the values that can be called for a given function for single param.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    /// @param index the index of the param to scope.
    /// @param paramType provides information about the type of parameter.
    /// @param compValues the values to compare a param against.
    function scopeParameterAsOneOf(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig,
        uint256 index,
        ParameterType paramType,
        bytes[] calldata compValues
    ) external {
        if (index >= SCOPE_MAX_PARAMS) {
            revert ScopeMaxParametersExceeded();
        }

        if (compValues.length < 2) {
            revert NotEnoughCompValuesForOneOf();
        }

        for (uint256 i = 0; i < compValues.length; i++) {
            enforceCompValue(paramType, compValues[i]);
        }

        // set scopeConfig
        bytes32 key = keyForFunctions(targetAddress, functionSig);
        uint256 scopeConfig = packParameter(
            role.functions[key],
            index,
            true, // isScoped
            paramType,
            Comparison.OneOf
        );
        role.functions[key] = scopeConfig;

        // set compValue
        key = keyForCompValues(targetAddress, functionSig, index);
        role.compValuesOneOf[key] = new bytes32[](compValues.length);
        for (uint256 i = 0; i < compValues.length; i++) {
            role.compValuesOneOf[key][i] = compressCompValue(
                paramType,
                compValues[i]
            );
        }

        emit ScopeParameterAsOneOf(
            roleId,
            targetAddress,
            functionSig,
            index,
            paramType,
            compValues,
            scopeConfig
        );
    }

    /// @dev Removes the restrictions for a function param.
    /// @param role reference to role storage.
    /// @param roleId identifier of the role to be modified.
    /// @param targetAddress Destination address of transaction.
    /// @param functionSig 4 byte function selector.
    /// @param index the index of the param to scope.
    function unscopeParameter(
        Role storage role,
        uint16 roleId,
        address targetAddress,
        bytes4 functionSig,
        uint256 index
    ) external {
        if (index >= SCOPE_MAX_PARAMS) {
            revert ScopeMaxParametersExceeded();
        }

        // set scopeConfig
        bytes32 key = keyForFunctions(targetAddress, functionSig);
        uint256 scopeConfig = packParameter(
            role.functions[key],
            index,
            false, // isScoped
            ParameterType(0),
            Comparison(0)
        );
        role.functions[key] = scopeConfig;

        emit UnscopeParameter(
            roleId,
            targetAddress,
            functionSig,
            index,
            scopeConfig
        );
    }

    /// @dev Internal function that enforces a comparison type is valid.
    /// @param paramType provides information about the type of parameter.
    /// @param paramComp the type of comparison for each parameter.
    function enforceComp(ParameterType paramType, Comparison paramComp)
        internal
        pure
    {
        if (paramComp == Comparison.OneOf) {
            revert UnsuitableOneOfComparison();
        }

        if (
            (paramType != ParameterType.Static) &&
            (paramComp != Comparison.EqualTo)
        ) {
            revert UnsuitableRelativeComparison();
        }
    }

    /// @dev Internal function that enforces a param type is valid.
    /// @param paramType provides information about the type of parameter.
    /// @param compValue the value to compare a param against.
    function enforceCompValue(ParameterType paramType, bytes calldata compValue)
        internal
        pure
    {
        if (paramType == ParameterType.Static && compValue.length != 32) {
            revert UnsuitableStaticCompValueSize();
        }

        if (
            paramType == ParameterType.Dynamic32 && compValue.length % 32 != 0
        ) {
            revert UnsuitableDynamic32CompValueSize();
        }
    }

    /*
     *
     * HELPERS
     *
     */

    /// @dev Helper function grab a specific dynamic parameter from data blob.
    /// @param data the parameter data blob.
    /// @param paramType provides information about the type of parameter.
    /// @param index position of the parameter in the data.
    function pluckDynamicValue(
        bytes memory data,
        ParameterType paramType,
        uint256 index
    ) internal pure returns (bytes32) {
        assert(paramType != ParameterType.Static);
        // pre-check: is there a word available for the current parameter at argumentsBlock?
        if (data.length < 4 + index * 32 + 32) {
            revert CalldataOutOfBounds();
        }

        /*
         * Encoded calldata:
         * 4  bytes -> function selector
         * 32 bytes -> sequence, one chunk per parameter
         *
         * There is one (byte32) chunk per parameter. Depending on type it contains:
         * Static    -> value encoded inline (not plucked by this function)
         * Dynamic   -> a byte offset to encoded data payload
         * Dynamic32 -> a byte offset to encoded data payload
         * Note: Fixed Sized Arrays (e.g., bool[2]), are encoded inline
         * Note: Nested types also do not follow the above described rules, and are unsupported
         * Note: The offset to payload does not include 4 bytes for functionSig
         *
         *
         * At encoded payload, the first 32 bytes are the length encoding of the parameter payload. Depending on ParameterType:
         * Dynamic   -> length in bytes
         * Dynamic32 -> length in bytes32
         * Note: Dynamic types are: bytes, string
         * Note: Dynamic32 types are non-nested arrays: address[] bytes32[] uint[] etc
         */

        // the start of the parameter block
        // 32 bytes - length encoding of the data bytes array
        // 4  bytes - function sig
        uint256 argumentsBlock;
        assembly {
            argumentsBlock := add(data, 36)
        }

        // the two offsets are relative to argumentsBlock
        uint256 offset = index * 32;
        uint256 offsetPayload;
        assembly {
            offsetPayload := mload(add(argumentsBlock, offset))
        }

        uint256 lengthPayload;
        assembly {
            lengthPayload := mload(add(argumentsBlock, offsetPayload))
        }

        // account for:
        // 4  bytes - functionSig
        // 32 bytes - length encoding for the parameter payload
        uint256 start = 4 + offsetPayload + 32;
        uint256 end = start +
            (
                paramType == ParameterType.Dynamic32
                    ? lengthPayload * 32
                    : lengthPayload
            );

        // are we slicing out of bounds?
        if (data.length < end) {
            revert CalldataOutOfBounds();
        }

        return keccak256(slice(data, start, end));
    }

    /// @dev Helper function grab a specific static parameter from data blob.
    /// @param data the parameter data blob.
    /// @param index position of the parameter in the data.
    function pluckStaticValue(bytes memory data, uint256 index)
        internal
        pure
        returns (bytes32)
    {
        // pre-check: is there a word available for the current parameter at argumentsBlock?
        if (data.length < 4 + index * 32 + 32) {
            revert CalldataOutOfBounds();
        }

        uint256 offset = 4 + index * 32;
        bytes32 value;
        assembly {
            // add 32 - jump over the length encoding of the data bytes array
            value := mload(add(32, add(data, offset)))
        }
        return value;
    }

    function slice(
        bytes memory data,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes memory result) {
        result = new bytes(end - start);
        for (uint256 j = start; j < end; j++) {
            result[j - start] = data[j];
        }
    }

    /*
     * pack/unpack are bit helpers for scopeConfig
     */
    function packParameter(
        uint256 scopeConfig,
        uint256 index,
        bool isScoped,
        ParameterType paramType,
        Comparison paramComp
    ) internal pure returns (uint256) {
        (ExecutionOptions options, , uint256 prevLength) = unpackFunction(
            scopeConfig
        );

        uint256 nextLength = index + 1 > prevLength ? index + 1 : prevLength;

        return
            packLeft(
                packRight(scopeConfig, index, isScoped, paramType, paramComp),
                options,
                false, // isWildcarded=false
                nextLength
            );
    }

    function packOptions(uint256 scopeConfig, ExecutionOptions options)
        internal
        pure
        returns (uint256)
    {
        uint256 optionsMask = 3 << 254;

        scopeConfig &= ~optionsMask;
        scopeConfig |= uint256(options) << 254;

        return scopeConfig;
    }

    function packLeft(
        uint256 scopeConfig,
        ExecutionOptions options,
        bool isWildcarded,
        uint256 length
    ) internal pure returns (uint256) {
        // LEFT SIDE
        // 2   bits -> options
        // 1   bits -> isWildcarded
        // 5   bits -> unused
        // 8   bits -> length
        // RIGHT SIDE
        // 48  bits -> isScoped
        // 96  bits -> paramType (2 bits per entry 48*2)
        // 96  bits -> paramComp (2 bits per entry 48*2)

        // Wipe the LEFT SIDE clean. Start from there
        scopeConfig = (scopeConfig << 16) >> 16;

        // set options -> 256 - 2 = 254
        scopeConfig |= uint256(options) << 254;

        // set isWildcarded -> 256 - 2 - 1 = 253
        if (isWildcarded) {
            scopeConfig |= 1 << 253;
        }

        // set Length -> 48 + 96 + 96 = 240
        scopeConfig |= length << 240;

        return scopeConfig;
    }

    function packRight(
        uint256 scopeConfig,
        uint256 index,
        bool isScoped,
        ParameterType paramType,
        Comparison paramComp
    ) internal pure returns (uint256) {
        // LEFT SIDE
        // 2   bits -> options
        // 1   bits -> isWildcarded
        // 5   bits -> unused
        // 8   bits -> length
        // RIGHT SIDE
        // 48  bits -> isScoped
        // 96  bits -> paramType (2 bits per entry 48*2)
        // 96  bits -> paramComp (2 bits per entry 48*2)
        uint256 isScopedMask = 1 << (index + 96 + 96);
        uint256 paramTypeMask = 3 << (index * 2 + 96);
        uint256 paramCompMask = 3 << (index * 2);

        if (isScoped) {
            scopeConfig |= isScopedMask;
        } else {
            scopeConfig &= ~isScopedMask;
        }

        scopeConfig &= ~paramTypeMask;
        scopeConfig |= uint256(paramType) << (index * 2 + 96);

        scopeConfig &= ~paramCompMask;
        scopeConfig |= uint256(paramComp) << (index * 2);

        return scopeConfig;
    }

    function unpackFunction(uint256 scopeConfig)
        internal
        pure
        returns (
            ExecutionOptions options,
            bool isWildcarded,
            uint256 length
        )
    {
        uint256 isWildcardedMask = 1 << 253;

        options = ExecutionOptions(scopeConfig >> 254);
        isWildcarded = scopeConfig & isWildcardedMask != 0;
        length = (scopeConfig << 8) >> 248;
    }

    function unpackParameter(uint256 scopeConfig, uint256 index)
        internal
        pure
        returns (
            bool isScoped,
            ParameterType paramType,
            Comparison paramComp
        )
    {
        uint256 isScopedMask = 1 << (index + 96 + 96);
        uint256 paramTypeMask = 3 << (index * 2 + 96);
        uint256 paramCompMask = 3 << (index * 2);

        isScoped = (scopeConfig & isScopedMask) != 0;
        paramType = ParameterType(
            (scopeConfig & paramTypeMask) >> (index * 2 + 96)
        );
        paramComp = Comparison((scopeConfig & paramCompMask) >> (index * 2));
    }

    function keyForFunctions(address targetAddress, bytes4 functionSig)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(abi.encodePacked(targetAddress, functionSig));
    }

    function keyForCompValues(
        address targetAddress,
        bytes4 functionSig,
        uint256 index
    ) internal pure returns (bytes32) {
        assert(index <= type(uint8).max);
        return
            bytes32(abi.encodePacked(targetAddress, functionSig, uint8(index)));
    }

    function compressCompValue(
        ParameterType paramType,
        bytes calldata compValue
    ) internal pure returns (bytes32) {
        return
            paramType == ParameterType.Static
                ? bytes32(compValue)
                : keccak256(compValue);
    }
}

contract Roles is Modifier {
    address public multisend;

    mapping(address => uint16) public defaultRoles;
    mapping(uint16 => Role) internal roles;

    event AssignRoles(address module, uint16[] roles, bool[] memberOf);
    event SetMultisendAddress(address multisendAddress);
    event RolesModSetup(
        address indexed initiator,
        address indexed owner,
        address indexed avatar,
        address target
    );
    event SetDefaultRole(address module, uint16 defaultRole);

    /// Arrays must be the same length
    error ArraysDifferentLength();

    /// Sender is allowed to make this call, but the internal transaction failed
    error ModuleTransactionFailed();

    /// @param _owner Address of the owner
    /// @param _avatar Address of the avatar (e.g. a Gnosis Safe)
    /// @param _target Address of the contract that will call exec function
    constructor(
        address _owner,
        address _avatar,
        address _target
    ) {
        bytes memory initParams = abi.encode(_owner, _avatar, _target);
        setUp(initParams);
    }

    /// @dev There is no zero address check as solidty will check for
    /// missing arguments and the space of invalid addresses is too large
    /// to check. Invalid avatar or target address can be reset by owner.
    function setUp(bytes memory initParams) public override {
        (address _owner, address _avatar, address _target) = abi.decode(
            initParams,
            (address, address, address)
        );
        __Ownable_init();

        avatar = _avatar;
        target = _target;

        transferOwnership(_owner);
        setupModules();

        emit RolesModSetup(msg.sender, _owner, _avatar, _target);
    }

    function setupModules() internal {
        assert(modules[SENTINEL_MODULES] == address(0));
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    /// @dev Set the address of the expected multisend library
    /// @notice Only callable by owner.
    /// @param _multisend address of the multisend library contract
    function setMultisend(address _multisend) external onlyOwner {
        multisend = _multisend;
        emit SetMultisendAddress(multisend);
    }

    /// @dev Allows all calls made to an address.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Address to be allowed
    /// @param options defines whether or not delegate calls and/or eth can be sent to the target address.
    function allowTarget(
        uint16 role,
        address targetAddress,
        ExecutionOptions options
    ) external onlyOwner {
        Permissions.allowTarget(roles[role], role, targetAddress, options);
    }

    /// @dev Disallows all calls made to an address.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Address to be disallowed
    function revokeTarget(uint16 role, address targetAddress)
        external
        onlyOwner
    {
        Permissions.revokeTarget(roles[role], role, targetAddress);
    }

    /// @dev Scopes calls to an address, limited to specific function signatures, and per function scoping rules.
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Address to be scoped.
    function scopeTarget(uint16 role, address targetAddress)
        external
        onlyOwner
    {
        Permissions.scopeTarget(roles[role], role, targetAddress);
    }

    /// @dev Allows a specific function signature on a scoped target.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Scoped address on which a function signature should be allowed.
    /// @param functionSig Function signature to be allowed.
    /// @param options Defines whether or not delegate calls and/or eth can be sent to the function.
    function scopeAllowFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        ExecutionOptions options
    ) external onlyOwner {
        Permissions.scopeAllowFunction(
            roles[role],
            role,
            targetAddress,
            functionSig,
            options
        );
    }

    /// @dev Disallows a specific function signature on a scoped target.
    /// @notice Only callable by owner.
    /// @param role Role to set for
    /// @param targetAddress Scoped address on which a function signature should be disallowed.
    /// @param functionSig Function signature to be disallowed.
    function scopeRevokeFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig
    ) external onlyOwner {
        Permissions.scopeRevokeFunction(
            roles[role],
            role,
            targetAddress,
            functionSig
        );
    }

    /// @dev Sets scoping rules for a function, on a scoped address.
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Scoped address on which scoping rules for a function are to be set.
    /// @param functionSig Function signature to be scoped.
    /// @param isParamScoped false for un-scoped, true for scoped.
    /// @param paramType Static, Dynamic or Dynamic32, depending on the parameter type.
    /// @param paramComp Any, or EqualTo, GreaterThan, or LessThan, depending on comparison type.
    /// @param compValue The reference value used while comparing and authorizing.
    /// @param options Defines whether or not delegate calls and/or eth can be sent to the function.
    function scopeFunction(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        bool[] calldata isParamScoped,
        ParameterType[] calldata paramType,
        Comparison[] calldata paramComp,
        bytes[] memory compValue,
        ExecutionOptions options
    ) external onlyOwner {
        Permissions.scopeFunction(
            roles[role],
            role,
            targetAddress,
            functionSig,
            isParamScoped,
            paramType,
            paramComp,
            compValue,
            options
        );
    }

    /// @dev Sets whether or not delegate calls and/or eth can be sent to a function on a scoped target.
    /// @notice Only callable by owner.
    /// @notice Only in play when target is scoped.
    /// @param role Role to set for.
    /// @param targetAddress Scoped address on which the ExecutionOptions for a function are to be set.
    /// @param functionSig Function signature on which the ExecutionOptions are to be set.
    /// @param options Defines whether or not delegate calls and/or eth can be sent to the function.
    function scopeFunctionExecutionOptions(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        ExecutionOptions options
    ) external onlyOwner {
        Permissions.scopeFunctionExecutionOptions(
            roles[role],
            role,
            targetAddress,
            functionSig,
            options
        );
    }

    /// @dev Sets and enforces scoping rules, for a single parameter of a function, on a scoped target.
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Scoped address on which functionSig lives.
    /// @param functionSig Function signature to be scoped.
    /// @param paramIndex The index of the parameter to scope.
    /// @param paramType Static, Dynamic or Dynamic32, depending on the parameter type.
    /// @param paramComp Any, or EqualTo, GreaterThan, or LessThan, depending on comparison type.
    /// @param compValue The reference value used while comparing and authorizing.
    function scopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint256 paramIndex,
        ParameterType paramType,
        Comparison paramComp,
        bytes calldata compValue
    ) external onlyOwner {
        Permissions.scopeParameter(
            roles[role],
            role,
            targetAddress,
            functionSig,
            paramIndex,
            paramType,
            paramComp,
            compValue
        );
    }

    /// @dev Sets and enforces scoping rules, for a single parameter of a function, on a scoped target.
    /// @notice Only callable by owner.
    /// @notice Parameter will be scoped with comparison type OneOf.
    /// @param role Role to set for.
    /// @param targetAddress Scoped address on which functionSig lives.
    /// @param functionSig Function signature to be scoped.
    /// @param paramIndex The index of the parameter to scope.
    /// @param paramType Static, Dynamic or Dynamic32, depending on the parameter type.
    /// @param compValues The reference values used while comparing and authorizing.
    function scopeParameterAsOneOf(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint256 paramIndex,
        ParameterType paramType,
        bytes[] calldata compValues
    ) external onlyOwner {
        Permissions.scopeParameterAsOneOf(
            roles[role],
            role,
            targetAddress,
            functionSig,
            paramIndex,
            paramType,
            compValues
        );
    }

    /// @dev Un-scopes a single parameter of a function, on a scoped target.
    /// @notice Only callable by owner.
    /// @param role Role to set for.
    /// @param targetAddress Scoped address on which functionSig lives.
    /// @param functionSig Function signature to be scoped.
    /// @param paramIndex The index of the parameter to un-scope.
    function unscopeParameter(
        uint16 role,
        address targetAddress,
        bytes4 functionSig,
        uint8 paramIndex
    ) external onlyOwner {
        Permissions.unscopeParameter(
            roles[role],
            role,
            targetAddress,
            functionSig,
            paramIndex
        );
    }

    /// @dev Assigns and revokes roles to a given module.
    /// @param module Module on which to assign/revoke roles.
    /// @param _roles Roles to assign/revoke.
    /// @param memberOf Assign (true) or revoke (false) corresponding _roles.
    function assignRoles(
        address module,
        uint16[] calldata _roles,
        bool[] calldata memberOf
    ) external onlyOwner {
        if (_roles.length != memberOf.length) {
            revert ArraysDifferentLength();
        }
        for (uint16 i = 0; i < _roles.length; i++) {
            roles[_roles[i]].members[module] = memberOf[i];
        }
        if (!isModuleEnabled(module)) {
            enableModule(module);
        }
        emit AssignRoles(module, _roles, memberOf);
    }

    /// @dev Sets the default role used for a module if it calls execTransactionFromModule() or execTransactionFromModuleReturnData().
    /// @param module Address of the module on which to set default role.
    /// @param role Role to be set as default.
    function setDefaultRole(address module, uint16 role) external onlyOwner {
        defaultRoles[module] = role;
        emit SetDefaultRole(module, role);
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
        Permissions.check(
            roles[defaultRoles[msg.sender]],
            multisend,
            to,
            value,
            data,
            operation
        );
        return exec(to, value, data, operation);
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
    ) public override moduleOnly returns (bool, bytes memory) {
        Permissions.check(
            roles[defaultRoles[msg.sender]],
            multisend,
            to,
            value,
            data,
            operation
        );
        return execAndReturnData(to, value, data, operation);
    }

    /// @dev Passes a transaction to the modifier assuming the specified role.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param role Identifier of the role to assume for this transaction
    /// @param shouldRevert Should the function revert on inner execution returning success false?
    /// @notice Can only be called by enabled modules
    function execTransactionWithRole(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint16 role,
        bool shouldRevert
    ) public moduleOnly returns (bool success) {
        Permissions.check(roles[role], multisend, to, value, data, operation);
        success = exec(to, value, data, operation);
        if (shouldRevert && !success) {
            revert ModuleTransactionFailed();
        }
    }

    /// @dev Passes a transaction to the modifier assuming the specified role. Expects return data.
    /// @param to Destination address of module transaction
    /// @param value Ether value of module transaction
    /// @param data Data payload of module transaction
    /// @param operation Operation type of module transaction
    /// @param role Identifier of the role to assume for this transaction
    /// @param shouldRevert Should the function revert on inner execution returning success false?
    /// @notice Can only be called by enabled modules
    function execTransactionWithRoleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint16 role,
        bool shouldRevert
    ) public moduleOnly returns (bool success, bytes memory returnData) {
        Permissions.check(roles[role], multisend, to, value, data, operation);
        (success, returnData) = execAndReturnData(to, value, data, operation);
        if (shouldRevert && !success) {
            revert ModuleTransactionFailed();
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/// @title Gnosis Protocol v2 Order Library modified to 0.8.13
/// @author Gnosis Developers
library GPv2Order {
    /// @dev The complete data for a Gnosis Protocol order. This struct contains
    /// all order parameters that are signed for submitting to GP.
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        bytes32 kind;
        bool partiallyFillable;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
    }

    /// @dev The order EIP-712 type hash for the [`GPv2Order.Data`] struct.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256(
    ///     "Order(" +
    ///         "address sellToken," +
    ///         "address buyToken," +
    ///         "address receiver," +
    ///         "uint256 sellAmount," +
    ///         "uint256 buyAmount," +
    ///         "uint32 validTo," +
    ///         "bytes32 appData," +
    ///         "uint256 feeAmount," +
    ///         "string kind," +
    ///         "bool partiallyFillable," +
    ///         "string sellTokenBalance," +
    ///         "string buyTokenBalance" +
    ///     ")"
    /// )
    /// ```
    bytes32 internal constant TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";

    /// @dev The marker value for a sell order for computing the order struct
    /// hash. This allows the EIP-712 compatible wallets to display a
    /// descriptive string for the order kind (instead of 0 or 1).
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("sell")
    /// ```
    bytes32 internal constant KIND_SELL =
        hex"f3b277728b3fee749481eb3e0b3b48980dbbab78658fc419025cb16eee346775";

    /// @dev The OrderKind marker value for a buy order for computing the order
    /// struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("buy")
    /// ```
    bytes32 internal constant KIND_BUY =
        hex"6ed88e868af0a1983e3886d5f3e95a2fafbd6c3450bc229e27342283dc429ccc";

    /// @dev The TokenBalance marker value for using direct ERC20 balances for
    /// computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("erc20")
    /// ```
    bytes32 internal constant BALANCE_ERC20 =
        hex"5a28e9363bb942b639270062aa6bb295f434bcdfc42c97267bf003f272060dc9";

    /// @dev The TokenBalance marker value for using Balancer Vault external
    /// balances (in order to re-use Vault ERC20 approvals) for computing the
    /// order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("external")
    /// ```
    bytes32 internal constant BALANCE_EXTERNAL =
        hex"abee3b73373acd583a130924aad6dc38cfdc44ba0555ba94ce2ff63980ea0632";

    /// @dev The TokenBalance marker value for using Balancer Vault internal
    /// balances for computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("internal")
    /// ```
    bytes32 internal constant BALANCE_INTERNAL =
        hex"4ac99ace14ee0a5ef932dc609df0943ab7ac16b7583634612f8dc35a4289a6ce";

    /// @dev Marker address used to indicate that the receiver of the trade
    /// proceeds should the owner of the order.
    ///
    /// This is chosen to be `address(0)` for gas efficiency as it is expected
    /// to be the most common case.
    address internal constant RECEIVER_SAME_AS_OWNER = address(0);

    /// @dev The byte length of an order unique identifier.
    uint256 internal constant UID_LENGTH = 56;

    /// @dev Returns the actual receiver for an order. This function checks
    /// whether or not the [`receiver`] field uses the marker value to indicate
    /// it is the same as the order owner.
    ///
    /// @return receiver The actual receiver of trade proceeds.
    function actualReceiver(Data memory order, address owner)
        internal
        pure
        returns (address receiver)
    {
        if (order.receiver == RECEIVER_SAME_AS_OWNER) {
            receiver = owner;
        } else {
            receiver = order.receiver;
        }
    }

    /// @dev Return the EIP-712 signing hash for the specified order.
    ///
    /// @param order The order to compute the EIP-712 signing hash for.
    /// @param domainSeparator The EIP-712 domain separator to use.
    /// @return orderDigest The 32 byte EIP-712 struct hash.
    function hash(Data memory order, bytes32 domainSeparator)
        internal
        pure
        returns (bytes32 orderDigest)
    {
        bytes32 structHash;

        // NOTE: Compute the EIP-712 order struct hash in place. As suggested
        // in the EIP proposal, noting that the order struct has 12 fields, and
        // prefixing the type hash `(1 + 12) * 32 = 416` bytes to hash.
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-encodedata>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, TYPE_HASH)
            structHash := keccak256(dataStart, 416)
            mstore(dataStart, temp)
        }

        // NOTE: Now that we have the struct hash, compute the EIP-712 signing
        // hash using scratch memory past the free memory pointer. The signing
        // hash is computed from `"\x19\x01" || domainSeparator || structHash`.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory>
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(bytes calldata orderUid)
        internal
        pure
        returns (
            bytes32 orderDigest,
            address owner,
            uint32 validTo
        )
    {
        require(orderUid.length == UID_LENGTH, "GPv2: invalid uid");

        // Use assembly to efficiently decode packed calldata.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            orderDigest := calldataload(orderUid.offset)
            owner := shr(96, calldataload(add(orderUid.offset, 32)))
            validTo := shr(224, calldataload(add(orderUid.offset, 52)))
        }
    }
}

pragma abicoder v2;

interface IPriceChecker {
    function checkPrice(
        uint256 _amountIn,
        address _fromToken,
        address _toToken,
        uint256 _feeAmount,
        uint256 _minOut,
        bytes calldata _data
    ) external view returns (bool);
}

error SameInOut();
error EmptyTokenArr();
error WrongArrLen();
error BadNonce();
error CallFail();
error AlreadyInit();
error ProxyCallOnly();
error ImplCallOnly();
error BadSeparator();
error BadTradeType();
error BadTimestamp();
error BadOrderType();
error BadBuyBalance();
error BadSellBalance();
error BadSign();

/**
 * Zodiac module with role-based access for cowswap swaps
 * Role based access from zodiac gives control of func param calls
 */
contract MooneyModule is Roles {
    using SafeERC20 for IERC20;
    using GPv2Order for GPv2Order.Data;

    event SwapRequested(
        address orderContract,
        address orderCreator,
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes priceCheckerData
    );

    event UpdateSendPermissions(
        address caller,
        bool setup, 
        IERC20[] fromTokens, 
        IERC20[] toTokens,
        uint256 swapLimit
    );

    event NewPriceChecker(address priceChecker);

    event NewPriceCheckerData(bytes priceCheckerData);

    address public priceChecker;
    bytes public priceCheckerData;

    /// @dev The contract Milkman needs to give allowance.
    address internal immutable VAULT_RELAYER = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
    /// @dev The settlement contract's EIP-712 domain separator. Milkman uses this to verify that a provided UID matches provided order parameters.
    bytes32 public constant DOMAIN_SEPARATOR =
        0xc078f884a2676e1345748b1feace7b0abee5d00ecadb6e574dcdd109a63e8943;
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;
    bytes4 internal constant NON_MAGIC_VALUE = 0xffffffff;
    bytes32 internal constant ROOT_MILKMAN_SWAP_HASH =
        0xca11ab1efacade00000000000000000000000000000000000000000000000000;

    uint16 lastRole = 1;
    mapping(address => uint16) public tokensToRole;

    uint256 public nonce;
    bytes32 public swapHash;

    constructor(
        address _owner,
        address _avatar,
        address _target
    ) Roles(_owner, _avatar, _target) {
        // to differentiate proxy vs master
        swapHash = ROOT_MILKMAN_SWAP_HASH;
    }

    function initialize(IERC20 fromToken, bytes32 _swapHash) external {
        if (swapHash != bytes32(0) || _swapHash == bytes32(0)) {
            revert AlreadyInit();
        }
        swapHash = _swapHash;
        fromToken.safeApprove(VAULT_RELAYER, type(uint256).max);
    }

    function isImpl() internal view returns (bool) {
        return (swapHash == ROOT_MILKMAN_SWAP_HASH);
    }

    modifier noImpl() {
        if (isImpl()) {
            revert ProxyCallOnly();
        }
        _;
    }

    modifier noProxy() {
        if (!isImpl()) {
            revert ImplCallOnly();
        }
        _;
    }

    /**
     * @notice Create a swap 
     * @dev this tx is called from safe
     * @dev this call will originate via sendCreateSwap or from execTransaction from a parent module
     * @dev we deploy a proxy to do swaps. 1 proxy per swap. allows you to cancel easily (by pulling funds out)
     * @param amountIn amount of input token
     * @param fromToken addr of input erc20
     * @param toToken addr of output erc20
     */
    function createSwap(
        uint256 amountIn, 
        IERC20 fromToken, 
        IERC20 toToken
    ) external noProxy onlyOwner {
        if (address(fromToken) == address(toToken)) {
            revert SameInOut();
        }

        address orderContract = createOrderContract();
        fromToken.safeTransferFrom(msg.sender, orderContract, amountIn);

        // compute and set valid signature
        bytes32 _swapHash = keccak256(
            abi.encode(
                address(this),
                owner(),
                fromToken,
                toToken,
                amountIn,
                priceChecker,
                priceCheckerData
            )
        );

        MooneyModule(orderContract).initialize(fromToken, _swapHash);

        emit SwapRequested(
            orderContract,
            msg.sender,
            amountIn,
            address(fromToken),
            address(toToken),
            owner(),
            priceChecker,
            priceCheckerData
        );
    }
    
    /**
     * @notice this function starts a createSwap tx flow
     * @dev tx will go down into the safe via execTx..() and exec() loops
     * @param amountIn amount of erc20 token to swap
     * @param fromToken addr of input token
     * @param toToken addr of output token 
     */
    function sendCreateSwap(uint256 amountIn, IERC20 fromToken, IERC20 toToken) public noProxy {
        if (address(fromToken) == address(toToken)) {
            revert SameInOut();
        }

        // approve tx        
        checkAndSend(
            roles[defaultRoles[msg.sender]], 
            address(fromToken), 
            abi.encodeWithSelector(
                IERC20.approve.selector, 
                address(this), //spender 
                amountIn //amountToken
            ), 
            Enum.Operation.Call
        );

        // createSwap tx
        checkAndSend(
            roles[defaultRoles[msg.sender]], 
            address(this),
            abi.encodeWithSelector(
                this.createSwap.selector, 
                amountIn, 
                fromToken, 
                toToken
            ), 
            Enum.Operation.Call
        );
    }

    /**
     * @notice Function calls cancel swap on the proxy
     * @dev must be called from safe, same flow from 
     * @param amountIn amount of input token
     * @param fromToken addr of from token
     * @param toToken addr of to token
     * @param _priceChecker address of price checker
     * @param _priceCheckerData data to pass into check
     * @param _orderContract addr of proxy
     */
    function cancelSwap(
        uint256 amountIn,
        IERC20 fromToken,
        IERC20 toToken,
        address _priceChecker, // have to specify, else cant cancel old orders when it change
        bytes calldata _priceCheckerData, // same as above
        address _orderContract
    ) public onlyOwner noProxy {
        MooneyModule(_orderContract).cancelSwapProxy(
            amountIn,
            fromToken,
            toToken,
            _priceChecker,
            _priceCheckerData,
            owner()
        );
    }

    /**
     * @notice Function in proxy that cancels a swap
     * @param amountIn amount of input token
     * @param fromToken addr of to token
     * @param toToken addr of to token
     * @param _priceChecker address of price checker
     * @param _priceCheckerData data to pass into check
     * @param owner addr where tokens will sent to = gnosis safe
     */
    function cancelSwapProxy(
        uint256 amountIn,
        IERC20 fromToken,
        IERC20 toToken,
        address _priceChecker, // have to specify, else cant cancel old orders when it changes
        bytes calldata _priceCheckerData, // same as above
        address owner
    ) public noImpl {
        bytes32 _calculatedSwapHash = keccak256(
            abi.encode(
                msg.sender,
                owner,
                fromToken,
                toToken,
                amountIn,
                _priceChecker,
                _priceCheckerData
            )
        );

        require(swapHash == _calculatedSwapHash, "!valid_creator_proof");

        // we sub in createswap fn selector to do the check 
        fromToken.safeTransfer(owner, amountIn);
    }

    /**
     * @notice Function to start cancelling a swap 
     * @param amountIn amount of input token
     * @param fromToken addr of to token
     * @param toToken addr of to token
     * @param _priceChecker address of price checker
     * @param _priceCheckerData data to pass into check
     * @param _orderContract addr of proxy
     */
    function sendCancelSwap(
        uint256 amountIn,
        IERC20 fromToken,
        IERC20 toToken,
        address _priceChecker, // have to specify, else might not be able to cancel some
        bytes calldata _priceCheckerData,
        address _orderContract
    ) public noProxy {
        checkAndSend(
            roles[defaultRoles[msg.sender]], 
            address(this), 
            abi.encodeWithSelector(
                this.cancelSwap.selector,
                amountIn,
                fromToken,
                toToken, 
                _priceChecker,
                _priceCheckerData,
                _orderContract
            ), 
            Enum.Operation.Call
        );
    }

    /**
     * @notice This function modifies the list of input-token-roles for a swapper
     */
    function updateSendPermissions(
        address caller,
        bool setup, 
        IERC20[] memory fromTokens, 
        IERC20[] memory toTokens,
        uint256 swapLimit 
    ) public onlyOwner noProxy {
        // assign nonzero role
        uint16 role = defaultRoles[caller];
        if (role == 0) {
            defaultRoles[caller] = lastRole;
            role = lastRole;
            ++lastRole;
        }

        if (roles[role].targets[caller].clearance != Clearance.Function) {
            Permissions.scopeTarget(
                roles[role],
                role,
                address(this)
            );
        }

        // add as role member
        roles[role].members[caller] = true;

        // allowing calls to erc20 for safe to call inputtoken. approve
        for (uint i = 0; i < fromTokens.length; i++) {
            Permissions.allowTarget(
                roles[role],
                role,
                address(fromTokens[i]),
                ExecutionOptions.None
            );
        }

        bytes4[2] memory fnSigs = [this.createSwap.selector, this.cancelSwap.selector];

        for (uint i = 0; i < 2; i++) {
            if (setup) {
                Permissions.scopeAllowFunction(
                    roles[role],
                    role,
                    address(this),
                    fnSigs[i],
                    ExecutionOptions.None
                );
            } else {
                Permissions.scopeRevokeFunction(
                    roles[role],
                    role,
                    address(this),
                    fnSigs[i]
                );
            }

            // changing swapLimit
            Permissions.scopeParameter(
                roles[role],
                role,
                address(this),
                fnSigs[i],
                0,
                ParameterType.Static,
                Comparison.LessThan,
                abi.encode(swapLimit)
            );

            if (fromTokens.length == 1) {
                Permissions.scopeParameter(
                    roles[role], // roles
                    role, //role
                    address(this), // target
                    fnSigs[i], //fn sig
                    1, //arg idx
                    ParameterType.Static,  //paramtype
                    Comparison.EqualTo, //comparison
                    ierc20ToBytes(fromTokens[0])
                );
            } else if (fromTokens.length > 1) {
                // adding from tokens
                Permissions.scopeParameterAsOneOf(
                    roles[role], // roles
                    role, // role
                    address(this), // target
                    fnSigs[i], //fn sig
                    1, //arg idx
                    ParameterType.Static, //paramtype
                    ierc20ArrToBytesArr(fromTokens)
                );
            }

            if (fromTokens.length == 1) {
                Permissions.scopeParameter(
                    roles[role], // roles                    
                    role, // role
                    address(this), // target
                    fnSigs[i], //fn sig
                    2, //arg idx
                    ParameterType.Static, //paramtype
                    Comparison.EqualTo, //comparison
                    ierc20ToBytes(toTokens[0])
                );
            } else if (fromTokens.length > 1) {
                // adding to tokens
                Permissions.scopeParameterAsOneOf(
                    roles[role], // roles
                    role, // role
                    address(this), // target
                    fnSigs[i], //fn sig
                    2, //arg idx
                    ParameterType.Static, //paramtype
                    ierc20ArrToBytesArr(toTokens)
                );
            }
        }
        
        emit UpdateSendPermissions(caller, setup, fromTokens, toTokens, swapLimit);
    }

    /** 
     * @notice 1271 contract signatures based on created orders
     * @param _orderDigest hash of the order 
     * @param _encodedOrder full bytes of the order
     * @return bytes4 good sig = MAGIC_VALUE, bad sig = NON_MAGIC_VALUE
     */
    function isValidSignature(bytes32 _orderDigest, bytes calldata _encodedOrder) external noImpl view returns (bytes4) {
        (
            GPv2Order.Data memory _order,
            address _orderCreator,
            address _priceChecker,
            bytes memory _priceCheckerData
        ) = abi.decode(
            _encodedOrder,
            (GPv2Order.Data, address, address, bytes)
        );

        if (_order.hash(DOMAIN_SEPARATOR) != _orderDigest) {
            revert BadSeparator();
        }

        if (_order.kind != GPv2Order.KIND_SELL) {
            revert BadTradeType();
        }
        
        if (_order.validTo < block.timestamp + 5 minutes) {
            revert BadTimestamp();
        }        
        
        if (_order.partiallyFillable) {
            revert BadOrderType();
        }

        if (_order.sellTokenBalance != GPv2Order.BALANCE_ERC20) {
            revert BadBuyBalance();
        }
        
        if (_order.buyTokenBalance == GPv2Order.BALANCE_ERC20) {
            revert BadSellBalance();
        }

        // pricechecker = addr(0) for no oracle
        if (priceChecker != address(0) &&
            !IPriceChecker(priceChecker).checkPrice(
            _order.sellAmount + _order.feeAmount,
            address(_order.sellToken),
            address(_order.buyToken),
            _order.feeAmount,
            _order.buyAmount,
            priceCheckerData
        )) {
            revert BadSign();
        }

        bytes32 _calculatedSwapHash = keccak256(
            abi.encode(
                _orderCreator,
                _order.receiver,
                _order.sellToken,
                _order.buyToken,
                _order.sellAmount + _order.feeAmount,
                _priceChecker,
                _priceCheckerData
            )
        );

        if (_calculatedSwapHash == swapHash) {
            // should be true as long as the keeper isn't submitting bad orders
            return MAGIC_VALUE;
        } else {
            return NON_MAGIC_VALUE;
        }
    }

    function checkAndSend(Role storage _role, address _to, bytes memory _data, Enum.Operation _operation) internal {
        Permissions.check(
            _role, 
            multisend,
            _to,
            0,
            _data,
            _operation
        );
        exec(_to, 0, _data, _operation);
    }

    /**
     * @notice sets price oracle
     * @dev only callable by safe owner
     * @param _priceChecker address of new price checker
     */
    function setPriceChecker(address _priceChecker) public onlyOwner {
        priceChecker = _priceChecker;
        emit NewPriceChecker(priceChecker);
    }

    /**
     * @notice sets price data for swaps
     * @dev only callable by safe owner
     * @param _priceCheckData data for new price checker
     */
    function setPriceCheckerData(bytes memory _priceCheckData) public onlyOwner {
        priceCheckerData = _priceCheckData;
        emit NewPriceCheckerData(priceCheckerData);
    }

    function createOrderContract() internal returns (address _orderContract) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol

        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            _orderContract := create(0, clone_code, 0x37)
        }
    }

    function ierc20ArrToBytesArr(IERC20[] memory a) internal pure returns (bytes[] memory b) {
            b = new bytes[](a.length);
            for (uint i = 0; i < a.length; i++) {
                b[i] = ierc20ToBytes(a[i]);
            }
    }

    function ierc20ToBytes(IERC20 a) internal pure returns (bytes memory b) {
        b = abi.encodePacked(
                    uint256(
                        uint160(
                            address(a)
                        )
                    )
                );
    }
}