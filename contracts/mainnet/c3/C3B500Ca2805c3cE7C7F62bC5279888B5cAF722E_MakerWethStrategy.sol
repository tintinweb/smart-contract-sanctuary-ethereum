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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {VaultAPI} from "../../interfaces/vault/VaultAPI.sol";

library StrategyLib {
    using SafeMath for uint256;

    function internalHarvestTrigger(
        address vault,
        address strategy,
        uint256 callCost,
        uint256 minReportDelay,
        uint256 maxReportDelay,
        uint256 debtThreshold,
        uint256 profitFactor
    ) public view returns (bool) {
        StrategyParams memory params = VaultAPI(vault).strategies(strategy);
        // Should not trigger if Strategy is not activated
        if (params.activation == 0) {
            return false;
        }

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp.sub(params.lastReport) < minReportDelay) return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = VaultAPI(vault).debtOutstanding();

        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = StrategyAPI(strategy).estimatedTotalAssets();

        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt);
        // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = VaultAPI(vault).creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    function internalSetRewards(
        address oldRewards,
        address newRewards,
        address vault
    ) public {
        require(newRewards != address(0));
        VaultAPI(vault).approve(oldRewards, 0);
        VaultAPI(vault).approve(newRewards, type(uint256).max);
    }
}

// File: StrategyLib.sol

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

/**
 * @title Base Strategy
 * @author Everbloom
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
    using SafeMath for uint256;
    string public metadataURI;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.3";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of the ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    modifier onlyEmergencyAuthorized() {
        _onlyEmergencyAuthorized();
        _;
    }

    modifier onlyStrategist() {
        _onlyStrategist();
        _;
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    modifier onlyRewarder() {
        _onlyRewarder();
        _;
    }

    modifier onlyKeepers() {
        _onlyKeepers();
        _;
    }

    function _onlyAuthorized() internal view {
        require(msg.sender == strategist || msg.sender == _governance());
    }

    function _onlyEmergencyAuthorized() internal view {
        require(
            msg.sender == strategist ||
                msg.sender == _governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    function _onlyStrategist() internal view {
        require(msg.sender == strategist);
    }

    function _onlyGovernance() internal view {
        require(msg.sender == _governance());
    }

    function _onlyRewarder() internal view {
        require(msg.sender == _governance() || msg.sender == strategist);
    }

    function _onlyKeepers() internal view {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == _governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    constructor(address _vault) {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        SafeERC20.safeApprove(want, _vault, type(uint256).max);
        // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, type(uint256).max);
        // Allow rewards to be pulled
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyRewarder {
        address oldRewards = rewards;
        rewards = _rewards;
        StrategyLib.internalSetRewards(oldRewards, _rewards, address(vault));
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function _governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 180000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function _adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */

    function _liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss".
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    // solhint-disable-next-line no-unused-vars
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        // If your implementation uses the cost of the call in want, you can
        // use uint256 callCost = ethToWant(callCostInWei);

        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        _adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss".
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        return
            StrategyLib.internalHarvestTrigger(
                address(vault),
                address(this),
                ethToWant(callCostInWei),
                minReportDelay,
                maxReportDelay,
                debtThreshold,
                profitFactor
            );
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = _liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = _prepareReturn(debtOutstanding);
        }

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        _adjustPosition(debtOutstanding);

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = _liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        SafeERC20.safeTransfer(want, msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function _prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        _prepareMigration(_newStrategy);
        SafeERC20.safeTransfer(want, _newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function _protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory protectedTokens = _protectedTokens();
        for (uint256 i; i < protectedTokens.length; i++) require(_token != protectedTokens[i], "!protected");

        SafeERC20.safeTransfer(IERC20(_token), _governance(), IERC20(_token).balanceOf(address(this)));
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;

    event Cloned(address indexed clone);

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function clone(address _vault) external returns (address) {
        return this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        require(isOriginal, "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

        emit Cloned(newStrategy);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {BaseStrategy} from "./BaseStrategy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IDssCdpManager} from "../../interfaces/maker/IDssCdpManager.sol";
import {IGemJoin} from "../../interfaces/maker/IGemJoin.sol";
import {IDaiJoin} from "../../interfaces/maker/IDaiJoin.sol";
import {IJug} from "../../interfaces/maker/IJug.sol";
import {IVat} from "../../interfaces/maker/IVat.sol";
import {ISpot} from "../../interfaces/maker/ISpot.sol";
import {VaultAPI} from "../../interfaces/vault/VaultAPI.sol";
import {IUniswapV2Router01} from "../../interfaces/uniswap/IUniswapV2Router01.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MakerWethStrategy is BaseStrategy {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant _WAD = 1e18;
    uint256 internal constant _RAY = 1e27;
    // 100%, or _WAD basis points
    uint256 internal constant _MAX_BPS = _WAD;
    string internal _strategyName;
    uint256 public cdpId;
    bytes32 public ilk;
    uint256 public dust;
    uint256 public idealCollRatio;
    uint256 public liquidationRatio;
    uint256 public deltaRatioPercentage = 1e25; // 1% in basis points in ray (100% = 1e27 = 1 RAY)
    address public urnHandler;
    ISpot public spot;
    // Wrapped Ether - Used for swaps routing
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IGemJoin public gemJoin;

    // Maximum acceptable loss on DAI vault withdrawal. Default to 0.01%.
    uint256 public maxLoss;

    VaultAPI public daiVault;

    IDssCdpManager internal constant _DSS_CDP_MANAGER = IDssCdpManager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    IDaiJoin internal constant _DAI_JOIN = IDaiJoin(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
    IJug internal constant _JUG = IJug(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    IVat internal constant _VAT = IVat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    IERC20 internal constant _DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint256 internal constant _MAX_LOSS_BPS = 10000;
    IUniswapV2Router01 internal constant _UNISWAPROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event Cloned(address indexed clone);
    event CdpUpdated(uint256 virtualNextCollRatio, uint256 updatedCollRatio);

    /**
     * @notice
     *  All precise quantities e.g. ratios have a _RAY denomination
     *  All basic quantities e.g. balances have a _WAD denomination
     */
    constructor(
        address _vault,
        string memory strategyName,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) BaseStrategy(_vault) {
        _initializeStrat(strategyName, _ilk, _spot, _gemJoin, _daiVault);
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        string memory _name,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) external {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(_name, _ilk, _spot, _gemJoin, _daiVault);
    }

    function _initializeStrat(
        string memory strategyName,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) internal {
        require(idealCollRatio == 0, "Already Initialized");
        _strategyName = strategyName;
        ilk = _ilk;
        cdpId = _DSS_CDP_MANAGER.open(ilk, address(this));
        require(cdpId > 0, "Bad cdp id");
        urnHandler = _DSS_CDP_MANAGER.urns(cdpId);
        spot = ISpot(_spot);
        gemJoin = IGemJoin(_gemJoin);
        (, liquidationRatio) = spot.ilks(ilk);
        (, , , , dust) = _VAT.ilks(ilk);

        daiVault = VaultAPI(_daiVault);
        // Approve gemJoin to spend want tokens
        IERC20(vault.token()).safeApprove(address(gemJoin), type(uint256).max);

        idealCollRatio = 2100000000000000000000000000; // ray

        // Define maximum acceptable loss on withdrawal to be 0.01%.
        maxLoss = 1;

        // Allow DAI vault and DAIJOIN to spend DAI tokens
        _DAI.safeApprove(address(daiVault), type(uint256).max);
        _DAI.safeApprove(address(_DAI_JOIN), type(uint256).max);

        // Allow the _DAI_JOIN contract to modify the VAT DAI balance of the strategy
        _VAT.hope(address(_DAI_JOIN));
    }

    function cloneMakerWethStrategy(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        string memory _name,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) external returns (address payable newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        MakerWethStrategy(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _name,
            _ilk,
            _spot,
            _gemJoin,
            _daiVault
        );

        emit Cloned(newStrategy);
    }

    function name() external view override returns (string memory) {
        return _strategyName;
    }

    function updateCollateralizationRatio(uint256 _collateralizationRatio) public onlyAuthorized {
        require(_collateralizationRatio > liquidationRatio, "Can't go below liquidation ratio");
        idealCollRatio = _collateralizationRatio;
    }

    function updateDeltaCollRatio(uint256 _deltaRatioPercentage) public onlyAuthorized {
        deltaRatioPercentage = _deltaRatioPercentage;
    }

    function updateMaxLoss(uint256 _maxLoss) external onlyAuthorized {
        require(_maxLoss <= _MAX_LOSS_BPS, "Can't set maxLoss higher than 100%");
        maxLoss = _maxLoss;
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 allDaiInWant = daiToWant(daiTokensInStrategy().add(daiTokensInEbVault()));
        uint256 allAssets = want.balanceOf(address(this)).add(collateralInCdp()).add(allDaiInWant);
        uint256 allDebtInWant = daiToWant(debtInCdp());
        return allAssets.sub(allDebtInWant);
    }

    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _debtPayment = _debtOutstanding;
        uint256 debtToVault = vault.strategies(address(this)).totalDebt;
        _takeDaiVaultProfit();
        uint256 currentValue = estimatedTotalAssets();

        _profit = currentValue > debtToVault ? currentValue.sub(debtToVault) : 0;
        _loss = debtToVault > currentValue ? debtToVault.sub(currentValue) : 0;

        uint256 toFree = _debtPayment.add(_profit);
        uint256 _withdrawalLoss;

        if (toFree > 0) {
            (, _withdrawalLoss) = _liquidatePosition(toFree);

            if (_withdrawalLoss < _profit) {
                _profit = _profit.sub(_withdrawalLoss);
            } else {
                _loss = _loss.add(_withdrawalLoss.sub(_profit));
                _profit = 0;
            }

            uint256 wantBalance = want.balanceOf(address(this));

            if (wantBalance > _profit && wantBalance < _debtPayment.add(_profit)) {
                _debtPayment = wantBalance.sub(_profit);
            }
        }
    }

    function _liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // If we can pay with available want balance, we do
        uint256 wantBalanceBefore = want.balanceOf(address(this));

        if (wantBalanceBefore >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        uint256 amountToLiquidate = _amountNeeded.sub(wantBalanceBefore); // wad
        uint256 amountAvailable = collateralInCdp(); // wad
        // If we don't have enough collateral available, we have to report a loss and liquidate what is available
        amountToLiquidate = Math.min(amountToLiquidate, amountAvailable);
        // By liquidating we adjust the collateralization ratio of our cdp and have to account for this
        uint256 _debtInCdp = debtInCdp(); // wad
        uint256 wantPrice = wantPriceUsd(); // wad
        uint256 amountAvailableUsd = amountAvailable.mul(wantPrice).div(_WAD); // wad
        uint256 amountToLiquidateUsd = amountToLiquidate.mul(wantPrice).div(_WAD); // wad

        if (_debtInCdp > 0) {
            uint256 newCollateralizationRatio = amountAvailableUsd.sub(amountToLiquidateUsd).mul(_RAY).div(_debtInCdp); // ray

            // Assess how much DAI we need to repay in order to keep a healthy collateralization ratio after withdrawing collateral
            _payOffDebt(newCollateralizationRatio);
        }

        // Unlock collateral from the urn and move it back to the strategy
        amountToLiquidate = Math.min(amountToLiquidate, _maxCollLiquidation());
        _freeAndMoveCollateral(amountToLiquidate);

        // Our want balance should now cover the amount we need. If not, we have to report a loss
        uint256 diff = want.balanceOf(address(this)).sub(wantBalanceBefore);

        return diff > amountToLiquidate ? (amountToLiquidate, 0) : (diff, amountToLiquidate.sub(diff));
    }

    function _payOffDebt(uint256 newCollRatio) internal {
        uint256 delta = idealCollRatio.mul(deltaRatioPercentage).div(_MAX_BPS.mul(1e9));
        if (newCollRatio.add(delta) > idealCollRatio) {
            return;
        }
        uint256 debt = debtInCdp(); // wad
        uint256 healthyDebt = newCollRatio.mul(debt).div(idealCollRatio); // wad
        uint256 daiToPayOff;
        uint256 daiBalance = daiTokensInStrategy();
        // Withdraw dai from DaiVault
        if (healthyDebt <= dust.div(_RAY)) {
            // Pay off whole debt if we can, pay off just above the debtfloor (1 wad) otherwise
            uint256 totalAvailableDai = daiBalance.add(daiTokensInEbVault());
            daiToPayOff = totalAvailableDai >= debt ? debt : debt.sub(dust.div(_RAY)).sub(_WAD);
        } else {
            daiToPayOff = debt.sub(healthyDebt);
        }
        if (daiToPayOff > daiBalance) {
            uint256 vaultSharesToWithdraw = Math.min(
                daiToPayOff.sub(daiBalance).mul(_WAD).div(daiVault.pricePerShare()),
                daiVault.balanceOf(address(this))
            );
            if (vaultSharesToWithdraw > 0) {
                daiVault.withdraw(vaultSharesToWithdraw, address(this), maxLoss);
            }
        }

        _wipe(daiToPayOff);
    }

    function _wipe(uint256 amount) private {
        uint256 daiBalance = _DAI.balanceOf(address(this));

        // We cannot payoff more debt then we have
        amount = Math.min(amount, daiBalance);

        uint256 debt = debtInCdp();
        // We cannot payoff more debt then we owe
        amount = Math.min(amount, debt);

        if (amount > 0) {
            // When repaying the full debt it is very common to experience Vat/dust
            // reverts due to the debt being non-zero and less than (or equal to) the debt floor.
            // This can happen due to rounding
            // To circumvent this issue we will add 1 Wei to the amount to be paid
            // if there is enough investment token balance (DAI) to do it.
            if (debt.sub(amount) == 0 && daiBalance.sub(amount) >= 1) {
                amount = amount.add(1);
            }

            // Joins DAI amount into the vat and burns the amount from the callers address
            _DAI_JOIN.join(urnHandler, amount);
            // Paybacks debt to the CDP with the provided DAI in the vat
            _DSS_CDP_MANAGER.frob(cdpId, 0, _getWipeDart(urnHandler, _VAT.dai(urnHandler)));
        }
    }

    function _getWipeDart(address urn, uint256 dai) internal view returns (int256 dart) {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = _VAT.ilks(ilk);
        // Gets actual art value of the urn
        (, uint256 art) = _VAT.urns(ilk, urn);

        // Uses the whole dai balance in the vat to reduce the debt
        dart = int256(dai.div(rate));

        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint256(dart) <= art ? -dart : -int256(art);
    }

    function _maxCollLiquidation() internal view returns (uint256) {
        uint256 amountAvailable = collateralInCdp(); // wad
        uint256 _debtInCdp = debtInCdp(); // wad
        if (_debtInCdp == 0) {
            return amountAvailable;
        }

        uint256 collateralPrice = wantPriceUsd(); // wad
        // Allow the liquidation of collateral te be 10% above the liquidation ratio
        uint256 deltaLiqRatioPercentage = (10 * _RAY).div(100);

        uint256 minCollAmount = liquidationRatio.add(deltaLiqRatioPercentage).mul(_debtInCdp).div(collateralPrice).div(
            1e9
        ); // wad

        // If we are under collateralized then it is not safe for us to withdraw anything
        return minCollAmount > amountAvailable ? 0 : amountAvailable.sub(minCollAmount);
    }

    function _liquidateAllPositions() internal override returns (uint256 _amountFreed) {
        (_amountFreed, ) = _liquidatePosition(1e36);
        // we can request a lot. dont use max because of overflow
    }

    function ethToWant(uint256 _amtInWei) public view override returns (uint256) {
        return _amtInWei;
    }

    function daiToWant(uint256 _daiAmount) public view returns (uint256) {
        return _daiAmount.mul(_WAD).div(wantPriceUsd());
    }

    // solhint-disable-next-line no-unused-vars
    function _adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 _wantToInvest = want.balanceOf(address(this));
        if (_wantToInvest == 0) {
            return;
        }

        // Calculate the amount of DAI we want to mint
        uint256 _dart = _calculateDaiAmount(_wantToInvest);
        if (_dart.add(debtInCdp()) <= dust.div(_RAY)) {
            return;
        }

        // Deposit collateral in the VAT
        _depositCollateral(_wantToInvest);
        // Mint DAI against collateral amount
        _mintAndMoveDai(_wantToInvest, _dart);
        daiVault.deposit();
    }

    function _prepareMigration(address _newStrategy) internal override {
        IERC20(daiVault).safeTransfer(_newStrategy, daiVault.balanceOf(address(this)));
        _DAI.safeTransfer(_newStrategy, daiTokensInStrategy());

        // Move ownership to the new strategy. This does NOT move any funds
        _DSS_CDP_MANAGER.give(cdpId, _newStrategy);
    }

    /**
     * @notice
     *  Move collateral and debt to another CDP(urn)
     * @dev
     *  The strategy calling this function, needs to have ownership over both the old and new cdp ids
     *  This function should only be called after migration is done since ownership is moved there
     * @param oldCdpId The CDP ID of the old strategy's urn
     */
    function shiftToCdp(uint256 oldCdpId) external onlyGovernance {
        _DSS_CDP_MANAGER.shift(oldCdpId, cdpId);
    }

    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(daiVault);
        protected[1] = address(_DAI);
        return protected;
    }

    // Deposits want into the vat contract
    function _depositCollateral(uint256 _collateralAmount) internal {
        gemJoin.join(urnHandler, _collateralAmount);
    }

    /**
     * @notice
     *  Step 1: Locks collateral into the urn and generates debt against it
     *  Step 2: move DAI to the strategy and mint ERC20 DAI tokens
        The strategies DAI balance should have been increased after minting DAI
     * @param _dink collateral to lock
     * @param _dart DAI in wad to generate as debt and to mint as ERC20
     */
    function _mintAndMoveDai(uint256 _dink, uint256 _dart) internal {
        // Lock collateral & generate DAI
        int256 daiToMintMinusRate = _getDrawDart(urnHandler, _dart);
        _DSS_CDP_MANAGER.frob(cdpId, int256(_dink), daiToMintMinusRate);

        // Move assets from the urn to the strategy
        _DSS_CDP_MANAGER.move(cdpId, address(this), _dart.mul(_RAY));

        // Mint DAI ERC20 tokens for the strategy by decreasing its DAI balance in the VAT contract
        _DAI_JOIN.exit(address(this), _dart);
    }

    function _getDrawDart(address urn, uint256 wad) internal returns (int256 dart) {
        // Updates stability fee rate
        uint256 rate = _JUG.drip(ilk); // ray

        // Gets DAI balance of the urn in the vat
        uint256 dai = _VAT.dai(urn); // rad

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < wad.mul(_RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = int256(wad.mul(_RAY).sub(dai).div(rate)); // wad
            // This is needed due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = uint256(dart).mul(rate) < wad.mul(_RAY) ? dart + 1 : dart; // wad
        }
    }

    // Adjusted from 'freeGem' in dssProxyActions.sol. Unlocks collateral and moves it to the strategy.
    function _freeAndMoveCollateral(uint256 _dink) internal {
        // Unlocks token amount from the CDP
        _DSS_CDP_MANAGER.frob(cdpId, -int256(_dink), 0);
        // Moves the amount from the CDP urn to proxy's address
        _DSS_CDP_MANAGER.flux(cdpId, address(this), _dink);
        // Exits token amount to the strategy as a token
        gemJoin.exit(address(this), _dink);
    }

    function wantPriceUsd() public view returns (uint256) {
        (, , uint256 spotPrice, , ) = _VAT.ilks(ilk); // ray
        return spotPrice.mul(liquidationRatio).div(_RAY * 1e9); // wad
    }

    function collateralInCdp() public view returns (uint256) {
        (uint256 collateral, ) = _VAT.urns(ilk, urnHandler);
        return collateral; // wad
    }

    function debtInCdp() public view returns (uint256) {
        (, uint256 debt) = _VAT.urns(ilk, urnHandler); // wad
        (, uint256 rate, , , ) = _VAT.ilks(ilk); // ray
        return debt.mul(rate).div(_RAY); // wad
    }

    /**
     * @notice
     *  Calculates the amount of DAI we can mint for a given collateral amount
     * @param _collateralAmount The amount of collateral tokens to mint dai debt against
     * @return
     *  the amount of DAI to mint in wad
     */
    function _calculateDaiAmount(uint256 _collateralAmount) internal view returns (uint256) {
        uint256 collateralPrice = wantPriceUsd(); // wad

        // dai to mint in wad = wad * wad * wad / (ray * 1e9)
        return _collateralAmount.mul(collateralPrice).mul(_MAX_BPS).div(idealCollRatio * 1e9); // wad
    }

    /**
     * @notice
     *  Calculates the amount of DAI we can mint for a new coll ratio within our current position
     * @param collRatio The collateralization ratio used to determine the amount of DAI to mint
     * @return
     *  the amount of DAI to mint in wad
     */
    function _calculateDaiToMint(uint256 collRatio) internal view returns (uint256) {
        // We need to use Math.max here to prevent underflow errors
        uint256 newCollRatio = Math.max(collRatio, idealCollRatio);
        return newCollRatio.mul(debtInCdp()).div(idealCollRatio).sub(debtInCdp()); // wad
    }

    function daiTokensInEbVault() public view returns (uint256) {
        uint256 balance = daiVault.balanceOf(address(this));
        if (daiVault.totalSupply() == 0) {
            // Needed because of revert on priceperfullshare if 0
            return 0;
        }
        uint256 pricePerShare = daiVault.pricePerShare();
        // dai tokens are 1e18 decimals
        return balance.mul(pricePerShare).div(1e18);
    }

    function daiTokensInStrategy() public view returns (uint256) {
        return _DAI.balanceOf(address(this));
    }

    function _daiToDaiVaultShares(uint256 amount) internal view returns (uint256) {
        return amount.mul(10**daiVault.decimals()).div(daiVault.pricePerShare());
    }

    function currentCollateralRatio() public view returns (uint256) {
        uint256 collateralPrice = wantPriceUsd();
        return calculateCollRatio(collateralInCdp(), debtInCdp(), collateralPrice); // rad
    }

    function calculateCollRatio(
        uint256 collateralAmount,
        uint256 debt,
        uint256 wantPrice
    ) public pure returns (uint256) {
        uint256 collateralInUsd = collateralAmount.mul(wantPrice).div(_WAD);
        return collateralInUsd.mul(_RAY).div(debt); // ray
    }

    /**
     * @notice
     *  Updates the collateralization ratio to ensure a healthy position for the next price snapshot
     * @dev
     *  MakerDAO updates the usd price of collateral every hour
     *  we need to prepare the strategy to prevent liquidation by minting extra DAI
     *  or by repaying debt based on the new collateralization ratio
     * @param newWantPrice The price of the collateral(want) token in the next snapshot in WAD
     */
    function updateCdpRatio(uint256 newWantPrice) external onlyKeepers {
        uint256 newCollRatio = calculateCollRatio(collateralInCdp(), debtInCdp(), newWantPrice); // ray
        if (newCollRatio < liquidationRatio) {
            _payOffDebt(newCollRatio);
        } else {
            uint256 delta = idealCollRatio.mul(deltaRatioPercentage).div(_RAY);
            require(newCollRatio > idealCollRatio.add(delta), "The new collateralization ratio is too low");
            uint256 daiToMint = _calculateDaiToMint(newCollRatio);
            uint256 expectedCollRatioAfterDaiMint = calculateCollRatio(
                collateralInCdp(),
                debtInCdp().add(daiToMint),
                wantPriceUsd()
            );
            require(expectedCollRatioAfterDaiMint > liquidationRatio, "Can't go below liquidation ratio");
            _mintAndMoveDai(0, daiToMint);
            daiVault.deposit();
        }
        emit CdpUpdated(newCollRatio, currentCollateralRatio());
    }

    function _takeDaiVaultProfit() internal {
        uint256 _debt = debtInCdp();
        uint256 _valueInVault = daiTokensInEbVault();
        if (_debt >= _valueInVault) {
            return;
        }

        uint256 profit = _valueInVault.sub(_debt);
        uint256 daiVaultSharesToWithdraw = _daiToDaiVaultShares(profit);
        if (daiVaultSharesToWithdraw > 0) {
            daiVault.withdraw(daiVaultSharesToWithdraw);
            _sellAForB(daiTokensInStrategy(), address(_DAI), address(want));
        }
    }

    function _sellAForB(
        uint256 _amount,
        address tokenA,
        address tokenB
    ) internal {
        if (_amount == 0 || tokenA == tokenB) {
            return;
        }

        _checkAllowance(address(_UNISWAPROUTER), tokenA, _amount);
        _UNISWAPROUTER.swapExactTokensForTokens(
            _amount,
            0,
            _getTokenOutPath(tokenA, tokenB),
            address(this),
            block.timestamp
        );
    }

    function _getTokenOutPath(address _tokenIn, address _tokenOut) internal pure returns (address[] memory _path) {
        bool isWeth = _tokenIn == address(_WETH) || _tokenOut == address(_WETH);
        _path = new address[](isWeth ? 2 : 3);
        _path[0] = _tokenIn;

        if (isWeth) {
            _path[1] = _tokenOut;
        } else {
            _path[1] = address(_WETH);
            _path[2] = _tokenOut;
        }
    }

    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _contract) < _amount) {
            IERC20(_token).safeApprove(_contract, 0);
            IERC20(_token).safeApprove(_contract, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IDaiJoin {
    function exit(address usr, uint256 wad) external;

    function join(address, uint256) external payable;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IDssCdpManager {
    function open(bytes32, address) external returns (uint256);

    function urns(uint256) external view returns (address);

    function owns(uint256) external returns (address);

    function frob(
        uint256,
        int256,
        int256
    ) external;

    function move(
        uint256 cdp,
        address dst,
        uint256 rad
    ) external;

    function flux(
        uint256,
        address,
        uint256
    ) external;

    function quit(uint256 cdp, address dst) external;

    function urnAllow(address usr, uint256 ok) external;

    function give(uint256 cdp, address dst) external;

    function shift(uint256 cdpSrc, uint256 cdpDst) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IGemJoin {
    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IJug {
    function drip(bytes32) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ISpot {
    function ilks(bytes32) external view returns (address, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IVat {
    function dai(address) external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function hope(address usr) external;

    function urns(bytes32, address) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {StrategyParams} from "../../contracts/strategy/BaseStrategy.sol";

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}