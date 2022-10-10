/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)



/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)



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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)




/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)



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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)






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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}


// File contracts/ERC721JUpgradeable.sol












error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MaxCopiesReached();
error MintToZeroAddress();
error NotEnoughEther();
error OwnerIndexOutOfBounds();
error OwnerIsOperator();
error OwnerQueryForNonexistentToken();
error QueryForNonexistentToken();
error SenderNotOwner();
error TokenAlreadyMinted();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();
error URISetOfNonexistentSong();
error TokenNotApproved();
error TokenBalanceZero();
error TokenAlreadyClaimed();
error GenerationOutOne();
error GenerationOutZero();
error SongInZero();
error NewMaxLessThanCurrentSupply();
error InvalidGeneration();
error RecycleDisabled();

//
//Version 2 of ERC721J
//
//Supports 1/1 original master with any edition size.
//Minting a copy requires the owner to own a copy,
//or for public mint to be true on that token.
//
//
//New in v2: custom max supply (used to be always 100),
//Mint price can be set, in eth and any erc-20 token.
//Rarity affected by generation of copy (rarity used to be affected by serial # of a copy of a song)
//Added public mint switch as an option to mint copies traditionally.
//Added recycle to burn 2 songs to mint 1.
//Added free claim system.
//Added and the ability to change the max editions of a song, or the name or symbol of the contract.
//Made recycling optional, added a toggle to turn it off if you want to.
//
//
//
contract ERC721J is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    IERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    function initialize(
        string memory cloneName,
        string memory cloneSymbol,
        address cloneOwner,
        uint256 cloneMintPrice
    ) public virtual initializer {
        __ERC721J_init(cloneName, cloneSymbol, cloneOwner, cloneMintPrice);
    }

    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    // _tokenIds and _songIds for keeping track of the ongoing total tokenids, and total songids
    uint256 private _tokenIds;
    uint256 private _songIds;

    // Token name
    string private _name = "ERC721J";

    // Token symbol
    string private _symbol = "721J";

    //Define the baseURI
    string private _baseURI = "https://arweave.net/";

    //Define Contract URI
    string private _contractURI;

    uint256 private _mintPrice = 50000000000000000;

    //define toggle recycle
    bool private _recycleToggle = true;

    struct tokenInfo {
        uint128 song;
        uint128 generation;
    }

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping for song URIs. Takes songId then songGeneration combined as a number with a string for the URI.
    mapping(uint256 => string) private _songURIs;
    // Mapping for the counters of copies minted for each song
    mapping(uint256 => uint256) private _songSerials;
    // Mapping for the extra info to each tokenId
    mapping(uint256 => tokenInfo) private _tokenIdInfo;

    // Mapping for the max songs. Takes songId then max amount of editions for that song.
    mapping(uint256 => uint256) private _maxEditions;

    // Mapping for erc-20 token addresses and their price in wei
    mapping(address => uint256) private _tokenPrice;

    // true or false for a tokenId if public mint is on for it
    mapping(uint256 => bool) private _publicMint;

    //Declaring new events
    event SetFreeClaim(
        address indexed contractName,
        uint256 songIn,
        uint256 songOut
    );
    event TokenPriceSet(address indexed tokenContract, uint256 price);

    event Copy(uint256 indexed tokenId);

    event NewMax(uint256 indexed songId, uint256 maxEditions);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721J_init(
        string memory name_,
        string memory symbol_,
        address owner,
        uint256 mintPrice_
    ) internal onlyInitializing {
        __ERC721J_init_unchained(name_, symbol_, owner, mintPrice_);
    }

    function __ERC721J_init_unchained(
        string memory name_,
        string memory symbol_,
        address owner,
        uint256 mintPrice_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _transferOwnership(owner);
        _baseURI = "https://arweave.net/";
        _mintPrice = mintPrice_;
    }

    //from erc721enumerable
    //
    //function returns the total supply of tokens minted by the contract
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIds;
    }

    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index > _tokenIds - 1) revert TokenIndexOutOfBounds();
        return index + 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index > balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _tokenIds;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        unchecked {
            for (uint256 i; i <= numMintedSoFar; i++) {
                address ownership = _owners[i];
                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
                }
                if (currOwnershipAddr == owner && ownership != address(0)) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        // Execution should never reach this point.
        assert(false);
        return 0;
    }

    //Returns the serial # of a songId
    function tokenOfSongByIndex(uint256 songId, uint256 index)
        public
        view
        returns (uint256)
    {
        if (index > _songSerials[songId]) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _tokenIds;
        uint256 tokenIdsIdx;
        uint256 currSong;
        unchecked {
            for (uint256 i; i <= numMintedSoFar; i++) {
                uint256 song = songOfToken(i);
                if (song != 0) {
                    currSong = song;
                }
                if (currSong == songId && _owners[i] != address(0)) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        // Execution should never reach this point.
        assert(false);
        return 0;
    }

    //Returns every song that has public mint set to true
    function tokenOfPublicByIndex(uint256 index) public view returns (uint256) {
        uint256 numMintedSoFar = _tokenIds;
        if (index > numMintedSoFar) revert OwnerIndexOutOfBounds();

        uint256 tokenIdsIdx;
        unchecked {
            for (uint256 i; i <= numMintedSoFar; i++) {
                bool _public = publicMint(i);
                uint256 _song = songOfToken(i);
                if (
                    _public != false &&
                    _owners[i] != address(0) &&
                    _songSerials[_song] != _maxEditions[_song]
                ) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        // Execution should never reach this point.
        assert(false);
        return 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert OwnerQueryForNonexistentToken();
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    //sets the Name
    function setName(string memory newName) public virtual onlyOwner {
        _name = newName;
    }

    //
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    //sets the Symbol
    function setSymbol(string memory newSymbol) public virtual onlyOwner {
        _symbol = newSymbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        uint256 songId = songOfToken(tokenId);
        uint256 songGeneration = generationOfToken(tokenId);
        string memory _tokenURI;
        // Shows different uri depending on serial number
        _tokenURI = _songURIs[(songId * (10**18)) + songGeneration];
        for (uint256 i; i <= songGeneration; i++) {
            if (bytes(_tokenURI).length == 0) {
                _tokenURI = _songURIs[(songId * (10**18)) + songGeneration - i];
            }
        }

        // Set baseURI
        string memory base = baseURI();
        // Concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        } else {
            return "";
        }
    }

    //
    //
    //URI Section
    //
    //

    //Returns baseURI internally
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    //sets the baseURI
    function setBaseURI(string memory base) public virtual onlyOwner {
        _baseURI = base;
    }

    //Returns contractURI internally
    function contractURI() public view virtual returns (string memory) {
        // Set baseURI
        string memory base = baseURI();
        // Concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_contractURI).length > 0) {
            return string(abi.encodePacked(base, _contractURI));
        } else {
            return "";
        }
    }

    //sets the contractURI
    function setContractURI(string memory uri) public virtual onlyOwner {
        _contractURI = uri;
    }

    //sets the songURIs when minting a new song
    function _setSongURI2(
        uint256 songId,
        string memory songURI1,
        string memory songURI2
    ) internal virtual {
        if (!_exists(songId)) revert URISetOfNonexistentSong();
        _songURIs[(songId * (10**18)) + 1] = songURI1;
        _songURIs[(songId * (10**18)) + 2] = songURI2;
    }

    //sets the songURIs when minting a new song
    function _setSongURI(
        uint256 songId,
        string memory songURI1,
        string memory songURI2,
        string memory songURI3
    ) internal virtual {
        if (!_exists(songId)) revert URISetOfNonexistentSong();
        _songURIs[(songId * (10**18)) + 1] = songURI1;
        _songURIs[(songId * (10**18)) + 2] = songURI2;
        _songURIs[(songId * (10**18)) + 3] = songURI3;
    }

    //Changes the songURI for one generation of a song, when given the songId and songGeneration
    function changeSongURI(
        uint256 songId,
        uint256 songGeneration,
        string memory _songURI
    ) public virtual onlyOwner {
        if (!_exists(songId)) revert URISetOfNonexistentSong();
        _songURIs[(songId * (10**18)) + songGeneration] = _songURI;
    }

    //Changes the songURI for two generations of a song, when given the songId and songGeneration
    function changeSongURIs(
        uint256 songId,
        uint256 songGeneration1,
        string memory songURI1,
        uint256 songGeneration2,
        string memory songURI2
    ) public virtual onlyOwner {
        if (!_exists(songId)) revert URISetOfNonexistentSong();
        _songURIs[(songId * (10**18)) + songGeneration1] = songURI1;
        _songURIs[(songId * (10**18)) + songGeneration2] = songURI2;
    }

    //
    //ERC721 Meat and Potatoes Section
    //

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    //
    //Transfer Section
    //
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert TransferCallerNotOwnerNorApproved();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert TransferCallerNotOwnerNorApproved();
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    //
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    //
    //Minting Section!
    //

    //Returns Mint Price
    function mintPrice() public view virtual returns (uint256) {
        return _mintPrice;
    }

    //sets the Mint Price in Wei
    function setMintPrice(uint256 priceWei) public virtual onlyOwner {
        _mintPrice = priceWei;
    }

    //Returns status of public mint for tokenId
    function publicMint(uint256 tokenId) public view virtual returns (bool) {
        return _publicMint[tokenId];
    }

    //Toggles Public Mint for Token Id
    function togglePublicMint(uint256 tokenId) public virtual {
        if (ownerOf(tokenId) != msg.sender) revert SenderNotOwner();
        _publicMint[tokenId] = !_publicMint[tokenId];
    }

    //Returns Token Mint Price
    function tokenMintPrice(address token)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenPrice[token];
    }

    //sets the Token Mint Price in Wei
    function setTokenMintPrice(address token, uint256 priceWei)
        public
        virtual
        onlyOwner
    {
        _tokenPrice[token] = priceWei;
        emit TokenPriceSet(token, priceWei);
    }

    //Changes the max editions for a song
    function setMaxEditions(uint256 songId, uint256 maxEditions)
        public
        virtual
        onlyOwner
    {
        if (_songSerials[songId] > maxEditions) {
            revert NewMaxLessThanCurrentSupply();
        }

        _maxEditions[songId] = maxEditions;
        emit NewMax(songId, maxEditions);
    }

    //Returns Token Mint Price
    function recycleStatus() public view virtual returns (bool) {
        return _recycleToggle;
    }

    //Toggles recycle mint
    function toggleRecycleMint() public virtual onlyOwner {
        _recycleToggle = !_recycleToggle;
    }

    //
    //
    //
    //
    function mintOriginal2(
        string memory songURI1,
        string memory songURI2,
        uint256 maxEditions
    ) public onlyOwner {
        // Updates the count of total tokenids and songids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;
        uint256 songId = _songIds;
        songId++;
        _songIds = songId;

        // Updates the count of how many of a particular song have been made
        uint256 songSerial = _songSerials[songId];
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(1);

        _maxEditions[songId] = maxEditions;

        _safeMint(msg.sender, id);
        _setSongURI2(songId, songURI1, songURI2);
    }

    function mintOriginal(
        string memory songURI1,
        string memory songURI2,
        string memory songURI3,
        uint256 maxEditions
    ) public onlyOwner {
        // Updates the count of total tokenids and songids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;
        uint256 songId = _songIds;
        songId++;
        _songIds = songId;

        // Updates the count of how many of a particular song have been made
        uint256 songSerial = _songSerials[songId];
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(1);

        _maxEditions[songId] = maxEditions;

        _safeMint(msg.sender, id);
        _setSongURI(songId, songURI1, songURI2, songURI3);
    }

    function ownerMintsCopy(
        uint256 tokenId,
        uint256 songGeneration,
        address to
    ) public onlyOwner {
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender)
            if (_publicMint[tokenId] == false) revert SenderNotOwner();

        if (songGeneration < 2) {
            revert InvalidGeneration();
        }
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        // uint256 songGeneration = generationOfToken(tokenId);
        //requires the amount of copies to be less than the max
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        // _tokenIdInfo[id].generation = uint128(songGeneration + 1);
        _tokenIdInfo[id].generation = uint128(songGeneration);

        emit Copy(tokenId);

        _safeMintCopy(ownerOf(tokenId), to, id);
    }

    function mintCopy(uint256 tokenId) public payable {
        //requires eth
        if (msg.value < _mintPrice) revert NotEnoughEther();
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender)
            if (_publicMint[tokenId] == false) revert SenderNotOwner();
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        uint256 songGeneration = generationOfToken(tokenId);
        //requires the amount of copies to be less than the max
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(songGeneration + 1);

        emit Copy(tokenId);

        _safeMintCopy(ownerOf(tokenId), msg.sender, id);
    }

    function mintCopyTo(uint256 tokenId, address to) public payable {
        //requires eth
        if (msg.value < _mintPrice) revert NotEnoughEther();
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender)
            if (_publicMint[tokenId] == false) revert SenderNotOwner();
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        uint256 songGeneration = generationOfToken(tokenId);
        //requires the amount of copies to be less than the max
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(songGeneration + 1);

        emit Copy(tokenId);

        _safeMintCopy(ownerOf(tokenId), to, id);
    }

    function mintCopyToken(uint256 tokenId, address token) public {
        //requires token
        if (ERC20Upgradeable(token).balanceOf(msg.sender) < _tokenPrice[token])
            revert NotEnoughEther();
        //checks if contract is approved
        if (_tokenPrice[token] == 0) revert TokenNotApproved();
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender)
            if (_publicMint[tokenId] == false) revert SenderNotOwner();
        //transfer tokens
        ERC20Upgradeable(token).transferFrom(
            msg.sender,
            owner(),
            _tokenPrice[token]
        );
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        uint256 songGeneration = generationOfToken(tokenId);
        //requires the amount of copies to be less than the max
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(songGeneration + 1);

        emit Copy(tokenId);

        _safeMintCopy(ownerOf(tokenId), msg.sender, id);
    }

    function mintCopyTokenTo(uint256 tokenId, address token, address to) public {
        //requires token
        if (ERC20Upgradeable(token).balanceOf(msg.sender) < _tokenPrice[token])
            revert NotEnoughEther();
        //checks if contract is approved
        if (_tokenPrice[token] == 0) revert TokenNotApproved();
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender)
            if (_publicMint[tokenId] == false) revert SenderNotOwner();
        //transfer tokens
        ERC20Upgradeable(token).transferFrom(msg.sender, owner(), _tokenPrice[token]);
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        uint256 songGeneration = generationOfToken(tokenId);
        //requires the amount of copies to be less than the max
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(songGeneration + 1);

        emit Copy(tokenId);

        _safeMintCopy(ownerOf(tokenId), to, id);
    }


    function recycleMint(
        uint256 mintTokenId,
        uint256 burnTokenId1,
        uint256 burnTokenId2
    ) public {
        if (ownerOf(burnTokenId1) != msg.sender) revert SenderNotOwner();
        if (ownerOf(burnTokenId2) != msg.sender) revert SenderNotOwner();

        //requires the sender to have the tokenId in their wallet
        if (ownerOf(mintTokenId) != msg.sender)
            if (_publicMint[mintTokenId] == false) revert SenderNotOwner();

        //Checks if recycling is allowed
        if (_recycleToggle != true) {
            revert RecycleDisabled();
        }

        //Gets the songId from the tokenId
        uint256 songId = songOfToken(mintTokenId);
        uint256 songSerial = _songSerials[songId];
        uint256 songGeneration = generationOfToken(mintTokenId);
        //requires the amount of copies to be less than the max
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        //Burns tokens
        _balances[msg.sender] -= 2;
        _burn(burnTokenId1);
        _burn(burnTokenId2);

        uint256 burnSongId1 = songOfToken(burnTokenId1);
        uint256 burnSongId2 = songOfToken(burnTokenId2);
        //If either burn tokens are the same songId as the token you're minting,
        //it updates the memory songSerial.  If not it updates storage.
        if (burnSongId1 == burnSongId2 && burnSongId1 != songId) {
            _songSerials[burnSongId1] -= 2;
        } else {
            if (burnSongId1 == songId) {
                songSerial--;
            } else {
                _songSerials[burnSongId1]--;
            }
            if (burnSongId2 == songId) {
                songSerial--;
            } else {
                _songSerials[burnSongId2]--;
            }
        }

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].generation = uint128(songGeneration + 1);

        emit Copy(mintTokenId);

        _safeMintCopy(ownerOf(mintTokenId), msg.sender, id);
    }

    //
    //
    //
    //

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMintCopy(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeMintCopy(from, to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _safeMintCopy(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mintCopy(from, to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId)) revert TokenAlreadyMinted();

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _mintCopy(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId)) revert TokenAlreadyMinted();

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    //
    //
    //
    //
    //Burn function
    function _burn(uint256 tokenId) internal virtual {
        // Clear approvals
        _approve(address(0), tokenId);

        delete _owners[tokenId];

        emit Transfer(msg.sender, address(0), tokenId);
    }

    //
    //More ERC721 Functions Meat and Potatoes style Section
    //

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) revert OwnerIsOperator();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    //
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    //
    //Other Functions Section
    //

    //function returns how many different songs have been created
    function amountOfSongs() public view virtual returns (uint256) {
        return _songIds;
    }

    //function returns what song a certain tokenid is
    function songOfToken(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdInfo[tokenId].song;
    }

    //function returns what generation a certain tokenid is
    function generationOfToken(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdInfo[tokenId].generation;
    }

    //function returns how many of a song are minted
    function songSupply(uint256 songId) public view virtual returns (uint256) {
        return _songSerials[songId];
    }

    //function returns max of a song to be minted
    function maxSongSupply(uint256 songId)
        public
        view
        virtual
        returns (uint256)
    {
        return _maxEditions[songId];
    }

    //returns a songURI, when given the songId and songGeneration
    function songURI(uint256 songId, uint256 songGeneration)
        public
        view
        virtual
        returns (string memory)
    {
        if (songId > _songIds) revert URIQueryForNonexistentToken();
        string memory _songURI;

        _songURI = _songURIs[(songId * (10**18)) + songGeneration];
        for (uint256 i; i <= songGeneration; i++) {
            if (bytes(_songURI).length == 0) {
                _songURI = _songURIs[(songId * (10**18)) + songGeneration - i];
            }
        }

        string memory base = baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, _songURI))
                : "";
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        // Payable address can receive Ether
        address payable owner;
        owner = payable(msg.sender);
        // send all Ether to owner
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    //
    //
    //Free Claim Section
    //
    //
    //Mappings
    //
    //Address to SongOut.  For ERC721
    mapping(address => uint256) private _addressClaim;
    //Address to SongIn to SongOut. For ERC721J
    mapping(address => mapping(uint256 => uint256))
        private _addressClaimSpecific;
    //
    //Address to TokenId to bool
    mapping(address => mapping(uint256 => bool)) private _giftClaim;
    //Address to TokenId to bool
    mapping(address => mapping(uint256 => bool)) private _giftClaimSpecific;

    //
    //Set Functions
    //
    //For normal ERC721
    function setFreeClaim(
        address _contract,
        uint256 songIdOut,
        uint256 generationOut
    ) external onlyOwner {
        if (generationOut == 1) revert GenerationOutOne();

        uint256 _songOut = (songIdOut * (10**18)) + generationOut;

        _addressClaim[_contract] = _songOut;

        emit SetFreeClaim(_contract, 0, _songOut);
    }

    //For ERC721J
    function setFreeClaimSpecific(
        address _contract,
        uint256 songIdIn,
        uint256 generationIn,
        uint256 songIdOut,
        uint256 generationOut
    ) external onlyOwner {
        if (generationOut == 1) revert GenerationOutOne();
        if (songIdIn == 0 && generationIn == 0) revert SongInZero();

        uint256 _songIn = (songIdIn * (10**18)) + generationIn;
        uint256 _songOut = (songIdOut * (10**18)) + generationOut;

        _addressClaimSpecific[_contract][_songIn] = _songOut;

        emit SetFreeClaim(_contract, _songIn, _songOut);
    }

    //
    //Read Functions
    //
    //Checks if a contract address is whitelisted
    function claimCheck(address _contract)
        public
        view
        virtual
        returns (uint256 _songIdOut, uint256 _generationOut)
    {
        uint256 _songOut = _addressClaim[_contract];

        _songIdOut = _songOut / (10**18);
        _generationOut = _songOut % (10**18);
    }

    //
    //For ERC721J. Checks if a contract address, with song and rarity, is whitelisted
    function claimCheckSpecific(
        address _contract,
        uint256 songIdIn,
        uint256 generationIn
    ) public view virtual returns (uint256 _songIdOut, uint256 _generationOut) {
        uint256 _songIn = (songIdIn * (10**18)) + generationIn;

        uint256 _songOut = _addressClaimSpecific[_contract][_songIn];

        _songIdOut = _songOut / (10**18);
        _generationOut = _songOut % (10**18);
    }

    //
    //Checks if a token from a contract has been claimed through the normal contract wide whitelist.
    function giftClaimCheck(address _contract, uint256 tokenId)
        public
        view
        virtual
        returns (bool)
    {
        return _giftClaim[_contract][tokenId];
    }

    //
    //Checks if a token from a contract has been claimed through the ERC721J specific whitelist.
    function giftClaimCheckSpecific(address _contract, uint256 tokenId)
        public
        view
        virtual
        returns (bool)
    {
        return _giftClaimSpecific[_contract][tokenId];
    }

    //
    //Minting Functions
    //
    //Free claim is for ERC721 tokens
    function freeClaim(address _contract, uint256 tokenId) public {
        //Sets contract address as external nft
        ERC721J _claimContract = ERC721J(_contract);
        //Checks if the token has been claimed
        if (_giftClaim[_contract][tokenId] != false)
            revert TokenAlreadyClaimed();
        //Checks if msg.sender is the owner of the token from the contract
        if (_claimContract.ownerOf(tokenId) != msg.sender)
            revert SenderNotOwner();
        //Grabs songOut for the contract, and gets the songIdOut and generationOut from it
        uint256 _songOut = _addressClaim[_contract];
        uint256 _songIdOut = _songOut / (10**18);
        uint256 _generationOut = _songOut % (10**18);
        //GenerationOut being zero means you can't claim
        if (_generationOut == 0) revert GenerationOutZero();

        //sets songId to the most recent song if songIdOut is 0
        if (_songIdOut == 0) _songIdOut = _songIds;
        //

        uint256 songSerial = _songSerials[_songIdOut];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[_songIdOut]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[_songIdOut] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(_songIdOut);
        _tokenIdInfo[id].generation = uint128(_generationOut);

        _giftClaim[_contract][tokenId] = true;

        _safeMintCopy(owner(), msg.sender, id);
    }

    //
    //Free claim specific is for ERC721J tokens
    function freeClaimSpecific(address _contract, uint256 tokenId) public {
        //Sets contract address as external nft
        ERC721J _claimContract = ERC721J(_contract);
        //Checks if the token has been claimed
        if (_giftClaimSpecific[_contract][tokenId] != false)
            revert TokenAlreadyClaimed();
        //Checks if msg.sender is the owner of the token from the contract
        if (_claimContract.ownerOf(tokenId) != msg.sender)
            revert SenderNotOwner();
        //Gets songId and generation of token from old contract
        uint256 _songIdIn = _claimContract.songOfToken(tokenId);
        uint256 _generationIn = _claimContract.generationOfToken(tokenId);
        uint256 _songIn = (_songIdIn * (10**18)) + _generationIn;
        //Grabs songOut for the contract, and gets the songIdOut and generationOut from it
        uint256 _songOut = _addressClaimSpecific[_contract][_songIn];
        uint256 _songIdOut = _songOut / (10**18);
        uint256 _generationOut = _songOut % (10**18);
        //GenerationOut being zero means you can't claim
        if (_generationOut == 0) revert GenerationOutZero();

        //sets songId to the most recent song if songIdOut is 0
        if (_songIdOut == 0) _songIdOut = _songIds;
        //

        uint256 songSerial = _songSerials[_songIdOut];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[_songIdOut]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[_songIdOut] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(_songIdOut);
        _tokenIdInfo[id].generation = uint128(_generationOut);

        _giftClaimSpecific[_contract][tokenId] = true;

        _safeMintCopy(owner(), msg.sender, id);
    }

    //
    //Free claim song reward is for ERC721J tokens to claim a song specific reward
    function freeClaimSongReward(address _contract, uint256 tokenId) public {
        //Sets contract address as external nft
        ERC721J _claimContract = ERC721J(_contract);
        //Checks if the token has been claimed
        if (_giftClaimSpecific[_contract][tokenId] != false)
            revert TokenAlreadyClaimed();
        //Checks if msg.sender is the owner of the token from the contract
        if (_claimContract.ownerOf(tokenId) != msg.sender)
            revert SenderNotOwner();
        //Gets songId of token from old contract
        uint256 _songIdIn = _claimContract.songOfToken(tokenId);
        uint256 _songIn = _songIdIn * (10**18);
        //Grabs songOut for the contract, and gets the songIdOut and generationOut from it
        uint256 _songOut = _addressClaimSpecific[_contract][_songIn];
        uint256 _songIdOut = _songOut / (10**18);
        uint256 _generationOut = _songOut % (10**18);
        //GenerationOut being zero means you can't claim
        if (_generationOut == 0) revert GenerationOutZero();

        //sets songId to the most recent song if songIdOut is 0
        if (_songIdOut == 0) _songIdOut = _songIds;
        //

        uint256 songSerial = _songSerials[_songIdOut];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[_songIdOut]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[_songIdOut] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(_songIdOut);
        _tokenIdInfo[id].generation = uint128(_generationOut);

        _giftClaimSpecific[_contract][tokenId] = true;

        _safeMintCopy(owner(), msg.sender, id);
    }

    //
    //Free claim rarity reward is for ERC721J tokens to claim a rarity specific reward
    function freeClaimRarityReward(address _contract, uint256 tokenId) public {
        //Sets contract address as external nft
        ERC721J _claimContract = ERC721J(_contract);
        //Checks if the token has been claimed
        if (_giftClaimSpecific[_contract][tokenId] != false)
            revert TokenAlreadyClaimed();
        //Checks if msg.sender is the owner of the token from the contract
        if (_claimContract.ownerOf(tokenId) != msg.sender)
            revert SenderNotOwner();
        //Gets generation of token from old contract
        uint256 _generationIn = _claimContract.generationOfToken(tokenId);
        uint256 _songIn = _generationIn;
        //Grabs songOut for the contract, and gets the songIdOut and generationOut from it
        uint256 _songOut = _addressClaimSpecific[_contract][_songIn];
        uint256 _songIdOut = _songOut / (10**18);
        uint256 _generationOut = _songOut % (10**18);
        //GenerationOut being zero means you can't claim
        if (_generationOut == 0) revert GenerationOutZero();

        //sets songId to the most recent song if songIdOut is 0
        if (_songIdOut == 0) _songIdOut = _songIds;
        //

        uint256 songSerial = _songSerials[_songIdOut];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[_songIdOut]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[_songIdOut] = songSerial;
        //makes it easy to look up the song or gen of a tokenid
        _tokenIdInfo[id].song = uint128(_songIdOut);
        _tokenIdInfo[id].generation = uint128(_generationOut);

        _giftClaimSpecific[_contract][tokenId] = true;

        _safeMintCopy(owner(), msg.sender, id);
    }
    //
    //
    //
}


// File @openzeppelin/contracts/proxy/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)



/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// File contracts/ApeTapesContractWizard.sol







contract ApeTapesContractWizard is Ownable {
    address immutable tokenImplementation;

    constructor() {
        tokenImplementation = address(new ERC721J());
    }

    //contract ids is the total number of all the clone contracts made
    uint256 private _contractIds;

    //Mint price to create contract
    uint256 private _mintPrice = 10000000000000000;

    //Define Contract URI
    string private _contractURI;

    //Mapping contract id with clone address
    mapping(uint256 => address) private cloneLibrary;

    //price in wei for erc-20 address
    mapping(address => uint256) private _tokenPrice;

    //Declaring new event
    event TokenPriceSet(address indexed tokenContract, uint256 price);

    event NewContract(address contractAddress, uint256 contractId );


    //Returns a contract address when you enter in a contract id.
    function getContractByID(uint256 contractId) public view returns (address) {
        if (contractId >= _contractIds) revert TokenIndexOutOfBounds();
        return cloneLibrary[contractId];
    }

    //Returns the a number in the index if the contract is in the directory.
    function inCollection(address contractAddress)
        public
        view
        returns (uint256)
    {
        unchecked {
            for (uint256 i; i <= _contractIds; i++) {
                if (cloneLibrary[i] == contractAddress) return i;
            }
        }
        // Execution should never reach this point.
        assert(false);
        return 0;
    }

    //Creates a clone.
    function createClone(
        string calldata name,
        string calldata symbol,
        uint256 mintPriceWei
    ) public payable returns (address) {
        //requires eth
        if (msg.value < _mintPrice) revert NotEnoughEther();
        //creates clone
        address clone = Clones.clone(tokenImplementation);
        ERC721J(clone).initialize(name, symbol, msg.sender, mintPriceWei);
        //finds the next contract id
        uint256 contractId = _contractIds;
        //assigns clone a contract id
        cloneLibrary[contractId] = clone;

        emit NewContract(clone, contractId);

        contractId++;
        _contractIds = contractId;


        return clone;
    }

    //Creates a clone paying with an ERC20 token
    function createCloneToken(
        string calldata name,
        string calldata symbol,
        uint256 mintPriceWei,
        address token
    ) external returns (address) {
        //requires token
        if (ERC20Upgradeable(token).balanceOf(msg.sender) < _tokenPrice[token])
            revert NotEnoughEther();
        //checks if contract is approved
        if (_tokenPrice[token] == 0) revert TokenNotApproved();

        //transfer tokens
        ERC20Upgradeable(token).transferFrom(
            msg.sender,
            owner(),
            _tokenPrice[token]
        );

        //creates clone
        address clone = Clones.clone(tokenImplementation);
        ERC721J(clone).initialize(name, symbol, msg.sender, mintPriceWei);
        //finds the next contract id
        uint256 contractId = _contractIds;
        //assigns clone a contract id
        cloneLibrary[contractId] = clone;

        emit NewContract(clone, contractId);

        contractId++;
        _contractIds = contractId;
        return clone;
    }


    //Returns contractURI internally
    function contractURI() public view virtual returns (string memory) {
        return (_contractURI);
    }

    //sets the contractURI
    function setContractURI(string memory uri) public virtual onlyOwner {
        _contractURI = uri;
    }

    //Returns the count of contracts made
    function contractCount() public view virtual returns (uint256) {
        return _contractIds;
    }

    //Returns Mint Price
    function mintPrice() public view virtual returns (uint256) {
        return _mintPrice;
    }

    //sets the Mint Price in Wei
    function setMintPrice(uint256 priceWei) public virtual onlyOwner {
        _mintPrice = priceWei;
    }

    //Returns Token Mint Price
    function tokenMintPrice(address token)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenPrice[token];
    }

    //sets the Token Mint Price in Wei
    function setTokenMintPrice(address token, uint256 price)
        public
        virtual
        onlyOwner
    {
        _tokenPrice[token] = price;
        emit TokenPriceSet(token, price);
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        // Payable address can receive Ether
        address payable owner;
        owner = payable(msg.sender);
        // send all Ether to owner
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}