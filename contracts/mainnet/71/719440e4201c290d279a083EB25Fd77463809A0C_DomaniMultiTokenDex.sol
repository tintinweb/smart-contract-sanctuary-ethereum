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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDomaniMultiTokenDex} from "./interfaces/IDomaniMultiTokenDex.sol";
import {IWNative} from "./interfaces/IWNative.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ExplicitERC20} from "../lib/ExplicitERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {DelegateCall} from "./lib/DelegateCall.sol";
import {PreciseUnitMath} from "../lib/PreciseUnitMath.sol";
import {DomaniDexConstants} from "./lib/DomaniDexConstants.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DomaniMultiTokenDex
 * @author Domani Protocol
 *
 * DomaniMultiTokenDex is a smart contract used to swap generic native/ERC20 with multi tokens
 * and multi tokens for a generic native/ERC20
 *
 */
contract DomaniMultiTokenDex is IDomaniMultiTokenDex, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address payable;
  using DelegateCall for address;
  using PreciseUnitMath for uint256;

  struct TempBuyArgs {
    bool isNativeInput;
    uint256 startingAmount;
    uint256 remainingInputAmount;
    Swap swap;
    bool isNativeOutput;
    address dexAddress;
    SwapParams swapParams;
    bytes result;
    ReturnValues returnValues;
    SwapToken[] tokensBought;
  }

  struct TempSellArgs {
    bool isNativeOutput;
    Swap swap;
    bool isNativeInput;
    address dexAddress;
    SwapParams swapParams;
    bytes result;
    ReturnValues returnValues;
    SwapToken[] tokensSold;
  }

  string private constant EXACT_INPUT_SIG =
    "swapExactInput(bytes,(uint256,uint256,bytes,bool,uint256,address))";

  string private constant EXACT_OUTPUT_SIG =
    "swapExactOutput(bytes,(uint256,uint256,bytes,bool,uint256,address))";

  IWNative public immutable override wNative;

  mapping(bytes32 => Implementation) private idToImplementation;

  uint64 fee;

  address feeRecipient;

  /**
   * Set initial variables
   * @param _wNative Wrapper of the native token of the blockchain
   * @param _owner Owner of the dex
   * @param _fee Fee precentage
   * @param _feeRecipient Recipient address to which receives fees
   */
  constructor(
    IWNative _wNative,
    address _owner,
    uint64 _fee,
    address _feeRecipient
  ) {
    wNative = _wNative;
    transferOwnership(_owner);
    _setFee(_fee);
    _setFeeRecipient(_feeRecipient);
  }

  receive() external payable {}

  /**
   * Register the specific implementation for a dex by owner
   * @param _identifier Name of dex identifier to register
   * @param _dexAddr Address of the dex implementation to register
   * @param _dexInfo Specific info of the dex that will be used in the swaps
   */
  function registerImplementation(
    string calldata _identifier,
    address _dexAddr,
    bytes calldata _dexInfo
  ) external onlyOwner() {
    require(_dexAddr != address(0), "Implementation address can not be the 0x00");
    Implementation storage implementation = idToImplementation[keccak256(abi.encode(_identifier))];
    implementation.dexAddr = _dexAddr;
    implementation.dexInfo = _dexInfo;
    emit ImplementationRegistered(_identifier, _dexAddr, _dexInfo);
  }

  /**
   * Remove a registered implementation
   * @param _identifier Name of dex identifier to remove
   */
  function removeImplementation(string calldata _identifier) external onlyOwner() {
    bytes32 identifierHash = keccak256(abi.encode(_identifier));
    require(
      idToImplementation[identifierHash].dexAddr != address(0),
      "Implementation with this id is not registered"
    );
    delete idToImplementation[identifierHash];
    emit ImplementationRemoved(_identifier);
  }

  /**
   * Set fee perecentage by owner
   * @param _newFee Fee percentage
   */
  function setFee(uint64 _newFee) external onlyOwner {
    _setFee(_newFee);
  }

  /**
   * Set fee recipient that receives tokens generated by the fees
   * @param _feeRecipient Address to which receive tokens
   */
  function setFeeRecipient(address _feeRecipient) external onlyOwner {
    _setFeeRecipient(_feeRecipient);
  }

  /**
   * Swap a generic ERC20/native token for a quantity of multi tokens
   * @param _inputMultiTokenDexParams See InputDexParams in IDomaniMultiTokenDex
   * @return inputAmountUsed Amount of the token used for buying the multi tokens
   * @return feeAmount Amount of fees paid for the swap
   */
  function buyMultiToken(InputMultiTokenDexParams calldata _inputMultiTokenDexParams)
    external
    payable
    override
    nonReentrant
    returns (uint256 inputAmountUsed, uint256 feeAmount)
  {
    require(block.timestamp <= _inputMultiTokenDexParams.expiration, "Transaction expired");
    require(_inputMultiTokenDexParams.swaps.length > 0, "No tokens passed");

    TempBuyArgs memory tempBuyArgs;
    tempBuyArgs.isNativeInput =
      address(_inputMultiTokenDexParams.swapToken) == DomaniDexConstants.NATIVE_ADDR;

    if (!tempBuyArgs.isNativeInput) {
      require(msg.value == 0, "Native token not required for an ERC20 transfer");
      ExplicitERC20.transferFrom(
        _inputMultiTokenDexParams.swapToken,
        msg.sender,
        address(this),
        _inputMultiTokenDexParams.maxOrMinSwapTokenAmount
      );
    }

    tempBuyArgs.startingAmount = tempBuyArgs.isNativeInput
      ? msg.value
      : _inputMultiTokenDexParams.maxOrMinSwapTokenAmount;
    tempBuyArgs.remainingInputAmount = tempBuyArgs.startingAmount;
    tempBuyArgs.tokensBought = new SwapToken[](_inputMultiTokenDexParams.swaps.length);
    Implementation storage implementation;

    for (uint256 i = 0; i < _inputMultiTokenDexParams.swaps.length; i++) {
      tempBuyArgs.swap = _inputMultiTokenDexParams.swaps[i];
      require(
        _inputMultiTokenDexParams.swapToken != tempBuyArgs.swap.token,
        "Input and output tokens are the same"
      );
      tempBuyArgs.tokensBought[i] = SwapToken(
        address(tempBuyArgs.swap.token),
        tempBuyArgs.swap.amount
      );
      tempBuyArgs.isNativeOutput =
        address(tempBuyArgs.swap.token) == DomaniDexConstants.NATIVE_ADDR;
      if (tempBuyArgs.isNativeInput && address(tempBuyArgs.swap.token) == address(wNative)) {
        wNative.deposit{value: tempBuyArgs.swap.amount}();
        tempBuyArgs.remainingInputAmount = tempBuyArgs.remainingInputAmount.sub(
          tempBuyArgs.swap.amount
        );
        tempBuyArgs.swap.token.safeTransfer(
          _inputMultiTokenDexParams.recipient,
          tempBuyArgs.swap.amount
        );
      } else if (
        tempBuyArgs.isNativeOutput &&
        address(_inputMultiTokenDexParams.swapToken) == address(wNative)
      ) {
        wNative.withdraw(tempBuyArgs.swap.amount);
        tempBuyArgs.remainingInputAmount = tempBuyArgs.remainingInputAmount.sub(
          tempBuyArgs.swap.amount
        );
        payable(_inputMultiTokenDexParams.recipient).sendValue(tempBuyArgs.swap.amount);
      } else {
        implementation = idToImplementation[keccak256(abi.encode(tempBuyArgs.swap.identifier))];
        tempBuyArgs.dexAddress = implementation.dexAddr;
        require(tempBuyArgs.dexAddress != address(0), "Implementation not supported");
        tempBuyArgs.swapParams = SwapParams(
          tempBuyArgs.swap.amount,
          tempBuyArgs.remainingInputAmount,
          tempBuyArgs.swap.swapData,
          tempBuyArgs.isNativeInput,
          _inputMultiTokenDexParams.expiration,
          tempBuyArgs.isNativeOutput ? address(this) : _inputMultiTokenDexParams.recipient
        );
        tempBuyArgs.result = tempBuyArgs.dexAddress.functionDelegateCall(
          abi.encodeWithSignature(EXACT_OUTPUT_SIG, implementation.dexInfo, tempBuyArgs.swapParams)
        );
        tempBuyArgs.returnValues = abi.decode(tempBuyArgs.result, (ReturnValues));
        require(
          tempBuyArgs.returnValues.inputToken == address(_inputMultiTokenDexParams.swapToken),
          "Wrong input token in the swap"
        );
        if (!tempBuyArgs.isNativeOutput) {
          require(
            tempBuyArgs.returnValues.outputToken == address(tempBuyArgs.swap.token),
            "Wrong output token in the swap"
          );
        } else {
          require(
            tempBuyArgs.returnValues.outputToken == address(wNative),
            "Wrong native output token in the swap"
          );
          wNative.withdraw(tempBuyArgs.swap.amount);
          payable(_inputMultiTokenDexParams.recipient).sendValue(tempBuyArgs.swap.amount);
        }
        tempBuyArgs.remainingInputAmount = tempBuyArgs.remainingInputAmount.sub(
          tempBuyArgs.returnValues.inputAmount
        );
      }
    }

    inputAmountUsed = tempBuyArgs.startingAmount.sub(tempBuyArgs.remainingInputAmount);

    feeAmount = inputAmountUsed.preciseMul(fee);

    tempBuyArgs.remainingInputAmount = tempBuyArgs.remainingInputAmount.sub(feeAmount);

    if (tempBuyArgs.isNativeInput) {
      payable(feeRecipient).sendValue(feeAmount);
      if (tempBuyArgs.remainingInputAmount > 0) {
        msg.sender.sendValue(tempBuyArgs.remainingInputAmount);
      }
    } else {
      _inputMultiTokenDexParams.swapToken.safeTransfer(feeRecipient, feeAmount);
      if (tempBuyArgs.remainingInputAmount > 0) {
        _inputMultiTokenDexParams.swapToken.safeTransfer(
          msg.sender,
          tempBuyArgs.remainingInputAmount
        );
      }
    }

    emit MultiTokenBought(
      msg.sender,
      SwapToken(address(_inputMultiTokenDexParams.swapToken), inputAmountUsed),
      _inputMultiTokenDexParams.recipient,
      tempBuyArgs.tokensBought,
      feeAmount
    );
  }

  /**
   * Swap multi tokens for generic ERC20/native token
   * @param _inputMultiTokenDexParams See InputDexParams in IDomaniMultiTokenDex
   * @return outputAmountReceived Amount of the ERC20 received from the multi-token selling
   * @return feeAmount Amount of fees paid for the swap
   */
  function sellMultiToken(InputMultiTokenDexParams calldata _inputMultiTokenDexParams)
    external
    payable
    override
    nonReentrant
    returns (uint256 outputAmountReceived, uint256 feeAmount)
  {
    require(block.timestamp <= _inputMultiTokenDexParams.expiration, "Transaction expired");
    require(_inputMultiTokenDexParams.swaps.length > 0, "No tokens passed");

    TempSellArgs memory tempSellArgs;
    tempSellArgs.isNativeOutput =
      address(_inputMultiTokenDexParams.swapToken) == DomaniDexConstants.NATIVE_ADDR;
    tempSellArgs.tokensSold = new SwapToken[](_inputMultiTokenDexParams.swaps.length);
    Implementation storage implementation;

    for (uint256 i = 0; i < _inputMultiTokenDexParams.swaps.length; i++) {
      tempSellArgs.swap = _inputMultiTokenDexParams.swaps[i];
      require(
        _inputMultiTokenDexParams.swapToken != tempSellArgs.swap.token,
        "Input and output tokens are the same"
      );
      tempSellArgs.tokensSold[i] = SwapToken(
        address(tempSellArgs.swap.token),
        tempSellArgs.swap.amount
      );
      tempSellArgs.isNativeInput =
        address(tempSellArgs.swap.token) == DomaniDexConstants.NATIVE_ADDR;
      if (!tempSellArgs.isNativeInput) {
        ExplicitERC20.transferFrom(
          tempSellArgs.swap.token,
          msg.sender,
          address(this),
          tempSellArgs.swap.amount
        );
      }
      if (tempSellArgs.isNativeOutput && address(tempSellArgs.swap.token) == address(wNative)) {
        wNative.withdraw(tempSellArgs.swap.amount);
        outputAmountReceived = outputAmountReceived.add(tempSellArgs.swap.amount);
      } else if (
        tempSellArgs.isNativeInput &&
        address(_inputMultiTokenDexParams.swapToken) == address(wNative)
      ) {
        wNative.deposit{value: tempSellArgs.swap.amount}();
        outputAmountReceived = outputAmountReceived.add(tempSellArgs.swap.amount);
      } else {
        implementation = idToImplementation[keccak256(abi.encode(tempSellArgs.swap.identifier))];
        tempSellArgs.dexAddress = implementation.dexAddr;
        require(tempSellArgs.dexAddress != address(0), "Implementation not supported");
        if (tempSellArgs.isNativeInput) {
          wNative.deposit{value: tempSellArgs.swap.amount}();
        }
        tempSellArgs.swapParams = SwapParams(
          tempSellArgs.swap.amount,
          0,
          tempSellArgs.swap.swapData,
          tempSellArgs.isNativeOutput,
          _inputMultiTokenDexParams.expiration,
          address(this)
        );
        tempSellArgs.result = tempSellArgs.dexAddress.functionDelegateCall(
          abi.encodeWithSignature(EXACT_INPUT_SIG, implementation.dexInfo, tempSellArgs.swapParams)
        );
        tempSellArgs.returnValues = abi.decode(tempSellArgs.result, (ReturnValues));
        require(
          tempSellArgs.returnValues.outputToken == address(_inputMultiTokenDexParams.swapToken),
          "Wrong output token in the swap"
        );
        !tempSellArgs.isNativeInput
          ? require(
            tempSellArgs.returnValues.inputToken == address(tempSellArgs.swap.token),
            "Wrong input token in the swap"
          )
          : require(
            tempSellArgs.returnValues.inputToken == address(wNative),
            "Wrong native input token in the swap"
          );
        outputAmountReceived = outputAmountReceived.add(tempSellArgs.returnValues.outputAmount);
      }
    }

    feeAmount = outputAmountReceived.preciseMul(fee);

    outputAmountReceived = outputAmountReceived.sub(feeAmount);

    require(
      outputAmountReceived >= _inputMultiTokenDexParams.maxOrMinSwapTokenAmount,
      "Amount received less than minimum"
    );

    if (tempSellArgs.isNativeOutput) {
      payable(feeRecipient).sendValue(feeAmount);
      payable(_inputMultiTokenDexParams.recipient).sendValue(outputAmountReceived);
    } else {
      _inputMultiTokenDexParams.swapToken.safeTransfer(feeRecipient, feeAmount);
      _inputMultiTokenDexParams.swapToken.safeTransfer(
        _inputMultiTokenDexParams.recipient,
        outputAmountReceived
      );
    }

    emit MultiTokenSold(
      msg.sender,
      tempSellArgs.tokensSold,
      _inputMultiTokenDexParams.recipient,
      SwapToken(address(_inputMultiTokenDexParams.swapToken), outputAmountReceived),
      feeAmount
    );
  }

  /**
   * Swap a quantity of a Domani fund for a generic ERC20
   * @param _token Address of the token to sweep (for native token use NATIVE_ADDR)
   * @param _recipient Address receiving the amount of token
   * @return Amount of token received
   */
  function sweepToken(IERC20 _token, address payable _recipient)
    external
    override
    nonReentrant
    returns (uint256)
  {
    bool isETH = address(_token) == DomaniDexConstants.NATIVE_ADDR;
    uint256 balance = isETH ? address(this).balance : _token.balanceOf(address(this));
    if (balance > 0) {
      if (isETH) {
        _recipient.sendValue(balance);
      } else {
        _token.safeTransfer(_recipient, balance);
      }
    }
    return balance;
  }

  /**
   * Get address and info of a supported dex
   * @param _identifier Name of dex identifier to get
   * @return See Implementation struct in IDomaniDexGeneral
   */
  function getImplementation(string calldata _identifier)
    external
    view
    override
    returns (Implementation memory)
  {
    return idToImplementation[keccak256(abi.encode(_identifier))];
  }

  /**
   * Get fee percentage charge during buying/selling
   * @return Fee percentage
   */
  function getFee() external view override returns (uint64) {
    return fee;
  }

  /**
   * Get address that will receive the fees
   * @return Address will receive fees
   */
  function getFeeRecipient() external view override returns (address) {
    return feeRecipient;
  }

  /**
   * Get the dummy address to identify native token
   * @return Address used fot native token
   */
  function nativeTokenAddress() external pure override returns (address) {
    return DomaniDexConstants.NATIVE_ADDR;
  }

  function _setFee(uint64 _newFee) internal {
    require(_newFee < 10**18, "Fee must be less than 100%");
    uint64 actualFee = fee;
    require(actualFee != _newFee, "Fee already set");
    fee = _newFee;
    emit FeeSet(actualFee, _newFee);
  }

  function _setFeeRecipient(address _feeRecipient) internal {
    require(_feeRecipient != address(0), "Fee recipient can not be 0x00");
    address actualRecipient = feeRecipient;
    require(actualRecipient != _feeRecipient, "Fee recipient already set");
    feeRecipient = _feeRecipient;
    emit FeeRecipientSet(actualRecipient, _feeRecipient);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental "ABIEncoderV2";

interface IDomaniDexGeneral {
  struct ReturnValues {
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 outputAmount;
  }

  struct SwapParams {
    uint256 exactAmount;
    uint256 minOutOrMaxIn;
    bytes extraData;
    bool isNative;
    uint256 expiration;
    address recipient;
  }

  struct Implementation {
    // Address of the implementation of a dex
    address dexAddr;
    // General info (like a router) to be used for the execution of the swaps
    bytes dexInfo;
  }

  event ImplementationRegistered(
    string indexed id,
    address implementationAddr,
    bytes implementationInfo
  );

  event ImplementationRemoved(string indexed id);

  function getImplementation(string calldata identifier)
    external
    view
    returns (Implementation memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWNative} from "../interfaces/IWNative.sol";
import {IDomaniDexGeneral} from "./IDomaniDexGeneral.sol";

interface IDomaniMultiTokenDex is IDomaniDexGeneral {
  struct Swap {
    // Token used in the swap with the swapToken
    IERC20 token;
    // Exact amount of token to buy/sell
    uint256 amount;
    // Identifier of the dex to be used
    string identifier;
    // Info (like routes) to be used in a dex for the swap execution
    bytes swapData;
  }

  struct InputMultiTokenDexParams {
    // Address of the token to send/receive
    IERC20 swapToken;
    // Max amount to spend in a buying or min amount to receive in a selling (anti-slippage)
    uint256 maxOrMinSwapTokenAmount;
    // Info contained the choice of dex for executing multi-token swap
    Swap[] swaps;
    // Expiration time (in seconds)
    uint256 expiration;
    // Address receiving fund in a buying or selling
    address recipient;
  }

  struct SwapToken {
    address token;
    uint256 amount;
  }

  event FeeSet(uint64 prevFee, uint64 newFee);

  event FeeRecipientSet(address prevRecipient, address newRecipient);

  event MultiTokenBought(
    address indexed sender,
    SwapToken tokenSold,
    address indexed recipient,
    SwapToken[] tokensBought,
    uint256 feePaid
  );

  event MultiTokenSold(
    address indexed sender,
    SwapToken[] tokensSold,
    address indexed recipient,
    SwapToken tokenBought,
    uint256 feePaid
  );

  function buyMultiToken(InputMultiTokenDexParams calldata _inputMultiTokenDexParams)
    external
    payable
    returns (uint256 inputAmountUsed, uint256 feeAmount);

  function sellMultiToken(InputMultiTokenDexParams calldata _inputMultiTokenDexParams)
    external
    payable
    returns (uint256 outputAmountReceived, uint256 feeAmount);

  function sweepToken(IERC20 token, address payable recipient) external returns (uint256);

  function wNative() external view returns (IWNative);

  function nativeTokenAddress() external pure returns (address);

  function getFee() external view returns (uint64);

  function getFeeRecipient() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IWNative {
  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental "ABIEncoderV2";

library DelegateCall {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

pragma solidity ^0.7.6;

library DomaniDexConstants {
  // Dummy address used for the identification of the native token in the swap
  address public constant NATIVE_ADDR = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
  using SafeMath for uint256;

  /**
   * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
   * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
   *
   * @param _token           ERC20 token to approve
   * @param _from            The account to transfer tokens from
   * @param _to              The account to transfer tokens to
   * @param _quantity        The quantity to transfer
   */
  function transferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal {
    // Call specified ERC20 contract to transfer tokens (via proxy).
    if (_quantity > 0) {
      uint256 existingBalance = _token.balanceOf(_to);

      SafeERC20.safeTransferFrom(_token, _from, _to, _quantity);

      uint256 newBalance = _token.balanceOf(_to);

      // Verify transfer quantity is reflected in balance
      require(newBalance == existingBalance.add(_quantity), "Invalid post transfer balance");
    }
  }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 */
library PreciseUnitMath {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;
  int256 internal constant PRECISE_UNIT_INT = 10**18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;
  // Max and min signed integer value
  int256 internal constant MAX_INT_256 = type(int256).max;
  int256 internal constant MIN_INT_256 = type(int256).min;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnitInt() internal pure returns (int256) {
    return PRECISE_UNIT_INT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxInt256() internal pure returns (int256) {
    return MAX_INT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function minInt256() internal pure returns (int256) {
    return MIN_INT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(PRECISE_UNIT);
  }

  /**
   * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
   * significand of a number with 18 decimals precision.
   */
  function preciseMul(int256 a, int256 b) internal pure returns (int256) {
    return a.mul(b).div(PRECISE_UNIT_INT);
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(PRECISE_UNIT).div(b);
  }

  /**
   * @dev Divides value a by value b (result is rounded towards 0).
   */
  function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
    return a.mul(PRECISE_UNIT_INT).div(b);
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Cant divide by 0");

    return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
  }

  /**
   * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
   */
  function divDown(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "Cant divide by 0");
    require(a != MIN_INT_256 || b != -1, "Invalid input");

    int256 result = a.div(b);
    if (a ^ b < 0 && a % b != 0) {
      result -= 1;
    }

    return result;
  }

  /**
   * @dev Multiplies value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a.mul(b), PRECISE_UNIT_INT);
  }

  /**
   * @dev Divides value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a.mul(PRECISE_UNIT_INT), b);
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, "Value must be positive");

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      // Using safemath multiplication prevents overflows
      result = previousResult.mul(a);
    }

    return result;
  }

  /**
   * @dev Returns true if a =~ b within range, false otherwise.
   */
  function approximatelyEquals(
    uint256 a,
    uint256 b,
    uint256 range
  ) internal pure returns (bool) {
    return a <= b.add(range) && a >= b.sub(range);
  }
}