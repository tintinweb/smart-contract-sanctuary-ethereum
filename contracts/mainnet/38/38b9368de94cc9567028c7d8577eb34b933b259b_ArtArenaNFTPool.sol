/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// Contract code written by @EVMlord

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Strings.sol
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
 
 // Contract code written by @EVMlord

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


// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
// Contract code written by @EVMlord

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol
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


// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



pragma solidity >=0.4.0;
// Contract code written by @EVMlord

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.8.0;
// Contract code written by @EVMlord

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
 
// Contract code written by @EVMlord
 
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

pragma solidity >0.6.0;

/// @dev an interface to interact NFT Contracts
interface IEVMlordNFT {
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

// File: @openzeppelin/contracts/utils/Address.sol
pragma solidity >0.6.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// File: contracts/SmartChefInitializable.sol
pragma solidity >=0.6.12;

contract ArtArenaNFTPool is IERC721Receiver ,Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // treasury Subscription info
    uint256 public subEndBlock = 0;
    uint256 public subLengthDays = 60;
	mapping (address => bool) public subOperator;
    
    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;

    // Whether it is initialized
    bool public isInitialized;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // The block number when reward mining ends.
    uint256 public bonusEndBlock = 0;

    // The block number when reward mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // The reward token
    IBEP20 public rewardToken;

    // The staked token
    IEVMlordNFT public stakedToken;

    // Total Staked tokens
    uint256 public totalStaked = 0;

    // Denominator of fee
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Numerator of fee
    uint256 public tokenFee = 100; 

    uint256 public currentRound = 0;
    uint256 rewardTokenCount = 1;

    address public vault;
    
    mapping(uint256 => RoundInfo) public roundInfo;  

    struct RoundInfo {
        address rwdToken;
        uint256 accTokenPerShare;
        uint256 rewardPerBlock;
        uint256 prevAndCurrentRewardsBalance;
        uint256 PRECISION_FACTOR;
    }  

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) usersInfo;
    mapping (uint256 => address) public tokenOwner;

    mapping(address => mapping(uint256 => uint256)) usersRewardDebt;


    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256[] tokenIds;       
    }

    function userInfo(address _user) external view returns(uint256 amount, uint256 rewardDebt, uint256[] memory tokenIds) {
        amount = usersInfo[_user].amount;
        rewardDebt = usersRewardDebt[_user][currentRound];
        tokenIds = usersInfo[_user].tokenIds;
    }

    function rewardPerBlock() external view returns (uint256) {
        RoundInfo storage round = roundInfo[currentRound];
        return round.rewardPerBlock;
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event EmergencyUnstake(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event _Stake(uint256 _tokenId);
    event _Unstake(uint256 _tokenId);
    event ExtendPoolWithFundsAlreadyInContract();
    event StartNewPool(uint256 _startInDays, uint256 _poolLengthDays);
    event NFTReceived();
    
    constructor() {
        SMART_CHEF_FACTORY = msg.sender;
    }


   // Subscription
    modifier onlySub() {
      require(subOperator[msg.sender] || msg.sender == owner());
      _;
    }
 
    function setSubOperator(address newSubOperator, bool state) external onlySub {
      subOperator[newSubOperator] = state;
    }

    function changeFactory(address newFactory) external onlyOwner {
        SMART_CHEF_FACTORY = payable(newFactory);
    }

    function changeVault(address newVault) external onlyOwner {
        vault = newVault;
    }
    
    function RenewOrExtendSubscriptionSixWeeks() external payable onlySub {
		uint256 _subEndBlock = subEndBlock;
        require(_subEndBlock > 0, "Subscription hasnt started");
        if(block.number <= _subEndBlock) subEndBlock += (subLengthDays * 28800);
        else subEndBlock = block.number + (subLengthDays * 28800); 
        
    }

    /**
    * @notice this function is to extend or renew the pool ==============================================================
    */

    function increaseAPR() external onlySub {
        RoundInfo storage round = roundInfo[currentRound];
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
		uint256 _bonusEndBlock = bonusEndBlock;
        require(_bonusEndBlock > block.number, "Pool has Ended, use startNewPool");
        require(totalNewReward > 0, "no NewRewards availavble, send tokens First");

        uint256 blocksLeft = _bonusEndBlock - block.number;
        uint256 addedRPB = totalNewReward / blocksLeft;
        round.rewardPerBlock += addedRPB;

            // check how much new rewards are available
            round.prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
       
        _updatePool();

    }

    function ExtendPool() external onlySub {
        RoundInfo storage round = roundInfo[currentRound];
		uint256 _bonusEndBlock = bonusEndBlock;
        require(_bonusEndBlock > block.number, "Pool has Ended, use startNewPool");
          
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        require(totalNewReward > 0, "No funds to start new pool with");
        
            // check how much new rewards are available
            round.prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));        
        
        // increase block count for pool
        uint256 timeExtended = totalNewReward / round.rewardPerBlock;
        bonusEndBlock = bonusEndBlock + (timeExtended);
        if(msg.sender != owner()) require(bonusEndBlock <= subEndBlock, "Subscription runs out before this end block renewSubscription");

    }

    function startNewPoolOrRound( uint256 _startInDays, uint256 _poolLengthDays ) external onlySub {
        RoundInfo storage round = roundInfo[currentRound];
        // make sure pool has ended
        require(bonusEndBlock < block.number, "Pool has not ended, Try Extending");
        
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        require(totalNewReward > 0, "No funds to start new pool with");
        
        // setup for calculations
        uint256 startInBlocks;
        uint256 totalBlocks;
        startInBlocks = _startInDays * 28800;
        totalBlocks = _poolLengthDays;

            // check how much new rewards are available            
            round.prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
        
        // set last reward block to new start block
        startBlock = (block.number + startInBlocks);
        lastRewardBlock = startBlock;
        
        // set end block of new pool
        bonusEndBlock = startBlock + totalBlocks;
        if(msg.sender != owner()) require(bonusEndBlock <= subEndBlock, "Subscription runs out before this end block renewSubscription");
        
        // set new rewards per block based off the new information
        round.rewardPerBlock = totalNewReward / totalBlocks;
        if(subEndBlock == 0) subEndBlock = block.number + (subLengthDays * 28800);
        
        
    }

    function setNextRewardToken(IBEP20 _rewardToken) external onlySub {
        require(bonusEndBlock < block.number, "Pool has not ended, Try Extending");
        require(rewardToken != _rewardToken,"same token");
        
        // final update
        _updatePool();
        // set new token reward
        rewardToken = _rewardToken;    

        bool  isOld =false;
        for(uint i=0; i<rewardTokenCount; i++) {
            if(roundInfo[i].rwdToken == address(_rewardToken)) {
                currentRound = i;
                isOld = true;
            }
        }
        if(!isOld){
            // NEW TOKEN
            currentRound = rewardTokenCount;
            rewardTokenCount++;
            // set new rounds reward token
            RoundInfo storage round = roundInfo[currentRound];
            round.rwdToken = address(rewardToken);
            uint256 decimalsRewardToken = uint256(rewardToken.decimals());
            require(decimalsRewardToken < 30, "Must be inferior to 30");
            round.PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));
            // set rewardscounter
            round.prevAndCurrentRewardsBalance = 0;
        }
        
        _updatePool();

    }

    function setupTokens(
        IEVMlordNFT _stakedToken,
        IBEP20 _rewardToken
        ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == SMART_CHEF_FACTORY, "Not factory");
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;


        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        RoundInfo storage round = roundInfo[currentRound];
        round.PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));
        
        // set rewardscounter
        round.prevAndCurrentRewardsBalance = 0;
        round.rwdToken = address(rewardToken);
        isInitialized = true;
    }

    /// @notice Stake 1 or many NFTs.
    // claims rewards
    function stake(uint256[] memory tokenIds) public {
        UserInfo storage user = usersInfo[msg.sender];
        RoundInfo storage round = roundInfo[currentRound];
        claim();
        
        for (uint i = 0; i < tokenIds.length; i++) {
            _stake(tokenIds[i]);
        }
        
        usersRewardDebt[msg.sender][currentRound] = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR);
    }

    /// @notice Stake all your NFTs and earn reward tokens. 
    function stakeAll() external {
        uint256[] memory TokenIDs = walletOfOwner(msg.sender);
        require(TokenIDs.length > 0, "You have no NFTs of this kind");
        
        stake(TokenIDs);
    }

    /*
     * @notice Used internall to stake TokenId's
     */
    function _stake(uint256 _tokenId) internal {
        UserInfo storage user = usersInfo[msg.sender];
        
            user.tokenIds.push(_tokenId);
            tokenOwner[_tokenId] = msg.sender;

                stakedToken.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
                );

            user.amount = user.amount.add(1);
            totalStaked += (1);

        emit _Stake( _tokenId);
    }

    /// @notice unstake 1 or Multiple TokenId's. 
    function unstake (uint256[] memory tokenIds) public {
        UserInfo storage user = usersInfo[msg.sender];
        RoundInfo storage round = roundInfo[currentRound];
        claim();
        for (uint i = 0; i < tokenIds.length; i++) {
            uint TokenId = tokenIds[i];
            if (tokenOwner[TokenId] == msg.sender) {
                _unstake(TokenId);
            }
        }
        usersRewardDebt[msg.sender][currentRound] = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR);
    }

    /*
    * @notice unstake all TokenId's listed in the userInfo memory.
    */
    function unstakeAll() external {
        UserInfo storage user = usersInfo[msg.sender];
        require(user.tokenIds.length > 0, "You have no NFTs of this kind");
        unstake(user.tokenIds);
    }

    /*
     * @notice Withdraw staked NFT's used interally from Stake all and Stake commands
     */
    function _unstake(uint256 _tokenId) internal {
       UserInfo storage user = usersInfo[msg.sender];
        require(tokenOwner[_tokenId] == msg.sender, "You are Not the Owner of this NFT");

            for (uint256 i; i<user.tokenIds.length; i++) {
                if (user.tokenIds[i] == _tokenId) {
                    user.tokenIds[i] = user.tokenIds[user.tokenIds.length - 1];
                    user.tokenIds.pop();
                }
            }
           
        delete tokenOwner[_tokenId];
        user.amount = user.amount.sub(1);

            stakedToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
            );

        totalStaked -= 1;

        emit _Unstake(_tokenId);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    
    function emergencyUnstakeALL() public {
        UserInfo storage user = usersInfo[msg.sender];
        require(user.tokenIds.length > 0, "You have no NFTs of this kind");
        for (uint i = 0; i < user.tokenIds.length; i++) {
            uint TokenId = user.tokenIds[i];
            if (tokenOwner[TokenId] == msg.sender) {
                _unstake(TokenId);
            }
        }
        for(uint i = 0; i <= currentRound; i++){
            usersRewardDebt[msg.sender][i] = 0;
        
        }
      emit EmergencyUnstake(msg.sender,user.tokenIds.length);
    }

   

    // Claim rewards or Harvest rewards
     function claim() internal {
        UserInfo storage user = usersInfo[msg.sender];
        RoundInfo storage round = roundInfo[currentRound];
        _updatePool();
        
        uint256 pending = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR).sub(usersRewardDebt[msg.sender][currentRound]);
            
            if (pending > 0) {

                uint256 maintainanceFee = pending.mul(tokenFee).div(FEE_DENOMINATOR);
				uint256 actualStakingReward = pending.sub(maintainanceFee);
				
				rewardToken.safeTransfer(address(vault), maintainanceFee);
				
                rewardToken.safeTransfer(address(msg.sender), actualStakingReward);
                round.prevAndCurrentRewardsBalance -= pending;
            }
            (,,bool hasOldRewards) = prevPendingRewards(msg.sender);
            if(hasOldRewards) claimPrevRewards();
    } 

    // Claim rewards or Harvest rewards
     function claimReward() public {
        
        _updatePool();
        UserInfo storage user = usersInfo[msg.sender];
        RoundInfo storage round = roundInfo[currentRound];
        uint256 pending = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR).sub(usersRewardDebt[msg.sender][currentRound]);
            
            if (pending > 0) {

                uint256 maintainanceFee = pending.mul(tokenFee).div(FEE_DENOMINATOR);
				uint256 actualStakingReward = pending.sub(maintainanceFee);
				
				rewardToken.safeTransfer(address(vault), maintainanceFee);
				
                rewardToken.safeTransfer(address(msg.sender), actualStakingReward);
                usersRewardDebt[msg.sender][currentRound] = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR);
                round.prevAndCurrentRewardsBalance -= pending;
            }
} 
    

    
    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     * @dev All tokens left in the contract for 3 months become OWNERLESS and can be claimed.
     */ 
    function recoverTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
            require(_tokenAddress != address(stakedToken), "Cannot be staked token");
            require(block.number > bonusEndBlock, "Pool Must be ended");

            IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
 
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

   

    function stopReward() external onlyOwner {
         RoundInfo storage round = roundInfo[currentRound];
        _updatePool();
        uint256 totalNewReward = checkTotalNewRewards();
        uint256 timeLeft = bonusEndBlock - block.number;
        uint256 rewardsLeft = round.rewardPerBlock * timeLeft;
       
            // check how much new rewards are available
            round.prevAndCurrentRewardsBalance = rewardToken.balanceOf(address(this));
        
        round.prevAndCurrentRewardsBalance -= rewardsLeft;
        round.prevAndCurrentRewardsBalance -= totalNewReward;
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number > startBlock, "Pool is yet to start");
        RoundInfo storage round = roundInfo[currentRound];
        round.rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        
        RoundInfo storage round = roundInfo[currentRound];
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;
		
		// set new rewards per block based off the new information
		uint256 totalBlocks = _bonusEndBlock - _startBlock;
		uint256 totalNewReward = rewardToken.balanceOf(address(this)); 
        require(totalNewReward > 0, "No funds to start new pool with");
        round.rewardPerBlock = totalNewReward / totalBlocks;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo memory user = usersInfo[_user];
        RoundInfo memory round = roundInfo[currentRound];
        uint256 stakedTokenSupply = totalStaked;
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(round.rewardPerBlock);
            uint256 adjustedTokenPerShare =
                round.accTokenPerShare.add(cakeReward.mul(round.PRECISION_FACTOR).div(stakedTokenSupply));
            return user.amount.mul(adjustedTokenPerShare).div(round.PRECISION_FACTOR).sub(usersRewardDebt[_user][currentRound]);
        } else {
            return user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR).sub(usersRewardDebt[_user][currentRound]);
        }
    }

    function prevPendingRewards(address _user) public view returns (address[] memory _rwdToken, uint256[] memory _amount, bool hasRewards) {
        UserInfo memory user = usersInfo[_user];
        _rwdToken = new address[](rewardTokenCount);
        _amount = new uint256[](rewardTokenCount);
        hasRewards = false;
        for (uint i = 0; i < rewardTokenCount; i++) {
            if( i != currentRound){
                RoundInfo memory round = roundInfo[i];
                _rwdToken[i] = round.rwdToken;
                _amount[i] = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR).sub(usersRewardDebt[msg.sender][i]);
                if (_amount[i] > 0) hasRewards = true;
            }
        }
        return (_rwdToken, _amount, hasRewards);
    }

    function claimPrevRewards() public {
        UserInfo storage user = usersInfo[msg.sender];

        for (uint i = 0; i < rewardTokenCount; i++){
            if( i != currentRound){            
                RoundInfo memory round = roundInfo[i];
                uint256 pending = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR).sub(usersRewardDebt[msg.sender][i]);
            
                if (pending > 0) {
                    IBEP20 rwd = IBEP20(round.rwdToken);
                    try rwd.transfer(address(msg.sender), pending) {} catch {}
                    usersRewardDebt[msg.sender][i] = user.amount.mul(round.accTokenPerShare).div(round.PRECISION_FACTOR);
                }
            }
        }
    }

    // return ONLY the token id's for current user
    function getTokenIds(address _user) external view returns (uint256[] memory) {
         UserInfo memory user = usersInfo[_user];
         return (user.tokenIds);
    }

    function getUserPoolInfo(address _user) external view returns (
                uint256 _balance,
                uint256[] memory _tokenIds,
                uint256 _pendingReward
                ) {
        UserInfo memory user = usersInfo[_user];
        return (user.amount, user.tokenIds, pendingReward(_user));
    }

    function getMainPoolInfo() external view returns (
        uint256 _rewardPerBlock,
        uint256 _totalStaked,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _tokenFee
        ) {
            RoundInfo memory round = roundInfo[currentRound];
            return (round.rewardPerBlock, totalStaked, startBlock, bonusEndBlock, tokenFee);  
        }

     function checkTotalNewRewards() public view returns(uint256 totalNewReward){
            RoundInfo memory round = roundInfo[currentRound];
            totalNewReward = (rewardToken.balanceOf(address(this)) - round.prevAndCurrentRewardsBalance);    
    }

    function NEWRewardWithdraw() external onlyOwner {
        uint256 totalNewReward = checkTotalNewRewards();
        require(totalNewReward > 0, "No New Reward Tokens to Withdrawl");
        rewardToken.safeTransfer(address(msg.sender), totalNewReward);
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 stakedTokenSupply = totalStaked;

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        RoundInfo storage round = roundInfo[currentRound];
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(round.rewardPerBlock);
        round.accTokenPerShare = round.accTokenPerShare.add(cakeReward.mul(round.PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = stakedToken.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = stakedToken.tokenOfOwnerByIndex(_owner, i);
        }
    return tokenIds;
    }
    
     function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4){
        _operator;
        _from;
        _tokenId;
        _data;
        emit NFTReceived();
        return 0x150b7a02;
    }
   
    function setTokenFee(uint256 newTokenFee) public onlyOwner {
      tokenFee = newTokenFee;
    }
    
// Contract code written by @EVMlord
}