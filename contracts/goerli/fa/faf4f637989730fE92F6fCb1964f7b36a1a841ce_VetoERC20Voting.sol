//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVetoGuard.sol";
import "./interfaces/IVetoVoting.sol";
import "./TransactionHasher.sol";
import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

/// @notice A contract for casting veto votes with an ERC20 votes token
contract VetoERC20Voting is IVetoVoting, TransactionHasher, FactoryFriendly {
    uint256 public vetoVotesThreshold; // Number of votes required to veto a transaction
    uint256 public freezeVotesThreshold; // Number of freeze votes required to activate a freeze
    uint256 public freezeProposalCreatedBlock; // Block number the freeze proposal was created at
    uint256 public freezeProposalCreatedTime; // Timestsamp the freeze proposal was created at  
    uint256 public freezeProposalVoteCount; // Number of accrued freeze votes
    uint256 public freezeProposalPeriod; // Number of seconds a freeze proposal has to succeed
    uint256 public freezePeriod; // Number of seconds a freeze lasts, from time of freeze proposal creation
    IVotes public votesToken;
    IVetoGuard public vetoGuard;
    mapping(bytes32 => uint256) public transactionVetoVotes;
    mapping(address => mapping(bytes32 => bool)) public userHasVoted;
    mapping(address => mapping(uint256 => bool)) public userHasFreezeVoted;

    /// @notice Initialize function, will be triggered when a new proxy is deployed
    /// @param initializeParams Parameters of initialization encoded
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (
            address _owner,
            uint256 _vetoVotesThreshold,
            uint256 _freezeVotesThreshold,
            uint256 _freezeProposalPeriod,
            uint256 _freezePeriod,
            address _votesToken,
            address _vetoGuard
        ) = abi.decode(
                initializeParams,
                (address, uint256, uint256, uint256, uint256, address, address)
            );

        _transferOwnership(_owner);
        vetoVotesThreshold = _vetoVotesThreshold;
        freezeVotesThreshold = _freezeVotesThreshold;
        freezeProposalPeriod = _freezeProposalPeriod;
        freezePeriod = _freezePeriod;
        votesToken = IVotes(_votesToken);
        vetoGuard = IVetoGuard(_vetoGuard);
    }

    /// @notice Allows the msg.sender to cast veto and freeze votes on the specified transaction
    /// @param _transactionHash The hash of the transaction data
    /// @param _freeze Bool indicating whether the voter thinks the DAO should also be frozen
    function castVetoVote(bytes32 _transactionHash, bool _freeze) external {
        // Check that user has not yet voted
        require(
            !userHasVoted[msg.sender][_transactionHash],
            "User has already voted"
        );

        // Get the block number the transaction was queued on the VetoGuard
        uint256 queuedBlockNumber = vetoGuard.getTransactionQueuedBlock(
            _transactionHash
        );

        // Check that the transaction has been queued
        require(queuedBlockNumber != 0, "Transaction has not yet been queued");

        uint256 vetoVotes = votesToken.getPastVotes(
            msg.sender,
            queuedBlockNumber - 1
        );

        require(vetoVotes > 0, "User has no votes");

        // Add the user votes to the veto vote count for this transaction
        transactionVetoVotes[_transactionHash] += vetoVotes;

        // If the user is voting to freeze, count that vote as well
        if (_freeze) {
            castFreezeVote();
        }

        // User has voted
        userHasVoted[msg.sender][_transactionHash] = true;

        emit VetoVoteCast(msg.sender, _transactionHash, vetoVotes, _freeze);
    }

    /// @notice Allows user to cast a freeze vote, creating a freeze proposal if necessary
    function castFreezeVote() public {
        uint256 userVotes;

        if (
            block.timestamp >
            freezeProposalCreatedTime + freezeProposalPeriod
        ) {
            // Create freeze proposal, set total votes to msg.sender's vote count
            freezeProposalCreatedBlock = block.number;
            freezeProposalCreatedTime = block.timestamp;

            userVotes = votesToken.getPastVotes(
                msg.sender,
                freezeProposalCreatedBlock - 1
            );
            require(userVotes > 0, "User has no votes");

            freezeProposalVoteCount = userVotes;

            emit FreezeProposalCreated(msg.sender);
        } else {
            // There is an existing freeze proposal, count user's votes
            require(
                !userHasFreezeVoted[msg.sender][freezeProposalCreatedBlock],
                "User has already voted"
            );

            userVotes = votesToken.getPastVotes(
                msg.sender,
                freezeProposalCreatedBlock - 1
            );
            require(userVotes > 0, "User has no votes");

            freezeProposalVoteCount += userVotes;
        }

        userHasFreezeVoted[msg.sender][freezeProposalCreatedBlock] = true;

        emit FreezeVoteCast(msg.sender, userVotes);
    }

    /// @notice Unfreezes the DAO, only callable by the owner
    function defrost() public onlyOwner {
        freezeProposalCreatedBlock = 0;
        freezeProposalCreatedTime = 0;
        freezeProposalVoteCount = 0;
    }

    /// @notice Updates the veto votes threshold, only callable by the owner
    /// @param _vetoVotesThreshold The number of votes required to veto a transaction
    function updateVetoVotesThreshold(uint256 _vetoVotesThreshold)
        external
        onlyOwner
    {
        vetoVotesThreshold = _vetoVotesThreshold;
    }

    /// @notice Updates the freeze votes threshold, only callable by the owner
    /// @param _freezeVotesThreshold Number of freeze votes required to activate a freeze
    function updateFreezeVotesThreshold(uint256 _freezeVotesThreshold)
        external
        onlyOwner
    {
        freezeVotesThreshold = _freezeVotesThreshold;
    }

    /// @notice Updates the freeze proposal period, only callable by the owner
    /// @param _freezeProposalPeriod The number of seconds a freeze proposal has to succeed
    function updateFreezeProposalPeriod(
        uint256 _freezeProposalPeriod
    ) external onlyOwner {
        freezeProposalPeriod = _freezeProposalPeriod;
    }

    /// @notice Updates the freeze period, only callable by the owner
    /// @param _freezePeriod The number of seconds a freeze lasts, from time of freeze proposal creation
    function updateFreezePeriod(uint256 _freezePeriod)
        external
        onlyOwner
    {
        freezePeriod = _freezePeriod;
    }

    /// @notice Returns whether the specified transaction has been vetoed
    /// @param _transactionHash The hash of the transaction data
    /// @return bool True if the transaction is vetoed
    function getIsVetoed(bytes32 _transactionHash)
        external
        view
        returns (bool)
    {
        return transactionVetoVotes[_transactionHash] > vetoVotesThreshold;
    }

    /// @notice Returns true if the DAO is currently frozen, false otherwise
    /// @return bool Indicates whether the DAO is currently frozen
    function isFrozen() external view returns (bool) {
        if (
            freezeProposalVoteCount > freezeVotesThreshold &&
            block.timestamp < freezeProposalCreatedTime + freezePeriod
        ) {
            return true;
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IVetoGuard {
    event VetoGuardSetup(
        address creator,
        uint256 timelockPeriod,
        uint256 executionPeriod,
        address indexed owner,
        address indexed vetoVoting
    );

    event TransactionQueued(
        address indexed queuer,
        bytes32 indexed transactionHash,
        bytes indexed signatures
    );

    /// @notice Allows a user to queue the transaction, requires valid signatures
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function queueTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external;

    /// @notice Updates the timelock period in seconds, only callable by the owner
    /// @param _timelockPeriod The number of seconds between when a transaction is queued and can be executed
    function updateTimelockPeriod(uint256 _timelockPeriod)
        external;

    /// @notice Updates the execution period in seconds, only callable by the owner
    /// @param _executionPeriod The number of seconds a transaction has to be executed after timelock period has ended
    function updateExecutionPeriod(uint256 _executionPeriod)
        external;

    /// @notice Gets the block number that the transaction was queued at
    /// @param _transactionHash The hash of the transaction data
    /// @return uint256 The block number
    function getTransactionQueuedBlock(bytes32 _transactionHash)
        external
        view
        returns (uint256);

    /// @notice Gets the timestamp that the transaction was queued at
    /// @param _transactionHash The hash of the transaction data
    /// @return uint256 The timestamp the transaction was queued at
    function getTransactionQueuedTimestamp(bytes32 _transactionHash)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IVetoVoting {
    event VetoVoteCast(
        address indexed voter,
        bytes32 indexed transactionHash,
        uint256 votesCast,
        bool freeze
    );

    event FreezeVoteCast(address indexed voter, uint256 votesCast);

    event FreezeProposalCreated(address indexed creator);

    /// @notice Allows the msg.sender to cast veto and freeze votes on the specified transaction
    /// @param _transactionHash The hash of the transaction data
    /// @param _freeze Bool indicating whether the voter thinks the DAO should also be frozen
    function castVetoVote(bytes32 _transactionHash, bool _freeze) external;

    /// @notice Allows a user to cast a freeze vote if there is an active freeze proposal
    /// @notice If there isn't an active freeze proposal, it is created and the user's votes are cast
    function castFreezeVote() external;

    /// @notice Returns whether the specified transaction has been vetoed
    /// @param _transactionHash The hash of the transaction data
    /// @return bool True if the transaction is vetoed
    function getIsVetoed(bytes32 _transactionHash) external view returns (bool);

    /// @notice Returns true if the DAO is currently frozen, false otherwise
    /// @return bool Indicates whether the DAO is currently frozen
    function isFrozen() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

abstract contract TransactionHasher {
    /// @dev Returns the hash of all the transaction data
    /// @dev It is important to note that this implementation is different than that in the Gnosis Safe contract
    /// @dev This implementation does not use the nonce, as this is not part of the Guard contract checkTransaction interface
    /// @dev This implementation also omits the EIP-712 related values, since these hashes are not being signed by users
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @return Transaction hash bytes.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                to,
                value,
                keccak256(data),
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver
            )
        );
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

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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