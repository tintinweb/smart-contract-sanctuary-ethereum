// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @notice Simple interface to retrieve the version of pools deployed by a pool factory.
 */
interface IFactoryCreatedPoolVersion {
    /**
     * @dev Returns a JSON representation of the deployed pool version containing name, version number and task ID.
     *
     * This is typically only useful in complex Pool deployment schemes, where multiple subsystems need to know about
     * each other. Note that this value will only be updated at factory creation time.
     */
    function getPoolVersion() external view returns (string memory);
}



/**
 * @dev Source of truth for all Protocol Fee percentages, that is, how much the protocol charges certain actions. Some
 * of these values may also be retrievable from other places (such as the swap fee percentage), but this is the
 * preferred source nonetheless.
 */
interface IProtocolFeePercentagesProvider {
    // All fee percentages are 18-decimal fixed point numbers, so e.g. 1e18 = 100% and 1e16 = 1%.

    // Emitted when a new fee type is registered.
    event ProtocolFeeTypeRegistered(uint256 indexed feeType, string name, uint256 maximumPercentage);

    // Emitted when the value of a fee type changes.
    // IMPORTANT: it is possible for a third party to modify the SWAP and FLASH_LOAN fee type values directly in the
    // ProtocolFeesCollector, which will result in this event not being emitted despite their value changing. Such usage
    // of the ProtocolFeesCollector is however discouraged: all state-changing interactions with it should originate in
    // this contract.
    event ProtocolFeePercentageChanged(uint256 indexed feeType, uint256 percentage);

    /**
     * @dev Registers a new fee type in the system, making it queryable via `getFeeTypePercentage` and `getFeeTypeName`,
     * as well as configurable via `setFeeTypePercentage`.
     *
     * `feeType` can be any arbitrary value (that is not in use).
     *
     * It is not possible to de-register fee types, nor change their name or maximum value.
     */
    function registerFeeType(
        uint256 feeType,
        string memory name,
        uint256 maximumValue,
        uint256 initialValue
    ) external;

    /**
     * @dev Returns true if `feeType` has been registered and can be queried.
     */
    function isValidFeeType(uint256 feeType) external view returns (bool);

    /**
     * @dev Returns true if `value` is a valid percentage value for `feeType`.
     */
    function isValidFeeTypePercentage(uint256 feeType, uint256 value) external view returns (bool);

    /**
     * @dev Sets the percentage value for `feeType` to `newValue`.
     *
     * IMPORTANT: it is possible for a third party to modify the SWAP and FLASH_LOAN fee type values directly in the
     * ProtocolFeesCollector, without invoking this function. This will result in the `ProtocolFeePercentageChanged`
     * event not being emitted despite their value changing. Such usage of the ProtocolFeesCollector is however
     * discouraged: only this contract should be granted permission to call `setSwapFeePercentage` and
     * `setFlashLoanFeePercentage`.
     */
    function setFeeTypePercentage(uint256 feeType, uint256 newValue) external;

    /**
     * @dev Returns the current percentage value for `feeType`. This is the preferred mechanism for querying these -
     * whenever possible, use this fucntion instead of e.g. querying the ProtocolFeesCollector.
     */
    function getFeeTypePercentage(uint256 feeType) external view returns (uint256);

    /**
     * @dev Returns `feeType`'s maximum value.
     */
    function getFeeTypeMaximumPercentage(uint256 feeType) external view returns (uint256);

    /**
     * @dev Returns `feeType`'s name.
     */
    function getFeeTypeName(uint256 feeType) external view returns (string memory);
}

library ProtocolFeeType {
    // This list is not exhaustive - more fee types can be added to the system. It is expected for this list to be
    // extended with new fee types as they are registered, to keep them all in one place and reduce
    // likelihood of user error.

    // solhint-disable private-vars-leading-underscore
    uint256 internal constant SWAP = 0;
    uint256 internal constant FLASH_LOAN = 1;
    uint256 internal constant YIELD = 2;
    uint256 internal constant AUM = 3;
    // solhint-enable private-vars-leading-underscore
}





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



interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}



/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}



/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}



/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}



/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}



interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}



// Inspired by Aave Protocol's IFlashLoanReceiver.

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}





/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable, IAuthentication {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}



interface IBasePoolFactory is IAuthentication {
    /**
     * @dev Returns true if `pool` was created by this factory.
     */
    function isPoolFromFactory(address pool) external view returns (bool);

    /**
     * @dev Check whether the derived factory has been disabled.
     */
    function isDisabled() external view returns (bool);
}







// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(
    bool condition,
    uint256 errorCode,
    bytes3 prefix
) pure {
    if (!condition) _revert(errorCode, prefix);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
    _revert(errorCode, 0x42414c); // This is the raw byte representation of "BAL"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of 'BAL', it results in 0x42414c23 ('BAL#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(200, add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;
    uint256 internal constant INSUFFICIENT_DATA = 105;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant FEATURE_DISABLED = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;
    uint256 internal constant FRACTIONAL_TARGET = 353;
    uint256 internal constant ADD_OR_REMOVE_BPT = 354;
    uint256 internal constant INVALID_CIRCUIT_BREAKER_BOUNDS = 355;
    uint256 internal constant CIRCUIT_BREAKER_TRIPPED = 356;
    uint256 internal constant MALICIOUS_QUERY_REVERT = 357;
    uint256 internal constant JOINS_EXITS_DISABLED = 358;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;
    uint256 internal constant CODEC_OVERFLOW = 436;
    uint256 internal constant IN_RECOVERY_MODE = 437;
    uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
    uint256 internal constant INDUCED_FAILURE = 439;
    uint256 internal constant EXPIRED_SIGNATURE = 440;
    uint256 internal constant MALFORMED_SIGNATURE = 441;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_UINT64 = 442;
    uint256 internal constant UNHANDLED_FEE_TYPE = 443;
    uint256 internal constant BURN_FROM_ZERO = 444;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;

    // FeeSplitter
    uint256 internal constant SPLITTER_FEE_PERCENTAGE_TOO_HIGH = 700;

    // Misc
    uint256 internal constant UNIMPLEMENTED = 998;
    uint256 internal constant SHOULD_NOT_HAPPEN = 999;
}

/**
 * @dev Library used to deploy contracts with specific code. This can be used for long-term storage of immutable data as
 * contract code, which can be retrieved via the `extcodecopy` opcode.
 */
library CodeDeployer {
    // During contract construction, the full code supplied exists as code, and can be accessed via `codesize` and
    // `codecopy`. This is not the contract's final code however: whatever the constructor returns is what will be
    // stored as its code.
    //
    // We use this mechanism to have a simple constructor that stores whatever is appended to it. The following opcode
    // sequence corresponds to the creation code of the following equivalent Solidity contract, plus padding to make the
    // full code 32 bytes long:
    //
    // contract CodeDeployer {
    //     constructor() payable {
    //         uint256 size;
    //         assembly {
    //             size := sub(codesize(), 32) // size of appended data, as constructor is 32 bytes long
    //             codecopy(0, 32, size) // copy all appended data to memory at position 0
    //             return(0, size) // return appended data for it to be stored as code
    //         }
    //     }
    // }
    //
    // More specifically, it is composed of the following opcodes (plus padding):
    //
    // [1] PUSH1 0x20
    // [2] CODESIZE
    // [3] SUB
    // [4] DUP1
    // [6] PUSH1 0x20
    // [8] PUSH1 0x00
    // [9] CODECOPY
    // [11] PUSH1 0x00
    // [12] RETURN
    //
    // The padding is just the 0xfe sequence (invalid opcode). It is important as it lets us work in-place, avoiding
    // memory allocation and copying.
    bytes32
        private constant _DEPLOYER_CREATION_CODE = 0x602038038060206000396000f3fefefefefefefefefefefefefefefefefefefe;

    /**
     * @dev Deploys a contract with `code` as its code, returning the destination address.
     *
     * Reverts if deployment fails.
     */
    function deploy(bytes memory code) internal returns (address destination) {
        bytes32 deployerCreationCode = _DEPLOYER_CREATION_CODE;

        // We need to concatenate the deployer creation code and `code` in memory, but want to avoid copying all of
        // `code` (which could be quite long) into a new memory location. Therefore, we operate in-place using
        // assembly.

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let codeLength := mload(code)

            // `code` is composed of length and data. We've already stored its length in `codeLength`, so we simply
            // replace it with the deployer creation code (which is exactly 32 bytes long).
            mstore(code, deployerCreationCode)

            // At this point, `code` now points to the deployer creation code immediately followed by `code`'s data
            // contents. This is exactly what the deployer expects to receive when created.
            destination := create(0, code, add(codeLength, 32))

            // Finally, we restore the original length in order to not mutate `code`.
            mstore(code, codeLength)
        }

        // The create opcode returns the zero address when contract creation fails, so we revert if this happens.
        _require(destination != address(0), Errors.CODE_DEPLOYMENT_FAILED);
    }
}

/**
 * @dev Base factory for contracts whose creation code is so large that the factory cannot hold it. This happens when
 * the contract's creation code grows close to 24kB.
 *
 * Note that this factory cannot help with contracts that have a *runtime* (deployed) bytecode larger than 24kB.
 */
abstract contract BaseSplitCodeFactory {
    // The contract's creation code is stored as code in two separate addresses, and retrieved via `extcodecopy`. This
    // means this factory supports contracts with creation code of up to 48kB.
    // We rely on inline-assembly to achieve this, both to make the entire operation highly gas efficient, and because
    // `extcodecopy` is not available in Solidity.

    // solhint-disable no-inline-assembly

    address private immutable _creationCodeContractA;
    uint256 private immutable _creationCodeSizeA;

    address private immutable _creationCodeContractB;
    uint256 private immutable _creationCodeSizeB;

    /**
     * @dev The creation code of a contract Foo can be obtained inside Solidity with `type(Foo).creationCode`.
     */
    constructor(bytes memory creationCode) {
        uint256 creationCodeSize = creationCode.length;

        // We are going to deploy two contracts: one with approximately the first half of `creationCode`'s contents
        // (A), and another with the remaining half (B).
        // We store the lengths in both immutable and stack variables, since immutable variables cannot be read during
        // construction.
        uint256 creationCodeSizeA = creationCodeSize / 2;
        _creationCodeSizeA = creationCodeSizeA;

        uint256 creationCodeSizeB = creationCodeSize - creationCodeSizeA;
        _creationCodeSizeB = creationCodeSizeB;

        // To deploy the contracts, we're going to use `CodeDeployer.deploy()`, which expects a memory array with
        // the code to deploy. Note that we cannot simply create arrays for A and B's code by copying or moving
        // `creationCode`'s contents as they are expected to be very large (> 24kB), so we must operate in-place.

        // Memory: [ code length ] [ A.data ] [ B.data ]

        // Creating A's array is simple: we simply replace `creationCode`'s length with A's length. We'll later restore
        // the original length.

        bytes memory creationCodeA;
        assembly {
            creationCodeA := creationCode
            mstore(creationCodeA, creationCodeSizeA)
        }

        // Memory: [ A.length ] [ A.data ] [ B.data ]
        //         ^ creationCodeA

        _creationCodeContractA = CodeDeployer.deploy(creationCodeA);

        // Creating B's array is a bit more involved: since we cannot move B's contents, we are going to create a 'new'
        // memory array starting at A's last 32 bytes, which will be replaced with B's length. We'll back-up this last
        // byte to later restore it.

        bytes memory creationCodeB;
        bytes32 lastByteA;

        assembly {
            // `creationCode` points to the array's length, not data, so by adding A's length to it we arrive at A's
            // last 32 bytes.
            creationCodeB := add(creationCode, creationCodeSizeA)
            lastByteA := mload(creationCodeB)
            mstore(creationCodeB, creationCodeSizeB)
        }

        // Memory: [ A.length ] [ A.data[ : -1] ] [ B.length ][ B.data ]
        //         ^ creationCodeA                ^ creationCodeB

        _creationCodeContractB = CodeDeployer.deploy(creationCodeB);

        // We now restore the original contents of `creationCode` by writing back the original length and A's last byte.
        assembly {
            mstore(creationCodeA, creationCodeSize)
            mstore(creationCodeB, lastByteA)
        }
    }

    /**
     * @dev Returns the two addresses where the creation code of the contract crated by this factory is stored.
     */
    function getCreationCodeContracts() public view returns (address contractA, address contractB) {
        return (_creationCodeContractA, _creationCodeContractB);
    }

    /**
     * @dev Returns the creation code of the contract this factory creates.
     */
    function getCreationCode() public view returns (bytes memory) {
        return _getCreationCodeWithArgs("");
    }

    /**
     * @dev Returns the creation code that will result in a contract being deployed with `constructorArgs`.
     */
    function _getCreationCodeWithArgs(bytes memory constructorArgs) private view returns (bytes memory code) {
        // This function exists because `abi.encode()` cannot be instructed to place its result at a specific address.
        // We need for the ABI-encoded constructor arguments to be located immediately after the creation code, but
        // cannot rely on `abi.encodePacked()` to perform concatenation as that would involve copying the creation code,
        // which would be prohibitively expensive.
        // Instead, we compute the creation code in a pre-allocated array that is large enough to hold *both* the
        // creation code and the constructor arguments, and then copy the ABI-encoded arguments (which should not be
        // overly long) right after the end of the creation code.

        // Immutable variables cannot be used in assembly, so we store them in the stack first.
        address creationCodeContractA = _creationCodeContractA;
        uint256 creationCodeSizeA = _creationCodeSizeA;
        address creationCodeContractB = _creationCodeContractB;
        uint256 creationCodeSizeB = _creationCodeSizeB;

        uint256 creationCodeSize = creationCodeSizeA + creationCodeSizeB;
        uint256 constructorArgsSize = constructorArgs.length;

        uint256 codeSize = creationCodeSize + constructorArgsSize;

        assembly {
            // First, we allocate memory for `code` by retrieving the free memory pointer and then moving it ahead of
            // `code` by the size of the creation code plus constructor arguments, and 32 bytes for the array length.
            code := mload(0x40)
            mstore(0x40, add(code, add(codeSize, 32)))

            // We now store the length of the code plus constructor arguments.
            mstore(code, codeSize)

            // Next, we concatenate the creation code stored in A and B.
            let dataStart := add(code, 32)
            extcodecopy(creationCodeContractA, dataStart, 0, creationCodeSizeA)
            extcodecopy(creationCodeContractB, add(dataStart, creationCodeSizeA), 0, creationCodeSizeB)
        }

        // Finally, we copy the constructorArgs to the end of the array. Unfortunately there is no way to avoid this
        // copy, as it is not possible to tell Solidity where to store the result of `abi.encode()`.
        uint256 constructorArgsDataPtr;
        uint256 constructorArgsCodeDataPtr;
        assembly {
            constructorArgsDataPtr := add(constructorArgs, 32)
            constructorArgsCodeDataPtr := add(add(code, 32), creationCodeSize)
        }

        _memcpy(constructorArgsCodeDataPtr, constructorArgsDataPtr, constructorArgsSize);
    }

    /**
     * @dev Deploys a contract with constructor arguments. To create `constructorArgs`, call `abi.encode()` with the
     * contract's constructor arguments, in order.
     */
    function _create(bytes memory constructorArgs) internal virtual returns (address) {
        bytes memory creationCode = _getCreationCodeWithArgs(constructorArgs);

        address destination;
        assembly {
            destination := create(0, add(creationCode, 32), mload(creationCode))
        }

        if (destination == address(0)) {
            // Bubble up inner revert reason
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return destination;
    }

    // From
    // https://github.com/Arachnid/solidity-stringutils/blob/b9a6f6615cf18a87a823cbc461ce9e140a61c305/src/strings.sol
    function _memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

/**
 * @dev Building block for performing access control on external functions.
 *
 * This contract is used via the `authenticate` modifier (or the `_authenticateCaller` function), which can be applied
 * to external functions to only make them callable by authorized accounts.
 *
 * Derived contracts must implement the `_canPerform` function, which holds the actual access control logic.
 */
abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    /**
     * @dev The main purpose of the `actionIdDisambiguator` is to prevent accidental function selector collisions in
     * multi contract systems.
     *
     * There are two main uses for it:
     *  - if the contract is a singleton, any unique identifier can be used to make the associated action identifiers
     *    unique. The contract's own address is a good option.
     *  - if the contract belongs to a family that shares action identifiers for the same functions, an identifier
     *    shared by the entire family (and no other contract) should be used instead.
     */
    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    /**
     * @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call the entry point function.
     */
    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        _require(_canPerform(actionId, msg.sender), Errors.SENDER_NOT_ALLOWED);
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
        // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
        // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
        // multiple contracts.
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}

abstract contract SingletonAuthentication is Authentication {
    IVault private immutable _vault;

    // Use the contract's own address to disambiguate action identifiers
    constructor(IVault vault) Authentication(bytes32(uint256(address(this)))) {
        _vault = vault;
    }

    /**
     * @notice Returns the Balancer Vault
     */
    function getVault() public view returns (IVault) {
        return _vault;
    }

    /**
     * @notice Returns the Authorizer
     */
    function getAuthorizer() public view returns (IAuthorizer) {
        return getVault().getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        return getAuthorizer().canPerform(actionId, account, address(this));
    }

    function _canPerform(
        bytes32 actionId,
        address account,
        address where
    ) internal view returns (bool) {
        return getAuthorizer().canPerform(actionId, account, where);
    }
}

/**
 * @dev Allows for a contract to be paused during an initial period after deployment, disabling functionality. Can be
 * used as an emergency switch in case a security vulnerability or threat is identified.
 *
 * The contract can only be paused during the Pause Window, a period that starts at deployment. It can also be
 * unpaused and repaused any number of times during this period. This is intended to serve as a safety measure: it lets
 * system managers react quickly to potentially dangerous situations, knowing that this action is reversible if careful
 * analysis later determines there was a false alarm.
 *
 * If the contract is paused when the Pause Window finishes, it will remain in the paused state through an additional
 * Buffer Period, after which it will be automatically unpaused forever. This is to ensure there is always enough time
 * to react to an emergency, even if the threat is discovered shortly before the Pause Window expires.
 *
 * Note that since the contract can only be paused within the Pause Window, unpausing during the Buffer Period is
 * irreversible.
 */
abstract contract TemporarilyPausable is ITemporarilyPausable {
    // The Pause Window and Buffer Period are timestamp-based: they should not be relied upon for sub-minute accuracy.
    // solhint-disable not-rely-on-time

    uint256 private immutable _pauseWindowEndTime;
    uint256 private immutable _bufferPeriodEndTime;

    bool private _paused;

    constructor(uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        _require(pauseWindowDuration <= PausableConstants.MAX_PAUSE_WINDOW_DURATION, Errors.MAX_PAUSE_WINDOW_DURATION);
        _require(
            bufferPeriodDuration <= PausableConstants.MAX_BUFFER_PERIOD_DURATION,
            Errors.MAX_BUFFER_PERIOD_DURATION
        );

        uint256 pauseWindowEndTime = block.timestamp + pauseWindowDuration;

        _pauseWindowEndTime = pauseWindowEndTime;
        _bufferPeriodEndTime = pauseWindowEndTime + bufferPeriodDuration;
    }

    /**
     * @dev Reverts if the contract is paused.
     */
    modifier whenNotPaused() {
        _ensureNotPaused();
        _;
    }

    /**
     * @dev Returns the current contract pause status, as well as the end times of the Pause Window and Buffer
     * Period.
     */
    function getPausedState()
        external
        view
        override
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        )
    {
        paused = !_isNotPaused();
        pauseWindowEndTime = _getPauseWindowEndTime();
        bufferPeriodEndTime = _getBufferPeriodEndTime();
    }

    /**
     * @dev Sets the pause state to `paused`. The contract can only be paused until the end of the Pause Window, and
     * unpaused until the end of the Buffer Period.
     *
     * Once the Buffer Period expires, this function reverts unconditionally.
     */
    function _setPaused(bool paused) internal {
        if (paused) {
            _require(block.timestamp < _getPauseWindowEndTime(), Errors.PAUSE_WINDOW_EXPIRED);
        } else {
            _require(block.timestamp < _getBufferPeriodEndTime(), Errors.BUFFER_PERIOD_EXPIRED);
        }

        _paused = paused;
        emit PausedStateChanged(paused);
    }

    /**
     * @dev Reverts if the contract is paused.
     */
    function _ensureNotPaused() internal view {
        _require(_isNotPaused(), Errors.PAUSED);
    }

    /**
     * @dev Reverts if the contract is not paused.
     */
    function _ensurePaused() internal view {
        _require(!_isNotPaused(), Errors.NOT_PAUSED);
    }

    /**
     * @dev Returns true if the contract is unpaused.
     *
     * Once the Buffer Period expires, the gas cost of calling this function is reduced dramatically, as storage is no
     * longer accessed.
     */
    function _isNotPaused() internal view returns (bool) {
        // After the Buffer Period, the (inexpensive) timestamp check short-circuits the storage access.
        return block.timestamp > _getBufferPeriodEndTime() || !_paused;
    }

    // These getters lead to reduced bytecode size by inlining the immutable variables in a single place.

    function _getPauseWindowEndTime() private view returns (uint256) {
        return _pauseWindowEndTime;
    }

    function _getBufferPeriodEndTime() private view returns (uint256) {
        return _bufferPeriodEndTime;
    }
}

/**
 * @dev Keep the maximum durations in a single place.
 */
library PausableConstants {
    uint256 public constant MAX_PAUSE_WINDOW_DURATION = 270 days;
    uint256 public constant MAX_BUFFER_PERIOD_DURATION = 90 days;
}

/**
 * @dev Utility to create Pool factories for Pools that use the `TemporarilyPausable` contract.
 *
 * By calling `TemporarilyPausable`'s constructor with the result of `getPauseConfiguration`, all Pools created by this
 * factory will share the same Pause Window end time, after which both old and new Pools will not be pausable.
 */
contract FactoryWidePauseWindow {
    // This contract relies on timestamps in a similar way as `TemporarilyPausable` does - the same caveats apply.
    // solhint-disable not-rely-on-time

    uint256 private immutable _initialPauseWindowDuration;
    uint256 private immutable _bufferPeriodDuration;

    // Time when the pause window for all created Pools expires, and the pause window duration of new Pools becomes
    // zero.
    uint256 private immutable _poolsPauseWindowEndTime;

    constructor(uint256 initialPauseWindowDuration, uint256 bufferPeriodDuration) {
        // New pools will check on deployment that the durations given are within the bounds specified by
        // `TemporarilyPausable`. Since it is now possible for a factory to pass in arbitrary values here,
        // pre-emptively verify that these durations are valid for pool creation.
        // (Otherwise, you would be able to deploy a useless factory where `create` would always revert.)

        _require(
            initialPauseWindowDuration <= PausableConstants.MAX_PAUSE_WINDOW_DURATION,
            Errors.MAX_PAUSE_WINDOW_DURATION
        );
        _require(
            bufferPeriodDuration <= PausableConstants.MAX_BUFFER_PERIOD_DURATION,
            Errors.MAX_BUFFER_PERIOD_DURATION
        );

        _initialPauseWindowDuration = initialPauseWindowDuration;
        _bufferPeriodDuration = bufferPeriodDuration;

        _poolsPauseWindowEndTime = block.timestamp + initialPauseWindowDuration;
    }

    /**
     * @dev Returns the current `TemporarilyPausable` configuration that will be applied to Pools created by this
     * factory.
     *
     * `pauseWindowDuration` will decrease over time until it reaches zero, at which point both it and
     * `bufferPeriodDuration` will be zero forever, meaning deployed Pools will not be pausable.
     */
    function getPauseConfiguration() public view returns (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        uint256 currentTime = block.timestamp;
        if (currentTime < _poolsPauseWindowEndTime) {
            // The buffer period is always the same since its duration is related to how much time is needed to respond
            // to a potential emergency. The Pause Window duration however decreases as the end time approaches.

            pauseWindowDuration = _poolsPauseWindowEndTime - currentTime; // No need for checked arithmetic.
            bufferPeriodDuration = _bufferPeriodDuration;
        } else {
            // After the end time, newly created Pools have no Pause Window, nor Buffer Period (since they are not
            // pausable in the first place).

            pauseWindowDuration = 0;
            bufferPeriodDuration = 0;
        }
    }
}

/**
 * @notice Base contract for Pool factories.
 *
 * Pools are deployed from factories to allow third parties to reason about them. Unknown Pools may have arbitrary
 * logic: being able to assert that a Pool's behavior follows certain rules (those imposed by the contracts created by
 * the factory) is very powerful.
 *
 * @dev By using the split code mechanism, we can deploy Pools with creation code so large that a regular factory
 * contract would not be able to store it.
 *
 * Since we expect to release new versions of pool types regularly - and the blockchain is forever - versioning will
 * become increasingly important. Governance can deprecate a factory by calling `disable`, which will permanently
 * prevent the creation of any future pools from the factory.
 */
abstract contract BasePoolFactory is
    IBasePoolFactory,
    BaseSplitCodeFactory,
    SingletonAuthentication,
    FactoryWidePauseWindow
{
    IProtocolFeePercentagesProvider private immutable _protocolFeeProvider;

    mapping(address => bool) private _isPoolFromFactory;
    bool private _disabled;

    event PoolCreated(address indexed pool);

    constructor(
        IVault vault,
        IProtocolFeePercentagesProvider protocolFeeProvider,
        uint256 initialPauseWindowDuration,
        uint256 bufferPeriodDuration,
        bytes memory creationCode
    )
        BaseSplitCodeFactory(creationCode)
        SingletonAuthentication(vault)
        FactoryWidePauseWindow(initialPauseWindowDuration, bufferPeriodDuration)
    {
        _protocolFeeProvider = protocolFeeProvider;
    }

    function isPoolFromFactory(address pool) external view override returns (bool) {
        return _isPoolFromFactory[pool];
    }

    function isDisabled() public view override returns (bool) {
        return _disabled;
    }

    function _ensureEnabled() internal view {
        _require(!isDisabled(), Errors.DISABLED);
    }

    function getProtocolFeePercentagesProvider() public view returns (IProtocolFeePercentagesProvider) {
        return _protocolFeeProvider;
    }

    function _create(bytes memory constructorArgs) internal virtual override returns (address) {
        _ensureEnabled();

        address pool = super._create(constructorArgs);

        _isPoolFromFactory[pool] = true;

        emit PoolCreated(pool);

        return pool;
    }
}



/**
 * @notice Interface for ExternalWeightedMath, a contract-wrapper for Weighted Math, Joins and Exits.
 */
interface IExternalWeightedMath {
    /**
     * @dev See `WeightedMath._calculateInvariant`.
     */
    function calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
        external
        pure
        returns (uint256);

    /**
     * @dev See `WeightedMath._calcOutGivenIn`.
     */
    function calcOutGivenIn(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcInGivenOut`.
     */
    function calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcBptOutGivenExactTokensIn`.
     */
    function calcBptOutGivenExactTokensIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcBptOutGivenExactTokenIn`.
     */
    function calcBptOutGivenExactTokenIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcTokenInGivenExactBptOut`.
     */
    function calcTokenInGivenExactBptOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcAllTokensInGivenExactBptOut`.
     */
    function calcAllTokensInGivenExactBptOut(
        uint256[] memory balances,
        uint256 bptAmountOut,
        uint256 totalBPT
    ) external pure returns (uint256[] memory);

    /**
     * @dev See `WeightedMath._calcBptInGivenExactTokensOut`.
     */
    function calcBptInGivenExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcBptInGivenExactTokenOut`.
     */
    function calcBptInGivenExactTokenOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcTokenOutGivenExactBptIn`.
     */
    function calcTokenOutGivenExactBptIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcTokensOutGivenExactBptIn`.
     */
    function calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) external pure returns (uint256[] memory);

    /**
     * @dev See `WeightedMath._calcBptOutAddToken`.
     */
    function calcBptOutAddToken(uint256 totalSupply, uint256 normalizedWeight) external pure returns (uint256);

    /**
     * @dev See `WeightedJoinsLib.joinExactTokensInForBPTOut`.
     */
    function joinExactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);

    /**
     * @dev See `WeightedJoinsLib.joinTokenInForExactBPTOut`.
     */
    function joinTokenInForExactBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);

    /**
     * @dev See `WeightedJoinsLib.joinAllTokensInForExactBPTOut`.
     */
    function joinAllTokensInForExactBPTOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) external pure returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    /**
     * @dev See `WeightedExitsLib.exitExactBPTInForTokenOut`.
     */
    function exitExactBPTInForTokenOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);

    /**
     * @dev See `WeightedExitsLib.exitExactBPTInForTokensOut`.
     */
    function exitExactBPTInForTokensOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) external pure returns (uint256 bptAmountIn, uint256[] memory amountsOut);

    /**
     * @dev See `WeightedExitsLib.exitBPTInForExactTokensOut`.
     */
    function exitBPTInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);
}



library WeightedPoolUserData {
    // In order to preserve backwards compatibility, make sure new join and exit kinds are added at the end of the enum.
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    function joinKind(bytes memory self) internal pure returns (JoinKind) {
        return abi.decode(self, (JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (ExitKind) {
        return abi.decode(self, (ExitKind));
    }

    // Joins

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function exactTokensInForBptOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsIn, uint256 minBPTAmountOut)
    {
        (, amountsIn, minBPTAmountOut) = abi.decode(self, (JoinKind, uint256[], uint256));
    }

    function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
        (, bptAmountOut, tokenIndex) = abi.decode(self, (JoinKind, uint256, uint256));
    }

    function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut) {
        (, bptAmountOut) = abi.decode(self, (JoinKind, uint256));
    }

    // Exits

    function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
        (, bptAmountIn, tokenIndex) = abi.decode(self, (ExitKind, uint256, uint256));
    }

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (ExitKind, uint256));
    }

    function bptInForExactTokensOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
    {
        (, amountsOut, maxBPTAmountIn) = abi.decode(self, (ExitKind, uint256[], uint256));
    }
}



// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x >> 255 == 0, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    // solhint-disable no-inline-assembly

    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant TWO = 2 * ONE;
    uint256 internal constant FOUR = 4 * ONE;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = product == 0 ? 0 : ((product - 1) / FixedPoint.ONE) + 1;
        assembly {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        uint256 aInflated = a * ONE;
        _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

        return aInflated / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        uint256 aInflated = a * ONE;
        _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = a == 0 ? 0 : (a * FixedPoint.ONE - 1) / b + 1;
        assembly {
            result := mul(iszero(iszero(aInflated)), add(div(sub(aInflated, 1), b), 1))
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            if (raw < maxError) {
                return 0;
            } else {
                return sub(raw, maxError);
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            return add(raw, maxError);
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (x < ONE) ? (ONE - x) : 0;
        assembly {
            result := mul(lt(x, ONE), sub(ONE, x))
        }
    }
}

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}



library BasePoolMath {
    using FixedPoint for uint256;

    function computeProportionalAmountsIn(
        uint256[] memory balances,
        uint256 bptTotalSupply,
        uint256 bptAmountOut
    ) internal pure returns (uint256[] memory amountsIn) {
        /************************************************************************************
        // computeProportionalAmountsIn                                                    //
        // (per token)                                                                     //
        // aI = amountIn                   /      bptOut      \                            //
        // b = balance           aI = b * | ----------------- |                            //
        // bptOut = bptAmountOut           \  bptTotalSupply  /                            //
        // bpt = bptTotalSupply                                                            //
        ************************************************************************************/

        // Since we're computing amounts in, we round up overall. This means rounding up on both the
        // multiplication and division.

        uint256 bptRatio = bptAmountOut.divUp(bptTotalSupply);

        amountsIn = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsIn[i] = balances[i].mulUp(bptRatio);
        }
    }

    function computeProportionalAmountsOut(
        uint256[] memory balances,
        uint256 bptTotalSupply,
        uint256 bptAmountIn
    ) internal pure returns (uint256[] memory amountsOut) {
        /**********************************************************************************************
        // computeProportionalAmountsOut                                                             //
        // (per token)                                                                               //
        // aO = tokenAmountOut             /        bptIn         \                                  //
        // b = tokenBalance      a0 = b * | ---------------------  |                                 //
        // bptIn = bptAmountIn             \     bptTotalSupply    /                                 //
        // bpt = bptTotalSupply                                                                      //
        **********************************************************************************************/

        // Since we're computing an amount out, we round down overall. This means rounding down on both the
        // multiplication and division.

        uint256 bptRatio = bptAmountIn.divDown(bptTotalSupply);

        amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsOut[i] = balances[i].mulDown(bptRatio);
        }
    }
}



// solhint-disable no-inline-assembly

library ComposablePoolLib {
    using FixedPoint for uint256;

    /**
     * @notice Returns a slice of the original array, with the BPT token address removed.
     * @dev *This mutates the original array*, which should not be used anymore after calling this function.
     * It's recommended to call this function such that the calling function either immediately returns or overwrites
     * the original array variable so it cannot be accessed.
     */
    function dropBptFromTokens(IERC20[] memory registeredTokens) internal pure returns (IERC20[] memory tokens) {
        assembly {
            // An array's memory representation is a 32 byte word for the length followed by 32 byte words for
            // each element, with the stack variable pointing to the length. Since there's no memory deallocation,
            // and we are free to mutate the received array, the cheapest way to remove the first element is to
            // create a new subarray by overwriting the first element with a reduced length, and moving the pointer
            // forward to that position.
            //
            // Original:
            // [ length ] [ data[0] ] [ data[1] ] [ ... ]
            // ^ pointer
            //
            // Modified:
            // [ length ] [ length - 1 ] [ data[1] ] [ ... ]
            //                ^ pointer
            //
            // Note that this can only be done if the element to remove is the first one, which is one of the reasons
            // why Composable Pools register BPT as the first token.
            mstore(add(registeredTokens, 32), sub(mload(registeredTokens), 1))
            tokens := add(registeredTokens, 32)
        }
    }

    /**
     * @notice Returns the virtual supply, and a slice of the original balances array with the BPT balance removed.
     * @dev *This mutates the original array*, which should not be used anymore after calling this function.
     * It's recommended to call this function such that the calling function either immediately returns or overwrites
     * the original array variable so it cannot be accessed.
     */
    function dropBptFromBalances(uint256 totalSupply, uint256[] memory registeredBalances)
        internal
        pure
        returns (uint256 virtualSupply, uint256[] memory balances)
    {
        virtualSupply = totalSupply.sub(registeredBalances[0]);
        assembly {
            // See dropBptFromTokens for a detailed explanation of how this works.
            mstore(add(registeredBalances, 32), sub(mload(registeredBalances), 1))
            balances := add(registeredBalances, 32)
        }
    }

    /**
     * @notice Returns slices of the original arrays, with the BPT token address and balance removed.
     * @dev *This mutates the original arrays*, which should not be used anymore after calling this function.
     * It's recommended to call this function such that the calling function either immediately returns or overwrites
     * the original array variable so it cannot be accessed.
     */
    function dropBpt(IERC20[] memory registeredTokens, uint256[] memory registeredBalances)
        internal
        pure
        returns (IERC20[] memory tokens, uint256[] memory balances)
    {
        assembly {
            // See dropBptFromTokens for a detailed explanation of how this works
            mstore(add(registeredTokens, 32), sub(mload(registeredTokens), 1))
            tokens := add(registeredTokens, 32)

            mstore(add(registeredBalances, 32), sub(mload(registeredBalances), 1))
            balances := add(registeredBalances, 32)
        }
    }

    /**
     * @notice Returns the passed array prepended with a zero element.
     */
    function prependZeroElement(uint256[] memory array) internal pure returns (uint256[] memory prependedArray) {
        prependedArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            prependedArray[i + 1] = array[i];
        }
    }
}



library PoolRegistrationLib {
    function registerPool(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens
    ) internal returns (bytes32) {
        return registerPoolWithAssetManagers(vault, specialization, tokens, new address[](tokens.length));
    }

    function registerPoolWithAssetManagers(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) internal returns (bytes32) {
        // The Vault only requires the token list to be ordered for the Two Token Pools specialization. However,
        // to make the developer experience consistent, we are requiring this condition for all the native pools.
        //
        // Note that for Pools which can register and deregister tokens after deployment, this property may not hold
        // as tokens which are added to the Pool after deployment are always added to the end of the array.
        InputHelpers.ensureArrayIsSorted(tokens);

        return _registerPool(vault, specialization, tokens, assetManagers);
    }

    function registerComposablePool(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) internal returns (bytes32) {
        // The Vault only requires the token list to be ordered for the Two Token Pools specialization. However,
        // to make the developer experience consistent, we are requiring this condition for all the native pools.
        //
        // Note that for Pools which can register and deregister tokens after deployment, this property may not hold
        // as tokens which are added to the Pool after deployment are always added to the end of the array.
        InputHelpers.ensureArrayIsSorted(tokens);

        IERC20[] memory composableTokens = new IERC20[](tokens.length + 1);
        // We insert the Pool's BPT address into the first position.
        // This allows us to know the position of the BPT token in the tokens array without explicitly tracking it.
        // When deregistering a token, the token at the end of the array is moved into the index of the deregistered
        // token, changing its index. By placing BPT at the beginning of the tokens array we can be sure that its index
        // will never change unless it is deregistered itself (something which composable pools must prevent anyway).
        composableTokens[0] = IERC20(address(this));
        for (uint256 i = 0; i < tokens.length; i++) {
            composableTokens[i + 1] = tokens[i];
        }

        address[] memory composableAssetManagers = new address[](assetManagers.length + 1);
        // We do not allow an asset manager for the Pool's BPT.
        composableAssetManagers[0] = address(0);
        for (uint256 i = 0; i < assetManagers.length; i++) {
            composableAssetManagers[i + 1] = assetManagers[i];
        }
        return _registerPool(vault, specialization, composableTokens, composableAssetManagers);
    }

    function _registerPool(
        IVault vault,
        IVault.PoolSpecialization specialization,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) private returns (bytes32) {
        bytes32 poolId = vault.registerPool(specialization);

        // We don't need to check that tokens and assetManagers have the same length, since the Vault already performs
        // that check.
        vault.registerTokens(poolId, tokens, assetManagers);

        return poolId;
    }

    function registerToken(
        IVault vault,
        bytes32 poolId,
        IERC20 token,
        address assetManager
    ) internal {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = token;

        address[] memory assetManagers = new address[](1);
        assetManagers[0] = assetManager;

        vault.registerTokens(poolId, tokens, assetManagers);
    }

    function deregisterToken(
        IVault vault,
        bytes32 poolId,
        IERC20 token
    ) internal {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = token;

        vault.deregisterTokens(poolId, tokens);
    }
}









interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

/**
 * @dev Interface for adding and removing liquidity that all Pool contracts should implement. Note that this is not
 * the complete Pool contract interface, as it is missing the swap hooks. Pool contracts should also inherit from
 * either IGeneralPool or IMinimalSwapInfoPool
 */
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `balances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `balances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Returns this Pool's ID, used when interacting with the Vault (to e.g. join the Pool or swap with it).
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @dev Returns the current swap fee percentage as a 18 decimal fixed point number, so e.g. 1e17 corresponds to a
     * 10% swap fee.
     */
    function getSwapFeePercentage() external view returns (uint256);

    /**
     * @dev Returns the scaling factors of each of the Pool's tokens. This is an implementation detail that is typically
     * not relevant for outside parties, but which might be useful for some types of Pools.
     */
    function getScalingFactors() external view returns (uint256[] memory);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

interface IManagedPool is IBasePool {
    event GradualSwapFeeUpdateScheduled(
        uint256 startTime,
        uint256 endTime,
        uint256 startSwapFeePercentage,
        uint256 endSwapFeePercentage
    );
    event GradualWeightUpdateScheduled(
        uint256 startTime,
        uint256 endTime,
        uint256[] startWeights,
        uint256[] endWeights
    );
    event SwapEnabledSet(bool swapEnabled);
    event MustAllowlistLPsSet(bool mustAllowlistLPs);
    event AllowlistAddressAdded(address indexed member);
    event AllowlistAddressRemoved(address indexed member);
    event ManagementAumFeePercentageChanged(uint256 managementAumFeePercentage);
    event ManagementAumFeeCollected(uint256 bptAmount);
    event CircuitBreakerSet(
        IERC20 indexed token,
        uint256 bptPrice,
        uint256 lowerBoundPercentage,
        uint256 upperBoundPercentage
    );
    event TokenAdded(IERC20 indexed token, uint256 normalizedWeight);
    event TokenRemoved(IERC20 indexed token);

    /**
     * @notice Returns the effective BPT supply.
     *
     * @dev The Pool owes debt to the Protocol and the Pool's owner in the form of unminted BPT, which will be minted
     * immediately before the next join or exit. We need to take these into account since, even if they don't yet exist,
     * they will effectively be included in any Pool operation that involves BPT.
     *
     * In the vast majority of cases, this function should be used instead of `totalSupply()`.
     */
    function getActualSupply() external view returns (uint256);

    // Swap fee percentage

    /**
     * @notice Schedule a gradual swap fee update.
     * @dev The swap fee will change from the given starting value (which may or may not be the current
     * value) to the given ending fee percentage, over startTime to endTime.
     *
     * Note that calling this with a starting swap fee different from the current value will immediately change the
     * current swap fee to `startSwapFeePercentage`, before commencing the gradual change at `startTime`.
     * Emits the GradualSwapFeeUpdateScheduled event.
     * This is a permissioned function.
     *
     * @param startTime - The timestamp when the swap fee change will begin.
     * @param endTime - The timestamp when the swap fee change will end (must be >= startTime).
     * @param startSwapFeePercentage - The starting value for the swap fee change.
     * @param endSwapFeePercentage - The ending value for the swap fee change. If the current timestamp >= endTime,
     * `getSwapFeePercentage()` will return this value.
     */
    function updateSwapFeeGradually(
        uint256 startTime,
        uint256 endTime,
        uint256 startSwapFeePercentage,
        uint256 endSwapFeePercentage
    ) external;

    /**
     * @notice Returns the current gradual swap fee update parameters.
     * @dev The current swap fee can be retrieved via `getSwapFeePercentage()`.
     * @return startTime - The timestamp when the swap fee update will begin.
     * @return endTime - The timestamp when the swap fee update will end.
     * @return startSwapFeePercentage - The starting swap fee percentage (could be different from the current value).
     * @return endSwapFeePercentage - The final swap fee percentage, when the current timestamp >= endTime.
     */
    function getGradualSwapFeeUpdateParams()
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 startSwapFeePercentage,
            uint256 endSwapFeePercentage
        );

    // Token weights

    /**
     * @notice Schedule a gradual weight change.
     * @dev The weights will change from their current values to the given endWeights, over startTime to endTime.
     * This is a permissioned function.
     *
     * Since, unlike with swap fee updates, we generally do not want to allow instantaneous weight changes,
     * the weights always start from their current values. This also guarantees a smooth transition when
     * updateWeightsGradually is called during an ongoing weight change.
     * @param startTime - The timestamp when the weight change will begin.
     * @param endTime - The timestamp when the weight change will end (can be >= startTime).
     * @param tokens - The tokens associated with the target weights (must match the current pool tokens).
     * @param endWeights - The target weights. If the current timestamp >= endTime, `getNormalizedWeights()`
     * will return these values.
     */
    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        IERC20[] memory tokens,
        uint256[] memory endWeights
    ) external;

    /**
     * @notice Returns all normalized weights, in the same order as the Pool's tokens.
     */
    function getNormalizedWeights() external view returns (uint256[] memory);

    /**
     * @notice Returns the current gradual weight change update parameters.
     * @dev The current weights can be retrieved via `getNormalizedWeights()`.
     * @return startTime - The timestamp when the weight update will begin.
     * @return endTime - The timestamp when the weight update will end.
     * @return startWeights - The starting weights, when the weight change was initiated.
     * @return endWeights - The final weights, when the current timestamp >= endTime.
     */
    function getGradualWeightUpdateParams()
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        );

    // Swap enable/disable

    /**
     * @notice Enable or disable trading.
     * @dev Emits the SwapEnabledSet event. This is a permissioned function.
     * @param swapEnabled - The new value of the swap enabled flag.
     */
    function setSwapEnabled(bool swapEnabled) external;

    /**
     * @notice Returns whether swaps are enabled.
     */
    function getSwapEnabled() external view returns (bool);

    // LP Allowlist

    /**
     * @notice Enable or disable the LP allowlist.
     * @dev Note that any addresses added to the allowlist will be retained if the allowlist is toggled off and
     * back on again, because this action does not affect the list of LP addresses.
     * Emits the MustAllowlistLPsSet event. This is a permissioned function.
     * @param mustAllowlistLPs - The new value of the mustAllowlistLPs flag.
     */
    function setMustAllowlistLPs(bool mustAllowlistLPs) external;

    /**
     * @notice Adds an address to the LP allowlist.
     * @dev Will fail if the address is already allowlisted.
     * Emits the AllowlistAddressAdded event. This is a permissioned function.
     * @param member - The address to be added to the allowlist.
     */
    function addAllowedAddress(address member) external;

    /**
     * @notice Removes an address from the LP allowlist.
     * @dev Will fail if the address was not previously allowlisted.
     * Emits the AllowlistAddressRemoved event. This is a permissioned function.
     * @param member - The address to be removed from the allowlist.
     */
    function removeAllowedAddress(address member) external;

    /**
     * @notice Returns whether the allowlist for LPs is enabled.
     */
    function getMustAllowlistLPs() external view returns (bool);

    /**
     * @notice Check whether an LP address is on the allowlist.
     * @dev This simply checks the list, regardless of whether the allowlist feature is enabled.
     * @param member - The address to check against the allowlist.
     * @return true if the given address is on the allowlist.
     */
    function isAddressOnAllowlist(address member) external view returns (bool);

    // Management fees

    /**
     * @notice Collect any accrued AUM fees and send them to the pool manager.
     * @dev This can be called by anyone to collect accrued AUM fees - and will be called automatically
     * whenever the supply changes (e.g., joins and exits, add and remove token), and before the fee
     * percentage is changed by the manager, to prevent fees from being applied retroactively.
     * @return The amount of BPT minted to the manager.
     */
    function collectAumManagementFees() external returns (uint256);

    /**
     * @notice Setter for the yearly percentage AUM management fee, which is payable to the pool manager.
     * @dev Attempting to collect AUM fees in excess of the maximum permitted percentage will revert.
     * To avoid retroactive fee increases, we force collection at the current fee percentage before processing
     * the update. Emits the ManagementAumFeePercentageChanged event. This is a permissioned function.
     * @param managementAumFeePercentage - The new management AUM fee percentage.
     * @return amount - The amount of BPT minted to the manager before the update, if any.
     */
    function setManagementAumFeePercentage(uint256 managementAumFeePercentage) external returns (uint256);

    /**
     * @notice Returns the management AUM fee percentage as an 18-decimal fixed point number and the timestamp of the
     * last collection of AUM fees.
     */
    function getManagementAumFeeParams()
        external
        view
        returns (uint256 aumFeePercentage, uint256 lastCollectionTimestamp);

    // Circuit Breakers

    /**
     * @notice Set a circuit breaker for one or more tokens.
     * @dev This is a permissioned function. The lower and upper bounds are percentages, corresponding to a
     * relative change in the token's spot price: e.g., a lower bound of 0.8 means the breaker should prevent
     * trades that result in the value of the token dropping 20% or more relative to the rest of the pool.
     */
    function setCircuitBreakers(
        IERC20[] memory tokens,
        uint256[] memory bptPrices,
        uint256[] memory lowerBoundPercentages,
        uint256[] memory upperBoundPercentages
    ) external;

    /**
     * @notice Return the full circuit breaker state for the given token.
     * @dev These are the reference values (BPT price and reference weight) passed in when the breaker was set,
     * along with the percentage bounds. It also returns the current BPT price bounds, needed to check whether
     * the circuit breaker should trip.
     */
    function getCircuitBreakerState(IERC20 token)
        external
        view
        returns (
            uint256 bptPrice,
            uint256 referenceWeight,
            uint256 lowerBound,
            uint256 upperBound,
            uint256 lowerBptPriceBound,
            uint256 upperBptPriceBound
        );

    // Add/remove tokens

    /**
     * @notice Adds a token to the Pool's list of tradeable tokens. This is a permissioned function.
     *
     * @dev By adding a token to the Pool's composition, the weights of all other tokens will be decreased. The new
     * token will have no balance - it is up to the owner to provide some immediately after calling this function.
     * Note however that regular join functions will not work while the new token has no balance: the only way to
     * deposit an initial amount is by using an Asset Manager.
     *
     * Token addition is forbidden during a weight change, or if one is scheduled to happen in the future.
     *
     * The caller may additionally pass a non-zero `mintAmount` to have some BPT be minted for them, which might be
     * useful in some scenarios to account for the fact that the Pool will have more tokens.
     *
     * Emits the TokenAdded event.
     *
     * @param tokenToAdd - The ERC20 token to be added to the Pool.
     * @param assetManager - The Asset Manager for the token.
     * @param tokenToAddNormalizedWeight - The normalized weight of `token` relative to the other tokens in the Pool.
     * @param mintAmount - The amount of BPT to be minted as a result of adding `token` to the Pool.
     * @param recipient - The address to receive the BPT minted by the Pool.
     */
    function addToken(
        IERC20 tokenToAdd,
        address assetManager,
        uint256 tokenToAddNormalizedWeight,
        uint256 mintAmount,
        address recipient
    ) external;

    /**
     * @notice Removes a token from the Pool's list of tradeable tokens.
     * @dev Tokens can only be removed if the Pool has more than 2 tokens, as it can never have fewer than 2 (not
     * including BPT). Token removal is also forbidden during a weight change, or if one is scheduled to happen in
     * the future.
     *
     * Emits the TokenRemoved event. This is a permissioned function.
     *
     * The caller may additionally pass a non-zero `burnAmount` to burn some of their BPT, which might be useful
     * in some scenarios to account for the fact that the Pool now has fewer tokens. This is a permissioned function.
     * @param tokenToRemove - The ERC20 token to be removed from the Pool.
     * @param burnAmount - The amount of BPT to be burned after removing `token` from the Pool.
     * @param sender - The address to burn BPT from.
     */
    function removeToken(
        IERC20 tokenToRemove,
        uint256 burnAmount,
        address sender
    ) external;
}

// solhint-disable

function _asIAsset(IERC20[] memory tokens) pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        assets := tokens
    }
}

function _sortTokens(
    IERC20 tokenA,
    IERC20 tokenB
) pure returns (IERC20[] memory tokens) {
    bool aFirst = tokenA < tokenB;
    IERC20[] memory sortedTokens = new IERC20[](2);

    sortedTokens[0] = aFirst ? tokenA : tokenB;
    sortedTokens[1] = aFirst ? tokenB : tokenA;

    return sortedTokens;
}

function _insertSorted(IERC20[] memory tokens, IERC20 token) pure returns (IERC20[] memory sorted) {
    sorted = new IERC20[](tokens.length + 1);

    if (tokens.length == 0) {
        sorted[0] = token;
        return sorted;
    }

    uint256 i;
    for (i = tokens.length; i > 0 && tokens[i - 1] > token; i--) sorted[i] = tokens[i - 1];
    for (uint256 j = 0; j < i; j++) sorted[j] = tokens[j];
    sorted[i] = token;
}

function _findTokenIndex(IERC20[] memory tokens, IERC20 token) pure returns (uint256) {
    // Note that while we know tokens are initially sorted, we cannot assume this will hold throughout
    // the pool's lifetime, as pools with mutable tokens can append and remove tokens in any order.
    uint256 tokensLength = tokens.length;
    for (uint256 i = 0; i < tokensLength; i++) {
        if (tokens[i] == token) {
            return i;
        }
    }

    _revert(Errors.INVALID_TOKEN);
}





/* solhint-disable private-vars-leading-underscore */

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library.
 */
library Math {
    // solhint-disable no-inline-assembly

    /**
     * @dev Returns the absolute value of a signed integer.
     */
    function abs(int256 a) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = a > 0 ? uint256(a) : uint256(-a)
        assembly {
            let s := sar(255, a)
            result := sub(xor(a, s), s)
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (a < b) ? b : a;
        assembly {
            result := sub(a, mul(sub(a, b), lt(a, b)))
        }
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to `result = (a < b) ? a : b`
        assembly {
            result := sub(a, mul(sub(a, b), gt(a, b)))
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        // Equivalent to:
        // result = a == 0 ? 0 : 1 + (a - 1) / b;
        assembly {
            result := mul(iszero(iszero(a)), add(1, div(sub(a, 1), b)))
        }
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, Errors.SUB_OVERFLOW);
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        uint256 errorCode
    ) internal pure returns (uint256) {
        _require(b <= a, errorCode);
        uint256 c = a - b;

        return c;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}. The total supply should only be read using this function
     *
     * Can be overridden by derived contracts to store the total supply in a different way (e.g. packed with other
     * storage values).
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Sets a new value for the total supply. It should only be set using this function.
     *
     * * Can be overridden by derived contracts to store the total supply in a different way (e.g. packed with other
     * storage values).
     */
    function _setTotalSupply(uint256 value) internal virtual {
        _totalSupply = value;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE)
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, Errors.ERC20_DECREASED_ALLOWANCE_BELOW_ZERO)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _require(sender != address(0), Errors.ERC20_TRANSFER_FROM_ZERO_ADDRESS);
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_BALANCE);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);

        _setTotalSupply(totalSupply().add(amount));
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _require(account != address(0), Errors.ERC20_BURN_FROM_ZERO_ADDRESS);

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, Errors.ERC20_BURN_EXCEEDS_BALANCE);
        _setTotalSupply(totalSupply().sub(amount));
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// solhint-disable

// To simplify Pool logic, all token balances and amounts are normalized to behave as if the token had 18 decimals.
// e.g. When comparing DAI (18 decimals) and USDC (6 decimals), 1 USDC and 1 DAI would both be represented as 1e18,
// whereas without scaling 1 USDC would be represented as 1e6.
// This allows us to not consider differences in token decimals in the internal Pool maths, simplifying it greatly.

// Single Value

/**
 * @dev Applies `scalingFactor` to `amount`, resulting in a larger or equal value depending on whether it needed
 * scaling or not.
 */
function _upscale(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    // Upscale rounding wouldn't necessarily always go in the same direction: in a swap for example the balance of
    // token in should be rounded up, and that of token out rounded down. This is the only place where we round in
    // the same direction for all amounts, as the impact of this rounding is expected to be minimal.
    return FixedPoint.mulDown(amount, scalingFactor);
}

/**
 * @dev Reverses the `scalingFactor` applied to `amount`, resulting in a smaller or equal value depending on
 * whether it needed scaling or not. The result is rounded down.
 */
function _downscaleDown(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    return FixedPoint.divDown(amount, scalingFactor);
}

/**
 * @dev Reverses the `scalingFactor` applied to `amount`, resulting in a smaller or equal value depending on
 * whether it needed scaling or not. The result is rounded up.
 */
function _downscaleUp(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    return FixedPoint.divUp(amount, scalingFactor);
}

// Array

/**
 * @dev Same as `_upscale`, but for an entire array. This function does not return anything, but instead *mutates*
 * the `amounts` array.
 */
function _upscaleArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.mulDown(amounts[i], scalingFactors[i]);
    }
}

/**
 * @dev Same as `_downscaleDown`, but for an entire array. This function does not return anything, but instead
 * *mutates* the `amounts` array.
 */
function _downscaleDownArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.divDown(amounts[i], scalingFactors[i]);
    }
}

/**
 * @dev Same as `_downscaleUp`, but for an entire array. This function does not return anything, but instead
 * *mutates* the `amounts` array.
 */
function _downscaleUpArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.divUp(amounts[i], scalingFactors[i]);
    }
}

function _computeScalingFactor(IERC20 token) view returns (uint256) {
    // Tokens that don't implement the `decimals` method are not supported.
    uint256 tokenDecimals = ERC20(address(token)).decimals();

    // Tokens with more than 18 decimals are not supported.
    uint256 decimalsDifference = Math.sub(18, tokenDecimals);
    return FixedPoint.ONE * 10**decimalsDifference;
}



/**
 * @dev Library for encoding and decoding values stored inside a 256 bit word. Typically used to pack multiple values in
 * a single storage slot, saving gas by performing less storage accesses.
 *
 * Each value is defined by its size and the least significant bit in the word, also known as offset. For example, two
 * 128 bit values may be encoded in a word by assigning one an offset of 0, and the other an offset of 128.
 *
 * We could use Solidity structs to pack values together in a single storage slot instead of relying on a custom and
 * error-prone library, but unfortunately Solidity only allows for structs to live in either storage, calldata or
 * memory. Because a memory struct uses not just memory but also a slot in the stack (to store its memory location),
 * using memory for word-sized values (i.e. of 256 bits or less) is strictly less gas performant, and doesn't even
 * prevent stack-too-deep issues. This is compounded by the fact that Balancer contracts typically are memory-intensive,
 * and the cost of accesing memory increases quadratically with the number of allocated words. Manual packing and
 * unpacking is therefore the preferred approach.
 */
library WordCodec {
    // solhint-disable no-inline-assembly

    // Masks are values with the least significant N bits set. They can be used to extract an encoded value from a word,
    // or to insert a new one replacing the old.
    uint256 private constant _MASK_1 = 2**(1) - 1;
    uint256 private constant _MASK_192 = 2**(192) - 1;

    // In-place insertion

    /**
     * @dev Inserts an unsigned integer of bitLength, shifted by an offset, into a 256 bit word,
     * replacing the old value. Returns the new word.
     */
    function insertUint(
        bytes32 word,
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32 result) {
        _validateEncodingParams(value, offset, bitLength);
        // Equivalent to:
        // uint256 mask = (1 << bitLength) - 1;
        // bytes32 clearedWord = bytes32(uint256(word) & ~(mask << offset));
        // result = clearedWord | bytes32(value << offset);
        assembly {
            let mask := sub(shl(bitLength, 1), 1)
            let clearedWord := and(word, not(shl(offset, mask)))
            result := or(clearedWord, shl(offset, value))
        }
    }

    /**
     * @dev Inserts a signed integer shifted by an offset into a 256 bit word, replacing the old value. Returns
     * the new word.
     *
     * Assumes `value` can be represented using `bitLength` bits.
     */
    function insertInt(
        bytes32 word,
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        uint256 mask = (1 << bitLength) - 1;
        bytes32 clearedWord = bytes32(uint256(word) & ~(mask << offset));
        // Integer values need masking to remove the upper bits of negative values.
        return clearedWord | bytes32((uint256(value) & mask) << offset);
    }

    // Encoding

    /**
     * @dev Encodes an unsigned integer shifted by an offset. Ensures value fits within
     * `bitLength` bits.
     *
     * The return value can be ORed bitwise with other encoded values to form a 256 bit word.
     */
    function encodeUint(
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        return bytes32(value << offset);
    }

    /**
     * @dev Encodes a signed integer shifted by an offset.
     *
     * The return value can be ORed bitwise with other encoded values to form a 256 bit word.
     */
    function encodeInt(
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        uint256 mask = (1 << bitLength) - 1;
        // Integer values need masking to remove the upper bits of negative values.
        return bytes32((uint256(value) & mask) << offset);
    }

    // Decoding

    /**
     * @dev Decodes and returns an unsigned integer with `bitLength` bits, shifted by an offset, from a 256 bit word.
     */
    function decodeUint(
        bytes32 word,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = uint256(word >> offset) & ((1 << bitLength) - 1);
        assembly {
            result := and(shr(offset, word), sub(shl(bitLength, 1), 1))
        }
    }

    /**
     * @dev Decodes and returns a signed integer with `bitLength` bits, shifted by an offset, from a 256 bit word.
     */
    function decodeInt(
        bytes32 word,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (int256 result) {
        int256 maxInt = int256((1 << (bitLength - 1)) - 1);
        uint256 mask = (1 << bitLength) - 1;

        int256 value = int256(uint256(word >> offset) & mask);
        // In case the decoded value is greater than the max positive integer that can be represented with bitLength
        // bits, we know it was originally a negative integer. Therefore, we mask it to restore the sign in the 256 bit
        // representation.
        //
        // Equivalent to:
        // result = value > maxInt ? (value | int256(~mask)) : value;
        assembly {
            result := or(mul(gt(value, maxInt), not(mask)), value)
        }
    }

    // Special cases

    /**
     * @dev Decodes and returns a boolean shifted by an offset from a 256 bit word.
     */
    function decodeBool(bytes32 word, uint256 offset) internal pure returns (bool result) {
        // Equivalent to:
        // result = (uint256(word >> offset) & 1) == 1;
        assembly {
            result := and(shr(offset, word), 1)
        }
    }

    /**
     * @dev Inserts a 192 bit value shifted by an offset into a 256 bit word, replacing the old value.
     * Returns the new word.
     *
     * Assumes `value` can be represented using 192 bits.
     */
    function insertBits192(
        bytes32 word,
        bytes32 value,
        uint256 offset
    ) internal pure returns (bytes32) {
        bytes32 clearedWord = bytes32(uint256(word) & ~(_MASK_192 << offset));
        return clearedWord | bytes32((uint256(value) & _MASK_192) << offset);
    }

    /**
     * @dev Inserts a boolean value shifted by an offset into a 256 bit word, replacing the old value. Returns the new
     * word.
     */
    function insertBool(
        bytes32 word,
        bool value,
        uint256 offset
    ) internal pure returns (bytes32 result) {
        // Equivalent to:
        // bytes32 clearedWord = bytes32(uint256(word) & ~(1 << offset));
        // bytes32 referenceInsertBool = clearedWord | bytes32(uint256(value ? 1 : 0) << offset);
        assembly {
            let clearedWord := and(word, not(shl(offset, 1)))
            result := or(clearedWord, shl(offset, value))
        }
    }

    // Helpers

    function _validateEncodingParams(
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) private pure {
        _require(offset < 256, Errors.OUT_OF_BOUNDS);
        // We never accept 256 bit values (which would make the codec pointless), and the larger the offset the smaller
        // the maximum bit length.
        _require(bitLength >= 1 && bitLength <= Math.min(255, 256 - offset), Errors.OUT_OF_BOUNDS);

        // Testing unsigned values for size is straightforward: their upper bits must be cleared.
        _require(value >> bitLength == 0, Errors.CODEC_OVERFLOW);
    }

    function _validateEncodingParams(
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) private pure {
        _require(offset < 256, Errors.OUT_OF_BOUNDS);
        // We never accept 256 bit values (which would make the codec pointless), and the larger the offset the smaller
        // the maximum bit length.
        _require(bitLength >= 1 && bitLength <= Math.min(255, 256 - offset), Errors.OUT_OF_BOUNDS);

        // Testing signed values for size is a bit more involved.
        if (value >= 0) {
            // For positive values, we can simply check that the upper bits are clear. Notice we remove one bit from the
            // length for the sign bit.
            _require(value >> (bitLength - 1) == 0, Errors.CODEC_OVERFLOW);
        } else {
            // Negative values can receive the same treatment by making them positive, with the caveat that the range
            // for negative values in two's complement supports one more value than for the positive case.
            _require(Math.abs(value + 1) >> (bitLength - 1) == 0, Errors.CODEC_OVERFLOW);
        }
    }
}

library ExternalFees {
    using FixedPoint for uint256;

    /**
     * @dev Calculates the amount of BPT necessary to give ownership of a given percentage of the Pool to an external
     * third party. In the case of protocol fees, this is the DAO, but could also be a pool manager, etc.
     * Note that this function reverts if `poolPercentage` >= 100%, it's expected that the caller will enforce this.
     * @param totalSupply - The total supply of the pool prior to minting BPT.
     * @param poolOwnershipPercentage - The desired ownership percentage of the pool to have as a result of minting BPT.
     * @return bptAmount - The amount of BPT to mint such that it is `poolPercentage` of the resultant total supply.
     */
    function bptForPoolOwnershipPercentage(uint256 totalSupply, uint256 poolOwnershipPercentage)
        internal
        pure
        returns (uint256)
    {
        // If we mint some amount `bptAmount` of BPT then the percentage ownership of the pool this grants is given by:
        // `poolOwnershipPercentage = bptAmount / (totalSupply + bptAmount)`.
        // Solving for `bptAmount`, we arrive at:
        // `bptAmount = totalSupply * poolOwnershipPercentage / (1 - poolOwnershipPercentage)`.
        return Math.divDown(Math.mul(totalSupply, poolOwnershipPercentage), poolOwnershipPercentage.complement());
    }
}

library InvariantGrowthProtocolSwapFees {
    using FixedPoint for uint256;

    function getProtocolOwnershipPercentage(
        uint256 invariantGrowthRatio,
        uint256 supplyGrowthRatio,
        uint256 protocolSwapFeePercentage
    ) internal pure returns (uint256) {
        // Joins and exits are symmetrical; for simplicity, we consider a join, where the invariant and supply
        // both increase.

        // |-------------------------|-- original invariant * invariantGrowthRatio
        // |   increase from fees    |
        // |-------------------------|-- original invariant * supply growth ratio (fee-less invariant)
        // |                         |
        // | increase from balances  |
        // |-------------------------|-- original invariant
        // |                         |
        // |                         |  |------------------|-- currentSupply
        // |                         |  |    BPT minted    |
        // |                         |  |------------------|-- previousSupply
        // |   original invariant    |  |  original supply |
        // |_________________________|  |__________________|
        //
        // If the join is proportional, the invariant and supply will likewise increase proportionally,
        // so the growth ratios (invariantGrowthRatio / supplyGrowthRatio) will be equal. In this case, we do not charge
        // any protocol fees.
        // We also charge no protocol fees in the case where `invariantGrowthRatio < supplyGrowthRatio` to avoid
        // potential underflows, however this should only occur in extremely low volume actions due solely to rounding
        // error.

        if ((supplyGrowthRatio >= invariantGrowthRatio) || (protocolSwapFeePercentage == 0)) return 0;

        // If the join is non-proportional, the supply increase will be proportionally less than the invariant increase,
        // since the BPT minted will be based on fewer tokens (because swap fees are not included). So the supply growth
        // is due entirely to the balance changes, while the invariant growth also includes swap fees.
        //
        // To isolate the amount of increase by fees then, we multiply the original invariant by the supply growth
        // ratio to get the "feeless invariant". The difference between the final invariant and this value is then
        // the amount of the invariant due to fees, which we convert to a percentage by normalizing against the
        // final invariant. This is expressed as the expression below:
        //
        // invariantGrowthFromFees = currentInvariant - supplyGrowthRatio * previousInvariant
        //
        // We then divide through by current invariant so the LHS can be identified as the fraction of the pool which
        // is made up of accumulated swap fees.
        //
        // swapFeesPercentage = 1 - supplyGrowthRatio * previousInvariant / currentInvariant
        //
        // We then define `invariantGrowthRatio` in a similar fashion to `supplyGrowthRatio` to give the result:
        //
        // swapFeesPercentage = 1 - supplyGrowthRatio / invariantGrowthRatio
        //
        // Using this form allows us to consider only the ratios of the two invariants, rather than their absolute
        // values: a useful property, as this is sometimes easier than calculating the full invariant twice.

        // We've already checked that `supplyGrowthRatio` is smaller than `invariantGrowthRatio`, and hence their ratio
        // smaller than FixedPoint.ONE, allowing for unchecked arithmetic.
        uint256 swapFeesPercentage = FixedPoint.ONE - supplyGrowthRatio.divDown(invariantGrowthRatio);

        // We then multiply by the protocol swap fee percentage to get the fraction of the pool which the protocol
        // should own once fees have been collected.
        return swapFeesPercentage.mulDown(protocolSwapFeePercentage);
    }

    function calcDueProtocolFees(
        uint256 invariantGrowthRatio,
        uint256 previousSupply,
        uint256 currentSupply,
        uint256 protocolSwapFeePercentage
    ) internal pure returns (uint256) {
        uint256 protocolOwnershipPercentage = getProtocolOwnershipPercentage(
            invariantGrowthRatio,
            currentSupply.divDown(previousSupply),
            protocolSwapFeePercentage
        );

        return ExternalFees.bptForPoolOwnershipPercentage(currentSupply, protocolOwnershipPercentage);
    }
}



/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        _require(value >> 255 == 0, Errors.SAFE_CAST_VALUE_CANT_FIT_INT256);
        return int256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into an unsigned uint64.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxUint64.
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        _require(value <= type(uint64).max, Errors.SAFE_CAST_VALUE_CANT_FIT_UINT64);
        return uint64(value);
    }
}





library BasePoolUserData {
    // Special ExitKind for all pools, used in Recovery Mode. Use the max 8-bit value to prevent conflicts
    // with future additions to the ExitKind enums (or any front-end code that maps to existing values)
    uint8 public constant RECOVERY_MODE_EXIT_KIND = 255;

    // Return true if this is the special exit kind.
    function isRecoveryModeExitKind(bytes memory self) internal pure returns (bool) {
        // Check for the "no data" case, or abi.decode would revert
        return self.length > 0 && abi.decode(self, (uint8)) == RECOVERY_MODE_EXIT_KIND;
    }

    // Parse the bptAmountIn out of the userData
    function recoveryModeExit(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (uint8, uint256));
    }
}



/**
 * @dev Interface for the RecoveryMode module.
 */
interface IRecoveryMode {
    /**
     * @dev Emitted when the Recovery Mode status changes.
     */
    event RecoveryModeStateChanged(bool enabled);

    /**
     * @notice Enables Recovery Mode in the Pool, disabling protocol fee collection and allowing for safe proportional
     * exits with low computational complexity and no dependencies.
     */
    function enableRecoveryMode() external;

    /**
     * @notice Disables Recovery Mode in the Pool, restoring protocol fee collection and disallowing proportional exits.
     */
    function disableRecoveryMode() external;

    /**
     * @notice Returns true if the Pool is in Recovery Mode.
     */
    function inRecoveryMode() external view returns (bool);
}


/**
 * @dev Base authorization layer implementation for Pools.
 *
 * The owner account can call some of the permissioned functions - access control of the rest is delegated to the
 * Authorizer. Note that this owner is immutable: more sophisticated permission schemes, such as multiple ownership,
 * granular roles, etc., could be built on top of this by making the owner a smart contract.
 *
 * Access control of all other permissioned functions is delegated to an Authorizer. It is also possible to delegate
 * control of *all* permissioned functions to the Authorizer by setting the owner address to `_DELEGATE_OWNER`.
 */
abstract contract BasePoolAuthorization is Authentication {
    address private immutable _owner;

    address internal constant _DELEGATE_OWNER = 0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B;

    constructor(address owner) {
        _owner = owner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        if ((getOwner() != _DELEGATE_OWNER) && _isOwnerOnlyAction(actionId)) {
            // Only the owner can perform "owner only" actions, unless the owner is delegated.
            return msg.sender == getOwner();
        } else {
            // Non-owner actions are always processed via the Authorizer, as "owner only" ones are when delegated.
            return _getAuthorizer().canPerform(actionId, account, address(this));
        }
    }

    function _isOwnerOnlyAction(bytes32) internal view virtual returns (bool) {
        return false;
    }

    function _getAuthorizer() internal view virtual returns (IAuthorizer);
}

/**
 * @notice Handle storage and state changes for pools that support "Recovery Mode".
 *
 * @dev This is intended to provide a safe way to exit any pool during some kind of emergency, to avoid locking funds
 * in the event the pool enters a non-functional state (i.e., some code that normally runs during exits is causing
 * them to revert).
 *
 * Recovery Mode is *not* the same as pausing the pool. The pause function is only available during a short window
 * after factory deployment. Pausing can only be intentionally reversed during a buffer period, and the contract
 * will permanently unpause itself thereafter. Paused pools are completely disabled, in a kind of suspended animation,
 * until they are voluntarily or involuntarily unpaused.
 *
 * By contrast, a privileged account - typically a governance multisig - can place a pool in Recovery Mode at any
 * time, and it is always reversible. The pool is *not* disabled while in this mode: though of course whatever
 * condition prompted the transition to Recovery Mode has likely effectively disabled some functions. Rather,
 * a special "clean" exit is enabled, which runs the absolute minimum code necessary to exit proportionally.
 * In particular, stable pools do not attempt to compute the invariant (which is a complex, iterative calculation
 * that can fail in extreme circumstances), and no protocol fees are collected.
 *
 * It is critical to ensure that turning on Recovery Mode would do no harm, if activated maliciously or in error.
 */
abstract contract RecoveryMode is IRecoveryMode, BasePoolAuthorization {
    using FixedPoint for uint256;
    using BasePoolUserData for bytes;

    /**
     * @dev Reverts if the contract is in Recovery Mode.
     */
    modifier whenNotInRecoveryMode() {
        _ensureNotInRecoveryMode();
        _;
    }

    /**
     * @notice Enable recovery mode, which enables a special safe exit path for LPs.
     * @dev Does not otherwise affect pool operations (beyond deferring payment of protocol fees), though some pools may
     * perform certain operations in a "safer" manner that is less likely to fail, in an attempt to keep the pool
     * running, even in a pathological state. Unlike the Pause operation, which is only available during a short window
     * after factory deployment, Recovery Mode can always be enabled.
     */
    function enableRecoveryMode() external override authenticate {
        // Unlike when recovery mode is disabled, derived contracts should *not* do anything when it is enabled.
        // We do not want to make any calls that could fail and prevent the pool from entering recovery mode.
        // Accordingly, this should have no effect, but for consistency with `disableRecoveryMode`, revert if
        // recovery mode was already enabled.
        _ensureNotInRecoveryMode();

        _setRecoveryMode(true);

        emit RecoveryModeStateChanged(true);
    }

    /**
     * @notice Disable recovery mode, which disables the special safe exit path for LPs.
     * @dev Protocol fees are not paid while in Recovery Mode, so it should only remain active for as long as strictly
     * necessary.
     */
    function disableRecoveryMode() external override authenticate {
        // Some derived contracts respond to disabling recovery mode with state changes (e.g., related to protocol fees,
        // or otherwise ensuring that enabling and disabling recovery mode has no ill effects on LPs). When called
        // outside of recovery mode, these state changes might lead to unexpected behavior.
        _ensureInRecoveryMode();

        _setRecoveryMode(false);

        emit RecoveryModeStateChanged(false);
    }

    // Defer implementation for functions that require storage

    /**
     * @notice Override to check storage and return whether the pool is in Recovery Mode
     */
    function inRecoveryMode() public view virtual override returns (bool);

    /**
     * @dev Override to update storage and emit the event
     *
     * No complex code or external calls that could fail should be placed in the implementations,
     * which could jeopardize the ability to enable and disable Recovery Mode.
     */
    function _setRecoveryMode(bool enabled) internal virtual;

    /**
     * @dev Reverts if the contract is not in Recovery Mode.
     */
    function _ensureInRecoveryMode() internal view {
        _require(inRecoveryMode(), Errors.NOT_IN_RECOVERY_MODE);
    }

    /**
     * @dev Reverts if the contract is in Recovery Mode.
     */
    function _ensureNotInRecoveryMode() internal view {
        _require(!inRecoveryMode(), Errors.IN_RECOVERY_MODE);
    }

    /**
     * @dev A minimal proportional exit, suitable as is for most pools: though not for pools with preminted BPT
     * or other special considerations. Designed to be overridden if a pool needs to do extra processing,
     * such as scaling a stored invariant, or caching the new total supply.
     *
     * No complex code or external calls should be made in derived contracts that override this!
     */
    function _doRecoveryModeExit(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) internal virtual returns (uint256, uint256[] memory);
}

/**
 * @dev The Vault does not provide the protocol swap fee percentage in swap hooks (as swaps don't typically need this
 * value), so for swaps that need this value, we would have to to fetch it ourselves from the
 * ProtocolFeePercentagesProvider. Additionally, other protocol fee types (such as Yield or AUM) can only be obtained
 * by making said call.
 *
 * However, these values change so rarely that it doesn't make sense to perform the required calls to get the current
 * values in every single user interaction. Instead, we keep a local copy that can be permissionlessly updated by anyone
 * with the real value. We also pack these values together, performing a single storage read to get them all.
 */
abstract contract ProtocolFeeCache is RecoveryMode {
    using SafeCast for uint256;
    using WordCodec for bytes32;

    // Protocol Fee IDs represent fee types; we are supporting 3 types (join, yield and aum), so 8 bits is enough to
    // store each of them.
    // [ 232 bits |   8 bits   |    8 bits    |    8 bits   ]
    // [  unused  | AUM fee ID | Yield fee ID | Swap fee ID ]
    // [MSB                                              LSB]
    uint256 private constant _FEE_TYPE_ID_WIDTH = 8;
    uint256 private constant _SWAP_FEE_ID_OFFSET = 0;
    uint256 private constant _YIELD_FEE_ID_OFFSET = _SWAP_FEE_ID_OFFSET + _FEE_TYPE_ID_WIDTH;
    uint256 private constant _AUM_FEE_ID_OFFSET = _YIELD_FEE_ID_OFFSET + _FEE_TYPE_ID_WIDTH;

    // Protocol Fee Percentages can never be larger than 100% (1e18), which fits in ~59 bits, so using 64 for each type
    // is sufficient.
    // [  64 bits |    64 bits    |     64 bits     |     64 bits    ]
    // [  unused  | AUM fee cache | Yield fee cache | Swap fee cache ]
    // [MSB                                                       LSB]
    uint256 private constant _FEE_TYPE_CACHE_WIDTH = 64;
    uint256 private constant _SWAP_FEE_OFFSET = 0;
    uint256 private constant _YIELD_FEE_OFFSET = _SWAP_FEE_OFFSET + _FEE_TYPE_CACHE_WIDTH;
    uint256 private constant _AUM_FEE_OFFSET = _YIELD_FEE_OFFSET + _FEE_TYPE_CACHE_WIDTH;

    event ProtocolFeePercentageCacheUpdated(bytes32 feeCache);

    /**
     * @dev Protocol fee types can be set at contract creation. Fee IDs store which of the IDs in the protocol fee
     * provider shall be applied to its respective fee type (swap, yield, aum).
     * This is because some Pools may have different protocol fee values for the same type of underlying operation:
     * for example, Stable Pools might have a different swap protocol fee than Weighted Pools.
     * This module does not check at all that the chosen fee types have any sort of relation with the operation they're
     * assigned to: it is possible to e.g. set a Pool's swap protocol fee to equal the flash loan protocol fee.
     */
    struct ProviderFeeIDs {
        uint256 swap;
        uint256 yield;
        uint256 aum;
    }

    IProtocolFeePercentagesProvider private immutable _protocolFeeProvider;
    bytes32 private immutable _feeIds;

    bytes32 private _feeCache;

    constructor(IProtocolFeePercentagesProvider protocolFeeProvider, ProviderFeeIDs memory providerFeeIDs) {
        _protocolFeeProvider = protocolFeeProvider;

        bytes32 feeIds = WordCodec.encodeUint(providerFeeIDs.swap, _SWAP_FEE_ID_OFFSET, _FEE_TYPE_ID_WIDTH) |
            WordCodec.encodeUint(providerFeeIDs.yield, _YIELD_FEE_ID_OFFSET, _FEE_TYPE_ID_WIDTH) |
            WordCodec.encodeUint(providerFeeIDs.aum, _AUM_FEE_ID_OFFSET, _FEE_TYPE_ID_WIDTH);

        _feeIds = feeIds;

        _updateProtocolFeeCache(protocolFeeProvider, feeIds);
    }

    /**
     * @notice Returns the cached protocol fee percentage.
     */
    function getProtocolFeePercentageCache(uint256 feeType) public view returns (uint256) {
        if (inRecoveryMode()) {
            return 0;
        }

        uint256 offset;
        if (feeType == ProtocolFeeType.SWAP) {
            offset = _SWAP_FEE_OFFSET;
        } else if (feeType == ProtocolFeeType.YIELD) {
            offset = _YIELD_FEE_OFFSET;
        } else if (feeType == ProtocolFeeType.AUM) {
            offset = _AUM_FEE_OFFSET;
        } else {
            _revert(Errors.UNHANDLED_FEE_TYPE);
        }

        return _feeCache.decodeUint(offset, _FEE_TYPE_CACHE_WIDTH);
    }

    /**
     * @notice Returns the provider fee ID for the given fee type.
     */
    function getProviderFeeId(uint256 feeType) public view returns (uint256) {
        uint256 offset;

        if (feeType == ProtocolFeeType.SWAP) {
            offset = _SWAP_FEE_ID_OFFSET;
        } else if (feeType == ProtocolFeeType.YIELD) {
            offset = _YIELD_FEE_ID_OFFSET;
        } else if (feeType == ProtocolFeeType.AUM) {
            offset = _AUM_FEE_ID_OFFSET;
        } else {
            _revert(Errors.UNHANDLED_FEE_TYPE);
        }

        return _feeIds.decodeUint(offset, _FEE_TYPE_ID_WIDTH);
    }

    /**
     * @notice Updates the cache to the latest value set by governance.
     * @dev Can be called by anyone to update the cached fee percentages.
     */
    function updateProtocolFeePercentageCache() external {
        _beforeProtocolFeeCacheUpdate();

        _updateProtocolFeeCache(_protocolFeeProvider, _feeIds);
    }

    /**
     * @dev Override in derived contracts to perform some action before the cache is updated. This is typically relevant
     * to Pools that incur protocol debt between operations. To avoid altering the amount due retroactively, this debt
     * needs to be paid before the fee percentages change.
     */
    function _beforeProtocolFeeCacheUpdate() internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _updateProtocolFeeCache(IProtocolFeePercentagesProvider protocolFeeProvider, bytes32 feeIds) private {
        uint256 swapFee = protocolFeeProvider.getFeeTypePercentage(
            feeIds.decodeUint(_SWAP_FEE_ID_OFFSET, _FEE_TYPE_ID_WIDTH)
        );
        uint256 yieldFee = protocolFeeProvider.getFeeTypePercentage(
            feeIds.decodeUint(_YIELD_FEE_ID_OFFSET, _FEE_TYPE_ID_WIDTH)
        );
        uint256 aumFee = protocolFeeProvider.getFeeTypePercentage(
            feeIds.decodeUint(_AUM_FEE_ID_OFFSET, _FEE_TYPE_ID_WIDTH)
        );

        bytes32 feeCache = WordCodec.encodeUint(swapFee, _SWAP_FEE_OFFSET, _FEE_TYPE_CACHE_WIDTH) |
            WordCodec.encodeUint(yieldFee, _YIELD_FEE_OFFSET, _FEE_TYPE_CACHE_WIDTH) |
            WordCodec.encodeUint(aumFee, _AUM_FEE_OFFSET, _FEE_TYPE_CACHE_WIDTH);

        _feeCache = feeCache;

        emit ProtocolFeePercentageCacheUpdated(feeCache);
    }
}



library ExternalAUMFees {
    /**
     * @notice Calculates the amount of BPT to mint to pay AUM fees accrued since the last collection.
     * @dev This calculation assumes that the Pool's total supply is constant over the fee period.
     *
     * When paying AUM fees over short durations, significant rounding errors can be introduced when converting from a
     * percentage of the pool to a BPT amount. To combat this, we convert the yearly percentage to BPT and then scale
     * appropriately.
     */
    function getAumFeesBptAmount(
        uint256 totalSupply,
        uint256 currentTime,
        uint256 lastCollection,
        uint256 annualAumFeePercentage
    ) internal pure returns (uint256) {
        // If no time has passed since the last collection then clearly no fees are accrued so we can return early.
        // We also perform an early return if the AUM fee is zero.
        if (currentTime <= lastCollection || annualAumFeePercentage == 0) return 0;

        uint256 annualBptAmount = ExternalFees.bptForPoolOwnershipPercentage(totalSupply, annualAumFeePercentage);

        // We want to collect fees so that after a year the Pool will have paid `annualAumFeePercentage` of its AUM as
        // fees. In normal operation however, we will collect fees regularly over the course of the year so we
        // multiply `annualBptAmount` by the fraction of the year which has elapsed since we last collected fees.
        uint256 elapsedTime = currentTime - lastCollection;

        // As an example for this calculate, consider a pool with a total supply of 1000e18 BPT, AUM fees are charged
        // at 5% yearly and it's been 7 days since the last collection of AUM fees. The expected fees are then:
        //
        // expected_yearly_fees = totalSupply * annualAumFeePercentage / (1 - annualAumFeePercentage)
        //                      = 1000e18 * 0.05 / 0.95
        //                      ~= 52.63e18 BPT
        //
        // fees_to_collect = expected_yearly_fees * time_since_last_collection / 1 year
        //                 = 52.63e18 * 7 / 365
        //                 ~= 1.009 BPT
        //
        // Note that if we were to mint expected_yearly_fees BPT then the recipient would own 52.63e18 out of
        // 1052.63e18 BPT. This agrees with the recipient being expected to own 5% of the Pool *after* fees are paid.

        // Like with all other fees, we round down, favoring LPs.
        // return Math.divDown(Math.mul(annualBptAmount, elapsedTime), 365 days);
        // Note JB/WINR will never charge AUM fees to the LPs
        return 0;
    }
}

interface IGeneralPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amount);
}



/**
 * @dev Pool contracts with the MinimalSwapInfo or TwoToken specialization settings should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will grant
 * to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);
}



/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    // solc-ignore-next-line func-mutability
    function _getChainId() private view returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

/**
 * @dev Utility for signing Solidity function calls.
 */
abstract contract EOASignaturesValidator is ISignaturesValidator, EIP712 {
    // Replay attack prevention for each account.
    mapping(address => uint256) internal _nextNonce;

    function getDomainSeparator() public view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getNextNonce(address account) public view override returns (uint256) {
        return _nextNonce[account];
    }

    function _ensureValidSignature(
        address account,
        bytes32 structHash,
        bytes memory signature,
        uint256 errorCode
    ) internal {
        return _ensureValidSignature(account, structHash, signature, type(uint256).max, errorCode);
    }

    function _ensureValidSignature(
        address account,
        bytes32 structHash,
        bytes memory signature,
        uint256 deadline,
        uint256 errorCode
    ) internal {
        bytes32 digest = _hashTypedDataV4(structHash);
        _require(_isValidSignature(account, digest, signature), errorCode);

        // We could check for the deadline before validating the signature, but this leads to saner error processing (as
        // we only care about expired deadlines if the signature is correct) and only affects the gas cost of the revert
        // scenario, which will only occur infrequently, if ever.
        // The deadline is timestamp-based: it should not be relied upon for sub-minute accuracy.
        // solhint-disable-next-line not-rely-on-time
        _require(deadline >= block.timestamp, Errors.EXPIRED_SIGNATURE);

        // We only advance the nonce after validating the signature. This is irrelevant for this module, but it can be
        // important in derived contracts that override _isValidSignature (e.g. SignaturesValidator), as we want for
        // the observable state to still have the current nonce as the next valid one.
        _nextNonce[account] += 1;
    }

    function _isValidSignature(
        address account,
        bytes32 digest,
        bytes memory signature
    ) internal view virtual returns (bool) {
        _require(signature.length == 65, Errors.MALFORMED_SIGNATURE);

        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the r, s and v signature parameters, and the only way to get them is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        address recoveredAddress = ecrecover(digest, v, r, s);

        // ecrecover returns the zero address on recover failure, so we need to handle that explicitly.
        return (recoveredAddress != address(0) && recoveredAddress == account);
    }

    function _toArraySignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        bytes memory signature = new bytes(65);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(signature, 32), r)
            mstore(add(signature, 64), s)
            mstore8(add(signature, 96), v)
        }

        return signature;
    }
}

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EOASignaturesValidator {
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, getNextNonce(owner), deadline)
        );

        _ensureValidSignature(owner, structHash, _toArraySignature(v, r, s), deadline, Errors.INVALID_SIGNATURE);

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return getNextNonce(owner);
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return getDomainSeparator();
    }
}

/**
 * @title Highly opinionated token implementation
 * @author Balancer Labs
 * @dev
 * - Includes functions to increase and decrease allowance as a workaround
 *   for the well-known issue with `approve`:
 *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * - Allows for 'infinite allowance', where an allowance of 0xff..ff is not
 *   decreased by calls to transferFrom
 * - Lets a token holder use `transferFrom` to send their own tokens,
 *   without first setting allowance
 * - Emits 'Approval' events whenever allowance is changed by `transferFrom`
 * - Assigns infinite allowance for all token holders to the Vault
 */
contract BalancerPoolToken is ERC20Permit {
    IVault private immutable _vault;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        IVault vault
    ) ERC20(tokenName, tokenSymbol) ERC20Permit(tokenName) {
        _vault = vault;
    }

    function getVault() public view returns (IVault) {
        return _vault;
    }

    // Overrides

    /**
     * @dev Override to grant the Vault infinite allowance, causing for Pool Tokens to not require approval.
     *
     * This is sound as the Vault already provides authorization mechanisms when initiation token transfers, which this
     * contract inherits.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        if (spender == address(getVault())) {
            return uint256(-1);
        } else {
            return super.allowance(owner, spender);
        }
    }

    /**
     * @dev Override to allow for 'infinite allowance' and let the token owner use `transferFrom` with no self-allowance
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        _require(msg.sender == sender || currentAllowance >= amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE);

        _transfer(sender, recipient, amount);

        if (msg.sender != sender && currentAllowance != uint256(-1)) {
            // Because of the previous require, we know that if msg.sender != sender then currentAllowance >= amount
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Override to allow decreasing allowance by more than the current amount (setting it to zero)
     */
    function decreaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);

        if (amount >= currentAllowance) {
            _approve(msg.sender, spender, 0);
        } else {
            // No risk of underflow due to if condition
            _approve(msg.sender, spender, currentAllowance - amount);
        }

        return true;
    }

    // Internal functions

    function _mintPoolTokens(address recipient, uint256 amount) internal {
        _mint(recipient, amount);
    }

    function _burnPoolTokens(address sender, uint256 amount) internal {
        _burn(sender, amount);
    }
}

// solhint-disable max-states-count

/**
 * @notice Reference implementation for the base layer of a Pool contract.
 * @dev Reference implementation for the base layer of a Pool contract that manages a single Pool with optional
 * Asset Managers, an admin-controlled swap fee percentage, and an emergency pause mechanism.
 *
 * This Pool pays protocol fees by minting BPT directly to the ProtocolFeeCollector instead of using the
 * `dueProtocolFees` return value. This results in the underlying tokens continuing to provide liquidity
 * for traders, while still keeping gas usage to a minimum since only a single token (the BPT) is transferred.
 *
 * Note that neither swap fees nor the pause mechanism are used by this contract. They are passed through so that
 * derived contracts can use them via the `_addSwapFeeAmount` and `_subtractSwapFeeAmount` functions, and the
 * `whenNotPaused` modifier.
 *
 * No admin permissions are checked here: instead, this contract delegates that to the Vault's own Authorizer.
 *
 * Because this contract doesn't implement the swap hooks, derived contracts should generally inherit from
 * BaseGeneralPool or BaseMinimalSwapInfoPool. Otherwise, subclasses must inherit from the corresponding interfaces
 * and implement the swap callbacks themselves.
 */
abstract contract BasePool is
    IBasePool,
    IGeneralPool,
    IMinimalSwapInfoPool,
    BasePoolAuthorization,
    BalancerPoolToken,
    TemporarilyPausable,
    RecoveryMode
{
    using BasePoolUserData for bytes;

    uint256 private constant _DEFAULT_MINIMUM_BPT = 1e6;

    bytes32 private immutable _poolId;

    // Note that this value is immutable in the Vault, so we can make it immutable here and save gas
    IProtocolFeesCollector private immutable _protocolFeesCollector;

    constructor(
        IVault vault,
        bytes32 poolId,
        string memory name,
        string memory symbol,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    )
        // Base Pools are expected to be deployed using factories. By using the factory address as the action
        // disambiguator, we make all Pools deployed by the same factory share action identifiers. This allows for
        // simpler management of permissions (such as being able to manage granting the 'set fee percentage' action in
        // any Pool created by the same factory), while still making action identifiers unique among different factories
        // if the selectors match, preventing accidental errors.
        Authentication(bytes32(uint256(msg.sender)))
        BalancerPoolToken(name, symbol, vault)
        BasePoolAuthorization(owner)
        TemporarilyPausable(pauseWindowDuration, bufferPeriodDuration)
    {
        // Set immutable state variables - these cannot be read from during construction
        _poolId = poolId;
        _protocolFeesCollector = vault.getProtocolFeesCollector();
    }

    // Getters

    /**
     * @notice Return the pool id.
     */
    function getPoolId() public view override returns (bytes32) {
        return _poolId;
    }

    function _getAuthorizer() internal view override returns (IAuthorizer) {
        // Access control management is delegated to the Vault's Authorizer. This lets Balancer Governance manage which
        // accounts can call permissioned functions: for example, to perform emergency pauses.
        // If the owner is delegated, then *all* permissioned functions, including `updateSwapFeeGradually`, will be
        // under Governance control.
        return getVault().getAuthorizer();
    }

    /**
     * @dev Returns the minimum BPT supply. This amount is minted to the zero address during initialization, effectively
     * locking it.
     *
     * This is useful to make sure Pool initialization happens only once, but derived Pools can change this value (even
     * to zero) by overriding this function.
     */
    function _getMinimumBpt() internal pure returns (uint256) {
        return _DEFAULT_MINIMUM_BPT;
    }

    // Protocol Fees

    /**
     * @notice Return the ProtocolFeesCollector contract.
     * @dev This is immutable, and retrieved from the Vault on construction. (It is also immutable in the Vault.)
     */
    function getProtocolFeesCollector() public view returns (IProtocolFeesCollector) {
        return _protocolFeesCollector;
    }

    /**
     * @dev Pays protocol fees by minting `bptAmount` to the Protocol Fee Collector.
     */
    // function _payProtocolFees(uint256 bptAmount) internal {
    //     if (bptAmount > 0) {
    //         _mintPoolTokens(address(getProtocolFeesCollector()), bptAmount);
    //     }
    // }

    /**
     * @notice Pause the pool: an emergency action which disables all pool functions.
     * @dev This is a permissioned function that will only work during the Pause Window set during pool factory
     * deployment (see `TemporarilyPausable`).
     */
    function pause() external authenticate {
        _setPaused(true);
    }

    /**
     * @notice Reverse a `pause` operation, and restore a pool to normal functionality.
     * @dev This is a permissioned function that will only work on a paused pool within the Buffer Period set during
     * pool factory deployment (see `TemporarilyPausable`). Note that any paused pools will automatically unpause
     * after the Buffer Period expires.
     */
    function unpause() external authenticate {
        _setPaused(false);
    }

    modifier onlyVault(bytes32 poolId) {
        _require(msg.sender == address(getVault()), Errors.CALLER_NOT_VAULT);
        _require(poolId == getPoolId(), Errors.INVALID_POOL_ID);
        _;
    }

    // Swap / Join / Exit Hooks

    function onSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) external override onlyVault(request.poolId) returns (uint256) {
        _ensureNotPaused();

        return _onSwapMinimal(request, balanceTokenIn, balanceTokenOut);
    }

    function _onSwapMinimal(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal virtual returns (uint256);

    function onSwap(
        SwapRequest memory request,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external override onlyVault(request.poolId) returns (uint256) {
        _ensureNotPaused();

        return _onSwapGeneral(request, balances, indexIn, indexOut);
    }

    function _onSwapGeneral(
        SwapRequest memory request,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) internal virtual returns (uint256);

    /**
     * @notice Vault hook for adding liquidity to a pool (including the first time, "initializing" the pool).
     * @dev This function can only be called from the Vault, from `joinPool`.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override onlyVault(poolId) returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFees) {
        uint256 bptAmountOut;

        _ensureNotPaused();
        if (totalSupply() == 0) {
            (bptAmountOut, amountsIn) = _onInitializePool(sender, userData);

            // On initialization, we lock _getMinimumBpt() by minting it for the zero address. This BPT acts as a
            // minimum as it will never be burned, which reduces potential issues with rounding, and also prevents the
            // Pool from ever being fully drained.
            _require(bptAmountOut >= _getMinimumBpt(), Errors.MINIMUM_BPT);
            _mintPoolTokens(address(0), _getMinimumBpt());
            _mintPoolTokens(recipient, bptAmountOut - _getMinimumBpt());
        } else {
            (bptAmountOut, amountsIn) = _onJoinPool(sender, balances, userData);

            // Note we no longer use `balances` after calling `_onJoinPool`, which may mutate it.

            _mintPoolTokens(recipient, bptAmountOut);
        }

        // This Pool ignores the `dueProtocolFees` return value, so we simply return a zeroed-out array.
        dueProtocolFees = new uint256[](amountsIn.length);
    }

    /**
     * @notice Vault hook for removing liquidity from a pool.
     * @dev This function can only be called from the Vault, from `exitPool`.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override onlyVault(poolId) returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFees) {
        uint256 bptAmountIn;

        // When a user calls `exitPool`, this is the first point of entry from the Vault.
        // We first check whether this is a Recovery Mode exit - if so, we proceed using this special lightweight exit
        // mechanism which avoids computing any complex values, interacting with external contracts, etc., and generally
        // should always work, even if the Pool's mathematics or a dependency break down.
        if (userData.isRecoveryModeExitKind()) {
            // This exit kind is only available in Recovery Mode.
            _ensureInRecoveryMode();

            // Note that we don't upscale balances nor downscale amountsOut - we don't care about scaling factors during
            // a recovery mode exit.
            (bptAmountIn, amountsOut) = _doRecoveryModeExit(balances, totalSupply(), userData);
        } else {
            // Note that we only call this if we're not in a recovery mode exit.
            _ensureNotPaused();

            (bptAmountIn, amountsOut) = _onExitPool(sender, balances, userData);
        }

        // Note we no longer use `balances` after calling `_onExitPool`, which may mutate it.

        _burnPoolTokens(sender, bptAmountIn);

        // This Pool ignores the `dueProtocolFees` return value, so we simply return a zeroed-out array.
        dueProtocolFees = new uint256[](amountsOut.length);
    }

    // Query functions

    /**
     * @notice "Dry run" `onJoinPool`.
     * @dev Returns the amount of BPT that would be granted to `recipient` if the `onJoinPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `sender` would have to supply.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
    function queryJoin(
        bytes32,
        address sender,
        address,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override returns (uint256 bptOut, uint256[] memory amountsIn) {
        _queryAction(sender, balances, userData, _onJoinPool);

        // The `return` opcode is executed directly inside `_queryAction`, so execution never reaches this statement,
        // and we don't need to return anything here - it just silences compiler warnings.
        return (bptOut, amountsIn);
    }

    /**
     * @notice "Dry run" `onExitPool`.
     * @dev Returns the amount of BPT that would be burned from `sender` if the `onExitPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `recipient` would receive.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
    function queryExit(
        bytes32,
        address sender,
        address,
        uint256[] memory balances,
        uint256,
        uint256,
        bytes memory userData
    ) external override returns (uint256 bptIn, uint256[] memory amountsOut) {
        _queryAction(sender, balances, userData, _onExitPool);

        // The `return` opcode is executed directly inside `_queryAction`, so execution never reaches this statement,
        // and we don't need to return anything here - it just silences compiler warnings.
        return (bptIn, amountsOut);
    }

    // Internal hooks to be overridden by derived contracts - all token amounts (except BPT) in these interfaces are
    // upscaled.

    /**
     * @dev Called when the Pool is joined for the first time; that is, when the BPT total supply is zero.
     *
     * Returns the amount of BPT to mint, and the token amounts the Pool will receive in return.
     *
     * Minted BPT will be sent to `recipient`, except for _getMinimumBpt(), which will be deducted from this amount and
     * sent to the zero address instead. This will cause that BPT to remain forever locked there, preventing total BTP
     * from ever dropping below that value, and ensuring `_onInitializePool` can only be called once in the entire
     * Pool's lifetime.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     */
    function _onInitializePool(address sender, bytes memory userData)
        internal
        virtual
        returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    /**
     * @dev Called whenever the Pool is joined after the first initialization join (see `_onInitializePool`).
     *
     * Returns the amount of BPT to mint, the token amounts that the Pool will receive in return, and the number of
     * tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * Minted BPT will be sent to `recipient`.
     *
     * The tokens granted to the Pool will be transferred from `sender`. These amounts are considered upscaled and will
     * be downscaled (rounding up) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onJoinPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     */
    function _onJoinPool(
        address sender,
        uint256[] memory balances,
        bytes memory userData
    ) internal virtual returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    /**
     * @dev Called whenever the Pool is exited.
     *
     * Returns the amount of BPT to burn, the token amounts for each Pool token that the Pool will grant in return, and
     * the number of tokens to pay in protocol swap fees.
     *
     * Implementations of this function might choose to mutate the `balances` array to save gas (e.g. when
     * performing intermediate calculations, such as subtraction of due protocol fees). This can be done safely.
     *
     * BPT will be burnt from `sender`.
     *
     * The Pool will grant tokens to `recipient`. These amounts are considered upscaled and will be downscaled
     * (rounding down) before being returned to the Vault.
     *
     * Due protocol swap fees will be taken from the Pool's balance in the Vault (see `IBasePool.onExitPool`). These
     * amounts are considered upscaled and will be downscaled (rounding down) before being returned to the Vault.
     */
    function _onExitPool(
        address sender,
        uint256[] memory balances,
        bytes memory userData
    ) internal virtual returns (uint256 bptAmountIn, uint256[] memory amountsOut);

    function _queryAction(
        address sender,
        uint256[] memory balances,
        bytes memory userData,
        function(address, uint256[] memory, bytes memory) internal returns (uint256, uint256[] memory) _action
    ) private {
        // This uses the same technique used by the Vault in queryBatchSwap. Refer to that function for a detailed
        // explanation.

        if (msg.sender != address(this)) {
            // We perform an external call to ourselves, forwarding the same calldata. In this call, the else clause of
            // the preceding if statement will be executed instead.

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(msg.data);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // This call should always revert to decode the bpt and token amounts from the revert reason
                switch success
                    case 0 {
                        // Note we are manually writing the memory slot 0. We can safely overwrite whatever is
                        // stored there as we take full control of the execution and then immediately return.

                        // We copy the first 4 bytes to check if it matches with the expected signature, otherwise
                        // there was another revert reason and we should forward it.
                        returndatacopy(0, 0, 0x04)
                        let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                        // If the first 4 bytes don't match with the expected signature, we forward the revert reason.
                        if eq(eq(error, 0x43adbafb00000000000000000000000000000000000000000000000000000000), 0) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                        // The returndata contains the signature, followed by the raw memory representation of the
                        // `bptAmount` and `tokenAmounts` (array: length + data). We need to return an ABI-encoded
                        // representation of these.
                        // An ABI-encoded response will include one additional field to indicate the starting offset of
                        // the `tokenAmounts` array. The `bptAmount` will be laid out in the first word of the
                        // returndata.
                        //
                        // In returndata:
                        // [ signature ][ bptAmount ][ tokenAmounts length ][ tokenAmounts values ]
                        // [  4 bytes  ][  32 bytes ][       32 bytes      ][ (32 * length) bytes ]
                        //
                        // We now need to return (ABI-encoded values):
                        // [ bptAmount ][ tokeAmounts offset ][ tokenAmounts length ][ tokenAmounts values ]
                        // [  32 bytes ][       32 bytes     ][       32 bytes      ][ (32 * length) bytes ]

                        // We copy 32 bytes for the `bptAmount` from returndata into memory.
                        // Note that we skip the first 4 bytes for the error signature
                        returndatacopy(0, 0x04, 32)

                        // The offsets are 32-bytes long, so the array of `tokenAmounts` will start after
                        // the initial 64 bytes.
                        mstore(0x20, 64)

                        // We now copy the raw memory array for the `tokenAmounts` from returndata into memory.
                        // Since bpt amount and offset take up 64 bytes, we start copying at address 0x40. We also
                        // skip the first 36 bytes from returndata, which correspond to the signature plus bpt amount.
                        returndatacopy(0x40, 0x24, sub(returndatasize(), 36))

                        // We finally return the ABI-encoded uint256 and the array, which has a total length equal to
                        // the size of returndata, plus the 32 bytes of the offset but without the 4 bytes of the
                        // error signature.
                        return(0, add(returndatasize(), 28))
                    }
                    default {
                        // This call should always revert, but we fail nonetheless if that didn't happen
                        invalid()
                    }
            }
        } else {
            (uint256 bptAmount, uint256[] memory tokenAmounts) = _action(sender, balances, userData);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // We will return a raw representation of `bptAmount` and `tokenAmounts` in memory, which is composed of
                // a 32-byte uint256, followed by a 32-byte for the array length, and finally the 32-byte uint256 values
                // Because revert expects a size in bytes, we multiply the array length (stored at `tokenAmounts`) by 32
                let size := mul(mload(tokenAmounts), 32)

                // We store the `bptAmount` in the previous slot to the `tokenAmounts` array. We can make sure there
                // will be at least one available slot due to how the memory scratch space works.
                // We can safely overwrite whatever is stored in this slot as we will revert immediately after that.
                let start := sub(tokenAmounts, 0x20)
                mstore(start, bptAmount)

                // We send one extra value for the error signature "QueryError(uint256,uint256[])" which is 0x43adbafb
                // We use the previous slot to `bptAmount`.
                mstore(sub(start, 0x20), 0x0000000000000000000000000000000000000000000000000000000043adbafb)
                start := sub(start, 0x04)

                // When copying from `tokenAmounts` into returndata, we copy the additional 68 bytes to also return
                // the `bptAmount`, the array 's length, and the error signature.
                revert(start, add(size, 68))
            }
        }
    }
}

// solhint-disable not-rely-on-time

library GradualValueChange {
    using FixedPoint for uint256;

    function getInterpolatedValue(
        uint256 startValue,
        uint256 endValue,
        uint256 startTime,
        uint256 endTime
    ) internal view returns (uint256) {
        uint256 pctProgress = calculateValueChangeProgress(startTime, endTime);

        return interpolateValue(startValue, endValue, pctProgress);
    }

    function resolveStartTime(uint256 startTime, uint256 endTime) internal view returns (uint256 resolvedStartTime) {
        // If the start time is in the past, "fast forward" to start now
        // This avoids discontinuities in the value curve. Otherwise, if you set the start/end times with
        // only 10% of the period in the future, the value would immediately jump 90%
        resolvedStartTime = Math.max(block.timestamp, startTime);

        _require(resolvedStartTime <= endTime, Errors.GRADUAL_UPDATE_TIME_TRAVEL);
    }

    function interpolateValue(
        uint256 startValue,
        uint256 endValue,
        uint256 pctProgress
    ) internal pure returns (uint256) {
        if (pctProgress >= FixedPoint.ONE || startValue == endValue) return endValue;
        if (pctProgress == 0) return startValue;

        if (startValue > endValue) {
            uint256 delta = pctProgress.mulDown(startValue - endValue);
            return startValue - delta;
        } else {
            uint256 delta = pctProgress.mulDown(endValue - startValue);
            return startValue + delta;
        }
    }

    /**
     * @dev Returns a fixed-point number representing how far along the current value change is, where 0 means the
     * change has not yet started, and FixedPoint.ONE means it has fully completed.
     */
    function calculateValueChangeProgress(uint256 startTime, uint256 endTime) internal view returns (uint256) {
        if (block.timestamp >= endTime) {
            return FixedPoint.ONE;
        } else if (block.timestamp <= startTime) {
            return 0;
        }

        // No need for SafeMath as it was checked right above: endTime > block.timestamp > startTime
        uint256 totalSeconds = endTime - startTime;
        uint256 secondsElapsed = block.timestamp - startTime;

        // We don't need to consider zero division here as this is covered above.
        return secondsElapsed.divDown(totalSeconds);
    }
}





/**
 * @dev Library for compressing and decompressing numbers by using smaller types.
 * All values are 18 decimal fixed-point numbers, so heavier compression (fewer bits)
 * results in fewer decimals.
 */
library ValueCompression {
    /**
     * @notice Returns the maximum potential error when compressing and decompressing a value to a certain bit length.
     * @dev During compression, the range [0, maxUncompressedValue] is mapped onto the range [0, maxCompressedValue].
     * Each increment in compressed space then corresponds to an increment of maxUncompressedValue / maxCompressedValue
     * in uncompressed space. This granularity is the maximum error when decompressing a compressed value.
     */
    function maxCompressionError(uint256 bitLength, uint256 maxUncompressedValue) internal pure returns (uint256) {
        // It's not meaningful to compress 1-bit values (2 bits is also a bit silly, but theoretically possible).
        // 255 would likewise not be very helpful, but is technically valid.
        _require(bitLength >= 2 && bitLength <= 255, Errors.OUT_OF_BOUNDS);

        uint256 maxCompressedValue = (1 << bitLength) - 1;
        return Math.divUp(maxUncompressedValue, maxCompressedValue);
    }

    /**
     * @dev Compress a 256 bit value into `bitLength` bits.
     * To compress a value down to n bits, you first "normalize" it over the full input range.
     * For instance, if the maximum value were 10_000, and the `value` is 2_000, it would be
     * normalized to 0.2.
     *
     * Finally, "scale" that normalized value into the output range: adapting [0, maxUncompressedValue]
     * to [0, max n-bit value]. For n=8 bits, the max value is 255, so 0.2 corresponds to 51.
     * Likewise, for 16 bits, 0.2 would be stored as 13_107.
     */
    function compress(
        uint256 value,
        uint256 bitLength,
        uint256 maxUncompressedValue
    ) internal pure returns (uint256) {
        // It's not meaningful to compress 1-bit values (2 bits is also a bit silly, but theoretically possible).
        // 255 would likewise not be very helpful, but is technically valid.
        _require(bitLength >= 2 && bitLength <= 255, Errors.OUT_OF_BOUNDS);
        // The value cannot exceed the input range, or the compression would not "fit" in the output range.
        _require(value <= maxUncompressedValue, Errors.OUT_OF_BOUNDS);

        // There is another way this can fail: maxUncompressedValue * value can overflow, if either or both
        // are too big. Essentially, the maximum bitLength will be about 256 - (# bits needed for maxUncompressedValue).
        // It's not worth it to test for this: the caller is responsible for many things anyway, notably ensuring
        // compress and decompress are called with the same arguments, and packing the resulting value properly
        // (the most common use is to assist in packing several variables into a 256-bit word).

        uint256 maxCompressedValue = (1 << bitLength) - 1;

        return Math.divDown(Math.mul(value, maxCompressedValue), maxUncompressedValue);
    }

    /**
     * @dev Reverse a compression operation, and restore the 256 bit value from a compressed value of
     * length `bitLength`. The compressed value is in the range [0, 2^(bitLength) - 1], and we are mapping
     * it back onto the uncompressed range [0, maxUncompressedValue].
     *
     * It is very important that the bitLength and maxUncompressedValue arguments are the
     * same for compress and decompress, or the results will be meaningless. This must be validated
     * externally.
     */
    function decompress(
        uint256 value,
        uint256 bitLength,
        uint256 maxUncompressedValue
    ) internal pure returns (uint256) {
        // It's not meaningful to compress 1-bit values (2 bits is also a bit silly, but theoretically possible).
        // 255 would likewise not be very helpful, but is technically valid.
        _require(bitLength >= 2 && bitLength <= 255, Errors.OUT_OF_BOUNDS);
        uint256 maxCompressedValue = (1 << bitLength) - 1;
        // The value must not exceed the maximum compressed value (2**(bitLength) - 1), or it will exceed the max
        // uncompressed value.
        _require(value <= maxCompressedValue, Errors.OUT_OF_BOUNDS);

        return Math.divDown(Math.mul(value, maxUncompressedValue), maxCompressedValue);
    }

    // Special case overloads

    /**
     * @dev It is very common for the maximum value to be one: Weighted Pool weights, for example.
     * Overload for this common case, passing FixedPoint.ONE to the general `compress` function.
     */
    function compress(uint256 value, uint256 bitLength) internal pure returns (uint256) {
        return compress(value, bitLength, FixedPoint.ONE);
    }

    /**
     * @dev It is very common for the maximum value to be one: Weighted Pool weights, for example.
     * Overload for this common case, passing FixedPoint.ONE to the general `decompress` function.
     */
    function decompress(uint256 value, uint256 bitLength) internal pure returns (uint256) {
        return decompress(value, bitLength, FixedPoint.ONE);
    }
}



/**
 * @title Circuit Breaker Library
 * @notice Library for logic and functions related to circuit breakers.
 */
library CircuitBreakerLib {
    using FixedPoint for uint256;

    /**
     * @notice Single-sided check for whether a lower or upper circuit breaker would trip in the given pool state.
     * @dev Compute the current BPT price from the input parameters, and compare it to the given bound to determine
     * whether the given post-operation pool state is within the circuit breaker bounds.
     * @param virtualSupply - the post-operation totalSupply (including protocol fees, etc.)
     * @param weight - the normalized weight of the token we are checking.
     * @param balance - the post-operation token balance (including swap fees, etc.). It must be an 18-decimal
     * floating point number, adjusted by the scaling factor of the token.
     * @param boundBptPrice - the BPT price at the limit (lower or upper) of the allowed trading range.
     * @param isLowerBound - true if the boundBptPrice represents the lower bound.
     * @return - boolean flag for whether the breaker has been tripped.
     */
    function hasCircuitBreakerTripped(
        uint256 virtualSupply,
        uint256 weight,
        uint256 balance,
        uint256 boundBptPrice,
        bool isLowerBound
    ) internal pure returns (bool) {
        // A bound price of 0 means that no breaker is set.
        if (boundBptPrice == 0) {
            return false;
        }

        // Round down for lower bound checks, up for upper bound checks
        uint256 currentBptPrice = Math.div(Math.mul(virtualSupply, weight), balance, !isLowerBound);

        return isLowerBound ? currentBptPrice < boundBptPrice : currentBptPrice > boundBptPrice;
    }

    /**
     * @notice Convert a bound to a BPT price ratio
     * @param bound - The bound percentage.
     * @param weight - The current normalized token weight.
     * @param isLowerBound - A flag indicating whether this is for a lower bound.
     */
    function calcAdjustedBound(
        uint256 bound,
        uint256 weight,
        bool isLowerBound
    ) external pure returns (uint256 boundRatio) {
        // To be conservative and protect LPs, round up for the lower bound, and down for the upper bound.
        boundRatio = (isLowerBound ? FixedPoint.powUp : FixedPoint.powDown)(bound, weight.complement());
    }

    /**
     * @notice Convert a BPT price ratio to a BPT price bound
     * @param boundRatio - The cached bound ratio
     * @param bptPrice - The BPT price stored at the time the breaker was set.
     * @param isLowerBound - A flag indicating whether this is for a lower bound.
     */
    function calcBptPriceBoundary(
        uint256 boundRatio,
        uint256 bptPrice,
        bool isLowerBound
    ) internal pure returns (uint256 boundBptPrice) {
        // To be conservative and protect LPs, round up for the lower bound, and down for the upper bound.
        boundBptPrice = (isLowerBound ? FixedPoint.mulUp : FixedPoint.mulDown)(bptPrice, boundRatio);
    }
}

/**
 * @title Circuit Breaker Storage Library
 * @notice Library for storing and manipulating state related to circuit breakers.
 * @dev The intent of circuit breakers is to halt trading of a given token if its value changes drastically -
 * in either direction - with respect to other tokens in the pool. For instance, a stablecoin might de-peg
 * and go to zero. With no safeguards, arbitrageurs could drain the pool by selling large amounts of the
 * token to the pool at inflated internal prices.
 *
 * The circuit breaker mechanism establishes a "safe trading range" for each token, expressed in terms of
 * the BPT price. Both lower and upper bounds can be set, and if a trade would result in moving the BPT price
 * of any token involved in the operation outside that range, the breaker is "tripped", and the operation
 * should revert. Each token is independent, since some might have very "tight" valid trading ranges, such as
 * stablecoins, and others are more volatile.
 *
 * The BPT price of a token is defined as the amount of BPT that could be redeemed for a single token.
 * For instance, in an 80/20 pool with a total supply of 1000, the 80% token accounts for 800 BPT. So each
 * token would be worth 800 / token balance. The formula is then: total supply * token weight / token balance.
 * (Note that this only applies *if* the pool is balanced (a condition that cannot be checked by the pool without
 * accessing price oracles.)
 *
 * We need to use the BPT price as the measure to ensure we account for the change relative to the rest of
 * the pool, which could have many other tokens. The drop detected by circuit breakers is analogous to
 * impermanent loss: it is relative to the performance of the other tokens. If the entire market tanks and
 * all token balances go down together, the *relative* change would be zero, and the breaker would not be
 * triggered: even though the external price might have dropped 50 or 70%. It is only the *relative* movement
 * compared to the rest of the pool that matters.
 *
 * If we have tokens A, B, and C, If A drops 20% and B and C are unchanged, that's a simple 20% drop for A.
 * However, if A is unchanged and C increases 25%, that would also be a 20% "drop" for A 1 / 1.25 = 0.8.
 * The breaker might register a 20% drop even if both go up - if our target token lags the market. For
 * instance, if A goes up 60% and B and C double, 1.6 / 2 = 0.8.
 *
 * Since BPT prices are not intuitive - and there is a very non-linear relationship between "spot" prices and
 * BPT prices - circuit breakers are set using simple percentages. Intuitively, a lower bound of 0.8 means the
 * token can lose 20% of its value before triggering the circuit breaker, and an upper bound of 3.0 means it
 * can triple before being halted. These percentages are then transformed into BPT prices for comparison to the
 * "reference" state of the pool when the circuit breaker was set.
 *
 * Prices can change in two ways: arbitrage traders responding to external price movement can change the balances,
 * or an ongoing gradual weight update (or change in pool composition) can change the weights. In order to isolate
 * the balance changes due to price movement, the bounds are dynamic, adjusted for the current weight.
 */
library CircuitBreakerStorageLib {
    using ValueCompression for uint256;
    using FixedPoint for uint256;
    using WordCodec for bytes32;

    // Store circuit breaker information per token
    // When the circuit breaker is set, the caller passes in the lower and upper bounds (expressed as percentages),
    // the current BPT price, and the normalized weight. The weight is bound by 1e18, and fits in ~60 bits, so there
    // is no need for compression. We store the weight in 64 bits, just to use round numbers for all the bit lengths.
    //
    // We then store the current BPT price, and compute and cache the adjusted lower and upper bounds at the current
    // weight. When multiplied by the stored BPT price, the adjusted bounds define the BPT price trading range: the
    // "runtime" BPT prices can be directly compared to these BPT price bounds.
    //
    // Since the price bounds need to be adjusted for the token weight, in general these adjusted bounds would be
    // computed every time. However, if the weight of the token has not changed since the circuit breaker was set,
    // the adjusted bounds cache can still be used, avoiding a heavy computation.
    //
    // [        32 bits       |        32 bits       |  96 bits  |     64 bits      |   16 bits   |   16 bits   |
    // [ adjusted upper bound | adjusted lower bound | BPT price | reference weight | upper bound | lower bound |
    // |MSB                                                                                                  LSB|
    uint256 private constant _LOWER_BOUND_OFFSET = 0;
    uint256 private constant _UPPER_BOUND_OFFSET = _LOWER_BOUND_OFFSET + _BOUND_WIDTH;
    uint256 private constant _REFERENCE_WEIGHT_OFFSET = _UPPER_BOUND_OFFSET + _BOUND_WIDTH;
    uint256 private constant _BPT_PRICE_OFFSET = _REFERENCE_WEIGHT_OFFSET + _REFERENCE_WEIGHT_WIDTH;
    uint256 private constant _ADJUSTED_LOWER_BOUND_OFFSET = _BPT_PRICE_OFFSET + _BPT_PRICE_WIDTH;
    uint256 private constant _ADJUSTED_UPPER_BOUND_OFFSET = _ADJUSTED_LOWER_BOUND_OFFSET + _ADJUSTED_BOUND_WIDTH;

    uint256 private constant _REFERENCE_WEIGHT_WIDTH = 64;
    uint256 private constant _BPT_PRICE_WIDTH = 96;
    uint256 private constant _BOUND_WIDTH = 16;
    uint256 private constant _ADJUSTED_BOUND_WIDTH = 32;

    // We allow the bounds to range over two orders of magnitude: 0.1 - 10. The maximum upper bound is set to 10.0
    // in 18-decimal floating point, since this fits in 64 bits, and can be shifted down to 16 bit precision without
    // much loss. Since compression would lose a lot of precision for values close to 0, we also constrain the lower
    // bound to a minimum value >> 0.
    //
    // Since the adjusted bounds are (bound percentage)**(1 - weight), and weights are stored normalized, the
    // maximum normalized weight is 1 - minimumWeight, which is 0.99 ~ 1. Therefore the adjusted bounds are likewise
    // constrained to 10**1 ~ 10. So we can use this as the maximum value of both the raw percentage and
    // weight-adjusted percentage bounds.
    uint256 private constant _MIN_BOUND_PERCENTAGE = 1e17; // 0.1 in 18-decimal fixed point

    uint256 private constant _MAX_BOUND_PERCENTAGE = 10e18; // 10.0 in 18-decimal fixed point

    // Since we know the bounds fit into 64 bits, simply shifting them down to fit in 16 bits is not only faster than
    // the compression and decompression operations, but generally less lossy.
    uint256 private constant _BOUND_SHIFT_BITS = 64 - _BOUND_WIDTH;

    /**
     * @notice Returns the BPT price, reference weight, and the lower and upper percentage bounds for a given token.
     * @dev If an upper or lower bound value is zero, it means there is no circuit breaker in that direction for the
     * given token.
     * @param circuitBreakerState - The bytes32 state of the token of interest.
     */
    function getCircuitBreakerFields(bytes32 circuitBreakerState)
        internal
        pure
        returns (
            uint256 bptPrice,
            uint256 referenceWeight,
            uint256 lowerBound,
            uint256 upperBound
        )
    {
        bptPrice = circuitBreakerState.decodeUint(_BPT_PRICE_OFFSET, _BPT_PRICE_WIDTH);
        referenceWeight = circuitBreakerState.decodeUint(_REFERENCE_WEIGHT_OFFSET, _REFERENCE_WEIGHT_WIDTH);
        // Decompress the bounds by shifting left.
        lowerBound = circuitBreakerState.decodeUint(_LOWER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS;
        upperBound = circuitBreakerState.decodeUint(_UPPER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS;
    }

    /**
     * @notice Returns a dynamic lower or upper BPT price bound for a given token, at the current weight.
     * @dev The current BPT price of the token can be directly compared to this value, to determine whether
     * the breaker should be tripped. If a bound is 0, it means there is no circuit breaker in that direction
     * for this token: there might be a lower bound, but no upper bound. If the current BPT price is less than
     * the lower bound, or greater than the non-zero upper bound, the transaction should revert.
     *
     * These BPT price bounds are dynamically adjusted by a non-linear factor dependent on the weight.
     * In general: lower/upper BPT price bound = bptPrice * "weight adjustment". The weight adjustment is
     * given as: (boundaryPercentage)**(1 - weight).
     *
     * For instance, given the 80/20 BAL/WETH pool with a 90% lower bound, the weight complement would be
     * (1 - 0.8) = 0.2, so the lower adjusted bound would be (0.9 ** 0.2) ~ 0.9791. For the WETH token at 20%,
     * the bound would be (0.9 ** 0.8) ~ 0.9192.
     *
     * With unequal weights (assuming a balanced pool), the balance of a higher-weight token will respond less
     * to a proportional change in spot price than a lower weight token, which we might call "balance inertia".
     *
     * If the external price drops, all else being equal, the pool would be arbed until the percent drop in spot
     * price equaled the external price drop. Since during this process the *internal* pool price would be
     * above market, the arbers would sell cheap tokens to our poor unwitting pool at inflated prices, raising
     * the balance of the depreciating token, and lowering the balance of another token (WETH in this example).
     *
     * Using weighted math, and assuming for simplicity that the sum of all weights is 1, you can compute the
     * amountIn ratio for the arb trade as: (1/priceRatio) ** (1 - weight). For our 0.9 ratio and a weight of
     * 0.8, this is ~ 1.0213. So if you had 8000 tokens before, the ending balance would be 8000*1.0213 ~ 8170.
     * Note that the higher the weight, the lower this ratio is. That means the counterparty token is going
     * out proportionally faster than the arb token is coming in: hence the non-linear relationship between
     * spot price and BPT price.
     *
     * If we call the initial balance B0, and set k = (1/priceRatio) ** (1 - weight), the post-arb balance is
     * given by: B1 = k * B0. Since the BPTPrice0 = totalSupply*weight/B0, and BPTPrice1 = totalSupply*weight/B1,
     * we can combine these equations to compute the BPT price ratio BPTPrice1/BPTPrice0 = 1/k; BPT1 = BPT0/k.
     * So we see that the "conversion factor" between the spot price ratio and BPT Price ratio can be written
     * as above BPT1 = BPT0 * (1/k), or more simply: (BPT price) * (priceRatio)**(1 - weight).
     *
     * Another way to think of it is in terms of "BPT Value". Assuming a balanced pool, a token with a weight
     * of 80% represents 80% of the value of the BPT. An uncorrelated drop in that token's value would drop
     * the value of LP shares much faster than a similar drop in the value of a 20% token. Whatever the value
     * of the bound percentage, as the adjustment factor - B ** (1 - weight) - approaches 1, less adjustment
     * is necessary: it tracks the relative price movement more closely. Intuitively, this is wny we use the
     * complement of the weight. Higher weight = lower exponent = adjustment factor closer to 1.0 = "faster"
     * tracking of value changes.
     *
     * If the value of the weight has not changed, we can use the cached adjusted bounds stored when the breaker
     * was set. Otherwise, we need to calculate them.
     *
     * As described in the general comments above, the weight adjustment calculation attempts to isolate changes
     * in the balance due to arbitrageurs responding to external prices, from internal price changes caused by
     * weight changes. There is a non-linear relationship between "spot" price changes and BPT price changes.
     * This calculation transforms one into the other.
     * @param circuitBreakerState - The bytes32 state of the token of interest.
     * @param currentWeight - The token's current normalized weight.
     * @param isLowerBound - Flag indicating whether this is the lower bound.
     * @return - lower or upper bound BPT price, which can be directly compared against the current BPT price.
     */
    function getBptPriceBound(
        bytes32 circuitBreakerState,
        uint256 currentWeight,
        bool isLowerBound
    ) internal pure returns (uint256) {
        uint256 bound = circuitBreakerState.decodeUint(
            isLowerBound ? _LOWER_BOUND_OFFSET : _UPPER_BOUND_OFFSET,
            _BOUND_WIDTH
        ) << _BOUND_SHIFT_BITS;

        if (bound == 0) {
            return 0;
        }
        // Retrieve the BPT price and reference weight passed in when the circuit breaker was set.
        uint256 bptPrice = circuitBreakerState.decodeUint(_BPT_PRICE_OFFSET, _BPT_PRICE_WIDTH);
        uint256 referenceWeight = circuitBreakerState.decodeUint(_REFERENCE_WEIGHT_OFFSET, _REFERENCE_WEIGHT_WIDTH);

        uint256 boundRatio;

        if (currentWeight == referenceWeight) {
            // If the weight hasn't changed since the circuit breaker was set, we can use the precomputed
            // adjusted bounds.
            boundRatio = circuitBreakerState
                .decodeUint(
                isLowerBound ? _ADJUSTED_LOWER_BOUND_OFFSET : _ADJUSTED_UPPER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            )
                .decompress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE);
        } else {
            // The weight has changed, so we retrieve the raw percentage bounds and do the full calculation.
            // Decompress the bounds by shifting left.
            boundRatio = CircuitBreakerLib.calcAdjustedBound(bound, currentWeight, isLowerBound);
        }

        // Use the adjusted bounds (either cached or computed) to calculate the BPT price bounds.
        return CircuitBreakerLib.calcBptPriceBoundary(boundRatio, bptPrice, isLowerBound);
    }

    /**
     * @notice Sets the reference BPT price, normalized weight, and upper and lower bounds for a token.
     * @dev If a bound is zero, it means there is no circuit breaker in that direction for the given token.
     * @param bptPrice: The BPT price of the token at the time the circuit breaker is set. The BPT Price
     * of a token is generally given by: supply * weight / balance.
     * @param referenceWeight: This is the current normalized weight of the token.
     * @param lowerBound: The value of the lower bound, expressed as a percentage.
     * @param upperBound: The value of the upper bound, expressed as a percentage.
     */
    function setCircuitBreaker(
        uint256 bptPrice,
        uint256 referenceWeight,
        uint256 lowerBound,
        uint256 upperBound
    ) internal pure returns (bytes32) {
        // It's theoretically not required for the lower bound to be < 1, but it wouldn't make much sense otherwise:
        // the circuit breaker would immediately trip. Note that this explicitly allows setting either to 0, disabling
        // the circuit breaker for the token in that direction.
        _require(
            lowerBound == 0 || (lowerBound >= _MIN_BOUND_PERCENTAGE && lowerBound <= FixedPoint.ONE),
            Errors.INVALID_CIRCUIT_BREAKER_BOUNDS
        );
        _require(upperBound <= _MAX_BOUND_PERCENTAGE, Errors.INVALID_CIRCUIT_BREAKER_BOUNDS);
        _require(upperBound == 0 || upperBound >= lowerBound, Errors.INVALID_CIRCUIT_BREAKER_BOUNDS);

        // Set the reference parameters: BPT price of the token, and the reference weight.
        bytes32 circuitBreakerState = bytes32(0).insertUint(bptPrice, _BPT_PRICE_OFFSET, _BPT_PRICE_WIDTH).insertUint(
            referenceWeight,
            _REFERENCE_WEIGHT_OFFSET,
            _REFERENCE_WEIGHT_WIDTH
        );

        // Add the lower and upper percentage bounds. Compress by shifting right.
        circuitBreakerState = circuitBreakerState
            .insertUint(lowerBound >> _BOUND_SHIFT_BITS, _LOWER_BOUND_OFFSET, _BOUND_WIDTH)
            .insertUint(upperBound >> _BOUND_SHIFT_BITS, _UPPER_BOUND_OFFSET, _BOUND_WIDTH);

        // Precompute and store the adjusted bounds, used to convert percentage bounds to BPT price bounds.
        // If the weight has not changed since the breaker was set, we can use the precomputed values directly,
        // and avoid a heavy computation.
        uint256 adjustedLowerBound = CircuitBreakerLib.calcAdjustedBound(lowerBound, referenceWeight, true);
        uint256 adjustedUpperBound = CircuitBreakerLib.calcAdjustedBound(upperBound, referenceWeight, false);

        // Finally, insert these computed adjusted bounds, and return the complete set of fields.
        return
            circuitBreakerState
                .insertUint(
                adjustedLowerBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_LOWER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            )
                .insertUint(
                adjustedUpperBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_UPPER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            );
    }

    /**
     * @notice Update the cached adjusted bounds, given a new weight.
     * @dev This might be used when weights are adjusted, pre-emptively updating the cache to improve performance
     * of operations after the weight change completes. Note that this does not update the BPT price: this is still
     * relative to the last call to `setCircuitBreaker`. The intent is only to optimize the automatic bounds
     * adjustments due to changing weights.
     */
    function updateAdjustedBounds(bytes32 circuitBreakerState, uint256 newReferenceWeight)
        internal
        pure
        returns (bytes32)
    {
        uint256 adjustedLowerBound = CircuitBreakerLib.calcAdjustedBound(
            circuitBreakerState.decodeUint(_LOWER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS,
            newReferenceWeight,
            true
        );
        uint256 adjustedUpperBound = CircuitBreakerLib.calcAdjustedBound(
            circuitBreakerState.decodeUint(_UPPER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS,
            newReferenceWeight,
            false
        );

        // Replace the reference weight.
        bytes32 result = circuitBreakerState.insertUint(
            newReferenceWeight,
            _REFERENCE_WEIGHT_OFFSET,
            _REFERENCE_WEIGHT_WIDTH
        );

        // Update the cached adjusted bounds.
        return
            result
                .insertUint(
                adjustedLowerBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_LOWER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            )
                .insertUint(
                adjustedUpperBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_UPPER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            );
    }
}

// These functions start with an underscore, as if they were part of a contract and not a library. At some point this
// should be fixed.
// solhint-disable private-vars-leading-underscore

library WeightedMath {
    using FixedPoint for uint256;
    // A minimum normalized weight imposes a maximum weight ratio. We need this due to limitations in the
    // implementation of the power function, as these ratios are often exponents.
    uint256 internal constant _MIN_WEIGHT = 0.01e18;
    // Having a minimum normalized weight imposes a limit on the maximum number of tokens;
    // i.e., the largest possible pool is one where all tokens have exactly the minimum weight.
    uint256 internal constant _MAX_WEIGHTED_TOKENS = 100;

    // Pool limits that arise from limitations in the fixed point power function (and the imposed 1:100 maximum weight
    // ratio).

    // Swap limits: amounts swapped may not be larger than this percentage of total balance.
    uint256 internal constant _MAX_IN_RATIO = 0.3e18;
    uint256 internal constant _MAX_OUT_RATIO = 0.3e18;

    // Invariant growth limit: non-proportional joins cannot cause the invariant to increase by more than this ratio.
    uint256 internal constant _MAX_INVARIANT_RATIO = 3e18;
    // Invariant shrink limit: non-proportional exits cannot cause the invariant to decrease by less than this ratio.
    uint256 internal constant _MIN_INVARIANT_RATIO = 0.7e18;

    // About swap fees on joins and exits:
    // Any join or exit that is not perfectly balanced (e.g. all single token joins or exits) is mathematically
    // equivalent to a perfectly balanced join or exit followed by a series of swaps. Since these swaps would charge
    // swap fees, it follows that (some) joins and exits should as well.
    // On these operations, we split the token amounts in 'taxable' and 'non-taxable' portions, where the 'taxable' part
    // is the one to which swap fees are applied.

    // Invariant is used to collect protocol swap fees by comparing its value between two times.
    // So we can round always to the same direction. It is also used to initiate the BPT amount
    // and, because there is a minimum BPT, we round down the invariant.
    function _calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
        internal
        pure
        returns (uint256 invariant)
    {
        /**********************************************************************************************
        // invariant               _____                                                             //
        // wi = weight index i      | |      wi                                                      //
        // bi = balance index i     | |  bi ^   = i                                                  //
        // i = invariant                                                                             //
        **********************************************************************************************/

        invariant = FixedPoint.ONE;
        for (uint256 i = 0; i < normalizedWeights.length; i++) {
            invariant = invariant.mulDown(balances[i].powDown(normalizedWeights[i]));
        }

        _require(invariant > 0, Errors.ZERO_INVARIANT);
    }

    // Computes how many tokens can be taken out of a pool if `amountIn` are sent, given the
    // current balances and weights.
    function _calcOutGivenIn(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    ) internal pure returns (uint256) {
        /**********************************************************************************************
        // outGivenIn                                                                                //
        // aO = amountOut                                                                            //
        // bO = balanceOut                                                                           //
        // bI = balanceIn              /      /            bI             \    (wI / wO) \           //
        // aI = amountIn    aO = bO * |  1 - | --------------------------  | ^            |          //
        // wI = weightIn               \      \       ( bI + aI )         /              /           //
        // wO = weightOut                                                                            //
        **********************************************************************************************/

        // Amount out, so we round down overall.

        // The multiplication rounds down, and the subtrahend (power) rounds up (so the base rounds up too).
        // Because bI / (bI + aI) <= 1, the exponent rounds down.

        // Cannot exceed maximum in ratio
        _require(amountIn <= balanceIn.mulDown(_MAX_IN_RATIO), Errors.MAX_IN_RATIO);

        uint256 denominator = balanceIn.add(amountIn);
        uint256 base = balanceIn.divUp(denominator);
        uint256 exponent = weightIn.divDown(weightOut);
        uint256 power = base.powUp(exponent);

        return balanceOut.mulDown(power.complement());
    }

    // Computes how many tokens must be sent to a pool in order to take `amountOut`, given the
    // current balances and weights.
    function _calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut
    ) internal pure returns (uint256) {
        /**********************************************************************************************
        // inGivenOut                                                                                //
        // aO = amountOut                                                                            //
        // bO = balanceOut                                                                           //
        // bI = balanceIn              /  /            bO             \    (wO / wI)      \          //
        // aI = amountIn    aI = bI * |  | --------------------------  | ^            - 1  |         //
        // wI = weightIn               \  \       ( bO - aO )         /                   /          //
        // wO = weightOut                                                                            //
        **********************************************************************************************/

        // Amount in, so we round up overall.

        // The multiplication rounds up, and the power rounds up (so the base rounds up too).
        // Because b0 / (b0 - a0) >= 1, the exponent rounds up.

        // Cannot exceed maximum out ratio
        _require(amountOut <= balanceOut.mulDown(_MAX_OUT_RATIO), Errors.MAX_OUT_RATIO);

        uint256 base = balanceOut.divUp(balanceOut.sub(amountOut));
        uint256 exponent = weightOut.divUp(weightIn);
        uint256 power = base.powUp(exponent);

        // Because the base is larger than one (and the power rounds up), the power should always be larger than one, so
        // the following subtraction should never revert.
        uint256 ratio = power.sub(FixedPoint.ONE);

        return balanceIn.mulUp(ratio);
    }

    function _calcBptOutGivenExactTokensIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        // BPT out, so we round down overall.

        uint256[] memory balanceRatiosWithFee = new uint256[](amountsIn.length);

        uint256 invariantRatioWithFees = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            balanceRatiosWithFee[i] = balances[i].add(amountsIn[i]).divDown(balances[i]);
            invariantRatioWithFees = invariantRatioWithFees.add(balanceRatiosWithFee[i].mulDown(normalizedWeights[i]));
        }

        uint256 invariantRatio = _computeJoinExactTokensInInvariantRatio(
            balances,
            normalizedWeights,
            amountsIn,
            balanceRatiosWithFee,
            invariantRatioWithFees,
            swapFeePercentage
        );

        uint256 bptOut = (invariantRatio > FixedPoint.ONE)
            ? bptTotalSupply.mulDown(invariantRatio - FixedPoint.ONE)
            : 0;
        return bptOut;
    }

    function _calcBptOutGivenExactTokenIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        // BPT out, so we round down overall.

        uint256 amountInWithoutFee;
        {
            uint256 balanceRatioWithFee = balance.add(amountIn).divDown(balance);

            // The use of `normalizedWeight.complement()` assumes that the sum of all weights equals FixedPoint.ONE.
            // This may not be the case when weights are stored in a denormalized format or during a gradual weight
            // change due rounding errors during normalization or interpolation. This will result in a small difference
            // between the output of this function and the equivalent `_calcBptOutGivenExactTokensIn` call.
            uint256 invariantRatioWithFees = balanceRatioWithFee.mulDown(normalizedWeight).add(
                normalizedWeight.complement()
            );

            if (balanceRatioWithFee > invariantRatioWithFees) {
                uint256 nonTaxableAmount = invariantRatioWithFees > FixedPoint.ONE
                    ? balance.mulDown(invariantRatioWithFees - FixedPoint.ONE)
                    : 0;
                uint256 taxableAmount = amountIn.sub(nonTaxableAmount);
                uint256 swapFee = taxableAmount.mulUp(swapFeePercentage);

                amountInWithoutFee = nonTaxableAmount.add(taxableAmount.sub(swapFee));
            } else {
                amountInWithoutFee = amountIn;
                // If a token's amount in is not being charged a swap fee then it might be zero.
                // In this case, it's clear that the sender should receive no BPT.
                if (amountInWithoutFee == 0) {
                    return 0;
                }
            }
        }

        uint256 balanceRatio = balance.add(amountInWithoutFee).divDown(balance);

        uint256 invariantRatio = balanceRatio.powDown(normalizedWeight);

        uint256 bptOut = (invariantRatio > FixedPoint.ONE)
            ? bptTotalSupply.mulDown(invariantRatio - FixedPoint.ONE)
            : 0;
        return bptOut;
    }

    /**
     * @dev Intermediate function to avoid stack-too-deep errors.
     */
    function _computeJoinExactTokensInInvariantRatio(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256[] memory balanceRatiosWithFee,
        uint256 invariantRatioWithFees,
        uint256 swapFeePercentage
    ) private pure returns (uint256 invariantRatio) {
        // Swap fees are charged on all tokens that are being added in a larger proportion than the overall invariant
        // increase.
        invariantRatio = FixedPoint.ONE;

        for (uint256 i = 0; i < balances.length; i++) {
            uint256 amountInWithoutFee;

            if (balanceRatiosWithFee[i] > invariantRatioWithFees) {
                // invariantRatioWithFees might be less than FixedPoint.ONE in edge scenarios due to rounding error,
                // particularly if the weights don't exactly add up to 100%.
                uint256 nonTaxableAmount = invariantRatioWithFees > FixedPoint.ONE
                    ? balances[i].mulDown(invariantRatioWithFees - FixedPoint.ONE)
                    : 0;
                uint256 swapFee = amountsIn[i].sub(nonTaxableAmount).mulUp(swapFeePercentage);
                amountInWithoutFee = amountsIn[i].sub(swapFee);
            } else {
                amountInWithoutFee = amountsIn[i];

                // If a token's amount in is not being charged a swap fee then it might be zero (e.g. when joining a
                // Pool with only a subset of tokens). In this case, `balanceRatio` will equal `FixedPoint.ONE`, and
                // the `invariantRatio` will not change at all. We therefore skip to the next iteration, avoiding
                // the costly `powDown` call.
                if (amountInWithoutFee == 0) {
                    continue;
                }
            }

            uint256 balanceRatio = balances[i].add(amountInWithoutFee).divDown(balances[i]);

            invariantRatio = invariantRatio.mulDown(balanceRatio.powDown(normalizedWeights[i]));
        }
    }

    function _calcTokenInGivenExactBptOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        /******************************************************************************************
        // tokenInForExactBPTOut                                                                 //
        // a = amountIn                                                                          //
        // b = balance                      /  /    totalBPT + bptOut      \    (1 / w)       \  //
        // bptOut = bptAmountOut   a = b * |  | --------------------------  | ^          - 1  |  //
        // bpt = totalBPT                   \  \       totalBPT            /                  /  //
        // w = weight                                                                            //
        ******************************************************************************************/

        // Token in, so we round up overall.

        // Calculate the factor by which the invariant will increase after minting BPTAmountOut
        uint256 invariantRatio = bptTotalSupply.add(bptAmountOut).divUp(bptTotalSupply);
        _require(invariantRatio <= _MAX_INVARIANT_RATIO, Errors.MAX_OUT_BPT_FOR_TOKEN_IN);

        // Calculate by how much the token balance has to increase to match the invariantRatio
        uint256 balanceRatio = invariantRatio.powUp(FixedPoint.ONE.divUp(normalizedWeight));

        uint256 amountInWithoutFee = balance.mulUp(balanceRatio.sub(FixedPoint.ONE));

        // We can now compute how much extra balance is being deposited and used in virtual swaps, and charge swap fees
        // accordingly.
        uint256 taxableAmount = amountInWithoutFee.mulUp(normalizedWeight.complement());
        uint256 nonTaxableAmount = amountInWithoutFee.sub(taxableAmount);

        uint256 taxableAmountPlusFees = taxableAmount.divUp(swapFeePercentage.complement());

        return nonTaxableAmount.add(taxableAmountPlusFees);
    }

    function _calcAllTokensInGivenExactBptOut(
        uint256[] memory balances,
        uint256 bptAmountOut,
        uint256 totalBPT
    ) internal pure returns (uint256[] memory) {
        /************************************************************************************
        // tokensInForExactBptOut                                                          //
        // (per token)                                                                     //
        // aI = amountIn                   /   bptOut   \                                  //
        // b = balance           aI = b * | ------------ |                                 //
        // bptOut = bptAmountOut           \  totalBPT  /                                  //
        // bpt = totalBPT                                                                  //
        ************************************************************************************/

        // Tokens in, so we round up overall.
        uint256 bptRatio = bptAmountOut.divUp(totalBPT);

        uint256[] memory amountsIn = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsIn[i] = balances[i].mulUp(bptRatio);
        }

        return amountsIn;
    }

    function _calcBptInGivenExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        // BPT in, so we round up overall.

        uint256[] memory balanceRatiosWithoutFee = new uint256[](amountsOut.length);
        uint256 invariantRatioWithoutFees = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            balanceRatiosWithoutFee[i] = balances[i].sub(amountsOut[i]).divUp(balances[i]);
            invariantRatioWithoutFees = invariantRatioWithoutFees.add(
                balanceRatiosWithoutFee[i].mulUp(normalizedWeights[i])
            );
        }

        uint256 invariantRatio = _computeExitExactTokensOutInvariantRatio(
            balances,
            normalizedWeights,
            amountsOut,
            balanceRatiosWithoutFee,
            invariantRatioWithoutFees,
            swapFeePercentage
        );

        return bptTotalSupply.mulUp(invariantRatio.complement());
    }

    function _calcBptInGivenExactTokenOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        // BPT in, so we round up overall.

        uint256 balanceRatioWithoutFee = balance.sub(amountOut).divUp(balance);

        uint256 invariantRatioWithoutFees = balanceRatioWithoutFee.mulUp(normalizedWeight).add(
            normalizedWeight.complement()
        );

        uint256 amountOutWithFee;
        if (invariantRatioWithoutFees > balanceRatioWithoutFee) {
            // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it to
            // 'token out'. This results in slightly larger price impact.

            uint256 nonTaxableAmount = balance.mulDown(invariantRatioWithoutFees.complement());
            uint256 taxableAmount = amountOut.sub(nonTaxableAmount);
            uint256 taxableAmountPlusFees = taxableAmount.divUp(swapFeePercentage.complement());

            amountOutWithFee = nonTaxableAmount.add(taxableAmountPlusFees);
        } else {
            amountOutWithFee = amountOut;
            // If a token's amount out is not being charged a swap fee then it might be zero.
            // In this case, it's clear that the sender should not send any BPT.
            if (amountOutWithFee == 0) {
                return 0;
            }
        }

        uint256 balanceRatio = balance.sub(amountOutWithFee).divDown(balance);

        uint256 invariantRatio = balanceRatio.powDown(normalizedWeight);

        return bptTotalSupply.mulUp(invariantRatio.complement());
    }

    /**
     * @dev Intermediate function to avoid stack-too-deep errors.
     */
    function _computeExitExactTokensOutInvariantRatio(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256[] memory balanceRatiosWithoutFee,
        uint256 invariantRatioWithoutFees,
        uint256 swapFeePercentage
    ) private pure returns (uint256 invariantRatio) {
        invariantRatio = FixedPoint.ONE;

        for (uint256 i = 0; i < balances.length; i++) {
            // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it to
            // 'token out'. This results in slightly larger price impact.

            uint256 amountOutWithFee;
            if (invariantRatioWithoutFees > balanceRatiosWithoutFee[i]) {
                uint256 nonTaxableAmount = balances[i].mulDown(invariantRatioWithoutFees.complement());
                uint256 taxableAmount = amountsOut[i].sub(nonTaxableAmount);
                uint256 taxableAmountPlusFees = taxableAmount.divUp(swapFeePercentage.complement());

                amountOutWithFee = nonTaxableAmount.add(taxableAmountPlusFees);
            } else {
                amountOutWithFee = amountsOut[i];
                // If a token's amount out is not being charged a swap fee then it might be zero (e.g. when exiting a
                // Pool with only a subset of tokens). In this case, `balanceRatio` will equal `FixedPoint.ONE`, and
                // the `invariantRatio` will not change at all. We therefore skip to the next iteration, avoiding
                // the costly `powDown` call.
                if (amountOutWithFee == 0) {
                    continue;
                }
            }

            uint256 balanceRatio = balances[i].sub(amountOutWithFee).divDown(balances[i]);

            invariantRatio = invariantRatio.mulDown(balanceRatio.powDown(normalizedWeights[i]));
        }
    }

    function _calcTokenOutGivenExactBptIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        /*****************************************************************************************
        // exactBPTInForTokenOut                                                                //
        // a = amountOut                                                                        //
        // b = balance                     /      /    totalBPT - bptIn       \    (1 / w)  \   //
        // bptIn = bptAmountIn    a = b * |  1 - | --------------------------  | ^           |  //
        // bpt = totalBPT                  \      \       totalBPT            /             /   //
        // w = weight                                                                           //
        *****************************************************************************************/

        // Token out, so we round down overall. The multiplication rounds down, but the power rounds up (so the base
        // rounds up). Because (totalBPT - bptIn) / totalBPT <= 1, the exponent rounds down.

        // Calculate the factor by which the invariant will decrease after burning BPTAmountIn
        uint256 invariantRatio = bptTotalSupply.sub(bptAmountIn).divUp(bptTotalSupply);
        _require(invariantRatio >= _MIN_INVARIANT_RATIO, Errors.MIN_BPT_IN_FOR_TOKEN_OUT);

        // Calculate by how much the token balance has to decrease to match invariantRatio
        uint256 balanceRatio = invariantRatio.powUp(FixedPoint.ONE.divDown(normalizedWeight));

        // Because of rounding up, balanceRatio can be greater than one. Using complement prevents reverts.
        uint256 amountOutWithoutFee = balance.mulDown(balanceRatio.complement());

        // We can now compute how much excess balance is being withdrawn as a result of the virtual swaps, which result
        // in swap fees.

        // Swap fees are typically charged on 'token in', but there is no 'token in' here, so we apply it
        // to 'token out'. This results in slightly larger price impact. Fees are rounded up.
        uint256 taxableAmount = amountOutWithoutFee.mulUp(normalizedWeight.complement());
        uint256 nonTaxableAmount = amountOutWithoutFee.sub(taxableAmount);
        uint256 taxableAmountMinusFees = taxableAmount.mulUp(swapFeePercentage.complement());

        return nonTaxableAmount.add(taxableAmountMinusFees);
    }

    function _calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) internal pure returns (uint256[] memory) {
        /**********************************************************************************************
        // exactBPTInForTokensOut                                                                    //
        // (per token)                                                                               //
        // aO = amountOut                  /        bptIn         \                                  //
        // b = balance           a0 = b * | ---------------------  |                                 //
        // bptIn = bptAmountIn             \       totalBPT       /                                  //
        // bpt = totalBPT                                                                            //
        **********************************************************************************************/

        // Since we're computing an amount out, we round down overall. This means rounding down on both the
        // multiplication and division.

        uint256 bptRatio = bptAmountIn.divDown(totalBPT);

        uint256[] memory amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsOut[i] = balances[i].mulDown(bptRatio);
        }

        return amountsOut;
    }

    /**
     * @dev Calculate the amount of BPT which should be minted when adding a new token to the Pool.
     *
     * Note that normalizedWeight is set that it corresponds to the desired weight of this token *after* adding it.
     * i.e. For a two token 50:50 pool which we want to turn into a 33:33:33 pool, we use a normalized weight of 33%
     * @param totalSupply - the total supply of the Pool's BPT.
     * @param normalizedWeight - the normalized weight of the token to be added (normalized relative to final weights)
     */
    function _calcBptOutAddToken(uint256 totalSupply, uint256 normalizedWeight) internal pure returns (uint256) {
        // The amount of BPT which is equivalent to the token being added may be calculated by the growth in the
        // sum of the token weights, i.e. if we add a token which will make up 50% of the pool then we should receive
        // 50% of the new supply of BPT.
        //
        // The growth in the total weight of the pool can be easily calculated by:
        //
        // weightSumRatio = totalWeight / (totalWeight - newTokenWeight)
        //
        // As we're working with normalized weights `totalWeight` is equal to 1.

        uint256 weightSumRatio = FixedPoint.ONE.divDown(FixedPoint.ONE.sub(normalizedWeight));

        // The amount of BPT to mint is then simply:
        //
        // toMint = totalSupply * (weightSumRatio - 1)

        return totalSupply.mulDown(weightSumRatio.sub(FixedPoint.ONE));
    }
}


/**
 * @title Managed Pool Storage Library
 * @notice Library for manipulating a bitmap used for commonly used Pool state in ManagedPool.
 */
library ManagedPoolStorageLib {
    using WordCodec for bytes32;

    /* solhint-disable max-line-length */
    // Store non-token-based values:
    // Start/end timestamps for gradual weight and swap fee updates
    // Start/end values of the swap fee
    // Flags for the LP allowlist, enabling/disabling trading, and recovery mode
    //
    // [  1 bit |   1 bit  |  1 bit  |   1 bit   |    62 bits   |     62 bits    |    32 bits   |     32 bits    | 32 bits |  32 bits  ]
    // [ unused | recovery | LP flag | swap flag | end swap fee | start swap fee | end fee time | start fee time | end wgt | start wgt ]
    // |MSB                                                                                                                         LSB|
    /* solhint-enable max-line-length */
    uint256 private constant _WEIGHT_START_TIME_OFFSET = 0;
    uint256 private constant _WEIGHT_END_TIME_OFFSET = _WEIGHT_START_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_START_TIME_OFFSET = _WEIGHT_END_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_END_TIME_OFFSET = _SWAP_FEE_START_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_START_PCT_OFFSET = _SWAP_FEE_END_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_END_PCT_OFFSET = _SWAP_FEE_START_PCT_OFFSET + _SWAP_FEE_PCT_WIDTH;
    uint256 private constant _SWAP_ENABLED_OFFSET = _SWAP_FEE_END_PCT_OFFSET + _SWAP_FEE_PCT_WIDTH;
    uint256 private constant _MUST_ALLOWLIST_LPS_OFFSET = _SWAP_ENABLED_OFFSET + 1;
    uint256 private constant _RECOVERY_MODE_OFFSET = _MUST_ALLOWLIST_LPS_OFFSET + 1;

    uint256 private constant _TIMESTAMP_WIDTH = 32;
    // 2**60 ~= 1.1e18 so this is sufficient to store the full range of potential swap fees.
    uint256 private constant _SWAP_FEE_PCT_WIDTH = 62;

    // Getters

    /**
     * @notice Returns whether the Pool is currently in Recovery Mode.
     * @param poolState - The byte32 state of the Pool.
     */
    function getRecoveryModeEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_RECOVERY_MODE_OFFSET);
    }

    /**
     * @notice Returns whether the Pool currently allows swaps (and by extension, non-proportional joins/exits).
     * @param poolState - The byte32 state of the Pool.
     */
    function getSwapsEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_SWAP_ENABLED_OFFSET);
    }

    /**
     * @notice Returns whether addresses must be allowlisted to add liquidity to the Pool.
     * @param poolState - The byte32 state of the Pool.
     */
    function getLPAllowlistEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_MUST_ALLOWLIST_LPS_OFFSET);
    }

    /**
     * @notice Returns the percentage progress through the current gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @return pctProgress - A 18 decimal fixed-point value corresponding to how far to interpolate between the start
     * and end weights. 0 represents the start weight and 1 represents the end weight (with values >1 being clipped).
     */
    function getGradualWeightChangeProgress(bytes32 poolState) internal view returns (uint256) {
        (uint256 startTime, uint256 endTime) = getWeightChangeFields(poolState);

        return GradualValueChange.calculateValueChangeProgress(startTime, endTime);
    }

    /**
     * @notice Returns the start and end timestamps of the current gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @param startTime - The timestamp at which the current gradual weight change started/will start.
     * @param endTime - The timestamp at which the current gradual weight change finished/will finish.
     */
    function getWeightChangeFields(bytes32 poolState) internal pure returns (uint256 startTime, uint256 endTime) {
        startTime = poolState.decodeUint(_WEIGHT_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        endTime = poolState.decodeUint(_WEIGHT_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
    }

    /**
     * @notice Returns the current value of the swap fee percentage.
     * @dev Computes the current swap fee percentage, which can change every block if a gradual swap fee
     * update is in progress.
     * @param poolState - The byte32 state of the Pool.
     */
    function getSwapFeePercentage(bytes32 poolState) internal view returns (uint256) {
        (
            uint256 startTime,
            uint256 endTime,
            uint256 startSwapFeePercentage,
            uint256 endSwapFeePercentage
        ) = getSwapFeeFields(poolState);

        return
            GradualValueChange.getInterpolatedValue(startSwapFeePercentage, endSwapFeePercentage, startTime, endTime);
    }

    /**
     * @notice Returns the start and end timestamps of the current gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @return startTime - The timestamp at which the current gradual swap fee change started/will start.
     * @return endTime - The timestamp at which the current gradual swap fee change finished/will finish.
     * @return startSwapFeePercentage - The swap fee value at the start of the current gradual swap fee change.
     * @return endSwapFeePercentage - The swap fee value at the end of the current gradual swap fee change.
     */
    function getSwapFeeFields(bytes32 poolState)
        internal
        pure
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 startSwapFeePercentage,
            uint256 endSwapFeePercentage
        )
    {
        startTime = poolState.decodeUint(_SWAP_FEE_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        endTime = poolState.decodeUint(_SWAP_FEE_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
        startSwapFeePercentage = poolState.decodeUint(_SWAP_FEE_START_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
        endSwapFeePercentage = poolState.decodeUint(_SWAP_FEE_END_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
    }

    // Setters

    /**
     * @notice Sets the "Recovery Mode enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether Recovery Mode is to be enabled.
     */
    function setRecoveryModeEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _RECOVERY_MODE_OFFSET);
    }

    /**
     * @notice Sets the "swaps enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether swaps are to be enabled.
     */
    function setSwapsEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _SWAP_ENABLED_OFFSET);
    }

    /**
     * @notice Sets the "LP allowlist enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether the LP allowlist is to be enforced.
     */
    function setLPAllowlistEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _MUST_ALLOWLIST_LPS_OFFSET);
    }

    /**
     * @notice Sets the start and end times of a gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @param startTime - The timestamp at which the gradual weight change is to start.
     * @param endTime - The timestamp at which the gradual weight change is to finish.
     */
    function setWeightChangeData(
        bytes32 poolState,
        uint256 startTime,
        uint256 endTime
    ) internal pure returns (bytes32) {
        poolState = poolState.insertUint(startTime, _WEIGHT_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        return poolState.insertUint(endTime, _WEIGHT_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
    }

    /**
     * @notice Sets the start and end times of a gradual swap fee change.
     * @param poolState - The byte32 state of the Pool.
     * @param startTime - The timestamp at which the gradual swap fee change is to start.
     * @param endTime - The timestamp at which the gradual swap fee change is to finish.
     * @param startSwapFeePercentage - The desired swap fee value at the start of the gradual swap fee change.
     * @param endSwapFeePercentage - The desired swap fee value at the end of the gradual swap fee change.
     */
    function setSwapFeeData(
        bytes32 poolState,
        uint256 startTime,
        uint256 endTime,
        uint256 startSwapFeePercentage,
        uint256 endSwapFeePercentage
    ) internal pure returns (bytes32) {
        poolState = poolState.insertUint(startTime, _SWAP_FEE_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        poolState = poolState.insertUint(endTime, _SWAP_FEE_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
        poolState = poolState.insertUint(startSwapFeePercentage, _SWAP_FEE_START_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
        return poolState.insertUint(endSwapFeePercentage, _SWAP_FEE_END_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
    }
}


/**
 * @title Managed Pool AUM Storage Library
 * @notice Library for manipulating a bitmap used for Pool state used for charging AUM fees in ManagedPool.
 */
library ManagedPoolAumStorageLib {
    using WordCodec for bytes32;

    // Store AUM fee values:
    // Percentage of AUM to be paid as fees yearly.
    // Timestamp of the most recent collection of AUM fees.
    //
    // [  164 bit |        32 bits       |    60 bits   ]
    // [  unused  | last collection time | aum fee pct. ]
    // |MSB                                          LSB|
    uint256 private constant _AUM_FEE_PERCENTAGE_OFFSET = 0;
    uint256 private constant _LAST_COLLECTION_TIMESTAMP_OFFSET = _AUM_FEE_PERCENTAGE_OFFSET + _AUM_FEE_PCT_WIDTH;

    uint256 private constant _TIMESTAMP_WIDTH = 32;
    // 2**60 ~= 1.1e18 so this is sufficient to store the full range of potential AUM fees.
    uint256 private constant _AUM_FEE_PCT_WIDTH = 60;

    // Getters

    /**
     * @notice Returns the current AUM fee percentage and the timestamp of the last fee collection.
     * @param aumState - The byte32 state of the Pool's AUM fees.
     * @return aumFeePercentage - The percentage of the AUM of the Pool to be charged as fees yearly.
     * @return lastCollectionTimestamp - The timestamp of the last collection of AUM fees.
     */
    function getAumFeeFields(bytes32 aumState)
        internal
        pure
        returns (uint256 aumFeePercentage, uint256 lastCollectionTimestamp)
    {
        aumFeePercentage = aumState.decodeUint(_AUM_FEE_PERCENTAGE_OFFSET, _AUM_FEE_PCT_WIDTH);
        lastCollectionTimestamp = aumState.decodeUint(_LAST_COLLECTION_TIMESTAMP_OFFSET, _TIMESTAMP_WIDTH);
    }

    // Setters

    /**
     * @notice Sets the AUM fee percentage describing what fraction of the Pool should be charged as fees yearly.
     * @param aumState - The byte32 state of the Pool's AUM fees.
     * @param aumFeePercentage - The new percentage of the AUM of the Pool to be charged as fees yearly.
     */
    function setAumFeePercentage(bytes32 aumState, uint256 aumFeePercentage) internal pure returns (bytes32) {
        return aumState.insertUint(aumFeePercentage, _AUM_FEE_PERCENTAGE_OFFSET, _AUM_FEE_PCT_WIDTH);
    }

    /**
     * @notice Sets the timestamp of the last collection of AUM fees
     * @param aumState - The byte32 state of the Pool's AUM fees.
     * @param timestamp - The timestamp of the last collection of AUM fees. `block.timestamp` should usually be passed.
     */
    function setLastCollectionTimestamp(bytes32 aumState, uint256 timestamp) internal pure returns (bytes32) {
        return aumState.insertUint(timestamp, _LAST_COLLECTION_TIMESTAMP_OFFSET, _TIMESTAMP_WIDTH);
    }
}




/**
 * @title Managed Pool Token Library
 * @notice Library for manipulating bitmaps used for storing token-related state in ManagedPool.
 * @dev
 *
 * This library stores all token weights in a normalized format, meaning they add up to 100% (1.0 in 18 decimal fixed
 * point format).
 */
library ManagedPoolTokenStorageLib {
    using WordCodec for bytes32;
    using FixedPoint for uint256;

    // Store token-based values:
    // Each token's scaling factor (encoded as the scaling factor's exponent / token decimals).
    // Each token's starting and ending normalized weights.
    // [ 123 bits |  5 bits  |     64 bits     |     64 bits       |
    // [  unused  | decimals | end norm weight | start norm weight |
    // |MSB                                                     LSB|
    uint256 private constant _START_NORM_WEIGHT_OFFSET = 0;
    uint256 private constant _END_NORM_WEIGHT_OFFSET = _START_NORM_WEIGHT_OFFSET + _NORM_WEIGHT_WIDTH;
    uint256 private constant _DECIMAL_DIFF_OFFSET = _END_NORM_WEIGHT_OFFSET + _NORM_WEIGHT_WIDTH;

    uint256 private constant _NORM_WEIGHT_WIDTH = 64;
    uint256 private constant _DECIMAL_DIFF_WIDTH = 5;

    // Getters

    /**
     * @notice Returns the token's scaling factor.
     * @param tokenState - The byte32 state of the token of interest.
     */
    function getTokenScalingFactor(bytes32 tokenState) internal pure returns (uint256) {
        uint256 decimalsDifference = tokenState.decodeUint(_DECIMAL_DIFF_OFFSET, _DECIMAL_DIFF_WIDTH);

        // This is equivalent to `10**(18+decimalsDifference)` but this form optimizes for 18 decimal tokens.
        return FixedPoint.ONE * 10**decimalsDifference;
    }

    /**
     * @notice Returns the token weight, interpolated between the starting and ending weights.
     * @param tokenState - The byte32 state of the token of interest.
     * @param pctProgress - A 18 decimal fixed-point value corresponding to how far to interpolate between the start
     * and end weights. 0 represents the start weight and 1 represents the end weight (with values >1 being clipped).
     */
    function getTokenWeight(bytes32 tokenState, uint256 pctProgress) internal pure returns (uint256) {
        return
            GradualValueChange.interpolateValue(
                tokenState.decodeUint(_START_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH),
                tokenState.decodeUint(_END_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH),
                pctProgress
            );
    }

    /**
     * @notice Returns the token's starting and ending weights.
     * @param tokenState - The byte32 state of the token of interest.
     * @return normalizedStartWeight - The starting normalized weight of the token.
     * @return normalizedEndWeight - The ending normalized weight of the token.
     */
    function getTokenStartAndEndWeights(bytes32 tokenState)
        internal
        pure
        returns (uint256 normalizedStartWeight, uint256 normalizedEndWeight)
    {
        normalizedStartWeight = tokenState.decodeUint(_START_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH);
        normalizedEndWeight = tokenState.decodeUint(_END_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH);
    }

    // Setters

    /**
     * @notice Updates a token's starting and ending weights.
     * @dev Initiate a gradual weight change between the given starting and ending values.
     * @param tokenState - The byte32 state of the token of interest.
     * @param normalizedStartWeight - The current normalized weight of the token.
     * @param normalizedEndWeight - The desired final normalized weight of the token.
     */
    function setTokenWeight(
        bytes32 tokenState,
        uint256 normalizedStartWeight,
        uint256 normalizedEndWeight
    ) internal pure returns (bytes32) {
        return
            tokenState.insertUint(normalizedStartWeight, _START_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH).insertUint(
                normalizedEndWeight,
                _END_NORM_WEIGHT_OFFSET,
                _NORM_WEIGHT_WIDTH
            );
    }

    /**
     * @notice Writes the token's scaling factor into the token state.
     * @dev To save space, we store the scaling factor as the difference between 18 and the token's decimals,
     * and compute the "raw" scaling factor on the fly.
     * We segregated this function to avoid unnecessary external calls. Token decimals do not change, so we
     * only need to call this once per token: either from the constructor, for the initial set of tokens, or
     * when adding a new token.
     * @param tokenState - The byte32 state of the token of interest.
     * @param token - The ERC20 token of interest.
     */
    function setTokenScalingFactor(bytes32 tokenState, IERC20 token) internal view returns (bytes32) {
        // Tokens that don't implement the `decimals` method are not supported.
        // Tokens with more than 18 decimals are not supported
        return
            tokenState.insertUint(
                uint256(18).sub(ERC20(address(token)).decimals()),
                _DECIMAL_DIFF_OFFSET,
                _DECIMAL_DIFF_WIDTH
            );
    }

    /**
     * @notice Initializes the token state for a new token.
     * @dev Since weights must be fixed during add/remove operations, we only need to supply a single normalized weight.
     * @param token - The ERC20 token of interest.
     * @param normalizedWeight - The normalized weight of the token.
     */
    function initializeTokenState(IERC20 token, uint256 normalizedWeight) internal view returns (bytes32 tokenState) {
        tokenState = setTokenScalingFactor(bytes32(0), token);
        tokenState = setTokenWeight(tokenState, normalizedWeight, normalizedWeight);
    }
}



library ManagedPoolAddRemoveTokenLib {
    // ManagedPool weights and swap fees can change over time: these periods are expected to be long enough (e.g. days)
    // that any timestamp manipulation would achieve very little.
    // solhint-disable not-rely-on-time

    using FixedPoint for uint256;

    function _ensureNoWeightChange(bytes32 poolState) private view {
        (uint256 startTime, uint256 endTime) = ManagedPoolStorageLib.getWeightChangeFields(poolState);

        if (block.timestamp < endTime) {
            _revert(
                block.timestamp < startTime
                    ? Errors.CHANGE_TOKENS_PENDING_WEIGHT_CHANGE
                    : Errors.CHANGE_TOKENS_DURING_WEIGHT_CHANGE
            );
        }
    }

    /**
     * @notice Adds a token to the Pool's list of tradeable tokens.
     *
     * @dev By adding a token to the Pool's composition, the weights of all other tokens will be decreased. The new
     * token will have no balance - it is up to the owner to provide some immediately after calling this function.
     * Note however that regular join functions will not work while the new token has no balance: the only way to
     * deposit an initial amount is by using an Asset Manager.
     *
     * Token addition is forbidden during a weight change, or if one is scheduled to happen in the future.
     *
     * @param vault - The address of the Balancer Vault.
     * @param poolId - The bytes32 poolId of the Pool which to add the token.
     * @param poolState - The byte32 state of the Pool.
     * @param currentTokens - The array of IERC20 tokens held in the Pool prior to adding the new token.
     * @param currentWeights - The array of token weights prior to adding the new token.
     * @param tokenToAdd - The ERC20 token to be added to the Pool.
     * @param assetManager - The Asset Manager for the token.
     * @param tokenToAddNormalizedWeight - The normalized weight of `token` relative to the other tokens in the Pool.
     * @return tokenToAddState - The bytes32 state of the token which has been added.
     * @return newTokens - The updated tokens array once the token has been added.
     * @return newWeights - The updated weights array once the token has been added.
     */
    function addToken(
        IVault vault,
        bytes32 poolId,
        bytes32 poolState,
        IERC20[] memory currentTokens,
        uint256[] memory currentWeights,
        IERC20 tokenToAdd,
        address assetManager,
        uint256 tokenToAddNormalizedWeight
    )
        external
        returns (
            bytes32 tokenToAddState,
            IERC20[] memory newTokens,
            uint256[] memory newWeights
        )
    {
        // BPT cannot be added using this mechanism: Composable Pools manage it via dedicated PoolRegistrationLib
        // functions.
        _require(tokenToAdd != IERC20(address(this)), Errors.ADD_OR_REMOVE_BPT);

        // Tokens cannot be added during or before a weight change, since a) adding a token already involves a weight
        // change and would override an existing one, and b) any previous weight changes would be incomplete since they
        // wouldn't include the new token.
        _ensureNoWeightChange(poolState);

        // We first register the token in the Vault. This makes the Pool enter an invalid state, since one of its tokens
        // has a balance of zero (making the invariant also zero). The Asset Manager must be used to deposit some
        // initial balance and restore regular operation.
        //
        // We don't need to check that the new token is not already in the Pool, as the Vault will simply revert if we
        // try to register it again.
        PoolRegistrationLib.registerToken(vault, poolId, tokenToAdd, assetManager);

        // Once we've updated the state in the Vault, we need to also update our own state. This is a two-step process,
        // since we need to:
        //  a) initialize the state of the new token
        //  b) adjust the weights of all other tokens

        // Initializing the new token is straightforward. The Pool itself doesn't track how many or which tokens it uses
        // (and relies instead on the Vault for this), so we simply store the new token-specific information.
        // Note that we don't need to check here that the weight is valid as this is enforced when updating the weights.
        tokenToAddState = ManagedPoolTokenStorageLib.initializeTokenState(tokenToAdd, tokenToAddNormalizedWeight);

        // Adjusting the weights is a bit more involved however. We need to reduce all other weights to make room for
        // the new one. This is achieved by multipliyng them by a factor of `1 - new token weight`.
        // For example, if a  0.25/0.75 Pool gets added a token with a weight of 0.80, the final weights would be
        // 0.05/0.15/0.80, where 0.05 = 0.25 * (1 - 0.80) and 0.15 = 0.75 * (1 - 0.80).
        uint256 newWeightSum = 0;
        newTokens = new IERC20[](currentTokens.length + 1);
        newWeights = new uint256[](currentWeights.length + 1);
        for (uint256 i = 0; i < currentWeights.length; ++i) {
            newTokens[i] = currentTokens[i];

            newWeights[i] = currentWeights[i].mulDown(FixedPoint.ONE.sub(tokenToAddNormalizedWeight));
            newWeightSum = newWeightSum.add(newWeights[i]);
        }

        // Newly added tokens are always appended to the end of the existing array.
        newTokens[newTokens.length - 1] = tokenToAdd;

        // At this point `newWeights` contains the updated weights for all tokens other than the token to be added.
        // We could naively write `tokenToAddNormalizedWeight` into the last element of the `newWeights` array however,
        // it is possible that the new weights don't add up to f_100% due to rounding errors - the sum might be slightly
        // smaller since we round the weights down. Due to this, we adjust the last weight so that the sum is exact.
        //
        // This error is negligible, since the error introduced in the weight of the last token equals the number of
        // tokens in the worst case (as each weight can be off by one at most), and the minimum weight is 1e16, meaning
        // there's ~15 orders of magnitude between the smallest weight and the error. It is important however that the
        // weights do add up to 100% exactly, as that property is relied on in some parts of the WeightedMath
        // computations.
        newWeights[newWeights.length - 1] = FixedPoint.ONE.sub(newWeightSum);
    }

    /**
     * @notice Removes a token from the Pool's list of tradeable tokens.
     * @dev Tokens can only be removed if the Pool has more than 2 tokens, as it can never have fewer than 2.
     *
     * Token removal is also forbidden during a weight change, or if one is scheduled to happen in the future.
     *
     * @param vault - The address of the Balancer Vault.
     * @param poolId - The bytes32 poolId of the Pool which to add the token.
     * @param poolState - The byte32 state of the Pool.
     * @param currentTokens - The array of IERC20 tokens held in the Pool prior to adding the new token.
     * @param currentWeights - The array of token weights prior to adding the new token.
     * @param tokenToRemove - The ERC20 token to be removed from the Pool.
     * @param tokenToRemoveNormalizedWeight - The normalized weight of `tokenToRemove`.
     * @return newTokens - The updated tokens array once the token has been removed.
     * @return newWeights - The updated weights array once the token has been removed.
     */
    function removeToken(
        IVault vault,
        bytes32 poolId,
        bytes32 poolState,
        IERC20[] memory currentTokens,
        uint256[] memory currentWeights,
        IERC20 tokenToRemove,
        uint256 tokenToRemoveNormalizedWeight
    ) external returns (IERC20[] memory newTokens, uint256[] memory newWeights) {
        // BPT cannot be removed using this mechanism: Composable Pools manage it via dedicated PoolRegistrationLib
        // functions.
        _require(tokenToRemove != IERC20(address(this)), Errors.ADD_OR_REMOVE_BPT);

        // Tokens cannot be removed during or before a weight change, since a) removing a token already involves a
        // weight change and would override an existing one, and b) any previous weight changes would be incorrect since
        // they would include the removed token.
        _ensureNoWeightChange(poolState);

        // Before this function is called, the caller must have withdrawn all balance for `token` from the Pool. This
        // means that the Pool is in an invalid state, since among other things the invariant is zero. Because we're not
        // in a valid state and all value-changing operations will revert, we are free to modify the Pool state (e.g.
        // alter weights).
        //
        // We don't need to test the zero balance since the Vault will simply revert on deregistration if this is not
        // the case, or if the token is not currently registered.
        PoolRegistrationLib.deregisterToken(vault, poolId, tokenToRemove);

        // Once we've updated the state in the Vault, we need to also update our own state. This is a two-step process,
        // since we need to:
        //  a) delete the state of the removed token
        //  b) adjust the weights of all other tokens

        // Adjusting the weights is a bit more involved however. We need to increase all other weights so that they add
        // up to 100%. This is achieved by dividing them by a factor of `1 - old token weight`.
        // For example, if a  0.05/0.15/0.80 Pool has its 80% token removed, the final weights would be 0.25/0.75, where
        // 0.25 = 0.05 / (1 - 0.80) and 0.75 = 0.15 / (1 - 0.80).
        uint256 newWeightSum = 0;
        newTokens = new IERC20[](currentTokens.length - 1);
        newWeights = new uint256[](currentWeights.length - 1);
        for (uint256 i = 0; i < newWeights.length; ++i) {
            if (currentTokens[i] == tokenToRemove) {
                // If we're at the index of the removed token then want to instead insert the weight of the final token.
                // This is because the token at the end of the array will be moved into the index of the removed token
                // in a "swap and pop" operation.
                newTokens[i] = currentTokens[currentTokens.length - 1];
                newWeights[i] = currentWeights[currentWeights.length - 1].divDown(
                    FixedPoint.ONE.sub(tokenToRemoveNormalizedWeight)
                );
            } else {
                newTokens[i] = currentTokens[i];
                newWeights[i] = currentWeights[i].divDown(FixedPoint.ONE.sub(tokenToRemoveNormalizedWeight));
            }
            newWeightSum = newWeightSum.add(newWeights[i]);
        }

        // It is possible that the new weights don't add up to 100% due to rounding errors - the sum might be slightly
        // smaller since we round the weights down. In that case, we adjust the last weight so that the sum is exact.
        //
        // This error is negligible, since the error introduced in the weight of the last token equals the number of
        // tokens in the worst case (as each weight can be off by one at most), and the minimum weight is 1e16, meaning
        // there's ~15 orders of magnitude between the smallest weight and the error. It is important however that the
        // weights do add up to 100% exactly, as that property is relied on in some parts of the WeightedMath
        // computations.
        if (newWeightSum != FixedPoint.ONE) {
            newWeights[newWeights.length - 1] = newWeights[newWeights.length - 1].add(FixedPoint.ONE.sub(newWeightSum));
        }
    }
}


/**
 * @title Managed Pool Settings
 */
abstract contract ManagedPoolSettings is BasePool, ProtocolFeeCache, IManagedPool {
    // ManagedPool weights and swap fees can change over time: these periods are expected to be long enough (e.g. days)
    // that any timestamp manipulation would achieve very little.
    // solhint-disable not-rely-on-time

    using FixedPoint for uint256;
    using WeightedPoolUserData for bytes;

    // State variables

    uint256 private constant _MIN_TOKENS = 2;
    // The upper bound is WeightedMath.MAX_WEIGHTED_TOKENS, but this is constrained by other factors, such as Pool
    // creation gas consumption.
    uint256 private constant _MAX_TOKENS = 50;

    // The swap fee cannot be 100%: calculations that divide by (1-fee) would revert with division by zero.
    // Swap fees close to 100% can still cause reverts when performing join/exit swaps, if the calculated fee
    // amounts exceed the pool's token balances in the Vault. 95% is a very high but safe maximum value, and we want to
    // be permissive to let the owner manage the Pool as they see fit.
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 95e16; // 95%

    // The same logic applies to the AUM fee.
    uint256 private constant _MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 95e16; // 95%

    // We impose a minimum swap fee to create some buy/sell spread, and prevent the Pool from being drained through
    // repeated interactions. We should not need this since we explicity always round favoring the Pool, but a minimum
    // swap fee adds an extra safeguard.
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%

    // Stores commonly used Pool state.
    // This slot is preferred for gas-sensitive operations as it is read in all joins, swaps and exits,
    // and therefore warm.
    // See `ManagedPoolStorageLib.sol` for data layout.
    bytes32 private _poolState;

    // Stores state related to charging AUM fees.
    // See `ManagedPoolAUMStorageLib.sol` for data layout.
    bytes32 private _aumState;

    // Store scaling factor and start/end normalized weights for each token.
    // See `ManagedPoolTokenStorageLib.sol` for data layout.
    mapping(IERC20 => bytes32) private _tokenState;

    // Store the circuit breaker configuration for each token.
    // See `CircuitBreakerStorageLib.sol` for data layout.
    mapping(IERC20 => bytes32) private _circuitBreakerState;

    // If mustAllowlistLPs is enabled, this is the list of addresses allowed to join the pool
    mapping(address => bool) private _allowedAddresses;

    struct NewPoolParams {
        string name;
        string symbol;
        IERC20[] tokens;
        uint256[] normalizedWeights;
        address[] assetManagers;
        uint256 swapFeePercentage;
        bool swapEnabledOnStart;
        bool mustAllowlistLPs;
        uint256 managementAumFeePercentage;
        uint256 aumFeeId;
    }

    constructor(NewPoolParams memory params, IProtocolFeePercentagesProvider protocolFeeProvider)
        ProtocolFeeCache(
            protocolFeeProvider,
            ProviderFeeIDs({ swap: ProtocolFeeType.SWAP, yield: ProtocolFeeType.YIELD, aum: params.aumFeeId })
        )
    {
        uint256 totalTokens = params.tokens.length;
        _require(totalTokens >= _MIN_TOKENS, Errors.MIN_TOKENS);
        _require(totalTokens <= _MAX_TOKENS, Errors.MAX_TOKENS);

        InputHelpers.ensureInputLengthMatch(totalTokens, params.normalizedWeights.length, params.assetManagers.length);

        // Validate and set initial fees
        _setManagementAumFeePercentage(params.managementAumFeePercentage);

        // Initialize the tokens' states with their scaling factors and weights.
        for (uint256 i = 0; i < totalTokens; i++) {
            IERC20 token = params.tokens[i];
            _tokenState[token] = ManagedPoolTokenStorageLib.initializeTokenState(token, params.normalizedWeights[i]);
        }

        // This is technically a noop with regards to the tokens' weights in storage. However, it performs important
        // validation of the token weights (normalization / bounds checking), and emits an event for offchain services.
        _startGradualWeightChange(
            block.timestamp,
            block.timestamp,
            params.normalizedWeights,
            params.normalizedWeights,
            params.tokens
        );

        _startGradualSwapFeeChange(
            block.timestamp,
            block.timestamp,
            params.swapFeePercentage,
            params.swapFeePercentage
        );

        // If false, the pool will start in the disabled state (prevents front-running the enable swaps transaction).
        _setSwapEnabled(params.swapEnabledOnStart);

        // If true, only addresses on the manager-controlled allowlist may join the pool.
        _setMustAllowlistLPs(params.mustAllowlistLPs);
    }

    function _getPoolState() internal view returns (bytes32) {
        return _poolState;
    }

    function _getTokenState(IERC20 token) internal view returns (bytes32) {
        return _tokenState[token];
    }

    function _getCircuitBreakerState(IERC20 token) internal view returns (bytes32) {
        return _circuitBreakerState[token];
    }

    // Virtual Supply

    /**
     * @notice Returns the number of tokens in circulation.
     * @dev For the majority of Pools, this will simply be a wrapper around the `totalSupply` function. However,
     * composable pools premint a large fraction of the BPT supply and place it in the Vault. In this situation,
     * the override would subtract this BPT balance from the total to reflect the actual amount of BPT in circulation.
     */
    function _getVirtualSupply() internal view virtual returns (uint256);

    // Actual Supply

    function getActualSupply() external view override returns (uint256) {
        return _getActualSupply(_getVirtualSupply());
    }

    function _getActualSupply(uint256 virtualSupply) internal view returns (uint256) {
        (uint256 aumFeePercentage, uint256 lastCollectionTimestamp) = getManagementAumFeeParams();
        uint256 aumFeesAmount = ExternalAUMFees.getAumFeesBptAmount(
            virtualSupply,
            block.timestamp,
            lastCollectionTimestamp,
            aumFeePercentage
        );
        return virtualSupply.add(aumFeesAmount);
    }

    // Swap fees

    /**
     * @notice Returns the current value of the swap fee percentage.
     * @dev Computes the current swap fee percentage, which can change every block if a gradual swap fee
     * update is in progress.
     */
    function getSwapFeePercentage() external view override returns (uint256) {
        return ManagedPoolStorageLib.getSwapFeePercentage(_poolState);
    }

    function getGradualSwapFeeUpdateParams()
        external
        view
        override
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 startSwapFeePercentage,
            uint256 endSwapFeePercentage
        )
    {
        return ManagedPoolStorageLib.getSwapFeeFields(_poolState);
    }

    function updateSwapFeeGradually(
        uint256 startTime,
        uint256 endTime,
        uint256 startSwapFeePercentage,
        uint256 endSwapFeePercentage
    ) external override authenticate whenNotPaused {
        _startGradualSwapFeeChange(
            GradualValueChange.resolveStartTime(startTime, endTime),
            endTime,
            startSwapFeePercentage,
            endSwapFeePercentage
        );
    }

    function _validateSwapFeePercentage(uint256 swapFeePercentage) internal pure {
        _require(swapFeePercentage >= _MIN_SWAP_FEE_PERCENTAGE, Errors.MIN_SWAP_FEE_PERCENTAGE);
        _require(swapFeePercentage <= _MAX_SWAP_FEE_PERCENTAGE, Errors.MAX_SWAP_FEE_PERCENTAGE);
    }

    /**
     * @notice Encodes a gradual swap fee update into the Pool state in storage.
     * @param startTime - The timestamp when the swap fee change will begin.
     * @param endTime - The timestamp when the swap fee change will end (must be >= startTime).
     * @param startSwapFeePercentage - The starting value for the swap fee change.
     * @param endSwapFeePercentage - The ending value for the swap fee change. If the current timestamp >= endTime,
     * `getSwapFeePercentage()` will return this value.
     */
    function _startGradualSwapFeeChange(
        uint256 startTime,
        uint256 endTime,
        uint256 startSwapFeePercentage,
        uint256 endSwapFeePercentage
    ) internal {
        _validateSwapFeePercentage(startSwapFeePercentage);
        _validateSwapFeePercentage(endSwapFeePercentage);

        _poolState = ManagedPoolStorageLib.setSwapFeeData(
            _poolState,
            startTime,
            endTime,
            startSwapFeePercentage,
            endSwapFeePercentage
        );

        emit GradualSwapFeeUpdateScheduled(startTime, endTime, startSwapFeePercentage, endSwapFeePercentage);
    }

    // Token weights

    /**
     * @dev Returns all normalized weights, in the same order as the Pool's tokens.
     */
    function _getNormalizedWeights(IERC20[] memory tokens) internal view returns (uint256[] memory normalizedWeights) {
        uint256 weightChangeProgress = ManagedPoolStorageLib.getGradualWeightChangeProgress(_poolState);

        uint256 numTokens = tokens.length;
        normalizedWeights = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            normalizedWeights[i] = ManagedPoolTokenStorageLib.getTokenWeight(
                _tokenState[tokens[i]],
                weightChangeProgress
            );
        }
    }

    function getNormalizedWeights() external view override returns (uint256[] memory) {
        (IERC20[] memory tokens, ) = _getPoolTokens();
        return _getNormalizedWeights(tokens);
    }

    /**
     * @dev Returns the normalized weight of a single token.
     */
    function _getNormalizedWeight(IERC20 token) internal view returns (uint256) {
        return
            ManagedPoolTokenStorageLib.getTokenWeight(
                _tokenState[token],
                ManagedPoolStorageLib.getGradualWeightChangeProgress(_poolState)
            );
    }

    function getGradualWeightUpdateParams()
        external
        view
        override
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        )
    {
        (startTime, endTime) = ManagedPoolStorageLib.getWeightChangeFields(_poolState);

        (IERC20[] memory tokens, ) = _getPoolTokens();

        startWeights = new uint256[](tokens.length);
        endWeights = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            (startWeights[i], endWeights[i]) = ManagedPoolTokenStorageLib.getTokenStartAndEndWeights(
                _tokenState[tokens[i]]
            );
        }
    }

    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        IERC20[] memory tokens,
        uint256[] memory endWeights
    ) external override authenticate whenNotPaused {
        (IERC20[] memory actualTokens, ) = _getPoolTokens();
        InputHelpers.ensureInputLengthMatch(tokens.length, actualTokens.length, endWeights.length);

        for (uint256 i = 0; i < actualTokens.length; ++i) {
            _require(actualTokens[i] == tokens[i], Errors.TOKENS_MISMATCH);
        }

        _startGradualWeightChange(
            GradualValueChange.resolveStartTime(startTime, endTime),
            endTime,
            _getNormalizedWeights(tokens),
            endWeights,
            tokens
        );
    }

    /**
     * @dev Validate the end weights, and set the start weights. `updateWeightsGradually` passes in the current weights
     * as the start weights, so that calling updateWeightsGradually again during an update will not result in any
     * abrupt weight changes. Also update the pool state with the start and end times.
     */
    function _startGradualWeightChange(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory startWeights,
        uint256[] memory endWeights,
        IERC20[] memory tokens
    ) internal {
        uint256 normalizedSum;

        for (uint256 i = 0; i < endWeights.length; i++) {
            uint256 endWeight = endWeights[i];
            _require(endWeight >= WeightedMath._MIN_WEIGHT, Errors.MIN_WEIGHT);
            normalizedSum = normalizedSum.add(endWeight);

            IERC20 token = tokens[i];
            _tokenState[token] = ManagedPoolTokenStorageLib.setTokenWeight(
                _tokenState[token],
                startWeights[i],
                endWeight
            );
        }

        // Ensure that the normalized weights sum to ONE
        _require(normalizedSum == FixedPoint.ONE, Errors.NORMALIZED_WEIGHT_INVARIANT);

        _poolState = ManagedPoolStorageLib.setWeightChangeData(_poolState, startTime, endTime);

        emit GradualWeightUpdateScheduled(startTime, endTime, startWeights, endWeights);
    }

    // Swap Enabled

    function getSwapEnabled() external view override returns (bool) {
        return ManagedPoolStorageLib.getSwapsEnabled(_poolState);
    }

    function setSwapEnabled(bool swapEnabled) external override authenticate whenNotPaused {
        _setSwapEnabled(swapEnabled);
    }

    function _setSwapEnabled(bool swapEnabled) private {
        _poolState = ManagedPoolStorageLib.setSwapsEnabled(_poolState, swapEnabled);

        emit SwapEnabledSet(swapEnabled);
    }

    // LP Allowlist

    function getMustAllowlistLPs() external view override returns (bool) {
        return ManagedPoolStorageLib.getLPAllowlistEnabled(_poolState);
    }

    /**
     * @notice Check whether an LP address is on the allowlist.
     * @dev This simply checks the list, regardless of whether the allowlist feature is enabled, so that the allowlist
     * can be inspected at any time.
     * @param member - The address to check against the allowlist.
     * @return true if the given address is on the allowlist.
     */
    function isAddressOnAllowlist(address member) public view override returns (bool) {
        return _allowedAddresses[member];
    }

    /**
     * @notice Check an LP address against the allowlist.
     * @dev If the allowlist is not enabled, this returns true for every address.
     * @param poolState - The bytes32 representing the state of the pool.
     * @param member - The address to check against the allowlist.
     * @return - Whether the given address is allowed to join the pool.
     */
    function _isAllowedAddress(bytes32 poolState, address member) internal view returns (bool) {
        return !ManagedPoolStorageLib.getLPAllowlistEnabled(poolState) || isAddressOnAllowlist(member);
    }

    function addAllowedAddress(address member) external override authenticate whenNotPaused {
        _require(!isAddressOnAllowlist(member), Errors.ADDRESS_ALREADY_ALLOWLISTED);

        _allowedAddresses[member] = true;
        emit AllowlistAddressAdded(member);
    }

    function removeAllowedAddress(address member) external override authenticate whenNotPaused {
        _require(isAddressOnAllowlist(member), Errors.ADDRESS_NOT_ALLOWLISTED);

        delete _allowedAddresses[member];
        emit AllowlistAddressRemoved(member);
    }

    function setMustAllowlistLPs(bool mustAllowlistLPs) external override authenticate whenNotPaused {
        _setMustAllowlistLPs(mustAllowlistLPs);
    }

    function _setMustAllowlistLPs(bool mustAllowlistLPs) private {
        _poolState = ManagedPoolStorageLib.setLPAllowlistEnabled(_poolState, mustAllowlistLPs);

        emit MustAllowlistLPsSet(mustAllowlistLPs);
    }

    // AUM management fees

    function getManagementAumFeeParams()
        public
        view
        override
        returns (uint256 aumFeePercentage, uint256 lastCollectionTimestamp)
    {
        (aumFeePercentage, lastCollectionTimestamp) = ManagedPoolAumStorageLib.getAumFeeFields(_aumState);

        // If we're in recovery mode, set the fee percentage to zero so that we bypass any fee logic that might fail
        // and prevent LPs from exiting the pool.
        if (ManagedPoolStorageLib.getRecoveryModeEnabled(_poolState)) {
            aumFeePercentage = 0;
        }
    }

    function setManagementAumFeePercentage(uint256 managementAumFeePercentage)
        external
        override
        authenticate
        whenNotPaused
        returns (uint256 amount)
    {
        // We want to prevent the pool manager from retroactively increasing the amount of AUM fees payable.
        // To prevent this, we perform a collection before updating the fee percentage.
        // This is only necessary if the pool has been initialized (which is indicated by a nonzero total supply).
        uint256 supplyBeforeFeeCollection = _getVirtualSupply();
        if (supplyBeforeFeeCollection > 0) {
            amount = _collectAumManagementFees(supplyBeforeFeeCollection);
        }

        _setManagementAumFeePercentage(managementAumFeePercentage);
    }

    function _setManagementAumFeePercentage(uint256 managementAumFeePercentage) private {
        _require(
            managementAumFeePercentage <= _MAX_MANAGEMENT_AUM_FEE_PERCENTAGE,
            Errors.MAX_MANAGEMENT_AUM_FEE_PERCENTAGE
        );

        _aumState = ManagedPoolAumStorageLib.setAumFeePercentage(_aumState, managementAumFeePercentage);
        emit ManagementAumFeePercentageChanged(managementAumFeePercentage);
    }

    /**
     * @notice Stores the current timestamp as the most recent collection of AUM fees.
     * @dev This function *must* be called after each collection of AUM fees.
     */
    function _updateAumFeeCollectionTimestamp() internal {
        _aumState = ManagedPoolAumStorageLib.setLastCollectionTimestamp(_aumState, block.timestamp);
    }

    function collectAumManagementFees() external override whenNotPaused returns (uint256) {
        // It only makes sense to collect AUM fees after the pool is initialized (as before then the AUM is zero).
        // We can query if the pool is initialized by checking for a nonzero total supply.
        // Reverting here prevents zero value AUM fee collections causing bogus events.
        uint256 supply = _getVirtualSupply();
        _require(supply > 0, Errors.UNINITIALIZED);
        return _collectAumManagementFees(supply);
    }

    /**
     * @notice Calculates the AUM fees accrued since the last collection and pays it to the pool manager.
     * @dev The AUM fee calculation is based on inflating the Pool's BPT supply by a target rate. This assumes
     * a constant virtual supply between fee collections. To ensure proper accounting, we must therefore collect
     * AUM fees whenever the virtual supply of the Pool changes.
     *
     * This collection mints the difference between the virtual supply and the actual supply. By adding the amount of
     * BPT returned by this function to the virtual supply passed in, we may calculate the updated virtual supply
     * (which is equal to the actual supply).
     * @return bptAmount - The amount of BPT minted as AUM fees.
     */
    function _collectAumManagementFees(uint256 virtualSupply) internal returns (uint256) {
        (uint256 aumFeePercentage, uint256 lastCollectionTimestamp) = getManagementAumFeeParams();
        uint256 bptAmount = ExternalAUMFees.getAumFeesBptAmount(
            virtualSupply,
            block.timestamp,
            lastCollectionTimestamp,
            aumFeePercentage
        );

        // We always update last collection timestamp even when there is nothing to collect to ensure the state is kept
        // consistent.
        _updateAumFeeCollectionTimestamp();

        // Early return if either:
        // - AUM fee is disabled.
        // - no time has passed since the last collection.
        if (bptAmount == 0) {
            return 0;
        }

        // Split AUM fees between protocol and Pool manager. In low liquidity situations, rounding may result in a
        // managerBPTAmount of zero. In general, when splitting fees, LPs come first, followed by the protocol,
        // followed by the manager.
        // uint256 protocolBptAmount = bptAmount.mulUp(getProtocolFeePercentageCache(ProtocolFeeType.AUM));
        // uint256 managerBPTAmount = bptAmount.sub(protocolBptAmount);

        // _payProtocolFees(protocolBptAmount);

        // emit ManagementAumFeeCollected(managerBPTAmount);

        // _mintPoolTokens(getOwner(), managerBPTAmount);

        return bptAmount;
    }

    // Add/Remove tokens

    function addToken(
        IERC20 tokenToAdd,
        address assetManager,
        uint256 tokenToAddNormalizedWeight,
        uint256 mintAmount,
        address recipient
    ) external override authenticate whenNotPaused {
        {
            // This complex operation might mint BPT, altering the supply. For simplicity, we forbid adding tokens
            // before initialization (i.e. before BPT is first minted). We must also collect AUM fees every time the
            // BPT supply changes. For consistency, we do this always, even if the amount to mint is zero.
            uint256 supply = _getVirtualSupply();
            _require(supply > 0, Errors.UNINITIALIZED);
            _collectAumManagementFees(supply);
        }

        (IERC20[] memory tokens, ) = _getPoolTokens();
        _require(tokens.length + 1 <= _MAX_TOKENS, Errors.MAX_TOKENS);

        // `ManagedPoolAddRemoveTokenLib.addToken` performs any necessary state updates in the Vault and returns
        // values necessary for the Pool to update its own state.
        (bytes32 tokenToAddState, IERC20[] memory newTokens, uint256[] memory newWeights) = ManagedPoolAddRemoveTokenLib
            .addToken(
            getVault(),
            getPoolId(),
            _poolState,
            tokens,
            _getNormalizedWeights(tokens),
            tokenToAdd,
            assetManager,
            tokenToAddNormalizedWeight
        );

        // Once we've updated the state in the Vault, we also need to update our own state. This is a two-step process,
        // since we need to:
        //  a) initialize the state of the new token
        //  b) adjust the weights of all other tokens

        // Initializing the new token is straightforward. The Pool itself doesn't track how many or which tokens it uses
        // (and relies instead on the Vault for this), so we simply store the new token-specific information.
        // Note that we don't need to check here that the weight is valid. We'll later call `_startGradualWeightChange`,
        // which will check the entire set of weights for correctness.
        _tokenState[tokenToAdd] = tokenToAddState;

        // `_startGradualWeightChange` will perform all required validation on the new weights, including minimum
        // weights, sum, etc., so we don't need to worry about that ourselves.
        // Note that this call will set the weight for `tokenToAdd`, which we've already done - that'll just be a no-op.
        _startGradualWeightChange(block.timestamp, block.timestamp, newWeights, newWeights, newTokens);

        if (mintAmount > 0) {
            _mintPoolTokens(recipient, mintAmount);
        }

        emit TokenAdded(tokenToAdd, tokenToAddNormalizedWeight);
    }

    function removeToken(
        IERC20 tokenToRemove,
        uint256 burnAmount,
        address sender
    ) external override authenticate whenNotPaused {
        {
            // Add new scope to avoid stack too deep.

            // This complex operation might burn BPT, altering the supply. For simplicity, we forbid removing tokens
            // before initialization (i.e. before BPT is first minted). We must also collect AUM fees every time the
            // BPT supply changes. For consistency, we do this always, even if the amount to burn is zero.
            uint256 supply = _getVirtualSupply();
            _require(supply > 0, Errors.UNINITIALIZED);
            _collectAumManagementFees(supply);
        }

        (IERC20[] memory tokens, ) = _getPoolTokens();
        _require(tokens.length - 1 >= 2, Errors.MIN_TOKENS);

        // Token removal is forbidden during a weight change or if one is scheduled so we can assume that
        // the weight change progress is 100%.
        uint256 tokenToRemoveNormalizedWeight = ManagedPoolTokenStorageLib.getTokenWeight(
            _tokenState[tokenToRemove],
            FixedPoint.ONE
        );

        // `ManagedPoolAddRemoveTokenLib.removeToken` performs any necessary state updates in the Vault and returns
        // values necessary for the Pool to update its own state.
        (IERC20[] memory newTokens, uint256[] memory newWeights) = ManagedPoolAddRemoveTokenLib.removeToken(
            getVault(),
            getPoolId(),
            _poolState,
            tokens,
            _getNormalizedWeights(tokens),
            tokenToRemove,
            tokenToRemoveNormalizedWeight
        );

        // Once we've updated the state in the Vault, we also need to update our own state. This is a two-step process,
        // since we need to:
        //  a) delete the state of the removed token
        //  b) adjust the weights of all other tokens

        // Deleting the old token is straightforward. The Pool itself doesn't track how many or which tokens it uses
        // (and relies instead on the Vault for this), so we simply delete the token-specific information.
        delete _tokenState[tokenToRemove];

        // `_startGradualWeightChange` will perform all required validation on the new weights, including minimum
        // weights, sum, etc., so we don't need to worry about that ourselves.
        _startGradualWeightChange(block.timestamp, block.timestamp, newWeights, newWeights, newTokens);

        if (burnAmount > 0) {
            // We disallow burning from the zero address, as that would allow potentially returning the Pool to the
            // uninitialized state.
            _require(sender != address(0), Errors.BURN_FROM_ZERO);
            _burnPoolTokens(sender, burnAmount);
        }

        // The Pool is now again in a valid state: by the time the zero valued token is deregistered, all internal Pool
        // state is updated.

        emit TokenRemoved(tokenToRemove);
    }

    // Scaling Factors

    function getScalingFactors() external view override returns (uint256[] memory) {
        (IERC20[] memory tokens, ) = _getPoolTokens();
        return _scalingFactors(tokens);
    }

    function _scalingFactors(IERC20[] memory tokens) internal view returns (uint256[] memory scalingFactors) {
        uint256 numTokens = tokens.length;
        scalingFactors = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            scalingFactors[i] = ManagedPoolTokenStorageLib.getTokenScalingFactor(_tokenState[tokens[i]]);
        }
    }

    // Protocol Fee Cache

    /**
     * @dev Pays any due protocol and manager fees before updating the cached protocol fee percentages.
     */
    function _beforeProtocolFeeCacheUpdate() internal override {
        // We pay any due protocol or manager fees *before* updating the cache. This ensures that the new
        // percentages only affect future operation of the Pool, and not past fees.

        // Given that this operation is state-changing and relatively complex, we only allow it as long as the Pool is
        // not paused.
        _ensureNotPaused();

        // We skip fee collection until the Pool is initialized.
        uint256 supplyBeforeFeeCollection = _getVirtualSupply();
        if (supplyBeforeFeeCollection > 0) {
            _collectAumManagementFees(supplyBeforeFeeCollection);
        }
    }

    // Recovery Mode

    /**
     * @notice Returns whether the pool is in Recovery Mode.
     */
    function inRecoveryMode() public view override returns (bool) {
        return ManagedPoolStorageLib.getRecoveryModeEnabled(_poolState);
    }

    /**
     * @dev Sets the recoveryMode state, and emits the corresponding event.
     */
    function _setRecoveryMode(bool enabled) internal override {
        _poolState = ManagedPoolStorageLib.setRecoveryModeEnabled(_poolState, enabled);

        // Some pools need to update their state when leaving recovery mode to ensure proper functioning of the Pool.
        // We do not perform any state updates when entering recovery mode, as this may jeopardize the ability to
        // enable Recovery mode.
        if (!enabled) {
            // Recovery mode exits bypass the AUM fee calculation. This means that if the Pool is paused and in
            // Recovery mode for a period of time, then later returns to normal operation, AUM fees will be charged
            // to the remaining LPs for the full period. We then update the collection timestamp so that no AUM fees
            // are accrued over this period.
            _updateAumFeeCollectionTimestamp();
        }
    }

    // Circuit Breakers

    function getCircuitBreakerState(IERC20 token)
        external
        view
        override
        returns (
            uint256 bptPrice,
            uint256 referenceWeight,
            uint256 lowerBound,
            uint256 upperBound,
            uint256 lowerBptPriceBound,
            uint256 upperBptPriceBound
        )
    {
        bytes32 circuitBreakerState = _circuitBreakerState[token];

        (bptPrice, referenceWeight, lowerBound, upperBound) = CircuitBreakerStorageLib.getCircuitBreakerFields(
            circuitBreakerState
        );

        uint256 normalizedWeight = _getNormalizedWeight(token);

        lowerBptPriceBound = CircuitBreakerStorageLib.getBptPriceBound(circuitBreakerState, normalizedWeight, true);
        upperBptPriceBound = CircuitBreakerStorageLib.getBptPriceBound(circuitBreakerState, normalizedWeight, false);

        // Restore the original unscaled BPT price passed in `setCircuitBreakers`.
        uint256 tokenScalingFactor = ManagedPoolTokenStorageLib.getTokenScalingFactor(_getTokenState(token));
        bptPrice = _upscale(bptPrice, tokenScalingFactor);

        // Also render the adjusted bounds as unscaled values.
        lowerBptPriceBound = _upscale(lowerBptPriceBound, tokenScalingFactor);
        upperBptPriceBound = _upscale(upperBptPriceBound, tokenScalingFactor);
    }

    function setCircuitBreakers(
        IERC20[] memory tokens,
        uint256[] memory bptPrices,
        uint256[] memory lowerBoundPercentages,
        uint256[] memory upperBoundPercentages
    ) external override authenticate whenNotPaused {
        InputHelpers.ensureInputLengthMatch(tokens.length, lowerBoundPercentages.length, upperBoundPercentages.length);
        InputHelpers.ensureInputLengthMatch(tokens.length, bptPrices.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _setCircuitBreaker(tokens[i], bptPrices[i], lowerBoundPercentages[i], upperBoundPercentages[i]);
        }
    }

    // Compute the reference values, then pass them along with the bounds to the library. The bptPrice must be
    // passed in from the caller, or it would be manipulable. We assume the bptPrice from the caller was computed
    // using the native (i.e., unscaled) token balance.
    function _setCircuitBreaker(
        IERC20 token,
        uint256 bptPrice,
        uint256 lowerBoundPercentage,
        uint256 upperBoundPercentage
    ) private {
        uint256 normalizedWeight = _getNormalizedWeight(token);
        // Fail if the token is not in the pool (or is the BPT token)
        _require(normalizedWeight != 0, Errors.INVALID_TOKEN);

        // The incoming BPT price (defined as actualSupply * weight / balance) will have been calculated dividing
        // by unscaled token balance, effectively multiplying the result by the scaling factor.
        // To correct this, we need to divide by it (downscaling).
        uint256 scaledBptPrice = _downscaleDown(
            bptPrice,
            ManagedPoolTokenStorageLib.getTokenScalingFactor(_getTokenState(token))
        );

        // The library will validate the lower/upper bounds
        _circuitBreakerState[token] = CircuitBreakerStorageLib.setCircuitBreaker(
            scaledBptPrice,
            normalizedWeight,
            lowerBoundPercentage,
            upperBoundPercentage
        );

        // Echo the unscaled BPT price in the event.
        emit CircuitBreakerSet(token, bptPrice, lowerBoundPercentage, upperBoundPercentage);
    }

    // Misc

    /**
     * @dev Enumerates all ownerOnly functions in Managed Pool.
     */
    function _isOwnerOnlyAction(bytes32 actionId) internal view override returns (bool) {
        return
            (actionId == getActionId(ManagedPoolSettings.updateWeightsGradually.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.updateSwapFeeGradually.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.setSwapEnabled.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.addAllowedAddress.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.removeAllowedAddress.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.setMustAllowlistLPs.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.addToken.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.removeToken.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.setManagementAumFeePercentage.selector)) ||
            (actionId == getActionId(ManagedPoolSettings.setCircuitBreakers.selector));
    }

    /**
     * @notice Returns the tokens in the Pool and their current balances.
     * @dev This function must be overridden to process these arrays according to the specific pool type.
     * A common example of this is in composable pools, as we may need to drop the BPT token and its balance.
     */
    function _getPoolTokens() internal view virtual returns (IERC20[] memory tokens, uint256[] memory balances);
}


/**
 * @title Managed Pool
 * @dev Weighted Pool with mutable tokens and weights, designed to be used in conjunction with a contract
 * (as the owner, containing any specific business logic). Since the pool itself permits "dangerous"
 * operations, it should never be deployed with an EOA as the owner.
 *
 * The owner contract can impose arbitrary access control schemes on its permissions: it might allow a multisig
 * to add or remove tokens, and let an EOA set the swap fees.
 *
 * Pool owners can also serve as intermediate contracts to hold tokens, deploy timelocks, consult with
 * other protocols or on-chain oracles, or bundle several operations into one transaction that re-entrancy
 * protection would prevent initiating from the pool contract.
 *
 * Managed Pools are designed to support many asset management use cases, including: large token counts,
 * rebalancing through token changes, gradual weight or fee updates, fine-grained control of protocol and
 * management fees, allowlisting of LPs, and more.
 */
contract ManagedPool is ManagedPoolSettings {
    // ManagedPool weights and swap fees can change over time: these periods are expected to be long enough (e.g. days)
    // that any timestamp manipulation would achieve very little.
    // solhint-disable not-rely-on-time

    using FixedPoint for uint256;
    using BasePoolUserData for bytes;
    using WeightedPoolUserData for bytes;

    // The maximum imposed by the Vault, which stores balances in a packed format, is 2**(112) - 1.
    // We are only minting half of the maximum value - already an amount many orders of magnitude greater than any
    // conceivable real liquidity - to allow for minting new BPT as a result of regular joins.
    uint256 private constant _PREMINTED_TOKEN_BALANCE = 2**(111);
    IExternalWeightedMath private immutable _weightedMath;

    constructor(
        NewPoolParams memory params,
        IVault vault,
        IProtocolFeePercentagesProvider protocolFeeProvider,
        IExternalWeightedMath weightedMath,
        address owner,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration
    )
        BasePool(
            vault,
            PoolRegistrationLib.registerComposablePool(
                vault,
                IVault.PoolSpecialization.MINIMAL_SWAP_INFO,
                params.tokens,
                params.assetManagers
            ),
            params.name,
            params.symbol,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
        ManagedPoolSettings(params, protocolFeeProvider)
    {
        _weightedMath = weightedMath;
    }

    function _getWeightedMath() internal view returns (IExternalWeightedMath) {
        return _weightedMath;
    }

    // Virtual Supply

    /**
     * @notice Returns the number of tokens in circulation.
     * @dev In other pools, this would be the same as `totalSupply`, but since this pool pre-mints BPT and holds it in
     * the Vault as a token, we need to subtract the Vault's balance to get the total "circulating supply". Both the
     * totalSupply and Vault balance can change. If users join or exit using swaps, some of the preminted BPT are
     * exchanged, so the Vault's balance increases after joins and decreases after exits. If users call the recovery
     * mode exit function, the totalSupply can change as BPT are burned.
     *
     * The virtual supply can also be calculated by calling ComposablePoolLib.dropBptFromBalances with appropriate
     * inputs, which is the preferred approach whenever possible, as it avoids extra calls to the Vault.
     */
    function _getVirtualSupply() internal view override returns (uint256) {
        (uint256 cash, uint256 managed, , ) = getVault().getPoolTokenInfo(getPoolId(), IERC20(this));
        // We don't need to use SafeMath here as the Vault restricts token balances to be less than 2**112.
        // This ensures that `cash + managed` cannot overflow and the Pool's balance of BPT cannot exceed the total
        // supply so we cannot underflow either.
        return totalSupply() - (cash + managed);
    }

    // Swap Hooks

    /**
     * @dev Dispatch code for all kinds of swaps. Depending on the tokens involved this could result in a join, exit or
     * a standard swap between two token in the Pool.
     *
     * The return value is expected to be downscaled (appropriately rounded based on the swap type) ready to be passed
     * to the Vault.
     */
    function _onSwapMinimal(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) internal override returns (uint256) {
        bytes32 poolState = _getPoolState();

        // ManagedPool is a composable Pool, so a swap could be either a join swap, an exit swap, or a token swap.
        // By checking whether the incoming or outgoing token is the BPT, we can determine which kind of
        // operation we want to perform and pass it to the appropriate handler.
        //
        // We block all types of swap if swaps are disabled as a token swap is equivalent to a join swap followed by
        // an exit swap into a different token.
        _require(ManagedPoolStorageLib.getSwapsEnabled(poolState), Errors.SWAPS_DISABLED);

        if (request.tokenOut == IERC20(this)) {
            // `tokenOut` is the BPT, so this is a join swap.

            // Check allowlist for LPs, if applicable
            _require(_isAllowedAddress(poolState, request.from), Errors.ADDRESS_NOT_ALLOWLISTED);

            // This is equivalent to `_getVirtualSupply()`, but as `balanceTokenOut` is the Vault's balance of BPT
            // we can avoid querying this value again from the Vault as we do in `_getVirtualSupply()`.
            uint256 virtualSupply = totalSupply() - balanceTokenOut;

            // See documentation for `getActualSupply()` and `_collectAumManagementFees()`.
            uint256 actualSupply = virtualSupply + _collectAumManagementFees(virtualSupply);

            return _onJoinSwap(request, balanceTokenIn, actualSupply, poolState);
        } else if (request.tokenIn == IERC20(this)) {
            // `tokenIn` is the BPT, so this is an exit swap.

            // Note that we do not check the LP allowlist here. LPs must always be able to exit the pool,
            // and enforcing the allowlist would allow the manager to perform DOS attacks on LPs.

            // This is equivalent to `_getVirtualSupply()`, but as `balanceTokenIn` is the Vault's balance of BPT
            // we can avoid querying this value again from the Vault as we do in `_getVirtualSupply()`.
            uint256 virtualSupply = totalSupply() - balanceTokenIn;

            // See documentation for `getActualSupply()` and `_collectAumManagementFees()`.
            uint256 actualSupply = virtualSupply + _collectAumManagementFees(virtualSupply);

            return _onExitSwap(request, balanceTokenOut, actualSupply, poolState);
        } else {
            // Neither token is the BPT, so this is a standard token swap.
            return _onTokenSwap(request, balanceTokenIn, balanceTokenOut, poolState);
        }
    }

    /*
     * @dev Called when a swap with the Pool occurs, where the tokens leaving the Pool are BPT.
     *
     * This function is responsible for upscaling any amounts received, in particular `balanceTokenIn`
     * and `request.amount`.
     *
     * The return value is expected to be downscaled (appropriately rounded based on the swap type) ready to be passed
     * to the Vault.
     */
    function _onJoinSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 actualSupply,
        bytes32 poolState
    ) internal view returns (uint256) {
        // We first query data needed to perform the joinswap, i.e. the token weight and scaling factor as well as the
        // Pool's swap fee.
        (uint256 tokenInWeight, uint256 scalingFactorTokenIn) = _getTokenInfo(
            request.tokenIn,
            ManagedPoolStorageLib.getGradualWeightChangeProgress(poolState)
        );
        uint256 swapFeePercentage = ManagedPoolStorageLib.getSwapFeePercentage(poolState);

        // `_onSwapMinimal` passes unscaled values so we upscale the token balance.
        balanceTokenIn = _upscale(balanceTokenIn, scalingFactorTokenIn);

        // We may also need to upscale `request.amount`, however we do not yet know this as that depends on whether that
        // is a token amount (GIVEN_IN) or a BPT amount (GIVEN_OUT), which gets no scaling.
        //
        // Therefore we branch depending on the swap kind and calculate the `bptAmountOut` for GIVEN_IN joinswaps or the
        // `amountIn` for GIVEN_OUT joinswaps. We call these values the `amountCalculated`.
        uint256 amountCalculated;
        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // In `GIVEN_IN` joinswaps, `request.amount` is the amount of tokens entering the pool so we upscale with
            // `scalingFactorTokenIn`.
            request.amount = _upscale(request.amount, scalingFactorTokenIn);

            // Once fees are removed we can then calculate the equivalent BPT amount.
            amountCalculated = _getWeightedMath().calcBptOutGivenExactTokenIn(
                balanceTokenIn,
                tokenInWeight,
                request.amount,
                actualSupply,
                swapFeePercentage
            );
        } else {
            // In `GIVEN_OUT` joinswaps, `request.amount` is the amount of BPT leaving the pool, which does not need any
            // scaling.
            amountCalculated = _getWeightedMath().calcTokenInGivenExactBptOut(
                balanceTokenIn,
                tokenInWeight,
                request.amount,
                actualSupply,
                swapFeePercentage
            );
        }

        // A joinswap decreases the price of the token entering the Pool and increases the price of all other tokens.
        // ManagedPool's circuit breakers prevent the tokens' prices from leaving certain bounds so we must  check that
        // we haven't tripped a breaker as a result of the joinswap.
        _checkCircuitBreakersOnJoinOrExitSwap(request, actualSupply, amountCalculated, true);

        // Finally we downscale `amountCalculated` before we return it.
        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // BPT is leaving the Pool, which doesn't need scaling.
            return amountCalculated;
        } else {
            // `amountCalculated` tokens are entering the Pool, so we round up.
            return _downscaleUp(amountCalculated, scalingFactorTokenIn);
        }
    }

    /*
     * @dev Called when a swap with the Pool occurs, where the tokens entering the Pool are BPT.
     *
     * This function is responsible for upscaling any amounts received, in particular `balanceTokenOut`
     * and `request.amount`.
     *
     * The return value is expected to be downscaled (appropriately rounded based on the swap type) ready to be passed
     * to the Vault.
     */
    function _onExitSwap(
        SwapRequest memory request,
        uint256 balanceTokenOut,
        uint256 actualSupply,
        bytes32 poolState
    ) internal view returns (uint256) {
        // We first query data needed to perform the exitswap, i.e. the token weight and scaling factor as well as the
        // Pool's swap fee.
        (uint256 tokenOutWeight, uint256 scalingFactorTokenOut) = _getTokenInfo(
            request.tokenOut,
            ManagedPoolStorageLib.getGradualWeightChangeProgress(poolState)
        );
        uint256 swapFeePercentage = ManagedPoolStorageLib.getSwapFeePercentage(poolState);

        // `_onSwapMinimal` passes unscaled values so we upscale the token balance.
        balanceTokenOut = _upscale(balanceTokenOut, scalingFactorTokenOut);

        // We may also need to upscale `request.amount`, however we do not yet know this as that depends on whether that
        // is a BPT amount (GIVEN_IN), which gets no scaling, or a token amount (GIVEN_OUT).
        //
        // Therefore we branch depending on the swap kind and calculate the `amountOut` for GIVEN_IN exitswaps or the
        // `bptAmountIn` for GIVEN_OUT exitswaps. We call these values the `amountCalculated`.
        uint256 amountCalculated;
        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // In `GIVEN_IN` exitswaps, `request.amount` is the amount of BPT entering the pool, which does not need any
            // scaling.
            amountCalculated = _getWeightedMath().calcTokenOutGivenExactBptIn(
                balanceTokenOut,
                tokenOutWeight,
                request.amount,
                actualSupply,
                swapFeePercentage
            );
        } else {
            // In `GIVEN_OUT` exitswaps, `request.amount` is the amount of tokens leaving the pool so we upscale with
            // `scalingFactorTokenOut`.
            request.amount = _upscale(request.amount, scalingFactorTokenOut);

            amountCalculated = _getWeightedMath().calcBptInGivenExactTokenOut(
                balanceTokenOut,
                tokenOutWeight,
                request.amount,
                actualSupply,
                swapFeePercentage
            );
        }

        // A exitswap increases the price of the token leaving the Pool and decreases the price of all other tokens.
        // ManagedPool's circuit breakers prevent the tokens' prices from leaving certain bounds so we must  check that
        // we haven't tripped a breaker as a result of the exitswap.
        _checkCircuitBreakersOnJoinOrExitSwap(request, actualSupply, amountCalculated, false);

        // Finally we downscale `amountCalculated` before we return it.
        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // `amountCalculated` tokens are exiting the Pool, so we round down.
            return _downscaleDown(amountCalculated, scalingFactorTokenOut);
        } else {
            // BPT is entering the Pool, which doesn't need scaling.
            return amountCalculated;
        }
    }

    // Holds information for the tokens involved in a regular swap.
    struct SwapTokenData {
        uint256 tokenInWeight;
        uint256 tokenOutWeight;
        uint256 scalingFactorTokenIn;
        uint256 scalingFactorTokenOut;
    }

    /*
     * @dev Called when a swap with the Pool occurs, where neither of the tokens involved are the BPT of the Pool.
     *
     * This function is responsible for upscaling any amounts received, in particular `balanceTokenIn`,
     * `balanceTokenOut` and `request.amount`.
     *
     * The return value is expected to be downscaled (appropriately rounded based on the swap type) ready to be passed
     * to the Vault.
     */
    function _onTokenSwap(
        SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        bytes32 poolState
    ) internal view returns (uint256) {
        // We first query data needed to perform the swap, i.e. token weights and scaling factors as well as the Pool's
        // swap fee (in the form of its complement).
        SwapTokenData memory tokenData = _getSwapTokenData(request, poolState);
        uint256 swapFeeComplement = ManagedPoolStorageLib.getSwapFeePercentage(poolState).complement();

        // `_onSwapMinimal` passes unscaled values so we upscale token balances using the appropriate scaling factors.
        balanceTokenIn = _upscale(balanceTokenIn, tokenData.scalingFactorTokenIn);
        balanceTokenOut = _upscale(balanceTokenOut, tokenData.scalingFactorTokenOut);

        // We must also upscale `request.amount` however we do not yet know which scaling factor to use as this differs
        // depending on whether it represents an amount of tokens entering (GIVEN_IN) or leaving (GIVEN_OUT) the Pool.
        //
        // Therefore we branch depending on the swap kind and calculate the `amountOut` for GIVEN_IN swaps or the
        // `amountIn` for GIVEN_OUT swaps. We call these values the `amountCalculated`.
        uint256 amountCalculated;
        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // In `GIVEN_IN` swaps, `request.amount` is the amount of tokens entering the pool so we upscale with
            // `scalingFactorTokenIn`.
            request.amount = _upscale(request.amount, tokenData.scalingFactorTokenIn);

            // We then subtract swap fees from this amount so the collected swap fees aren't use to calculate how many
            // tokens the trader will receive. We round this value down (favoring a higher fee amount).
            uint256 amountInMinusFees = request.amount.mulDown(swapFeeComplement);

            // Once fees are removed we can then calculate the equivalent amount of `tokenOut`.
            amountCalculated = _getWeightedMath().calcOutGivenIn(
                balanceTokenIn,
                tokenData.tokenInWeight,
                balanceTokenOut,
                tokenData.tokenOutWeight,
                amountInMinusFees
            );
        } else {
            // In `GIVEN_OUT` swaps, `request.amount` is the amount of tokens leaving the pool so we upscale with
            // `scalingFactorTokenOut`.
            request.amount = _upscale(request.amount, tokenData.scalingFactorTokenOut);

            // We first calculate how many tokens must be sent in order to receive `request.amount` tokens out.
            // This calculation does not yet include fees.
            uint256 amountInMinusFees = _getWeightedMath().calcInGivenOut(
                balanceTokenIn,
                tokenData.tokenInWeight,
                balanceTokenOut,
                tokenData.tokenOutWeight,
                request.amount
            );

            // We then add swap fees to this amount so the trader must send extra tokens.
            // We round this value up (favoring a higher fee amount).
            amountCalculated = amountInMinusFees.divUp(swapFeeComplement);
        }

        // A token swap increases the price of the token leaving the Pool and reduces the price of the token entering
        // the Pool. ManagedPool's circuit breakers prevent the tokens' prices from leaving certain bounds so we must
        // check that we haven't tripped a breaker as a result of the token swap.
        _checkCircuitBreakersOnRegularSwap(request, tokenData, balanceTokenIn, balanceTokenOut, amountCalculated);

        // Finally we downscale `amountCalculated` before we return it. We want to round this value in favour of the
        // Pool so apply different scaling on amounts entering or leaving the Pool.
        if (request.kind == IVault.SwapKind.GIVEN_IN) {
            // `amountCalculated` tokens are exiting the Pool, so we round down.
            return _downscaleDown(amountCalculated, tokenData.scalingFactorTokenOut);
        } else {
            // `amountCalculated` tokens are entering the Pool, so we round up.
            return _downscaleUp(amountCalculated, tokenData.scalingFactorTokenIn);
        }
    }

    /**
     * @dev Gather the information required to process a regular token swap. This is required to avoid stack-too-deep
     * issues.
     */
    function _getSwapTokenData(SwapRequest memory request, bytes32 poolState)
        private
        view
        returns (SwapTokenData memory tokenInfo)
    {
        bytes32 tokenInState = _getTokenState(request.tokenIn);
        bytes32 tokenOutState = _getTokenState(request.tokenOut);

        uint256 weightChangeProgress = ManagedPoolStorageLib.getGradualWeightChangeProgress(poolState);
        tokenInfo.tokenInWeight = ManagedPoolTokenStorageLib.getTokenWeight(tokenInState, weightChangeProgress);
        tokenInfo.tokenOutWeight = ManagedPoolTokenStorageLib.getTokenWeight(tokenOutState, weightChangeProgress);

        tokenInfo.scalingFactorTokenIn = ManagedPoolTokenStorageLib.getTokenScalingFactor(tokenInState);
        tokenInfo.scalingFactorTokenOut = ManagedPoolTokenStorageLib.getTokenScalingFactor(tokenOutState);
    }

    /**
     * @notice Returns a token's weight and scaling factor
     */
    function _getTokenInfo(IERC20 token, uint256 weightChangeProgress)
        private
        view
        returns (uint256 tokenWeight, uint256 scalingFactor)
    {
        bytes32 tokenState = _getTokenState(token);
        tokenWeight = ManagedPoolTokenStorageLib.getTokenWeight(tokenState, weightChangeProgress);
        scalingFactor = ManagedPoolTokenStorageLib.getTokenScalingFactor(tokenState);
    }

    // Initialize

    function _onInitializePool(address sender, bytes memory userData)
        internal
        override
        returns (uint256 bptAmountOut, uint256[] memory amountsIn)
    {
        // Check allowlist for LPs, if applicable
        _require(_isAllowedAddress(_getPoolState(), sender), Errors.ADDRESS_NOT_ALLOWLISTED);

        // Ensure that the user intends to initialize the Pool.
        WeightedPoolUserData.JoinKind kind = userData.joinKind();
        _require(kind == WeightedPoolUserData.JoinKind.INIT, Errors.UNINITIALIZED);

        // Extract the initial token balances `sender` is sending to the Pool.
        (IERC20[] memory tokens, ) = _getPoolTokens();
        amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(amountsIn.length, tokens.length);

        // We now want to determine the correct amount of BPT to mint in return for these tokens.
        // In order to do this we calculate the Pool's invariant which requires the token amounts to be upscaled.
        uint256[] memory scalingFactors = _scalingFactors(tokens);
        _upscaleArray(amountsIn, scalingFactors);

        uint256 invariantAfterJoin = _getWeightedMath().calculateInvariant(_getNormalizedWeights(tokens), amountsIn);

        // Set the initial BPT to the value of the invariant times the number of tokens. This makes BPT supply more
        // consistent in Pools with similar compositions but different number of tokens.
        bptAmountOut = Math.mul(invariantAfterJoin, amountsIn.length);

        // We don't need upscaled balances anymore and will need to return downscaled amounts so we downscale here.
        // `amountsIn` are amounts entering the Pool, so we round up when doing this.
        _downscaleUpArray(amountsIn, scalingFactors);

        // BasePool will mint `bptAmountOut` for the sender: we then also mint the remaining BPT to make up the total
        // supply, and have the Vault pull those tokens from the sender as part of the join.
        //
        // Note that the sender need not approve BPT for the Vault as the Vault already has infinite BPT allowance for
        // all accounts.
        uint256 initialBpt = _PREMINTED_TOKEN_BALANCE.sub(bptAmountOut);
        _mintPoolTokens(sender, initialBpt);

        // The Vault expects an array of amounts which includes BPT (which always sits in the first position).
        // We then add an extra element to the beginning of the array and set it to `initialBpt`.
        amountsIn = ComposablePoolLib.prependZeroElement(amountsIn);
        amountsIn[0] = initialBpt;

        // At this point we have all necessary return values for the initialization.

        // Finally, we want to start collecting AUM fees from this point onwards. Prior to initialization the Pool holds
        // no funds so naturally charges no AUM fees.
        _updateAumFeeCollectionTimestamp();
    }

    // Join

    function _onJoinPool(
        address sender,
        uint256[] memory balances,
        bytes memory userData
    ) internal virtual override returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        // The Vault passes an array of balances which includes the pool's BPT (This always sits in the first position).
        // We want to separate this from the other balances before continuing with the join.
        uint256 virtualSupply;
        (virtualSupply, balances) = ComposablePoolLib.dropBptFromBalances(totalSupply(), balances);

        // We want to upscale all of the balances received from the Vault by the appropriate scaling factors.
        // In order to do this we must query the Pool's tokens from the Vault as ManagedPool doesn't keep track.
        (IERC20[] memory tokens, ) = _getPoolTokens();
        uint256[] memory scalingFactors = _scalingFactors(tokens);
        _upscaleArray(balances, scalingFactors);

        // See documentation for `getActualSupply()` and `_collectAumManagementFees()`.
        uint256 actualSupply = virtualSupply + _collectAumManagementFees(virtualSupply);
        uint256[] memory normalizedWeights = _getNormalizedWeights(tokens);

        (bptAmountOut, amountsIn) = _doJoin(
            sender,
            balances,
            normalizedWeights,
            scalingFactors,
            actualSupply,
            userData
        );

        _checkCircuitBreakers(actualSupply.add(bptAmountOut), tokens, balances, amountsIn, normalizedWeights, true);

        // amountsIn are amounts entering the Pool, so we round up.
        _downscaleUpArray(amountsIn, scalingFactors);

        // The Vault expects an array of amounts which includes BPT so prepend an empty element to this array.
        amountsIn = ComposablePoolLib.prependZeroElement(amountsIn);
    }

    /**
     * @dev Dispatch code which decodes the provided userdata to perform the specified join type.
     */
    function _doJoin(
        address sender,
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        bytes memory userData
    ) internal view returns (uint256, uint256[] memory) {
        bytes32 poolState = _getPoolState();
        WeightedPoolUserData.JoinKind kind = userData.joinKind();

        // If swaps are disabled, only proportional joins are allowed. All others involve implicit swaps, and alter
        // token prices.
        _require(
            ManagedPoolStorageLib.getSwapsEnabled(poolState) ||
                kind == WeightedPoolUserData.JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
            Errors.INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED
        );

        // Check allowlist for LPs, if applicable
        _require(_isAllowedAddress(poolState, sender), Errors.ADDRESS_NOT_ALLOWLISTED);

        if (kind == WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return
                _getWeightedMath().joinExactTokensInForBPTOut(
                    balances,
                    normalizedWeights,
                    scalingFactors,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else if (kind == WeightedPoolUserData.JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT) {
            return
                _getWeightedMath().joinTokenInForExactBPTOut(
                    balances,
                    normalizedWeights,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else if (kind == WeightedPoolUserData.JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT) {
            return _getWeightedMath().joinAllTokensInForExactBPTOut(balances, totalSupply, userData);
        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    // Exit

    function _onExitPool(
        address sender,
        uint256[] memory balances,
        bytes memory userData
    ) internal virtual override returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        // The Vault passes an array of balances which includes the pool's BPT (This always sits in the first position).
        // We want to separate this from the other balances before continuing with the exit.
        uint256 virtualSupply;
        (virtualSupply, balances) = ComposablePoolLib.dropBptFromBalances(totalSupply(), balances);

        // We want to upscale all of the balances received from the Vault by the appropriate scaling factors.
        // In order to do this we must query the Pool's tokens from the Vault as ManagedPool doesn't keep track.
        (IERC20[] memory tokens, ) = _getPoolTokens();
        uint256[] memory scalingFactors = _scalingFactors(tokens);
        _upscaleArray(balances, scalingFactors);

        // See documentation for `getActualSupply()` and `_collectAumManagementFees()`.
        uint256 actualSupply = virtualSupply + _collectAumManagementFees(virtualSupply);

        uint256[] memory normalizedWeights = _getNormalizedWeights(tokens);

        (bptAmountIn, amountsOut) = _doExit(
            sender,
            balances,
            normalizedWeights,
            scalingFactors,
            actualSupply,
            userData
        );

        // Do not check circuit breakers on proportional exits, which do not change BPT prices.
        if (userData.exitKind() != WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            _checkCircuitBreakers(
                actualSupply.sub(bptAmountIn),
                tokens,
                balances,
                amountsOut,
                normalizedWeights,
                false
            );
        }

        // amountsOut are amounts exiting the Pool, so we round down.
        _downscaleDownArray(amountsOut, scalingFactors);

        // The Vault expects an array of amounts which includes BPT so prepend an empty element to this array.
        amountsOut = ComposablePoolLib.prependZeroElement(amountsOut);
    }

    /**
     * @dev Dispatch code which decodes the provided userdata to perform the specified exit type.
     * Inheriting contracts may override this function to add additional exit types or extra conditions to allow
     * or disallow exit under certain circumstances.
     */
    function _doExit(
        address,
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        bytes memory userData
    ) internal view virtual returns (uint256, uint256[] memory) {
        bytes32 poolState = _getPoolState();
        WeightedPoolUserData.ExitKind kind = userData.exitKind();

        // If swaps are disabled, only proportional exits are allowed. All others involve implicit swaps, and alter
        // token prices.
        _require(
            ManagedPoolStorageLib.getSwapsEnabled(poolState) ||
                kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
            Errors.INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED
        );

        // Note that we do not check the LP allowlist here. LPs must always be able to exit the pool,
        // and enforcing the allowlist would allow the manager to perform DOS attacks on LPs.

        if (kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT) {
            return
                _getWeightedMath().exitExactBPTInForTokenOut(
                    balances,
                    normalizedWeights,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else if (kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            return _getWeightedMath().exitExactBPTInForTokensOut(balances, totalSupply, userData);
        } else if (kind == WeightedPoolUserData.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT) {
            return
                _getWeightedMath().exitBPTInForExactTokensOut(
                    balances,
                    normalizedWeights,
                    scalingFactors,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else {
            _revert(Errors.UNHANDLED_EXIT_KIND);
        }
    }

    function _doRecoveryModeExit(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) internal pure override returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        // As ManagedPool is a composable Pool, `_doRecoveryModeExit()` must use the virtual supply rather than the
        // total supply to correctly distribute Pool assets proportionally.
        // We must also ensure that we do not pay out a proportionaly fraction of the BPT held in the Vault, otherwise
        // this would allow a user to recursively exit the pool using BPT they received from the previous exit.

        uint256 virtualSupply;
        (virtualSupply, balances) = ComposablePoolLib.dropBptFromBalances(totalSupply, balances);

        bptAmountIn = userData.recoveryModeExit();
        amountsOut = WeightedMath._calcTokensOutGivenExactBptIn(balances, bptAmountIn, virtualSupply);

        // The Vault expects an array of amounts which includes BPT so prepend an empty element to this array.
        amountsOut = ComposablePoolLib.prependZeroElement(amountsOut);
    }

    /**
     * @notice Returns the tokens in the Pool and their current balances.
     * @dev This function drops the BPT token and its balance from the returned arrays as these values are unused by
     * internal functions outside of the swap/join/exit hooks.
     */
    function _getPoolTokens() internal view override returns (IERC20[] memory, uint256[] memory) {
        (IERC20[] memory registeredTokens, uint256[] memory registeredBalances, ) = getVault().getPoolTokens(
            getPoolId()
        );
        return ComposablePoolLib.dropBpt(registeredTokens, registeredBalances);
    }

    // Circuit Breakers

    // Depending on the type of operation, we may need to check only the upper or lower bound, or both.
    enum BoundCheckKind { LOWER, UPPER, BOTH }

    /**
     * @dev Check the circuit breakers of the two tokens involved in a regular swap.
     */
    function _checkCircuitBreakersOnRegularSwap(
        SwapRequest memory request,
        SwapTokenData memory tokenData,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut,
        uint256 amountCalculated
    ) private view {
        uint256 actualSupply = _getActualSupply(_getVirtualSupply());

        (uint256 amountIn, uint256 amountOut) = request.kind == IVault.SwapKind.GIVEN_IN
            ? (request.amount, amountCalculated)
            : (amountCalculated, request.amount);

        // Since the balance of tokenIn is increasing, its BPT price will decrease,
        // so we need to check the lower bound.
        _checkCircuitBreaker(
            BoundCheckKind.LOWER,
            request.tokenIn,
            actualSupply,
            balanceTokenIn.add(amountIn),
            tokenData.tokenInWeight
        );

        // Since the balance of tokenOut is decreasing, its BPT price will increase,
        // so we need to check the upper bound.
        _checkCircuitBreaker(
            BoundCheckKind.UPPER,
            request.tokenOut,
            actualSupply,
            balanceTokenOut.sub(amountOut),
            tokenData.tokenOutWeight
        );
    }

    /**
     * @dev We need to check the breakers for all tokens on joins and exits (including join and exit swaps), since any
     * change to the BPT supply affects all BPT prices. For a multi-token join or exit, we will have a set of
     * balances and amounts. For a join/exitSwap, only one token balance is changing. We can use the same data for
     *  both: in the single token swap case, the other token `amounts` will be zero.
     */
    function _checkCircuitBreakersOnJoinOrExitSwap(
        SwapRequest memory request,
        uint256 actualSupply,
        uint256 amountCalculated,
        bool isJoin
    ) private view {
        uint256 newActualSupply;
        uint256 amount;

        // This is a swap between the BPT token and another pool token. Calculate the end state: actualSupply
        // and the token amount being swapped, depending on whether it is a join or exit, GivenIn or GivenOut.
        if (isJoin) {
            (newActualSupply, amount) = request.kind == IVault.SwapKind.GIVEN_IN
                ? (actualSupply.add(amountCalculated), request.amount)
                : (actualSupply.add(request.amount), amountCalculated);
        } else {
            (newActualSupply, amount) = request.kind == IVault.SwapKind.GIVEN_IN
                ? (actualSupply.sub(request.amount), amountCalculated)
                : (actualSupply.sub(amountCalculated), request.amount);
        }

        // Since this is a swap, we do not have all the tokens, balances, or weights, and need to fetch them.
        (IERC20[] memory tokens, uint256[] memory balances) = _getPoolTokens();
        uint256[] memory normalizedWeights = _getNormalizedWeights(tokens);
        _upscaleArray(balances, _scalingFactors(tokens));

        // Initialize to all zeros, and set the amount associated with the swap.
        uint256[] memory amounts = new uint256[](tokens.length);
        IERC20 token = isJoin ? request.tokenIn : request.tokenOut;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                amounts[i] = amount;
                break;
            }
        }

        _checkCircuitBreakers(newActualSupply, tokens, balances, amounts, normalizedWeights, isJoin);
    }

    /**
     * @dev Check circuit breakers for a set of tokens. The given virtual supply is what it will be post-operation:
     * this includes any pending external fees, and the amount of BPT exchanged (swapped, minted, or burned) in the
     * current operation.
     *
     * We pass in the tokens, upscaled balances, and weights necessary to compute BPT prices, then check the circuit
     * breakers. Unlike a straightforward token swap, where we know the direction the BPT price will move, once the
     * virtual supply changes, all bets are off. To be safe, we need to check both directions for all tokens.
     *
     * It does attempt to short circuit quickly if there is no bound set.
     */
    function _checkCircuitBreakers(
        uint256 actualSupply,
        IERC20[] memory tokens,
        uint256[] memory balances,
        uint256[] memory amounts,
        uint256[] memory normalizedWeights,
        bool isJoin
    ) private view {
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 finalBalance = (isJoin ? FixedPoint.add : FixedPoint.sub)(balances[i], amounts[i]);

            // Since we cannot be sure which direction the BPT price of the token has moved,
            // we must check both the lower and upper bounds.
            _checkCircuitBreaker(BoundCheckKind.BOTH, tokens[i], actualSupply, finalBalance, normalizedWeights[i]);
        }
    }

    // Check the appropriate circuit breaker(s) according to the BoundCheckKind.
    function _checkCircuitBreaker(
        BoundCheckKind checkKind,
        IERC20 token,
        uint256 actualSupply,
        uint256 balance,
        uint256 weight
    ) private view {
        bytes32 circuitBreakerState = _getCircuitBreakerState(token);

        if (checkKind == BoundCheckKind.LOWER || checkKind == BoundCheckKind.BOTH) {
            _checkOneSidedCircuitBreaker(circuitBreakerState, actualSupply, balance, weight, true);
        }

        if (checkKind == BoundCheckKind.UPPER || checkKind == BoundCheckKind.BOTH) {
            _checkOneSidedCircuitBreaker(circuitBreakerState, actualSupply, balance, weight, false);
        }
    }

    // Check either the lower or upper bound circuit breaker for the given token.
    function _checkOneSidedCircuitBreaker(
        bytes32 circuitBreakerState,
        uint256 actualSupply,
        uint256 balance,
        uint256 weight,
        bool isLowerBound
    ) private pure {
        uint256 bound = CircuitBreakerStorageLib.getBptPriceBound(circuitBreakerState, weight, isLowerBound);

        _require(
            !CircuitBreakerLib.hasCircuitBreakerTripped(actualSupply, weight, balance, bound, isLowerBound),
            Errors.CIRCUIT_BREAKER_TRIPPED
        );
    }

    // Unimplemented

    /**
     * @dev Unimplemented as ManagedPool uses the MinimalInfoSwap Pool specialization.
     */
    function _onSwapGeneral(
        SwapRequest memory, /*request*/
        uint256[] memory, /* balances*/
        uint256, /* indexIn */
        uint256 /*indexOut */
    ) internal pure override returns (uint256) {
        _revert(Errors.UNIMPLEMENTED);
    }
}


library WeightedExitsLib {
    using WeightedPoolUserData for bytes;

    function exitExactBPTInForTokenOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) internal pure returns (uint256, uint256[] memory) {
        (uint256 bptAmountIn, uint256 tokenIndex) = userData.exactBptInForTokenOut();
        // Note that there is no minimum amountOut parameter: this is handled by `IVault.exitPool`.

        _require(tokenIndex < balances.length, Errors.OUT_OF_BOUNDS);

        uint256 amountOut = WeightedMath._calcTokenOutGivenExactBptIn(
            balances[tokenIndex],
            normalizedWeights[tokenIndex],
            bptAmountIn,
            totalSupply,
            swapFeePercentage
        );

        // This is an exceptional situation in which the fee is charged on a token out instead of a token in.
        // We exit in a single token, so we initialize amountsOut with zeros
        uint256[] memory amountsOut = new uint256[](balances.length);
        // And then assign the result to the selected token
        amountsOut[tokenIndex] = amountOut;

        return (bptAmountIn, amountsOut);
    }

    function exitExactBPTInForTokensOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) internal pure returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        bptAmountIn = userData.exactBptInForTokensOut();
        // Note that there is no minimum amountOut parameter: this is handled by `IVault.exitPool`.

        amountsOut = BasePoolMath.computeProportionalAmountsOut(balances, totalSupply, bptAmountIn);
    }

    function exitBPTInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) internal pure returns (uint256, uint256[] memory) {
        (uint256[] memory amountsOut, uint256 maxBPTAmountIn) = userData.bptInForExactTokensOut();
        InputHelpers.ensureInputLengthMatch(amountsOut.length, balances.length);
        _upscaleArray(amountsOut, scalingFactors);

        // This is an exceptional situation in which the fee is charged on a token out instead of a token in.
        uint256 bptAmountIn = WeightedMath._calcBptInGivenExactTokensOut(
            balances,
            normalizedWeights,
            amountsOut,
            totalSupply,
            swapFeePercentage
        );
        _require(bptAmountIn <= maxBPTAmountIn, Errors.BPT_IN_MAX_AMOUNT);

        return (bptAmountIn, amountsOut);
    }
}



library WeightedJoinsLib {
    using WeightedPoolUserData for bytes;

    function joinExactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) internal pure returns (uint256, uint256[] memory) {
        (uint256[] memory amountsIn, uint256 minBPTAmountOut) = userData.exactTokensInForBptOut();
        InputHelpers.ensureInputLengthMatch(balances.length, amountsIn.length);

        _upscaleArray(amountsIn, scalingFactors);

        uint256 bptAmountOut = WeightedMath._calcBptOutGivenExactTokensIn(
            balances,
            normalizedWeights,
            amountsIn,
            totalSupply,
            swapFeePercentage
        );

        _require(bptAmountOut >= minBPTAmountOut, Errors.BPT_OUT_MIN_AMOUNT);

        return (bptAmountOut, amountsIn);
    }

    function joinTokenInForExactBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) internal pure returns (uint256, uint256[] memory) {
        (uint256 bptAmountOut, uint256 tokenIndex) = userData.tokenInForExactBptOut();
        // Note that there is no maximum amountIn parameter: this is handled by `IVault.joinPool`.

        _require(tokenIndex < balances.length, Errors.OUT_OF_BOUNDS);

        uint256 amountIn = WeightedMath._calcTokenInGivenExactBptOut(
            balances[tokenIndex],
            normalizedWeights[tokenIndex],
            bptAmountOut,
            totalSupply,
            swapFeePercentage
        );

        // We join in a single token, so we initialize amountsIn with zeros
        uint256[] memory amountsIn = new uint256[](balances.length);
        // And then assign the result to the selected token
        amountsIn[tokenIndex] = amountIn;

        return (bptAmountOut, amountsIn);
    }

    function joinAllTokensInForExactBPTOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) internal pure returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        bptAmountOut = userData.allTokensInForExactBptOut();
        // Note that there is no maximum amountsIn parameter: this is handled by `IVault.joinPool`.

        amountsIn = BasePoolMath.computeProportionalAmountsIn(balances, totalSupply, bptAmountOut);
    }
}

/**
 * @notice A contract-wrapper for Weighted Math, Joins and Exits.
 * @dev Use this contract as an external replacement for WeightedMath, WeightedJoinsLib and WeightedExitsLib libraries.
 */
contract ExternalWeightedMath is IExternalWeightedMath {
    function calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
        external
        pure
        override
        returns (uint256)
    {
        return WeightedMath._calculateInvariant(normalizedWeights, balances);
    }

    function calcOutGivenIn(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    ) external pure override returns (uint256) {
        return WeightedMath._calcOutGivenIn(balanceIn, weightIn, balanceOut, weightOut, amountIn);
    }

    function calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut
    ) external pure override returns (uint256) {
        return WeightedMath._calcInGivenOut(balanceIn, weightIn, balanceOut, weightOut, amountOut);
    }

    function calcBptOutGivenExactTokensIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure override returns (uint256) {
        return
            WeightedMath._calcBptOutGivenExactTokensIn(
                balances,
                normalizedWeights,
                amountsIn,
                bptTotalSupply,
                swapFeePercentage
            );
    }

    function calcBptOutGivenExactTokenIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure override returns (uint256) {
        return
            WeightedMath._calcBptOutGivenExactTokenIn(
                balance,
                normalizedWeight,
                amountIn,
                bptTotalSupply,
                swapFeePercentage
            );
    }

    function calcTokenInGivenExactBptOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure override returns (uint256) {
        return
            WeightedMath._calcTokenInGivenExactBptOut(
                balance,
                normalizedWeight,
                bptAmountOut,
                bptTotalSupply,
                swapFeePercentage
            );
    }

    function calcAllTokensInGivenExactBptOut(
        uint256[] memory balances,
        uint256 bptAmountOut,
        uint256 totalBPT
    ) external pure override returns (uint256[] memory) {
        return BasePoolMath.computeProportionalAmountsIn(balances, totalBPT, bptAmountOut);
    }

    function calcBptInGivenExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure override returns (uint256) {
        return
            WeightedMath._calcBptInGivenExactTokensOut(
                balances,
                normalizedWeights,
                amountsOut,
                bptTotalSupply,
                swapFeePercentage
            );
    }

    function calcBptInGivenExactTokenOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure override returns (uint256) {
        return
            WeightedMath._calcBptInGivenExactTokenOut(
                balance,
                normalizedWeight,
                amountOut,
                bptTotalSupply,
                swapFeePercentage
            );
    }

    function calcTokenOutGivenExactBptIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure override returns (uint256) {
        return
            WeightedMath._calcTokenOutGivenExactBptIn(
                balance,
                normalizedWeight,
                bptAmountIn,
                bptTotalSupply,
                swapFeePercentage
            );
    }

    function calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) external pure override returns (uint256[] memory) {
        return BasePoolMath.computeProportionalAmountsOut(balances, totalBPT, bptAmountIn);
    }

    function calcBptOutAddToken(uint256 totalSupply, uint256 normalizedWeight)
        external
        pure
        override
        returns (uint256)
    {
        return WeightedMath._calcBptOutAddToken(totalSupply, normalizedWeight);
    }

    function joinExactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure override returns (uint256, uint256[] memory) {
        return
            WeightedJoinsLib.joinExactTokensInForBPTOut(
                balances,
                normalizedWeights,
                scalingFactors,
                totalSupply,
                swapFeePercentage,
                userData
            );
    }

    function joinTokenInForExactBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure override returns (uint256, uint256[] memory) {
        return
            WeightedJoinsLib.joinTokenInForExactBPTOut(
                balances,
                normalizedWeights,
                totalSupply,
                swapFeePercentage,
                userData
            );
    }

    function joinAllTokensInForExactBPTOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) external pure override returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        return WeightedJoinsLib.joinAllTokensInForExactBPTOut(balances, totalSupply, userData);
    }

    function exitExactBPTInForTokenOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure override returns (uint256, uint256[] memory) {
        return
            WeightedExitsLib.exitExactBPTInForTokenOut(
                balances,
                normalizedWeights,
                totalSupply,
                swapFeePercentage,
                userData
            );
    }

    function exitExactBPTInForTokensOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) external pure override returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        return WeightedExitsLib.exitExactBPTInForTokensOut(balances, totalSupply, userData);
    }

    function exitBPTInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure override returns (uint256, uint256[] memory) {
        return
            WeightedExitsLib.exitBPTInForExactTokensOut(
                balances,
                normalizedWeights,
                scalingFactors,
                totalSupply,
                swapFeePercentage,
                userData
            );
    }
}

contract WINRManagedPoolFactory is BasePoolFactory {
    IExternalWeightedMath private immutable _weightedMath;
    address public govenor;

    constructor(IVault vault, IProtocolFeePercentagesProvider protocolFeeProvider, address _govenor)
        BasePoolFactory(vault, protocolFeeProvider,0,0, type(ManagedPool).creationCode)
    {
        _weightedMath = new ExternalWeightedMath();
        govenor = _govenor;
    }

    function getWeightedMath() external view returns (IExternalWeightedMath) {
        return _weightedMath;
    }

    struct NewPoolParams {
        string name;
        string symbol;
        IERC20[] tokens;
        uint256[] normalizedWeights;
        address[] assetManagers;
        uint256 swapFeePercentage;
        bool swapEnabledOnStart;
        bool mustAllowlistLPs;
        uint256 managementAumFeePercentage;
        uint256 aumFeeId;
    }

    /**
     * @dev Deploys a new `ManagedPool`. The owner should be a contract, deployed by another factory.
     */
    function create(NewPoolParams memory poolParams, address owner)
        external
        returns (address pool)
    {
        require(msg.sender == govenor, "OnlyGov");
        (uint256 pauseWindowDuration, uint256 bufferPeriodDuration) = getPauseConfiguration();

        return
            _create(
                abi.encode(
                    poolParams,
                    getVault(),
                    getProtocolFeePercentagesProvider(),
                    _weightedMath,
                    owner,
                    pauseWindowDuration,
                    bufferPeriodDuration
                )
            );
    }
}