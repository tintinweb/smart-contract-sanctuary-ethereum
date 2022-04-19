// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenVesting is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeERC20 for IERC20;

    uint256 internal constant SECONDS_PER_WEEK = 604800;

    struct VestingSchedule {
        bool isValid;
        uint256 startTime;
        uint256 amount;
        uint16 duration;
        uint16 delay;
        uint16 weeksClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    event VestingAdded(
        address indexed recipient,
        uint256 vestingId,
        uint256 startTime,
        uint256 amount,
        uint16 duration,
        uint16 delay
    );
    event VestingTokensClaimed(address indexed recipient, uint256 vestingId, uint256 amountClaimed);
    event VestingRemoved(address recipient, uint256 vestingId, uint256 amountVested, uint256 amountNotVested);
    event VestingRecipientUpdated(uint256 vestingId, address oldRecipient, address newRecipient);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    IERC20 public immutable token;

    mapping(uint256 => VestingSchedule) public vestingSchedules;
    mapping(address => uint256) private activeVesting;
    uint256 public totalVestingCount;
    uint256 public totalVestingAmount;
    bool public allocInitialized;

    constructor(IERC20 _token, address aragonAgent) {
        require(address(aragonAgent) != address(0), "invalid aragon agent address");
        require(address(_token) != address(0), "invalid token address");
        token = _token;
        _transferOwnership(aragonAgent);
    }

    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - totalVestingAmount, "Insufficient token balance");
        require(activeVesting[_recipient] == 0, "active vesting already exists");

        uint256 amountVestedPerWeek = _amount.div(_durationInWeeks);
        require(amountVestedPerWeek > 0, "amountVestedPerWeek > 0");

        VestingSchedule memory vesting = VestingSchedule({
            isValid: true,
            startTime: _startTime == 0 ? currentTime() : _startTime,
            amount: _amount,
            duration: _durationInWeeks,
            delay: _delayInWeeks,
            weeksClaimed: 0,
            totalClaimed: 0,
            recipient: _recipient
        });

        totalVestingCount++;
        vestingSchedules[totalVestingCount] = vesting;
        activeVesting[_recipient] = totalVestingCount;
        emit VestingAdded(_recipient, totalVestingCount, vesting.startTime, _amount, _durationInWeeks, _delayInWeeks);
        totalVestingAmount += _amount;
    }

    function getActiveVesting(address _recipient) public view returns (uint256) {
        return activeVesting[_recipient];
    }

    function calculateVestingClaim(uint256 _vestingId) public view returns (uint16, uint256) {
        require(_vestingId > 0, "invalid vestingId");
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        return _calculateVestingClaim(vestingSchedule);
    }

    function _calculateVestingClaim(VestingSchedule storage vestingSchedule) internal view returns (uint16, uint256) {
        if (currentTime() < vestingSchedule.startTime || !vestingSchedule.isValid) {
            return (0, 0);
        }

        uint256 elapsedTime = currentTime().sub(vestingSchedule.startTime);
        uint256 elapsedWeeks = elapsedTime.div(SECONDS_PER_WEEK);

        if (elapsedWeeks < vestingSchedule.delay) {
            return (uint16(elapsedWeeks), 0);
        }

        if (elapsedWeeks >= vestingSchedule.duration + vestingSchedule.delay) {
            uint256 remainingVesting = vestingSchedule.amount.sub(vestingSchedule.totalClaimed);
            return (vestingSchedule.duration, remainingVesting);
        } else {
            uint16 claimableWeeks = uint16(elapsedWeeks.sub(vestingSchedule.delay));
            uint16 weeksVested = uint16(claimableWeeks.sub(vestingSchedule.weeksClaimed));
            uint256 amountVestedPerWeek = vestingSchedule.amount.div(uint256(vestingSchedule.duration));
            uint256 amountVested = uint256(weeksVested.mul(amountVestedPerWeek));
            return (weeksVested, amountVested);
        }
    }

    function claimVestedTokens() external {
        uint256 _vestingId = activeVesting[msg.sender];
        require(_vestingId > 0, "no active vesting found");

        uint16 weeksVested;
        uint256 amountVested;

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];

        require(vestingSchedule.recipient == msg.sender, "only recipient can claim");

        (weeksVested, amountVested) = _calculateVestingClaim(vestingSchedule);
        require(amountVested > 0, "amountVested is 0");

        vestingSchedule.weeksClaimed = uint16(vestingSchedule.weeksClaimed.add(weeksVested));
        vestingSchedule.totalClaimed = uint256(vestingSchedule.totalClaimed.add(amountVested));

        require(token.balanceOf(address(this)) >= amountVested, "no tokens");
        token.safeTransfer(vestingSchedule.recipient, amountVested);
        emit VestingTokensClaimed(vestingSchedule.recipient, _vestingId, amountVested);
    }

    function removeVestingSchedule(uint256 _vestingId) external onlyOwner {
        require(_vestingId > 0, "invalid vestingId");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        require(activeVesting[vestingSchedule.recipient] == _vestingId, "inactive vesting");
        address recipient = vestingSchedule.recipient;
        uint16 weeksVested;
        uint256 amountVested;
        (weeksVested, amountVested) = _calculateVestingClaim(vestingSchedule);

        uint256 amountNotVested = (vestingSchedule.amount.sub(vestingSchedule.totalClaimed)).sub(amountVested);

        vestingSchedule.isValid = false;
        activeVesting[recipient] = 0;

        require(token.balanceOf(address(this)) >= amountVested, "not enough balance");
        token.safeTransfer(recipient, amountVested);

        totalVestingAmount -= amountNotVested;
        emit VestingRemoved(recipient, _vestingId, amountVested, amountNotVested);
    }

    function updateVestingRecipient(uint256 _vestingId, address recipient) external onlyOwner {
        require(_vestingId > 0, "invalid vestingId");
        require(activeVesting[recipient] == 0, "recipient has an active vesting");
        require(address(recipient) != address(0), "invalid recipient address");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        require(activeVesting[vestingSchedule.recipient] == _vestingId, "inactive vesting");
        activeVesting[vestingSchedule.recipient] = 0;

        emit VestingRecipientUpdated(_vestingId, vestingSchedule.recipient, recipient);

        vestingSchedule.recipient = recipient;
        activeVesting[recipient] = _vestingId;
    }

    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    function tokensVestedPerWeek(uint256 _vestingId) public view returns (uint256) {
        require(_vestingId > 0, "invalid vestingId");
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        return vestingSchedule.amount.div(uint256(vestingSchedule.duration));
    }

    function withdrawToken(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid token address");
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "amount should not exceed balance");
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(recipient, amount);
    }

    function initializeAllocation(uint256 startTime) external onlyOwner {
        require(!allocInitialized, "allocation already initialized.");

        // Early Contributors
        addVestingSchedule(0x07A8c46530ADf39bbd2791ac5f5e477011C42A9f, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0xa23CB57ccC903e18dd5B4399826B7FC8c68D0C9C, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0xC31cc7B4a202eAFfd571D0895033ffa7986d181f, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x84a9a19dC122e472493E3E21d25469Be8b3d47Fc, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x5132d87c57598c4d10A9ab188DdCCc061531cc99, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x29488965c47A61f476a798B40a669cf7cdBcF805, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xb2695290A04d2a61b1fE6c89EaF9298B3534d3bD, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x9E59Ea877e5aDB95cF6a82618a910F855568d6ff, startTime, 4768000 * 10**18, 50, 0);
        addVestingSchedule(0xa665a0507Ad4B0571B12B1f59FA7e8d2BF63C65F, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xC6b6896A9e0131820b10B586dadBAc4E9ACfb86A, startTime, 596000 * 10**18, 50, 0);
        addVestingSchedule(0x32802F989B4348A51DD0E61D23B78BE1a0543469, startTime, 1788000 * 10**18, 50, 0);
        addVestingSchedule(0x09443af3e8bf03899A40d6026480fAb0E44D518E, startTime, 1192000 * 10**18, 50, 0);
        addVestingSchedule(0xCA63CD425d0e78fFE05a84c330Bfee691242113d, startTime, 2384000 * 10**18, 50, 0);
        addVestingSchedule(0x3eF7f258816F6e2868566276647e3776616CBF4d, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0x1e550B93a628Dc2bD7f6A592f23867241e562AeE, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x3BB9378a2A29279aA82c00131a6046aa0b5F6A79, startTime, 17880000 * 10**18, 50, 0);
        addVestingSchedule(0x6AB0a3F3B01653295c0DC2eCeD5c4EaD099c3f9D, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x31476BE87e39722488b9B228284B1Fe0A6deD88c, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0xB66e29158d18c34097a199624e5B126703B346C3, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x33f4BeBbc43Bc5725F4eD64629E7022a46eD9146, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x61F85f43e275Fda8b5E122C7738Fe188C92385c0, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xfE8420a2758c303ADC5f6C3125FDa7E9eD96A1E3, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x2630b80F4fD862aca4010fBFeFA2081FC631D20C, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x58791B7d2CFC8310f7D2032B99B3e9DfFAAe4f17, startTime, 1192000 * 10**18, 50, 0);
        addVestingSchedule(0xDD1b2aeD364f3532A90dAcB5d9ba8D47b11Cdea3, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x58d0f3dA9C97dE3c39f481e146f3568081d328a2, startTime, 1788000 * 10**18, 50, 0);
        addVestingSchedule(0xC71F1e087AadfBaE3e8578b5eFAFDeC8aFA95a16, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x683E0fCB25A2A84Bf9f5850a47d88Ad9c38C2a2f, startTime, 17880000 * 10**18, 50, 0);
        addVestingSchedule(0x1856D5e4767737a4051ae61c7852acdF8DFFb27b, startTime, 8940000 * 10**18, 50, 0);
        addVestingSchedule(0xDeCf6cC45e4F1816fC75C3b2AeD1e7BF02C43E52, startTime, 596000 * 10**18, 50, 0);
        addVestingSchedule(0x77aB3a45Fb6A48Ed390ae75D7812e4BD8ACe5A17, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x99F229481Bbb6245BA2763f224f733A7Cd784f0c, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x55E1e020Ca8f589b691Dbc3E9CBCe8845a400f97, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x4caeDdE6188c8c452556A141aA463999b4cF2ffc, startTime, 1788000 * 10**18, 50, 0);
        addVestingSchedule(0xb9FeCf6dC7F8891721d98825De85516e67922772, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xf83A22e3eF017AdA8f4DCE1D534532d6e7000795, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0xDA51f23515Bf0FF319FfD5727e22C1Aa114B392C, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0xC7fC3d9820c9803d788369E9129ACA7C16abe96D, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0xb8F03E0a03673B5e9E094880EdE376Dc2caF4286, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x0cf02f3a7B424dD8AA57A550B3c0362aa0146E95, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x05AE0683d8B39D13950c053E70538f5810737bC5, startTime, 1192000 * 10**18, 50, 0);
        addVestingSchedule(0xf2d876D0621Ee340aFcD37ea6F49733982b08bC2, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0x1887D97F9C875108Aa6bE109B282f87A666472f2, startTime, 3576000 * 10**18, 50, 0);
        addVestingSchedule(0xB7A210a2786fF2B22786e4C082d2a6FF6775CB68, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x480F32b9B5BBCD188501C9FA74FE23D6Eb037BDf, startTime, 5960000 * 10**18, 50, 0);

        // Ecosystem Development
        addVestingSchedule(0xdBB0FfAFD38A61A1C06BA0C40761355F9F50a01E, startTime, 2384000 * 10**18, 104, 0);
        addVestingSchedule(0xe4382f06191cb158515A763E2ED5c573d7b3E4C0, startTime, 1192000 * 10**18, 104, 0);
        addVestingSchedule(0xB9BbB220D5eB660BBB634805dfF8cBDacb732cB4, startTime, 4768000 * 10**18, 104, 0);
        addVestingSchedule(0xf4a3F5bC8FAD4C49f0a0102b410Dcbfa29406D50, startTime, 5960000 * 10**18, 104, 0);
        addVestingSchedule(0x4Eee8BA6724Ca5cEc0E1433B9f613936C774b9F5, startTime, 11920000 * 10**18, 104, 0);

        // Advisors
        addVestingSchedule(0x3cEaFDFcA243AEfef6c2360B549B22b9c118744e, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xa11f5Aecf3D5d5A17FF16dA1dDdc2bA43A6c5Fe1, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0x747dfb7D6D27671B4e3E98087f00e6B023d0AAb7, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xDA223201df90Fe53CA5C9282BE932F876F6FA2F1, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xaBBDe42239e98FE42e732961F25cf0cfFF68e107, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xd051a1170e3c336D95397208ae58Fa4b22e92A97, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0x9796260c3D8E52f2c053D27Dcb382b7f2a504522, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xCc7357203C0D1C0D64eD7C5605a495C8FBEBAC8c, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0x88C3531B54Dde2438b10107e352551521B4319bD, startTime, 2980000 * 10**18, 104, 12);

        // ASM Gnosis Safe
        addVestingSchedule(0xEcbc5C456D9508A441254A6dA7d51C693A206eCf, startTime, 381440000 * 10**18, 104, 12);

        allocInitialized = true;
    }
}