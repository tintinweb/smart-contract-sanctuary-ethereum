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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./libraries/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LiquidityBootstrapAuction is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable asto;
    IERC20 public immutable usdc;
    uint256 public immutable totalRewardAmount;
    uint256 public auctionStartTime;
    uint256 public totalDepositedUSDC;
    uint256 public totalDepositedASTO;
    address public liquidityPair;
    uint256 public lpTokenAmount;
    uint16 public constant REWARDS_RELEASE_DURATION_IN_WEEKS = 12;
    uint16 public constant HOURS_PER_DAY = 24;
    uint256 internal constant SECONDS_PER_WEEK = 604800;
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_HOUR = 3600;

    mapping(address => uint256) public depositedUSDC;
    mapping(address => uint256) public depositedASTO;
    mapping(address => bool) public usdcWithdrawnOnDay6;
    mapping(address => bool) public usdcWithdrawnOnDay7;
    mapping(address => uint256) public rewardClaimed;
    mapping(address => uint256) public lpClaimed;

    struct Timeline {
        uint256 auctionStartTime;
        uint256 astoDepositEndTime;
        uint256 usdcDepositEndTime;
        uint256 auctionEndTime;
    }

    struct Stats {
        uint256 totalDepositedASTO;
        uint256 totalDepositedUSDC;
        uint256 depositedASTO;
        uint256 depositedUSDC;
    }

    event ASTODeposited(address indexed recipient, uint256 amount, Stats stats);
    event USDCDeposited(address indexed recipient, uint256 amount, Stats stats);
    event USDCWithdrawn(address indexed recipient, uint256 amount, Stats stats);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event LiquidityAdded(uint256 astoAmount, uint256 usdcAmount, uint256 lpTokenAmount);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    /**
     * @notice Initialize the contract
     * @param multisig Multisig address as the contract owner
     * @param _asto $ASTO contract address
     * @param _usdc $USDC contract address
     * @param rewardAmount Total $ASTO token amount as rewards
     * @param startTime Auction start timestamp
     */
    constructor(
        address multisig,
        IERC20 _asto,
        IERC20 _usdc,
        uint256 rewardAmount,
        uint256 startTime
    ) {
        require(address(_asto) != address(0), "invalid token address");
        require(address(_usdc) != address(0), "invalid token address");

        asto = _asto;
        usdc = _usdc;
        totalRewardAmount = rewardAmount;
        auctionStartTime = startTime;
        _transferOwnership(multisig);
    }

    /**
     * @notice Deposit `astoAmount` $ASTO and `usdcAmount` $USDC to the contract
     * @param astoAmount $ASTO token amount to deposit
     * @param usdcAmount $USDC token amount to deposit
     */
    function deposit(uint256 astoAmount, uint256 usdcAmount) external {
        if (astoAmount > 0) {
            depositASTO(astoAmount);
        }

        if (usdcAmount > 0) {
            depositUSDC(usdcAmount);
        }
    }

    /**
     * @notice Deposit `amount` $ASTO to the contract
     * @param amount $ASTO token amount to deposit
     */
    function depositASTO(uint256 amount) public nonReentrant {
        require(astoDepositAllowed(), "deposit not allowed");
        require(asto.balanceOf(msg.sender) >= amount, "insufficient balance");

        depositedASTO[msg.sender] += amount;
        totalDepositedASTO += amount;
        emit ASTODeposited(msg.sender, amount, stats(msg.sender));

        asto.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Deposit `amount` $USDC to the contract
     * @param amount $USDC token amount to deposit
     */
    function depositUSDC(uint256 amount) public nonReentrant {
        require(usdcDepositAllowed(), "deposit not allowed");
        require(usdc.balanceOf(msg.sender) >= amount, "insufficient balance");

        depositedUSDC[msg.sender] += amount;
        totalDepositedUSDC += amount;
        emit USDCDeposited(msg.sender, amount, stats(msg.sender));

        usdc.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Get withdrawable $USDC amount to `recipient`
     * @param recipient Wallet address to calculate for
     * @return Withdrawable $USDC token amount
     */
    function withdrawableUSDCAmount(address recipient) public view returns (uint256) {
        if (currentTime() < auctionStartTime || currentTime() >= auctionEndTime()) {
            return 0;
        }

        // USDC can only be withdrawn once on Day 6 and once on Day 7
        // Withdrawable USDC amount on Day 6: half of deposited USDC amount
        // Withdrawable USDC amount on Day 7: hourly linear decrease from half of deposited USDC amount to 0
        if (currentTime() < usdcDepositEndTime()) {
            return depositedUSDC[recipient];
        } else if (currentTime() >= usdcWithdrawLastDay()) {
            // On day 7, $USDC is only allowed to be withdrawn once
            if (usdcWithdrawnOnDay7[recipient]) {
                return 0;
            }
            uint256 elapsedTime = currentTime() - usdcWithdrawLastDay();
            uint256 maxAmount = depositedUSDC[recipient] / 2;

            if (elapsedTime > SECONDS_PER_DAY) {
                return 0;
            }

            // Elapsed time in hours, range from 1 to 24
            uint256 elapsedTimeRatio = (SECONDS_PER_DAY - elapsedTime) / SECONDS_PER_HOUR + 1;

            return (maxAmount * elapsedTimeRatio) / HOURS_PER_DAY;
        }
        // On day 6, $USDC is only allowed to be withdrawn once
        return usdcWithdrawnOnDay6[recipient] ? 0 : depositedUSDC[msg.sender] / 2;
    }

    /**
     * @notice Withdraw `amount` $USDC
     * @param amount The $USDC token amount to withdraw
     */
    function withdrawUSDC(uint256 amount) external nonReentrant {
        require(usdcWithdrawAllowed(), "withdraw not allowed");
        require(amount > 0, "amount should greater than zero");
        require(amount <= withdrawableUSDCAmount(msg.sender), "amount exceeded allowance");

        if (currentTime() >= usdcWithdrawLastDay()) {
            usdcWithdrawnOnDay7[msg.sender] = true;
        } else if (currentTime() >= usdcDepositEndTime()) {
            usdcWithdrawnOnDay6[msg.sender] = true;
        }

        depositedUSDC[msg.sender] -= amount;
        totalDepositedUSDC -= amount;

        emit USDCWithdrawn(msg.sender, amount, stats(msg.sender));

        usdc.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Calculate optimal swap amount to AMM based exchange
     * @param amtA Token amount for token A
     * @param amtB Token amount for token B
     * @param resA Reserved token amount for token A in LP pool
     * @param resB Reserved token amount for token B in LP pool
     * @return The optimal swap amount for token A
     */
    function optimalDeposit(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256) {
        // This function implements the forumal mentioned in the following article
        // https://blog.alphafinance.io/onesideduniswap/
        require(amtA.mul(resB) >= amtB.mul(resA), "invalid token amount");

        uint256 a = 997;
        uint256 b = uint256(1997).mul(resA);
        uint256 _c = (amtA.mul(resB)).sub(amtB.mul(resA));
        uint256 c = _c.mul(1000).div(amtB.add(resB)).mul(resA);

        uint256 d = a.mul(c).mul(4);
        uint256 e = Math.sqrt(b.mul(b).add(d));

        uint256 numerator = e.sub(b);
        uint256 denominator = a.mul(2);

        return numerator.div(denominator);
    }

    /**
     * @notice Add all deposited $ASTO and $USDC to AMM based exchange
     * @param router Router contract address to the exchange
     * @param factory Factory contract address to the exchange
     */
    function addLiquidityToExchange(address router, address factory) external nonReentrant onlyOwner {
        require(currentTime() >= auctionEndTime(), "auction not finished");
        require(totalDepositedUSDC > 0, "no USDC deposited");
        require(totalDepositedASTO > 0, "no ASTO deposited");

        // 1. Approve the router contract to get all tokens from this contract
        usdc.approve(router, type(uint256).max);
        asto.approve(router, type(uint256).max);

        uint256 usdcSent;
        uint256 astoSent;

        // 2. Add deposited tokens to the exchange as much as posisble
        // The tokens will be transferred to the liquidity pool if it exists, otherwise a new trading pair will be created
        (usdcSent, astoSent, lpTokenAmount) = IUniswapV2Router02(router).addLiquidity(
            address(usdc),
            address(asto),
            totalDepositedUSDC,
            totalDepositedASTO,
            0,
            0,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        // Store the LP contract address
        liquidityPair = IUniswapV2Factory(factory).getPair(address(asto), address(usdc));

        // Both deposited $ASTO and $USDC are transferred to the liquidity pool,
        // which means the trading pair was not created before, or the price from exchange matches with auction
        if (usdcSent == totalDepositedUSDC && astoSent == totalDepositedASTO) {
            emit LiquidityAdded(astoSent, usdcSent, lpTokenAmount);
            return;
        }

        // 3. Swap the tokens left in the contract if not all tokens been aadded to the liquidity pool

        // Get reserved token amounts in LP pool
        uint256 resASTO;
        uint256 resUSDC;
        if (IUniswapV2Pair(liquidityPair).token0() == address(asto)) {
            (resASTO, resUSDC, ) = IUniswapV2Pair(liquidityPair).getReserves();
        } else {
            (resUSDC, resASTO, ) = IUniswapV2Pair(liquidityPair).getReserves();
        }

        // Calculate swap amount
        uint256 swapAmt;
        address[] memory path = new address[](2);
        bool isReserved;
        uint256 balance;
        if (usdcSent == totalDepositedUSDC) {
            balance = totalDepositedASTO - astoSent;
            swapAmt = optimalDeposit(balance, 0, resASTO, resUSDC);
            (path[0], path[1]) = (address(asto), address(usdc));
        } else {
            balance = totalDepositedUSDC - usdcSent;
            swapAmt = optimalDeposit(balance, 0, resUSDC, resASTO);
            (path[0], path[1]) = (address(usdc), address(asto));
            isReserved = true;
        }

        require(swapAmt > 0, "swapAmt must great then 0");

        // Swap the token
        uint256[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
            swapAmt,
            0,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        // 4. Add liquidity to the exchange again. All tokens should be transferred in this step
        (uint256 amountA, , uint256 moreLPAmount) = IUniswapV2Router02(router).addLiquidity(
            isReserved ? address(usdc) : address(asto),
            isReserved ? address(asto) : address(usdc),
            balance - swapAmt,
            amounts[1],
            0,
            0,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        lpTokenAmount += moreLPAmount;
        uint256 totalASTOSent = isReserved ? astoSent : astoSent + swapAmt + amountA;
        uint256 totalUSDCSent = isReserved ? usdcSent + swapAmt + amountA : usdcSent;
        emit LiquidityAdded(totalASTOSent, totalUSDCSent, lpTokenAmount);
    }

    /**
     * @notice Claim LP tokens. The LP tokens are locked for 12 weeks after auction ends
     */
    function claimLPToken() external nonReentrant {
        uint256 claimable = claimableLPAmount(msg.sender);
        require(claimable > 0, "no claimable token");

        lpClaimed[msg.sender] += claimable;

        require(IUniswapV2Pair(liquidityPair).transfer(msg.sender, claimable), "insufficient LP token balance");
    }

    /**
     * @notice Calculate claimable LP amount based on deposited token amount
     * @param recipient Wallet address to calculate for
     * @return Claimable LP amount
     */
    function claimableLPAmount(address recipient) public view returns (uint256) {
        if (currentTime() < lpTokenReleaseTime()) {
            return 0;
        }
        // LP tokens are splitted into two equal parts. One part for $ASTO and another for $USDC
        uint256 claimableLPTokensForASTO = (lpTokenAmount * depositedASTO[recipient]) / (2 * totalDepositedASTO);
        uint256 claimableLPTokensForUSDC = (lpTokenAmount * depositedUSDC[recipient]) / (2 * totalDepositedUSDC);
        uint256 total = claimableLPTokensForASTO + claimableLPTokensForUSDC;
        return total - lpClaimed[recipient];
    }

    /**
     * @notice Claim `amount` $ASTO tokens as rewards
     * @param amount The $ASTO token amount to claim
     */
    function claimRewards(uint256 amount) external nonReentrant {
        uint256 amountVested;
        (, amountVested) = claimableRewards(msg.sender);

        require(amount <= amountVested, "amount not claimable");
        rewardClaimed[msg.sender] += amount;

        require(asto.balanceOf(address(this)) >= amount, "insufficient ASTO balance");
        asto.safeTransfer(msg.sender, amount);

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Calculate claimable $ASTO token amount as rewards. The rewards are released weekly for 12 weeks after auction ends.
     * @param recipient Wallet address to calculate for
     * @return Vested weeks and vested(claimable) $ASTO token amount
     */
    function claimableRewards(address recipient) public view returns (uint16, uint256) {
        if (currentTime() < auctionEndTime()) {
            return (0, 0);
        }

        uint256 elapsedTime = currentTime() - auctionEndTime();
        uint16 elapsedWeeks = uint16(elapsedTime / SECONDS_PER_WEEK);

        if (elapsedWeeks >= REWARDS_RELEASE_DURATION_IN_WEEKS) {
            uint256 remaining = calculateRewards(recipient) - rewardClaimed[recipient];
            return (REWARDS_RELEASE_DURATION_IN_WEEKS, remaining);
        } else {
            uint256 amountVestedPerWeek = calculateRewards(recipient) / REWARDS_RELEASE_DURATION_IN_WEEKS;
            uint256 amountVested = amountVestedPerWeek * elapsedWeeks - rewardClaimed[recipient];
            return (elapsedWeeks, amountVested);
        }
    }

    /**
     * @notice Calculate the total $ASTO token amount as rewards
     * @param recipient Wallet address to calculate for
     * @return Total rewards amount
     */
    function calculateRewards(address recipient) public view returns (uint256) {
        return calculateASTORewards(recipient) + calculateUSDCRewards(recipient);
    }

    /**
     * @notice Calculate the $ASTO rewards amount for depositing $ASTO
     * @param recipient Wallet address to calculate for
     * @return Rewards amount for for depositing $ASTO
     */
    function calculateASTORewards(address recipient) public view returns (uint256) {
        if (totalDepositedASTO == 0) {
            return 0;
        }
        return (astoRewardAmount() * depositedASTO[recipient]) / totalDepositedASTO;
    }

    /**
     * @notice Calculate the $ASTO rewards amount for depositing $USDC
     * @param recipient Wallet address to calculate for
     * @return Rewards amount for for depositing $USDC
     */
    function calculateUSDCRewards(address recipient) public view returns (uint256) {
        if (totalDepositedUSDC == 0) {
            return 0;
        }
        return (usdcRewardAmount() * depositedUSDC[recipient]) / totalDepositedUSDC;
    }

    /**
     * @notice Withdraw any token left in the contract to multisig
     * @param token ERC20 token contract address to withdraw
     * @param amount Token amount to withdraw
     */
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "invalid token address");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "amount should not exceed balance");
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Check if depositing $ASTO is allowed
     * @return $ASTO deposit status
     */
    function astoDepositAllowed() public view returns (bool) {
        return currentTime() >= auctionStartTime && currentTime() < astoDepositEndTime();
    }

    /**
     * @notice Check if depositing $USDC is allowed
     * @return $USDC deposit status
     */
    function usdcDepositAllowed() public view returns (bool) {
        return currentTime() >= auctionStartTime && currentTime() < usdcDepositEndTime();
    }

    /**
     * @notice Check if withdrawing $USDC is allowed
     * @return $USDC withdraw status
     */
    function usdcWithdrawAllowed() public view returns (bool) {
        return currentTime() >= auctionStartTime && currentTime() < auctionEndTime();
    }

    /**
     * @notice Get $ASTO deposit end timestamp
     * @return Timestamp when $ASTO deposit ends
     */
    function astoDepositEndTime() public view returns (uint256) {
        return auctionStartTime + 3 days;
    }

    /**
     * @notice Get $USDC deposit end timestamp
     * @return Timestamp when $USDC deposit ends
     */
    function usdcDepositEndTime() public view returns (uint256) {
        return auctionStartTime + 5 days;
    }

    /**
     * @notice Get the timestamp for the last day of withdrawing $USDC
     * @return Timestamp for the last day of withdrawing $USDC
     */
    function usdcWithdrawLastDay() public view returns (uint256) {
        return auctionStartTime + 6 days;
    }

    /**
     * @notice Get auction end timestamp
     * @return Timestamp when the auction ends
     */
    function auctionEndTime() public view returns (uint256) {
        return auctionStartTime + 7 days;
    }

    /**
     * @notice Get LP token release timestamp
     * @return Timestamp when the locked LP tokens been released
     */
    function lpTokenReleaseTime() public view returns (uint256) {
        return auctionEndTime() + 12 weeks;
    }

    /**
     * @notice Get the rewards portion for all deposited $ASTO
     * @return $ASTO token amount to be distributed as rewards for depositing $ASTO
     */
    function astoRewardAmount() public view returns (uint256) {
        return (totalRewardAmount * 75) / 100;
    }

    /**
     * @notice Get the rewards portion for all deposited $USDC
     * @return $ASTO token amount to be distributed as rewards for depositing $USDC
     */
    function usdcRewardAmount() public view returns (uint256) {
        return (totalRewardAmount * 25) / 100;
    }

    /**
     * @notice Set auction start timestamp
     * @param newStartTime The auction start timestamp to set
     */
    function setStartTime(uint256 newStartTime) external onlyOwner {
        auctionStartTime = newStartTime;
    }

    /**
     * @notice Get the auction timelines
     * @return Timeline struct for the auction
     */
    function timeline() public view returns (Timeline memory) {
        return Timeline(auctionStartTime, astoDepositEndTime(), usdcDepositEndTime(), auctionEndTime());
    }

    /**
     * @notice Get the deposit stats
     * @param depositor The wallet address to get the stats for
     * @return Stats struct for the auction
     */
    function stats(address depositor) public view returns (Stats memory) {
        return Stats(totalDepositedASTO, totalDepositedUSDC, depositedASTO[depositor], depositedUSDC[depositor]);
    }

    /**
     * @notice Get the latest block timestamp
     * @return The latest block timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}

pragma solidity 0.8.6;

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}