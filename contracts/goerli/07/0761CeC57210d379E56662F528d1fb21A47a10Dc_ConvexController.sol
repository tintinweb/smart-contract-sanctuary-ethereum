// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IBalancerPool.sol";
import "./BaseController.sol";

contract BalancerController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address manager, address _addressRegistry) public BaseController(manager, _addressRegistry) {}

    /// @notice Used to deploy liquidity to a Balancer pool
    /// @dev Calls into external contract
    /// @param poolAddress Address of pool to have liquidity added
    /// @param tokens Array of ERC20 tokens to be added to pool
    /// @param amounts Corresponding array of amounts of tokens to be added to a pool
    /// @param data Bytes data passed from manager containing information to be passed to the balancer pool
    function deploy(
        address poolAddress,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyManager {
        require(tokens.length == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
        require(tokens.length > 0, "TOKENS_AMOUNTS_NOT_PROVIDED");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
            _approve(tokens[i], poolAddress, amounts[i]);
        }

        IBalancerPool pool = IBalancerPool(poolAddress);
        uint256 balanceBefore = pool.balanceOf(address(this));

        //Notes:
        // - If your pool is eligible for weekly BAL rewards, they will be distributed to your LPs automatically
        // - If you contribute significant long-term liquidity to the platform, you can apply to have smart contract deployment gas costs reimbursed from the Balancer Ecosystem fund
        // - The pool is the LP token, All pools in Balancer are also ERC20 tokens known as BPTs \(Balancer Pool Tokens\)
        (uint256 poolAmountOut, uint256[] memory maxAmountsIn) = abi.decode(
            data,
            (uint256, uint256[])
        );
        pool.joinPool(poolAmountOut, maxAmountsIn);
        
        uint256 balanceAfter = pool.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");
    }

    /// @notice Used to withdraw liquidity from balancer pools
    /// @dev Calls into external contract
    /// @param poolAddress Address of pool to have liquidity withdrawn
    /// @param data Data to be decoded and passed to pool
    function withdraw(address poolAddress, bytes calldata data) external onlyManager {
        (uint256 poolAmountIn, uint256[] memory minAmountsOut) = abi.decode(
            data,
            (uint256, uint256[])
        );

        IBalancerPool pool = IBalancerPool(poolAddress);
        address[] memory tokens = pool.getFinalTokens();
        uint256[] memory balancesBefore = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balancesBefore[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        _approve(IERC20(poolAddress), poolAddress, poolAmountIn);
        pool.exitPool(poolAmountIn, minAmountsOut);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(address(this));
            require(balanceAfter > balancesBefore[i], "MUST_INCREASE");
        }
    }

    function _approve(
        IERC20 token,
        address poolAddress,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), poolAddress);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(poolAddress, currentAllowance);
        }
        token.safeIncreaseAllowance(poolAddress, amount);
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

pragma solidity 0.6.11;

/// @title Interface for a Balancer Labs BPool
/// @dev https://docs.balancer.fi/v/v1/smart-contracts/interfaces
interface IBalancerPool {
    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function getBalance(address token) external view returns (uint256);

    function decimals() external view returns (uint8);

    function isFinalized() external view returns (bool);

    function getFinalTokens() external view returns (address[] memory tokens);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWallet.sol";
import "./BaseController.sol";

contract ZeroExController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line
    IWallet public immutable WALLET;

    constructor(IWallet wallet, address manager, address _addressRegistry) public BaseController(manager, _addressRegistry) {
        require(address(wallet) != address(0), "INVALID_WALLET");
        WALLET = wallet;
    }

    /// @notice Deposits tokens into WALLET
    /// @dev Call to external contract via _approve functions
    /// @param data Bytes containing an array of token addresses and token accounts
    function deploy(bytes calldata data) external onlyManager {
        (address[] memory tokens, uint256[] memory amounts) = abi.decode(
            data,
            (address[], uint256[])
        );
        uint256 tokensLength = tokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            require(addressRegistry.checkAddress(tokens[i], 0), "INVALID_TOKEN");
            _approve(IERC20(tokens[i]), amounts[i]);
        }
        WALLET.deposit(tokens, amounts);
    }

    /// @notice Withdraws tokens from WALLET
    /// @param data Bytes containing address and uint256 array
    function withdraw(bytes calldata data) external onlyManager {
        (address[] memory tokens, uint256[] memory amounts) = abi.decode(
            data,
            (address[], uint256[])
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            require(addressRegistry.checkAddress(tokens[i], 0), "INVALID_TOKEN");
        }
        WALLET.withdraw(tokens, amounts);
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(WALLET));
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(address(WALLET), currentAllowance);
        }
        token.safeIncreaseAllowance(address(WALLET), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 *  @title 0x trade wallet used to hold funds and fullfil orders submitted by Pricers
 */
interface IWallet {
    /// @notice Register with 0x an address that is allowed to sign on behalf of this contract
    /// @param signer EOA that is signing RFQ orders
    function registerAllowedOrderSigner(address signer, bool allowed) external;

    /// @notice Add the supplied amounts to the wallet to fullfill order with
    function deposit(address[] calldata tokens, uint256[] calldata amounts) external;

    /// @notice Withdraw assets from the wallet
    function withdraw(address[] calldata tokens, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IManager.sol";
import "../interfaces/ILiquidityPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/IEventSender.sol";

//solhint-disable not-rely-on-time 
//solhint-disable var-name-mixedcase
contract Manager is IManager, Initializable, AccessControl, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public immutable ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public immutable ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
    bytes32 public immutable MID_CYCLE_ROLE = keccak256("MID_CYCLE_ROLE");
    bytes32 public immutable START_ROLLOVER_ROLE = keccak256("START_ROLLOVER_ROLE");

    uint256 public currentCycle; // Start timestamp of current cycle
    uint256 public currentCycleIndex; // Uint representing current cycle
    uint256 public cycleDuration; // Cycle duration in seconds

    bool public rolloverStarted;

    // Bytes32 controller id => controller address
    mapping(bytes32 => address) public registeredControllers;
    // Cycle index => ipfs rewards hash
    mapping(uint256 => string) public override cycleRewardsHashes;
    EnumerableSet.AddressSet private pools;
    EnumerableSet.Bytes32Set private controllerIds;

    // Reentrancy Guard
    bool private _entered;

    bool public _eventSend;
    Destinations public destinations;

    uint256 public nextCycleStartTime;

    bool private isLogicContract;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyRollover() {
        require(hasRole(ROLLOVER_ROLE, _msgSender()), "NOT_ROLLOVER_ROLE");
        _;
    }

    modifier onlyMidCycle() {
        require(hasRole(MID_CYCLE_ROLE, _msgSender()), "NOT_MID_CYCLE_ROLE");
        _;
    }

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier onlyStartRollover() {
        require(hasRole(START_ROLLOVER_ROLE, _msgSender()), "NOT_START_ROLLOVER_ROLE");
        _;
    }

    constructor() public {
        isLogicContract = true;
    }

    function initialize(uint256 _cycleDuration, uint256 _nextCycleStartTime) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        cycleDuration = _cycleDuration;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ROLLOVER_ROLE, _msgSender());
        _setupRole(MID_CYCLE_ROLE, _msgSender());
        _setupRole(START_ROLLOVER_ROLE, _msgSender());

        setNextCycleStartTime(_nextCycleStartTime);
    }

    function registerController(bytes32 id, address controller) external override onlyAdmin {
        registeredControllers[id] = controller;
        require(controllerIds.add(id), "ADD_FAIL");
        emit ControllerRegistered(id, controller);
    }

    function unRegisterController(bytes32 id) external override onlyAdmin {
        emit ControllerUnregistered(id, registeredControllers[id]);
        delete registeredControllers[id];
        require(controllerIds.remove(id), "REMOVE_FAIL");
    }

    function registerPool(address pool) external override onlyAdmin {
        require(pools.add(pool), "ADD_FAIL");
        emit PoolRegistered(pool);
    }

    function unRegisterPool(address pool) external override onlyAdmin {
        require(pools.remove(pool), "REMOVE_FAIL");
        emit PoolUnregistered(pool);
    }

    function setCycleDuration(uint256 duration) external override onlyAdmin {
        require(duration > 60, "CYCLE_TOO_SHORT");
        cycleDuration = duration;
        emit CycleDurationSet(duration);
    }

    function setNextCycleStartTime(uint256 _nextCycleStartTime) public override onlyAdmin {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(_nextCycleStartTime > block.timestamp, "MUST_BE_FUTURE");
        nextCycleStartTime = _nextCycleStartTime;
        emit NextCycleStartSet(_nextCycleStartTime);
    }

    function getPools() external view override returns (address[] memory) {
        uint256 poolsLength = pools.length();
        address[] memory returnData = new address[](poolsLength);
        for (uint256 i = 0; i < poolsLength; i++) {
            returnData[i] = pools.at(i);
        }
        return returnData;
    }

    function getControllers() external view override returns (bytes32[] memory) {
        uint256 controllerIdsLength = controllerIds.length();
        bytes32[] memory returnData = new bytes32[](controllerIdsLength);
        for (uint256 i = 0; i < controllerIdsLength; i++) {
            returnData[i] = controllerIds.at(i);
        }
        return returnData;
    }

    function completeRollover(string calldata rewardsIpfsHash) external override onlyRollover {
        // Can't be hit via test cases, going to leave in anyways in case we ever change code
        require(nextCycleStartTime > 0, "SET_BEFORE_ROLLOVER");
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
        _completeRollover(rewardsIpfsHash);
    }

    /// @notice Used for mid-cycle adjustments
    function executeMaintenance(MaintenanceExecution calldata params)
        external
        override
        onlyMidCycle
        nonReentrant
    {
        for (uint256 x = 0; x < params.cycleSteps.length; x++) {
            _executeControllerCommand(params.cycleSteps[x]);
        }
    }

    function executeRollover(RolloverExecution calldata params) external override onlyRollover nonReentrant {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");

        // Transfer deployable liquidity out of the pools and into the manager
        for (uint256 i = 0; i < params.poolData.length; i++) {
            require(pools.contains(params.poolData[i].pool), "INVALID_POOL");
            ILiquidityPool pool = ILiquidityPool(params.poolData[i].pool);
            IERC20 underlyingToken = pool.underlyer();
            underlyingToken.safeTransferFrom(
                address(pool),
                address(this),
                params.poolData[i].amount
            );
            emit LiquidityMovedToManager(params.poolData[i].pool, params.poolData[i].amount);
        }

        // Deploy or withdraw liquidity
        for (uint256 x = 0; x < params.cycleSteps.length; x++) {
            _executeControllerCommand(params.cycleSteps[x]);
        }

        // Transfer recovered liquidity back into the pools; leave no funds in the manager
        for (uint256 y = 0; y < params.poolsForWithdraw.length; y++) {
            require(pools.contains(params.poolsForWithdraw[y]), "INVALID_POOL");
            ILiquidityPool pool = ILiquidityPool(params.poolsForWithdraw[y]);
            IERC20 underlyingToken = pool.underlyer();

            uint256 managerBalance = underlyingToken.balanceOf(address(this));

            // transfer funds back to the pool if there are funds
            if (managerBalance > 0) {
                underlyingToken.safeTransfer(address(pool), managerBalance);
            }
            emit LiquidityMovedToPool(params.poolsForWithdraw[y], managerBalance);
        }

        if (params.complete) {
            _completeRollover(params.rewardsIpfsHash);
        }
    }

    function sweep(address[] calldata poolAddresses) external override onlyRollover {

        uint256 length = poolAddresses.length;
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address currentPoolAddress = poolAddresses[i];
            require(pools.contains(currentPoolAddress), "INVALID_ADDRESS");
            IERC20 underlyer = IERC20(ILiquidityPool(currentPoolAddress).underlyer());
            uint256 amount = underlyer.balanceOf(address(this));
            amounts[i] = amount;
            
            if (amount > 0) {
                underlyer.safeTransfer(currentPoolAddress, amount);
            }
        }
        emit ManagerSwept(poolAddresses, amounts);
    }

    function _executeControllerCommand(ControllerTransferData calldata transfer) private {
        require(!isLogicContract, "FORBIDDEN_CALL");

        address controllerAddress = registeredControllers[transfer.controllerId];
        require(controllerAddress != address(0), "INVALID_CONTROLLER");
        controllerAddress.functionDelegateCall(transfer.data, "CYCLE_STEP_EXECUTE_FAILED");
        emit DeploymentStepExecuted(transfer.controllerId, controllerAddress, transfer.data);
    }

    function startCycleRollover() external override onlyStartRollover {
        // We are aware of the possibility of timestamp manipulation.  It does not pose any
        // risk based on the design of our system
        require(block.timestamp > nextCycleStartTime, "PREMATURE_EXECUTION");
        rolloverStarted = true;
        emit CycleRolloverStarted(block.timestamp);
    }

    function _completeRollover(string calldata rewardsIpfsHash) private {
        currentCycle = nextCycleStartTime;
        nextCycleStartTime = nextCycleStartTime.add(cycleDuration);
        cycleRewardsHashes[currentCycleIndex] = rewardsIpfsHash;
        currentCycleIndex = currentCycleIndex.add(1);
        rolloverStarted = false;

        bytes32 eventSig = "Cycle Complete";
        encodeAndSendData(eventSig);

        emit CycleRolloverComplete(block.timestamp);
    }

    function getCurrentCycle() external view override returns (uint256) {
        return currentCycle;
    }

    function getCycleDuration() external view override returns (uint256) {
        return cycleDuration;
    }

    function getCurrentCycleIndex() external view override returns (uint256) {
        return currentCycleIndex;
    }

    function getRolloverStatus() external view override returns (bool) {
        return rolloverStarted;
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyAdmin {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyAdmin {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function setupRole(bytes32 role) external override onlyAdmin {
        _setupRole(role, _msgSender());
    }

    function encodeAndSendData(bytes32 _eventSig) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        bytes memory data = abi.encode(CycleRolloverEvent({
            eventSig: _eventSig,
            cycleIndex: currentCycleIndex,
            timestamp: currentCycle
        }));

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
    // bytes can take on the form of deploying or recovering liquidity
    struct ControllerTransferData {
        bytes32 controllerId; // controller to target
        bytes data; // data the controller will pass
    }

    struct PoolTransferData {
        address pool; // pool to target
        uint256 amount; // amount to transfer
    }

    struct MaintenanceExecution {
        ControllerTransferData[] cycleSteps;
    }

    struct RolloverExecution {
        PoolTransferData[] poolData;
        ControllerTransferData[] cycleSteps;
        address[] poolsForWithdraw; //Pools to target for manager -> pool transfer
        bool complete; //Whether to mark the rollover complete
        string rewardsIpfsHash;
    }

    event ControllerRegistered(bytes32 id, address controller);
    event ControllerUnregistered(bytes32 id, address controller);
    event PoolRegistered(address pool);
    event PoolUnregistered(address pool);
    event CycleDurationSet(uint256 duration);
    event LiquidityMovedToManager(address pool, uint256 amount);
    event DeploymentStepExecuted(bytes32 controller, address adapaterAddress, bytes data);
    event LiquidityMovedToPool(address pool, uint256 amount);
    event CycleRolloverStarted(uint256 timestamp);
    event CycleRolloverComplete(uint256 timestamp);
    event NextCycleStartSet(uint256 nextCycleStartTime);
    event ManagerSwept(address[] addresses, uint256[] amounts);

    /// @notice Registers controller
    /// @param id Bytes32 id of controller
    /// @param controller Address of controller
    function registerController(bytes32 id, address controller) external;

    /// @notice Registers pool
    /// @param pool Address of pool
    function registerPool(address pool) external;

    /// @notice Unregisters controller
    /// @param id Bytes32 controller id
    function unRegisterController(bytes32 id) external;

    /// @notice Unregisters pool
    /// @param pool Address of pool
    function unRegisterPool(address pool) external;

    ///@notice Gets addresses of all pools registered
    ///@return Memory array of pool addresses
    function getPools() external view returns (address[] memory);

    ///@notice Gets ids of all controllers registered
    ///@return Memory array of Bytes32 controller ids
    function getControllers() external view returns (bytes32[] memory);

    ///@notice Allows for owner to set cycle duration
    ///@param duration Block durtation of cycle
    function setCycleDuration(uint256 duration) external;

    ///@notice Starts cycle rollover
    ///@dev Sets rolloverStarted state boolean to true
    function startCycleRollover() external;

    ///@notice Allows for controller commands to be executed midcycle
    ///@param params Contains data for controllers and params
    function executeMaintenance(MaintenanceExecution calldata params) external;

    ///@notice Allows for withdrawals and deposits for pools along with liq deployment
    ///@param params Contains various data for executing against pools and controllers
    function executeRollover(RolloverExecution calldata params) external;

    ///@notice Completes cycle rollover, publishes rewards hash to ipfs
    ///@param rewardsIpfsHash rewards hash uploaded to ipfs
    function completeRollover(string calldata rewardsIpfsHash) external;

    ///@notice Gets reward hash by cycle index
    ///@param index Cycle index to retrieve rewards hash
    ///@return String memory hash
    function cycleRewardsHashes(uint256 index) external view returns (string memory);

    ///@notice Gets current starting block
    ///@return uint256 with block number
    function getCurrentCycle() external view returns (uint256);

    ///@notice Gets current cycle index
    ///@return uint256 current cycle number
    function getCurrentCycleIndex() external view returns (uint256);

    ///@notice Gets current cycle duration
    ///@return uint256 in block of cycle duration
    function getCycleDuration() external view returns (uint256);

    ///@notice Gets cycle rollover status, true for rolling false for not
    ///@return Bool representing whether cycle is rolling over or not
    function getRolloverStatus() external view returns (bool);

    /// @notice Sets next cycle start time manually
    /// @param nextCycleStartTime uint256 that represents start of next cycle
    function setNextCycleStartTime(uint256 nextCycleStartTime) external;

    /// @notice Sweeps amanager contract for any leftover funds
    /// @param addresses array of addresses of pools to sweep funds into
    function sweep(address[] calldata addresses) external;

    /// @notice Setup a role using internal function _setupRole
    /// @param role keccak256 of the role keccak256("MY_ROLE");
    function setupRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit ERC-20 tokens to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityPool {
    struct WithdrawalInfo {
        uint256 minCycle;
        uint256 amount;
    }

    event WithdrawalRequested(address requestor, uint256 amount);
    event DepositsPaused();
    event DepositsUnpaused();

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function deposit(uint256 amount) external;

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function depositFor(address account, uint256 amount) external;

    /// @notice Requests that the manager prepare funds for withdrawal next cycle
    /// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
    /// @param amount Amount of fTokens requested to be redeemed
    function requestWithdrawal(uint256 amount) external;

    function approveManager(uint256 amount) external;

    /// @notice Sender must first invoke requestWithdrawal in a previous cycle
    /// @notice This function will burn the fAsset and transfers underlying asset back to sender
    /// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
    /// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
    function withdraw(uint256 amount) external;

    /// @return Reference to the underlying ERC-20 contract
    function underlyer() external view returns (ERC20Upgradeable);

    /// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
    function withheldLiquidity() external view returns (uint256);

    /// @notice Get withdraw requests for an account
    /// @param account User account to check
    /// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
    function requestedWithdrawals(address account) external view returns (uint256, uint256);

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    // @notice Pause deposits only on the pool.
    function pauseDeposit() external;

    // @notice Unpause deposits only on the pool.
    function unpauseDeposit() external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../../fxPortal/IFxStateSender.sol";

/// @notice Configuration entity for sending events to Governance layer
struct Destinations {
    IFxStateSender fxStateSender;
    address destinationOnL2;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a cycle rollover is complete
struct CycleRolloverEvent {
    bytes32 eventSig;
    uint256 cycleIndex;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";

interface IEventSender {
    event DestinationsSet(address fxStateSender, address destinationOnL2);
    event EventSendSet(bool eventSendSet);

    /// @notice Configure the Polygon state sender root and destination for messages sent
    /// @param fxStateSender Address of Polygon State Sender Root contract
    /// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
    function setDestinations(address fxStateSender, address destinationOnL2) external;

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
pragma solidity >=0.6.0;

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../fxPortal/IFxStateSender.sol";
import "../interfaces/events/IEventSender.sol";

/**
 * @title Specialized implementation of the Pool contract that allows the
 * same rules as Staking when it comes to withdrawal requests. That is,
 * voting balances are updated on request instead of completion of withdrawal
 *
 */
contract TokeVotePool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer; // Underlying ERC20 token
    IManager public manager;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;
    bool public _eventSend;
    Destinations public destinations;

    bool public depositsPaused;

    event BalanceEventUpdated(address[] addresses);

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier whenDepositsNotPaused() {
        require(!paused(), "Pausable: paused");
        require(!depositsPaused, "DEPOSITS_PAUSED");
        _;
    }

    function initialize(
        ERC20 _underlyer,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_underlyer) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        underlyer = _underlyer;
        manager = _manager;
    }

    ///@notice Gets decimals of underlyer so that tAsset decimals will match
    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function deposit(uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        // Checks for manager cycle and if user is allowed to withdraw based on their minimum withdrawal cycle
        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // If full amount withdrawn delete from mapping
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);
        underlyer.safeTransfer(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {
            // If manger is currently rolling over add two to min withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {
            // If manager is not rolling over add one to minimum withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        address[] memory senderAddress = new address[](1);
        senderAddress[0] = msg.sender;
        triggerBalanceUpdateEvent(senderAddress);

        emit WithdrawalRequested(msg.sender, amount);
    }

    function triggerBalanceUpdateEvent(address[] memory _addresses) public {
        bytes32 eventSig = "Withdrawal Request";
        for (uint256 i = 0; i < _addresses.length; i++) {
            encodeAndSendData(eventSig, _addresses[i]);
        }

        emit BalanceEventUpdated(_addresses);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = underlyer.allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            underlyer.safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            underlyer.safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        bool success = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        bool success = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function pauseDeposit() external override onlyOwner {
        depositsPaused = true;

        emit DepositsPaused();
    }

    function unpauseDeposit() external override onlyOwner {
        depositsPaused = false;

        emit DepositsUnpaused();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2)
        external
        override
        onlyOwner
    {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        underlyer.safeTransferFrom(fromAccount, address(this), amount);

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user).sub(requestedWithdrawals[_user].amount);
        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: address(this),
                amount: userBalance
            })
        );

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IStaking.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../fxPortal/IFxStateSender.sol";
import "../interfaces/events/IEventSender.sol";

/**
 * @title Specialized implementation of the Pool contract that allows immediate
 * withdraw of any previously set withdrawal request, as well as any newly set
 * withdrawal request. Also allow the immediate migration of funds to the Staking contract
 *
 * @dev This should not be deployed until we are ready to allow users to migrate to
 * the Staking contract. At that time, we will upgrade the TOKE pool to this version
 */
contract TokeMigrationPool is
    ILiquidityPool,
    Initializable,
    ERC20,
    Ownable,
    Pausable,
    IEventSender
{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer; // Underlying ERC20 token
    IManager public manager;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;
    bool public _eventSend;
    Destinations public destinations;

    bool public depositsPaused;

    address public constant STAKING = 0x96F98Ed74639689C3A11daf38ef86E59F43417D3;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier whenDepositsNotPaused() {
        require(!paused(), "Pausable: paused");
        require(!depositsPaused, "DEPOSITS_PAUSED");
        _;
    }

    event Migrated(address migrator, uint256 amount);

    function initialize(
        ERC20 _underlyer,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_underlyer) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        underlyer = _underlyer;
        manager = _manager;
    }

    ///@notice Gets decimals of underlyer so that tAsset decimals will match
    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function deposit(uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev Allows withdraw regardless of cycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // If full amount withdrawn delete from mapping
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);
        underlyer.safeTransfer(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);
    }

    function withdrawAndMigrate() external whenNotPaused nonReentrant {
        uint256 amount = balanceOf(msg.sender); // 1:1 allows this operation to work
        require(amount > 0, "NOTHING_TO_MIGRATE");

        WithdrawalInfo memory withdrawal = requestedWithdrawals[msg.sender];
        uint256 requestAmount = withdrawal.amount;
        if (requestAmount > 0) {
            withheldLiquidity = withheldLiquidity.sub(requestAmount);
            delete requestedWithdrawals[msg.sender];
        }

        _approveStaking(amount, STAKING);
        _burn(msg.sender, amount);

        IStaking(STAKING).depositFor(msg.sender, amount, 0);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);

        emit Migrated(msg.sender, amount);
    }

    function _approveStaking(uint256 amount, address staking) private {
        underlyer.safeIncreaseAllowance(staking, amount);
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        requestedWithdrawals[msg.sender].minCycle = 0;

        bytes32 eventSig = "Withdrawal Request";
        encodeAndSendData(eventSig, msg.sender);

        emit WithdrawalRequested(msg.sender, amount);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = underlyer.allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            underlyer.safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            underlyer.safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        bool success = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        bool success = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function pauseDeposit() external override onlyOwner {
        depositsPaused = true;

        emit DepositsPaused();
    }

    function unpauseDeposit() external override onlyOwner {
        depositsPaused = false;

        emit DepositsUnpaused();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2)
        external
        override
        onlyOwner
    {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        underlyer.safeTransferFrom(fromAccount, address(this), amount);

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user).sub(requestedWithdrawals[_user].amount);
        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: address(this),
                amount: userBalance
            })
        );

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Allows for the staking and vesting of TOKE for
 *  liquidity directors. Schedules can be added to enable various
 *  cliff+duration/interval unlock periods for vesting tokens.
 */
interface IStaking {
    struct StakingSchedule {
        uint256 cliff; // Duration in seconds before staking starts
        uint256 duration; // Seconds it takes for entire amount to stake
        uint256 interval; // Seconds it takes for a chunk to stake
        bool setup; //Just so we know its there
        bool isActive; //Whether we can setup new stakes with the schedule
        uint256 hardStart; //Stakings will always start at this timestamp if set
        bool isPublic; //Schedule can be written to by any account
    }

    struct StakingScheduleInfo {
        StakingSchedule schedule;
        uint256 index;
    }

    struct StakingDetails {
        uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
        uint256 withdrawn; //Amount that was staked and subsequently withdrawn
        uint256 slashed; //Amount that has been slashed
        uint256 started; //Timestamp at which the stake started
        uint256 scheduleIx;
    }

    struct WithdrawalInfo {
        uint256 minCycleIndex;
        uint256 amount;
    }

    struct QueuedTransfer {
        address from;
        uint256 scheduleIdxFrom;
        uint256 scheduleIdxTo;
        uint256 amount;
        address to;
    }

    event ScheduleAdded(
        uint256 scheduleIndex,
        uint256 cliff,
        uint256 duration,
        uint256 interval,
        bool setup,
        bool isActive,
        uint256 hardStart,
        address notional
    );
    event ScheduleRemoved(uint256 scheduleIndex);
    event WithdrawalRequested(address account, uint256 scheduleIdx, uint256 amount);
    event WithdrawCompleted(address account, uint256 scheduleIdx, uint256 amount);
    event Deposited(address account, uint256 amount, uint256 scheduleIx);
    event Slashed(address account, uint256 amount, uint256 scheduleIx);
    event PermissionedDepositorSet(address depositor, bool allowed);
    event UserSchedulesSet(address account, uint256[] userSchedulesIdxs);
    event NotionalAddressesSet(uint256[] scheduleIdxs, address[] addresses);
    event ScheduleStatusSet(uint256 scheduleId, bool isActive);
    event StakeTransferred(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event ZeroSweep(address user, uint256 amount, uint256 scheduleFrom);
    event TransferApproverSet(address approverAddress);
    event TransferQueued(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRemoved(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );
    event QueuedTransferRejected(
        address from,
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    );

    /// @notice Get a queued higher level schedule transfers
    /// @param fromAddress Account that initiated the transfer
    /// @param fromScheduleId Schedule they are transferring out of
    /// @return Details about the transfer
    function getQueuedTransfer(address fromAddress, uint256 fromScheduleId)
        external
        view
        returns (QueuedTransfer memory);

    /// @notice Get the current transfer approver
    /// @return Transfer approver address
    function transferApprover() external returns (address);

    ///@notice Allows for checking of user address in permissionedDepositors mapping
    ///@param account Address of account being checked
    ///@return Boolean, true if address exists in mapping
    function permissionedDepositors(address account) external returns (bool);

    ///@notice Allows owner to set a multitude of schedules that an address has access to
    ///@param account User address
    ///@param userSchedulesIdxs Array of schedule indexes
    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external;

    ///@notice Allows owner to add schedule
    ///@param schedule A StakingSchedule struct that contains all info needed to make a schedule
    ///@param notional Notional addrss for schedule, used to send balances to L2 for voting purposes
    function addSchedule(StakingSchedule memory schedule, address notional) external;

    ///@notice Gets all info on all schedules
    ///@return retSchedules An array of StakingScheduleInfo struct
    function getSchedules() external view returns (StakingScheduleInfo[] memory retSchedules);

    ///@notice Allows owner to set a permissioned depositor
    ///@param account User address
    ///@param canDeposit Boolean representing whether user can deposit
    function setPermissionedDepositor(address account, bool canDeposit) external;

    ///@notice Allows a user to get the stakes of an account
    ///@param account Address that is being checked for stakes
    ///@return stakes StakingDetails array containing info about account's stakes
    function getStakes(address account) external view returns (StakingDetails[] memory stakes);

    ///@notice Gets total value staked for an address across all schedules
    ///@param account Address for which total stake is being calculated
    ///@return value uint256 total of account
    function balanceOf(address account) external view returns (uint256 value);

    ///@notice Returns amount available to withdraw for an account and schedule Index
    ///@param account Address that is being checked for withdrawals
    ///@param scheduleIndex Index of schedule that is being checked for withdrawals
    function availableForWithdrawal(address account, uint256 scheduleIndex)
        external
        view
        returns (uint256);

    ///@notice Returns unvested amount for certain address and schedule index
    ///@param account Address being checked for unvested amount
    ///@param scheduleIndex Schedule index being checked for unvested amount
    ///@return value Uint256 representing unvested amount
    function unvested(address account, uint256 scheduleIndex) external view returns (uint256 value);

    ///@notice Returns vested amount for address and schedule index
    ///@param account Address being checked for vested amount
    ///@param scheduleIndex Schedule index being checked for vested amount
    ///@return value Uint256 vested
    function vested(address account, uint256 scheduleIndex) external view returns (uint256 value);

    ///@notice Allows user to deposit token to specific vesting / staking schedule
    ///@param amount Uint256 amount to be deposited
    ///@param scheduleIndex Uint256 representing schedule to user
    function deposit(uint256 amount, uint256 scheduleIndex) external;

    /// @notice Allows users to deposit into 0 schedule
    /// @param amount Deposit amount
    function deposit(uint256 amount) external;

    ///@notice Allows account to deposit on behalf of other account
    ///@param account Account to be deposited for
    ///@param amount Amount to be deposited
    ///@param scheduleIndex Index of schedule to be used for deposit
    function depositFor(
        address account,
        uint256 amount,
        uint256 scheduleIndex
    ) external;

    ///@notice Allows permissioned depositors to deposit into custom schedule
    ///@param account Address of account being deposited for
    ///@param amount Uint256 amount being deposited
    ///@param schedule StakingSchedule struct containing details needed for new schedule
    ///@param notional Notional address attached to schedule, allows for different voting weights on L2
    function depositWithSchedule(
        address account,
        uint256 amount,
        StakingSchedule calldata schedule,
        address notional
    ) external;

    ///@notice User can request withdrawal from staking contract at end of cycle
    ///@notice Performs checks to make sure amount <= amount available
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule index for withdrawal Request
    function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external;

    ///@notice Allows for withdrawal after successful withdraw request and proper amount of cycles passed
    ///@param amount Amount to withdraw
    ///@param scheduleIdx Schedule to withdraw from
    function withdraw(uint256 amount, uint256 scheduleIdx) external;

    /// @notice Allows owner to set schedule to active or not
    /// @param scheduleIndex Schedule index to set isActive boolean
    /// @param activeBoolean Bool to set schedule active or not
    function setScheduleStatus(uint256 scheduleIndex, bool activeBoolean) external;

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    /// @notice Used to slash user funds when needed
    /// @notice accounts and amounts arrays must be same length
    /// @notice Only one scheduleIndex can be slashed at a time
    /// @dev Implementation must be restructed to owner account
    /// @param accounts Array of accounts to slash
    /// @param amounts Array of amounts that corresponds with accounts
    /// @param scheduleIndex scheduleIndex of users that are being slashed
    function slash(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 scheduleIndex
    ) external;

    /// @notice Allows user to transfer stake to anohter address
    /// @param scheduleFrom, schedule stake being transferred from
    /// @param scheduleTo, schedule stake being transferred to
    /// @param amount, Amount to be transferred to new address and schedule
    /// @param to, Address to be transferred to
    function queueTransfer(
        uint256 scheduleFrom,
        uint256 scheduleTo,
        uint256 amount,
        address to
    ) external;

    /// @notice Allows user to remove queued transfer
    /// @param scheduleIdxFrom scheduleIdx being transferred from
    function removeQueuedTransfer(uint256 scheduleIdxFrom) external;

    /// @notice Set the address used to denote the token amount for a particular schedule
    /// @dev Relates to the Balance Tracker tracking of tokens and balances. Each schedule is tracked separately
    function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses)
        external;

    /// @notice For tokens in higher level schedules, move vested amounts to the default schedule
    /// @notice Allows for full voting weight to be applied when tokens have vested
    /// @param scheduleIdx Schedule to sweep tokens from
    /// @param amount Amount to sweep to default schedule
    function sweepToScheduleZero(uint256 scheduleIdx, uint256 amount) external;

    /// @notice Set the approver for higher schedule transfers
    /// @param approver New transfer approver
    function setTransferApprover(address approver) external;

    /// @notice Withdraw from the default schedule. Must have a request in previously
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) external;

    /// @notice Allows transfeApprover to reject a submitted transfer
    /// @param from address queued transfer is from
    /// @param scheduleIdxFrom Schedule index of queued transfer
    function rejectQueuedTransfer(address from, uint256 scheduleIdxFrom) external;

    /// @notice Approve a queued transfer from a higher level schedule
    /// @param from address that queued the transfer
    /// @param scheduleIdxFrom Schedule index of queued transfer
    /// @param scheduleIdxTo Schedule index of destination
    /// @param amount Amount being transferred
    /// @param to Destination account
    function approveQueuedTransfer(
        address from,
        uint256 scheduleIdxFrom,
        uint256 scheduleIdxTo,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../fxPortal/IFxStateSender.sol";
import "../interfaces/events/IEventSender.sol";

contract Pool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer; // Underlying ERC20 token
    IManager public manager;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;
    bool public _eventSend;
    Destinations public destinations;

    bool public depositsPaused;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier whenDepositsNotPaused() {
        require(!paused(), "Pausable: paused");
        require(!depositsPaused, "DEPOSITS_PAUSED");
        _;
    }

    function initialize(
        ERC20 _underlyer,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_underlyer) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        underlyer = _underlyer;
        manager = _manager;
    }

    ///@notice Gets decimals of underlyer so that tAsset decimals will match
    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function deposit(uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        // Checks for manager cycle and if user is allowed to withdraw based on their minimum withdrawal cycle
        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // If full amount withdrawn delete from mapping
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);
        underlyer.safeTransfer(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {
            // If manger is currently rolling over add two to min withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {
            // If manager is not rolling over add one to minimum withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        emit WithdrawalRequested(msg.sender, amount);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = underlyer.allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            underlyer.safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            underlyer.safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        bool success = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        bool success = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pauseDeposit() external override onlyOwner {
        depositsPaused = true;

        emit DepositsPaused();
    }

    function unpauseDeposit() external override onlyOwner {
        depositsPaused = false;

        emit DepositsUnpaused();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2)
        external
        override
        onlyOwner
    {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        underlyer.safeTransferFrom(fromAccount, address(this), amount);

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user);
        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: address(this),
                amount: userBalance
            })
        );

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityEthPool.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {AddressUpgradeable as Address} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/IEventSender.sol";

contract EthPool is ILiquidityEthPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    /// @dev TODO: Hardcode addresses, make immuatable, remove from initializer
    IWETH public override weth;
    IManager public manager;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;

    bool public _eventSend;
    Destinations public destinations;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    /// @dev necessary to receive ETH
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function initialize(
        IWETH _weth,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_weth) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        weth = _weth;
        manager = _manager;
        withheldLiquidity = 0;
    }

    function deposit(uint256 amount) external payable override whenNotPaused {
        _deposit(msg.sender, msg.sender, amount, msg.value);
    }

    function depositFor(address account, uint256 amount) external payable override whenNotPaused {
        _deposit(msg.sender, account, amount, msg.value);
    }

    function underlyer() external view override returns (address) {
        return address(weth);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount, bool asEth) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(weth.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // Delete if all assets withdrawn
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);
        _burn(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);

        if (asEth) { // Convert to eth
            weth.withdraw(requestedAmount);
            msg.sender.sendValue(requestedAmount);
        } else { // Send as WETH
            IERC20(weth).safeTransfer(msg.sender, requestedAmount);
        }
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {  // If manager is in the middle of a cycle rollover, add two cycles
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {  // If the manager is not in the middle of a rollover, add one cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        emit WithdrawalRequested(msg.sender, amount);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = IERC20(weth).allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            IERC20(weth).safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            IERC20(weth).safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        (bool success) = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        (bool success) = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyOwner {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount,
        uint256 msgValue
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        if (msgValue > 0) { // If ether get weth
            require(msgValue == amount, "AMT_VALUE_MISMATCH");
            weth.deposit{value: amount}();
        } else { // Else go ahead and transfer weth from account to pool
            IERC20(weth).safeTransferFrom(fromAccount, address(this), amount);
        }

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user);
        bytes memory data = abi.encode(BalanceUpdateEvent({
            eventSig: _eventSig,
            account: _user, 
            token: address(this), 
            amount: userBalance
        }));

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../interfaces/IWETH.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit Eth to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityEthPool {
    struct WithdrawalInfo {
        uint256 minCycle;
        uint256 amount;
    }

    event WithdrawalRequested(address requestor, uint256 amount);

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function deposit(uint256 amount) external payable;

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function depositFor(address account, uint256 amount) external payable;

    /// @notice Requests that the manager prepare funds for withdrawal next cycle
    /// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
    /// @param amount Amount of fTokens requested to be redeemed
    function requestWithdrawal(uint256 amount) external;

    function approveManager(uint256 amount) external;

    /// @notice Sender must first invoke requestWithdrawal in a previous cycle
    /// @notice This function will burn the fAsset and transfers underlying asset back to sender
    /// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
    /// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
    function withdraw(uint256 amount, bool asEth) external;

    /// @return Reference to the underlying ERC-20 contract
    function weth() external view returns (IWETH);

    /// @return Reference to the underlying ERC-20 contract
    function underlyer() external view returns (address);

    /// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
    function withheldLiquidity() external view returns (uint256);

    /// @notice Get withdraw requests for an account
    /// @param account User account to check
    /// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
    function requestedWithdrawals(address account) external view returns (uint256, uint256);

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 *  @title Interface for the WETH token
 */
interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AddressRegistry is IAddressRegistry, Initializable, AccessControl {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (AddressTypes => EnumerableSet.AddressSet) private addressSets;

    // solhint-disable-next-line var-name-mixedcase 
    bytes32 public immutable REGISTERED_ADDRESS = keccak256("REGISTERED_ROLE");

    modifier onlyRegistered () {
        require(hasRole(REGISTERED_ADDRESS, msg.sender), "NOT_REGISTERED");
        _;
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REGISTERED_ADDRESS, _msgSender());
    }

    function addRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        grantRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressAdded(_addr);
    }

    function removeRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        revokeRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressRemoved(_addr);
    }

    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        EnumerableSet.AddressSet storage structToAddTo = addressSets[_index];

        for (uint256 i = 0; i < arrayLength; i++) {
            require(_addresses[i] != address(0), "INVALID_ADDRESS");
            require(structToAddTo.add(_addresses[i]), "ADD_FAIL");
        }

        emit AddedToRegistry(_addresses, _index);
    }

    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        EnumerableSet.AddressSet storage structToRemoveFrom = addressSets[_index];
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        require(arrayLength <= structToRemoveFrom.length(), "TOO_MANY_ADDRESSES");

        for (uint256 i = 0; i < arrayLength; i++) {
            address currentAddress = _addresses[i];
            require(structToRemoveFrom.remove(currentAddress), "REMOVE_FAIL");
        }

        emit RemovedFromRegistry(_addresses, _index);
    }

    function getAddressForType(AddressTypes _index) external view override returns (address[] memory) {
        EnumerableSet.AddressSet storage structToReturn = addressSets[_index];
        uint256 arrayLength = structToReturn.length();

        address[] memory registryAddresses = new address[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            registryAddresses[i] = structToReturn.at(i);
        }
        return registryAddresses;
    }

    function checkAddress(address _addr, uint256 _index) external view override returns (bool) {
        EnumerableSet.AddressSet storage structToCheck = addressSets[AddressTypes(_index)];
        return structToCheck.contains(_addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/EventSender.sol";
import "../interfaces/events/DelegationDisabled.sol";
import "../interfaces/events/DelegationEnabled.sol";
import "../interfaces/IERC1271.sol";

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// solhint-disable var-name-mixedcase
contract DelegateFunction is IDelegateFunction, Initializable, Ownable, Pausable, EventSender {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    bytes4 public constant EIP1271_MAGICVALUE = 0x1626ba7e;

    string public constant EIP191_HEADER = "\x19\x01";

    bytes32 public immutable EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public immutable DELEGATE_PAYLOAD_TYPEHASH =
        keccak256(
            "DelegatePayload(uint256 nonce,DelegateMap[] sets)DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)"
        );

    bytes32 public immutable DELEGATE_MAP_TYPEHASH =
        keccak256("DelegateMap(bytes32 functionId,address otherParty,bool mustRelinquish)");

    bytes32 public immutable FUNCTIONS_LIST_PAYLOAD_TYPEHASH =
        keccak256("FunctionsListPayload(uint256 nonce,bytes32[] sets)");

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private CACHED_EIP712_DOMAIN_SEPARATOR;
    uint256 private CACHED_CHAIN_ID;

    bytes32 public constant DOMAIN_NAME = keccak256("Tokemak Delegate Function");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");

    /// @dev Stores the users next valid vote nonce
    mapping(address => uint256) public override contractWalletNonces;

    EnumerableSet.Bytes32Set private allowedFunctions;

    //from => functionId => (otherParty, mustRelinquish, functionId)
    mapping(address => mapping(bytes32 => Destination)) private delegations;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        CACHED_CHAIN_ID = _getChainID();
        CACHED_EIP712_DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    function getDelegations(address from)
        external
        view
        override
        returns (DelegateMapView[] memory maps)
    {
        uint256 numOfFunctions = allowedFunctions.length();
        maps = new DelegateMapView[](numOfFunctions);
        for (uint256 ix = 0; ix < numOfFunctions; ix++) {
            bytes32 functionId = allowedFunctions.at(ix);
            Destination memory existingDestination = delegations[from][functionId];
            if (existingDestination.otherParty != address(0)) {
                maps[ix] = DelegateMapView({
                    functionId: functionId,
                    otherParty: existingDestination.otherParty,
                    mustRelinquish: existingDestination.mustRelinquish,
                    pending: existingDestination.pending
                });
            }
        }
    }

    function getDelegation(address from, bytes32 functionId)
        external
        view
        override
        returns (DelegateMapView memory map)
    {
        Destination memory existingDestination = delegations[from][functionId];
        map = DelegateMapView({
            functionId: functionId,
            otherParty: existingDestination.otherParty,
            mustRelinquish: existingDestination.mustRelinquish,
            pending: existingDestination.pending
        });
    }

    function delegate(DelegateMap[] memory sets) external override whenNotPaused {
        _delegate(msg.sender, sets);
    }

    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 delegatePayloadHash = _hashDelegate(delegatePayload, signatureType);
        _verifyNonce(contractAddress, delegatePayload.nonce);

        _verifyIERC1271Signature(contractAddress, delegatePayloadHash, signature);

        _delegate(contractAddress, delegatePayload.sets);
    }

    function acceptDelegation(DelegatedTo[] calldata incoming) external override whenNotPaused {
        uint256 length = incoming.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegatedTo calldata deleg = incoming[ix];
            Destination storage destination = delegations[deleg.originalParty][deleg.functionId];
            require(destination.otherParty == msg.sender, "NOT_ASSIGNED");
            require(destination.pending, "ALREADY_ACCEPTED");

            destination.pending = false;

            bytes memory data = abi.encode(
                DelegationEnabled({
                    eventSig: "DelegationEnabled",
                    from: deleg.originalParty,
                    to: msg.sender,
                    functionId: deleg.functionId
                })
            );

            sendEvent(data);

            emit DelegationAccepted(
                deleg.originalParty,
                msg.sender,
                deleg.functionId,
                destination.mustRelinquish
            );
        }
    }

    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

        _verifyNonce(contractAddress, functionsListPayload.nonce);

        _verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

        _removeDelegations(contractAddress, functionsListPayload.sets);
    }

    function removeDelegation(bytes32[] calldata functionIds) external override whenNotPaused {
        _removeDelegations(msg.sender, functionIds);
    }

    function rejectDelegation(DelegatedTo[] calldata rejections) external override whenNotPaused {
        uint256 length = rejections.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegatedTo memory pending = rejections[ix];
            _rejectDelegation(msg.sender, pending);
        }
    }

    function relinquishDelegation(DelegatedTo[] calldata relinquish)
        external
        override
        whenNotPaused
    {
        uint256 length = relinquish.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            _relinquishDelegation(msg.sender, relinquish[ix]);
        }
    }

    function cancelPendingDelegation(bytes32[] calldata functionIds)
        external
        override
        whenNotPaused
    {
        _cancelPendingDelegations(msg.sender, functionIds);
    }

    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external override whenNotPaused {
        bytes32 functionsListPayloadHash = _hashFunctionsList(functionsListPayload, signatureType);

        _verifyNonce(contractAddress, functionsListPayload.nonce);

        _verifyIERC1271Signature(contractAddress, functionsListPayloadHash, signature);

        _cancelPendingDelegations(contractAddress, functionsListPayload.sets);
    }

    function setAllowedFunctions(AllowedFunctionSet[] calldata functions)
        external
        override
        onlyOwner
    {
        uint256 length = functions.length;
        require(functions.length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            require(allowedFunctions.add(functions[ix].id), "ADD_FAIL");
        }

        emit AllowedFunctionsSet(functions);
    }

    function canControlEventSend() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _delegate(address from, DelegateMap[] memory sets) internal {
        uint256 length = sets.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            DelegateMap memory set = sets[ix];

            require(allowedFunctions.contains(set.functionId), "INVALID_FUNCTION");
            require(set.otherParty != address(0), "INVALID_DESTINATION");
            require(set.otherParty != from, "NO_SELF");

            //Remove any existing delegation
            Destination memory existingDestination = delegations[from][set.functionId];
            if (existingDestination.otherParty != address(0)) {
                _removeDelegation(from, set.functionId, existingDestination);
            }

            delegations[from][set.functionId] = Destination({
                otherParty: set.otherParty,
                mustRelinquish: set.mustRelinquish,
                pending: true
            });

            emit PendingDelegationAdded(from, set.otherParty, set.functionId, set.mustRelinquish);
        }
    }

    function _rejectDelegation(address to, DelegatedTo memory pending) private {
        Destination memory existingDestination = delegations[pending.originalParty][
            pending.functionId
        ];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(existingDestination.pending, "ALREADY_ACCEPTED");

        delete delegations[pending.originalParty][pending.functionId];

        emit DelegationRejected(
            pending.originalParty,
            to,
            pending.functionId,
            existingDestination.mustRelinquish
        );
    }

    function _removeDelegations(address from, bytes32[] calldata functionIds) private {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            Destination memory existingDestination = delegations[from][functionIds[ix]];
            _removeDelegation(from, functionIds[ix], existingDestination);
        }
    }

    function _removeDelegation(
        address from,
        bytes32 functionId,
        Destination memory existingDestination
    ) private {
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(!existingDestination.mustRelinquish, "EXISTING_MUST_RELINQUISH");

        delete delegations[from][functionId];

        if (existingDestination.pending) {
            emit PendingDelegationRemoved(
                from,
                existingDestination.otherParty,
                functionId,
                existingDestination.mustRelinquish
            );
        } else {
            _sendDisabledEvent(from, existingDestination.otherParty, functionId);

            emit DelegationRemoved(
                from,
                existingDestination.otherParty,
                functionId,
                existingDestination.mustRelinquish
            );
        }
    }

    function _relinquishDelegation(address to, DelegatedTo calldata relinquish) private {
        Destination memory existingDestination = delegations[relinquish.originalParty][
            relinquish.functionId
        ];
        require(existingDestination.otherParty != address(0), "NOT_SETUP");
        require(existingDestination.otherParty == to, "NOT_OTHER_PARTIES");
        require(!existingDestination.pending, "NOT_YET_ACCEPTED");

        delete delegations[relinquish.originalParty][relinquish.functionId];

        _sendDisabledEvent(relinquish.originalParty, to, relinquish.functionId);

        emit DelegationRelinquished(
            relinquish.originalParty,
            to,
            relinquish.functionId,
            existingDestination.mustRelinquish
        );
    }

    function _sendDisabledEvent(
        address from,
        address to,
        bytes32 functionId
    ) private {
        bytes memory data = abi.encode(
            DelegationDisabled({
                eventSig: "DelegationDisabled",
                from: from,
                to: to,
                functionId: functionId
            })
        );

        sendEvent(data);
    }

    function _cancelPendingDelegations(address from, bytes32[] calldata functionIds) private {
        uint256 length = functionIds.length;
        require(length > 0, "NO_DATA");

        for (uint256 ix = 0; ix < length; ix++) {
            _cancelPendingDelegation(from, functionIds[ix]);
        }
    }

    function _cancelPendingDelegation(address from, bytes32 functionId) private {
        require(allowedFunctions.contains(functionId), "INVALID_FUNCTION");

        Destination memory existingDestination = delegations[from][functionId];
        require(existingDestination.otherParty != address(0), "NO_PENDING");
        require(existingDestination.pending, "NOT_PENDING");

        delete delegations[from][functionId];

        emit PendingDelegationRemoved(
            from,
            existingDestination.otherParty,
            functionId,
            existingDestination.mustRelinquish
        );
    }

    function _hashDelegate(DelegatePayload memory delegatePayload, SignatureType signatureType)
        private
        view
        returns (bytes32)
    {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(),
                _hashDelegatePayload(delegatePayload)
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _hashDelegatePayload(DelegatePayload memory delegatePayload)
        private
        view
        returns (bytes32)
    {
        bytes32[] memory encodedSets = new bytes32[](delegatePayload.sets.length);
        for (uint256 ix = 0; ix < delegatePayload.sets.length; ix++) {
            encodedSets[ix] = _hashDelegateMap(delegatePayload.sets[ix]);
        }

        return
            keccak256(
                abi.encode(
                    DELEGATE_PAYLOAD_TYPEHASH,
                    delegatePayload.nonce,
                    keccak256(abi.encodePacked(encodedSets))
                )
            );
    }

    function _hashDelegateMap(DelegateMap memory delegateMap) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DELEGATE_MAP_TYPEHASH,
                    delegateMap.functionId,
                    delegateMap.otherParty,
                    delegateMap.mustRelinquish
                )
            );
    }

    function _hashFunctionsList(
        FunctionsListPayload calldata functionsListPayload,
        SignatureType signatureType
    ) private view returns (bytes32) {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(
                        FUNCTIONS_LIST_PAYLOAD_TYPEHASH,
                        functionsListPayload.nonce,
                        keccak256(abi.encodePacked(functionsListPayload.sets))
                    )
                )
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _verifyIERC1271Signature(
        address contractAddress,
        bytes32 payloadHash,
        bytes memory signature
    ) private view {
        try IERC1271(contractAddress).isValidSignature(payloadHash, signature) returns (
            bytes4 result
        ) {
            require(result == EIP1271_MAGICVALUE, "INVALID_SIGNATURE");
        } catch {
            revert("INVALID_SIGNATURE_VALIDATION");
        }
    }

    function _verifyNonce(address account, uint256 nonce) private {
        require(contractWalletNonces[account] == nonce, "INVALID_NONCE");
        // Ensure the message cannot be replayed
        contractWalletNonces[account] = nonce.add(1);
    }

    function _getChainID() private pure returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_getChainID() == CACHED_CHAIN_ID) {
            return CACHED_EIP712_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    DOMAIN_NAME,
                    DOMAIN_VERSION,
                    _getChainID(),
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./structs/DelegateMapView.sol";
import "./structs/Signature.sol";

/**
 *   @title Manages the state of an accounts delegation settings.
 *   Allows for various methods of validation as well as enabling
 *   different system functions to be delegated to different accounts
 */
interface IDelegateFunction {
    struct AllowedFunctionSet {
        bytes32 id;
    }

    struct FunctionsListPayload {
        bytes32[] sets;
        uint256 nonce;
    }

    struct DelegatePayload {
        DelegateMap[] sets;
        uint256 nonce;
    }

    struct DelegateMap {
        bytes32 functionId;
        address otherParty;
        bool mustRelinquish;
    }

    struct Destination {
        address otherParty;
        bool mustRelinquish;
        bool pending;
    }

    struct DelegatedTo {
        address originalParty;
        bytes32 functionId;
    }

    event AllowedFunctionsSet(AllowedFunctionSet[] functions);
    event PendingDelegationAdded(address from, address to, bytes32 functionId, bool mustRelinquish);
    event PendingDelegationRemoved(
        address from,
        address to,
        bytes32 functionId,
        bool mustRelinquish
    );
    event DelegationRemoved(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRelinquished(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationAccepted(address from, address to, bytes32 functionId, bool mustRelinquish);
    event DelegationRejected(address from, address to, bytes32 functionId, bool mustRelinquish);

    /// @notice Get the current nonce a contract wallet should use
    /// @param account Account to query
    /// @return nonce Nonce that should be used for next call
    function contractWalletNonces(address account) external returns (uint256 nonce);

    /// @notice Get an accounts current delegations
    /// @dev These may be in a pending state
    /// @param from Account that is delegating functions away
    /// @return maps List of delegations in various states of approval
    function getDelegations(address from) external view returns (DelegateMapView[] memory maps);

    /// @notice Get an accounts delegation of a specific function
    /// @dev These may be in a pending state
    /// @param from Account that is the delegation functions away
    /// @return map Delegation info
    function getDelegation(address from, bytes32 functionId)
        external
        view
        returns (DelegateMapView memory map);

    /// @notice Initiate delegation of one or more system functions to different account(s)
    /// @param sets Delegation instructions for the contract to initiate
    function delegate(DelegateMap[] memory sets) external;

    /// @notice Initiate delegation on behalf of a contract that supports ERC1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param delegatePayload Sets of DelegateMap objects
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function delegateWithEIP1271(
        address contractAddress,
        DelegatePayload memory delegatePayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Accept one or more delegations from another account
    /// @param incoming Delegation details being accepted
    function acceptDelegation(DelegatedTo[] calldata incoming) external;

    /// @notice Remove one or more delegation that you have previously setup
    function removeDelegation(bytes32[] calldata functionIds) external;

    /// @notice Remove one or more delegations that you have previously setup on behalf of a contract supporting EIP1271
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function removeDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Reject one or more delegations being sent to you
    /// @param rejections Delegations to reject
    function rejectDelegation(DelegatedTo[] calldata rejections) external;

    /// @notice Remove one or more delegations that you have previously accepted
    function relinquishDelegation(DelegatedTo[] calldata relinquish) external;

    /// @notice Cancel one or more delegations you have setup but that has not yet been accepted
    /// @param functionIds System functions you wish to retain control of
    function cancelPendingDelegation(bytes32[] calldata functionIds) external;

    /// @notice Cancel one or more delegations you have setup on behalf of a contract that supported EIP1271, but that has not yet been accepted
    /// @param contractAddress Address of the ERC1271 contract used to verify the given signature
    /// @param functionsListPayload Sets of FunctionListPayload objects ({sets: bytes32[]})
    /// @param signature Signature data
    /// @param signatureType Type of signature used (EIP712|EthSign)
    function cancelPendingDelegationWithEIP1271(
        address contractAddress,
        FunctionsListPayload calldata functionsListPayload,
        bytes memory signature,
        SignatureType signatureType
    ) external;

    /// @notice Add to the list of system functions that are allowed to be delegated
    /// @param functions New system function ids
    function setAllowedFunctions(AllowedFunctionSet[] calldata functions) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Destinations.sol";
import "./IEventSender.sol";

/// @title Base contract for sending events to our Governance layer
abstract contract EventSender is IEventSender {
    bool public eventSend;
    Destinations public destinations;

    modifier onEventSend() {
        // Only send the event when enabled
        if (eventSend) {
            _;
        }
    }

    modifier onlyEventSendControl() {
        // Give the implementing contract control over permissioning
        require(canControlEventSend(), "CANNOT_CONTROL_EVENTS");
        _;
    }

    /// @notice Configure the Polygon state sender root and destination for messages sent
    /// @param fxStateSender Address of Polygon State Sender Root contract
    /// @param destinationOnL2 Destination address of events sent. Should be our Event Proxy
    function setDestinations(address fxStateSender, address destinationOnL2)
        external
        virtual
        override
        onlyEventSendControl
    {
        require(fxStateSender != address(0), "INVALID_FX_ADDRESS");
        require(destinationOnL2 != address(0), "INVALID_DESTINATION_ADDRESS");

        destinations.fxStateSender = IFxStateSender(fxStateSender);
        destinations.destinationOnL2 = destinationOnL2;

        emit DestinationsSet(fxStateSender, destinationOnL2);
    }

    /// @notice Enables or disables the sending of events
    function setEventSend(bool eventSendSet) external virtual override onlyEventSendControl {
        eventSend = eventSendSet;

        emit EventSendSet(eventSendSet);
    }

    /// @notice Determine permissions for controlling event sending
    /// @dev Should not revert, just return false
    function canControlEventSend() internal view virtual returns (bool);

    /// @notice Send event data to Governance layer
    function sendEvent(bytes memory data) internal virtual {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has disabled their delegation for voting or rewards
struct DelegationDisabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a user has enabled delegation for voting or rewards
struct DelegationEnabled {
    bytes32 eventSig;
    address from;
    address to;
    bytes32 functionId;
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (interfaces/IERC1271.sol)

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/// @notice Stores votes and rewards delegation mapping in DelegateFunction
struct DelegateMapView {
    bytes32 functionId;
    address otherParty;
    bool mustRelinquish;
    bool pending;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/// @notice Denotes the type of signature being submitted to contracts that support multiple
enum SignatureType {
    INVALID,
    // Specifically signTypedData_v4
    EIP712,
    // Specifically personal_sign
    ETHSIGN
}

// SPDX-License-Identifier: MIT

// Based on OpenZeppelin ERC1271WalletMock.sol 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/mocks/ERC1271WalletMock.sol
pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IERC1271.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

contract ERC1271WalletMock is Ownable, IERC1271 {
    constructor(address originalOwner) public {
        transferOwnership(originalOwner);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4 magicValue) {
        return ECDSA.recover(hash, signature) == owner() ? this.isValidSignature.selector : bytes4(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

// We import the contract so truffle compiles it, and we have the ABI
// available when working from truffle console.
import "@gnosis.pm/mock-contract/contracts/MockContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol" as ISushiswapV2Router;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol" as ISushiswapV2Factory;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2ERC20.sol" as ISushiswapV2ERC20;
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

pragma solidity ^0.6.0;

interface MockInterface {
	/**
	 * @dev After calling this method, the mock will return `response` when it is called
	 * with any calldata that is not mocked more specifically below
	 * (e.g. using givenMethodReturn).
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenAnyReturn(bytes calldata response) external;
	function givenAnyReturnBool(bool response) external;
	function givenAnyReturnUint(uint response) external;
	function givenAnyReturnAddress(address response) external;

	function givenAnyRevert() external;
	function givenAnyRevertWithMessage(string calldata message) external;
	function givenAnyRunOutOfGas() external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called regardless of arguments. If the methodId and arguments
	 * are mocked more specifically (using `givenMethodAndArguments`) the latter
	 * will take precedence.
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenMethodReturn(bytes calldata method, bytes calldata response) external;
	function givenMethodReturnBool(bytes calldata method, bool response) external;
	function givenMethodReturnUint(bytes calldata method, uint response) external;
	function givenMethodReturnAddress(bytes calldata method, address response) external;

	function givenMethodRevert(bytes calldata method) external;
	function givenMethodRevertWithMessage(bytes calldata method, string calldata message) external;
	function givenMethodRunOutOfGas(bytes calldata method) external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called with matching arguments. These exact calldataMocks will take
	 * precedence over all other calldataMocks.
	 * @param call ABI encoded calldata (methodId and arguments)
	 * @param response ABI encoded response that will be returned if contract is invoked with calldata
	 */
	function givenCalldataReturn(bytes calldata call, bytes calldata response) external;
	function givenCalldataReturnBool(bytes calldata call, bool response) external;
	function givenCalldataReturnUint(bytes calldata call, uint response) external;
	function givenCalldataReturnAddress(bytes calldata call, address response) external;

	function givenCalldataRevert(bytes calldata call) external;
	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external;
	function givenCalldataRunOutOfGas(bytes calldata call) external;

	/**
	 * @dev Returns the number of times anything has been called on this mock since last reset
	 */
	function invocationCount() external returns (uint);

	/**
	 * @dev Returns the number of times the given method has been called on this mock since last reset
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 */
	function invocationCountForMethod(bytes calldata method) external returns (uint);

	/**
	 * @dev Returns the number of times this mock has been called with the exact calldata since last reset.
	 * @param call ABI encoded calldata (methodId and arguments)
	 */
	function invocationCountForCalldata(bytes calldata call) external returns (uint);

	/**
	 * @dev Resets all mocked methods and invocation counts.
	 */
	 function reset() external;
}

/**
 * Implementation of the MockInterface.
 */
contract MockContract is MockInterface {
	enum MockType { Return, Revert, OutOfGas }
	
	bytes32 public constant MOCKS_LIST_START = hex"01";
	bytes public constant MOCKS_LIST_END = "0xff";
	bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
	bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";
	bytes public constant DEFAULT_FALLBACK_VALUE = abi.encode(false);

	// A linked list allows easy iteration and inclusion checks
	mapping(bytes32 => bytes) calldataMocks;
	mapping(bytes => MockType) calldataMockTypes;
	mapping(bytes => bytes) calldataExpectations;
	mapping(bytes => string) calldataRevertMessage;
	mapping(bytes32 => uint) calldataInvocations;

	mapping(bytes4 => bytes4) methodIdMocks;
	mapping(bytes4 => MockType) methodIdMockTypes;
	mapping(bytes4 => bytes) methodIdExpectations;
	mapping(bytes4 => string) methodIdRevertMessages;
	mapping(bytes32 => uint) methodIdInvocations;

	MockType fallbackMockType;
	bytes fallbackExpectation = DEFAULT_FALLBACK_VALUE;
	string fallbackRevertMessage;
	uint invocations;
	uint resetCount;

	constructor() public {
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
	}

	function trackCalldataMock(bytes memory call) private {
		bytes32 callHash = keccak256(call);
		if (calldataMocks[callHash].length == 0) {
			calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
			calldataMocks[MOCKS_LIST_START] = call;
		}
	}

	function trackMethodIdMock(bytes4 methodId) private {
		if (methodIdMocks[methodId] == 0x0) {
			methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
			methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
		}
	}

	function _givenAnyReturn(bytes memory response) internal {
		fallbackMockType = MockType.Return;
		fallbackExpectation = response;
	}

	function givenAnyReturn(bytes calldata response) override external {
		_givenAnyReturn(response);
	}

	function givenAnyReturnBool(bool response) override external {
		uint flag = response ? 1 : 0;
		_givenAnyReturn(uintToBytes(flag));
	}

	function givenAnyReturnUint(uint response) override external {
		_givenAnyReturn(uintToBytes(response));	
	}

	function givenAnyReturnAddress(address response) override external {
		_givenAnyReturn(uintToBytes(uint(response)));
	}

	function givenAnyRevert() override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = "";
	}

	function givenAnyRevertWithMessage(string calldata message) override external {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = message;
	}

	function givenAnyRunOutOfGas() override external {
		fallbackMockType = MockType.OutOfGas;
	}

	function _givenCalldataReturn(bytes memory call, bytes memory response) private  {
		calldataMockTypes[call] = MockType.Return;
		calldataExpectations[call] = response;
		trackCalldataMock(call);
	}

	function givenCalldataReturn(bytes calldata call, bytes calldata response) override external  {
		_givenCalldataReturn(call, response);
	}

	function givenCalldataReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenCalldataReturn(call, uintToBytes(flag));
	}

	function givenCalldataReturnUint(bytes calldata call, uint response) override external {
		_givenCalldataReturn(call, uintToBytes(response));
	}

	function givenCalldataReturnAddress(bytes calldata call, address response) override external {
		_givenCalldataReturn(call, uintToBytes(uint(response)));
	}

	function _givenMethodReturn(bytes memory call, bytes memory response) private {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Return;
		methodIdExpectations[method] = response;
		trackMethodIdMock(method);		
	}

	function givenMethodReturn(bytes calldata call, bytes calldata response) override external {
		_givenMethodReturn(call, response);
	}

	function givenMethodReturnBool(bytes calldata call, bool response) override external {
		uint flag = response ? 1 : 0;
		_givenMethodReturn(call, uintToBytes(flag));
	}

	function givenMethodReturnUint(bytes calldata call, uint response) override external {
		_givenMethodReturn(call, uintToBytes(response));
	}

	function givenMethodReturnAddress(bytes calldata call, address response) override external {
		_givenMethodReturn(call, uintToBytes(uint(response)));
	}

	function givenCalldataRevert(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = "";
		trackCalldataMock(call);
	}

	function givenMethodRevert(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		trackMethodIdMock(method);		
	}

	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) override external {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = message;
		trackCalldataMock(call);
	}

	function givenMethodRevertWithMessage(bytes calldata call, string calldata message) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		methodIdRevertMessages[method] = message;
		trackMethodIdMock(method);		
	}

	function givenCalldataRunOutOfGas(bytes calldata call) override external {
		calldataMockTypes[call] = MockType.OutOfGas;
		trackCalldataMock(call);
	}

	function givenMethodRunOutOfGas(bytes calldata call) override external {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.OutOfGas;
		trackMethodIdMock(method);	
	}

	function invocationCount() override external returns (uint) {
		return invocations;
	}

	function invocationCountForMethod(bytes calldata call) override external returns (uint) {
		bytes4 method = bytesToBytes4(call);
		return methodIdInvocations[keccak256(abi.encodePacked(resetCount, method))];
	}

	function invocationCountForCalldata(bytes calldata call) override external returns (uint) {
		return calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
	}

	function reset() override external {
		// Reset all exact calldataMocks
		bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
		bytes32 mockHash = keccak256(nextMock);
		// We cannot compary bytes
		while(mockHash != MOCKS_LIST_END_HASH) {
			// Reset all mock maps
			calldataMockTypes[nextMock] = MockType.Return;
			calldataExpectations[nextMock] = hex"";
			calldataRevertMessage[nextMock] = "";
			// Set next mock to remove
			nextMock = calldataMocks[mockHash];
			// Remove from linked list
			calldataMocks[mockHash] = "";
			// Update mock hash
			mockHash = keccak256(nextMock);
		}
		// Clear list
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

		// Reset all any calldataMocks
		bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
		while(nextAnyMock != SENTINEL_ANY_MOCKS) {
			bytes4 currentAnyMock = nextAnyMock;
			methodIdMockTypes[currentAnyMock] = MockType.Return;
			methodIdExpectations[currentAnyMock] = hex"";
			methodIdRevertMessages[currentAnyMock] = "";
			nextAnyMock = methodIdMocks[currentAnyMock];
			// Remove from linked list
			methodIdMocks[currentAnyMock] = 0x0;
		}
		// Clear list
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

		fallbackExpectation = DEFAULT_FALLBACK_VALUE;
		fallbackMockType = MockType.Return;
		invocations = 0;
		resetCount += 1;
	}

	function useAllGas() private {
		while(true) {
			bool s;
			assembly {
				//expensive call to EC multiply contract
				s := call(sub(gas(), 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
			}
		}
	}

	function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
		bytes4 out;
		for (uint i = 0; i < 4; i++) {
			out |= bytes4(b[i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function uintToBytes(uint256 x) private pure returns (bytes memory b) {
		b = new bytes(32);
		assembly { mstore(add(b, 32), x) }
	}

	function updateInvocationCount(bytes4 methodId, bytes memory originalMsgData) public {
		require(msg.sender == address(this), "Can only be called from the contract itself");
		invocations += 1;
		methodIdInvocations[keccak256(abi.encodePacked(resetCount, methodId))] += 1;
		calldataInvocations[keccak256(abi.encodePacked(resetCount, originalMsgData))] += 1;
	}

	fallback () payable external {
		bytes4 methodId;
		assembly {
			methodId := calldataload(0)
		}

		// First, check exact matching overrides
		if (calldataMockTypes[msg.data] == MockType.Revert) {
			revert(calldataRevertMessage[msg.data]);
		}
		if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
			useAllGas();
		}
		bytes memory result = calldataExpectations[msg.data];

		// Then check method Id overrides
		if (result.length == 0) {
			if (methodIdMockTypes[methodId] == MockType.Revert) {
				revert(methodIdRevertMessages[methodId]);
			}
			if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
				useAllGas();
			}
			result = methodIdExpectations[methodId];
		}

		// Last, use the fallback override
		if (result.length == 0) {
			if (fallbackMockType == MockType.Revert) {
				revert(fallbackRevertMessage);
			}
			if (fallbackMockType == MockType.OutOfGas) {
				useAllGas();
			}
			result = fallbackExpectation;
		}

		// Record invocation as separate call so we don't rollback in case we are called with STATICCALL
		(, bytes memory r) = address(this).call{gas: 100000}(abi.encodeWithSignature("updateInvocationCount(bytes4,bytes)", methodId, msg.data));
		assert(r.length == 0);
		
		assembly {
			return(add(0x20, result), mload(result))
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/AccessControl.sol";
import "../utils/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./BaseController.sol";

contract UniswapController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable UNISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Factory public immutable UNISWAP_FACTORY;

    constructor(
        IUniswapV2Router02 router,
        IUniswapV2Factory factory,
        address manager,
        address _addressRegistry
    ) public BaseController(manager, _addressRegistry) {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        UNISWAP_ROUTER = router;
        UNISWAP_FACTORY = factory;
    }

    /// @notice Deploys liq to Uniswap LP pool
    /// @dev Calls to external contract
    /// @param data Bytes containing token addrs, amounts, pool addr, dealine to interact with Uni router
    function deploy(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256)
            );

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        _approve(IERC20(tokenA), amountADesired);
        _approve(IERC20(tokenB), amountBDesired);

        IERC20 pair = IERC20(UNISWAP_FACTORY.getPair(tokenA, tokenB));
        uint256 balanceBefore = pair.balanceOf(address(this));

        //(uint256 amountA, uint256 amountB, uint256 liquidity) =
        UNISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        uint256 balanceAfter = pair.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");
    }

    /// @notice Withdraws liq from Uni LP pool
    /// @dev Calls to external contract
    /// @param data Bytes contains tokens addrs, amounts, liq, pool addr, dealine for Uni router
    function withdraw(bytes calldata data) external onlyManager {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256));

        require(to == manager, "MUST_BE_MANAGER");
        require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
        require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

        address pair = UNISWAP_FACTORY.getPair(tokenA, tokenB);
        require(pair != address(0), "pair doesn't exist");
        _approve(IERC20(pair), liquidity);

        IERC20 tokenAInterface = IERC20(tokenA);
        IERC20 tokenBInterface = IERC20(tokenB);
        uint256 tokenABalanceBefore = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceBefore = tokenBInterface.balanceOf(address(this));

        //(uint256 amountA, uint256 amountB) =
        UNISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        
        uint256 tokenABalanceAfter = tokenAInterface.balanceOf(address(this));
        uint256 tokenBBalanceAfter = tokenBInterface.balanceOf(address(this));
        require(tokenABalanceAfter > tokenABalanceBefore, "MUST_INCREASE");
        require(tokenBBalanceAfter > tokenBBalanceBefore, "MUST_INCREASE");
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(UNISWAP_ROUTER));
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(address(UNISWAP_ROUTER), currentAllowance);
        }
        token.safeIncreaseAllowance(address(UNISWAP_ROUTER), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BaseController.sol";

contract TransferController is BaseController {
    using SafeERC20 for IERC20;

    address public immutable treasuryAddress;

    constructor(
        address manager,
        address addressRegistry,
        address treasury
    ) public BaseController(manager, addressRegistry) {
        require(treasury != address(0), "INVALID_TREASURY_ADDRESS");
        treasuryAddress = treasury;
    }

    /// @notice Used to transfer funds to our treasury
    /// @dev Calls into external contract
    /// @param tokenAddress Address of IERC20 token
    /// @param amount amount of funds to transfer
    function transferFunds(address tokenAddress, uint256 amount) external onlyManager {
        require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
        require(amount > 0, "INVALID_AMOUNT");
        require(addressRegistry.checkAddress(tokenAddress, 0), "INVALID_TOKEN");
                
        IERC20(tokenAddress).safeTransfer(treasuryAddress, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *  @title Validates and distributes TOKE rewards based on the
 *  the signed and submitted payloads
 */
interface IRewards {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Recipient {
        uint256 chainId;
        uint256 cycle;
        address wallet;
        uint256 amount;
    }

    event SignerSet(address newSigner);
    event Claimed(uint256 cycle, address recipient, uint256 amount);

    /// @notice Get the underlying token rewards are paid in
    /// @return Token address
    function tokeToken() external view returns (IERC20);

    /// @notice Get the current payload signer;
    /// @return Signer address
    function rewardsSigner() external view returns (address);

    /// @notice Check the amount an account has already claimed
    /// @param account Account to check
    /// @return Amount already claimed
    function claimedAmounts(address account) external view returns (uint256);

    /// @notice Get the amount that is claimable based on the provided payload
    /// @param recipient Published rewards payload
    /// @return Amount claimable if the payload is signed
    function getClaimableAmount(Recipient calldata recipient) external view returns (uint256);

    /// @notice Change the signer used to validate payloads
    /// @param newSigner The new address that will be signing rewards payloads
    function setSigner(address newSigner) external;

    /// @notice Claim your rewards
    /// @param recipient Published rewards payload
    /// @param v v component of the payload signature
    /// @param r r component of the payload signature
    /// @param s s component of the payload signature
    function claim(
        Recipient calldata recipient,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

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

contract CurveControllerTemplate is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IAddressProvider public immutable addressProvider;

    uint256 public constant N_COINS = 2;

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
        uint256 amountsLength = amounts.length;

        for (uint256 i = 0; i < amountsLength; i++) {
            if (amounts[i] > 0) {
                address coin = IStableSwapPool(poolAddress).coins(i);

                require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

                uint256 balance = IERC20(coin).balanceOf(address(this));

                require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

                _approve(IERC20(coin), poolAddress, amounts[i]);
            }
        }

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
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

        IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
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

        require(lpTokenBalanceBefore - amount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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
        require(lpTokenBalanceBefore - tokenAmount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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

    function _getCoinsBalances(address poolAddress)
        internal
        returns (uint256[N_COINS] memory coinsBalances)
    {
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = IStableSwapPool(poolAddress).coins(i);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(
        uint256[N_COINS] memory balancesBefore,
        uint256[N_COINS] memory balancesAfter,
        uint256[N_COINS] memory amounts
    ) internal pure {
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
pragma solidity >=0.6.11;

interface IStableSwapPool {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[4] memory amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts)
        external
        returns (uint256[3] memory);

    function remove_liquidity(uint256 amount, uint256[4] memory min_amounts)
        external
        returns (uint256[4] memory);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

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

contract CurveController4 is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IAddressProvider public immutable addressProvider;

    uint256 public constant N_COINS = 4;

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
        uint256 amountsLength = amounts.length;

        for (uint256 i = 0; i < amountsLength; i++) {
            if (amounts[i] > 0) {
                address coin = IStableSwapPool(poolAddress).coins(i);

                require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

                uint256 balance = IERC20(coin).balanceOf(address(this));

                require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

                _approve(IERC20(coin), poolAddress, amounts[i]);
            }
        }

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
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

        IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
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

        require(lpTokenBalanceBefore - amount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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
        require(lpTokenBalanceBefore - tokenAmount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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

    function _getCoinsBalances(address poolAddress)
        internal
        returns (uint256[N_COINS] memory coinsBalances)
    {
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = IStableSwapPool(poolAddress).coins(i);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(
        uint256[N_COINS] memory balancesBefore,
        uint256[N_COINS] memory balancesAfter,
        uint256[N_COINS] memory amounts
    ) internal pure {
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
        uint256 amountsLength = amounts.length;

        for (uint256 i = 0; i < amountsLength; i++) {
            if (amounts[i] > 0) {
                address coin = IStableSwapPool(poolAddress).coins(i);

                require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

                uint256 balance = IERC20(coin).balanceOf(address(this));

                require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

                _approve(IERC20(coin), poolAddress, amounts[i]);
            }
        }

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
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

        IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
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

        require(lpTokenBalanceBefore - amount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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
        require(lpTokenBalanceBefore - tokenAmount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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

    function _getCoinsBalances(address poolAddress)
        internal
        returns (uint256[N_COINS] memory coinsBalances)
    {
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = IStableSwapPool(poolAddress).coins(i);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(
        uint256[N_COINS] memory balancesBefore,
        uint256[N_COINS] memory balancesAfter,
        uint256[N_COINS] memory amounts
    ) internal pure {
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

contract CurveController2 is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IAddressProvider public immutable addressProvider;

    uint256 public constant N_COINS = 2;

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
        uint256 amountsLength = amounts.length;

        for (uint256 i = 0; i < amountsLength; i++) {
            if (amounts[i] > 0) {
                address coin = IStableSwapPool(poolAddress).coins(i);

                require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

                uint256 balance = IERC20(coin).balanceOf(address(this));

                require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

                _approve(IERC20(coin), poolAddress, amounts[i]);
            }
        }

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        IStableSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
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

        IStableSwapPool(poolAddress).remove_liquidity_imbalance(amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
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

        require(lpTokenBalanceBefore - amount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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
        require(lpTokenBalanceBefore - tokenAmount == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
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

    function _getCoinsBalances(address poolAddress)
        internal
        returns (uint256[N_COINS] memory coinsBalances)
    {
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = IStableSwapPool(poolAddress).coins(i);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(
        uint256[N_COINS] memory balancesBefore,
        uint256[N_COINS] memory balancesAfter,
        uint256[N_COINS] memory amounts
    ) internal pure {
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
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseController.sol";
import "../interfaces/convex/IConvexBooster.sol";
import "../interfaces/convex/IConvexBaseReward.sol";
import "../interfaces/convex/ConvexPoolInfo.sol";

contract ConvexController is BaseController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IConvexBooster public immutable BOOSTER;

    struct ExpectedReward {
        address token;
        uint256 minAmount;
    }

    constructor(
        address _manager,
        address _addressRegistry,
        address _convexBooster
    ) public BaseController(_manager, _addressRegistry) {
        require(_convexBooster != address(0), "INVALID_BOOSTER_ADDRESS");

        BOOSTER = IConvexBooster(_convexBooster);
    }

    /// @notice deposits and stakes Curve LP tokens to Convex
    /// @param lpToken Curve LP token to deposit
    /// @param staking Convex reward contract associated with the Curve LP token
    /// @param poolId Convex poolId for the associated Curve LP token
    /// @param amount Quantity of Curve LP token to deposit and stake
    function depositAndStake(
        address lpToken,
        address staking,
        uint256 poolId,
        uint256 amount
    ) external onlyManager {
        require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
        require(staking != address(0), "INVALID_STAKING_ADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        ConvexPoolInfo memory poolInfo = BOOSTER.poolInfo(poolId);
        require(lpToken == poolInfo.lptoken, "POOL_ID_LP_TOKEN_MISMATCH");
        require(staking == poolInfo.crvRewards, "POOL_ID_STAKING_MISMATCH");

        _approve(IERC20(lpToken), amount);

        uint256 beforeBalance = IConvexBaseRewards(staking).balanceOf(address(this));

        bool success = BOOSTER.deposit(poolId, amount, true);
        require(success, "DEPOSIT_AND_STAKE_FAILED");

        uint256 balanceChange = IConvexBaseRewards(staking).balanceOf(address(this)).sub(
            beforeBalance
        );
        require(balanceChange == amount, "BALANCE_MUST_INCREASE");
    }

    /// @notice withdraws a Curve LP token from Convex
    /// @dev does not claim available rewards
    /// @param lpToken Curve LP token to withdraw
    /// @param staking Convex reward contract associated with the Curve LP token
    /// @param amount Quantity of Curve LP token to withdraw
    function withdrawStake(
        address lpToken,
        address staking,
        uint256 amount
    ) external onlyManager {
        require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
        require(staking != address(0), "INVALID_STAKING_ADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        uint256 beforeBalance = IERC20(lpToken).balanceOf(address(this));

        bool success = IConvexBaseRewards(staking).withdrawAndUnwrap(amount, false);
        require(success, "WITHDRAW_STAKE_FAILED");

        uint256 balanceChange = IERC20(lpToken).balanceOf(address(this)).sub(beforeBalance);
        require(balanceChange == amount, "BALANCE_MUST_INCREASE");
    }

    /// @notice claims all Convex rewards associated with the target Curve LP token
    /// @param staking Convex reward contract associated with the Curve LP token
    /// @param expectedRewards List of expected reward tokens and min amounts to receive on claim
    function claimRewards(address staking, ExpectedReward[] memory expectedRewards)
        external
        onlyManager
    {
        require(staking != address(0), "INVALID_STAKING_ADDRESS");
        require(expectedRewards.length > 0, "INVALID_EXPECTED_REWARDS");

        uint256[] memory beforeBalances = new uint256[](expectedRewards.length);

        for (uint256 i = 0; i < expectedRewards.length; i++) {
            require(expectedRewards[i].token != address(0), "INVALID_REWARD_TOKEN_ADDRESS");
            require(expectedRewards[i].minAmount > 0, "INVALID_MIN_REWARD_AMOUNT");
            beforeBalances[i] = IERC20(expectedRewards[i].token).balanceOf(address(this));
        }

        bool success = IConvexBaseRewards(staking).getReward();
        require(success, "CLAIM_REWARD_FAILED");

        for (uint256 i = 0; i < expectedRewards.length; i++) {
            uint256 balanceChange = IERC20(expectedRewards[i].token).balanceOf(address(this)).sub(
                beforeBalances[i]
            );
            require(balanceChange > expectedRewards[i].minAmount, "BALANCE_MUST_INCREASE");
        }
    }

    function _approve(IERC20 token, uint256 amount) internal {
        address spender = address(BOOSTER);
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(spender, currentAllowance);
        }
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./ConvexPoolInfo.sol";

//main Convex contract(booster.sol) basic interface
interface IConvexBooster {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    //get poolInfo for a poolId
    function poolInfo(uint256 _pid) external returns (ConvexPoolInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IConvexBaseRewards {
    //get balance of an address
    function balanceOf(address _account) external returns (uint256);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

    //claim rewards
    function getReward() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

struct ConvexPoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
}