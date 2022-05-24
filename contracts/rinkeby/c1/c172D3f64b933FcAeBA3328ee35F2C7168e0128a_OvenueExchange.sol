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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "./exchange/Exchange.sol";

contract OvenueExchange is Exchange {
    string public constant name = "Ovenue Exchange";

    string public constant version = "1.0";

    constructor () {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ArrayUtils.sol";
import "../libraries/SaleKindInterface.sol";
import "../libraries/ReentrancyGuarded.sol";
import "./ExchangeCore.sol";

contract Exchange is ExchangeCore {
    // /**
    //  * @dev Call guardedArrayReplace - library function exposed for testing.
    //  */
    // function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
    //     public
    //     pure
    //     returns (bytes memory)
    // {
    //     ArrayUtils.guardedArrayReplace(array, desired, mask);
    //     return array;
    // }

    // /**
    //  * Test copy byte array
    //  *
    //  * @param arrToCopy Array to copy
    //  * @return byte array
    //  */
    // function testCopy(bytes memory arrToCopy)
    //     public
    //     pure
    //     returns (bytes memory)
    // {
    //     bytes memory arr = new bytes(arrToCopy.length);
    //     uint index;
    //     assembly {
    //         index := add(arr, 0x20)
    //     }
    //     ArrayUtils.unsafeWriteBytes(index, arrToCopy);
    //     return arr;
    // }

    // /**
    //  * Test write address to bytes
    //  *
    //  * @param addr Address to write
    //  * @return byte array
    //  */
    // function testCopyAddress(address addr)
    //     public
    //     pure
    //     returns (bytes memory)
    // {
    //     bytes memory arr = new bytes(0x14);
    //     uint index;
    //     assembly {
    //         index := add(arr, 0x20)
    //     }
    //     ArrayUtils.unsafeWriteAddress(index, addr);
    //     return arr;
    // }

    /**
     * @dev Call calculateFinalPrice - library function exposed for testing.
     */
    function calculateFinalPrice(SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
    public
    view
    returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }

    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,

        bytes memory callData,
        bytes memory replacementPattern
    )
    public
    pure
    returns (bytes32)
    {
        return hashOrder(
            Order(
                addrs[0],
                addrs[1],
                addrs[2],
                uints[0],
                uints[1],
                addrs[3],
                side,
                saleKind,
                howToCall,
                addrs[4],
                callData,
                replacementPattern,
                addrs[5],
                uints[2],
                uints[3],
                uints[4],
                uints[5]
            )
        );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,

        bytes memory callData,
        bytes memory replacementPattern
    )
    public
    pure
    returns (bytes32)
    {
        return hashToSign(
            Order(
                addrs[0],
                addrs[1],
                addrs[2],
                uints[0],
                uints[1],
                addrs[3],
                side,
                saleKind,
                howToCall,
                addrs[4],
                callData,
                replacementPattern,
                addrs[5],
                uints[2],
                uints[3],
                uints[4],
                uints[5]
            )
        );
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,

        bytes memory callData,
        bytes memory replacementPattern
    )
    view
    public
    returns (bool)
    {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            side,
            saleKind,
            howToCall,
            addrs[4],
            callData,
            replacementPattern,
            addrs[5],
            uints[2],
            uints[3],
            uints[4],
            uints[5]
        );
        return validateOrderParameters(
            order
        );
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,

        bytes memory callData,
        bytes memory replacementPattern,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    view
    public
    returns (bool)
    {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            side,
            saleKind,
            howToCall,
            addrs[4],
            callData,
            replacementPattern,
            addrs[5],
            uints[2],
            uints[3],
            uints[4],
            uints[5]
        );

        return validateOrder(
            hashToSign(order),
            order,
            Sig(v, r, s)
        );
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bool orderbookInclusionDesired
    )
    public
    {

        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            side,
            saleKind,
            howToCall,
            addrs[4],
            callData,
            replacementPattern,
            addrs[5],
            uints[2],
            uints[3],
            uints[4],
            uints[5]
        );

        return approveOrder(order, orderbookInclusionDesired);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        uint8 v,
        bytes32 r,
        bytes32 s)
    public
    {

        return cancelOrder(
            Order(
                addrs[0],
                addrs[1],
                addrs[2],
                uints[0],
                uints[1],
                addrs[3],
                side,
                saleKind,
                howToCall,
                addrs[4],
                callData,
                replacementPattern,
                addrs[5],
                uints[2],
                uints[3],
                uints[4],
                uints[5]
            ),
            Sig(v, r, s)
        );
    }

    /**
     * @dev Call calculateCurrentPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateCurrentPrice_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern
    )
    public
    pure
    returns (uint)
    {
        return calculateCurrentPrice(
            Order(
                addrs[0],
                addrs[1],
                addrs[2],
                uints[0],
                uints[1],
                addrs[3],
                side,
                saleKind,
                howToCall,
                addrs[4],
                callData,
                replacementPattern,
                addrs[5],
                uints[2],
                uints[3],
                uints[4],
                uints[5]
            )
        );
    }

    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address[12] memory addrs,
        uint[12] memory uints,
        uint8[6] memory saleKinds,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell
    )
    public
    view
    returns (bool)
    {

        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            SaleKindInterface.Side(saleKinds[0]),
            SaleKindInterface.SaleKind(saleKinds[1]),
            HowToCall(saleKinds[2]),
            addrs[4],
            calldataBuy,
            replacementPatternBuy,
            addrs[5],
            uints[2],
            uints[3],
            uints[4],
            uints[5]
        );
        Order memory sell = Order(
            addrs[6],
            addrs[7],
            addrs[8],
            uints[6],
            uints[7],
            addrs[9],
            SaleKindInterface.Side(saleKinds[3]),
            SaleKindInterface.SaleKind(saleKinds[4]),
            HowToCall(saleKinds[5]),
            addrs[10],
            calldataSell,
            replacementPatternSell,
            addrs[11],
            uints[8],
            uints[9],
            uints[10],
            uints[11]
        );

        return ordersCanMatch(
            buy,
            sell
        );
    }

    /**
     * @dev Return whether or not two orders' calldata specifications can match
     * @param buyCalldata Buy-side order calldata
     * @param buyReplacementPattern Buy-side order calldata replacement mask
     * @param sellCalldata Sell-side order calldata
     * @param sellReplacementPattern Sell-side order calldata replacement mask
     * @return Whether the orders' calldata can be matched
     */
    function orderCalldataCanMatch(bytes memory buyCalldata, bytes memory buyReplacementPattern, bytes memory sellCalldata, bytes memory sellReplacementPattern)
    public
    pure
    returns (bool)
    {
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    /**
     * @dev Call calculateMatchPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateMatchPrice_(
        address[12] memory addrs,
        uint[12] memory uints,
        uint8[6] memory saleKinds,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell
    )
    public
    pure
    returns (uint)
    {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            SaleKindInterface.Side(saleKinds[0]),
            SaleKindInterface.SaleKind(saleKinds[1]),
            HowToCall(saleKinds[2]),
            addrs[4],
            calldataBuy,
            replacementPatternBuy,
            addrs[5],
            uints[2],
            uints[3],
            uints[4],
            uints[5]
        );
        Order memory sell = Order(
            addrs[6],
            addrs[7],
            addrs[8],
            uints[6],
            uints[7],
            addrs[9],
            SaleKindInterface.Side(saleKinds[3]),
            SaleKindInterface.SaleKind(saleKinds[4]),
            HowToCall(saleKinds[5]),
            addrs[10],
            calldataSell,
            replacementPatternSell,
            addrs[11],
            uints[8],
            uints[9],
            uints[10],
            uints[11]
        );
        return calculateMatchPrice(
            buy,
            sell
        );
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[12] memory addrs,
        uint[12] memory uints,
        uint8[6] memory saleKinds,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        uint8[2] memory vs,
        bytes32[4] memory rssMetadata
    )
    public
    payable
    {
        return atomicMatch(
            Order(
                addrs[0],
                addrs[1],
                addrs[2],
                uints[0],
                uints[1],
                addrs[3],
                SaleKindInterface.Side(saleKinds[0]),
                SaleKindInterface.SaleKind(saleKinds[1]),
                HowToCall(saleKinds[2]),
                addrs[4],
                calldataBuy,
                replacementPatternBuy,
                addrs[5],
                uints[2],
                uints[3],
                uints[4],
                uints[5]
            ),
            Sig(vs[0], rssMetadata[0], rssMetadata[1]),
            Order(
                addrs[6],
                addrs[7],
                addrs[8],
                uints[6],
                uints[7],
                addrs[9],
                SaleKindInterface.Side(saleKinds[3]),
                SaleKindInterface.SaleKind(saleKinds[4]),
                HowToCall(saleKinds[5]),
                addrs[10],
                calldataSell,
                replacementPatternSell,
                addrs[11],
                uints[8],
                uints[9],
                uints[10],
                uints[11]
            ),
            Sig(vs[1],
            rssMetadata[2],
            rssMetadata[3])
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/ArrayUtils.sol";
import "../libraries/SaleKindInterface.sol";
import "../libraries/ReentrancyGuarded.sol";

contract ExchangeCore is ReentrancyGuarded, Ownable {
    using SafeERC20 for IERC20;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* An order on the exchange. */
    struct Order {
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint takerRelayerFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        HowToCall howToCall;
        /* Target. */
        address target;
        /* Calldata. */
        bytes callData;
        bytes replacementPattern;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint basePrice;
        /* Listing timestamp. */
        uint listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint salt;
    }

    event OrderApprovedPartOne(bytes32 indexed hash, address exchange, address indexed maker, address taker, uint makerRelayerFee, uint takerRelayerFee, address indexed feeRecipient, SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, address target);
    event OrderApprovedPartTwo(bytes32 indexed hash, bytes callData, address paymentToken, uint basePrice, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired);
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, uint price);

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(address token, address from, address to, uint amount)
    internal
    {
        if (amount > 0) {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    /**
     * Calculate size of an order struct when tightly packed
     *
     * @param order Order to calculate size of
     * @return Size in bytes
     */
    function sizeOf(Order memory order)
    internal
    pure
    returns (uint)
    {
        return ((0x14 * 6) + (0x20 * 6) + 3 + order.callData.length + order.replacementPattern.length);
        // return ((0x14 * 6) + (0x20 * 9) + 4 + order.callData.length + order.replacementPattern.length + order.staticExtradata.length);
    }

    function hashOrder(Order memory order)
    internal
    pure
    returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint size = sizeOf(order);
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteAddress(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteAddress(index, order.target);
        index = ArrayUtils.unsafeWriteBytes(index, order.callData);
        index = ArrayUtils.unsafeWriteBytes(index, order.replacementPattern);
        index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    /**
   * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order)));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function requireValidOrder(Order memory order, Sig memory sig)
    internal
    view
    returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig), "Invalid Order Hash or already cancelled!");
        return hash;
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order)
    internal
    view
    returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange.sol contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function validateOrder(bytes32 hash, Order memory order, Sig memory sig)
    internal
    view
    returns (bool)
    {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Order authentication. Order must be either:
        /* (a) previously approved */
        if (approvedOrders[hash]) {
            return true;
        }

        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
    }

    /**
   * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired)
    internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker);

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);

        /* Assert order has not already been approved. */
        require(!approvedOrders[hash]);

        /* EFFECTS */

        /* Mark order as approved. */
        approvedOrders[hash] = true;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.makerRelayerFee, order.takerRelayerFee, order.feeRecipient, order.side, order.saleKind, order.target);
        }
        {
            emit OrderApprovedPartTwo(hash, order.callData, order.paymentToken, order.basePrice, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
        }
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param sig ECDSA signature
     */
    function cancelOrder(Order memory order, Sig memory sig)
    internal
    {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice(Order memory order)
    internal
    pure
    returns (uint)
    {
        //        return SaleKindInterface.calculateFinalPrice(order.side, order.saleKind, order.basePrice, order.listingTime, order.expirationTime);
        return order.basePrice;
    }

    /**
    * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell)
    pure
    internal
    returns (uint)
    {
        /* Calculate sell price. */
        uint sellPrice = sell.basePrice;

        /* Calculate buy price. */
        uint buyPrice = buy.basePrice;

        /* Require price cross. */
        require(buyPrice >= sellPrice, "OvenueExchange::Buy price must greater than sell price!");

        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

    /**
     * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell)
    internal
    returns (uint)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0, "OvenueExchange::Redundant sent funds!");
        }

        /* Calculate match price. */
        uint price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }
        

        /* Amount that will be received by seller (for Ether). */
        uint receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint requiredAmount = price;
        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerRelayerFee <= buy.takerRelayerFee, "OvenueExchange::taker fee is more than to maximum fee specified by buyer");

            if (sell.makerRelayerFee > 0) {
                uint makerRelayerFee = SafeMath.div(SafeMath.mul(sell.makerRelayerFee, price), INVERSE_BASIS_POINT);
                if (sell.paymentToken == address(0)) {
                    receiveAmount = SafeMath.sub(receiveAmount, makerRelayerFee);
                    require(payable(sell.feeRecipient).send(makerRelayerFee), "OvenueExchange::Fee transfer to maker failed!");
                } else {
                    transferTokens(sell.paymentToken, sell.maker, sell.feeRecipient, makerRelayerFee);
                }
            }

            if (sell.takerRelayerFee > 0) {
                uint takerRelayerFee = SafeMath.div(SafeMath.mul(sell.takerRelayerFee, price), INVERSE_BASIS_POINT);
                if (sell.paymentToken == address(0)) {
                    requiredAmount = SafeMath.add(requiredAmount, takerRelayerFee);
                    require(payable(sell.feeRecipient).send(takerRelayerFee), "OvenueExchange::Fee transfer to taker failed!");
                } else {
                    transferTokens(sell.paymentToken, buy.maker, sell.feeRecipient, takerRelayerFee);
                }
            }
        } else {
            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerRelayerFee <= sell.takerRelayerFee, "taker fee is more than maximum fee specified by seller");

            /* The Exchange.sol does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
            require(sell.paymentToken != address(0));

            if (buy.makerRelayerFee > 0) {
                uint makerRelayerFee = SafeMath.div(SafeMath.mul(buy.makerRelayerFee, price), INVERSE_BASIS_POINT);
                transferTokens(sell.paymentToken, buy.maker, buy.feeRecipient, makerRelayerFee);
            }

            if (buy.takerRelayerFee > 0) {
                uint takerRelayerFee = SafeMath.div(SafeMath.mul(buy.takerRelayerFee, price), INVERSE_BASIS_POINT);
                transferTokens(sell.paymentToken, sell.maker, buy.feeRecipient, takerRelayerFee);
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount, "Required sent ether amount is not enough");
            require(payable(sell.maker).send(receiveAmount), "Send funds to seller failed!");
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                require(payable(buy.maker).send(diff), "Send diff amount to buyer failed!");
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    function ordersCanMatch(Order memory buy, Order memory sell)
    internal
    view
    returns (bool)
    {
        return (
            /* Must be opposite-side. */
            (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) && buy.feeRecipient != address(0)) || (sell.feeRecipient != address(0) && buy.feeRecipient == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime)
        );
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        HowToCall operation
    ) internal returns (bool success) {
        if (operation == HowToCall.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }


    /**
    * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(Order memory buy, Sig memory buySig, Order memory sell, Sig memory sellSig)
    internal
    reentrancyGuard
    {
        /* CHECKS */
        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy), "OvenueExchange::Invalid buy order params!");
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }
        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell), "OvenueExchange::Invalid sell order params!");
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }


        /* Must be matchable. */
        require(ordersCanMatch(buy, sell), "OvenueExchange::Order not matched");
        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        uint size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0, "OvenueExchange::Order target is not a contract!");
        /* Must match calldata after replacement, if specified. */
        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buy.callData, sell.callData, buy.replacementPattern);
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sell.callData, buy.callData, sell.replacementPattern);
        }
        require(ArrayUtils.arrayEq(buy.callData, sell.callData), "OvenueExchange::Calldata after replacement is invalid!");

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* Execute funds transfer and pay fees. */
        uint price = executeFundsTransfer(buy, sell);

        bool success = execute(sell.target, 0, sell.callData, sell.howToCall);
        require(success, "OvenueExchange::ERC721 Transfer failed!");

        /* Log match event. */
        emit OrdersMatched(buyHash, sellHash, sell.feeRecipient != address(0) ? sell.maker : buy.maker, sell.feeRecipient != address(0) ? buy.maker : sell.maker, price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ArrayUtils
 * @author Wyvern Protocol Developers
 */
library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * Modifies the provided byte array parameter in place
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
    internal
    pure
    {
        require(array.length == desired.length, "Arrays have different lengths");
        require(array.length == mask.length, "Array and mask have different lengths");

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
    internal
    pure
    returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Drop the beginning of an array
     *
     * @param _bytes array
     * @param _start start index
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayDrop(bytes memory _bytes, uint _start)
    internal
    pure
    returns (bytes memory)
    {

        uint _length = SafeMath.sub(_bytes.length, _start);
        return arraySlice(_bytes, _start, _length);
    }

    /**
     * Take from the beginning of an array
     *
     * @param _bytes array
     * @param _length elements to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayTake(bytes memory _bytes, uint _length)
    internal
    pure
    returns (bytes memory)
    {

        return arraySlice(_bytes, 0, _length);
    }

    /**
     * Slice an array
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @param _bytes array
     * @param _start start index
     * @param _length length to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arraySlice(bytes memory _bytes, uint _start, uint _length)
    internal
    pure
    returns (bytes memory)
    {

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
    internal
    pure
    returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
    internal
    pure
    returns (uint)
    {
        uint conv = uint(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
    internal
    pure
    returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

/**
 * @title ReentrancyGuarded
 * @author Wyvern Protocol Developers
 */
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        require(!reentrancyLock, "Reentrancy detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SaleKindInterface {

    /**
     * Side: buy or sell.
     */
    enum Side { Buy, Sell }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind { FixedPrice, DutchAuction }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint expirationTime)
    pure
    internal
    returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint listingTime, uint expirationTime)
    view
    internal
    returns (bool)
    {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
    view
    internal
    returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        }
        else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(block.timestamp, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }
}