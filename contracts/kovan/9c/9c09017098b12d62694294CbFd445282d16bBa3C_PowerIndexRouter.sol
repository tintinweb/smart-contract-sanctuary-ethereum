/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

// File @powerpool/power-oracle/contracts/interfaces/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPowerPoke {
  /*** CLIENT'S CONTRACT INTERFACE ***/
  function authorizeReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporterWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinDeposit_
  ) external view;

  function authorizePoker(uint256 userId_, address pokerKey_) external view;

  function authorizePokerWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinStake_
  ) external view;

  function slashReporter(uint256 slasherId_, uint256 times_) external;

  function reward(
    uint256 userId_,
    uint256 gasUsed_,
    uint256 compensationPlan_,
    bytes calldata pokeOptions_
  ) external;

  /*** CLIENT OWNER INTERFACE ***/
  function transferClientOwnership(address client_, address to_) external;

  function addCredit(address client_, uint256 amount_) external;

  function withdrawCredit(
    address client_,
    address to_,
    uint256 amount_
  ) external;

  function setReportIntervals(
    address client_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setSlasherHeartbeat(address client_, uint256 slasherHeartbeat_) external;

  function setGasPriceLimit(address client_, uint256 gasPriceLimit_) external;

  function setFixedCompensations(
    address client_,
    uint256 eth_,
    uint256 cvp_
  ) external;

  function setBonusPlan(
    address client_,
    uint256 planId_,
    bool active_,
    uint64 bonusNominator_,
    uint64 bonusDenominator_,
    uint64 perGas_
  ) external;

  function setMinimalDeposit(address client_, uint256 defaultMinDeposit_) external;

  /*** POKER INTERFACE ***/
  function withdrawRewards(uint256 userId_, address to_) external;

  function setPokerKeyRewardWithdrawAllowance(uint256 userId_, bool allow_) external;

  /*** OWNER INTERFACE ***/
  function addClient(
    address client_,
    address owner_,
    bool canSlash_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setClientActiveFlag(address client_, bool active_) external;

  function setCanSlashFlag(address client_, bool canSlash) external;

  function setOracle(address oracle_) external;

  function pause() external;

  function unpause() external;

  /*** GETTERS ***/
  function creditOf(address client_) external view returns (uint256);

  function ownerOf(address client_) external view returns (address);

  function getMinMaxReportIntervals(address client_) external view returns (uint256 min, uint256 max);

  function getSlasherHeartbeat(address client_) external view returns (uint256);

  function getGasPriceLimit(address client_) external view returns (uint256);

  function getPokerBonus(
    address client_,
    uint256 bonusPlanId_,
    uint256 gasUsed_,
    uint256 userDeposit_
  ) external view returns (uint256);

  function getGasPriceFor(address client_) external view returns (uint256);
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File contracts/interfaces/IERC20Permit.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
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

// File contracts/interfaces/WrappedPiErc20Interface.sol

pragma solidity 0.6.12;

interface WrappedPiErc20Interface is IERC20Permit {
  function deposit(uint256 _amount) external payable returns (uint256);

  function withdraw(uint256 _amount) external payable returns (uint256);

  function withdrawShares(uint256 _burnAmount) external payable returns (uint256);

  function changeRouter(address _newRouter) external;

  function enableRouterCallback(bool _enable) external;

  function setNoFee(address _for, bool _noFee) external;

  function setEthFee(uint256 _newEthFee) external;

  function withdrawEthFee(address payable receiver) external;

  function approveUnderlying(address _to, uint256 _amount) external;

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount) external view returns (uint256);

  function getUnderlyingEquivalentForPi(uint256 _piAmount) external view returns (uint256);

  function balanceOfUnderlying(address account) external view returns (uint256);

  function callExternal(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external payable returns (bytes memory);

  struct ExternalCallData {
    address destination;
    bytes4 signature;
    bytes args;
    uint256 value;
  }

  function callExternalMultiple(ExternalCallData[] calldata calls) external payable returns (bytes[] memory);

  function getUnderlyingBalance() external view returns (uint256);
}

// File contracts/interfaces/IPoolRestrictions.sol

pragma solidity 0.6.12;

interface IPoolRestrictions {
  function getMaxTotalSupply(address _pool) external view returns (uint256);

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view returns (bool);

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view returns (bool);

  function isWithoutFee(address _addr) external view returns (bool);
}

// File contracts/interfaces/PowerIndexRouterInterface.sol

pragma solidity 0.6.12;

interface PowerIndexRouterInterface {
  enum StakeStatus {
    EQUILIBRIUM,
    EXCESS,
    SHORTAGE
  }

  //  function setVotingAndStaking(address _voting, address _staking) external;

  function setReserveConfig(
    uint256 _reserveRatio,
    uint256 _reserveRatioLowerBound,
    uint256 _reserveRatioUpperBound,
    uint256 _claimRewardsInterval
  ) external;

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount, uint256 _piTotalSupply)
    external
    view
    returns (uint256);

  function getPiEquivalentForUnderlyingPure(
    uint256 _underlyingAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) external pure returns (uint256);

  function getUnderlyingEquivalentForPi(uint256 _piAmount, uint256 _piTotalSupply) external view returns (uint256);

  function getUnderlyingEquivalentForPiPure(
    uint256 _piAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) external pure returns (uint256);
}

// File contracts/interfaces/IRouterConnector.sol

pragma solidity 0.6.12;

interface IRouterConnector {
  struct DistributeData {
    bytes stakeData;
    bytes stakeParams;
    uint256 performanceFee;
    address performanceFeeReceiver;
  }

  function beforePoke(
    bytes calldata _pokeData,
    DistributeData memory _distributeData,
    bool _willClaimReward
  ) external;

  function afterPoke(PowerIndexRouterInterface.StakeStatus _status, bool _rewardClaimDone)
    external
    returns (bytes calldata);

  function initRouter(bytes calldata) external;

  function getUnderlyingStaked() external view returns (uint256);

  function isClaimAvailable(
    bytes calldata _claimParams,
    uint256 _lastClaimRewardsAt,
    uint256 _lastChangeStakeAt
  ) external view returns (bool);

  function redeem(uint256 _amount, DistributeData calldata _distributeData)
    external
    returns (bytes calldata, bool claimed);

  function stake(uint256 _amount, DistributeData calldata _distributeData)
    external
    returns (bytes calldata, bool claimed);

  function calculateLockedProfit(bytes calldata _stakeData) external view returns (uint256);

  function claimRewards(PowerIndexRouterInterface.StakeStatus _status, DistributeData calldata _distributeData)
    external
    returns (bytes calldata);
}

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File contracts/interfaces/PowerIndexNaiveRouterInterface.sol

pragma solidity 0.6.12;

interface PowerIndexNaiveRouterInterface {
  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory _tokens
  ) external;

  function enableRouterCallback(address _piToken, bool _enable) external;

  function piTokenCallback(address sender, uint256 _withdrawAmount) external payable;
}

// File contracts/PowerIndexNaiveRouter.sol

pragma solidity 0.6.12;

contract PowerIndexNaiveRouter is PowerIndexNaiveRouterInterface, Ownable {
  using SafeMath for uint256;

  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory /*_tokens*/
  ) public virtual override onlyOwner {
    WrappedPiErc20Interface(_piToken).changeRouter(_newRouter);
  }

  function enableRouterCallback(address _piToken, bool _enable) public override onlyOwner {
    WrappedPiErc20Interface(_piToken).enableRouterCallback(_enable);
  }

  function piTokenCallback(address sender, uint256 _withdrawAmount) external payable virtual override {
    // DO NOTHING
  }
}

// File contracts/PowerIndexRouter.sol

pragma solidity 0.6.12;

/**
 * @notice PowerIndexRouter executes connectors with delegatecall to stake and redeem ERC20 tokens in
 * protocol-specified staking contracts. After calling, it saves stakeData and pokeData as connectors storage.
 * Available ERC20 token balance from piERC20 is distributed between connectors by its shares and calculated
 * as the difference between total balance and share of necessary balance(reserveRatio) for keeping in piERC20
 * for withdrawals.
 */
contract PowerIndexRouter is PowerIndexRouterInterface, PowerIndexNaiveRouter {
  using SafeERC20 for IERC20;

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;
  uint256 public constant HUNDRED_PCT = 1 ether;

  event SetReserveConfig(uint256 ratio, uint256 ratioLowerBound, uint256 ratioUpperBound, uint256 claimRewardsInterval);
  event SetPerformanceFee(uint256 performanceFee);
  event SetConnector(
    IRouterConnector indexed connector,
    uint256 share,
    bool callBeforeAfterPoke,
    uint256 indexed connectorIndex,
    bool indexed isNewConnector
  );
  event SetConnectorClaimParams(address connector, bytes claimParams);
  event SetConnectorStakeParams(address connector, bytes stakeParams);

  struct BasicConfig {
    address poolRestrictions;
    address powerPoke;
    uint256 reserveRatio;
    uint256 reserveRatioLowerBound;
    uint256 reserveRatioUpperBound;
    uint256 claimRewardsInterval;
    address performanceFeeReceiver;
    uint256 performanceFee;
  }

  WrappedPiErc20Interface public immutable piToken;
  IERC20 public immutable underlying;
  address public immutable performanceFeeReceiver;

  IPoolRestrictions public poolRestrictions;
  IPowerPoke public powerPoke;
  uint256 public reserveRatio;
  uint256 public claimRewardsInterval;
  uint256 public lastRebalancedByPokerAt;
  uint256 public reserveRatioLowerBound;
  uint256 public reserveRatioUpperBound;
  // 1 ether == 100%
  uint256 public performanceFee;
  Connector[] public connectors;

  struct RebalanceConfig {
    bool shouldPushFunds;
    StakeStatus status;
    uint256 diff;
    bool shouldClaim;
    bool forceRebalance;
    uint256 connectorIndex;
  }

  struct Connector {
    IRouterConnector connector;
    uint256 share;
    bool callBeforeAfterPoke;
    uint256 lastClaimRewardsAt;
    uint256 lastChangeStakeAt;
    bytes stakeData;
    bytes pokeData;
    bytes stakeParams;
    bytes claimParams;
  }

  struct ConnectorInput {
    bool newConnector;
    uint256 connectorIndex;
    IRouterConnector connector;
    uint256 share;
    bool callBeforeAfterPoke;
  }

  struct PokeFromState {
    uint256 minInterval;
    uint256 maxInterval;
    uint256 piTokenUnderlyingBalance;
    uint256 addToExpectedAmount;
    bool atLeastOneForceRebalance;
    bool skipCanPokeCheck;
  }

  modifier onlyEOA() {
    require(tx.origin == msg.sender, "ONLY_EOA");
    _;
  }

  modifier onlyReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  modifier onlyNonReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  constructor(address _piToken, BasicConfig memory _basicConfig) public PowerIndexNaiveRouter() Ownable() {
    require(_piToken != address(0), "INVALID_PI_TOKEN");
    require(_basicConfig.reserveRatioUpperBound <= HUNDRED_PCT, "UPPER_RR_GREATER_THAN_100_PCT");
    require(_basicConfig.reserveRatio >= _basicConfig.reserveRatioLowerBound, "RR_LTE_LOWER_RR");
    require(_basicConfig.reserveRatio <= _basicConfig.reserveRatioUpperBound, "RR_GTE_UPPER_RR");
    require(_basicConfig.performanceFee < HUNDRED_PCT, "PVP_FEE_GTE_HUNDRED_PCT");
    require(_basicConfig.performanceFeeReceiver != address(0), "INVALID_PVP_ADDR");
    require(_basicConfig.poolRestrictions != address(0), "INVALID_POOL_RESTRICTIONS_ADDR");

    piToken = WrappedPiErc20Interface(_piToken);
    (, bytes memory underlyingRes) = _piToken.call(abi.encodeWithSignature("underlying()"));
    underlying = IERC20(abi.decode(underlyingRes, (address)));
    poolRestrictions = IPoolRestrictions(_basicConfig.poolRestrictions);
    powerPoke = IPowerPoke(_basicConfig.powerPoke);
    reserveRatio = _basicConfig.reserveRatio;
    reserveRatioLowerBound = _basicConfig.reserveRatioLowerBound;
    reserveRatioUpperBound = _basicConfig.reserveRatioUpperBound;
    claimRewardsInterval = _basicConfig.claimRewardsInterval;
    performanceFeeReceiver = _basicConfig.performanceFeeReceiver;
    performanceFee = _basicConfig.performanceFee;
  }

  receive() external payable {}

  /*** OWNER METHODS ***/

  /**
   * @notice Set reserve ratio config
   * @param _reserveRatio Share of necessary token balance that piERC20 must hold after poke execution.
   * @param _reserveRatioLowerBound Lower bound of ERC20 token balance to force rebalance.
   * @param _reserveRatioUpperBound Upper bound of ERC20 token balance to force rebalance.
   * @param _claimRewardsInterval Time interval to claim rewards in connectors contracts.
   */
  function setReserveConfig(
    uint256 _reserveRatio,
    uint256 _reserveRatioLowerBound,
    uint256 _reserveRatioUpperBound,
    uint256 _claimRewardsInterval
  ) external virtual override onlyOwner {
    require(_reserveRatioUpperBound <= HUNDRED_PCT, "UPPER_RR_GREATER_THAN_100_PCT");
    require(_reserveRatio >= _reserveRatioLowerBound, "RR_LT_LOWER_RR");
    require(_reserveRatio <= _reserveRatioUpperBound, "RR_GT_UPPER_RR");

    reserveRatio = _reserveRatio;
    reserveRatioLowerBound = _reserveRatioLowerBound;
    reserveRatioUpperBound = _reserveRatioUpperBound;
    claimRewardsInterval = _claimRewardsInterval;
    emit SetReserveConfig(_reserveRatio, _reserveRatioLowerBound, _reserveRatioUpperBound, _claimRewardsInterval);
  }

  /**
   * @notice Set performance fee.
   * @param _performanceFee Share of rewards for distributing to performanceFeeReceiver(Protocol treasury).
   */
  function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
    require(_performanceFee < HUNDRED_PCT, "PERFORMANCE_FEE_OVER_THE_LIMIT");
    performanceFee = _performanceFee;
    emit SetPerformanceFee(_performanceFee);
  }

  /**
   * @notice Set piERC20 ETH fee for deposit and withdrawal functions.
   * @param _ethFee Fee amount in ETH.
   */
  function setPiTokenEthFee(uint256 _ethFee) external onlyOwner {
    require(_ethFee <= 0.1 ether, "ETH_FEE_OVER_THE_LIMIT");
    piToken.setEthFee(_ethFee);
  }

  /**
   * @notice Set connectors configs. Items should have `newConnector` variable to create connectors and `connectorIndex`
   * to update existing connectors.
   * @param _connectorList Array of connector items.
   */
  function setConnectorList(ConnectorInput[] memory _connectorList) external onlyOwner {
    require(_connectorList.length != 0, "CONNECTORS_LENGTH_CANT_BE_NULL");

    for (uint256 i = 0; i < _connectorList.length; i++) {
      ConnectorInput memory c = _connectorList[i];

      if (c.newConnector) {
        connectors.push(
          Connector(
            c.connector,
            c.share,
            c.callBeforeAfterPoke,
            0,
            0,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
          )
        );
        c.connectorIndex = connectors.length - 1;
      } else {
        connectors[c.connectorIndex].connector = c.connector;
        connectors[c.connectorIndex].share = c.share;
        connectors[c.connectorIndex].callBeforeAfterPoke = c.callBeforeAfterPoke;
      }

      emit SetConnector(c.connector, c.share, c.callBeforeAfterPoke, c.connectorIndex, c.newConnector);
    }
    _checkConnectorsTotalShare();
  }

  /**
   * @notice Set connectors claim params to pass it to connector.
   * @param _connectorIndex Index of connector
   * @param _claimParams Claim params
   */
  function setClaimParams(uint256 _connectorIndex, bytes memory _claimParams) external onlyOwner {
    connectors[_connectorIndex].claimParams = _claimParams;
    emit SetConnectorClaimParams(address(connectors[_connectorIndex].connector), _claimParams);
  }

  /**
   * @notice Set connector stake params to pass it to connector.
   * @param _connectorIndex Index of connector
   * @param _stakeParams Claim params
   */
  function setStakeParams(uint256 _connectorIndex, bytes memory _stakeParams) external onlyOwner {
    connectors[_connectorIndex].stakeParams = _stakeParams;
    emit SetConnectorStakeParams(address(connectors[_connectorIndex].connector), _stakeParams);
  }

  /**
   * @notice Set piERC20 noFee config for account address.
   * @param _for Account address.
   * @param _noFee Value for account.
   */
  function setPiTokenNoFee(address _for, bool _noFee) external onlyOwner {
    piToken.setNoFee(_for, _noFee);
  }

  /**
   * @notice Call piERC20 `withdrawEthFee`.
   * @param _receiver Receiver address.
   */
  function withdrawEthFee(address payable _receiver) external onlyOwner {
    piToken.withdrawEthFee(_receiver);
  }

  /**
   * @notice Transfer ERC20 balances and rights to a new router address.
   * @param _piToken piERC20 address.
   * @param _newRouter New router contract address.
   * @param _tokens ERC20 to transfer.
   */
  function migrateToNewRouter(
    address _piToken,
    address payable _newRouter,
    address[] memory _tokens
  ) public override onlyOwner {
    super.migrateToNewRouter(_piToken, _newRouter, _tokens);

    _newRouter.transfer(address(this).balance);

    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      IERC20 t = IERC20(_tokens[i]);
      t.safeTransfer(_newRouter, t.balanceOf(address(this)));
    }
  }

  /**
   * @notice Call initRouter function of the connector contract.
   * @param _connectorIndex Connector index in connectors array.
   * @param _data To pass as an argument.
   */
  function initRouterByConnector(uint256 _connectorIndex, bytes memory _data) public onlyOwner {
    (bool success, bytes memory result) = address(connectors[_connectorIndex].connector).delegatecall(
      abi.encodeWithSignature("initRouter(bytes)", _data)
    );
    require(success, string(result));
  }

  function piTokenCallback(address, uint256 _withdrawAmount) external payable virtual override {
    PokeFromState memory state = PokeFromState(0, 0, 0, _withdrawAmount, false, true);
    _rebalance(state, false, false);
  }

  /**
   * @notice Call poke by Reporter.
   * @param _reporterId Reporter ID.
   * @param _claimAndDistributeRewards Claim rewards only if interval reached.
   * @param _rewardOpts To whom and how to reward Reporter.
   */
  function pokeFromReporter(
    uint256 _reporterId,
    bool _claimAndDistributeRewards,
    bytes calldata _rewardOpts
  ) external onlyReporter(_reporterId, _rewardOpts) onlyEOA {
    _pokeFrom(_claimAndDistributeRewards, false);
  }

  /**
   * @notice Call poke by Slasher.
   * @param _reporterId Slasher ID.
   * @param _claimAndDistributeRewards Claim rewards only if interval reached.
   * @param _rewardOpts To whom and how reward Slasher.
   */
  function pokeFromSlasher(
    uint256 _reporterId,
    bool _claimAndDistributeRewards,
    bytes calldata _rewardOpts
  ) external onlyNonReporter(_reporterId, _rewardOpts) onlyEOA {
    _pokeFrom(_claimAndDistributeRewards, true);
  }

  /**
   * @notice Executes rebalance(beforePoke, rebalancePoke, claimRewards, afterPoke) for connector contract by config.
   * @param _conf Connector rebalance config.
   */
  function _rebalancePokeByConf(RebalanceConfig memory _conf) internal {
    Connector storage c = connectors[_conf.connectorIndex];

    if (c.callBeforeAfterPoke) {
      _beforePoke(c, _conf.shouldClaim);
    }

    if (_conf.status != StakeStatus.EQUILIBRIUM) {
      _rebalancePoke(c, _conf.status, _conf.diff);
    }

    // check claim interval again due to possibility of claiming by stake or redeem function(maybe already claimed)
    if (_conf.shouldClaim && claimRewardsIntervalReached(c.lastClaimRewardsAt)) {
      _claimRewards(c, _conf.status);
      c.lastClaimRewardsAt = block.timestamp;
    } else {
      require(_conf.status != StakeStatus.EQUILIBRIUM, "NOTHING_TO_DO");
    }

    if (c.callBeforeAfterPoke) {
      _afterPoke(c, _conf.status, _conf.shouldClaim);
    }
  }

  function claimRewardsIntervalReached(uint256 _lastClaimRewardsAt) public view returns (bool) {
    return _lastClaimRewardsAt + claimRewardsInterval < block.timestamp;
  }

  /**
   * @notice Rebalance every connector according to its share in an array.
   * @param _claimAndDistributeRewards Need to claim and distribute rewards.
   * @param _isSlasher Calling by Slasher.
   */
  function _pokeFrom(bool _claimAndDistributeRewards, bool _isSlasher) internal {
    PokeFromState memory state = PokeFromState(0, 0, 0, 0, false, false);
    (state.minInterval, state.maxInterval) = _getMinMaxReportInterval();

    _rebalance(state, _claimAndDistributeRewards, _isSlasher);

    require(
      _canPoke(_isSlasher, state.atLeastOneForceRebalance, state.minInterval, state.maxInterval),
      "INTERVAL_NOT_REACHED_OR_NOT_FORCE"
    );

    lastRebalancedByPokerAt = block.timestamp;
  }

  function _rebalance(
    PokeFromState memory s,
    bool _claimAndDistributeRewards,
    bool _isSlasher
  ) internal {
    if (connectors.length == 1 && reserveRatio == 0 && !_claimAndDistributeRewards) {
      if (s.addToExpectedAmount > 0) {
        _rebalancePoke(connectors[0], StakeStatus.EXCESS, s.addToExpectedAmount);
      } else {
        _rebalancePoke(connectors[0], StakeStatus.SHORTAGE, piToken.getUnderlyingBalance());
      }
      return;
    }

    s.piTokenUnderlyingBalance = piToken.getUnderlyingBalance();
    (uint256[] memory stakedBalanceList, uint256 totalStakedBalance) = _getUnderlyingStakedList();

    RebalanceConfig[] memory configs = new RebalanceConfig[](connectors.length);

    // First cycle: connectors with EXCESS balance status on staking
    for (uint256 i = 0; i < connectors.length; i++) {
      if (connectors[i].share == 0) {
        continue;
      }

      (StakeStatus status, uint256 diff, bool shouldClaim, bool forceRebalance) = getStakeAndClaimStatus(
        s.piTokenUnderlyingBalance,
        totalStakedBalance,
        stakedBalanceList[i],
        s.addToExpectedAmount,
        _claimAndDistributeRewards,
        connectors[i]
      );
      if (forceRebalance) {
        s.atLeastOneForceRebalance = true;
      }

      if (status == StakeStatus.EXCESS) {
        // Calling rebalance immediately if interval conditions reached
        if (s.skipCanPokeCheck || _canPoke(_isSlasher, forceRebalance, s.minInterval, s.maxInterval)) {
          _rebalancePokeByConf(RebalanceConfig(false, status, diff, shouldClaim, forceRebalance, i));
        }
      } else {
        // Push config for second cycle
        configs[i] = RebalanceConfig(true, status, diff, shouldClaim, forceRebalance, i);
      }
    }

    // Second cycle: connectors with EQUILIBRIUM and SHORTAGE balance status on staking
    for (uint256 i = 0; i < connectors.length; i++) {
      if (!configs[i].shouldPushFunds) {
        continue;
      }
      // Calling rebalance if interval conditions reached
      if (s.skipCanPokeCheck || _canPoke(_isSlasher, configs[i].forceRebalance, s.minInterval, s.maxInterval)) {
        _rebalancePokeByConf(configs[i]);
      }
    }
  }

  /**
   * @notice Checking: if time interval reached or have `forceRebalance`.
   */
  function _canPoke(
    bool _isSlasher,
    bool _forceRebalance,
    uint256 _minInterval,
    uint256 _maxInterval
  ) internal view returns (bool) {
    if (_forceRebalance) {
      return true;
    }
    return
      _isSlasher
        ? (lastRebalancedByPokerAt + _maxInterval < block.timestamp)
        : (lastRebalancedByPokerAt + _minInterval < block.timestamp);
  }

  /**
   * @notice Call redeem in the connector with delegatecall, save result stakeData if not null.
   */
  function _redeem(Connector storage _c, uint256 _diff) internal {
    _callStakeRedeem("redeem(uint256,(bytes,bytes,uint256,address))", _c, _diff);
  }

  /**
   * @notice Call stake in the connector with delegatecall, save result `stakeData` if not null.
   */
  function _stake(Connector storage _c, uint256 _diff) internal {
    _callStakeRedeem("stake(uint256,(bytes,bytes,uint256,address))", _c, _diff);
  }

  function _callStakeRedeem(
    string memory _method,
    Connector storage _c,
    uint256 _diff
  ) internal {
    (bool success, bytes memory result) = address(_c.connector).delegatecall(
      abi.encodeWithSignature(_method, _diff, _getDistributeData(_c))
    );
    require(success, string(result));
    bool claimed;
    (result, claimed) = abi.decode(result, (bytes, bool));
    if (result.length > 0) {
      _c.stakeData = result;
    }
    if (claimed) {
      _c.lastClaimRewardsAt = block.timestamp;
    }
    _c.lastChangeStakeAt = block.timestamp;
  }

  /**
   * @notice Call `beforePoke` in the connector with delegatecall, do not save `pokeData`.
   */
  function _beforePoke(Connector storage c, bool _willClaimReward) internal {
    (bool success, ) = address(c.connector).delegatecall(
      abi.encodeWithSignature(
        "beforePoke(bytes,(bytes,uint256,address),bool)",
        c.pokeData,
        _getDistributeData(c),
        _willClaimReward
      )
    );
    require(success, "_beforePoke call error");
  }

  /**
   * @notice Call `afterPoke` in the connector with delegatecall, save result `pokeData` if not null.
   */
  function _afterPoke(
    Connector storage _c,
    StakeStatus _stakeStatus,
    bool _rewardClaimDone
  ) internal {
    (bool success, bytes memory result) = address(_c.connector).delegatecall(
      abi.encodeWithSignature("afterPoke(uint8,bool)", uint8(_stakeStatus), _rewardClaimDone)
    );
    require(success, string(result));
    result = abi.decode(result, (bytes));
    if (result.length > 0) {
      _c.pokeData = result;
    }
  }

  /**
   * @notice Rebalance connector: stake if StakeStatus.SHORTAGE and redeem if StakeStatus.EXCESS.
   */
  function _rebalancePoke(
    Connector storage _c,
    StakeStatus _stakeStatus,
    uint256 _diff
  ) internal {
    if (_stakeStatus == StakeStatus.EXCESS) {
      _redeem(_c, _diff);
    } else if (_stakeStatus == StakeStatus.SHORTAGE) {
      _stake(_c, _diff);
    }
  }

  function redeem(uint256 _connectorIndex, uint256 _diff) external onlyOwner {
    _redeem(connectors[_connectorIndex], _diff);
  }

  function stake(uint256 _connectorIndex, uint256 _diff) external onlyOwner {
    _stake(connectors[_connectorIndex], _diff);
  }

  /**
   * @notice Explicitly collects the assigned rewards. If a reward token is the same as the underlying, it should
   * allocate it at piERC20. Otherwise, it should transfer to the router contract for further action.
   * @dev It's not the only way to claim rewards. Sometimes rewards are distributed implicitly while interacting
   * with a protocol. E.g., MasterChef distributes rewards on each `deposit()/withdraw()` action, and there is
   * no use in calling `_claimRewards()` immediately after calling one of these methods.
   */
  function _claimRewards(Connector storage c, StakeStatus _stakeStatus) internal {
    (bool success, bytes memory result) = address(c.connector).delegatecall(
      abi.encodeWithSelector(IRouterConnector.claimRewards.selector, _stakeStatus, _getDistributeData(c))
    );
    require(success, string(result));
    result = abi.decode(result, (bytes));
    if (result.length > 0) {
      c.stakeData = result;
    }
  }

  function _reward(
    uint256 _reporterId,
    uint256 _gasStart,
    uint256 _compensationPlan,
    bytes calldata _rewardOpts
  ) internal {
    powerPoke.reward(_reporterId, _gasStart.sub(gasleft()), _compensationPlan, _rewardOpts);
  }

  /*
   * @dev Getting status and diff of actual staked balance and target reserve balance.
   */
  function getStakeStatusForBalance(uint256 _stakedBalance, uint256 _share)
    external
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool forceRebalance
    )
  {
    return getStakeStatus(piToken.getUnderlyingBalance(), getUnderlyingStaked(), _stakedBalance, 0, _share);
  }

  function getStakeAndClaimStatus(
    uint256 _leftOnPiTokenBalance,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _addToExpectedAmount,
    bool _claimAndDistributeRewards,
    Connector memory _c
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool shouldClaim,
      bool forceRebalance
    )
  {
    (status, diff, forceRebalance) = getStakeStatus(
      _leftOnPiTokenBalance,
      _totalStakedBalance,
      _stakedBalance,
      _addToExpectedAmount,
      _c.share
    );
    shouldClaim = _claimAndDistributeRewards && claimRewardsIntervalReached(_c.lastClaimRewardsAt);

    if (shouldClaim && _c.claimParams.length != 0) {
      shouldClaim = _c.connector.isClaimAvailable(_c.claimParams, _c.lastClaimRewardsAt, _c.lastChangeStakeAt);
      if (shouldClaim && !forceRebalance) {
        forceRebalance = true;
      }
    }
  }

  /*
   * @dev Getting status and diff of current staked balance and target stake balance.
   */
  function getStakeStatus(
    uint256 _leftOnPiTokenBalance,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _addToExpectedAmount,
    uint256 _share
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      bool forceRebalance
    )
  {
    uint256 expectedStakeAmount;
    (status, diff, expectedStakeAmount) = getStakeStatusPure(
      reserveRatio,
      _leftOnPiTokenBalance,
      _totalStakedBalance,
      _stakedBalance,
      _share,
      _addToExpectedAmount
    );

    if (status == StakeStatus.EQUILIBRIUM) {
      return (status, diff, forceRebalance);
    }

    uint256 denominator = _leftOnPiTokenBalance.add(_totalStakedBalance);

    if (status == StakeStatus.EXCESS) {
      uint256 numerator = _leftOnPiTokenBalance.add(diff).mul(HUNDRED_PCT);
      uint256 currentRatio = numerator.div(denominator);
      forceRebalance = reserveRatioLowerBound >= currentRatio;
    } else if (status == StakeStatus.SHORTAGE) {
      if (diff > _leftOnPiTokenBalance) {
        return (status, diff, true);
      }
      uint256 numerator = _leftOnPiTokenBalance.sub(diff).mul(HUNDRED_PCT);
      uint256 currentRatio = numerator.div(denominator);
      forceRebalance = reserveRatioUpperBound <= currentRatio;
    }
  }

  function getUnderlyingStaked() public view virtual returns (uint256) {
    uint256 underlyingStaked = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      underlyingStaked += connectors[i].connector.getUnderlyingStaked();
    }
    return underlyingStaked;
  }

  function _getUnderlyingStakedList() internal view virtual returns (uint256[] memory list, uint256 total) {
    uint256[] memory underlyingStakedList = new uint256[](connectors.length);
    total = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      underlyingStakedList[i] = connectors[i].connector.getUnderlyingStaked();
      total += underlyingStakedList[i];
    }
    return (underlyingStakedList, total);
  }

  function getUnderlyingReserve() public view returns (uint256) {
    return underlying.balanceOf(address(piToken));
  }

  function calculateLockedProfit() public view returns (uint256) {
    uint256 lockedProfit = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      lockedProfit += connectors[i].connector.calculateLockedProfit(connectors[i].stakeData);
    }
    return lockedProfit;
  }

  function getUnderlyingAvailable() public view returns (uint256) {
    // _getUnderlyingReserve + getUnderlyingStaked - _calculateLockedProfit
    return getUnderlyingReserve().add(getUnderlyingStaked()).sub(calculateLockedProfit());
  }

  function getUnderlyingTotal() external view returns (uint256) {
    // _getUnderlyingReserve + getUnderlyingStaked
    return getUnderlyingReserve().add(getUnderlyingStaked());
  }

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount, uint256 _piTotalSupply)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return getPiEquivalentForUnderlyingPure(_underlyingAmount, getUnderlyingAvailable(), _piTotalSupply);
  }

  function getPiEquivalentForUnderlyingPure(
    uint256 _underlyingAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) public pure virtual override returns (uint256) {
    if (_piTotalSupply == 0) {
      return _underlyingAmount;
    }
    // return _piTotalSupply * _underlyingAmount / _totalUnderlyingWrapped;
    return _piTotalSupply.mul(_underlyingAmount).div(_totalUnderlyingWrapped);
  }

  function getUnderlyingEquivalentForPi(uint256 _piAmount, uint256 _piTotalSupply)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return getUnderlyingEquivalentForPiPure(_piAmount, getUnderlyingAvailable(), _piTotalSupply);
  }

  function getUnderlyingEquivalentForPiPure(
    uint256 _piAmount,
    uint256 _totalUnderlyingWrapped,
    uint256 _piTotalSupply
  ) public pure virtual override returns (uint256) {
    if (_piTotalSupply == 0) {
      return _piAmount;
    }
    // _piAmount * _totalUnderlyingWrapped / _piTotalSupply;
    return _totalUnderlyingWrapped.mul(_piAmount).div(_piTotalSupply);
  }

  /**
   * @notice Calculates the desired stake status.
   * @param _reserveRatioPct The reserve ratio in %, 1 ether == 100 ether.
   * @param _leftOnPiToken The underlying ERC20 tokens balance on the piERC20 contract.
   * @param _totalStakedBalance The underlying ERC20 tokens balance staked on the all connected staking contracts.
   * @param _stakedBalance The underlying ERC20 tokens balance staked on the connector staking contract.
   * @param _share Share of the connector contract.
   * @return status The stake status:
   * * SHORTAGE: There is not enough underlying ERC20 balance on the staking contract to satisfy the reserve ratio.
   *             Therefore, the connector contract should send the diff amount to the staking contract.
   * * EXCESS: There is some extra underlying ERC20 balance on the staking contract.
   *           Therefore, the connector contract should redeem the diff amount from the staking contract.
   * * EQUILIBRIUM: The reserve ratio hasn't changed, the diff amount is 0, and no need for additional
   *                stake/redeem actions.
   * @return diff The difference between `expectedStakeAmount` and `_stakedBalance`.
   * @return expectedStakeAmount The calculated expected underlying ERC20 staked balance.
   */
  function getStakeStatusPure(
    uint256 _reserveRatioPct,
    uint256 _leftOnPiToken,
    uint256 _totalStakedBalance,
    uint256 _stakedBalance,
    uint256 _share,
    uint256 _addToExpectedStakeAmount
  )
    public
    view
    returns (
      StakeStatus status,
      uint256 diff,
      uint256 expectedStakeAmount
    )
  {
    require(_reserveRatioPct <= HUNDRED_PCT, "RR_GREATER_THAN_100_PCT");
    expectedStakeAmount = getExpectedStakeAmount(_reserveRatioPct, _leftOnPiToken, _totalStakedBalance, _share);
    expectedStakeAmount = expectedStakeAmount.add(_addToExpectedStakeAmount.mul(_share).div(1 ether));

    if (expectedStakeAmount > _stakedBalance) {
      status = StakeStatus.SHORTAGE;
      diff = expectedStakeAmount.sub(_stakedBalance);
    } else if (expectedStakeAmount < _stakedBalance) {
      status = StakeStatus.EXCESS;
      diff = _stakedBalance.sub(expectedStakeAmount);
    } else {
      status = StakeStatus.EQUILIBRIUM;
      diff = 0;
    }
  }

  /**
   * @notice Calculates an expected underlying ERC20 staked balance.
   * @param _reserveRatioPct % of a reserve ratio, 1 ether == 100%.
   * @param _leftOnPiToken The underlying ERC20 tokens balance on the piERC20 contract.
   * @param _stakedBalance The underlying ERC20 tokens balance staked on the staking contract.
   * @param _share % of a total connectors share, 1 ether == 100%.
   * @return expectedStakeAmount The expected stake amount:
   *
   *                           / (100% - %reserveRatio) * (_leftOnPiToken + _stakedBalance) * %share \
   *    expectedStakeAmount = | ----------------------------------------------------------------------|
   *                           \                                    100%                             /
   */
  function getExpectedStakeAmount(
    uint256 _reserveRatioPct,
    uint256 _leftOnPiToken,
    uint256 _stakedBalance,
    uint256 _share
  ) public pure returns (uint256) {
    return
      uint256(1 ether).sub(_reserveRatioPct).mul(_stakedBalance.add(_leftOnPiToken).mul(_share).div(HUNDRED_PCT)).div(
        HUNDRED_PCT
      );
  }

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    return powerPoke.getMinMaxReportIntervals(address(this));
  }

  function _getDistributeData(Connector storage c) internal view returns (IRouterConnector.DistributeData memory) {
    return IRouterConnector.DistributeData(c.stakeData, c.stakeParams, performanceFee, performanceFeeReceiver);
  }

  function _checkConnectorsTotalShare() internal view {
    uint256 totalShare = 0;
    for (uint256 i = 0; i < connectors.length; i++) {
      require(address(connectors[i].connector) != address(0), "CONNECTOR_IS_NULL");
      totalShare = totalShare.add(connectors[i].share);
    }
    require(totalShare == HUNDRED_PCT, "TOTAL_SHARE_IS_NOT_HUNDRED_PCT");
  }
}