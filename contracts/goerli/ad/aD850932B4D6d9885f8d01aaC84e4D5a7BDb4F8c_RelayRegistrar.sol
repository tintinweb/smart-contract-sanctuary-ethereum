// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The Forwarder Interface
 * @notice The contracts implementing this interface take a role of authorization, authentication and replay protection
 * for contracts that choose to trust a `Forwarder`, instead of relying on a mechanism built into the Ethereum protocol.
 *
 * @notice if the `Forwarder` contract decides that an incoming `ForwardRequest` is valid, it must append 20 bytes that
 * represent the caller to the `data` field of the request and send this new data to the target address (the `to` field)
 *
 * :warning: **Warning** :warning: The Forwarder can have a full control over a `Recipient` contract.
 * Any vulnerability in a `Forwarder` implementation can make all of its `Recipient` contracts susceptible!
 * Recipient contracts should only trust forwarders that passed through security audit,
 * otherwise they are susceptible to identity theft.
 */
interface IForwarder is IERC165 {

    /**
     * @notice A representation of a request for a `Forwarder` to send `data` on behalf of a `from` to a target (`to`).
     */
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntilTime;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    /**
     * @param from The address of a sender.
     * @return The nonce for this address.
     */
    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * @notice Verify the transaction is valid and can be executed.
     * Implementations must validate the signature and the nonce of the request are correct.
     * Does not revert and returns successfully if the input is valid.
     * Reverts if any validation has failed. For instance, if either signature or nonce are incorrect.
     * Reverts if `domainSeparator` or `requestTypeHash` are not registered as well.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * @notice Executes a transaction specified by the `ForwardRequest`.
     * The transaction is first verified and then executed.
     * The success flag and returned bytes array of the `CALL` are returned as-is.
     *
     * This method would revert only in case of a verification error.
     *
     * All the target errors are reported using the returned success flag and returned bytes array.
     *
     * @param forwardRequest All requested transaction parameters.
     * @param domainSeparator The domain used when signing this request.
     * @param requestTypeHash The request type used when signing this request.
     * @param suffixData The ABI-encoded extension data for the current `RequestType` used when signing this request.
     * @param signature The client signature to be validated.
     *
     * @return success The success flag of the underlying `CALL` to the target address.
     * @return ret The byte array returned by the underlying `CALL` to the target address.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * @notice Register a new Request typehash.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @param typeName The name of the request type.
     * @param typeSuffix Any extra data after the generic params. Must contain add at least one param.
     * The generic ForwardRequest type is always registered by the constructor.
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * @notice Register a new domain separator.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @notice The domain separator must have the following fields: `name`, `version`, `chainId`, `verifyingContract`.
     * The `chainId` is the current network's `chainId`, and the `verifyingContract` is this Forwarder's address.
     * This method accepts the domain name and version to create and register the domain separator value.
     * @param name The domain's display name.
     * @param version The domain/protocol version.
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

/**
 * @title The RelayHub interface
 * @notice The implementation of this interface provides all the information the GSN client needs to
 * create a valid `RelayRequest` and also serves as an entry point for such requests.
 *
 * @notice The RelayHub also handles all the related financial records and hold the balances of participants.
 * The Paymasters keep their Ether deposited in the `RelayHub` in order to pay for the `RelayRequest`s that thay choose
 * to pay for, and Relay Servers keep their earned Ether in the `RelayHub` until they choose to `withdraw()`
 *
 * @notice The RelayHub on each supported network only needs a single instance and there is usually no need for dApp
 * developers or Relay Server operators to redeploy, reimplement, modify or override the `RelayHub`.
 */
interface IRelayHub is IERC165 {
    /**
     * @notice A struct that contains all the parameters of the `RelayHub` that can be modified after the deployment.
     */
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Minimum unstake delay seconds of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Developers address
        address devAddress;
        // 0 < fee < 100, as percentage of total charge from paymaster to relayer
        uint8 devFee;
        // baseRelayFee The base fee the Relay Server charges for a single transaction in Ether, in wei.
        uint80 baseRelayFee;
        // pctRelayFee The percent of the total charge to add as a Relay Server fee to the total charge.
        uint16 pctRelayFee;
    }

    /// @notice Emitted when a configuration of the `RelayHub` is changed
    event RelayHubConfigured(RelayHubConfig config);

    /// @notice Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// @notice Emitted when an account withdraws funds from the `RelayHub`.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// @notice Emitted when `depositFor` is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// @notice Emitted for each token configured for staking in setMinimumStakes
    event StakingTokenDataChanged(
        address token,
        uint256 minimumStake
    );

    /**
     * @notice Emitted when an attempt to relay a call fails and the `Paymaster` does not accept the transaction.
     * The actual relayed call was not executed, and the recipient not charged.
     * @param reason contains a revert reason returned from preRelayedCall or forwarder.
     */
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /**
     * @notice Emitted when a transaction is relayed. Note that the actual internal function call might be reverted.
     * The reason for a revert will be indicated in the `status` field of a corresponding `RelayCallStatus` value.
     * @notice `charge` is the Ether value deducted from the `Paymaster` balance.
     * The amount added to the `relayManager` balance will be lower if there is an activated `devFee` in the `config`.
     */
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    /// @notice This event is emitted in case the internal function returns a value or reverts with a revert string.
    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    /// @notice This event is emitted in case this `RelayHub` is deprecated and will stop serving transactions soon.
    event HubDeprecated(uint256 deprecationTime);

    /**
     * @notice This event is emitted in case a `relayManager` has been deemed "abandoned" for being
     * unresponsive for a prolonged period of time.
     * @notice This event means the entire balance of the relay has been transferred to the `devAddress`.
     */
    event AbandonedRelayManagerBalanceEscheated(
        address indexed relayManager,
        uint256 balance
    );

    /**
     * Error codes that describe all possible failure reasons reported in the `TransactionRelayed` event `status` field.
     *  @param OK The transaction was successfully relayed and execution successful - never included in the event.
     *  @param RelayedCallFailed The transaction was relayed, but the relayed call failed.
     *  @param RejectedByPreRelayed The transaction was not relayed due to preRelatedCall reverting.
     *  @param RejectedByForwarder The transaction was not relayed due to forwarder check (signature,nonce).
     *  @param PostRelayedFailed The transaction was relayed and reverted due to postRelatedCall reverting.
     *  @param PaymasterBalanceChanged The transaction was relayed and reverted due to the paymaster balance change.
     */
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /**
     * @notice Add new worker addresses controlled by the sender who must be a staked Relay Manager address.
     * Emits a `RelayWorkersAdded` event.
     * This function can be called multiple times, emitting new events.
     */
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    /**
     * @notice The `RelayRegistrar` callback to notify the `RelayHub` that this `relayManager` has updated registration.
     */
    function onRelayServerRegistered(address relayManager) external;

    // Balance management

    /**
     * @notice Deposits ether for a `Paymaster`, so that it can and pay for relayed transactions.
     * :warning: **Warning** :warning: Unused balance can only be withdrawn by the holder itself, by calling `withdraw`.
     * Emits a `Deposited` event.
     */
    function depositFor(address target) external payable;

    /**
     * @notice Withdraws from an account's balance, sending it back to the caller.
     * Relay Managers call this to retrieve their revenue, and `Paymasters` can also use it to reduce their funding.
     * Emits a `Withdrawn` event.
     */
    function withdraw(address payable dest, uint256 amount) external;

    /**
     * @notice Withdraws from an account's balance, sending funds to multiple provided addresses.
     * Relay Managers call this to retrieve their revenue, and `Paymasters` can also use it to reduce their funding.
     * Emits a `Withdrawn` event for each destination.
     */
    function withdrawMultiple(address payable[] memory dest, uint256[] memory amount) external;

    // Relaying

    /**
     * @notice Relays a transaction. For this to succeed, multiple conditions must be met:
     *  - `Paymaster`'s `preRelayCall` method must succeed and not revert.
     *  - the `msg.sender` must be a registered Relay Worker that the user signed to use.
     *  - the transaction's gas fees must be equal or larger than the ones that were signed by the sender.
     *  - the transaction must have enough gas to run all internal transactions if they use all gas available to them.
     *  - the `Paymaster` must have enough balance to pay the Relay Worker if all gas is spent.
     *
     * @notice If all conditions are met, the call will be relayed and the `Paymaster` charged.
     *
     * @param domainSeparatorName The name of the Domain Separator used to verify the EIP-712 signature
     * @param maxAcceptanceBudget The maximum valid value for `paymaster.getGasLimits().acceptanceBudget` to return.
     * @param relayRequest All details of the requested relayed call.
     * @param signature The client's EIP-712 signature over the `relayRequest` struct.
     * @param approvalData The dapp-specific data forwarded to the `Paymaster`'s `preRelayedCall` method.
     * This value is **not** verified by the `RelayHub` in any way.
     * As an example, it can be used to pass some kind of a third-party signature to the `Paymaster` for verification.
     *
     * Emits a `TransactionRelayed` event regardless of whether the transaction succeeded or failed.
     */
    function relayCall(
        string calldata domainSeparatorName,
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    returns (
        bool paymasterAccepted,
        uint256 charge,
        IRelayHub.RelayCallStatus status,
        bytes memory returnValue
    );

    /**
     * @notice In case the Relay Worker has been found to be in violation of some rules by the `Penalizer` contract,
     * the `Penalizer` will call this method to execute a penalization.
     * The `RelayHub` will look up the Relay Manager of the given Relay Worker and will forward the call to
     * the `StakeManager` contract. The `RelayHub` does not perform the actual penalization either.
     * @param relayWorker The address of the Relay Worker that committed a penalizable offense.
     * @param beneficiary The address that called the `Penalizer` and will receive a reward for it.
     */
    function penalize(address relayWorker, address payable beneficiary) external;

    /**
     * @notice Sets or changes the configuration of this `RelayHub`.
     * @param _config The new configuration.
     */
    function setConfiguration(RelayHubConfig memory _config) external;

    /**
     * @notice Sets or changes the minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     * @param token An array of addresses of ERC-20 compatible tokens.
     * @param minimumStake An array of minimal amounts necessary for a corresponding token, in wei.
     */
    function setMinimumStakes(IERC20[] memory token, uint256[] memory minimumStake) external;

    /**
     * @notice Deprecate hub by reverting all incoming `relayCall()` calls starting from a given timestamp
     * @param _deprecationTime The timestamp in seconds after which the `RelayHub` stops serving transactions.
     */
    function deprecateHub(uint256 _deprecationTime) external;

    /**
     * @notice
     * @param relayManager
     */
    function escheatAbandonedRelayBalance(address relayManager) external;

    /**
     * @notice The fee is expressed as a base fee in wei plus percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the recipient will be charged for 1.4 times the spent amount.
     * @param gasUsed An amount of gas used by the transaction.
     * @param relayData The details of a transaction signed by the sender.
     * @return The calculated charge, in wei.
     */
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /**
     * @notice The fee is expressed as a  percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the Relay Manager will only get 60% of the `charge`.
     * @param charge The amount of Ether in wei the Paymaster will be charged for this transaction.
     * @return The calculated devFee, in wei.
     */
    function calculateDevCharge(uint256 charge) external view returns (uint256);
    /* getters */

    /// @return config The configuration of the `RelayHub`.
    function getConfiguration() external view returns (RelayHubConfig memory config);

    /**
     * @param token An address of an ERC-20 compatible tokens.
     * @return The minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     */
    function getMinimumStakePerToken(IERC20 token) external view returns (uint256);

    /**
     * @param worker An address of the Relay Worker.
     * @return The address of its Relay Manager.
     */
    function getWorkerManager(address worker) external view returns (address);

    /**
     * @param manager An address of the Relay Manager.
     * @return The count of Relay Workers associated with this Relay Manager.
     */
    function getWorkerCount(address manager) external view returns (uint256);

    /// @return An account's balance. It can be either a deposit of a `Paymaster`, or a revenue of a Relay Manager.
    function balanceOf(address target) external view returns (uint256);

    /// @return The `StakeManager` address for this `RelayHub`.
    function getStakeManager() external view returns (IStakeManager);

    /// @return The `Penalizer` address for this `RelayHub`.
    function getPenalizer() external view returns (address);

    /// @return The `RelayRegistrar` address for this `RelayHub`.
    function getRelayRegistrar() external view returns (address);

    /// @return The `BatchGateway` address for this `RelayHub`.
    function getBatchGateway() external view returns (address);

    /**
     * @notice Uses `StakeManager` to decide if the Relay Manager can be considered staked or not.
     * Returns if the stake's token, amount and delay satisfy all requirements, reverts otherwise.
     */
    function verifyRelayManagerStaked(address relayManager) external view;

    /**
     * @notice Uses `StakeManager` to check if the Relay Manager can be considered abandoned or not.
     * Returns true if the stake's abandonment time is in the past including the escheatment delay, false otherwise.
     */
    function isRelayEscheatable(address relayManager) external view returns (bool);

    /// @return `true` if the `RelayHub` is deprecated, `false` it it is not deprecated and can serve transactions.
    function isDeprecated() external view returns (bool);

    /// @return The timestamp from which the hub no longer allows relaying calls.
    function getDeprecationTime() external view returns (uint256);

    /// @return The block number in which the contract has been deployed.
    function getCreationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the `RelayHub` contract.
    function versionHub() external view returns (string memory);

    /// @return A total measurable amount of gas left to current execution. Same as 'gasleft()' for pure EVMs.
    function aggregateGasleft() external view returns (uint256);
}

pragma solidity ^0.8.6;

//SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The RelayRegistrar Interface
 * @notice The on-chain registrar for all registered Relay Managers.
 *
 * @notice The client can use an implementation of a `RelayRegistrar` to find relay registration info.
 *
 */
interface IRelayRegistrar is IERC165 {

    /**
     * @notice A struct containing all the information necessary to client to interact with the Relay Server.
     */
    struct RelayInfo {
        //last registration block number
        uint32 lastSeenBlockNumber;
        //last registration block timestamp
        uint40 lastSeenTimestamp;
        //stake (first registration) block number
        uint32 firstSeenBlockNumber;
        //stake (first registration) block timestamp
        uint40 firstSeenTimestamp;
        bytes32[3] urlParts;
        address relayManager;
    }

    /**
     * @notice Emitted when a relay server registers or updates its details.
     * Looking up these events allows a client to discover registered Relay Servers.
     */
    event RelayServerRegistered(
        address indexed relayManager,
        address indexed relayHub,
        bytes32[3] relayUrl
    );

    /**
     * @notice This function is called by Relay Servers in order to register or to update their registration.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @param url The URL of the Relay Server that is listening to the clients' requests.
     */
    function registerRelayServer(
        address relayHub,
        bytes32[3] calldata url
    ) external;

    /**
     * @return The block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @return The maximum age the relay is considered registered by default by this `RelayRegistrar`, in seconds.
     */
    function getRelayRegistrationMaxAge() external view returns (uint256);

    /**
     * @notice Change the maximum relay registration age.
     */
    function setRelayRegistrationMaxAge(uint256) external;

    /**
     * @param relayManager An address of a Relay Manager.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @return info All the details of the given Relay Manager's registration. Throws if relay not found for `RelayHub`.
     */
    function getRelayInfo(address relayHub, address relayManager) external view returns (RelayInfo memory info);

    /**
     * @notice Read relay info of registered Relay Server from an on-chain storage.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @return info The list of `RelayInfo`s of registered Relay Servers
     */
    function readRelayInfos(
        address relayHub
    ) external view returns (
        RelayInfo[] memory info
    );

    /**
     * @notice Read relay info of registered Relay Server from an on-chain storage.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @param maxCount The maximum amount of relays to be returned by this function.
     * @param oldestBlockNumber The latest block number in which a Relay Server may be registered.
     * @param oldestBlockTimestamp The latest block timestamp in which a Relay Server may be registered.
     * @return info The list of `RelayInfo`s of registered Relay Servers
     */
    function readRelayInfosInRange(
        address relayHub,
        uint256 oldestBlockNumber,
        uint256 oldestBlockTimestamp,
        uint256 maxCount
    ) external view returns (
        RelayInfo[] memory info
    );
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title The StakeManager Interface
 * @notice In order to prevent an attacker from registering a large number of unresponsive relays, the GSN requires
 * the Relay Server to maintain a permanently locked stake in the system before being able to register.
 *
 * @notice Also, in some cases the behavior of a Relay Server may be found to be illegal by a `Penalizer` contract.
 * In such case, the stake will never be returned to the Relay Server operator and will be slashed.
 *
 * @notice An implementation of this interface is tasked with keeping Relay Servers' stakes, made in any ERC-20 token.
 * Note that the `RelayHub` chooses which ERC-20 tokens to support and how much stake is needed.
 */
interface IStakeManager is IERC165 {

    /// @notice Emitted when a `stake` or `unstakeDelay` are initialized or increased.
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// @notice Emitted once a stake is scheduled for withdrawal.
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawTime
    );

    /// @notice Emitted when owner withdraws `relayManager` funds.
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 amount
    );

    /// @notice Emitted when an authorized `RelayHub` penalizes a `relayManager`.
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        IERC20 token,
        uint256 reward
    );

    /// @notice Emitted when a `relayManager` adds a new `RelayHub` to a list of authorized.
    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    /// @notice Emitted when a `relayManager` removes a `RelayHub` from a list of authorized.
    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalTime
    );

    /// @notice Emitted when a `relayManager` sets its `owner`. This is necessary to prevent stake hijacking.
    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @notice Emitted when a `burnAddress` is changed.
    event BurnAddressSet(
        address indexed burnAddress
    );

    /// @notice Emitted when a `devAddress` is changed.
    event DevAddressSet(
        address indexed devAddress
    );

    /// @notice Emitted if Relay Server is inactive for an `abandonmentDelay` and contract owner initiates its removal.
    event RelayServerAbandoned(
        address indexed relayManager,
        uint256 abandonedTime
    );

    /// @notice Emitted to indicate an action performed by a relay server to prevent it from being marked as abandoned.
    event RelayServerKeepalive(
        address indexed relayManager,
        uint256 keepaliveTime
    );

    /// @notice Emitted when the stake of an abandoned relayer has been confiscated and transferred to the `devAddress`.
    event AbandonedRelayManagerStakeEscheated(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 amount
    );

    /**
     * @param stake - amount of ether staked for this relay
     * @param unstakeDelay - number of seconds to elapse before the owner can retrieve the stake after calling 'unlock'
     * @param withdrawTime - timestamp in seconds when 'withdraw' will be callable, or zero if the unlock has not been called
     * @param owner - address that receives revenue and manages relayManager's stake
     */
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawTime;
        uint256 abandonedTime;
        uint256 keepaliveTime;
        IERC20 token;
        address owner;
    }

    struct RelayHubInfo {
        uint256 removalTime;
    }

    /**
     * @param devAddress - the address that will receive the 'abandoned' stake
     * @param abandonmentDelay - the amount of time after which the relay can be marked as 'abandoned'
     * @param escheatmentDelay - the amount of time after which the abandoned relay's stake and balance may be withdrawn to the `devAddress`
     */
    struct AbandonedRelayServerConfig {
        address devAddress;
        uint256 abandonmentDelay;
        uint256 escheatmentDelay;
    }

    /**
     * @notice Set the owner of a Relay Manager. Called only by the RelayManager itself.
     * Note that owners cannot transfer ownership - if the entry already exists, reverts.
     * @param owner - owner of the relay (as configured off-chain)
     */
    function setRelayManagerOwner(address owner) external;

    /**
     * @notice Put a stake for a relayManager and set its unstake delay.
     * Only the owner can call this function. If the entry does not exist, reverts.
     * The owner must give allowance of the ERC-20 token to the StakeManager before calling this method.
     * It is the RelayHub who has a configurable list of minimum stakes per token. StakeManager accepts all tokens.
     * @param token The address of an ERC-20 token that is used by the relayManager as a stake
     * @param relayManager The address that represents a stake entry and controls relay registrations on relay hubs
     * @param unstakeDelay The number of seconds to elapse before an owner can retrieve the stake after calling `unlock`
     * @param amount The amount of tokens to be taken from the relayOwner and locked in the StakeManager as a stake
     */
    function stakeForRelayManager(IERC20 token, address relayManager, uint256 unstakeDelay, uint256 amount) external;

    /**
     * @notice Schedule the unlocking of the stake. The `unstakeDelay` must pass before owner can call `withdrawStake`.
     * @param relayManager The address of a Relay Manager whose stake is to be unlocked.
     */
    function unlockStake(address relayManager) external;
    /**
     * @notice Withdraw the unlocked stake.
     * @param relayManager The address of a Relay Manager whose stake is to be withdrawn.
     */
    function withdrawStake(address relayManager) external;

    /**
     * @notice Add the `RelayHub` to a list of authorized by this Relay Manager.
     * This allows the RelayHub to penalize this Relay Manager. The `RelayHub` cannot trust a Relay it cannot penalize.
     * @param relayManager The address of a Relay Manager whose stake is to be authorized for the new `RelayHub`.
     * @param relayHub The address of a `RelayHub` to be authorized.
     */
    function authorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `authorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function authorizeHubByManager(address relayHub) external;

    /**
     * @notice Remove the `RelayHub` from a list of authorized by this Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @param relayHub The address of a `RelayHub` to be unauthorized.
     */
    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `unauthorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function unauthorizeHubByManager(address relayHub) external;

    /**
     * Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns part of stake on the way.
     * @param relayManager The address of a Relay Manager to be penalized.
     * @param beneficiary The address that receives part of the penalty amount.
     * @param amount A total amount of penalty to be withdrawn from stake.
     */
    function penalizeRelayManager(address relayManager, address beneficiary, uint256 amount) external;

    /**
     * @notice Allows the contract owner to set the given `relayManager` as abandoned after a configurable delay.
     * Its entire stake and balance will be taken from a relay if it does not respond to being marked as abandoned.
     */
    function markRelayAbandoned(address relayManager) external;

    /**
     * @notice If more than `abandonmentDelay` has passed since the last Keepalive transaction, and relay manager
     * has been marked as abandoned, and after that more that `escheatmentDelay` have passed, entire stake and
     * balance will be taken from this relay.
     */
    function escheatAbandonedRelayStake(address relayManager) external;

    /**
     * @notice Sets a new `keepaliveTime` for the given `relayManager`, preventing it from being marked as abandoned.
     * Can be called by an authorized `RelayHub` or by the `relayOwner` address.
     */
    function updateRelayKeepaliveTime(address relayManager) external;

    /**
     * @notice Check if the Relay Manager can be considered abandoned or not.
     * Returns true if the stake's abandonment time is in the past including the escheatment delay, false otherwise.
     */
    function isRelayEscheatable(address relayManager) external view returns(bool);

    /**
     * @notice Get the stake details information for the given Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @return stakeInfo The `StakeInfo` structure.
     * @return isSenderAuthorizedHub `true` if the `msg.sender` for this call was a `RelayHub` that is authorized now.
     * `false` if the `msg.sender` for this call is not authorized.
     */
    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo, bool isSenderAuthorizedHub);

    /**
     * @return The maximum unstake delay this `StakeManger` allows. This is to prevent locking money forever by mistake.
     */
    function getMaxUnstakeDelay() external view returns (uint256);

    /**
     * @notice Change the address that will receive the 'burned' part of the penalized stake.
     * This is done to prevent malicious Relay Server from penalizing itself and breaking even.
     */
    function setBurnAddress(address _burnAddress) external;

    /**
     * @return The address that will receive the 'burned' part of the penalized stake.
     */
    function getBurnAddress() external view returns (address);

    /**
     * @notice Change the address that will receive the 'abandoned' stake.
     * This is done to prevent Relay Servers that lost their keys from losing access to funds.
     */
    function setDevAddress(address _burnAddress) external;

    /**
     * @return The structure that contains all configuration values for the 'abandoned' stake.
     */
    function getAbandonedRelayServerConfig() external view returns (AbandonedRelayServerConfig memory);

    /**
     * @return the block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @return a SemVer-compliant version of the `StakeManager` contract.
     */
    function versionSM() external view returns (string memory);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice maxFeePerGas, maxPriorityFeePerGas, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 transactionCalldataGasUsed;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// minimal bytes manipulation required by GSN
// a minimal subset from 0x/LibBytes
/* solhint-disable no-inline-assembly */

library MinLibBytes {

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data, uint256 maxlen) internal pure {
        if (data.length > maxlen) {
            assembly { mstore(data, maxlen) }
        }
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require (b.length >= index + 20, "readAddress: data too short");

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index + 32, "readBytes32: data too short" );

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
        }
        return result;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "readBytes4: data too short");

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

pragma solidity ^0.8.6;

// solhint-disable not-rely-on-time
//SPDX-License-Identifier: GPL-3.0-only

/* solhint-disable no-inline-assembly */

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./MinLibBytes.sol";
import "../interfaces/IRelayHub.sol";
import "../interfaces/IRelayRegistrar.sol";

/**
 * @title The RelayRegistrar Implementation
 * @notice Keeps a list of registered relayers.
 *
 * @notice Provides view functions to read the list of registered relayers and filters out invalid ones.
 *
 * @notice Protects the list from spamming entries: only staked relayers are added.
 */
contract RelayRegistrar is IRelayRegistrar, Ownable, ERC165 {
    using MinLibBytes for bytes;

    uint256 private constant MAX_RELAYS_RETURNED_COUNT = 1000;

    /// @notice Mapping from `RelayHub` address to a mapping from a Relay Manager address to its registration details.
    mapping(address => mapping(address => RelayInfo)) internal values;

    /// @notice Mapping from `RelayHub` address to an array of Relay Managers that are registered on that `RelayHub`.
    mapping(address => address[]) internal indexedValues;

    uint256 private immutable creationBlock;

    uint256 private relayRegistrationMaxAge;

    constructor(uint256 _relayRegistrationMaxAge) {
        setRelayRegistrationMaxAge(_relayRegistrationMaxAge);
        creationBlock = block.number;
    }

    /// @inheritdoc IRelayRegistrar
    function getCreationBlock() external override view returns (uint256){
        return creationBlock;
    }

    /// @inheritdoc IRelayRegistrar
    function getRelayRegistrationMaxAge() external override view returns (uint256){
        return relayRegistrationMaxAge;
    }

    /// @inheritdoc IRelayRegistrar
    function setRelayRegistrationMaxAge(uint256 _relayRegistrationMaxAge) public override onlyOwner {
        relayRegistrationMaxAge = _relayRegistrationMaxAge;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IRelayRegistrar).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRelayRegistrar
    function registerRelayServer(
        address relayHub,
        bytes32[3] calldata url
    ) external override {
        address relayManager = msg.sender;
        IRelayHub(relayHub).onRelayServerRegistered(relayManager);
        emit RelayServerRegistered(relayManager, relayHub, url);
        storeRelayServerRegistration(relayManager, relayHub, url);
    }

    function addItem(address relayHub, address relayManager) internal returns (RelayInfo storage) {
        RelayInfo storage storageInfo = values[relayHub][relayManager];
        if (storageInfo.lastSeenBlockNumber == 0) {
            indexedValues[relayHub].push(relayManager);
        }
        return storageInfo;
    }

    function storeRelayServerRegistration(
        address relayManager,
        address relayHub,
        bytes32[3] calldata url
    ) internal {
        RelayInfo storage storageInfo = addItem(relayHub, relayManager);
        if (storageInfo.firstSeenBlockNumber == 0) {
            storageInfo.firstSeenBlockNumber = uint32(block.number);
            storageInfo.firstSeenTimestamp = uint40(block.timestamp);
        }
        storageInfo.lastSeenBlockNumber = uint32(block.number);
        storageInfo.lastSeenTimestamp = uint40(block.timestamp);
        storageInfo.relayManager = relayManager;
        storageInfo.urlParts = url;
    }

    /// @inheritdoc IRelayRegistrar
    function getRelayInfo(address relayHub, address relayManager) public view override returns (RelayInfo memory) {
        RelayInfo memory info = values[relayHub][relayManager];
        require(info.lastSeenBlockNumber != 0, "relayManager not found");
        return info;
    }

    /// @inheritdoc IRelayRegistrar
    function readRelayInfos(
        address relayHub
    )
    public
    view
    override
    returns (
        RelayInfo[] memory info
    ) {
        uint256 blockTimestamp = block.timestamp;
        uint256 oldestBlockTimestamp = blockTimestamp >= relayRegistrationMaxAge ? blockTimestamp - relayRegistrationMaxAge : 0;
        return readRelayInfosInRange(relayHub, 0, oldestBlockTimestamp, MAX_RELAYS_RETURNED_COUNT);
    }

    /// @inheritdoc IRelayRegistrar
    function readRelayInfosInRange(
        address relayHub,
        uint256 oldestBlockNumber,
        uint256 oldestBlockTimestamp,
        uint256 maxCount
    )
    public
    view
    override
    returns (
        RelayInfo[] memory info
    ) {
        address[] storage items = indexedValues[relayHub];
        uint256 filled = 0;
        info = new RelayInfo[](items.length < maxCount ? items.length : maxCount);
        for (uint256 i = 0; i < items.length; i++) {
            address relayManager = items[i];
            RelayInfo memory relayInfo = getRelayInfo(relayHub, relayManager);
            if (
                relayInfo.lastSeenBlockNumber < oldestBlockNumber ||
                relayInfo.lastSeenTimestamp < oldestBlockTimestamp
            ) {
                continue;
            }
            // solhint-disable-next-line no-empty-blocks
            try IRelayHub(relayHub).verifyRelayManagerStaked(relayManager) {
            } catch (bytes memory /*lowLevelData*/) {
                continue;
            }
            info[filled++] = relayInfo;
            if (filled >= maxCount)
                break;
        }
        assembly { mstore(info, filled) }
    }
}