/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/game/interface/IADIToken.sol

pragma solidity ^0.8.0;

enum ADIType {
    Empty,
    Role,
    Weapon,
    Breakthrough
}

enum ADIGrade {
    N,
    R,
    S,
    SR,
    SSR
}


interface IADIToken {
    function typeOf(uint256 tokenID) external view returns (ADIType);

    function gradeOf(uint256 tokenID) external view returns (ADIGrade);
}

// File: contracts/game/interface/IGameToken.sol

pragma solidity ^0.8.0;

interface IGameToken {
    function transferFromDelegate(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mintRewardTo(address owner, uint256 amount) external;

    function burnFromDelegate(address from, uint256 amount) external;
}

// File: contracts/game/interface/IFighting.sol

pragma solidity ^0.8.0;

interface IFighting {
    function finalCombatEffectiveness(uint256 roleID,uint256 weaponID,bool hasWeapon) external view returns (uint256);
}

// File: contracts/game/GameScene.sol


pragma solidity ^0.8.0;












contract GameFactory is Ownable, ERC721Holder{ 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // 用户信息.
    struct UserInfo {
        uint256 power;  // 算力
        uint256 reward; // 累计未提取收益
        uint256 taked; // 已提取收益
        uint256 rewardDebt; // 债务率
        uint256 lastBlock; // 上一次操作时间
        //uint256[] deposits; // 投入的NFT
    }
    // 副本.
    struct SceneInfo {
        uint256 allocPoint;   // 产出因子
        uint256 lastBlock;  // 上一次操作区块
        uint256 totalPower; // 副本当前总算力
        uint256 accPowerPerShare; // 副本算力累计收益率
        bool status; //状态(软删除)
        ADIGrade minGrade; //最小品阶
        ADIGrade maxGrade; //最大品阶
        uint256 energyRate; //能量比率(满额10000)

    }
    // 产能区间.
    struct Capacity {
        uint256 output; // 每块产出
        uint256 startPower; // 启动算力
        uint256 jumpPower; // 跃迁算力(为0代表无限) 
        bool status; //状态(软删除)
    }
    // 战力计算
    address public fighiting;
    // ADI
    address public ADIToken;
    // 金币
    address public gold;
    // 矿石
    address public mineral;
    // 能量
    address public energy;
    // 副本集合.
    SceneInfo[] public sceneInfos;
    // 用户副本记录.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => mapping (address => uint256[])) public userDeposits;
     // 产能列表.
    Capacity[] public capacitys;
    // 总产出因子 所有副本集合.
    uint256 public totalAllocPoint;
    // 总算力.
    uint256 public totalPower;
    // 启动算力.
    uint256 public starPower;
    // 每块产出.
    uint256 public blockOutput;
    // 已产出.
    uint256 public haveOutput;
    // 上一次块产改变的区块
    uint256 private changeBlock;
   

    event Deposit(address indexed user, uint256 indexed id, uint256 roleID,uint256 weaponID,bool hasWeapon);
    event Withdraw(address indexed user, uint256 indexed id, uint256[] tokenID);
    event GetReward(address indexed user, uint256 indexed id, uint256 reward, uint256 energy);


    //constructor() public {}

    // 副本长度.
    function sceneLength() external view returns (uint256) {
        return sceneInfos.length;
    }
    // 产能区间长度.
    function capacityLength() external view returns (uint256) {
        return capacitys.length;
    }
    //基础配置
    function _setConfig(
        address _fighiting,
        address _ADIToken,
        address _gold,
        address _mineral,
        address _energy
    ) external onlyOwner {
        fighiting = _fighiting;
        ADIToken = _ADIToken;
        gold = _gold;
        mineral = _mineral;
        energy = _energy;
    }

    // 设置开始战力
    function _setStartPower(uint256 _power) external onlyOwner {
        starPower = _power;
        if(totalPower >= starPower){
            massUpdateScenes();
        }
    }

    // 添加产能区间.
    function _addCapacity(
        uint256 _output,
        uint256 _startPower,
        uint256 _jumpPower
    ) external {
        require(_jumpPower > _startPower || _jumpPower == 0, "jumpPower need greater than startPower");
        if(totalPower >= starPower){
            massUpdateScenes();
        }
        capacitys.push(Capacity({
            output: _output,
            startPower: _startPower,
            jumpPower: _jumpPower,
            status:true
        }));
        
    }
    // 修改产能区间.
    function _setCapacity(
        uint256 _id,
        uint256 _output,
        uint256 _startPower,
        uint256 _jumpPower,
        bool _status
    ) external onlyOwner {
        require(capacitys.length.sub(1) >= _id , "capacity no exist");
        if(totalPower >= starPower){
            massUpdateScenes();
        }
        capacitys[_id].output = _output;
        capacitys[_id].startPower = _startPower;
        capacitys[_id].jumpPower = _jumpPower;
        capacitys[_id].status = _status;
        
    }

    // 添加副本
    function _addScene(uint256 _allocPoint,uint256 _rate,bool _status,ADIGrade _minGrade,ADIGrade _maxGrade) external {  
        if(totalPower >= starPower){
            massUpdateScenes();
        } 
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        sceneInfos.push(SceneInfo({
            allocPoint: _allocPoint,
            lastBlock: block.number,
            totalPower: 0,
            accPowerPerShare: 0,
            status: _status,
            minGrade : _minGrade,
            maxGrade : _maxGrade,
            energyRate : _rate
        }));
        
    }

    // 修改副本.
    function _setScene(uint256 _id,uint256 _allocPoint,uint256 _rate,bool _status,ADIGrade _minGrade,ADIGrade _maxGrade) external {
        require(sceneInfos.length.sub(1) >= _id , "scene no exist");
        if(totalPower >= starPower){
            massUpdateScenes();
        }
        if(sceneInfos[_id].status && _status){
            //修改副本
            totalAllocPoint = totalAllocPoint.sub(sceneInfos[_id].allocPoint).add(_allocPoint);
        }else if (!sceneInfos[_id].status && _status){
            //开启副本
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }else if (sceneInfos[_id].status && !_status){
            //关闭副本
            totalAllocPoint = totalAllocPoint.sub(_allocPoint);
        }else{
            //无效操作
            totalAllocPoint = totalAllocPoint;
        }
        sceneInfos[_id].allocPoint = _allocPoint;
        sceneInfos[_id].status = _status;
        sceneInfos[_id].lastBlock = block.number;
        sceneInfos[_id].minGrade = _minGrade;
        sceneInfos[_id].maxGrade = _maxGrade;
        sceneInfos[_id].energyRate = _rate;
                
    }

    //设置区块产出
    function setBlockOutput(uint256 _output) internal {
        massUpdateScenes();
        haveOutput = blockOutput.mul(block.number.sub(changeBlock));
        changeBlock = block.number;
        blockOutput = _output;
        
    }

    // 当前区块产能（遍历产能区间）
    function setAccPerShare() internal {
        if(totalPower >= starPower){
            for(uint i = 0; i < capacitys.length; i++){
                if(capacitys[i].status){
                    bool isHaveCapacity = totalPower >= capacitys[i].startPower && (totalPower < capacitys[i].jumpPower || capacitys[i].jumpPower == 0);
                    if(isHaveCapacity && blockOutput != capacitys[i].output){
                        setBlockOutput(capacitys[i].output);
                        break;
                    }
                } 
            }
        }else{
            if(blockOutput != 0){
                setBlockOutput(0);
            }
            
        }       
    }

    //是否可以改变块产出
    function canChangeOutput(uint256 _totalPower) internal view returns (bool){
        if(_totalPower >= starPower){
            for(uint i = 0; i < capacitys.length; i++){
                if(capacitys[i].status){
                    bool isHaveCapacity = _totalPower >= capacitys[i].startPower && (_totalPower < capacitys[i].jumpPower || capacitys[i].jumpPower == 0);
                    if(isHaveCapacity && blockOutput != capacitys[i].output){
                        return true;
                    }
                } 
            }
        }else{
            if(blockOutput != 0){
                return true;
            }
            
        }
        return false;
    }


    //获取副本阶段收益率
    function getPowerPerShare(uint256 _id) internal view returns (uint256) {
        SceneInfo memory scene = sceneInfos[_id];
        if((!scene.status || totalAllocPoint == 0)|| scene.totalPower == 0){
            return 0;
        }else{
            return blockOutput
                    .mul(scene.allocPoint)
                    .mul(block.number.sub(scene.lastBlock))
                    .mul(1e12)
                    .div(totalAllocPoint.mul(scene.totalPower));
        }

    }

    // 查询收益
    function earned(uint256 _id, address _user) public view returns (uint256) {
        SceneInfo memory scene = sceneInfos[_id];
        UserInfo memory user = userInfo[_id][_user];
        return user.reward.add(user.power
                .mul(scene.accPowerPerShare.add(getPowerPerShare(_id)).sub(user.rewardDebt))
                .div(1e12));
    }

    // 更新全部副本收益
    function massUpdateScenes() internal {
        for (uint256 i = 0; i < sceneInfos.length; ++i) {
            updateScene(i);
        }
    }

    // 更新副本收益累计.
    function updateScene(uint256 _id) internal {
       sceneInfos[_id].accPowerPerShare = sceneInfos[_id].accPowerPerShare.add(getPowerPerShare(_id));
       sceneInfos[_id].lastBlock = block.number;
    }

    // 进入副本
    function deposit( uint256 _id, uint256 _roleID,uint256 _weaponID,bool _hasWeapon) external {
        
        SceneInfo storage scene = sceneInfos[_id];
        UserInfo storage user = userInfo[_id][msg.sender];
        require(
            IADIToken(ADIToken).gradeOf(_id) >= scene.minGrade && IADIToken(ADIToken).gradeOf(_id) <= scene.maxGrade,
            'role is not good'
            );
        uint256 power = IFighting(fighiting).finalCombatEffectiveness(_roleID, _weaponID, _hasWeapon);
        uint256 _totalPower = totalPower.add(power);
        totalPower = _totalPower;
        if(canChangeOutput(_totalPower)){
            setAccPerShare();
        }else{
            updateScene(_id);
        }
        IERC721(ADIToken).safeTransferFrom(msg.sender, address(this), _roleID);
        //user.deposits.push(_roleID);
        userDeposits[_id][msg.sender].push(_roleID);
        if(_hasWeapon){
            IERC721(ADIToken).safeTransferFrom(msg.sender, address(this), _weaponID);
            userDeposits[_id][msg.sender].push(_weaponID);
            //user.deposits.push(_weaponID);
        }
        
        user.reward = user.reward.add(user.power.mul(scene.accPowerPerShare.sub(user.rewardDebt)).div(1e12));
        user.rewardDebt = scene.accPowerPerShare;
        user.lastBlock = block.number;
        user.power = user.power.add(power);
        
        scene.totalPower = scene.totalPower.add(power);

        emit Deposit(msg.sender, _id,_roleID,_weaponID,_hasWeapon);
    }

    // 撤出副本.
    function withdraw(uint256 _id) external {
        SceneInfo storage scene = sceneInfos[_id];
        UserInfo storage user = userInfo[_id][msg.sender];
        uint256 _totalPower = totalPower.sub(user.power);
        totalPower = _totalPower;
        if(canChangeOutput(_totalPower)){
            setAccPerShare();
        }else{
            updateScene(_id);
        }
        for (uint256 i = 0; i < userDeposits[_id][msg.sender].length; i++) {
            IERC721(ADIToken).safeTransferFrom(address(this),msg.sender, userDeposits[_id][msg.sender][i]);            
        }

        user.reward = user.reward.add(user.power.mul(scene.accPowerPerShare.sub(user.rewardDebt)).div(1e12));
        user.rewardDebt = scene.accPowerPerShare;
        user.lastBlock = block.number;
        user.power = 0;
        
        scene.totalPower = scene.totalPower.sub(user.power);
        
        emit Withdraw(msg.sender, _id,userDeposits[_id][msg.sender]);
        delete userDeposits[_id][msg.sender];
    }

    // 提取收益.
    function getReward(uint256 _id) public {
        UserInfo storage user = userInfo[_id][msg.sender];
        updateScene(_id);
        uint256 reward = earned(_id, msg.sender);
        uint256 needEnergy = reward.mul(1e12).mul(sceneInfos[_id].energyRate.div(10000)).div(1e12);
        IGameToken(energy).burnFromDelegate(msg.sender, needEnergy);
        IGameToken(gold).mintRewardTo(msg.sender, reward);
        IGameToken(mineral).mintRewardTo(msg.sender, reward);
        user.reward = 0;
        user.rewardDebt = sceneInfos[_id].accPowerPerShare;
        user.lastBlock = block.number;
        user.taked = user.taked.add(reward);

        emit GetReward(msg.sender, _id,reward,needEnergy);
    }

    // 提取收益需要的能量
    function getRewardNeedEnergy(uint256 _id,address _user) external view returns(uint256) {
        uint256 reward = earned(_id, _user);
        return reward.mul(1e12).mul(sceneInfos[_id].energyRate.div(10000)).div(1e12);
    }

    // 一键提取所有收益
    function getRewardAll() external {
        for(uint256 i = 0; i < sceneInfos.length; i++ ){
            getReward(i);
        }
    }
    
}