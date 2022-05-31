/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol

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

// File: openzeppelin-solidity\contracts\access\Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: openzeppelin-solidity\contracts\security\Pausable.sol

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
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

// File: openzeppelin-solidity\contracts\security\ReentrancyGuard.sol

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

// File: openzeppelin-solidity\contracts\utils\math\SafeMath.sol

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

// File: openzeppelin-solidity\contracts\utils\math\Math.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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

// File: openzeppelin-solidity\contracts\utils\Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: node_modules\openzeppelin-solidity\contracts\utils\introspection\IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity\contracts\token\ERC721\IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: openzeppelin-solidity\contracts\token\ERC1155\IERC1155.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts\VirgoInstantLiquidity.sol


pragma solidity ^0.8.0;

contract VirgoInstantLiquidity is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    string public constant name = 'VirgoInstantLiquidity';
    string public constant version = 'V1';
    bytes32 public DOMAIN_SEPARATOR;

    //trade signer
    address public operator;
    //virgo nfts owner 
    address public nftOwner; 
    //multiple manager for signing eth withdraw;
    mapping(address => bool) public managers;  
    //index number for manager address(start from 1)  
    mapping(address => uint256) public managerIndexes;  
    //manager signature counts 
    uint256 private constant signCount = 3;   
    //passed manager signature counts 
    uint256 private constant signedCount = 2;    

    //only manager role can sign a request for contract's eth withdraw
    modifier isManager{        
        require(managers[_msgSender()], "caller is not manager"); 
        _;
    }

    event SellERC721Fail(address indexed seller, address indexed tokenAddress, uint256 indexed tokenId);
    event SellERC1155Fail(address indexed seller, address indexed tokenAddress, uint256 indexed tokenId, uint256 amounts);
    event BuyERC721Fail(address indexed buyer, address indexed tokenAddress, uint256 indexed tokenId);
    event BuyERC1155Fail(address indexed buyer, address indexed tokenAddress, uint256 indexed tokenId, uint256 amounts);  
    event EthRecordCreated(address from, address to, uint amount, uint ethRecordId);
    event WithdrawETH(address indexed recipient, uint256 amount); 
    event UpdateOperator(address indexed operatorAddress);
    event UpdateNFTOwner(address nftOwnerAddress);
    event Delegate(address from, address to);
    event CloseTransactions(uint256 ethRecordId);
    //tradeType (Sell:0   Buy:1)
    event OrderInfo(uint256 indexed orderId, uint256 indexed tradeType);

    // keccak256("ERC721Details(address tokenAddr,uint256[] ids,uint256[] price)")
    bytes32 private constant ERC721DETAILS_TYPEHASH = 0xa22e8bf7e119b195a6f04ed0c21241bcc24983bba105b07664defc2dc7e92612;
    // keccak256("ERC1155Details(address tokenAddr,uint256[] ids,uint256[] amounts,uint256[] unitPrice)")
    bytes32 private constant ERC1155DETAILS_TYPEHASH = 0x74f52a5cd1c2e6f4a7c9e679c7e7f1461ce7b3ef57b04c3546269aa80338d6f9;
    // keccak256("sellNFTsForETH(ERC721Details[] _erc721Details,ERC1155Details[] _erc1155Details,uint256 _totalPrice,uint256 _deadline,uint256 _orderId)ERC1155Details(address tokenAddr,uint256[] ids,uint256[] amounts,uint256[] unitPrice)ERC721Details(address tokenAddr,uint256[] ids,uint256[] price)")
    bytes32 private constant SELLNFTSFORETH_TYPEHASH = 0xb73baae7c9bec1201806782a92848dc25312dc35645cbdc8088ac1c5c9ab35c7;
     // keccak256("buyNFTsForETH(ERC721Details[] _erc721Details,ERC1155Details[] _erc1155Details,uint256 _totalPrice,uint256 _deadline,uint256 _orderId)ERC1155Details(address tokenAddr,uint256[] ids,uint256[] amounts,uint256[] unitPrice)ERC721Details(address tokenAddr,uint256[] ids,uint256[] price)")
    bytes32 private constant BUYNFTSFORETH_TYPEHASH = 0x89138277441e31c4f31b04b4d83b8b8048482d6fff3b13a35eb1baa840a245f4;
    

    struct ERC721Details {
        address tokenAddr;        
        uint256[] ids;
        uint256[] price;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
        uint256[] unitPrice;
    }

    struct EthRecord {        
        address from;
        address to;
        uint256 amount;
        uint256 signatureCount;
        bool isEnd;
        mapping (uint256 => bool) signatures;   //get sign status according to manager index number 
    }

    struct RoleUpdateRecord {
        address to;
        uint256 signatureCount;
        bool isUpdating;
        mapping (uint256 => bool) signatures;   //get sign status according to manager index number 
    }    

    mapping (uint256 => EthRecord) private ethRecords;
    uint256[] private pendingEthRecords;     
    uint256 private ethRecordNum;    
    RoleUpdateRecord private operatorRecord;
    RoleUpdateRecord private nftOwnerRecord;

    constructor(address[] memory _managers, address _operator, address _nftOwner) {        
        require(_managers.length == signCount, "Invalid manager address count");  
        require(_operator!= address(0) && !_operator.isContract(), "Invalid  operator address");    
        require(_nftOwner!= address(0) && !_nftOwner.isContract(), "Invalid nftowner address");         
        for (uint256 i = 0; i < _managers.length; i++) {
            require(!_managers[i].isContract(), "Invalid manager address");
            require(!managers[_managers[i]], "Repeated manager address");
            managers[_managers[i]] = true;
            managerIndexes[_managers[i]] = i + 1;
        }  
        operator = _operator;
        nftOwner = _nftOwner;              
        _setDomainSeperator();
    }

    function _setDomainSeperator() internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),                
                bytes32(getChainId()),                             
                address(this) 
            )
        );        
    }

    function getDomainSeperator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }   
   

    //Update operator address using multi-sign
    function updateOperator(address _operatorAddress) external isManager {
        require(_operatorAddress!= address(0) && !_operatorAddress.isContract() && _operatorAddress != operator, "You can not change operator to zero address or contract based address or same  operator address");

        if (!operatorRecord.isUpdating) {
            operatorRecord.to = _operatorAddress;
            operatorRecord.signatureCount = 1;            
            operatorRecord.isUpdating = true;
            operatorRecord.signatures[managerIndexes[_msgSender()]] = true;
        } 
        else {
            require(_operatorAddress == operatorRecord.to,"The new operator address you signed is not requested!");
            require(!operatorRecord.signatures[managerIndexes[_msgSender()]],"You have signed!");
            operatorRecord.signatures[managerIndexes[_msgSender()]] = true;
            operatorRecord.signatureCount+=1;    
            if(operatorRecord.signatureCount >= signedCount){       
                operator = _operatorAddress;
                emit UpdateOperator(_operatorAddress);
                _clearOperatorRecord();
            }
        }        
    }

    //Cancel to update operator address
    function cancelUpdateOperator() external isManager {
         _clearOperatorRecord();
    }

     //Update nft owner address using multi-sign
    function updateNFTOwner(address _nftOwnerAddress) external isManager {
        require(_nftOwnerAddress!= address(0) && !_nftOwnerAddress.isContract() && _nftOwnerAddress != nftOwner, "You can not change nft ownerAddress to zero address or contract based address or same nftowner address");

        if (!nftOwnerRecord.isUpdating) {
            nftOwnerRecord.to = _nftOwnerAddress;
            nftOwnerRecord.signatureCount = 1;            
            nftOwnerRecord.isUpdating = true;
            nftOwnerRecord.signatures[managerIndexes[_msgSender()]] = true;
        } 
        else {
            require(_nftOwnerAddress == nftOwnerRecord.to,"The new nftowner address you signed is not requested!");
            require(!nftOwnerRecord.signatures[managerIndexes[_msgSender()]],"You have signed!");
            nftOwnerRecord.signatures[managerIndexes[_msgSender()]] = true;
            nftOwnerRecord.signatureCount+=1;    
            if(nftOwnerRecord.signatureCount >= signedCount){       
                nftOwner = _nftOwnerAddress;
                emit UpdateNFTOwner(_nftOwnerAddress);
                _clearNFTOwnerRecord();
            }
        }  
    }

    //Cancel to update nft owner address
    function cancelUpdateNFTOwner() external isManager {
         _clearNFTOwnerRecord();
    }

    //Clear the operatorRecord 
    function _clearOperatorRecord() internal {
        operatorRecord.to = address(0);
        operatorRecord.signatureCount = 0;
        operatorRecord.isUpdating = false;
        for (uint256 i = 0; i < signCount; i++) {
            operatorRecord.signatures[i+1] = false;
        }
    }

    //Clear the nftOwnerRecord 
    function _clearNFTOwnerRecord() internal {
        nftOwnerRecord.to = address(0);
        nftOwnerRecord.signatureCount = 0;
        nftOwnerRecord.isUpdating = false;
        for (uint256 i = 0; i < signCount; i++) {
            nftOwnerRecord.signatures[i+1] = false;
        }
    }

    //get operator updating record
    function getOperatorRecord() external view isManager returns(        
        address _to,
        uint256 _signatureCount,
        bool _isUpdating
        )
    {            
        _to = operatorRecord.to;
        _signatureCount = operatorRecord.signatureCount;
        _isUpdating = operatorRecord.isUpdating;
    }    

    //get nftowner updating record
    function getNFTOwnerRecord() external view isManager returns(        
        address _to,
        uint256 _signatureCount,
        bool _isUpdating
        )
    {            
        _to = nftOwnerRecord.to;
        _signatureCount = nftOwnerRecord.signatureCount;
        _isUpdating = nftOwnerRecord.isUpdating;
    }    
    

   //Get the balance of contract
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    //Get the current timestamp of block
    function getBlockTimestamp() public view returns(uint){
        return block.timestamp;
    }

    //Deposit to contract
    function deposit() public payable{}

    //calculate hash for ERC721Details record
    function _hash(
        ERC721Details memory _erc721Detail
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ERC721DETAILS_TYPEHASH,
                _erc721Detail.tokenAddr,
                keccak256(abi.encodePacked(_erc721Detail.ids)),
                keccak256(abi.encodePacked(_erc721Detail.price))
            )
        );
    }

    //calculate hash for ERC1155Details record
    function _hash(
        ERC1155Details memory _erc1155Detail
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ERC1155DETAILS_TYPEHASH,
                _erc1155Detail.tokenAddr,
                keccak256(abi.encodePacked(_erc1155Detail.ids)),
                keccak256(abi.encodePacked(_erc1155Detail.amounts)),
                keccak256(abi.encodePacked(_erc1155Detail.unitPrice))
            )
        );
    }

    //Get message hash to sign for NFTs trade
    function _getMessageHash(
        bytes32 _typeHash,  
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details, 
        uint256 _totalPrice,
        uint256 _deadline,
        uint256 _orderId
    ) internal pure returns (bytes32) {   

        bytes32[] memory erc721Data = new bytes32[](_erc721Details.length);
        bytes32[] memory erc1155Data = new bytes32[](_erc1155Details.length);

        for (uint256 i = 0; i < _erc721Details.length; i++) {
            erc721Data[i] = _hash(_erc721Details[i]);
        }

        for (uint256 i = 0; i < _erc1155Details.length; i++) {
            erc1155Data[i] = _hash(_erc1155Details[i]);
        }

        return keccak256(abi.encode(_typeHash,  
                                    keccak256(abi.encodePacked(erc721Data)), 
                                    keccak256(abi.encodePacked(erc1155Data)),  
                                    _totalPrice,
                                    _deadline,
                                    _orderId));
               
    }

    //Get signed Message 
    function _getSignedMessageHash(bytes32 _messageHash)
        internal
        view
        returns (bytes32)
    {       
        return
            keccak256(
                abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, _messageHash)
            );               
    }
    

    //Verify the trade 
    function _verify(        
        bytes32 _typeHash,
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,  
        uint256 _totalPrice,
        uint256 _deadline,
        uint256 _orderId,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = _getMessageHash(_typeHash, _erc721Details, _erc1155Details, _totalPrice, _deadline, _orderId);
        bytes32 ethSignedMessageHash = _getSignedMessageHash(messageHash);

        return _recoverSigner(ethSignedMessageHash, signature) == operator;
    }

    //Recover Signer
    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    //Calculate r,s,v
    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
   

    //User sell NFTs
    function sellNFTsForETH( 
            ERC721Details[] calldata _erc721Details, 
            ERC1155Details[] calldata _erc1155Details,             
            uint256 _totalPrice,          
            uint256 _deadline,
            uint256 _orderId,
            bytes calldata _signature
    ) external nonReentrant whenNotPaused{
        require(_deadline >= block.timestamp, 'Trade expired');        
        require(_totalPrice > 0, 'Price must be granter than zero');
        require(getBalance() >= _totalPrice, 'The liquidity pool is full');   
        require(_msgSender() != nftOwner, "Seller can not be nftOwner");        
        require(_verify(            
            SELLNFTSFORETH_TYPEHASH,             
            _erc721Details, 
            _erc1155Details, 
            _totalPrice,             
            _deadline, 
            _orderId,
            _signature), 'INVALID_SIGNATURE');

        uint256 _ethAmount = 0;
            
        //transfer ERC721 to contract
        for (uint256 i = 0; i < _erc721Details.length; i++) {
            for (uint256 j = 0; j < _erc721Details[i].ids.length; j++) {
                  uint256 _tokenId = _erc721Details[i].ids[j];
                  if (IERC721(_erc721Details[i].tokenAddr).ownerOf(_tokenId) == _msgSender()) {                        
                        IERC721(_erc721Details[i].tokenAddr).safeTransferFrom(
                              _msgSender(),
                              nftOwner,                              
                              _tokenId
                        );
                        _ethAmount = _ethAmount.add(_erc721Details[i].price[j]);
                  }
                  else
                    emit SellERC721Fail(_msgSender(), _erc721Details[i].tokenAddr, _erc721Details[i].ids[j]);                  
            }
        }

        //transfer ERC1155 to contract
        for (uint256 i = 0; i < _erc1155Details.length; i++) {
            for (uint256 j = 0; j < _erc1155Details[i].ids.length; j++) {  
                uint256 _tokenId = _erc1155Details[i].ids[j]; 
                uint256 _amounts =  _erc1155Details[i].amounts[j]; 
                uint256 _price = _erc1155Details[i].unitPrice[j];                   
                uint256 _balanceOf = IERC1155(_erc1155Details[i].tokenAddr).balanceOf(_msgSender(), _tokenId); 
                if (_balanceOf >= _amounts) {

                    IERC1155(_erc1155Details[i].tokenAddr).safeTransferFrom(
                        _msgSender(),
                        nftOwner,
                        _tokenId,
                        _amounts,
                        ""
                    );
                    _ethAmount = _ethAmount.add(_price.mul(_amounts));
                }    
                else if (_balanceOf > 0) {
                    IERC1155(_erc1155Details[i].tokenAddr).safeTransferFrom(
                        _msgSender(),
                        nftOwner,
                        _tokenId,
                        _balanceOf,
                        ""
                    );
                    _ethAmount = _ethAmount.add(_price.mul(_balanceOf));
                    emit SellERC1155Fail(_msgSender(), _erc1155Details[i].tokenAddr, _tokenId, _amounts.sub(_balanceOf));
                }
                else 
                    emit SellERC1155Fail(_msgSender(), _erc1155Details[i].tokenAddr, _tokenId, _amounts);
            }
        }        

        //transfer ETH to user
        payable(_msgSender()).sendValue(_ethAmount);
        emit OrderInfo(_orderId, 0);
    } 
    

    //User buy NFTs 
    function buyNFTsForETH(              
        ERC721Details[] calldata _erc721Details, 
        ERC1155Details[] calldata _erc1155Details, 
        uint256 _totalPrice, 
        uint256 _deadline, 
        uint256 _orderId,
        bytes calldata _signature
    ) external payable nonReentrant whenNotPaused {
        require(_deadline >= block.timestamp, 'Trade expired');    
        require(_totalPrice > 0, 'Price must be granter than zero');
        require(msg.value >= _totalPrice, "Less than listing price");   
        require(_msgSender() != nftOwner, "Buyer can not be nftOwner");     
        require(_verify(             
            BUYNFTSFORETH_TYPEHASH,
            _erc721Details, 
            _erc1155Details, 
            _totalPrice, 
            _deadline, 
            _orderId,
            _signature), 'INVALID_SIGNATURE');

        uint256 _ethAmount = msg.value;

        //transfer ERC721 to user
        for (uint256 i = 0; i < _erc721Details.length; i++) {
            bool _isApproved = IERC721(_erc721Details[i].tokenAddr).isApprovedForAll(nftOwner, address(this));            
            for (uint256 j = 0; j < _erc721Details[i].ids.length; j++) {
                  uint256 _tokenId = _erc721Details[i].ids[j];
                  if (IERC721(_erc721Details[i].tokenAddr).ownerOf(_tokenId) == nftOwner && _isApproved &&                         
                        _ethAmount >= _erc721Details[i].price[j]) {
                        IERC721(_erc721Details[i].tokenAddr).safeTransferFrom(                              
                              nftOwner,
                              _msgSender(),                              
                              _tokenId
                        );
                        _ethAmount = _ethAmount.sub(_erc721Details[i].price[j]);
                  }
                  else
                    emit BuyERC721Fail(_msgSender(), _erc721Details[i].tokenAddr, _tokenId);                  
            }
        }
        

        //transfer ERC1155 to user
        for (uint256 i = 0; i < _erc1155Details.length; i++) {
            bool _isApproved =  IERC1155(_erc1155Details[i].tokenAddr).isApprovedForAll(nftOwner, address(this));  
            for (uint256 j = 0; j < _erc1155Details[i].ids.length; j++) { 
                uint256 _tokenId = _erc1155Details[i].ids[j]; 
                uint256 _amounts =  _erc1155Details[i].amounts[j]; 
                uint256 _price = _erc1155Details[i].unitPrice[j];                   
                uint256 _balanceOf = IERC1155(_erc1155Details[i].tokenAddr).balanceOf(nftOwner, _tokenId); 
                                
                if (_balanceOf >= _amounts && _isApproved && _ethAmount >= _price.mul(_amounts)) {
                    IERC1155(_erc1155Details[i].tokenAddr).safeTransferFrom(                        
                        nftOwner,
                        _msgSender(),
                        _tokenId,
                        _amounts,
                        ""
                    );
                    _ethAmount = _ethAmount.sub(_price.mul(_amounts));
                }    
                else if (_balanceOf > 0 && _isApproved && _ethAmount >= _price.mul(_balanceOf)) {
                    IERC1155(_erc1155Details[i].tokenAddr).safeTransferFrom(                        
                        nftOwner,
                        _msgSender(),
                        _tokenId,
                        _balanceOf,
                        ""
                    );
                    _ethAmount = _ethAmount.sub(_price.mul(_balanceOf));
                    emit BuyERC1155Fail(_msgSender(), _erc1155Details[i].tokenAddr, _tokenId, 
                    _amounts.sub(_balanceOf));
                }
                else 
                    emit BuyERC1155Fail(_msgSender(), _erc1155Details[i].tokenAddr, _tokenId, 
                    _amounts);
            }        
        }
        
        //transfer remaining ETH to user
        if (_ethAmount > 0)
            payable(_msgSender()).sendValue(_ethAmount);
        emit OrderInfo(_orderId, 1);    
    }   

    //batch query NFT approved status
    function isApprovedForAll(address[] calldata _nftAddress, bool[] calldata _isERC721) external view returns (bool[] memory) {
        require(_nftAddress.length == _isERC721.length, "_nftAddress and _isERC721 length mismatch");
        bool[] memory batchStatuses = new bool[](_nftAddress.length);

        for (uint256 i = 0; i < _nftAddress.length; i++) {
            if (_isERC721[i]) 
                batchStatuses[i] = IERC721(_nftAddress[i]).isApprovedForAll(_msgSender(), address(this));           
            else 
                batchStatuses[i] = IERC1155(_nftAddress[i]).isApprovedForAll(_msgSender(), address(this)); 
       }
       return batchStatuses;
    }


    function supportsInterface(bytes4 _interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return _interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}
    

    //start a eth withdraw request using multiple signatures
    function requestWithdrawETH(address _recipient, uint256 _amount) external{
        require(managers[_msgSender()], "Only manager can withdraw eth!");
        require(_recipient != address(0), "Transfer to the zero address");
        require(address(this).balance >= _amount,"Insufficient Balance");

        uint256 ethRecordId = ethRecordNum++;  
        EthRecord storage ethRecord =ethRecords[ethRecordId];
        ethRecord.from = _msgSender();      
        ethRecord.to = _recipient;
        ethRecord.amount = _amount;
        ethRecord.signatureCount = 1;
        ethRecord.signatures[managerIndexes[_msgSender()]] = true;
        ethRecord.isEnd = false;
        pendingEthRecords.push(ethRecordId);
        emit EthRecordCreated(_msgSender(), _recipient, _amount, ethRecordId);
    }   

    //get pending withdraw transactions list
    function getPendingWithdraws() public isManager view returns(uint256[] memory){    
        return pendingEthRecords;
    }

    //get withdraw transaction's information
    function getWithdrawInfo(uint256 _ethRecordId) external isManager view returns(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _signatureCount,
        bool _isEnd
        )
    {    
        _from = ethRecords[_ethRecordId].from;
        _to = ethRecords[_ethRecordId].to;
        _amount = ethRecords[_ethRecordId].amount;
        _signatureCount = ethRecords[_ethRecordId].signatureCount;
        _isEnd = ethRecords[_ethRecordId].isEnd;
    }    

    //change manager address
    function delegate(address _delegateTo) external isManager{  
        require(_delegateTo != address(0), "You can not delegate to the zero address");
        require(_delegateTo !=_msgSender(),"You can not delegate to yourself");
        require(!managers[_delegateTo],"You can not delegate to other manager");
        managers[_delegateTo] = true;  
        managerIndexes[_delegateTo] = managerIndexes[_msgSender()];
        managers[_msgSender()] = false;
        managerIndexes[_msgSender()] = 0;
        emit Delegate(_msgSender(), _delegateTo);
    }

    //sign for eth withdraw using multi-sign
    function signEthRecord(uint256 _ethRecordId) external isManager{
        EthRecord storage ethRecord = ethRecords[_ethRecordId];
        require(!ethRecord.isEnd, "This transaction is closed");
        require(ethRecord.from != _msgSender(), "You can not sign the transaction you request");
        require(!ethRecord.signatures[managerIndexes[_msgSender()]],"You have signed the transaction!");
        ethRecord.signatures[managerIndexes[_msgSender()]] = true;
        ethRecord.signatureCount+=1;       
        if(ethRecord.signatureCount >= signedCount ){       
            require(address(this).balance >= ethRecord.amount, "Insufficient Balance"); 
            payable(ethRecord.to).sendValue(ethRecord.amount); 
            emit WithdrawETH(ethRecord.to, ethRecord.amount);
            closeTransactions(_ethRecordId);
        }
    }

    //delete withdraw transaction in case the array is over
    function closeTransactions(uint256 _ethRecordId) public isManager{        
        require(!ethRecords[_ethRecordId].isEnd, "This transaction is closed");
        uint256 temp = 0;
        for(uint256 i = 0; i< pendingEthRecords.length; i++){
            if(1 == temp){
                pendingEthRecords[i-1] = pendingEthRecords[i];
            }else if(_ethRecordId == pendingEthRecords[i]){
                temp = 1;
            }
        }
        require(temp == 1, "The _ethRecordId does not exist.");
        delete pendingEthRecords[pendingEthRecords.length - 1];
        pendingEthRecords.pop();
        ethRecords[_ethRecordId].isEnd = true;   
        emit CloseTransactions(_ethRecordId);
    }

    //Pause trade
    function pause() external isManager whenNotPaused {
        _pause();
    }

    //Unpause trade
    function unpause() external isManager whenPaused {
        _unpause();
    }    
}