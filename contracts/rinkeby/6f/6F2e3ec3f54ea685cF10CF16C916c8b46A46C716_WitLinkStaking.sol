/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// File: stake.sol



pragma solidity 0.8.4;

    interface nftcontract {
        function maxSupply() view external returns (uint256);
    }



    //import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

    contract WitLinkStaking is Ownable, IERC721Receiver {

    uint256 public totalStaked;
    address public contractowner;
    uint256 public erc20balance;
    uint256 public zone1reward = 2;
    uint256 public zone2reward = 2;
    uint256 public zone3reward = 3;
    uint256 public zone4reward = 5;
    uint256 public largereward = 35;
    uint256 public smallreward = 15;
    uint256 public hightrafficreward = 50;
    uint256 public standardbase = 30 wei;
    uint256 public deluxebase = 70 ether;
    uint256 public villabase = 150 ether;
    uint256 public executivebase = 400 ether;
    uint16[] large =[uint16(6870), 6935, 6466, 6962, 6562, 6974, 6427, 6866, 6165, 6535, 6470, 6923, 6889, 6309, 6958, 6372, 6260, 6919, 6763, 6671, 6743, 6939, 6893, 6981, 6997, 6978, 6610, 6169, 6885, 6391, 6684, 6954, 6811, 6903, 6915, 6503, 6692, 6368, 6942, 6807, 6410, 6943, 6386, 6914, 6447, 6851, 6902, 6955, 6543, 6390, 6168, 6884, 6187, 6304, 7000, 6996, 6979, 6703, 6579, 6980, 6345, 6715, 6200, 6650, 6484, 6938, 6892, 6742, 6312, 6670, 6277, 6918, 6631, 6666, 6959, 6867, 6922, 6888, 6975, 6426, 6719, 6826, 6963, 6871, 6934, 6467, 6895, 6196, 6987, 6968, 6704, 6568, 6991, 6246, 6616, 6495, 6883, 6929, 6952, 6817, 6905, 6786, 6440, 6913, 6505, 6944, 6801, 6876, 6525, 6175, 6899, 6933, 6964, 6972, 6708, 6499, 6925, 6231, 6909, 6509, 6948, 6227, 6676, 6363, 6949, 6908, 6660, 6375, 6162, 6532, 6861, 6924, 6836, 6973, 6820, 6965, 6877, 6898, 6932, 6945, 6416, 6553, 6441, 6912, 6787, 6768, 6904, 6400, 6953, 6683, 6882, 6928, 6752, 6617, 6990, 6210, 6986, 6969, 6713, 6178, 6528, 6894, 6314, 6946, 6911, 6784, 6907, 6287, 6950, 6881, 6497, 6614, 6993, 6213, 6356, 6439, 6985, 6205, 6655, 6897, 6878, 6481, 6317, 6858, 6321, 6634, 6458, 6726, 6819, 6927, 6862, 6970, 6966, 6989, 6931, 6527, 6874, 6930, 6463, 6526, 6875, 6434, 6967, 6988, 6971, 6926, 6863, 6619, 6818, 6273, 6253, 6195, 6896, 6879, 6480, 6711, 6984, 6838, 6992, 6880, 6479, 6394, 6814, 6951, 6906, 6910, 6382, 6678, 6551, 6947, 6736, 6624, 6665, 6409, 6921, 6864, 6976, 6999, 6960, 6576, 6258, 6937, 6872, 6805, 6940, 6917, 6278, 6901, 6452, 6813, 6956, 6686, 6184, 6887, 6868, 6307, 6583, 6429, 6995, 6215, 6983, 6346, 6891, 6468, 6487, 6605, 6740, 6310, 6890, 6982, 6214, 6994, 6613, 6756, 6886, 6869, 6490, 6404, 6957, 6900, 6783, 6279, 6916, 6557, 6941, 6936, 6873, 6259, 6961, 6598, 6577, 6824, 6977, 6998, 6832, 6920, 6865, 6326, 6449, 6275];
    uint16[] small =[uint16(6827), 6831, 6759, 6722, 6630, 6325, 6276, 6333, 6221, 6364, 6190, 6344, 6597, 6702, 6352, 6647, 6217, 6305, 6240, 6186, 6796, 6283, 6779, 6450, 6515, 6295, 6387, 6554, 6806, 6739, 6693, 6369, 6502, 6451, 6797, 6778, 6328, 6492, 6241, 6611, 6646, 6607, 6257, 6365, 6735, 6559, 6627, 6762, 6324, 6774, 6723, 6758, 6830, 6575, 6172, 6315, 6600, 6483, 6529, 6712, 6207, 6657, 6397, 6682, 6401, 6790, 6285, 6456, 6513, 6293, 6769, 6856, 6319, 6572, 6163, 6548, 6724, 6374, 6323, 6289, 6620, 6335, 6226, 6764, 6334, 6267, 6637, 6322, 6288, 6230, 6725, 6359, 6709, 6573, 6436, 6318, 6748, 6524, 6800, 6695, 6857, 6457, 6791, 6284, 6379, 6729, 6181, 6569, 6586, 6355, 6343, 6656, 6197, 6601, 6251, 6415, 6696, 6679, 6854, 6442, 6842, 6511, 6268, 6403, 6395, 6301, 6751, 6585, 6839, 6643, 6710, 6194, 6747, 6675, 6419, 6337, 6788, 6264, 6376, 6663, 6233, 6474, 6161, 6423, 6589, 6835, 6823, 6570, 6462, 6199, 6176, 6822, 6658, 6208, 6422, 6567, 6530, 6249, 6232, 6320, 6635, 6859, 6766, 6623, 6789, 6418, 6361, 6224, 6603, 6746, 6316, 6204, 6592, 6642, 6212, 6707, 6584, 6300, 6183, 6402, 6286, 6228, 6223, 6389, 6761, 6331, 6327, 6777, 6798, 6262, 6848, 6370, 6235, 6188, 6649, 6425, 6560, 6608, 6413, 6690, 6385, 6852, 6501, 6444, 6517, 6281, 6794, 6405, 6669, 6612, 6645, 6595, 6829, 6203, 6653, 6192, 6604, 6311, 6469, 6486, 6594, 6644, 6306, 6185, 6238, 6668, 6812, 6280, 6516, 6845, 6453, 6500, 6445, 6465, 6520, 6218, 6648, 6189, 6473, 6536, 6408, 6721, 6371, 6760, 6330, 6625, 6367, 6222];
    uint16[] hightraffic= [uint16(380), 2018, 98, 4457, 1878, 2757, 5968, 363, 6780, 1784, 4704, 1802, 2015, 876, 1253, 4358, 1727, 6867, 2062, 5190, 1147, 1669, 1413, 3992, 2546, 4148, 1464, 4735, 4762, 6724, 1449, 5236, 3073, 2674, 597, 4431, 6498, 2988, 6359, 6820, 2785, 4344, 173, 3268, 5055, 1368, 4557, 45, 1098, 2964, 6463, 4736, 6926, 4794, 4669, 1484, 5202, 2237, 3871, 5527, 6425, 1339, 5395, 3579, 3083, 96, 5100, 4910, 1138, 2353, 6890, 2241, 6347, 3939, 5510, 3333, 4675, 5463, 3718, 4862];
    uint16[] zone4 = [uint16(6523), 3371, 2999, 2560, 396, 1989, 1966, 953, 5358, 3326, 6574, 6061, 6962, 5837, 512, 4375, 292, 338, 6831, 4949, 3019, 4676, 2608, 912, 5067, 695, 3367, 5876, 5175, 800, 5030, 1423, 5899, 2448, 5227, 5698, 3465, 5270, 4898, 656, 343, 5335, 3432, 3824, 77, 4318, 6775, 4924, 2235, 2665, 5909, 1419, 6333, 1767, 6364, 1710, 1655, 6190, 5568, 5138, 2307, 288, 2868, 5354, 1602, 5987, 5591, 1182, 5968, 4380, 1028, 5712, 2487, 334, 764, 3296, 6978, 5529, 3804, 4768, 5895, 949, 1706, 6493, 5315, 4857, 6885, 4441, 3193, 898, 4343, 1141, 3740, 6542, 3310, 4986, 5010, 94, 1403, 1546, 3081, 2690, 3202, 6000, 5293, 3582, 3428, 2393, 5006, 2055, 4882, 6446, 1679, 4181, 2956, 1229, 2813, 6850, 3886, 5051, 5401, 4640, 1012, 6738, 2281, 2901, 6411, 5378, 2147, 4569, 3612, 3757, 2795, 5953, 1506, 6914, 1697, 2541, 3429, 4616, 1947, 2668, 972, 2238, 134, 6294, 2941, 6847, 5768, 437, 4745, 4315, 821, 2015, 5380, 6406, 2916, 319, 2150, 876, 5103, 6685, 4712, 2982, 362, 5744, 1212, 5528, 4339, 3413, 4801, 4102, 1300, 6580, 270, 2193, 159, 6353, 6083, 3281, 2185, 6596, 17, 1195, 3901, 2243, 4143, 4513, 1204, 4006, 1654, 2078, 6892, 548, 1984, 6607, 1068, 3055, 6365, 4358, 3167, 6735, 4708, 3537, 1623, 303, 641, 4925, 1731, 3433, 4030, 1377, 4175, 5334, 5764, 2275, 2625, 196, 6236, 6373, 250, 3608, 1635, 2449, 4122, 4088, 5877, 6534, 3736, 5089, 4677, 1926, 5436, 2259, 5066, 769, 4948, 6076, 1875, 905, 1930, 4661, 4231, 2536, 4118, 6125, 3327, 6963, 1822, 1988, 1121, 544, 5861, 3059, 3370, 2998, 378, 6934, 1595, 2643, 1346, 5094, 2614, 3005, 2497, 774, 4406, 5082, 4369, 3156, 5597, 3910, 918, 1757, 5714, 5344, 2194, 3551, 559, 2340, 5743, 6180, 3382, 1215, 3228, 2593, 5256, 4914, 1002, 6397, 1147, 6728, 871, 5104, 4980, 2157, 4579, 2854, 4129, 575, 5850, 5780, 349, 6840, 1940, 5846, 3838, 5515, 2680, 3642, 6010, 6381, 4216, 2268, 922, 5112, 867, 2004, 6047, 6417, 2907, 6102, 2842, 2136, 4148, 2970, 2073, 5866, 6749, 5535, 1433, 6122, 6067, 6437, 1872, 1034, 2248, 5077, 6837, 4559, 3859, 5574, 6860, 4918, 1219, 1649, 806, 5523, 4298, 5935, 4277, 2209, 257, 1632, 1777, 5364, 2272, 5108, 26, 1235, 6909, 4488, 2675, 6773, 4164, 1736, 3422, 5149, 6765, 1274, 2008, 4830, 4099, 6677, 6362, 2321, 1019, 2770, 4427, 6949, 581, 3073, 2662, 89, 6764, 6508, 2674, 3065, 597, 3120, 3989, 2048, 5332, 5298, 344, 2273, 893, 5559, 6725, 4431, 6119, 6549, 5735, 5522, 4626, 2208, 2988, 738, 4919, 5125, 4221, 2526, 4558, 3337, 6420, 6973, 515, 450, 3008, 2619, 283, 6066, 112, 1577, 5164, 5471, 5922, 4519, 6174, 6031, 6945, 6380, 4217, 5810, 4702, 1384, 5797, 4169, 5001, 427, 1412, 1557, 831, 2947, 431, 4256, 3593, 5017, 962, 3985, 1812, 2013, 2156, 6816, 1280, 2785, 6396, 1516, 3878, 4850, 3696, 5257, 4915, 1097, 2341, 1582, 1306, 5650, 6705, 1490, 3638, 260, 4057, 4684, 1486, 5979, 2838, 5611, 237, 4779, 4329, 6601, 3053, 2212, 4994, 5686, 1295, 4428, 4701, 166, 4351, 920, 1446, 4490, 2114, 3210, 6012, 218, 832, 998, 131, 561, 5844, 5901, 2, 2397, 3343, 6454, 3656, 5628, 3085, 1542, 4605, 598, 6792, 6268, 3590, 6546, 2769, 5805, 5940, 5043, 1217, 4500, 2084, 4279, 6244, 2342, 3787, 6993, 5346, 4107, 5595, 449, 6643, 3011, 1606, 6593, 4054, 3791, 5350, 6985, 664, 3396, 4146, 6602, 4795, 5887, 1082, 3115, 45, 5491, 2704, 1763, 306, 4832, 243, 3565, 1108, 2724, 3973, 6622, 3359, 1364, 351, 4166, 3709, 4920, 3573, 6771, 3436, 2677, 717, 4170, 1372, 5331, 1519, 1149, 2335, 890, 3461, 193, 2509, 3318, 4127, 4577, 740, 5034, 557, 1132, 4019, 3226, 1866, 2749, 3158, 629, 1759, 2175, 5075, 3908, 453, 4371, 845, 2533, 4799, 1061, 957, 3660, 6462, 1718, 3375, 6874, 1963, 2709, 5166, 4327, 6064, 2027, 3909, 1934, 5424, 452, 4720, 1522, 5998, 1871, 2461, 6422, 628, 2877, 5432, 5598, 501, 4018, 3677, 5259, 2573, 3732, 4274, 556, 4599, 5672, 891, 1723, 4171, 4464, 6770, 4258, 3067, 5449, 1365, 3708, 4537, 700, 1670, 2660, 4130, 5721, 5234, 6418, 1277, 6048, 3860, 491, 3499, 2637, 5058, 3401, 4794, 1083, 3544, 2705, 3378, 4517, 4239, 6204, 4669, 1892, 3143, 3513, 1187, 3856, 4043, 4940, 2482, 1304, 4782, 4297, 1095, 6880, 1646, 6183, 366, 4151, 5740, 2768, 3179, 1514, 4716, 937, 3895, 3745, 2857, 3250, 576, 3987, 960, 6639, 6793, 1056, 3591, 2103, 2800, 5279, 2379, 3568, 4757, 3587, 6506, 4887, 5795, 4184, 4700, 4350, 167, 5111, 5541, 2284, 3883, 3929, 188, 1017, 1294, 6044, 3246, 6414, 6366, 3867, 880, 183, 479, 4567, 5399, 63, 2722, 3563, 3133, 6331, 584, 1698, 5264, 1227, 6448, 1118, 3963, 204, 1231, 5788, 5622, 22, 3871, 480, 3488, 4658, 3467, 5049, 3934, 4121, 1323, 5730, 4967, 1266, 1636, 4623, 2431, 3670, 6537, 4224, 1163, 6425, 3627, 2935, 3277, 2870, 455, 4662, 5589, 5136, 2759, 510, 6960, 2020, 793, 6825, 6608, 117, 3666, 5248, 2562, 6872, 2098, 3373, 1339, 2846, 5680, 1786, 5116, 5546, 3538, 4357, 5053, 4300, 3095, 2684, 1047, 6782, 588, 1728, 2104, 658, 1397, 5854, 4746, 434, 1401, 5696, 3742, 4087, 1285, 3607, 4341, 3484, 1143, 4711, 5100, 5415, 2780, 6239, 5317, 5747, 3369, 3806, 2190, 3781, 5340, 5985, 3152, 1495, 1600, 2186, 4547, 3328, 1315, 4117, 3902, 4681, 6716, 3847, 4906, 3390, 727, 1712, 4269, 1084, 2216, 5479, 42, 2353, 5245, 6039, 2979, 4454, 6469, 2095, 6202, 4395, 3450, 458, 4680, 6717, 5838, 1528, 2754, 4403, 3796, 4053, 264, 5212, 6982, 2168, 6828, 3779, 771, 321, 4679, 3446, 2257, 5438, 2312, 3850, 6701, 6351, 6582, 1247, 788, 6428, 4415, 3295, 1752, 2484, 419, 3554, 1990, 2345, 675, 4012, 6869, 730, 3368, 1841, 198, 6668, 5697, 4985, 2502, 5228, 2017, 3082, 3128, 6795, 1953, 6516, 6453, 659, 835, 5455, 6853, 6150, 4028, 2056, 2328, 862, 1504, 5814, 4356, 161, 1011, 5402, 1768, 6042, 2830, 5475, 4634, 5160, 2021, 1748, 2534, 454, 1524, 5834, 4376, 3626, 6074, 5434, 442, 157, 1532, 854, 6166, 1359, 2826, 4622, 4272, 2349, 5526, 5674, 4966, 5224, 3870, 3489, 4874, 710, 1375, 4198, 4032, 6776, 2365, 2220, 593, 3431, 1699, 5770, 4024, 6760, 4618, 2666, 614, 4970, 2631, 881];
    uint16[] zone3 = [uint16(6489), 2130, 6870, 2425, 3664, 1823, 5499, 1120, 545, 1065, 4267, 3408, 4637, 2219, 2167, 2921, 1527, 5134, 5564, 5421, 904, 1931, 5972, 1198, 2872, 6098, 6562, 6132, 5122, 1161, 4733, 5821, 4226, 3449, 441, 1927, 5437, 2126, 4158, 6165, 4508, 3737, 2960, 3388, 2063, 6759, 4764, 4334, 5525, 5460, 1970, 4066, 1634, 4436, 4820, 5732, 5362, 314, 4123, 1321, 4573, 1771, 4089, 894, 3936, 1458, 1008, 6722, 6688, 3170, 2331, 5620, 1399, 1663, 1726, 713, 4524, 6519, 1376, 590, 2673, 2389, 2223, 1819, 986, 4027, 210, 5636, 5773, 4162, 1360, 4532, 6276, 1049, 3074, 3561, 139, 3832, 2720, 4973, 4070, 247, 4565, 752, 3023, 181, 2632, 928, 882, 2798, 5548, 3865, 2777, 4359, 3166, 6734, 4284, 5495, 1985, 2700, 6256, 1593, 1069, 4791, 3687, 2995, 375, 1340, 725, 4007, 4457, 3392, 2429, 3845, 1878, 6344, 5991, 3003, 6201, 4396, 908, 1747, 3280, 322, 2491, 5704, 4816, 267, 1252, 508, 4695, 6352, 158, 2311, 1881, 3916, 6647, 3445, 4800, 6997, 1301, 4553, 6094, 2891, 1614, 621, 4416, 2468, 2038, 5207, 2716, 5179, 57, 6755, 3557, 3042, 1585, 3412, 5196, 2829, 4504, 1356, 2983, 4154, 5250, 4912, 5600, 1004, 1454, 3469, 2782, 5047, 3890, 877, 5552, 1842, 174, 4713, 5801, 1511, 2014, 1638, 1268, 4590, 4085, 748, 6112, 2151, 5694, 5440, 1950, 5913, 3594, 6796, 6283, 4744, 6779, 5856, 1116, 3828, 820, 1395, 2413, 2043, 6846, 5769, 5339, 4178, 3347, 4482, 4528, 3717, 1045, 420, 1946, 5456, 82, 1550, 6295, 5790, 3701, 709, 4494, 6153, 2110, 2794, 1911, 5952, 1157, 4355, 162, 3869, 1854, 6041, 6942, 5682, 3306, 6410, 5396, 6943, 2003, 5683, 2146, 1290, 2845, 5050, 925, 4211, 1013, 499, 4354, 5115, 3868, 5791, 2054, 4883, 2404, 3645, 4180, 2957, 1228, 2812, 6502, 6152, 4246, 3583, 1414, 5904, 7, 5457, 3995, 5142, 2687, 1551, 6001, 3653, 6902, 5787, 2042, 5292, 4179, 1681, 4529, 5441, 964, 1951, 4600, 1402, 1052, 6797, 1547, 6778, 6328, 3983, 5504, 4968, 2445, 1793, 6056, 1269, 3741, 4084, 749, 1286, 6810, 1455, 3192, 5945, 2629, 2279, 5046, 3891, 5553, 525, 4505, 698, 3690, 5314, 4856, 2081, 5251, 6884, 4913, 3385, 6187, 2717, 3805, 3106, 6754, 3556, 4786, 3043, 2652, 2202, 3297, 1245, 4047, 3782, 4944, 6979, 5656, 2039, 5206, 509, 5986, 1496, 2310, 3917, 5969, 3444, 6216, 3014, 1029, 289, 4544, 6129, 4114, 5355, 5705, 5210, 636, 2886, 1253, 2756, 5139, 1480, 3517, 3002, 4397, 724, 1711, 231, 3393, 4456, 4905, 2582, 2351, 3956, 5181, 1592, 4790, 3022, 3472, 929, 883, 5549, 1859, 37, 4972, 616, 4421, 246, 1789, 1273, 753, 4564, 1336, 4837, 2234, 6277, 1048, 568, 6332, 991, 211, 5637, 5267, 5288, 704, 4533, 3063, 591, 3599, 6631, 968, 99, 2388, 5508, 1818, 3825, 4319, 6324, 6774, 3576, 2808, 342, 4876, 6666, 1009, 6723, 6689, 21, 2330, 2760, 1265, 4964, 5226, 4821, 5363, 1320, 745, 1567, 5174, 5031, 5932, 4270, 1588, 5748, 4159, 4509, 2824, 3223, 381, 3389, 6922, 856, 1863, 1160, 4698, 5820, 505, 1025, 3448, 440, 2609, 913, 2873, 6563, 3331, 2170, 2520, 3624, 1619, 786, 143, 4374, 840, 5565, 5973, 1033, 6826, 5359, 2865, 790, 3262, 3798, 6060, 2920, 2023, 4773, 1064, 4266, 952, 728, 6488, 6172, 2131, 1658, 6037, 3235, 1983, 5539, 3814, 4328, 6315, 6600, 3052, 6250, 959, 689, 6483, 2839, 6529, 5755, 2090, 5610, 4001, 1203, 4451, 3394, 148, 1487, 3510, 518, 6712, 3906, 6657, 5702, 4543, 1741, 1311, 3639, 6591, 1254, 2881, 6968, 5578, 1868, 6704, 3506, 6354, 4693, 5981, 2252, 4105, 6092, 3290, 2481, 2897, 3785, 6587, 4410, 6753, 3802, 1995, 5190, 5313, 2086, 3697, 6495, 1350, 670, 4447, 4017, 2439, 6929, 934, 1901, 4200, 467, 4650, 5942, 1452, 6378, 1517, 4715, 5807, 3879, 2911, 3603, 6051, 5387, 2442, 5368, 6544, 4083, 3746, 1405, 5915, 6790, 4257, 2229, 5016, 2679, 1956, 2696, 3984, 4742, 3087, 1110, 4938, 2415, 3204, 1393, 4191, 1686, 3711, 2550, 2100, 2395, 84, 4241, 1043, 1413, 1556, 6293, 4754, 3091, 6769, 2950, 3212, 6856, 5283, 2546, 4538, 6155, 4168, 1690, 5954, 471, 3029, 888, 3880, 2638, 3496, 4979, 2454, 1278, 4580, 3300, 3750, 2511, 2141, 4996, 6876, 2566, 4518, 6525, 3377, 113, 1576, 4774, 3818, 4261, 406, 3770, 6572, 1608, 5132, 5831, 1521, 3459, 1464, 1937, 5427, 902, 5348, 6134, 3623, 781, 3789, 2032, 6358, 1864, 914, 5061, 447, 4670, 5962, 369, 6533, 739, 6925, 2065, 3224, 2966, 1833, 555, 5870, 105, 1130, 1425, 3418, 4627, 1075, 2659, 1976, 4060, 4430, 4125, 2858, 191, 6661, 3033, 2788, 5558, 3875, 4349, 6374, 3658, 650, 2049, 5276, 715, 345, 596, 3064, 5919, 129, 6289, 3571, 579, 2730, 2360, 5630, 5260, 6159, 6509, 5775, 6620, 580, 3588, 2233, 979, 2399, 5519, 2726, 1624, 4426, 3249, 5237, 1761, 2634, 5958, 1448, 187, 168, 6732, 30, 2635, 2265, 3024, 6699, 3161, 3531, 6733, 2320, 31, 3618, 3248, 2009, 5723, 4831, 305, 3423, 3970, 978, 1808, 3566, 6334, 3136, 4470, 1367, 702, 5324, 1408, 6288, 3570, 2731, 70, 981, 4466, 651, 3209, 5277, 6908, 4870, 4523, 190, 2789, 2623, 2336, 4348, 4962, 4124, 2859, 1998, 5488, 807, 1832, 4763, 5871, 554, 1561, 1131, 3419, 411, 3049, 2658, 3730, 6861, 6924, 2064, 6027, 1648, 1166, 6709, 5826, 1865, 1023, 1189, 1473, 3767, 4108, 6135, 3788, 6070, 3458, 2249, 5076, 6123, 6089, 6573, 2530, 6820, 6965, 796, 2926, 4325, 6748, 3819, 1961, 5888, 407, 4630, 1432, 6524, 3726, 4149, 3376, 391, 6898, 2588, 4978, 2455, 5390, 2005, 1783, 6046, 3301, 6800, 3478, 1015, 2269, 889, 923, 5406, 5113, 2286, 1853, 535, 4352, 3497, 4186, 6912, 5328, 6857, 4539, 2814, 4493, 3356, 2394, 85, 4240, 1042, 6787, 5902, 1107, 6292, 562, 5847, 3090, 4755, 3993, 2681, 2414, 2044, 348, 718, 5294, 5914, 2678, 5152, 827, 6284, 1111, 3252, 5369, 5693, 4578, 2855, 4082, 4128, 5410, 5040, 3897, 1003, 3194, 466, 489, 6683, 4714, 5806, 523, 2290, 5555, 870, 4503, 1701, 4446, 671, 4016, 221, 2068, 2438, 6928, 6302, 558, 3803, 50, 5484, 1994, 3946, 6247, 1078, 3291, 5715, 2896, 4041, 626, 5129, 2316, 2746, 5083, 4738, 6355, 4387, 6640, 5596, 2496, 6986, 5703, 4811, 775, 3287, 6085, 4112, 1255, 6590, 3268, 5216, 4954, 5996, 6713, 519, 5580, 6206, 1039, 1469, 6482, 688, 372, 4145, 1717, 4515, 4903, 1202, 1982, 5168, 5492, 6744, 3403, 5884, 4796, 1594, 3950, 958, 6803, 3302, 4078, 2905, 3617, 536, 5110, 2285, 5540, 5055, 2790, 3882, 6383, 473, 3181, 4644, 5956, 1738, 6157, 3355, 6854, 5281, 4886, 2051, 2401, 2952, 4185, 69, 2682, 3990, 3139, 6291, 1554, 424, 4613, 86, 5452, 1942, 5297, 1684, 3713, 2801, 6511, 4039, 1391, 2944, 2047, 4890, 5151, 2694, 5501, 1954, 5444, 90, 961, 6638, 1057, 4255, 3744, 4081, 1779, 6116, 5690, 2155, 3601, 4594, 1796, 6053, 2293, 873, 6680, 4347, 1515, 3528, 3197, 465, 1450, 3894, 2786, 6881, 5604, 2968, 672, 1702, 4150, 3695, 2987, 367, 6497, 5311, 3046, 3945, 2657, 3800, 2712, 808, 6301, 1094, 4042, 275, 4412, 1610, 5653, 3768, 3292, 3912, 2600, 3441, 4384, 6213, 6706, 3504, 5983, 3154, 4957, 4404, 799, 263, 6069, 3284, 4541, 6086, 4111, 3007, 1190, 3457, 4392, 5429, 5079, 1893, 5583, 849, 12, 6710, 234, 4003, 6194, 4900, 2587, 6878, 2138, 1344, 3379, 371, 1714, 2641, 3953, 408, 3050, 6252, 5868, 3861, 3498, 4218, 6675, 3924, 2266, 1299, 4131, 5370, 4998, 5720, 4977, 5665, 1626, 6419, 4424, 6337, 65, 2374, 3836, 2231, 428, 582, 6788, 6272, 5327, 1734, 4473, 4189, 5632, 5262, 2362, 982, 594, 1722, 1688, 4873, 4936, 4465, 1237, 4035, 3174, 486, 2765, 2270, 2620, 469, 6663, 3031, 4824, 2159, 255, 605, 4625, 1077, 6248, 4275, 1831, 6024, 6474, 384, 5258, 2067, 2572, 6862, 3363, 3699, 2821, 5576, 1535, 2460, 2933, 3271, 6589, 279, 4808, 6835, 2525, 1935, 1466, 5976, 4234, 516, 5833, 5999, 1870, 4058, 4408, 3637, 5219, 2026, 3322, 6570, 3288, 4263, 404, 4633, 5537, 49, 2358, 5167, 1124, 3549, 4776, 2972, 3230, 6032, 238, 4849, 2070, 393, 6463, 2836, 3724, 686, 2135, 4848, 6875, 4262, 1060, 5920, 1430, 5473, 5189, 5023, 1826, 110, 1575, 540, 6434, 5648, 5218, 2162, 2498, 3323, 3289, 901, 6658, 4665, 5977, 6208, 517, 1488, 5131, 844, 2031, 6971, 2932, 782, 3270, 2898, 6567, 3335, 444, 4673, 1471, 1888, 1867, 2748, 5577, 151, 5824, 4448, 2965, 6926, 3698, 2820, 1426, 5936, 4624, 4761, 1133, 1830, 4825, 2158, 5367, 741, 4576, 4063, 604, 1631, 5388, 1518, 2334, 25, 2764, 3899, 3933, 6398, 468, 1666, 2949, 653, 6459, 829, 3088, 4608, 6635, 3437, 6859, 5776, 2119, 3358, 215, 1220, 5799, 3564, 1559, 3134, 64, 995, 3421, 3071, 6789, 4560, 757, 1762, 307, 4999, 2908, 4425, 33, 2322, 3163, 6361, 6224, 3026, 184, 3925, 1918, 2267, 887, 5185, 2640, 3952, 5886, 6746, 1579, 6316, 1980, 4002, 665, 4901, 5243, 6896, 1345, 3728, 1191, 13, 1484, 5214, 5644, 1607, 6438, 632, 798, 6592, 2882, 262, 3285, 777, 327, 2494, 5701, 3913, 3440, 6642, 448, 3010, 6212, 5982, 3155, 5081, 1241, 5202, 5717, 4805, 2178, 6091, 1580, 3801, 5486, 1996, 6300, 2590, 6479, 1216, 4501, 4852, 5557, 2338, 29, 1144, 521, 4203, 1001, 464, 4653, 3196, 1902, 5042, 6117, 3315, 2504, 3600, 2912, 6402, 6052, 5853, 6286, 5150, 5015, 1955, 5445, 599, 6269, 4254, 6843, 4487, 6140, 1390, 4468, 5783, 2729, 999, 5146, 3991, 6290, 6785, 1040, 87, 3354, 2545, 2050, 2953, 3641, 5812, 3495, 2791, 5054, 5404, 921, 4215, 6228, 2512, 6802, 3303, 4079, 2007, 6736, 1509, 2775, 34, 3922, 3888, 3021, 6223, 4834, 3308, 300, 4137, 4072, 4588, 5663, 992, 2372, 6761, 3099, 3426, 5458, 4160, 4530, 5771, 1677, 5858, 3575, 3826, 984, 2671, 6798, 6262, 5767, 6848, 3719, 711, 1374, 4176, 4463, 4930, 2333, 2763, 2299, 6720, 3037, 2276, 5419, 4571, 4064, 6409, 414, 4789, 1071, 5462, 947, 1972, 5198, 59, 802, 5874, 4766, 3109, 4336, 3220, 6188, 6167, 1708, 2827, 4859, 5435, 4674, 4361, 5823, 506, 1860, 5120, 6075, 4048, 5209, 5659, 6999, 2489, 3332, 6130, 1460, 1899, 5423, 18, 843, 5566, 1525, 3148, 140, 2470, 3261, 2889, 6063, 6433, 639, 6126, 4818, 4635, 4320, 547, 4770, 814, 5531, 1821, 4009, 2077, 4091, 1769, 2515, 4992, 6043, 6413, 530, 1155, 6690, 475, 6385, 2796, 3884, 5403, 2112, 6852, 4496, 6151, 6444, 4479, 3646, 3216, 5792, 2407, 4750, 5842, 1552, 834, 5511, 1801, 5141, 3996, 4, 4245, 3580, 422, 5907, 3715, 4879, 3200, 6002, 2368, 3980, 5507, 3579, 6281, 4603, 4253, 5012, 2387, 1952, 2503, 6540, 3312, 4438, 2915, 4068, 5229, 5679, 6956, 176, 526, 1513, 2295, 5550, 875, 1840, 3938, 5946, 6669, 3386, 4443, 224, 5252, 4855, 4506, 4156, 2981, 2651, 2201, 3040, 1587, 3410, 6307, 1138, 4290, 5481, 4947, 5205, 4044, 6079, 2893, 623, 336, 3294, 766, 5710, 6995, 1180, 4382, 3851, 2743, 3502, 6700, 635, 4402, 265, 2885, 6983, 2493, 6829, 6080, 5585, 1895, 6203, 3144, 5993, 14, 6891, 2581, 4005, 6192, 2094, 4639, 6604, 4793, 3056, 5497, 2702, 818, 3543, 3407, 1590, 3057, 4792, 5029, 5183, 3954, 4287, 3112, 1206, 233, 1656, 6193, 663, 6486, 4511, 726, 4842, 5750, 5584, 6347, 3145, 1178, 5091, 15, 2304, 5707, 4116, 6644, 1928, 2742, 5984, 3153, 5654, 2191, 4946, 1617, 337, 6097, 5711, 6994, 3942, 2650, 2200, 5896, 4784, 6306, 1569, 6185, 225, 1210, 6886, 2129, 5316, 3738, 1705, 1355, 3692, 2980, 6687, 527, 4710, 2294, 1904, 3939, 3893, 1007, 6238, 1457, 6392, 462, 3743, 6541, 2914, 6054, 1791, 4069, 3256, 2447, 2693, 5156, 1816, 120, 4317, 4252, 5013, 5443, 97, 3344, 3714, 1729, 6845, 5290, 2040, 6003, 3651, 4751, 566, 1800, 5140, 1945, 6279, 6629, 2113, 3702, 4497, 1380, 4478, 3647, 4881, 2406, 39, 3539, 6691, 3493, 5052, 927, 6107, 1292, 4839, 2514, 4993, 2144, 5681, 6941, 3610, 2975, 6035, 6936, 2133, 2099, 6520, 3958, 1066, 1436, 6609, 403, 1123, 1573, 815, 3260, 6127, 3325, 2164, 4663, 5971, 4399, 5588, 5422, 19, 842, 3519, 1174, 2934, 5208, 2037, 5658, 6998, 6832, 3763, 3299, 3333, 3919, 911, 5064, 6218, 1498, 507, 5822, 5571, 6920, 6023, 383, 6473, 3364, 3734, 4858, 6865, 1420, 4788, 1070, 5033, 5463, 1973, 5199, 58, 3558, 550, 3108, 4823, 1267, 6058, 2332, 878, 3523, 481, 6371, 6664, 3466, 4209, 3036, 5048, 3935, 5336, 2559, 6849, 1725, 4527, 3348, 4462, 205, 1230, 5273, 3124, 1119, 5859, 985, 74, 3962, 3061, 6633, 356, 5320, 6019, 1676, 4474, 2723, 3098, 3132, 6330, 3077, 585, 4835, 1764, 3309, 244, 1271, 5662, 497, 3866, 3020, 6222];
    uint16[] zone2 = [uint16(3721), 2833, 729, 6173, 6935, 4908, 2976, 816, 5163, 4322, 5860, 1570, 4288, 5925, 2649, 5476, 5026, 5708, 6827, 4549, 791, 3633, 2188, 4725, 142, 3849, 841, 5071, 457, 1462, 1032, 3330, 2171, 2521, 2034, 6974, 2464, 6427, 1618, 6077, 1248, 3275, 857, 5572, 1862, 154, 1531, 5964, 2258, 6535, 3222, 6020, 3672, 6889, 1566, 553, 3808, 945, 4621, 5933, 4271, 1589, 1073, 1264, 3259, 3609, 4965, 2018, 2624, 5948, 197, 6237, 3035, 482, 6372, 20, 2761, 4932, 4461, 1233, 4174, 4877, 5765, 3598, 6260, 6630, 3961, 5509, 2736, 5159, 4748, 3577, 1225, 2059, 4861, 4498, 6626, 3424, 586, 2370, 5231, 5661, 1622, 1788, 1272, 1337, 5724, 6221, 3189, 2262, 5118, 2327, 36, 3536, 6743, 3111, 119, 6313, 2350, 3812, 2215, 3957, 6606, 3404, 2096, 4841, 6485, 1205, 230, 660, 5616, 4904, 2079, 6893, 2583, 5246, 5092, 1481, 3146, 3516, 3453, 1194, 6651, 3900, 2612, 5587, 6082, 4545, 1317, 4115, 6981, 5211, 5641, 4953, 4400, 637, 3795, 2887, 1497, 5084, 2741, 2254, 3015, 5342, 4103, 6581, 1244, 271, 4046, 3629, 5657, 2192, 1839, 1993, 3107, 4787, 6240, 2653, 3941, 2203, 733, 6169, 2080, 2595, 676, 3384, 1643, 6186, 1213, 3039, 461, 5944, 1907, 932, 5417, 3486, 6684, 524, 6954, 5381, 2444, 2917, 1792, 2852, 1287, 965, 436, 4601, 123, 5155, 3982, 1815, 5505, 2940, 4197, 4894, 5786, 2556, 2106, 2805, 3078, 4247, 1415, 5905, 2239, 1803, 5143, 135, 5840, 3097, 565, 4928, 2405, 3644, 3214, 6503, 3351, 924, 3185, 477, 4705, 532, 498, 861, 4586, 2517, 1291, 4093, 2844, 4587, 3242, 2453, 6806, 2516, 5379, 6105, 4138, 3307, 3887, 5400, 476, 533, 6739, 6693, 6369, 4929, 1678, 6017, 3700, 708, 3350, 358, 6851, 6781, 421, 2392, 83, 837, 4303, 1101, 564, 4753, 3203, 4196, 2557, 5338, 2107, 6144, 3346, 6514, 3716, 5011, 95, 3595, 6282, 3080, 5154, 3829, 6955, 1639, 4591, 3254, 6543, 3311, 6113, 3038, 4207, 6390, 4657, 460, 5416, 933, 3487, 1510, 2828, 1357, 2594, 5601, 677, 1642, 4010, 5178, 1992, 56, 2347, 6304, 4769, 1091, 4293, 6241, 6611, 5197, 948, 5343, 6996, 765, 1750, 2890, 3628, 2469, 6703, 4694, 3151, 1880, 2255, 6646, 2869, 773, 323, 5640, 4952, 4401, 1603, 4051, 5569, 1879, 3844, 2306, 6345, 3147, 4728, 6200, 2613, 5586, 5752, 3686, 1341, 6191, 661, 2428, 5617, 6938, 3540, 6742, 1087, 118, 5494, 40, 3813, 2214, 5928, 1438, 6257, 6220, 6670, 2633, 2263, 2776, 5119, 2326, 6559, 4134, 6109, 3976, 5908, 6627, 3425, 587, 3075, 6762, 3130, 138, 60, 2721, 3219, 1674, 3649, 6918, 2058, 354, 6261, 3960, 76, 4749, 4899, 1398, 1662, 207, 1727, 6518, 4525, 6148, 1459, 3034, 3521, 529, 3171, 483, 3872, 6959, 5676, 4572, 1770, 6758, 552, 1137, 4335, 3809, 801, 5461, 944, 1971, 417, 1422, 1072, 5898, 6867, 2577, 5318, 2127, 3366, 6021, 2961, 3673, 2062, 2598, 4362, 4732, 1530, 3018, 1475, 5965, 6099, 293, 6133, 6830, 6975, 3274, 1526, 513, 6719, 4724, 6349, 3848, 1199, 1463, 6430, 2473, 2189, 817, 5532, 5162, 5498, 114, 1571, 4289, 3409, 401, 2648, 5027, 3720, 2832, 682, 6871, 2074, 4909, 6467, 397, 2977, 5169, 2356, 5493, 1829, 4282, 5885, 6179, 2993, 723, 5305, 2585, 1653, 6196, 5997, 6342, 2751, 2301, 10, 1891, 5581, 6207, 5978, 1192, 1468, 4390, 5352, 6987, 3286, 6084, 324, 631, 3793, 261, 2028, 5217, 5647, 2182, 2747, 3855, 4739, 3443, 1184, 6211, 2602, 1307, 4555, 4806, 5201, 4294, 5485, 3947, 1079, 6616, 1429, 1700, 3678, 220, 6883, 5606, 5411, 5041, 6682, 488, 3480, 522, 1844, 2291, 6401, 2012, 6952, 5692, 2507, 1281, 6114, 3438, 4607, 3068, 3592, 963, 2383, 1540, 4312, 6905, 1669, 3341, 2803, 6513, 5295, 5450, 975, 6786, 4611, 830, 3992, 5145, 4187, 6440, 2116, 6505, 2815, 4492, 1444, 4646, 2792, 5407, 534, 1501, 4353, 6694, 1782, 3245, 6552, 5309, 3727, 2835, 6175, 390, 3232, 6899, 2423, 6933, 6319, 543, 5470, 955, 1063, 5923, 282, 778, 2531, 6821, 4959, 6964, 2474, 2024, 1258, 3265, 797, 2927, 5562, 847, 5098, 4723, 4373, 1171, 451, 3009, 4236, 2177, 5718, 6564, 6071, 2462, 2198, 1167, 502, 851, 5124, 1921, 4220, 693, 6499, 3361, 6163, 3731, 2435, 6026, 6476, 5489, 1560, 410, 5036, 4963, 5221, 1798, 607, 1327, 312, 4575, 3199, 6231, 892, 938, 2767, 1848, 6724, 3526, 3176, 1665, 3208, 200, 2419, 5626, 5333, 5299, 4522, 4172, 1370, 3967, 6266, 1059, 3434, 3121, 980, 71, 3988, 4888, 216, 1389, 646, 1673, 353, 4534, 88, 2376, 996, 6335, 611, 2458, 6948, 5372, 5688, 5722, 4563, 4133, 304, 1331, 3926, 2264, 6227, 3475, 6698, 492, 3863, 2771, 3927, 885, 6226, 186, 1449, 3474, 6363, 539, 3862, 4077, 5236, 2459, 5666, 4974, 5373, 4098, 4132, 1330, 997, 2377, 5518, 3835, 5631, 4889, 217, 1222, 647, 1388, 1672, 352, 6158, 4165, 5774, 2224, 1058, 3435, 1664, 4935, 5762, 714, 3462, 3198, 3931, 2766, 3874, 1849, 5670, 606, 1326, 4574, 4299, 4276, 5467, 942, 368, 6162, 2822, 2121, 2967, 3675, 4734, 915, 4671, 5349, 6836, 2875, 2930, 3622, 780, 2033, 2199, 846, 5563, 1873, 5099, 4722, 145, 1170, 5975, 1035, 4237, 903, 5426, 3321, 329, 3771, 2160, 2475, 2025, 3634, 1609, 6318, 542, 1824, 5021, 5758, 684, 3663, 3399, 6461, 3244, 3614, 2906, 6103, 309, 3751, 4094, 2843, 1296, 759, 2510, 3182, 3028, 866, 5543, 1500, 1150, 6695, 3213, 2052, 2547, 5282, 1941, 4610, 132, 4305, 6768, 5144, 6904, 4939, 5781, 6007, 3205, 1238, 6457, 3655, 1668, 4190, 4485, 3340, 1687, 6142, 2802, 3710, 2101, 1404, 1054, 3069, 2382, 2697, 3086, 124, 2910, 3602, 4597, 1795, 6050, 2443, 4981, 5739, 2506, 6545, 3747, 935, 1900, 4201, 4651, 3481, 6729, 5312, 2087, 5742, 2984, 4153, 364, 6494, 3679, 1644, 3229, 6882, 2592, 108, 3550, 6752, 2654, 5191, 5938, 6139, 333, 6093, 6569, 4554, 6990, 5345, 2480, 2195, 5200, 3784, 1243, 1869, 3854, 3157, 3442, 919, 5353, 1740, 325, 4407, 3792, 2880, 2029, 2479, 2183, 6969, 3511, 2750, 2300, 11, 3907, 1890, 3004, 3454, 4391, 3680, 2992, 722, 6528, 5304, 5241, 4000, 3395, 46, 3815, 1081, 3546, 4283, 6314, 2642, 5187, 2143, 6100, 3752, 6550, 6045, 4582, 6946, 5669, 5813, 1153, 6696, 3928, 1915, 5405, 189, 4214, 2817, 3705, 1692, 1368, 4869, 2544, 6911, 3640, 648, 5147, 1104, 4306, 3569, 4756, 4243, 1041, 6784, 1411, 2102, 4486, 6141, 3206, 4469, 5782, 577, 4310, 127, 1112, 3986, 824, 2381, 1407, 432, 2856, 3314, 2010, 5385, 2913, 609, 6403, 3251, 1846, 5556, 5106, 1145, 3178, 3482, 170, 520, 4202, 5413, 5254, 2591, 4916, 6182, 6478, 3380, 4015, 1352, 5741, 1581, 4629, 5038, 2207, 53, 6751, 2895, 1240, 5203, 5716, 4804, 2179, 4557, 760, 1885, 1493, 4691, 3857, 2745, 5080, 5215, 2180, 5645, 6439, 1743, 326, 1313, 2495, 4812, 6655, 4668, 3904, 2246, 2753, 5096, 1485, 3512, 5242, 6897, 4845, 2092, 5757, 5307, 2991, 3729, 2211, 3400, 1597, 3545, 6317, 1128, 3816, 2289, 32, 490, 3532, 6730, 6225, 3027, 4648, 185, 5409, 2636, 1919, 886, 4561, 1333, 5235, 2909, 6767, 1558, 994, 2661, 3420, 3070, 2548, 5777, 1671, 2698, 6264, 4609, 5448, 1958, 5018, 2227, 4520, 347, 5761, 5274, 5624, 2948, 652, 6376, 3898, 6399, 5736, 6819, 310, 1775, 4062, 1630, 4961, 1974, 941, 1427, 6618, 1562, 107, 5171, 4449, 3676, 5608, 6927, 691, 6161, 3733, 6531, 4222, 1020, 5960, 4672, 445, 1923, 1889, 5599, 2319, 5126, 150, 3508, 6970, 783, 6073, 2899, 6566, 2876, 6136, 900, 5425, 6659, 1036, 6209, 146, 1489, 1173, 5560, 795, 6435, 6966, 5649, 2163, 2499, 6120, 2860, 3772, 5921, 5472, 1962, 2708, 812, 111, 4326, 1574, 541, 5864, 2421, 392, 6198, 2837, 1348, 2134, 2420, 2973, 3231, 239, 6033, 6526, 6176, 1349, 4632, 405, 956, 5536, 3118, 1125, 4777, 5865, 794, 2924, 2532, 6822, 6121, 2861, 3773, 6571, 5074, 1467, 1037, 4235, 5832, 1172, 5561, 6072, 1758, 1308, 6834, 4809, 2524, 4223, 4389, 917, 1922, 2318, 1534, 3509, 4736, 385, 2436, 2089, 6863, 2123, 6160, 1076, 5873, 1099, 4331, 805, 5520, 6818, 3319, 1324, 311, 254, 6727, 487, 1148, 3175, 2621, 192, 6662, 3030, 4521, 346, 1689, 4872, 5275, 1236, 6009, 3821, 2733, 983, 3572, 6265, 595, 5019, 4167, 1735, 4022, 4472, 645, 4188, 4921, 5633, 5849, 6336, 1109, 2725, 3837, 3972, 6623, 4833, 5664, 1627, 2772, 868, 3533, 6731, 3476, 5408, 2210, 409, 3051, 1596, 5869, 1129, 3114, 44, 235, 1200, 3397, 1650, 6879, 6480, 370, 1715, 720, 3006, 6654, 4393, 3456, 2617, 1938, 3905, 5078, 3840, 6711, 2181, 4405, 4055, 1742, 6087, 4110, 1312, 6984, 2251, 2601, 4385, 6707, 1538, 6357, 1492, 4690, 3786, 6584, 624, 1611, 2197, 2528, 6838, 6992, 5347, 3339, 331, 4106, 4556, 6245, 4278, 3047, 6615, 3417, 2656, 2343, 3102, 3552, 5255, 5605, 2969, 673, 4014, 1703, 3694, 2986, 6496, 1847, 171, 5804, 6394, 5412, 2787, 4080, 1778, 2154, 4983, 2011, 2441, 6951, 4595, 258, 3084, 1543, 2695, 3968, 2380, 433, 5916, 4604, 2553, 1685, 3712, 6510, 3207, 6455, 3657, 5629, 2416, 1806, 5516, 68, 2683, 1105, 4307, 130, 1555, 5845, 4612, 5453, 2396, 1693, 4491, 1369, 4868, 5280, 2400, 649, 6013, 537, 864, 1914, 1447, 6678, 3180, 5957, 5687, 2841, 4096, 3753, 6551, 1781, 4583, 4429, 2904, 3616, 6947, 2457, 5238, 496, 3164, 2630, 6389, 6673, 2519, 3758, 1620, 245, 1270, 5233, 2688, 3830, 4249, 5008, 1362, 707, 4863, 5634, 212, 6018, 642, 3125, 6777, 2364, 75, 2221, 438, 2108, 2558, 1724, 3349, 1661, 4033, 5272, 3172, 6665, 6235, 896, 1909, 2626, 316, 746, 1773, 4822, 6059, 603, 5931, 4273, 5177, 2718, 1134, 101, 2061, 228, 2962, 1358, 6864, 2574, 2124, 910, 1026, 5966, 1499, 1533, 4418, 785, 2036, 6976, 2523, 3762, 290, 6560, 3298, 4398, 4232, 5073, 906, 1933, 2309, 3518, 5835, 4377, 6599, 2923, 6576, 286, 1749, 2165, 5474, 1067, 4265, 402, 1088, 5862, 1572, 5161, 6034, 3236, 6937, 5618, 2427, 2132, 2831, 3723, 6521, 681, 3689, 6106, 3304, 1293, 3754, 4838, 2145, 5395, 3241, 2903, 619, 38, 863, 2283, 1505, 5815, 3168, 160, 4212, 1010, 2811, 3353, 4183, 6014, 5268, 6917, 5638, 3979, 971, 80, 2391, 5004, 6278, 1378, 3345, 2807, 6844, 5291, 6901, 5784, 208, 2942, 79, 2692, 571, 3129, 1114, 5911, 1051, 6794, 5442, 96, 967, 2153, 6813, 6110, 1790, 3257, 2016, 6686, 5803, 3892, 5045, 1006, 1456, 3191, 4654, 463, 674, 6184, 1641, 1211, 6887, 5602, 4910, 6868, 1354, 3693, 3943, 5897, 6242, 6612, 1092, 3555, 1568, 5655, 789, 1246, 273, 2939, 6429, 1303, 1753, 4802, 2485, 4678, 6215, 4228, 1883, 5069, 2256, 5439, 3914, 2313, 5086, 859, 4697, 6350, 4052, 1250, 5643, 2169, 5356, 2539, 4814, 3778, 1745, 3282, 320, 2610, 2240, 3451, 4394, 6653, 1196, 459, 1483, 6346, 5839, 2755, 5614, 5244, 232, 6038, 1657, 398, 662, 6468, 2997, 4140, 3685, 6487, 3406, 1591, 5881, 5478, 2647, 4286, 6741, 6311, 6605, 4638, 6255, 4268, 5880, 1969, 5496, 1986, 819, 3542, 1085, 6740, 4907, 6890, 4004, 399, 3391, 2996, 3684, 4141, 2611, 3903, 1894, 3000, 6652, 5992, 3846, 634, 2884, 6594, 1251, 4950, 5642, 2538, 4815, 6081, 4383, 6214, 5068, 5592, 2607, 5087, 858, 4696, 1494, 6078, 4045, 2892, 4550, 4803, 5341, 5195, 6243, 1586, 5879, 4442, 3387, 2596, 5253, 2579, 5746, 4854, 4340, 5802, 1512, 874, 5551, 5101, 931, 2781, 5044, 4205, 5947, 4655, 3190, 2152, 6812, 4086, 2851, 1284, 6111, 6404, 3606, 4593, 5678, 5382, 2369, 989, 2739, 5506, 3578, 6280, 570, 5855, 4747, 1115, 435, 4602, 1400, 3597, 1050, 2386, 6146, 4481, 1379, 2806, 4878, 2410, 5785, 209, 4194, 2943, 136, 1103, 3094, 5843, 5510, 2685, 3997, 3978, 2390, 970, 589, 6783, 1046, 1416, 5906, 423, 4182, 5793, 6916, 5639, 5117, 1154, 4643, 3186, 5951, 474, 1441, 6384, 1912, 1338, 3305, 6557, 2847, 6804, 5394, 3240, 4585, 1787, 2902, 6412, 4458, 395, 4008, 5249, 2563, 680, 1965, 4321, 1089, 4771, 5530, 1820, 2471, 6961, 6598, 792, 2922, 6577, 2867, 4819, 1031, 1898, 1932, 1877, 5567, 4726, 511, 3149, 141, 4419, 6424, 6977, 2488, 2522, 291, 6561, 6131, 1924, 1027, 4225, 1477, 4675, 5988, 1162, 1861, 5121, 2060, 3221, 229, 3671, 679, 696, 6536, 2125, 415, 5176, 1836, 803, 1565, 1135, 100, 4337, 4120, 747, 1288, 4570, 5731, 4989, 4065, 2918, 6408, 4659, 6234, 1908, 2627, 2109, 3718, 340, 4177, 655, 1660, 5623, 4931, 3574, 2735, 1363, 4531, 706, 1733, 4862, 5265, 1226, 62, 3562, 6625, 3427, 5009, 5459, 1949, 2148, 5377, 5727, 1334, 4136, 4423, 4073, 5232, 5398, 6367, 1158, 3165, 6737, 5818, 1508, 2324, 3923, 3889, 6672];
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }
    event TransferReceived(address _from, uint _amount);
    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    // reference to the Block NFT contract
    ERC721Enumerable nft;
    IERC20 token;
    address private constant nftcontractaddress = 0xA476DE140Af5267D8561d5bB80b2b3392775b075;
    // maps tokenId to stake
    mapping(uint256 => Stake) public vault; 

    constructor(ERC721Enumerable _nft, IERC20 _token) { 
        contractowner = msg.sender;
        nft = _nft;
        token = _token;
    }
    receive() payable external {
        erc20balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }  
    function stake(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        totalStaked += tokenIds.length;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "not your token");
            require(vault[tokenId].tokenId == 0, 'already staked');

            nft.transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, tokenId, block.timestamp);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
    }

    function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        totalStaked -= tokenIds.length;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.transferFrom(address(this), account, tokenId);
        }
    }

    function claim(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, false);
    }

    function claimForAddress(address account, uint256[] calldata tokenIds) external {
        _claim(account, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, true);
    }

    function _zonerewards(uint256 _tokenId) internal view returns(uint256){
        for(uint i=0; i<2000; i++){
            if (zone2[i] == _tokenId) {
                return zone2reward;
            }else if(zone3[i] == _tokenId){
                return zone3reward;
            }else if(i<1000){
                if (zone4[i] == _tokenId){
                    return zone4reward;
                }
            }
        }
        return zone1reward;
    }
    function _billboardrewards(uint256 _tokenId) internal view returns(uint256){
        for(uint i=0; i<large.length; i++){
            if(large[i] == _tokenId){
                return largereward;
            }
        }
        for(uint i=0; i<small.length; i++){
            if(small[i] == _tokenId){
                return smallreward;
            }
        }
        return 0;
    }
    function _hightrafficrewards(uint256 _tokenId) internal view returns(uint256){
        for(uint i=0; i<hightraffic.length; i++){
            if(hightraffic[i] == _tokenId){
                return hightrafficreward;
            }
        }
    }
    function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
        uint256 tokenId;
        uint256 earned = 0;
        uint256 zone;
        uint256 billboard;
        uint256 hightrafficr;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
      
            require(staked.owner == account, "not an owner");
            uint256 stakedAt = staked.timestamp;
            zone = _zonerewards(tokenId);
            billboard = _billboardrewards(tokenId);
            hightrafficr= _hightrafficrewards(tokenId);
            if (tokenId<=3780) {
                earned =((standardbase + (standardbase*zone/100) + (standardbase*billboard/100) + (standardbase*hightrafficr/100))*(block.timestamp - stakedAt))/ 86400;
            }else if (tokenId<=6160){
                earned =((deluxebase + (deluxebase*zone/100) + (deluxebase*billboard/100) + (deluxebase*hightrafficr/100))*(block.timestamp - stakedAt))/ 86400;
            }else if (tokenId<=6860){
                earned =((villabase + (villabase*zone/100) + (villabase*billboard/100) + (villabase*hightrafficr/100))*(block.timestamp - stakedAt))/ 86400;
            }else if (tokenId<=7000){
                earned =((executivebase + (executivebase*zone/100) + (executivebase*billboard/100) + (executivebase*hightrafficr/100))*(block.timestamp - stakedAt))/ 86400;
            }

            vault[tokenId] = Stake({
                owner: account,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
        if (earned > 0) {
            token.transfer(account, earned);
        }
        if (_unstake) {
            _unstakeMany(account, tokenIds);
        }
        emit Claimed(account, earned);
    }

    function earningInfo(address account, uint256[] calldata tokenIds) external view returns (uint256[1] memory info) {
        uint256 tokenId;
        uint256 earned = 0;
        uint256 rewardmath = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "not an owner");
            uint256 stakedAt = staked.timestamp;
            rewardmath = 100 ether * (block.timestamp - stakedAt) / 86400;
            earned = rewardmath / 100;

        }
        if (earned > 0) {
            return [earned];
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = nft.totalSupply();
        for(uint i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

        uint256 supply = nftcontract(nftcontractaddress).maxSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for(uint tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index +=1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for(uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }
    function ercbalance() public view returns (uint cbalance) {
        return token.balanceOf(address(this));
    }
    function withdraw(uint256 withrawamount) public {
        require(msg.sender == contractowner, "Only owner can withdraw funds"); 
        require(withrawamount <= erc20balance, "balance is low");
        token.transfer(msg.sender, withrawamount);
        erc20balance -= withrawamount;
        emit TransferSent(msg.sender, msg.sender, withrawamount);
    }
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
  
}