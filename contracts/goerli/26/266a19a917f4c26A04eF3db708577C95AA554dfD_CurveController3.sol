// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/curve/IStableSwapPool.sol";
import "../interfaces/curve/IRegistry.sol";
import "../interfaces/curve/IAddressProvider.sol";
import "./BaseController.sol";

contract CurveController3 is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IAddressProvider public immutable addressProvider;

    uint256 public constant N_COINS = 3;

    constructor(
        address manager,
        address addressRegistry,
        address curveAddressProvider
    ) public BaseController(manager, addressRegistry) {
        require(curveAddressProvider != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
        addressProvider = IAddressProvider(curveAddressProvider);
    }

    /// @notice Deploy liquidity to Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress Token addresses
    /// @param amounts List of amounts of coins to deposit
    /// @param poolAddress Minimum amount of LP tokens to mint from the deposit
    function deploy(
        address poolAddress,
        uint256[N_COINS] memory amounts,
        uint256 minMintAmount
    ) external onlyManager {
        address lpTokenAddress = _getLPToken(poolAddress);

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                address coin = IStableSwapPool(poolAddress).coins(i);
                
                require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

                uint256 balance = IERC20(coin).balanceOf(address(this));

                require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

                _approve(IERC20(coin), poolAddress, amounts[i]);
            }
        }

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256 lpTokenReceived = IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceBefore + lpTokenReceived == lpTokenBalanceAfter, "LP_TOKEN_MISMATCH");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress Token addresses
    /// @param amounts List of amounts of underlying coins to withdraw
    /// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
    function withdrawImbalance(
        address poolAddress,
        uint256[N_COINS] memory amounts,
        uint256 maxBurnAmount
    ) external onlyManager {
        address lpTokenAddress = _getLPTokenAndApprove(poolAddress, maxBurnAmount);

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

        uint256 lpTokenBurnt = IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore - lpTokenBurnt == lpTokenBalanceAfter, "LP_TOKEN_MISMATCH");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress Token addresses
    /// @param amount Quantity of LP tokens to burn in the withdrawal
    /// @param minAmounts Minimum amounts of underlying coins to receive
    function withdraw(
        address poolAddress,
        uint256 amount,
        uint256[N_COINS] memory minAmounts
    ) external onlyManager {
        address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

        IStableSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

        require(lpTokenBalanceBefore - amount == lpTokenBalanceAfter, "LP_TOKEN_MISMATCH");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param poolAddress token addresses
    /// @param tokenAmount Amount of LP tokens to burn in the withdrawal
    /// @param i Index value of the coin to withdraw
    /// @param minAmount Minimum amount of coin to receive
    function withdrawOneCoin(
        address poolAddress,
        uint256 tokenAmount,
        int128 i,
        uint256 minAmount
    ) external onlyManager {
        address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
        address coin = IStableSwapPool(poolAddress).coins(uint256(i));
        
        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

        IStableSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

        require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
        require(lpTokenBalanceBefore - tokenAmount == lpTokenBalanceAfter, "LP_TOKEN_MISMATCH");
    }

    function _getLPToken(address poolAddress) internal returns (address) {
        require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

        address registryAddress = addressProvider.get_registry();
        address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

        // If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
        // https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
        if (lpTokenAddress == address(0)) {
            lpTokenAddress = poolAddress;
        }

        require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

        return lpTokenAddress;
    }

    function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = IStableSwapPool(poolAddress).coins(i);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(uint256[N_COINS] memory balancesBefore, uint256[N_COINS] memory balancesAfter, uint256[N_COINS] memory amounts) internal {
        for (uint256 i = 0; i < N_COINS; i++) {
            if (amounts[i] > 0) {
                require(balancesBefore[i] < balancesAfter[i], "BALANCE_MUST_INCREASE");
            }
        }
    }

    function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
        address lpTokenAddress = _getLPToken(poolAddress);
        if (lpTokenAddress != poolAddress) {
            _approve(IERC20(lpTokenAddress), poolAddress, amount);
        }
        return lpTokenAddress;
    }

    function _approve(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(spender, currentAllowance);
        }
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IStableSwapPool {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[4] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts)
        external
        returns (uint256[3] memory);

    function remove_liquidity(uint256 amount, uint256[4] memory min_amounts)
        external
        returns (uint256[4] memory);

    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount)
        external
        returns (uint256);

    function coins(uint256 i) external returns (address);

    function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IRegistry {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    function get_lp_token(address pool) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IAddressProvider {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    function get_registry() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;

import "../interfaces/IAddressRegistry.sol";

contract BaseController {

    address public immutable manager;
    IAddressRegistry public immutable addressRegistry;

    constructor(address _manager, address _addressRegistry) public {
        require(_manager != address(0), "INVALID_ADDRESS");
        require(_addressRegistry != address(0), "INVALID_ADDRESS");

        manager = _manager;
        addressRegistry = IAddressRegistry(_addressRegistry);
    }

    modifier onlyManager() {
        require(address(this) == manager, "NOT_MANAGER_ADDRESS");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

/**
 *   @title Track addresses to be used in liquidity deployment
 *   Any controller used, asset deployed, or pool tracked within the
 *   system should be registered here
 */
interface IAddressRegistry {
    enum AddressTypes {
        Token,
        Controller,
        Pool
    }

    event RegisteredAddressAdded(address added);
    event RegisteredAddressRemoved(address removed);
    event AddedToRegistry(address[] addresses, AddressTypes);
    event RemovedFromRegistry(address[] addresses, AddressTypes);

    /// @notice Allows address with REGISTERED_ROLE to add a registered address
    /// @param _addr address to be added
    function addRegistrar(address _addr) external;

    /// @notice Allows address with REGISTERED_ROLE to remove a registered address
    /// @param _addr address to be removed
    function removeRegistrar(address _addr) external;

    /// @notice Allows array of addresses to be added to registry for certain index
    /// @param _addresses calldata array of addresses to be added to registry
    /// @param _index AddressTypes enum of index to add addresses to
    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external;

    /// @notice Allows array of addresses to be removed from registry for certain index
    /// @param _addresses calldata array of addresses to be removed from registry
    /// @param _index AddressTypes enum of index to remove addresses from
    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external;

    /// @notice Allows array of all addresses for certain index to be returned
    /// @param _index AddressTypes enum of index to be returned
    /// @return address[] memory of addresses from index
    function getAddressForType(AddressTypes _index) external view returns (address[] memory);

    /// @notice Allows checking that one address exists in certain index
    /// @param _addr address to be checked
    /// @param _index AddressTypes index to check address against
    /// @return bool tells whether address exists or not
    function checkAddress(address _addr, uint256 _index) external view returns (bool);
}