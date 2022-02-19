/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]

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


// File contracts/interfaces/IBrain.sol

pragma solidity ^0.8.0;


interface IBrain {
    function getURIVersion(uint tokenId) external view returns (uint);
}


// File contracts/interfaces/IBrainOracle.sol

pragma solidity ^0.8.0;


interface IBrainOracle {
    function getRandFightNum() external view returns (uint);
}


// File contracts/contracts/OZ_forks/IaNFT.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IaNFT is IERC165 {
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

    function safeTransferFromBrain(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFromBrain(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
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


// File contracts/interfaces/IMetaDungeon.sol

pragma solidity ^0.8.0;

interface IMetaDungeon is IaNFT {

    function baseURI() external view returns (string memory);

    function setBaseURI(string memory newBaseTokenURI) external;

    function mint(address to, address brain) external returns (uint);

    function mint(address to, address brain, string[] memory tokenURIs) external returns (uint tokenId);

    function setTokenURIs(uint256 tokenId, string[] memory tokenURIs) external;

    function pause() external;

    function unpause() external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/contracts/mocks/autonomy/interfaces/IRegistry.sol

pragma solidity 0.8.6;

/**
* @title    Registry
* @notice   A contract which is essentially a glorified forwarder.
*           It essentially brings together people who want things executed,
*           and people who want to do that execution in return for a fee.
*           Users register the details of what they want executed, which
*           should always revert unless their execution condition is true,
*           and executors execute the request when the condition is true.
*           Only a specific executor is allowed to execute requests at any
*           given time, as determined by the StakeManager, which requires
*           staking AUTO tokens. This is infrastructure, and an integral
*           piece of the future of web3. It also provides the spark of life
*           for a new form of organism - cyber life. We are the gods now.
* @author   Quantaf1re (James Key)
*/
interface IRegistry {
    
    // The address vars are 20b, total 60, calldata is 4b + n*32b usually, which
    // has a factor of 32. uint112 since the current ETH supply of ~115m can fit
    // into that and it's the highest such that 2 * uint112 + 3 * bool is < 256b
    struct Request {
        address payable user;
        address target;
        address payable referer;
        bytes callData;
        uint112 initEthSent;
        uint112 ethForCall;
        bool verifyUser;
        bool insertFeeAmount;
        bool payWithAUTO;
        bool isAlive;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                      Hashed Requests                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Creates a new request, logs the request info in an event, then saves
     *          a hash of it on-chain in `_hashedReqs`. Uses the default for whether
     *          to pay in ETH or AUTO
     * @param target    The contract address that needs to be called
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param ethForCall    The ETH to send with the call
     * @param verifyUser  Whether the 1st input of the calldata equals the sender.
     *                      Needed for dapps to know who the sender is whilst
     *                      ensuring that the sender intended
     *                      that fcn and contract to be called - dapps will
     *                      require that msg.sender is the Verified Forwarder,
     *                      and only requests that have `verifyUser` = true will
     *                      be forwarded via the Verified Forwarder, so any calls
     *                      coming from it are guaranteed to have the 1st argument
     *                      be the sender
     * @param insertFeeAmount     Whether the gas estimate of the executor should be inserted
     *                      into the callData
     * @param isAlive       Whether or not the request should be deleted after it's executed
     *                      for the first time. If `true`, the request will exist permanently
     *                      (tho it can be cancelled any time), therefore executing the same
     *                      request repeatedly aslong as the request is executable,
     *                      and can be used to create fully autonomous contracts - the
     *                      first single-celled cyber life. We are the gods now
     * @return id   The id of the request, equal to the index in `_hashedReqs`
     */
    function newReq(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool isAlive
    ) external payable returns (uint id);

    /**
     * @notice  Creates a new request, logs the request info in an event, then saves
     *          a hash of it on-chain in `_hashedReqs`
     * @param target    The contract address that needs to be called
     * @param referer       The referer to get rewarded for referring the sender
     *                      to using Autonomy. Usally the address of a dapp owner
     * @param callData  The calldata of the call that the request is to make, i.e.
     *                  the fcn identifier + inputs, encoded
     * @param ethForCall    The ETH to send with the call
     * @param verifyUser  Whether the 1st input of the calldata equals the sender.
     *                      Needed for dapps to know who the sender is whilst
     *                      ensuring that the sender intended
     *                      that fcn and contract to be called - dapps will
     *                      require that msg.sender is the Verified Forwarder,
     *                      and only requests that have `verifyUser` = true will
     *                      be forwarded via the Verified Forwarder, so any calls
     *                      coming from it are guaranteed to have the 1st argument
     *                      be the sender
     * @param insertFeeAmount     Whether the gas estimate of the executor should be inserted
     *                      into the callData
     * @param payWithAUTO   Whether the sender wants to pay for the request in AUTO
     *                      or ETH. Paying in AUTO reduces the fee
     * @param isAlive       Whether or not the request should be deleted after it's executed
     *                      for the first time. If `true`, the request will exist permanently
     *                      (tho it can be cancelled any time), therefore executing the same
     *                      request repeatedly aslong as the request is executable,
     *                      and can be used to create fully autonomous contracts - the
     *                      first single-celled cyber life. We are the gods now
     * @return id   The id of the request, equal to the index in `_hashedReqs`
     */
    function newReqPaySpecific(
        address target,
        address payable referer,
        bytes calldata callData,
        uint112 ethForCall,
        bool verifyUser,
        bool insertFeeAmount,
        bool payWithAUTO,
        bool isAlive
    ) external payable returns (uint id);

    /**
     * @notice  Gets all keccak256 hashes of encoded requests. Completed requests will be 0x00
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqs() external view returns (bytes32[] memory);

    /**
     * @notice  Gets part of the keccak256 hashes of encoded requests. Completed requests will be 0x00.
     *          Needed since the array will quickly grow to cost more gas than the block limit to retrieve.
     *          so it can be viewed in chunks. E.g. for an array of x = [4, 5, 6, 7], x[1, 2] returns [5],
     *          the same as lists in Python
     * @param startIdx  [uint] The starting index from which to start getting the slice (inclusive)
     * @param endIdx    [uint] The ending index from which to start getting the slice (exclusive)
     * @return  [bytes32[]] An array of all hashes
     */
    function getHashedReqsSlice(uint startIdx, uint endIdx) external view returns (bytes32[] memory);

    /**
     * @notice  Gets the total number of requests that have been made, hashed, and stored
     * @return  [uint] The total number of hashed requests
     */
    function getHashedReqsLen() external view returns (uint);
    
    /**
     * @notice      Gets a single hashed request
     * @param id    [uint] The id of the request, which is its index in the array
     * @return      [bytes32] The sha3 hash of the request
     */
    function getHashedReq(uint id) external view returns (bytes32);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Bytes Helpers                     //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice      Encode a request into bytes
     * @param r     [request] The request to be encoded
     * @return      [bytes] The bytes array of the encoded request
     */
    function getReqBytes(Request memory r) external pure returns (bytes memory);

    function insertToCallData(bytes calldata callData, uint expectedGas, uint startIdx) external pure returns (bytes memory);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                         Executions                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request.
     *              Typically known by seeing the `HashedReqAdded` event emitted with `newReq`
     * @param expectedGas   [uint] The gas that the executor expects the execution to cost,
     *                      known by simulating the the execution of this tx locally off-chain.
     *                      This can be forwarded as part of the requested call such that the
     *                      receiving contract knows how much gas the whole execution cost and
     *                      can do something to compensate the exact amount (e.g. as part of a trade).
     *                      Cannot be more than 10% above the measured gas cost by the end of execution
     * @return gasUsed      [uint] The gas that was used as part of the execution. Used to know `expectedGas`
     */
    function executeHashedReq(
        uint id,
        Request calldata r,
        uint expectedGas
    ) external returns (uint gasUsed);


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                        Cancellations                     //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    /**
     * @notice      Execute a hashedReq. Calls the `target` with `callData`, then
     *              charges the user the fee, and gives it to the executor
     * @param id    [uint] The index of the request in `_hashedReqs`
     * @param r     [request] The full request struct that fully describes the request.
     *              Typically known by seeing the `HashedReqAdded` event emitted with `newReq`
     */
    function cancelHashedReq(
        uint id,
        Request memory r
    ) external;
    
    
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getAUTOAddr() external view returns (address);
    
    function getStakeManager() external view returns (address);

    function getOracle() external view returns (address);
    
    function getUserForwarder() external view returns (address);
    
    function getGasForwarder() external view returns (address);
    
    function getUserGasForwarder() external view returns (address);
    
    function getReqCountOf(address addr) external view returns (uint);
    
    function getExecCountOf(address addr) external view returns (uint);
    
    function getReferalCountOf(address addr) external view returns (uint);
}


// File contracts/contracts/mocks/autonomy/interfaces/IPriceOracle.sol

pragma solidity 0.8.6;


interface IPriceOracle {

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
}


// File contracts/contracts/mocks/autonomy/interfaces/IOracle.sol

pragma solidity 0.8.6;

interface IOracle {
    // Needs to output the same number for the whole epoch
    function getRandNum(uint salt) external view returns (uint);

    function getPriceOracle() external view returns (IPriceOracle);

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);

    function setPriceOracle(IPriceOracle newPriceOracle) external;

    function defaultPayIsAUTO() external view returns (bool);

    function setDefaultPayIsAUTO(bool newDefaultPayIsAUTO) external;
}


// File contracts/contracts/MetaBrain.sol

pragma solidity ^0.8.0;











contract MetaBrain is IBrain, IERC721Receiver, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint version = 0;

    event SummonSetsSet(uint indexed anftId, SummonSet[] newSummonSets);
    event PowerUpSetsSet(uint indexed anftId, PowerupSet[] newPowerupSets);
    event SentToPlayer(uint randNum, address ownerPool, address newOwner);
    event Fought(uint indexed anft, uint normalisedRandNum, uint attack, bool won);

    struct SummonSet {
        IERC721 nft;
        bool spend;
        uint[] tokenIds;
    }

    struct PowerupSet {
        IERC721 nft;
        bool spend;
        uint64 effect;
        uint[] tokenIds;
    }

    struct SetPath {
        uint setIdx;
        uint tokenIdIdx;
        uint tokenId;
    }

    // Used to package info about deposits that should always be together
    struct ERC20Deposit {
        IERC20 token;
        uint amount;
    }

    struct NFTDeposit {
        IERC721 nft;
        uint id;
    }

    struct Boss {
        uint difficulty;
        address[] ownerPools;
    }

    // Consts
    uint public constant MAX_UINT = type(uint).max;
    uint public constant MAX_BPS = 1e18;

    IMetaDungeon public immutable anft;
    
    // MetaBrain
    IBrainOracle public immutable brainOracle;
    uint public maxPowerups;
    // tokenId to the last time a request for that tokenId was executed
    mapping(uint => uint) private _lastExecTimes;
    // tokenId of aNFT to the info about what items can be used to summon it
    mapping(uint => SummonSet[]) private _anftIdToSummonSets;
    // tokenId of aNFT to the info about what items can be used as powerups against it
    mapping(uint => PowerupSet[]) private _anftIdToPowerupSets;
    // Each aNFT needs to know what its own balance is, separate from the others
    mapping(uint => mapping(IERC20 => uint)) public erc20Balances;
    mapping(uint => mapping(IERC721 => mapping(uint => bool))) public nftBalances;
    mapping(uint => mapping(IERC721 => mapping(uint => uint))) public lastSummonNoSpendTime;
    mapping(uint => Boss) public bosses;


    // Autonomy
    IRegistry public immutable registry;
    IOracle public immutable oracle;
    address public immutable userFeeVeriForwarder;


    constructor(
        IMetaDungeon anft_,
        IBrainOracle brainOracle_,
        uint maxPowerups_,
        IRegistry registry_,
        IOracle oracle_,
        address userFeeVeriForwarder_
    ) Ownable() ReentrancyGuard() {
        anft = anft_;
        brainOracle = brainOracle_;
        maxPowerups = maxPowerups_;
        registry = registry_;
        oracle = oracle_;
        userFeeVeriForwarder = userFeeVeriForwarder_;
    }


    function newBoss(
        address to,
        address brain,
        string[] memory tokenURIs,
        Boss calldata boss
    ) external onlyOwner returns (uint anftTokenId) {
        anftTokenId = anft.mint(to, brain, tokenURIs);
        bosses[anftTokenId] = boss;
    }

    function setDifficulty(uint anftTokenId, Boss calldata newBoss) external onlyOwner {
        bosses[anftTokenId] = newBoss;
    }

    function setMaxPowerups(uint newMaxPowerups) external onlyOwner {
        maxPowerups = newMaxPowerups;
    }

    function fightBoss(uint anftTokenId, SetPath[] calldata powerupPaths, ERC20Deposit[] calldata erc20Deps, NFTDeposit[] calldata nftDeps) external returns (bool) {
        require(anft.ownerOf(anftTokenId) == msg.sender);
        return _fightBoss(anftTokenId, powerupPaths, erc20Deps, nftDeps);
    }

    // require msg.sender == tx.origin
    function _fightBoss(
        uint anftTokenId,
        SetPath[] calldata powerupPaths,
        ERC20Deposit[] calldata erc20Deps,
        NFTDeposit[] calldata nftDeps
    ) private returns (bool won) {
        require(msg.sender == tx.origin);
        require(powerupPaths.length <= maxPowerups);

        Boss memory boss = bosses[anftTokenId];
        uint normalisedRandNum = brainOracle.getRandFightNum() / (MAX_UINT / MAX_BPS);
        uint attack = normalisedRandNum;

        for (uint i; i < powerupPaths.length; i++) {
            PowerupSet memory powerupSet = _anftIdToPowerupSets[anftTokenId][powerupPaths[i].setIdx];

            // If the length is 0, then accept any tokenId of this NFT
            if (powerupSet.tokenIds.length != 0) {
                require(powerupSet.tokenIds[powerupPaths[i].tokenIdIdx] == powerupPaths[i].tokenId, "MB: NOT THE REQUIRED POWERUP ITEMS");
            }

            if (powerupSet.spend) {
                _depositNFT(anftTokenId, NFTDeposit(powerupSet.nft, powerupPaths[i].tokenId));
            } else {
                require(powerupSet.nft.ownerOf(powerupPaths[i].tokenId) == msg.sender, "MB: you dont own the nft for power up");
            }

            attack += powerupSet.effect;
        }
        
        won = attack >= boss.difficulty;
        emit Fought(anftTokenId, normalisedRandNum, attack, won);
        // Don't revert in the case of not beating the boss
        if (won) {
            // Check that this boss has all the loot specified by the user
            // and send it to them
            for (uint i; i < erc20Deps.length; i++) {
                // Technically this check shouldn't be necessary since the `-=` underneath
                // would error otherwise, but better to be paranoid
                require(erc20Balances[anftTokenId][erc20Deps[i].token] <= erc20Deps[i].amount, "MB: boss doesn have exact erc in the erc20deps");
                erc20Balances[anftTokenId][erc20Deps[i].token] -= erc20Deps[i].amount;
                erc20Deps[i].token.safeTransfer(msg.sender, erc20Deps[i].amount);
            }
            for (uint i; i < nftDeps.length; i++) {
                // Technically this check shouldn't be necessary since the `safeTransferFrom`
                // underneath would error otherwise, but better to be paranoid
                require(nftBalances[anftTokenId][nftDeps[i].nft][nftDeps[i].id], "MB: boss doesn have exact nft in the nftdeps");
                nftBalances[anftTokenId][nftDeps[i].nft][nftDeps[i].id] = false;
                nftDeps[i].nft.safeTransferFrom(address(this), msg.sender, nftDeps[i].id);
            }
        }


    }

    function getSummonItems(uint anftTokenId) public view returns (SummonSet[] memory) {
        return _anftIdToSummonSets[anftTokenId];
    }

    function getSummonItem(uint anftTokenId, uint i) public view returns (SummonSet memory) {
        return _anftIdToSummonSets[anftTokenId][i];
    }

    function getPowerupItems(uint anftTokenId) public view returns (PowerupSet[] memory) {
        return _anftIdToPowerupSets[anftTokenId];
    }

    function getPowerupItem(uint anftTokenId, uint i) public view returns (PowerupSet memory) {
        return _anftIdToPowerupSets[anftTokenId][i];
    }

    function setSummonSets(
        uint anftTokenId,
        SummonSet[] memory newSummonSets
    ) external onlyOwner {
        uint initialLength = _anftIdToSummonSets[anftTokenId].length;

        for (uint i; i < newSummonSets.length; i++) {
            if (i < initialLength) {
                _anftIdToSummonSets[anftTokenId][i] = newSummonSets[i];
            } else {
                _anftIdToSummonSets[anftTokenId].push(newSummonSets[i]);
            }
        }

        if (newSummonSets.length < initialLength) {
            for (uint i = newSummonSets.length; i < initialLength; i++) {
                _anftIdToSummonSets[anftTokenId].pop();
            }
        }

        emit SummonSetsSet(anftTokenId, newSummonSets);
    }

    function setPowerUpSets(
        uint anftTokenId,
        PowerupSet[] memory newPowerupSets
    ) external onlyOwner {
        uint initialLength = _anftIdToPowerupSets[anftTokenId].length;

        for (uint i; i < newPowerupSets.length; i++) {
            if (i < initialLength) {
                _anftIdToPowerupSets[anftTokenId][i] = newPowerupSets[i];
            } else {
                _anftIdToPowerupSets[anftTokenId].push(newPowerupSets[i]);
            }
        }

        if (newPowerupSets.length < initialLength) {
            for (uint i = newPowerupSets.length; i < initialLength; i++) {
                _anftIdToPowerupSets[anftTokenId].pop();
            }
        }

        emit PowerUpSetsSet(anftTokenId, newPowerupSets);
    }

    function depositAssets(uint anftTokenId, ERC20Deposit[] memory erc20Deps, NFTDeposit[] memory nftDeps) public {
        _depositERC20s(anftTokenId, erc20Deps);
        _depositNFTs(anftTokenId, nftDeps);
    }

    function _depositNFT(uint anftTokenId, NFTDeposit memory nftDep) private {
        nftBalances[anftTokenId][nftDep.nft][nftDep.id] = true;
        nftDep.nft.safeTransferFrom(msg.sender, address(this), nftDep.id);
    }

    function _depositNFTs(uint anftTokenId, NFTDeposit[] memory nftDeps) private {
        for (uint i; i < nftDeps.length; i++) {
            _depositNFT(anftTokenId, nftDeps[i]);
        }
    }

    function _depositERC20s(uint anftTokenId, ERC20Deposit[] memory erc20Deps) private {
        uint[] memory prevBals = new uint[](erc20Deps.length);
        for (uint i; i < erc20Deps.length; i++) {
            prevBals[i] = erc20Deps[i].token.balanceOf(address(this));
            erc20Balances[anftTokenId][erc20Deps[i].token] += erc20Deps[i].amount;
            erc20Deps[i].token.safeTransferFrom(msg.sender, address(this), erc20Deps[i].amount);
        }

        // Incase of some freaky fee-on-transfer bullshit
        for (uint i; i < erc20Deps.length; i++) {
            require(
                IERC20(erc20Deps[i].token).balanceOf(address(this)) - prevBals[i] == erc20Deps[i].amount,
                string(
                    abi.encodePacked(
                        "MB: mismatch of balance with token ",
                        Strings.toHexString(uint160(address(erc20Deps[i].token)), 20)
                    )
                )
            );
        }
    }

    function summonWithItem(
        uint anftTokenId,
        SetPath calldata summonPath,
        address newOwner
    ) public nonReentrant {
        SummonSet memory summonSet = _anftIdToSummonSets[anftTokenId][summonPath.setIdx];

        // If the length is 0, then accept any tokenId of this NFT
        if (summonSet.tokenIds.length != 0) {
            require(summonSet.tokenIds[summonPath.tokenIdIdx] == summonPath.tokenId);
        }

        // If the NFT is required to be spent, then transfer it to this contract and
        // record that the specific anft owns that NFT. The transfer also implicitly
        // tests that msg.sender is the owner
        if (summonSet.spend) {
            // nftBalances[anftTokenId][summonSet.nft][tokenId] = true;
            // summonSet.nft.safeTransferFrom(msg.sender, address(this), tokenId);
            _depositNFT(anftTokenId, NFTDeposit(summonSet.nft, summonPath.tokenId));
        } else {
            require(
                lastSummonNoSpendTime[anftTokenId][summonSet.nft][summonPath.tokenId] < _lastExecTimes[anftTokenId]
            );
            lastSummonNoSpendTime[anftTokenId][summonSet.nft][summonPath.tokenId] = block.timestamp;

            require(summonSet.nft.ownerOf(summonPath.tokenId) == msg.sender);
        }

        anft.safeTransferFrom(anft.ownerOf(anftTokenId), newOwner, anftTokenId);
    }

    function setVersion(uint newX) public {
        version = newX;
    }

    function getURIVersion(uint tokenId) public view override returns (uint) {
        return version;
    }








    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier userFeeVerified() {
        require(msg.sender == userFeeVeriForwarder);
        _;
    }
    
    receive() external payable {}
}