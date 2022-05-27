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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

library Errors {
  // *** Contract Specific Errors ***
  // BorrowerPools
  error BP_BORROW_MAX_BORROWABLE_AMOUNT_EXCEEDED(); // "Amount borrowed is too big, exceeding borrowable capacity";
  error BP_REPAY_NO_ACTIVE_LOAN(); // "No active loan to be repaid, action cannot be performed";
  error BP_BORROW_UNSUFFICIENT_BORROWABLE_AMOUNT_WITHIN_BRACKETS(); // "Amount provided is greater than available amount within min rate and max rate brackets";
  error BP_REPAY_AT_MATURITY_ONLY(); // "Maturity has not been reached yet, action cannot be performed";
  error BP_BORROW_COOLDOWN_PERIOD_NOT_OVER(); // "Cooldown period after a repayment is not over";
  error BP_MULTIPLE_BORROW_AFTER_MATURITY(); // "Cannot borrow again from pool after loan maturity";
  error BP_POOL_NOT_ACTIVE(); // "Pool not active"
  error BP_POOL_DEFAULTED(); // "Pool defaulted"
  error BP_LOAN_ONGOING(); // "There's a loan ongoing, cannot update rate"
  error BP_BORROW_OUT_OF_BOUND_AMOUNT(); // "Amount provided is greater than available amount, action cannot be performed";
  error BP_POOL_CLOSED(); // "Pool closed";
  error BP_OUT_OF_BOUND_MIN_RATE(); // "Rate provided is lower than minimum rate of the pool";
  error BP_OUT_OF_BOUND_MAX_RATE(); // "Rate provided is greater than maximum rate of the pool";
  error BP_UNMATCHED_TOKEN(); // "Token/Asset provided does not match the underlying token of the pool";
  error BP_RATE_SPACING(); // "Decimals of rate provided do not comply with rate spacing of the pool";
  error BP_BOND_ISSUANCE_ID_TOO_HIGH(); // "Bond issuance id is too high";
  error BP_NO_DEPOSIT_TO_WITHDRAW(); // "Deposited amount non-borrowed equals to zero";
  error BP_TARGET_BOND_ISSUANCE_INDEX_EMPTY(); // "Target bond issuance index has no amount to withdraw";
  error BP_EARLY_REPAY_NOT_ACTIVATED(); // "The early repay feature is not activated for this pool";

  // PoolController
  error PC_POOL_NOT_ACTIVE(); // "Pool not active"
  error PC_POOL_DEFAULTED(); // "Pool defaulted"
  error PC_POOL_ALREADY_SET_FOR_BORROWER(); // "Targeted borrower is already set for another pool";
  error PC_POOL_TOKEN_NOT_SUPPORTED(); // "Underlying token is not supported by the yield provider";
  error PC_DISALLOW_UNMATCHED_BORROWER(); // "Revoking the wrong borrower as the provided borrower does not match the provided address";
  error PC_RATE_SPACING_COMPLIANCE(); // "Provided rate must be compliant with rate spacing";
  error PC_NO_ONGOING_LOAN(); // "Cannot default a pool that has no ongoing loan";
  error PC_NOT_ENOUGH_PROTOCOL_FEES(); // "Not enough registered protocol fees to withdraw";
  error PC_POOL_ALREADY_CLOSED(); // "Pool already closed";
  error PC_ZERO_POOL(); // "Cannot make actions on the zero pool";
  error PC_ZERO_ADDRESS(); // "Cannot make actions on the zero address";
  error PC_REPAYMENT_PERIOD_ONGOING(); // "Cannot default pool while repayment period in ongoing"
  error PC_ESTABLISHMENT_FEES_TOO_HIGH(); // "Cannot set establishment fee over 100% of loan amount"

  // PositionManager
  error POS_MGMT_ONLY_OWNER(); // "Only the owner of the position token can manage it (update rate, withdraw)";
  error POS_POSITION_ONLY_IN_BONDS(); // "Cannot withdraw a position that's only in bonds";
  error POS_ZERO_AMOUNT(); // "Cannot deposit zero amount";
  error POS_TIMELOCK(); // "Cannot withdraw or update rate in the same block as deposit";
  error POS_POSITION_DOES_NOT_EXIST(); // "Position does not exist";
  error POS_POOL_DEFAULTED(); // "Pool defaulted";

  // PositionDescriptor
  error POD_BAD_INPUT(); // "Input pool identifier does not correspond to input pool hash";

  //*** Library Specific Errors ***
  // WadRayMath
  error MATH_MULTIPLICATION_OVERFLOW(); // "The multiplication would result in a overflow";
  error MATH_ADDITION_OVERFLOW(); // "The addition would result in a overflow";
  error MATH_DIVISION_BY_ZERO(); // "The division would result in a divzion by zero";
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Rounding} from "./Rounding.sol";
import {Scaling} from "./Scaling.sol";
import {Uint128WadRayMath} from "./Uint128WadRayMath.sol";
import "./Types.sol";
import "./Errors.sol";
import "../extensions/AaveILendingPool.sol";

library PoolLogic {
  event PoolActivated(bytes32 poolHash);
  enum BalanceUpdateType {
    INCREASE,
    DECREASE
  }
  event TickInitialized(bytes32 borrower, uint128 rate, uint128 atlendisLiquidityRatio);
  event TickLoanDeposit(bytes32 borrower, uint128 rate, uint128 adjustedPendingDeposit);
  event TickNoLoanDeposit(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedPendingDeposit,
    uint128 atlendisLiquidityRatio
  );
  event TickBorrow(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedRemainingAmountReduction,
    uint128 loanedAmount,
    uint128 atlendisLiquidityRatio,
    uint128 unborrowedRatio
  );
  event TickWithdrawPending(bytes32 borrower, uint128 rate, uint128 adjustedAmountToWithdraw);
  event TickWithdrawRemaining(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 atlendisLiquidityRatio,
    uint128 accruedFeesToWithdraw
  );
  event TickPendingDeposit(
    bytes32 borrower,
    uint128 rate,
    uint128 adjustedPendingAmount,
    bool poolBondIssuanceIndexIncremented
  );
  event TopUpLiquidityRewards(bytes32 borrower, uint128 addedLiquidityRewards);
  event TickRepay(bytes32 borrower, uint128 rate, uint128 newAdjustedRemainingAmount, uint128 atlendisLiquidityRatio);
  event CollectFeesForTick(bytes32 borrower, uint128 rate, uint128 remainingLiquidityRewards, uint128 addedAccruedFees);

  using PoolLogic for Types.Pool;
  using Uint128WadRayMath for uint128;
  using Rounding for uint128;
  using Scaling for uint128;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public constant SECONDS_PER_YEAR = 365 days;
  uint256 public constant WAD = 1e18;
  uint256 public constant RAY = 1e27;

  /**
   * @dev Getter for the multiplier allowing a conversion between pending and deposited
   * amounts for the target bonds issuance index
   **/
  function getBondIssuanceMultiplierForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 bondsIssuanceIndex
  ) internal view returns (uint128 returnBondsIssuanceMultiplier) {
    Types.Tick storage tick = pool.ticks[rate];
    returnBondsIssuanceMultiplier = tick.bondsIssuanceIndexMultiplier[bondsIssuanceIndex];
    if (returnBondsIssuanceMultiplier == 0) {
      returnBondsIssuanceMultiplier = uint128(RAY);
    }
  }

  /**
   * @dev Get share of accumulated fees from stored current tick state
   **/
  function getAccruedFeesShare(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmount
  ) internal view returns (uint128 accruedFeesShare) {
    Types.Tick storage tick = pool.ticks[rate];
    accruedFeesShare = tick.accruedFees.wadMul(adjustedAmount).wadDiv(tick.adjustedRemainingAmount);
  }

  /**
   * @dev Get share of accumulated fees from estimated current tick state
   **/
  function peekAccruedFeesShare(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 accruedFees
  ) public view returns (uint128 accruedFeesShare) {
    Types.Tick storage tick = pool.ticks[rate];
    if (tick.adjustedRemainingAmount == 0) {
      return 0;
    }
    accruedFeesShare = accruedFees.wadMul(adjustedAmount).wadDiv(tick.adjustedRemainingAmount);
  }

  function getLateRepayFeePerBond(Types.Pool storage pool) public view returns (uint128 lateRepayFeePerBond) {
    uint256 lateRepaymentTimestamp = pool.state.currentMaturity + pool.parameters.REPAYMENT_PERIOD;
    if (block.timestamp > lateRepaymentTimestamp) {
      uint256 referenceTimestamp = pool.state.defaultTimestamp > 0 ? pool.state.defaultTimestamp : block.timestamp;
      lateRepayFeePerBond = uint128(
        uint256(referenceTimestamp - lateRepaymentTimestamp) * uint256(pool.parameters.LATE_REPAY_FEE_PER_BOND_RATE)
      );
    }
  }

  function getRepaymentFees(Types.Pool storage pool, uint128 normalizedRepayAmount)
    public
    view
    returns (uint128 repaymentFees)
  {
    repaymentFees = (normalizedRepayAmount - pool.state.normalizedBorrowedAmount).wadMul(
      pool.parameters.REPAYMENT_FEE_RATE
    );
  }

  /**
   * @dev The return value includes only notional and accrued interest,
   * it does not include any fees due for repay by the borrrower
   **/
  function getRepayValue(Types.Pool storage pool, bool earlyRepay) public view returns (uint128 repayValue) {
    if (pool.state.currentMaturity == 0) {
      return 0;
    }
    if (!earlyRepay) {
      // Note: Despite being in the context of a none early repay we prevent underflow in case of wrong user input
      // and allow querying expected bonds quantity if loan is repaid at maturity
      if (block.timestamp <= pool.state.currentMaturity) {
        return pool.state.bondsIssuedQuantity;
      }
    }
    for (
      uint128 rate = pool.state.lowerInterestRate;
      rate <= pool.parameters.MAX_RATE;
      rate += pool.parameters.RATE_SPACING
    ) {
      Types.Tick storage tick = pool.ticks[rate];
      repayValue += getTimeValue(pool, tick.bondsQuantity, rate);
    }
  }

  function getTimeValue(
    Types.Pool storage pool,
    uint128 bondsQuantity,
    uint128 rate
  ) public view returns (uint128) {
    if (block.timestamp <= pool.state.currentMaturity) {
      return bondsQuantity.wadMul(getTickBondPrice(rate, uint128(pool.state.currentMaturity - block.timestamp)));
    }
    uint256 referenceTimestamp = uint128(block.timestamp);
    if (pool.state.defaultTimestamp > 0) {
      referenceTimestamp = pool.state.defaultTimestamp;
    }
    return bondsQuantity.wadDiv(getTickBondPrice(rate, uint128(referenceTimestamp - pool.state.currentMaturity)));
  }

  /**
   * @dev Deposit to a target tick
   * Updates tick data
   **/
  function depositToTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 normalizedAmount
  ) public returns (uint128 adjustedAmount, uint128 returnBondsIssuanceIndex) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFees(rate);

    // if there is an ongoing loan, the deposited amount goes to the pending
    // quantity and will be considered for next loan
    if (pool.state.currentMaturity > 0) {
      adjustedAmount = normalizedAmount.wadRayDiv(tick.yieldProviderLiquidityRatio);
      tick.adjustedPendingAmount += adjustedAmount;
      returnBondsIssuanceIndex = pool.state.currentBondsIssuanceIndex + 1;
      emit TickLoanDeposit(pool.parameters.POOL_HASH, rate, adjustedAmount);
    }
    // if there is no ongoing loan, the deposited amount goes to total and remaining
    // amount and can be borrowed instantaneously
    else {
      adjustedAmount = normalizedAmount.wadRayDiv(tick.atlendisLiquidityRatio);
      tick.adjustedTotalAmount += adjustedAmount;
      tick.adjustedRemainingAmount += adjustedAmount;
      returnBondsIssuanceIndex = pool.state.currentBondsIssuanceIndex;
      pool.state.normalizedAvailableDeposits += normalizedAmount;

      // return amount adapted to bond index
      adjustedAmount = adjustedAmount.wadRayDiv(
        pool.getBondIssuanceMultiplierForTick(rate, pool.state.currentBondsIssuanceIndex)
      );
      emit TickNoLoanDeposit(pool.parameters.POOL_HASH, rate, adjustedAmount, tick.atlendisLiquidityRatio);
    }
    if ((pool.state.lowerInterestRate == 0) || (rate < pool.state.lowerInterestRate)) {
      pool.state.lowerInterestRate = rate;
    }
  }

  /**
   * @dev Computes the quantity of bonds purchased, and the equivalent adjusted deposit amount used for the issuance
   **/
  function getBondsIssuanceParametersForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 normalizedRemainingAmount
  ) public returns (uint128 bondsPurchasedQuantity, uint128 normalizedUsedAmount) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio) >= normalizedRemainingAmount) {
      normalizedUsedAmount = normalizedRemainingAmount;
    } else if (
      tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio) + tick.accruedFees >=
      normalizedRemainingAmount
    ) {
      normalizedUsedAmount = normalizedRemainingAmount;
      tick.accruedFees -=
        normalizedRemainingAmount -
        tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio);
    } else {
      normalizedUsedAmount = tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio) + tick.accruedFees;
      tick.accruedFees = 0;
    }
    uint128 bondsPurchasePrice = getTickBondPrice(
      rate,
      pool.state.currentMaturity == 0
        ? pool.parameters.LOAN_DURATION
        : pool.state.currentMaturity - uint128(block.timestamp)
    );
    bondsPurchasedQuantity = normalizedUsedAmount.wadDiv(bondsPurchasePrice);
  }

  /**
   * @dev Makes all the state changes necessary to add bonds to a tick
   * Updates tick data and conversion data
   **/
  function addBondsToTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 bondsIssuedQuantity,
    uint128 normalizedUsedAmountForPurchase
  ) public {
    Types.Tick storage tick = pool.ticks[rate];

    // update global state for tick and pool
    tick.bondsQuantity += bondsIssuedQuantity;
    uint128 adjustedAmountForPurchase = normalizedUsedAmountForPurchase.wadRayDiv(tick.atlendisLiquidityRatio);
    if (adjustedAmountForPurchase > tick.adjustedRemainingAmount) {
      adjustedAmountForPurchase = tick.adjustedRemainingAmount;
    }
    tick.adjustedRemainingAmount -= adjustedAmountForPurchase;
    tick.normalizedLoanedAmount += normalizedUsedAmountForPurchase;
    // emit event with tick updates
    uint128 unborrowedRatio = tick.adjustedRemainingAmount.wadDiv(tick.adjustedTotalAmount);
    emit TickBorrow(
      pool.parameters.POOL_HASH,
      rate,
      adjustedAmountForPurchase,
      normalizedUsedAmountForPurchase,
      tick.atlendisLiquidityRatio,
      unborrowedRatio
    );
    pool.state.bondsIssuedQuantity += bondsIssuedQuantity;
    pool.state.normalizedAvailableDeposits -= normalizedUsedAmountForPurchase;
  }

  /**
   * @dev Computes how the position is split between deposit and bonds
   **/
  function computeAmountRepartitionForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmount,
    uint128 bondsIssuanceIndex
  ) public view returns (uint128 bondsQuantity, uint128 adjustedDepositedAmount) {
    Types.Tick storage tick = pool.ticks[rate];

    if (bondsIssuanceIndex > pool.state.currentBondsIssuanceIndex) {
      return (0, adjustedAmount);
    }

    adjustedAmount = adjustedAmount.wadRayMul(pool.getBondIssuanceMultiplierForTick(rate, bondsIssuanceIndex));
    uint128 adjustedAmountUsedForBondsIssuance;
    if (tick.adjustedTotalAmount > 0) {
      adjustedAmountUsedForBondsIssuance = adjustedAmount
        .wadMul(tick.adjustedTotalAmount - tick.adjustedRemainingAmount)
        .wadDiv(tick.adjustedTotalAmount + tick.adjustedWithdrawnAmount);
    }

    if (tick.adjustedTotalAmount > tick.adjustedRemainingAmount) {
      bondsQuantity = tick.bondsQuantity.wadMul(adjustedAmountUsedForBondsIssuance).wadDiv(
        tick.adjustedTotalAmount - tick.adjustedRemainingAmount
      );
    }
    adjustedDepositedAmount = (adjustedAmount - adjustedAmountUsedForBondsIssuance);
  }

  /**
   * @dev Updates tick data after a withdrawal consisting of only amount deposited to yield provider
   **/
  function withdrawDepositedAmountForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 adjustedAmountToWithdraw,
    uint128 bondsIssuanceIndex
  ) public returns (uint128 normalizedAmountToWithdraw) {
    Types.Tick storage tick = pool.ticks[rate];

    pool.collectFees(rate);

    if (bondsIssuanceIndex <= pool.state.currentBondsIssuanceIndex) {
      uint128 feesShareToWithdraw = pool.getAccruedFeesShare(rate, adjustedAmountToWithdraw);
      tick.accruedFees -= feesShareToWithdraw;
      tick.adjustedTotalAmount -= adjustedAmountToWithdraw;
      tick.adjustedRemainingAmount -= adjustedAmountToWithdraw;

      normalizedAmountToWithdraw =
        adjustedAmountToWithdraw.wadRayMul(tick.atlendisLiquidityRatio) +
        feesShareToWithdraw;
      pool.state.normalizedAvailableDeposits -= normalizedAmountToWithdraw.round();

      // register withdrawn amount from partially matched positions
      // to maintain the proportion of bonds in each subsequent position the same
      if (tick.bondsQuantity > 0) {
        tick.adjustedWithdrawnAmount += adjustedAmountToWithdraw;
      }
      emit TickWithdrawRemaining(
        pool.parameters.POOL_HASH,
        rate,
        adjustedAmountToWithdraw,
        tick.atlendisLiquidityRatio,
        feesShareToWithdraw
      );
    } else {
      tick.adjustedPendingAmount -= adjustedAmountToWithdraw;
      normalizedAmountToWithdraw = adjustedAmountToWithdraw.wadRayMul(tick.yieldProviderLiquidityRatio);
      emit TickWithdrawPending(pool.parameters.POOL_HASH, rate, adjustedAmountToWithdraw);
    }

    // update lowerInterestRate if necessary
    if ((rate == pool.state.lowerInterestRate) && tick.adjustedTotalAmount == 0) {
      uint128 nextRate = rate + pool.parameters.RATE_SPACING;
      while (nextRate <= pool.parameters.MAX_RATE && pool.ticks[nextRate].adjustedTotalAmount == 0) {
        nextRate += pool.parameters.RATE_SPACING;
      }
      if (nextRate >= pool.parameters.MAX_RATE) {
        pool.state.lowerInterestRate = 0;
      } else {
        pool.state.lowerInterestRate = nextRate;
      }
    }
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function repayForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 lateRepayFeePerBond
  ) public returns (uint128 normalizedRepayAmountForTick, uint128 lateRepayFeeForTick) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.bondsQuantity > 0) {
      normalizedRepayAmountForTick = getTimeValue(pool, tick.bondsQuantity, rate);
      lateRepayFeeForTick = lateRepayFeePerBond.wadMul(normalizedRepayAmountForTick);
      uint128 bondPaidInterests = normalizedRepayAmountForTick - tick.normalizedLoanedAmount;
      // update liquidity ratio with interests from bonds, yield provider and liquidity rewards
      tick.atlendisLiquidityRatio += (tick.accruedFees + bondPaidInterests + lateRepayFeeForTick)
        .wadDiv(tick.adjustedTotalAmount)
        .wadToRay();

      // update tick amounts
      tick.bondsQuantity = 0;
      tick.adjustedWithdrawnAmount = 0;
      tick.normalizedLoanedAmount = 0;
      tick.accruedFees = 0;
      tick.adjustedRemainingAmount = tick.adjustedTotalAmount;
      emit TickRepay(pool.parameters.POOL_HASH, rate, tick.adjustedTotalAmount, tick.atlendisLiquidityRatio);
    }
  }

  /**
   * @dev Updates tick data after a repayment
   **/
  function includePendingDepositsForTick(
    Types.Pool storage pool,
    uint128 rate,
    bool bondsIssuanceIndexAlreadyIncremented
  ) internal returns (bool pendingDepositsExist) {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.adjustedPendingAmount > 0) {
      if (!bondsIssuanceIndexAlreadyIncremented) {
        pool.state.currentBondsIssuanceIndex += 1;
      }
      // include pending deposit amount into tick excluding them from bonds interest from current issuance
      tick.bondsIssuanceIndexMultiplier[pool.state.currentBondsIssuanceIndex] = pool
        .state
        .yieldProviderLiquidityRatio
        .rayDiv(tick.atlendisLiquidityRatio);
      uint128 adjustedPendingAmount = tick.adjustedPendingAmount.wadRayMul(
        tick.bondsIssuanceIndexMultiplier[pool.state.currentBondsIssuanceIndex]
      );

      // update global pool state
      pool.state.normalizedAvailableDeposits += tick.adjustedPendingAmount.wadRayMul(
        pool.state.yieldProviderLiquidityRatio
      );

      // update tick amounts
      tick.adjustedTotalAmount += adjustedPendingAmount;
      tick.adjustedRemainingAmount = tick.adjustedTotalAmount;
      tick.adjustedPendingAmount = 0;
      emit TickPendingDeposit(
        pool.parameters.POOL_HASH,
        rate,
        adjustedPendingAmount,
        !bondsIssuanceIndexAlreadyIncremented
      );
      return true;
    }
    return false;
  }

  /**
   * @dev Top up liquidity rewards for later distribution
   **/
  function topUpLiquidityRewards(Types.Pool storage pool, uint128 normalizedAmount)
    public
    returns (uint128 yieldProviderLiquidityRatio)
  {
    yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );
    pool.state.remainingAdjustedLiquidityRewardsReserve += normalizedAmount.wadRayDiv(yieldProviderLiquidityRatio);
  }

  /**
   * @dev Distributes remaining liquidity rewards reserve to lenders
   * Called in case of pool default
   **/
  function distributeLiquidityRewards(Types.Pool storage pool) public returns (uint128 distributedLiquidityRewards) {
    uint128 currentInterestRate = pool.state.lowerInterestRate;

    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );

    distributedLiquidityRewards = pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(
      yieldProviderLiquidityRatio
    );
    pool.state.normalizedAvailableDeposits += distributedLiquidityRewards;
    pool.state.remainingAdjustedLiquidityRewardsReserve = 0;

    while (pool.ticks[currentInterestRate].bondsQuantity > 0 && currentInterestRate <= pool.parameters.MAX_RATE) {
      pool.ticks[currentInterestRate].accruedFees += distributedLiquidityRewards
        .wadMul(pool.ticks[currentInterestRate].bondsQuantity)
        .wadDiv(pool.state.bondsIssuedQuantity);
      currentInterestRate += pool.parameters.RATE_SPACING;
    }
  }

  /**
   * @dev Updates tick data to reflect all fees accrued since last call
   * Accrued fees are composed of the yield provider liquidity ratio increase
   * and liquidity rewards paid by the borrower
   **/
  function collectFeesForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 yieldProviderLiquidityRatio
  ) internal {
    Types.Tick storage tick = pool.ticks[rate];
    if (tick.lastFeeDistributionTimestamp < block.timestamp) {
      (
        uint128 updatedAtlendisLiquidityRatio,
        uint128 updatedAccruedFees,
        uint128 liquidityRewardsIncrease,
        uint128 yieldProviderLiquidityRatioIncrease
      ) = pool.peekFeesForTick(rate, yieldProviderLiquidityRatio);

      // update global deposited amount
      pool.state.remainingAdjustedLiquidityRewardsReserve -= liquidityRewardsIncrease.wadRayDiv(
        yieldProviderLiquidityRatio
      );
      pool.state.normalizedAvailableDeposits +=
        liquidityRewardsIncrease +
        tick.adjustedRemainingAmount.wadRayMul(yieldProviderLiquidityRatioIncrease);

      // update tick data
      uint128 accruedFeesIncrease = updatedAccruedFees - tick.accruedFees;
      if (tick.atlendisLiquidityRatio == 0) {
        tick.yieldProviderLiquidityRatio = yieldProviderLiquidityRatio;
        emit TickInitialized(pool.parameters.POOL_HASH, rate, yieldProviderLiquidityRatio);
      }
      tick.atlendisLiquidityRatio = updatedAtlendisLiquidityRatio;
      tick.accruedFees = updatedAccruedFees;

      // update checkpoint data
      tick.lastFeeDistributionTimestamp = uint128(block.timestamp);

      emit CollectFeesForTick(
        pool.parameters.POOL_HASH,
        rate,
        pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(yieldProviderLiquidityRatio),
        accruedFeesIncrease
      );
    }
  }

  function collectFees(Types.Pool storage pool, uint128 rate) internal {
    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );
    pool.collectFeesForTick(rate, yieldProviderLiquidityRatio);
    pool.ticks[rate].yieldProviderLiquidityRatio = yieldProviderLiquidityRatio;
  }

  function collectFees(Types.Pool storage pool) internal {
    uint128 yieldProviderLiquidityRatio = uint128(
      pool.parameters.YIELD_PROVIDER.getReserveNormalizedIncome(address(pool.parameters.UNDERLYING_TOKEN))
    );
    for (
      uint128 currentInterestRate = pool.state.lowerInterestRate;
      currentInterestRate <= pool.parameters.MAX_RATE;
      currentInterestRate += pool.parameters.RATE_SPACING
    ) {
      pool.collectFeesForTick(currentInterestRate, yieldProviderLiquidityRatio);
    }
    pool.state.yieldProviderLiquidityRatio = yieldProviderLiquidityRatio;
  }

  /**
   * @dev Peek updated liquidity ratio and accrued fess for the target tick
   * Used to compute a position balance without updating storage
   **/
  function peekFeesForTick(
    Types.Pool storage pool,
    uint128 rate,
    uint128 yieldProviderLiquidityRatio
  )
    internal
    view
    returns (
      uint128 updatedAtlendisLiquidityRatio,
      uint128 updatedAccruedFees,
      uint128 liquidityRewardsIncrease,
      uint128 yieldProviderLiquidityRatioIncrease
    )
  {
    Types.Tick storage tick = pool.ticks[rate];

    if (tick.atlendisLiquidityRatio == 0) {
      return (yieldProviderLiquidityRatio, 0, 0, 0);
    }

    updatedAtlendisLiquidityRatio = tick.atlendisLiquidityRatio;
    updatedAccruedFees = tick.accruedFees;

    uint128 referenceLiquidityRatio;
    if (pool.state.yieldProviderLiquidityRatio > tick.yieldProviderLiquidityRatio) {
      referenceLiquidityRatio = pool.state.yieldProviderLiquidityRatio;
    } else {
      referenceLiquidityRatio = tick.yieldProviderLiquidityRatio;
    }
    yieldProviderLiquidityRatioIncrease = yieldProviderLiquidityRatio - referenceLiquidityRatio;

    // get additional fees from liquidity rewards
    liquidityRewardsIncrease = pool.getLiquidityRewardsIncrease(rate);
    uint128 currentNormalizedRemainingLiquidityRewards = pool.state.remainingAdjustedLiquidityRewardsReserve.wadRayMul(
      yieldProviderLiquidityRatio
    );
    if (liquidityRewardsIncrease > currentNormalizedRemainingLiquidityRewards) {
      liquidityRewardsIncrease = currentNormalizedRemainingLiquidityRewards;
    }
    // if no ongoing loan, all deposited amount gets the yield provider
    // and liquidity rewards so the global liquidity ratio is updated
    if (pool.state.currentMaturity == 0) {
      updatedAtlendisLiquidityRatio += yieldProviderLiquidityRatioIncrease;
      if (tick.adjustedRemainingAmount > 0) {
        updatedAtlendisLiquidityRatio += liquidityRewardsIncrease.wadToRay().wadDiv(tick.adjustedRemainingAmount);
      }
    }
    // if ongoing loan, accruing fees components are added, liquidity ratio will be updated at repay time
    else {
      updatedAccruedFees +=
        tick.adjustedRemainingAmount.wadRayMul(yieldProviderLiquidityRatioIncrease) +
        liquidityRewardsIncrease;
    }
  }

  /**
   * @dev Computes liquidity rewards amount to be paid to lenders since last fee collection
   * Liquidity rewards are paid to the unborrowed amount, and distributed to all ticks depending
   * on their normalized amounts
   **/
  function getLiquidityRewardsIncrease(Types.Pool storage pool, uint128 rate)
    internal
    view
    returns (uint128 liquidityRewardsIncrease)
  {
    Types.Tick storage tick = pool.ticks[rate];
    if (pool.state.normalizedAvailableDeposits > 0) {
      liquidityRewardsIncrease = (pool.parameters.LIQUIDITY_REWARDS_DISTRIBUTION_RATE *
        (uint128(block.timestamp) - tick.lastFeeDistributionTimestamp))
        .wadMul(pool.parameters.MAX_BORROWABLE_AMOUNT - pool.state.normalizedBorrowedAmount)
        .wadDiv(pool.parameters.MAX_BORROWABLE_AMOUNT)
        .wadMul(tick.adjustedRemainingAmount.wadRayMul(tick.atlendisLiquidityRatio))
        .wadDiv(pool.state.normalizedAvailableDeposits);
    }
  }

  function getTickBondPrice(uint128 rate, uint128 loanDuration) internal pure returns (uint128 price) {
    price = uint128(WAD).wadDiv(uint128(WAD + (uint256(rate) * uint256(loanDuration)) / uint256(SECONDS_PER_YEAR)));
  }

  function depositToYieldProvider(
    Types.Pool storage pool,
    address from,
    uint128 normalizedAmount
  ) public {
    IERC20Upgradeable underlyingToken = IERC20Upgradeable(pool.parameters.UNDERLYING_TOKEN);
    uint128 scaledAmount = normalizedAmount.scaleFromWad(pool.parameters.TOKEN_DECIMALS);
    ILendingPool yieldProvider = pool.parameters.YIELD_PROVIDER;
    underlyingToken.safeIncreaseAllowance(address(yieldProvider), scaledAmount);
    underlyingToken.safeTransferFrom(from, address(this), scaledAmount);
    yieldProvider.deposit(pool.parameters.UNDERLYING_TOKEN, scaledAmount, address(this), 0);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Rounding library
 * @author Atlendis
 * @dev Rounding utilities to mitigate precision loss when doing wad ray math operations
 **/
library Rounding {
  using Rounding for uint128;

  uint128 internal constant PRECISION = 1e3;

  /**
   * @notice rounds the input number with the default precision
   **/
  function round(uint128 amount) internal pure returns (uint128) {
    return (amount / PRECISION) * PRECISION;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Scaling library
 * @author Atlendis
 * @dev Scale an arbitrary number to or from WAD precision
 **/
library Scaling {
  uint256 internal constant WAD = 1e18;

  /**
   * @notice Scales an input amount to wad precision
   **/
  function scaleToWad(uint128 a, uint256 precision) internal pure returns (uint128) {
    return uint128((uint256(a) * WAD) / 10**precision);
  }

  /**
   * @notice Scales an input amount from wad to target precision
   **/
  function scaleFromWad(uint128 a, uint256 precision) internal pure returns (uint128) {
    return uint128((uint256(a) * 10**precision) / WAD);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../extensions/AaveILendingPool.sol";

library Types {
  struct PositionDetails {
    uint128 adjustedBalance;
    uint128 rate;
    bytes32 poolHash;
    address underlyingToken;
    uint128 bondsIssuanceIndex;
    uint128 remainingBonds;
    uint128 bondsMaturity;
    uint128 creationTimestamp;
  }

  struct Tick {
    mapping(uint128 => uint128) bondsIssuanceIndexMultiplier;
    uint128 bondsQuantity;
    uint128 adjustedTotalAmount;
    uint128 adjustedRemainingAmount;
    uint128 adjustedWithdrawnAmount;
    uint128 adjustedPendingAmount;
    uint128 normalizedLoanedAmount;
    uint128 lastFeeDistributionTimestamp;
    uint128 atlendisLiquidityRatio;
    uint128 yieldProviderLiquidityRatio;
    uint128 accruedFees;
  }

  struct PoolParameters {
    bytes32 POOL_HASH;
    address UNDERLYING_TOKEN;
    uint8 TOKEN_DECIMALS;
    ILendingPool YIELD_PROVIDER;
    uint128 MIN_RATE;
    uint128 MAX_RATE;
    uint128 RATE_SPACING;
    uint128 MAX_BORROWABLE_AMOUNT;
    uint128 LOAN_DURATION;
    uint128 LIQUIDITY_REWARDS_DISTRIBUTION_RATE;
    uint128 COOLDOWN_PERIOD;
    uint128 REPAYMENT_PERIOD;
    uint128 LATE_REPAY_FEE_PER_BOND_RATE;
    uint128 ESTABLISHMENT_FEE_RATE;
    uint128 REPAYMENT_FEE_RATE;
    uint128 LIQUIDITY_REWARDS_ACTIVATION_THRESHOLD;
    bool EARLY_REPAY;
  }

  struct PoolState {
    bool active;
    bool defaulted;
    bool closed;
    uint128 currentMaturity;
    uint128 bondsIssuedQuantity;
    uint128 normalizedBorrowedAmount;
    uint128 normalizedAvailableDeposits;
    uint128 lowerInterestRate;
    uint128 nextLoanMinStart;
    uint128 remainingAdjustedLiquidityRewardsReserve;
    uint128 yieldProviderLiquidityRatio;
    uint128 currentBondsIssuanceIndex;
    uint128 defaultTimestamp;
  }

  struct Pool {
    PoolParameters parameters;
    PoolState state;
    mapping(uint256 => Tick) ticks;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./WadRayMath.sol";

/**
 * @title Uint128WadRayMath library
 **/
library Uint128WadRayMath {
  using WadRayMath for uint256;

  /**
   * @dev Multiplies a wad to a ray, making back and forth conversions
   * @param a Wad
   * @param b Ray
   * @return The result of a*b, in wad
   **/
  function wadRayMul(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadToRay().rayMul(uint256(b)).rayToWad());
  }

  /**
   * @dev Divides a wad to a ray, making back and forth conversions
   * @param a Wad
   * @param b Ray
   * @return The result of a/b, in wad
   **/
  function wadRayDiv(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadToRay().rayDiv(uint256(b)).rayToWad());
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).rayDiv(uint256(b)));
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadMul(uint256(b)));
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint128 a, uint128 b) internal pure returns (uint128) {
    return uint128(uint256(a).wadDiv(uint256(b)));
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint128 a) internal pure returns (uint128) {
    return uint128(uint256(a).wadToRay());
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    if (a > (type(uint256).max - halfWAD) / b) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0) {
      revert Errors.MATH_DIVISION_BY_ZERO();
    }
    uint256 halfB = b / 2;

    if (a > (type(uint256).max - halfB) / WAD) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    if (a > (type(uint256).max - halfRAY) / b) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0) {
      revert Errors.MATH_DIVISION_BY_ZERO();
    }
    uint256 halfB = b / 2;

    if (a > (type(uint256).max - halfB) / RAY) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    if (result < halfRatio) {
      revert Errors.MATH_ADDITION_OVERFLOW();
    }

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    if (result / WAD_RAY_RATIO != a) {
      revert Errors.MATH_MULTIPLICATION_OVERFLOW();
    }
    return result;
  }
}