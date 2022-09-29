// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface INToken {
  function allowance ( address account, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function currencyId () external view returns ( uint16 );
  function decimals () external view returns ( uint8 );
  function getPresentValueAssetDenominated () external view returns ( int256 );
  function getPresentValueUnderlyingDenominated () external view returns ( int256 );
  function name () external view returns ( string memory );
  function proxy () external view returns ( address );
  function symbol () external view returns ( string memory );
  function totalSupply () external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./AssetRateAdapter.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
/// @dev Asset rate used to convert between underlying cash and asset cash
enum TokenType {UnderlyingToken, cToken, cETH, Ether, NonMintable, aToken}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

struct BalanceAction {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
}

struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
}

interface INotional {

    function getCurrency(uint16 currencyId) external view returns (Token memory assetToken, Token memory underlyingToken);

    function batchBalanceAction(address, BalanceAction[] calldata actions) external;

    function nTokenClaimIncentives() external returns(uint256);

    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool useUnderlying
    ) external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1

import "../external/interfaces/notional/INToken.sol";

pragma solidity 0.8.11;

interface INotionalStrategyContractHelper {
    function claimRewards(bool executeClaim) external returns(uint256);

    function deposit(uint256 amount) external returns(uint256);

    function withdraw(uint256 nTokenWithdraw) external returns(uint256);

    function withdrawAll() external returns (uint256);

    function nToken() external returns (INToken);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../interfaces/INotionalStrategyContractHelper.sol";
import "../../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../../external/interfaces/notional/INotional.sol";
import "../../external/interfaces/notional/INToken.sol";

/**
 * @notice This contract serves as a Notional strategy helper.
 * @dev
 *
 * This is done as NOTE rewards are claimed whenever mints or redeems occur,
 * in which case the rewards are returned to the master Spool contract.
 * Having a separate contract for each Notional strategy
 * gves us a way to collect the NOTE token rewards belonging
 * to this particular Spool strategy.
 * There should be one helper contract per Notional strategy.
 *
 * It can only be called by the Spool contract.
 * It should be only be used by NotionalStrategy.
 */
contract NotionalContractHelper is INotionalStrategyContractHelper {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    INotional public immutable notional;
    INToken public immutable nToken;
    IERC20 public immutable note;
    uint16 public immutable id;
    IERC20 public immutable underlying;
    address public immutable spool;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        INotional _notional,
        IERC20 _note,
        INToken _nToken,
        uint16 _id,
        IERC20 _underlying,
        address _spool
    ) {
        require(address(_notional) != address(0), "NotionalContractHelper::constructor: Notional address cannot be 0");
        require(address(_note) != address(0), "NotionalContractHelper::constructor: NOTE address cannot be 0");
        require(address(_nToken) != address(0), "NotionalContractHelper::constructor: Token address cannot be 0");
        require(_id == _nToken.currencyId(), "NotionalContractHelper::constructor: ID is not the same as nToken ID");
        (, Token memory underlyingToken) = _notional.getCurrency(_id);
        require(
            address(_underlying) == underlyingToken.tokenAddress,
            "NotionalContractHelper::constructor: Underlying and notional underlying do not match"
        );
        require(_spool != address(0), "NotionalContractHelper::constructor: Spool address cannot be 0");

        notional = _notional;
        note = _note;
        nToken = _nToken;
        id = _id;
        underlying = _underlying;
        spool = _spool;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Claim NOTE rewards from Notional proxy.
     * @dev
     * Rewards are sent back to the Spool contract
     *
     * @param executeClaim Do execute the claim
     * @return rewards Amount of NOTE tokens claimed
     */
    function claimRewards(bool executeClaim) external override onlySpool returns (uint256 rewards) {
        if (executeClaim) {
            notional.nTokenClaimIncentives();
        }

        rewards = note.balanceOf(address(this));

        IERC20(note).safeTransfer(msg.sender, rewards);
    }

    /**
     * @notice Deposit to Notional market
     * @dev
     * The Spool should send `underlying` token in size of `amount`
     * before calling this contract.
     * The contract deposits the received underlying and returns the
     * newly received nToken amount.
     *
     * @param amount Amount of underlying to deposit
     * @return nTokenBalanceNew Gained nToken amount from depositing
     */
    function deposit(uint256 amount) external override onlySpool returns (uint256) {
        BalanceAction[] memory actions = _buildBalanceAction(
            DepositActionType.DepositUnderlyingAndMintNToken,
            amount,
            false,
            false
        );

        // deposit underlying
        underlying.safeApprove(address(notional), amount);
        uint256 nTokenBalanceBefore = nToken.balanceOf(address(this));
        notional.batchBalanceAction(address(this), actions);
        uint256 nTokenBalanceNew = nToken.balanceOf(address(this)) - nTokenBalanceBefore;

        _resetAllowance(underlying, address(notional));

        return nTokenBalanceNew;
    }

    /**
     * @notice Withdraw from Notional market
     * @dev
     * The withdrawn underlying amount is then send back to the Spool.
     *
     * @param nTokenWithdraw Amount of tokens to withdraw
     * @return underlyingWithdrawn Gained underlying amount from withdrawing
     */
    function withdraw(uint256 nTokenWithdraw) external override onlySpool returns (uint256) {
        BalanceAction[] memory actions = _buildBalanceAction(
            DepositActionType.RedeemNToken,
            nTokenWithdraw,
            true,
            true
        );

        // withdraw nToken tokens from notional
        uint256 underlyingBefore = underlying.balanceOf(address(this));
        notional.batchBalanceAction(address(this), actions);
        uint256 underlyingWithdrawn = underlying.balanceOf(address(this)) - underlyingBefore;
        // transfer withdrawn back to spool
        underlying.safeTransfer(msg.sender, underlyingWithdrawn);
        return underlyingWithdrawn;
    }

    function withdrawAll() external override onlySpool returns (uint256) {
        BalanceAction[] memory actions = _buildBalanceAction(
            DepositActionType.RedeemNToken,
            nToken.balanceOf(address(this)),
            true,
            true
        );

        // withdraw nToken tokens from notional
        notional.batchBalanceAction(address(this), actions);

        uint256 underlyingWithdrawn = underlying.balanceOf(address(this));

        // transfer withdrawn back to spool
        underlying.safeTransfer(msg.sender, underlyingWithdrawn);

        return underlyingWithdrawn;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Reset allowance to zero if previously set to a higher value.
     */
    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
    }

    function _onlySpool() private view {
        require(msg.sender == spool, "NotionalStrategy::_onlySpool: Caller is not the Spool contract");
    }

    function _buildBalanceAction(
        DepositActionType actionType,
        uint256 depositActionAmount,
        bool withdrawEntireCashBalance,
        bool redeemToUnderlying
    ) private view returns (BalanceAction[] memory actions) {
        actions = new BalanceAction[](1);
        actions[0] = BalanceAction({
            actionType: actionType,
            currencyId: id,
            depositActionAmount: depositActionAmount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: withdrawEntireCashBalance,
            redeemToUnderlying: redeemToUnderlying
        });
    }

    /* ========== MODIFIERS ========== */

    modifier onlySpool() {
        _onlySpool();
        _;
    }
}