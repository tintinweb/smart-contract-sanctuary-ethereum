//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { IMultisigFreezeGuard } from "./interfaces/IMultisigFreezeGuard.sol";
import { IBaseFreezeVoting } from "./interfaces/IBaseFreezeVoting.sol";
import { ISafe } from "./interfaces/ISafe.sol";
import { IGuard } from "@gnosis.pm/zodiac/contracts/interfaces/IGuard.sol";
import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { BaseGuard } from "@gnosis.pm/zodiac/contracts/guard/BaseGuard.sol";

/**
 * Implementation of [IMultisigFreezeGuard](./interfaces/IMultisigFreezeGuard.md).
 */
contract MultisigFreezeGuard is FactoryFriendly, IGuard, IMultisigFreezeGuard, BaseGuard {

    /** Timelock period (in blocks). */
    uint32 public timelockPeriod;

    /** Execution period (in blocks). */
    uint32 public executionPeriod;

    /**
     * Reference to the [IBaseFreezeVoting](./interfaces/IBaseFreezeVoting.md)
     * implementation that determines whether the Safe is frozen.
     */
    IBaseFreezeVoting public freezeVoting;

    /** Reference to the Safe that can be frozen. */
    ISafe public childGnosisSafe;

    /** Mapping of signatures hash to the block during which it was timelocked. */
    mapping(bytes32 => uint32) internal transactionTimelockedBlock;

    event MultisigFreezeGuardSetup(
        address creator,
        address indexed owner,
        address indexed freezeVoting,
        address indexed childGnosisSafe
    );
    event TransactionTimelocked(
        address indexed timelocker,
        bytes32 indexed transactionHash,
        bytes indexed signatures
    );
    event TimelockPeriodUpdated(uint32 timelockPeriod);
    event ExecutionPeriodUpdated(uint32 executionPeriod);

    error AlreadyTimelocked();
    error NotTimelocked();
    error Timelocked();
    error Expired();
    error DAOFrozen();

    constructor() {
      _disableInitializers();
    }

    /**
     * Initialize function, will be triggered when a new instance is deployed.
     *
     * @param initializeParams encoded initialization parameters: `uint256 _timelockPeriod`,
     * `uint256 _executionPeriod`, `address _owner`, `address _freezeVoting`, `address _childGnosisSafe`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            address _owner,
            address _freezeVoting,
            address _childGnosisSafe
        ) = abi.decode(
                initializeParams,
                (uint32, uint32, address, address, address)
            );

        _updateTimelockPeriod(_timelockPeriod);
        _updateExecutionPeriod(_executionPeriod);
        transferOwnership(_owner);
        freezeVoting = IBaseFreezeVoting(_freezeVoting);
        childGnosisSafe = ISafe(_childGnosisSafe);

        emit MultisigFreezeGuardSetup(
            msg.sender,
            _owner,
            _freezeVoting,
            _childGnosisSafe
        );
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function timelockTransaction(
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
        uint256 nonce
    ) external {
        bytes32 signaturesHash = keccak256(signatures);

        if (transactionTimelockedBlock[signaturesHash] != 0)
            revert AlreadyTimelocked();

        bytes memory transactionHashData = childGnosisSafe
            .encodeTransactionData(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                nonce
            );

        bytes32 transactionHash = keccak256(transactionHashData);

        // if signatures are not valid, this will revert
        childGnosisSafe.checkSignatures(
            transactionHash,
            transactionHashData,
            signatures
        );

        transactionTimelockedBlock[signaturesHash] = uint32(block.number);

        emit TransactionTimelocked(msg.sender, transactionHash, signatures);
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function updateTimelockPeriod(uint32 _timelockPeriod) external onlyOwner {
        _updateTimelockPeriod(_timelockPeriod);
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function updateExecutionPeriod(uint32 _executionPeriod) external onlyOwner {
        executionPeriod = _executionPeriod;
    }

    /**
     * Called by the Safe to check if the transaction is able to be executed and reverts
     * if the guard conditions are not met.
     */
    function checkTransaction(
        address,
        uint256,
        bytes memory,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory signatures,
        address
    ) external view override(BaseGuard, IGuard) {
        bytes32 signaturesHash = keccak256(signatures);

        if (transactionTimelockedBlock[signaturesHash] == 0)
            revert NotTimelocked();

        if (
            block.number <
            transactionTimelockedBlock[signaturesHash] + timelockPeriod
        ) revert Timelocked();

        if (
            block.number >
            transactionTimelockedBlock[signaturesHash] +
                timelockPeriod +
                executionPeriod
        ) revert Expired();

        if (freezeVoting.isFrozen()) revert DAOFrozen();
    }

    /**
     * A callback performed after a transaction is executed on the Safe. This is a required
     * function of the `BaseGuard` and `IGuard` interfaces that we do not make use of.
     */
    function checkAfterExecution(bytes32, bool) external view override(BaseGuard, IGuard) {
        // not implementated
    }

    /** @inheritdoc IMultisigFreezeGuard*/
    function getTransactionTimelockedBlock(bytes32 _signaturesHash) public view returns (uint32) {
        return transactionTimelockedBlock[_signaturesHash];
    }

    /** Internal implementation of `updateTimelockPeriod` */
    function _updateTimelockPeriod(uint32 _timelockPeriod) internal {
        timelockPeriod = _timelockPeriod;
        emit TimelockPeriodUpdated(_timelockPeriod);
    }

    /** Internal implementation of `updateExecutionPeriod` */
    function _updateExecutionPeriod(uint32 _executionPeriod) internal {
        executionPeriod = _executionPeriod;
        emit ExecutionPeriodUpdated(_executionPeriod);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * A specification for a Safe Guard contract which allows for multi-sig DAOs (Safes)
 * to operate in a fashion similar to [Azorius](../azorius/Azorius.md) token voting DAOs.
 *
 * This Guard is intended to add a timelock period and execution period to a Safe
 * multi-sig contract, allowing parent DAOs to have the ability to properly
 * freeze multi-sig subDAOs.
 *
 * Without a timelock period, a vote to freeze the Safe would not be possible
 * as the multi-sig child could immediately execute any transactions they would like
 * in response.
 *
 * An execution period is also required. This is to prevent executing the transaction after
 * a potential freeze period is enacted. Without it a subDAO could just wait for a freeze
 * period to elapse and then execute their desired transaction.
 *
 * See https://docs.safe.global/learn/safe-core/safe-core-protocol/guards.
 */
interface IMultisigFreezeGuard {

    /**
     * Allows the caller to begin the `timelock` of a transaction.
     *
     * Timelock is the period during which a proposed transaction must wait before being
     * executed, after it has passed.  This period is intended to allow the parent DAO
     * sufficient time to potentially freeze the DAO, if they should vote to do so.
     *
     * The parameters for doing so are identical to [ISafe's](./ISafe.md) `execTransaction` function.
     *
     * @param _to destination address
     * @param _value ETH value
     * @param _data data payload
     * @param _operation Operation type, Call or DelegateCall
     * @param _safeTxGas gas that should be used for the safe transaction
     * @param _baseGas gas costs that are independent of the transaction execution
     * @param _gasPrice max gas price that should be used for this transaction
     * @param _gasToken token address (or 0 if ETH) that is used for the payment
     * @param _refundReceiver address of the receiver of gas payment (or 0 if tx.origin)
     * @param _signatures packed signature data
     * @param _nonce nonce to use for the safe transaction
     */
    function timelockTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address payable _refundReceiver,
        bytes memory _signatures,
        uint256 _nonce
    ) external;

    /**
     * Sets the subDAO's timelock period.
     *
     * @param _timelockPeriod new timelock period for the subDAO (in blocks)
     */
    function updateTimelockPeriod(uint32 _timelockPeriod) external;

    /**
     * Updates the execution period.
     *
     * Execution period is the time period during which a subDAO's passed Proposals must be executed,
     * otherwise they will be expired.
     *
     * This period begins immediately after the timelock period has ended.
     *
     * @param _executionPeriod number of blocks a transaction has to be executed within
     */
    function updateExecutionPeriod(uint32 _executionPeriod) external;

    /**
     * Gets the block number that the given transaction was timelocked at.
     *
     * @param _signaturesHash hash of the transaction signatures
     * @return uint32 block number in which the transaction began its timelock period
     */
    function getTransactionTimelockedBlock(bytes32 _signaturesHash) external view returns (uint32);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * A specification for a contract which manages the ability to call for and cast a vote
 * to freeze a subDAO.
 *
 * The participants of this vote are parent token holders or signers. The DAO should be
 * able to operate as normal throughout the freeze voting process, however if the vote
 * passes, further transaction executions on the subDAO should be blocked via a Safe guard
 * module (see [MultisigFreezeGuard](../MultisigFreezeGuard.md) / [AzoriusFreezeGuard](../AzoriusFreezeGuard.md)).
 */
interface IBaseFreezeVoting {

    /**
     * Allows an address to cast a "freeze vote", which is a vote to freeze the DAO
     * from executing transactions, even if they've already passed via a Proposal.
     *
     * If a vote to freeze has not already been initiated, a call to this function will do
     * so.
     *
     * This function should be publicly callable by any DAO token holder or signer.
     */
    function castFreezeVote() external;

    /**
     * Unfreezes the DAO.
     */
    function unfreeze() external;

    /**
     * Updates the freeze votes threshold for future freeze votes. This is the number of token
     * votes necessary to begin a freeze on the subDAO.
     *
     * @param _freezeVotesThreshold number of freeze votes required to activate a freeze
     */
    function updateFreezeVotesThreshold(uint256 _freezeVotesThreshold) external;

    /**
     * Updates the freeze proposal period for future freeze votes. This is the length of time
     * (in blocks) that a freeze vote is conducted for.
     *
     * @param _freezeProposalPeriod number of blocks a freeze proposal has to succeed
     */
    function updateFreezeProposalPeriod(uint32 _freezeProposalPeriod) external;

    /**
     * Updates the freeze period. This is the length of time (in blocks) the subDAO is actually
     * frozen for if a freeze vote passes.
     *
     * This period can be overridden by a call to `unfreeze()`, which would require a passed Proposal
     * from the parentDAO.
     *
     * @param _freezePeriod number of blocks a freeze lasts, from time of freeze proposal creation
     */
    function updateFreezePeriod(uint32 _freezePeriod) external;

    /**
     * Returns true if the DAO is currently frozen, false otherwise.
     *
     * @return bool whether the DAO is currently frozen
     */
    function isFrozen() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * The specification of methods available on a Safe contract wallet.
 * 
 * This interface does not encompass every available function on a Safe,
 * only those which are used within the Azorius contracts.
 *
 * For the complete set of functions available on a Safe, see:
 * https://github.com/safe-global/safe-contracts/blob/main/contracts/Safe.sol
 */
interface ISafe {

    /**
     * Returns the current transaction nonce of the Safe.
     * Each transaction should has a different nonce to prevent replay attacks.
     *
     * @return uint256 current transaction nonce
     */
    function nonce() external view returns (uint256);

    /**
     * Set a guard contract that checks transactions before execution.
     * This can only be done via a Safe transaction.
     *
     * See https://docs.gnosis-safe.io/learn/safe-tools/guards.
     * See https://github.com/safe-global/safe-contracts/blob/main/contracts/base/GuardManager.sol.
     * 
     * @param _guard address of the guard to be used or the 0 address to disable a guard
     */
    function setGuard(address _guard) external;

    /**
     * Executes an arbitrary transaction on the Safe.
     *
     * @param _to destination address
     * @param _value ETH value
     * @param _data data payload
     * @param _operation Operation type, Call or DelegateCall
     * @param _safeTxGas gas that should be used for the safe transaction
     * @param _baseGas gas costs that are independent of the transaction execution
     * @param _gasPrice max gas price that should be used for this transaction
     * @param _gasToken token address (or 0 if ETH) that is used for the payment
     * @param _refundReceiver address of the receiver of gas payment (or 0 if tx.origin)
     * @param _signatures packed signature data
     * @return success bool whether the transaction was successful or not
     */
    function execTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address payable _refundReceiver,
        bytes memory _signatures
    ) external payable returns (bool success);

    /**
     * Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     *
     * @param _dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param _data That should be signed (this is passed to an external validator contract)
     * @param _signatures Signature data that should be verified. Can be packed ECDSA signature 
     *      ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(bytes32 _dataHash, bytes memory _data, bytes memory _signatures) external view;

    /**
     * Returns the pre-image of the transaction hash.
     *
     * @param _to destination address
     * @param _value ETH value
     * @param _data data payload
     * @param _operation Operation type, Call or DelegateCall
     * @param _safeTxGas gas that should be used for the safe transaction
     * @param _baseGas gas costs that are independent of the transaction execution
     * @param _gasPrice max gas price that should be used for this transaction
     * @param _gasToken token address (or 0 if ETH) that is used for the payment
     * @param _refundReceiver address of the receiver of gas payment (or 0 if tx.origin)
     * @param _nonce transaction nonce
     * @return bytes hash bytes
     */
    function encodeTransactionData(
        address _to,
        uint256 _value,
        bytes calldata _data,
        Enum.Operation _operation,
        uint256 _safeTxGas,
        uint256 _baseGas,
        uint256 _gasPrice,
        address _gasToken,
        address _refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    /**
     * Returns if the given address is an owner of the Safe.
     *
     * See https://github.com/safe-global/safe-contracts/blob/main/contracts/base/OwnerManager.sol.
     *
     * @param _owner the address to check
     * @return bool whether _owner is an owner of the Safe
     */
    function isOwner(address _owner) external view returns (bool);
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

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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