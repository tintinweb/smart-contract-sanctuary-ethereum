// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event StakingToken(
        address token,
        uint minimumStake
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

    function verifyCanRegister(address relayManager) external;

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
    function withdraw(uint256 amount, address payable dest) external;

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
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

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
 * @notice Clients can use either events or on-chain querying mechanism depending on which one is more accessible.
 * The on-chain querying may be switched off and can be checked by a call to `isUsingStorageRegistry()` function.
 */
interface IRelayRegistrar is IERC165 {

    /**
     * @notice A struct containing all the information necessary to client to interact with the Relay Server.
     */
    struct RelayInfo {
        //last registration block number
        uint256 lastBlockNumber;
        //stake (first registration) block number
        uint256 stakeBlockNumber;
        address relayManager;
        uint256 baseRelayFee;
        uint256 pctRelayFee;
        string url;
    }

    /**
     * @notice Emitted when a relay server registers or updates its details.
     * Looking up these events allows a client to discover registered Relay Servers.
     */
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        string relayUrl
    );

    /**
     * @notice This function is called by Relay Servers in order to register or to update their registration.
     * @param baseRelayFee The base fee the Relay Server charges for a single transaction in Ether, in wei.
     * @param pctRelayFee The percent of the total charge to add as a Relay Server fee to the total charge.
     * @param url The URL of the Relay Server that is listening to the clients' requests.
     */
    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external;

    /**
     * @return The block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @return `true` if this `RelayRegistrar` keeps registrations on-chain in storage in addition to emitting events.
     * `false` if only events are emitted as part of Relay Server registration on this `RelayRegistrar`.
     */
    function isUsingStorageRegistry() external returns (bool);

    /**
     * @param relayManager An address of a Relay Manager.
     * @return info All the details of the given Relay Manager's registration.
     */
    function getRelayInfo(address relayManager) external view returns (RelayInfo memory info);

    /**
     * @notice Read relay info of registered Relay Server from an on-chain storage.
     * @param maxCount The maximum amount of relays to be returned by this function.
     * @param oldestBlock The latest block number in which a Relay Server may be registered in order to be returned.
     * @return info The list of `RelayInfo`s or registered Relay Servers
     * @return filled The number of entries filled in info. Entries in returned array that are not filled will be empty.
     */
    function readRelayInfos(uint256 oldestBlock, uint256 maxCount) external view returns (RelayInfo[] memory info, uint256 filled);
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
interface IStakeManager {

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
        IERC20 token;
        address owner;
    }

    struct RelayHubInfo {
        uint256 removalTime;
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
        uint256 pctRelayFee;
        uint256 baseRelayFee;
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

//SPDX-License-Identifier: GPL-3.0-only

/* solhint-disable no-inline-assembly */

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./MinLibBytes.sol";
import "../interfaces/IRelayHub.sol";
import "../interfaces/IRelayRegistrar.sol";

/**
 * on-chain relayer registrar.
 * - keep a list of registered relayers (using registerRelayer).
 * - provide view functions to read the list of registered relayers (and filter out invalid ones)
 * - protect the list from spamming entries: only staked relayers are added.
 */
contract RelayRegistrar is IRelayRegistrar, ERC165 {
    using MinLibBytes for bytes;

    struct RelayStorageInfo {
        uint32 lastBlockNumber;
        uint32 stakeBlockNumber;
        uint96 baseRelayFee;
        uint96 pctRelayFee;
        bytes32[3] urlParts;
    }

    mapping(address => RelayStorageInfo) public values;
    address[] public indexedValues;

    bool public immutable override isUsingStorageRegistry;
    uint256 private immutable creationBlock;

    IRelayHub public immutable relayHub;

    constructor(IRelayHub _relayHub, bool _isUsingStorageRegistry) {
        creationBlock = block.number;
        relayHub = _relayHub;
        isUsingStorageRegistry = _isUsingStorageRegistry;
    }

    function getCreationBlock() external override view returns (uint256){
        return creationBlock;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IRelayRegistrar).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRelayRegistrar
    function registerRelayServer(uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) external override {
        address relayManager = msg.sender;
        if (address(relayHub) != address(0)) {
            relayHub.verifyCanRegister(relayManager);
        }
        emit RelayServerRegistered(relayManager, baseRelayFee, pctRelayFee, url);
        if (isUsingStorageRegistry) {
            storeRelayServerRegistration(relayManager, baseRelayFee, pctRelayFee, url);
        }
    }

    function addItem(address relayManager) internal returns (RelayStorageInfo storage) {
        RelayStorageInfo storage storageInfo = values[relayManager];
        if (storageInfo.lastBlockNumber == 0) {
            indexedValues.push(relayManager);
        }
        return storageInfo;
    }

    function storeRelayServerRegistration(address relayManager, uint256 baseRelayFee, uint256 pctRelayFee, string calldata url) internal {
        RelayStorageInfo storage storageInfo = addItem(relayManager);
        if (storageInfo.stakeBlockNumber==0) {
            storageInfo.stakeBlockNumber = uint32(block.number);
        }
        storageInfo.lastBlockNumber = uint32(block.number);
        storageInfo.baseRelayFee = uint96(baseRelayFee);
        storageInfo.pctRelayFee = uint96(pctRelayFee);
        bytes32[3] memory parts = splitString(url);
        storageInfo.urlParts = parts;
    }

    /// @inheritdoc IRelayRegistrar
    function getRelayInfo(address relayManager) public view override returns (RelayInfo memory) {
        RelayInfo memory info;
        RelayStorageInfo storage storageInfo = values[relayManager];
        require(storageInfo.lastBlockNumber != 0, "relayManager not found");
        info.lastBlockNumber = storageInfo.lastBlockNumber;
        info.stakeBlockNumber = storageInfo.stakeBlockNumber;
        info.baseRelayFee = storageInfo.baseRelayFee;
        info.pctRelayFee = storageInfo.pctRelayFee;
        info.relayManager = relayManager;
        info.url = packString(storageInfo.urlParts);
        return info;
    }

    /// @inheritdoc IRelayRegistrar
    function readRelayInfos(uint256 oldestBlock, uint256 maxCount) public view override returns (RelayInfo[] memory info, uint256 filled) {
        address[] storage items = indexedValues;
        filled = 0;
        info = new RelayInfo[](items.length < maxCount ? items.length : maxCount);
        for (uint256 i = 0; i < items.length; i++) {
            address relayManager = items[i];
            RelayInfo memory relayInfo = getRelayInfo(relayManager);
            if (relayInfo.lastBlockNumber < oldestBlock) {
                continue;
            }
            if (address(relayHub) != address(0)) {
                // solhint-disable-next-line no-empty-blocks
                try IRelayHub(relayHub).verifyRelayManagerStaked(relayManager) {
                } catch (bytes memory /*lowLevelData*/) {
                    continue;
                }
            }
            info[filled++] = relayInfo;
            if (filled >= maxCount)
                break;
        }
    }

    /**
     * @notice Splits the variable size string array into static size bytes array. See `packString` for reverse.
     * @param str The string to be split.
     * @return The same string split into parts.
     */
    function splitString(string calldata str) public pure returns (bytes32[3] memory) {
        bytes32[3] memory parts;
        bytes calldata url = bytes(str);
        require(url.length <= 96, "url too long");
        parts[0] = bytes32(url[0 :]);
        if (url.length > 32) {
            parts[1] = bytes32(url[32 :]);
            if (url.length > 64) {
                parts[2] = bytes32(url[64 :]);
            } else {
                parts[2] = 0;
            }
        } else {
            parts[1] = 0;
            parts[2] = 0;
        }
        return parts;
    }

    /**
     * @notice Packs a string back after being split in `splitString`.
     * @param parts The string split into parts.
     * @return str The same string joined back together.
     */
    function packString(bytes32[3] memory parts) public pure returns (string memory str) {
        bytes memory ret = bytes.concat(parts[0], parts[1], parts[2]);
        //trim trailing zeros
        uint256 len = ret.length - 1;
        while (len > 0 && ret[len] == 0) len--;
        assembly {
            mstore(ret, add(len, 1))
        }
        str = string(ret);
    }
}