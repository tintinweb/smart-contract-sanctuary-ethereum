/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.10;

interface ICurvePool {
  function coins(uint256 n) external view returns (address);
  function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
  function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
  function get_virtual_price() external view returns (uint256);
  function get_balances() external view returns (uint256[] memory);
  function fee() external view returns (uint256);
}

interface IHarvestForwarder {
  function distribute(
    address token,
    uint256 amount,
    address beneficiary
  ) external;
  function badger_tree() external view returns(address);
}

interface IVault {
    function token() external view returns (address);

    function reportHarvest(uint256 _harvestedAmount) external;

    function reportAdditionalToken(address _token) external;

    // Fees
    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    // Actors
    function governance() external view returns (address);

    function keeper() external view returns (address);

    function guardian() external view returns (address);

    function strategist() external view returns (address);

    function treasury() external view returns (address);

    // External
    function deposit(uint256 _amount) external;

    function depositFor(address _recipient, uint256 _amount) external;

    function totalSupply() external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function balance() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
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

enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}

interface IBalancerVault {
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
    function getPoolTokens(
         bytes32 poolId
    )
    external
    view
    returns (
        address[] memory tokens,
        uint256[] memory balances,
        uint256 lastChangeBlock
    );
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

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

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

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory);

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
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IUniswapRouterV2 {
    function factory() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ICurveRouter {
  function get_best_rate(
    address from, address to, uint256 _amount) external view returns (address, uint256);
  
  function exchange_with_best_rate(
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected
  ) external returns (uint256);
  
  function exchange_with_best_rate(
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external returns (uint256);
  
  function exchange(
    address _pool,
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external returns (uint256);
}

interface ICowSettlement {
  function setPreSignature(bytes calldata orderUid, bool signed) external;
  function preSignature(bytes calldata orderUid) external view returns (uint256);
  function domainSeparator() external view returns (bytes32);
}

enum SwapType { 
    CURVE, //0
    UNIV2, //1
    SUSHI, //2
    UNIV3, //3
    UNIV3WITHWETH, //4 
    BALANCER, //5
    BALANCERWITHWETH //6 
}

// Onchain Pricing Interface
struct Quote {
    SwapType name;
    uint256 amountOut;
    bytes32[] pools; // specific pools involved in the optimal swap path
    uint256[] poolFees; // specific pool fees involved in the optimal swap path, typically in Uniswap V3
}
interface OnChainPricing {
  function findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) external view returns (Quote memory);
}
// END OnchainPricing

/// @title CowSwapSeller
/// @author Alex the Entreprenerd @ BadgerDAO
/// @dev Cowswap seller, a smart contract that receives order data and verifies if the order is worth going for
/// @notice CREDITS
/// Thank you Cowswap Team as well as Poolpi
/// @notice For the awesome project and the tutorial: https://hackmd.io/@2jvugD4TTLaxyG3oLkPg-g/H14TQ1Omt
contract CowSwapSeller is ReentrancyGuard {
    using SafeERC20 for IERC20;
    OnChainPricing public pricer; // Contract we will ask for a fair price of before accepting the cowswap order

    address public manager;

    address public constant DEV_MULTI = 0xB65cef03b9B89f99517643226d76e286ee999e77;

    /// Contract we give allowance to perform swaps
    address public constant RELAYER = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;

    ICowSettlement public constant SETTLEMENT = ICowSettlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);

    bytes32 private constant TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";

    // keccak256("sell")
    bytes32 public constant KIND_SELL =
        hex"f3b277728b3fee749481eb3e0b3b48980dbbab78658fc419025cb16eee346775";
    // keccak256("erc20")
    bytes32 public constant BALANCE_ERC20 =
        hex"5a28e9363bb942b639270062aa6bb295f434bcdfc42c97267bf003f272060dc9";

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// GPv2 contracts.
    /// @notice Copy pasted from mainnet because we need this
    bytes32 public immutable domainSeparator;
        // Cowswap Order Data Interface 
    uint256 constant UID_LENGTH = 56;

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
    ) pure public {
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
    constructor(address _pricer) {
        pricer = OnChainPricing(_pricer);
        manager = msg.sender;

        // Fetch the domainSeparator from Settlement from THIS chain
        domainSeparator = SETTLEMENT.domainSeparator();
    }

    /// @dev Set the Pricer Contract used to determine if a Order is fair
    /// @param newPricer - the new pricer
    function setPricer(OnChainPricing newPricer) external {
        require(msg.sender == DEV_MULTI);
        pricer = newPricer;
    }

    /// @dev Set the Manager, the account that can process the tokens
    /// @param newManager - the new manager
    function setManager(address newManager) external {
        require(msg.sender == manager);
        manager = newManager;
    }

    /// @dev Return the EIP-712 signing hash for the specified order.
    ///
    /// @param order The order to compute the EIP-712 signing hash for.
    /// @param separator The EIP-712 domain separator to use.
    /// @return orderDigest The 32 byte EIP-712 struct hash.
    function getHash(Data memory order, bytes32 separator)
        public
        pure
        returns (bytes32 orderDigest)
    {
        bytes32 structHash;

        // NOTE: Compute the EIP-712 order struct hash in place. As suggested
        // in the EIP proposal, noting that the order struct has 10 fields, and
        // including the type hash `(12 + 1) * 32 = 416` bytes to hash.
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
            mstore(add(freeMemoryPointer, 2), separator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }

    /// @dev Given the orderData, returns an orderId
    /// @param orderData - All the information for a Cowswap Order
    /// @return bytes - the OrderId
    function getOrderID(Data calldata orderData) public view returns (bytes memory) {
        // Allocated
        bytes memory orderUid = new bytes(UID_LENGTH);

        // Get the hash
        bytes32 digest = getHash(orderData, domainSeparator);
        packOrderUidParams(orderUid, digest, address(this), orderData.validTo);

        return orderUid;
    }

    /// @dev Given the orderData and the orderUid
    ///     Verify the parameter match the id and do basic checks for price and recipient
    /// @notice Virtual so you can override, e.g. for Limit Orders by other contracts
    /// @notice Reverts on lack of basic validation
    ///     However it returns false if the slippage check didn't pass
    ///     Meaning it won't revert if you've been quoted a bad price
    /// @return bool - Whether it passed the slippage checks
    function checkCowswapOrder(Data calldata orderData, bytes memory orderUid) public virtual returns(bool) {
        // Verify we get the same ID
        // NOTE: technically superfluous as we could just derive the id and setPresignature with that
        // But nice for internal testing
        bytes memory derivedOrderID = getOrderID(orderData);
        require(keccak256(derivedOrderID) == keccak256(orderUid));

        require(orderData.validTo > block.timestamp);
        require(orderData.receiver == address(this));
        require(keccak256(abi.encodePacked(orderData.kind)) == keccak256(abi.encodePacked(KIND_SELL)));

        // TODO: This should be done by using a gas cost oracle (see Chainlink)
        require(orderData.feeAmount <= orderData.sellAmount / 10); // Fee can be at most 1/10th of order

        // Check the price we're agreeing to. Before we continue, let's get a full onChain quote as baseline
        address tokenIn = address(orderData.sellToken);
        address tokenOut = address(orderData.buyToken);

        uint256 amountIn = orderData.sellAmount;
        uint256 amountOut = orderData.buyAmount;

        Quote memory result = pricer.findOptimalSwap(tokenIn, tokenOut, amountIn);

        // Require that Cowswap is offering a better price or matching
        return(result.amountOut <= amountOut);
    }

    /// @dev This is the function you want to use to perform a swap on Cowswap via this smart contract
    /// @param orderData - The data for the order, see {Data}
    /// @param orderUid - the identifier for the order
    function _doCowswapOrder(Data calldata orderData, bytes memory orderUid) internal nonReentrant {
        require(msg.sender == manager);

        require(checkCowswapOrder(orderData, orderUid), "!cowLowerPrice");

        // Because swap is looking good, check we have the amount, then give allowance to the Cowswap Router
        orderData.sellToken.safeApprove(RELAYER, 0); // Set to 0 just in case
        orderData.sellToken.safeApprove(RELAYER, orderData.sellAmount + orderData.feeAmount);

        // Once allowance is set, let's setPresignature and the order will happen
        //setPreSignature
        SETTLEMENT.setPreSignature(orderUid, true);
    }

    /// @dev Allows to cancel a cowswap order perhaps if it took too long or was with invalid parameters
    /// @notice This function performs no checks, there's a high change it will revert if you send it with fluff parameters
    /// @param orderUid - The id of the order to cancel
    function _cancelCowswapOrder(bytes memory orderUid) internal nonReentrant {
        require(msg.sender == manager);

        SETTLEMENT.setPreSignature(orderUid, false);
    }
}

/// @title AuraBribesProcessor
/// @author Swole @ BadgerDAO
/// @dev BribesProcess for bveAura, using CowSwapSeller allows to process bribes fairly
/// Minimizing the amount of power that the manager can have
/// @notice This code is forked from the VotiumBribesProcessor
///     Original Version: https://github.com/GalloDaSballo/fair-selling/blob/main/contracts/VotiumBribesProcessor.sol
contract AuraBribesProcessor is CowSwapSeller {
    using SafeERC20 for IERC20;

    // All events are token / amount
    event SentBribeToGovernance(address indexed token, uint256 amount);
    event SentBribeToTree(address indexed token, uint256 amount);
    event PerformanceFeeGovernance(address indexed token, uint256 amount);
    event BribeEmission(address indexed token, address indexed recipient, uint256 amount);

    // address public manager /// inherited by CowSwapSeller

    // timestamp of last action, we allow anyone to sweep this contract
    // if admin has been idle for too long.
    // Sweeping simply emits to the badgerTree making fair emission to vault depositors
    // Once BadgerRewards is live we will integrate it
    uint256 public lastBribeAction;

    uint256 public constant MAX_MANAGER_IDLE_TIME = 10 days; // Because we have Strategy Notify, 10 days is enough
    // Way more time than expected

    IERC20 public constant BADGER = IERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    IERC20 public constant AURA = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public constant STRATEGY = 0x3c0989eF27e3e3fAb87a2d7C38B35880C90E63b5;
    address public constant BADGER_TREE = 0x660802Fc641b154aBA66a62137e71f331B6d787A;

    // Source: https://badger.com/graviaura
    uint256 public constant MAX_BPS = 10_000;
    // A 5% fee will be charged on all bribes processed.
    uint256 public constant OPS_FEE = 500; // 5%

    /// `treasury_voter_multisig`
    /// https://github.com/Badger-Finance/badger-multisig/blob/6cd8f42ae0313d0da33a208d452370343e7599ba/helpers/addresses.py#L52
    address public constant TREASURY = 0xA9ed98B5Fb8428d68664f3C5027c62A10d45826b;

    IVault public constant BVE_AURA = IVault(0xBA485b556399123261a5F9c95d413B4f93107407);

    // We send tokens to emit here
    IHarvestForwarder public constant HARVEST_FORWARDER = IHarvestForwarder(0xA84B663837D94ec41B0f99903f37e1d69af9Ed3E);

    /// NOTE: Need constructor for CowSwapSeller
    constructor(address _pricer) CowSwapSeller(_pricer) {}

    function notifyNewRound() external {
        require(msg.sender == STRATEGY);

        // Give the manager 10 days to process else anyone can claim
        lastBribeAction = block.timestamp;
    }

    /// === Security Function === ///

    /// @dev Emits all of token directly to tree for people to receive
    /// @param token The token to transfer
    /// @param sendToGovernance Should we send to the dev multisig, or emit directly to the badgerTree?
    /// @notice has built in expiration allowing anyone to send the tokens to tree should the manager stop processing bribes
    ///     can also sendToGovernance if you prefer
    ///     at this time both options have the same level of trust assumptions
    /// This is effectively a security rescue function
    /// The manager can call it to move funds to tree (forfeiting any fees)
    /// And anyone can rescue the funds if the manager goes rogue
    function ragequit(IERC20 token, bool sendToGovernance) external nonReentrant {
        bool timeHasExpired = block.timestamp > lastBribeAction + MAX_MANAGER_IDLE_TIME;
        require(msg.sender == manager || timeHasExpired);

        // In order to avoid selling after, set back the allowance to 0 to the Relayer
        token.safeApprove(address(RELAYER), 0);

        // Send all tokens to badgerTree without fee
        uint256 amount = token.balanceOf(address(this));
        if(sendToGovernance) {
            token.safeTransfer(DEV_MULTI, amount);
            emit SentBribeToGovernance(address(token), amount);
        } else {
            require(HARVEST_FORWARDER.badger_tree() == BADGER_TREE);

            // If manager rqs to emit in time, treasury still receives a fee
            if(!timeHasExpired && msg.sender == manager) {
                
                // Take a fee here
                uint256 fee = amount * OPS_FEE / MAX_BPS;
                token.safeTransfer(TREASURY, fee);

                emit PerformanceFeeGovernance(address(token), fee);

                amount -= fee;
            }

            // Emit to Tree
            token.safeApprove(address(HARVEST_FORWARDER), amount);
            HARVEST_FORWARDER.distribute(address(token), amount, address(BVE_AURA));

            emit SentBribeToTree(address(token), amount);
        }
    }

    /// === Day to Day Operations Functions === ///

    /// @dev
    /// Step 1
    /// Use sellBribeForWETH
    /// To sell all bribes to WETH
    /// @notice nonReentrant not needed as `_doCowswapOrder` is nonReentrant
    function sellBribeForWeth(Data calldata orderData, bytes memory orderUid) external {
        require(orderData.sellToken != AURA); // Can't sell AURA;
        require(orderData.sellToken != BADGER); // Can't sell BADGER either;
        require(orderData.sellToken != WETH); // Can't sell WETH
        require(orderData.buyToken == WETH); // Gotta Buy WETH;

        _doCowswapOrder(orderData, orderUid);
    }

    /// @dev
    /// Step 2.a
    /// Swap WETH -> BADGER
    function swapWethForBadger(Data calldata orderData, bytes memory orderUid) external {
        require(orderData.sellToken == WETH); // Must Sell WETH
        require(orderData.buyToken == BADGER); // Must Buy BADGER

        /// NOTE: checks for msg.sender == manager
        _doCowswapOrder(orderData, orderUid);
    }

    /// @dev
    /// Step 2.b
    /// Swap WETH -> graviAURA or WETH -> AURA
    function swapWethForAURA(Data calldata orderData, bytes memory orderUid) external {
        require(orderData.sellToken == WETH); // Must Sell WETH
        require(
            orderData.buyToken == AURA || 
            orderData.buyToken == IERC20(address(BVE_AURA))
        ); // Must buy AURA or BVE_AURA

        /// NOTE: checks for msg.sender == manager
        _doCowswapOrder(orderData, orderUid);
    }

    /// AURA -> graviAURA -> Always Deposit in vault, unless direct pool

    /// @dev
    /// Step 3 Emit the Aura
    /// Takes all the Aura, takes fee, locks and emits it
    // TODO: REDO MATH to handle case of AURA / graviAURA already in this contract
    function swapAURATobveAURAAndEmit() external nonReentrant {
        // Will take all the Aura left,
        // swap it for bveAura if cheaper, or deposit it directly
        // and then emit it
        require(msg.sender == manager);
        require(HARVEST_FORWARDER.badger_tree() == BADGER_TREE);

        uint256 totalAURA = AURA.balanceOf(address(this));
        
        // === Handling of AURA === //
        if(totalAURA > 0) {
            // We'll also deposit the AURA
            AURA.safeIncreaseAllowance(address(BVE_AURA), totalAURA);
            // Deposit to address(this)
            BVE_AURA.deposit(totalAURA);

            // NOTE: Can be re-extended to use xyz stable pool (just use try/catch and expect long term failure)
        }

        // === Emit bveAURA === //
        uint256 totalBveAURA = BVE_AURA.balanceOf(address(this));
        require(totalBveAURA > 0);

        uint256 ops_fee = totalBveAURA * OPS_FEE / MAX_BPS;
        IERC20(address(BVE_AURA)).safeTransfer(TREASURY, ops_fee);

        // Subtraction to avoid dust
        uint256 toEmit = totalBveAURA - ops_fee;

        // Emit token to tree via HARVEST_FORWARDER
        IERC20(address(BVE_AURA)).safeIncreaseAllowance(address(HARVEST_FORWARDER), toEmit);
        HARVEST_FORWARDER.distribute(address(BVE_AURA), toEmit, address(BVE_AURA));

        emit PerformanceFeeGovernance(address(BVE_AURA), ops_fee);
        emit BribeEmission(address(BVE_AURA), address(BVE_AURA), toEmit);
    }

    /// @dev
    /// Step 4 Emit the Badger
    function emitBadger() external nonReentrant {
        require(msg.sender == manager);
        require(HARVEST_FORWARDER.badger_tree() == BADGER_TREE);

        // Sends Badger to the Tree
        // Emits custom event for it
        uint256 totalBadger = BADGER.balanceOf(address(this));
        require(totalBadger > 0);

        uint256 ops_fee = totalBadger * OPS_FEE / MAX_BPS;
        BADGER.safeTransfer(TREASURY, ops_fee);

        uint256 toEmitTotal = totalBadger - ops_fee;
        BADGER.safeIncreaseAllowance(address(HARVEST_FORWARDER), toEmitTotal);
        HARVEST_FORWARDER.distribute(address(BADGER), toEmitTotal, address(BVE_AURA));

        emit PerformanceFeeGovernance(address(BADGER), ops_fee);
        emit BribeEmission(address(BADGER), address(BVE_AURA), toEmitTotal);
    }

    /// === EXTRA === ///

    /// @dev Set new allowance to the relayer
    /// @notice used if you place two or more orders with the same token
    ///     In that case, place all orders, then set allowance to the sum of all orders
    function setCustomAllowance(address token, uint256 newAllowance) external nonReentrant {
        require(msg.sender == manager);

        IERC20(token).safeApprove(RELAYER, 0);
        // NOTE: Set this to the amount you need SUM(all_orders) to ensure they all go through
        IERC20(token).safeApprove(RELAYER, newAllowance);
    }
}