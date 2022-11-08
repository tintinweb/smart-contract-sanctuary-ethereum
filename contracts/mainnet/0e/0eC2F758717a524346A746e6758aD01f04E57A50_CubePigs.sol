/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File @openzeppelin/contracts/token/ERC721/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File @openzeppelin/contracts/utils/[email protected]

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File @openzeppelin/contracts/token/ERC721/[email protected]

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File contracts/CpigColor.sol

pragma solidity ^0.8.4;

contract CpigColor {
    //bg colors
    string[] private bgcols_ = [
        "343238",
        "fef9ee",
        "8cc6e5",
        "465c9c",
        "cdacee",
        "9df6f6",
        "7360a4",
        "e0bcb2",
        "feb3af"
    ];

    //balloon colors
    string[] private blc0_ = ["913444", "349144", "344491"];
    string[] private blc1_ = ["ec6a5f", "6aec5f", "6265f2"];
    string[] private blcs = [
        blc0_[0],
        blc1_[0],
        blc0_[1],
        blc1_[1],
        blc0_[0],
        blc1_[0],
        blc0_[2],
        blc1_[2],
        blc0_[1],
        blc1_[1],
        blc0_[2],
        blc1_[2],
        blc0_[2],
        blc1_[2],
        blc0_[0],
        blc1_[0],
        blc0_[2],
        blc1_[2],
        blc0_[1],
        blc1_[1],
        blc0_[1],
        blc1_[1],
        blc0_[0],
        blc1_[0]
    ];

    //pinwheel colors
    string[] private pwcols_ = [
        "ed685e",
        "e6c951",
        "eb839a",
        "ec923b",
        "c29ffd",
        "6d8bc0",
        "a963c0",
        "7bcdbb"
    ];
    //Saturn colors
    string[] private prcols_ = ["da9d4d", "e4cfb5", "cb8b39", "d5a55e"];

    //party hat colors
    string[] private bhc0_ = ["ed685e", "e6c951", "eb839a", "ec923b"];
    string[] private bhc1_ = ["6d8bc0", "c29ffd", "7bcdbb", "a963c0"];
    //bat bowtie
    string[] private bats_ = ["eef", "ffd700", "343238"];

    function bgcols(uint8 idx) external view returns (string memory) {
        return bgcols_[idx];
    }

    function blc0(uint8 idx) public view returns (string memory) {
        return blc0_[idx];
    }

    function blc1(uint8 idx) public view returns (string memory) {
        return blc1_[idx];
    }

    function pwcols(uint8 idx) external view returns (string memory) {
        return pwcols_[idx];
    }

    function prcols(uint8 idx) external view returns (string memory) {
        return prcols_[idx];
    }

    function bhc0(uint8 idx) external view returns (string memory) {
        return bhc0_[idx];
    }

    function bhc1(uint8 idx) external view returns (string memory) {
        return bhc1_[idx];
    }

    function bats(uint8 idx) external view returns (string memory) {
        return bats_[idx];
    }

    // Generate balloons
    function genBln(uint8 bidx) external view returns (string memory) {
        uint8 d = bidx * 4;
        return (
            string(
                abi.encodePacked(
                    '<defs><path id="ln1" d="M0,0 q-10,15 0,30 q10,15 0,50 q-10,15 0,60" style="fill:none;stroke:#666;stroke-width:10"/><path id="bid1" d="M0,0 a75,120 -40,0,1 -60,-150 a64,52 0,0,1 120,0 a75,120 40,0,1 -60,150 l-5,10 10,0 -5,-10 z"/></defs><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 1],
                    ";stroke:#",
                    blcs[d],
                    ';stroke-width:10"/><animateMotion dur="10s" repeatCount="indefinite" path="M120,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 3],
                    ";stroke:#",
                    blcs[d + 2],
                    ';stroke-width:10"/><animateMotion dur="9s" repeatCount="indefinite" path="M330,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 1],
                    ";stroke:#",
                    blcs[d],
                    ';stroke-width:10"/><animateMotion dur="9.8s" repeatCount="indefinite" path="M530,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 3],
                    ";stroke:#",
                    blcs[d + 2],
                    ';stroke-width:10"/><animateMotion dur="9.2s" repeatCount="indefinite" path="M730,1200 l0,-1400"/></g><g><use href="#ln1"/><use href="#bid1" style="fill:#',
                    blcs[d + 1],
                    ";stroke:#",
                    blcs[d],
                    ';stroke-width:10"/><animateMotion dur="9.6s" repeatCount="indefinite" path="M900,1200 l0,-1400"/></g>'
                )
            )
        );
    }

    //Gen Lollipop
    function genLlp(uint8 bidx) external view returns (string memory) {
        string memory c = "";
        if (bidx == 0) {
            c = blc0_[1];
        }
        if (bidx == 1) {
            c = blc1_[2];
        }
        if (bidx == 2) {
            c = blc1_[0];
        }
        return (
            string(
                abi.encodePacked(
                    '<defs><mask id="h9m"><circle cx="0" cy="0" r="82" fill="#fff"/></mask><path id="h9l" d="M0,0 a10,10 0,0,1 -10,10 a15,15 0,0,1 -15,-15 a35,35 0,0,1 35,-35 a50,50 0,0,1 50,50 a65,65 0,0,1 -65,65 a85,85 0,0,1 -85,-85"/></defs><path d="M500,130 v125" style="fill:none;stroke:#',
                    c,
                    ';stroke-width:10"/><g transform="translate(500,130),scale(0.7,0.7)"><circle cx="0" cy="0" r="82" style="fill:#',
                    c,
                    '"/><g mask="url(#h9m)" style="fill:none;stroke:#',
                    bgcols_[1],
                    ';stroke-width:18"><use href="#h9l" /><g transform="rotate(180)"><use href="#h9l"/></g></g></g>'
                )
            )
        );
    }
}

// File contracts/CpigParts.sol

pragma solidity ^0.8.4;

contract CpigParts {
    address addrColor;

    constructor(address _addrColor) {
        addrColor = _addrColor;
    }

    // Eyes
    function genEyes(
        string memory tokenId,
        uint8 idx,
        uint8 sidx
    ) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        string memory bmsk = string(
            abi.encodePacked(
                '<mask id="esk"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                cc.bgcols(1),
                '"><animate attributeName="ry" dur="5s" values="80;1;80;80" keyTimes="0;0.02;0.03;1" repeatCount="indefinite"/></ellipse><ellipse cx="680" cy="500" rx="70" ry="80" fill="#',
                cc.bgcols(1),
                '"><animate attributeName="ry" dur="5s" values="80;1;80;80" keyTimes="0;0.02;0.04;1" repeatCount="indefinite"/></ellipse></mask>'
            )
        );

        // Galaxy
        if (idx == 0) {
            string memory e0id = string(abi.encodePacked("e0", tokenId));
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<defs><path id="e0" d="M0,0 a15,15 0,0,0 -15,15 a20,-20 0,0,0 20,20 a30,30 0,0,0 30,-30 a40,40 0,0,0 -40,-40 a60,60 0,0,0 -60,60 v-15 a60,60 0,0,1 60,-60 a50,50 0,0,1 50,50 a40,40 0,0,1 -40,40 a25,25 0,0,1 -25,-25 a20,20 0,0,1 20,-20 z" /><g id="e0a" transform="scale(0.6,0.6)"><g><use href="#e0"/><use href="#e0" x="0" y="-20" transform="rotate(180)"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,0,10;360,0,10" dur="20s" repeatCount="indefinite"/></g></g></defs><g mask="url(#esk)"><g id="',
                        e0id,
                        '"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><use x="320" y="495" href="#e0a" fill="#',
                        cc.pwcols(sidx),
                        '"/><circle cx="320" cy="500" r="8" fill="#',
                        cc.bgcols(1),
                        '"/></g><use x="360" href="#',
                        e0id,
                        '"/></g>'
                    )
                )
            );
        }
        // Blink
        else if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e0l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><ellipse cx="330" cy="490" rx="20" ry="20" fill="#',
                        cc.bgcols(1),
                        '"/></g><use href="#e0l" x="360"/></g>'
                    )
                )
            );
        }
        // Rolling
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<g id="e1l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><ellipse cx="310" cy="490" rx="20" ry="20" fill="#',
                        cc.bgcols(1),
                        '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,320,500;360,320,500" dur="5s" repeatCount="indefinite"/></ellipse></g><use href="#e1l" x="360"/>'
                    )
                )
            );
        }
        // Cute
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e2l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><circle cx="300" cy="470" r="26" fill="#',
                        cc.bgcols(1),
                        '"/><circle cx="340" cy="530" r="15" fill="#',
                        cc.bgcols(1),
                        '"/></g><use href="#e2l" x="360"/></g>'
                    )
                )
            );
        }
        // Red Heart
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><g id="e3h"><animateTransform attributeName="transform" attributeType="XML" type="scale" values="1,1;1.5,1.5;1,1;1.5,1.5;1,1;1,1" keyTimes="0;0.02;0.04;0.06;0.08;1" dur="5s" repeatCount="indefinite"/><path d="M-60,0 a30,30 0,0,1 60,0 a30,30 0,0,1 60,0 q0,45 -60,90 q-60,-45 -60,-90 z" fill="#',
                        cc.blc1(0),
                        '"/></g></defs><use href="#e3h" x="320" y="470"/><use href="#e3h" x="680" y="470"/>'
                    )
                )
            );
        }
        // Star
        else if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e5l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><path d="M300,500 q20,-20 20,-40 q0,20 20,40 q-20,20 -20,40 q0,-20 -20,-40 z" fill="#',
                        cc.bgcols(1),
                        '"/></g><use href="#e5l" x="360"/></g>'
                    )
                )
            );
        }
        //Wink
        else if (idx == 6) {
            return (
                string(
                    abi.encodePacked(
                        '<mask id="e8m0"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#fff"/></mask><mask id="e8m1"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#fff"><animate attributeName="ry" dur="5s" values="80;1;1;80;80" keyTimes="0;0.02;0.22;0.24;1" repeatCount="indefinite"/></ellipse></mask><path mask="url(#e8m0)" d="M240,520 a50,25 0,0,1 160,0 a50,10 0,0,0 -160,0" fill="#',
                        cc.bgcols(0),
                        '"/><g mask="url(#e8m1)"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '" opacity="1"/><ellipse id="e8l" cx="330" cy="500" rx="20" ry="20" fill="#',
                        cc.bgcols(1),
                        '"><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;0,-25;0,-25;0,0;0,0" keyTimes="0;0.02;0.22;0.24;1" dur="5s" repeatCount="indefinite"/></ellipse></g><ellipse cx="680" cy="500" rx="70" ry="80" fill="#',
                        cc.bgcols(0),
                        '"/><use href="#e8l" x="360"/>'
                    )
                )
            );
        }
        // Cyborg
        else if (idx == 7) {
            return (
                string(
                    abi.encodePacked(
                        bmsk,
                        '<g mask="url(#esk)"><g id="e6l"><circle cx="320" cy="500" r="60" style="fill:#',
                        cc.blc0(2),
                        '"/><circle cx="320" cy="500" r="50" style="fill:none;stroke:#',
                        cc.bgcols(4),
                        ';stroke-width:10;stroke-dasharray:4,18"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,320,500;360,320,500" dur="30s" repeatCount="indefinite"/></circle><circle cx="320" cy="500" r="40" style="fill:none;stroke:#',
                        cc.blc1(2),
                        ';stroke-width:6;"/><circle cx="320" cy="500" r="30" style="fill:none;stroke:#',
                        cc.bats(0),
                        ';stroke-width:6;stroke-dasharray:10,10"><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,320,500;-360,320,500" dur="30s" repeatCount="indefinite"/></circle><circle cx="320" cy="500" r="20" style="fill:#',
                        cc.bgcols(1),
                        '"/></g><use href="#e6l" x="360"/></g>'
                    )
                )
            );
        }
        // Lazer
        else return "";
    }

    // Hat
    function genHat(
        string memory tokenId,
        uint8 idx,
        uint8 sidx
    ) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        // Pinwheels
        if (idx == 0) {
            return (
                string(
                    abi.encodePacked(
                        '<line x1="500" y1="260" x2="500" y2="120" stroke="#',
                        cc.bgcols(0),
                        '" stroke-width="10"/><g><path d="M500,130 l0,-100 q80,30 0,100 l0,100 q-80,-30 0,-100 l100,0 q-30,80 -100,0 l-100,0 q30,-80 100,0 z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10;"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="0,500,130;360,500,130" dur="3s" repeatCount="indefinite"/></g>'
                    )
                )
            );
        }
        // Party Hat
        else if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><pattern id="h4',
                        tokenId,
                        '" viewBox="-20,-20,40,40" width="28%" height="28%"><rect x="-12" y="-12" width="5" height="24" fill="#',
                        cc.bhc1(sidx),
                        '"/><ellipse cx="10" rx="6" ry="10" style="fill:none;stroke:#',
                        cc.bhc1(sidx),
                        ';stroke-width:5"/></pattern></defs><path d="M400,260 l200,0 -100,-200 -100,200 z" style="fill:#',
                        cc.bhc0(sidx),
                        '"/><path d="M400,260 l200,0 -100,-200 -100,200 z" fill="url(#h4',
                        tokenId,
                        ')"/><path d="M400,260 l200,0 -100,-200 -100,200 z" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/><circle cx="500" cy="60" r="20" style="fill:#',
                        cc.bhc0(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                )
            );
        }
        // Black Standing Hair
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M450,260 a20,40 -20,0,1 -10,-120 a10,10 0,1,1 -20,30 M500,260 a30,60 0,0,1 0,-160 a20,20 0,0,1 -20,40 M530,260 a20,40 0,0,1 10,-120 a10,10 0,1,1 -20,30" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        // Black Side Parting
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M470,260 a12,30 -10,0,1 60,80 M500,260 a10,30 -10,0,1 60,80 M530,260 a12,30 -10,0,1 60,80" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        // Antenna
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<polyline points="340,90 500,250 660,90" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;stroke-linecap:round"/><polyline points="410,160 500,250 590,160" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:20;stroke-linecap:round"/>'
                    )
                )
            );
        }
        //Green Lollipop
        else if (idx == 5) {
            return (cc.genLlp(0));
        }
        //Blue Lollipop
        else if (idx == 6) {
            return (cc.genLlp(1));
        }
        // Gold Standing Hair
        else if (idx == 7) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M450,255 a20,40 -20,0,1 -10,-120 a10,10 0,1,1 -20,30 M500,255 a30,60 0,0,1 0,-160 a20,20 0,0,1 -20,40 M530,255 a20,40 0,0,1 10,-120 a10,10 0,1,1 -20,30" style="fill:none;stroke:gold;stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        // Gold Side Parting
        else if (idx == 8) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M470,255 a12,30 -10,0,1 60,80 M500,255 a10,30 -10,0,1 60,80 M530,255 a12,30 -10,0,1 60,80" style="fill:none;stroke:gold;stroke-width:10;stroke-linecap:round"/>'
                    )
                )
            );
        }
        //Red Lollipop
        else if (idx == 9) {
            return (cc.genLlp(2));
        }
        // Crown
        else if (idx == 10) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M400,230 l200,0 0,30 -200,0 0,-30 -50,-120 q110,140 150,-40 q40,180 150,40 l-50,120 z" style="fill:gold;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/><circle id="crn1" cx="350" cy="110" r="12" style="fill:gold;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/><use href="#crn1" x="150" y="-45"/><use href="#crn1" x="300"/>'
                    )
                )
            );
        }

        return "";
    }
}

// File contracts/CpigParts2.sol

pragma solidity ^0.8.4;

contract CpigParts2 {
    address addrColor;

    constructor(address _addrColor) {
        addrColor = _addrColor;
    }

    // Neck
    function genNeck(uint8 idx, uint8 sidx)
        external
        view
        returns (string memory)
    {
        CpigColor cc = CpigColor(addrColor);

        // Bowtie
        if (idx == 0) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M360,830 a100,50 20,0,1 140,40 a100,50 20,0,0 140,40 a20,50 0,0,0 0,-80 a100,50 -20,0,0 -140,40 a100,50 -20,0,1 -140,40 a20,50 0,0,1 0,-80 z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><rect x="480" y="850" rx="10" ry="10" width="40" height="40" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                );
        }

        // Bowknot
        if (idx == 1) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M500,870 q-10,-40 -80,-60 q-30,40 0,80 l80,-20 q-80,30 -100,80 q20,20 60,40 q30,-50 40,-120 q10,-40 80,-60 q30,40 0,80 l-80,-20 q80,30 100,80 q-20,20 -60,40 q-30,-50 -40,-120 z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><rect x="480" y="850" rx="10" ry="10" width="40" height="40" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                );
        }

        // Tie
        if (idx == 2) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M450,860 l100,0 -30,40 -40,0 -30,-40z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><path d="M480,900 l40,0 20,80 -40,20 -40,-20 20,-80z" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/><path d="M340,860 l100,50 40,-50z M660,860 l-100,50 -40,-50z" style="fill:#',
                        cc.bgcols(1),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                );
        }

        //  Scarf
        if (idx == 3) {
            return
                string(
                    abi.encodePacked(
                        '<defs><rect id="nas" x="0" y="0" rx="15" width="60" height="150"/><mask id="nam"><rect x="250" y="820" width="500" height="160" fill="#fff"/><rect x="250" y="800" rx="0" ry="0" width="500" height="43" fill="#000"/></mask></defs><g mask="url(#nam)" style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10"><g transform="translate(540,830)"><use transform="rotate(-8)" href="#nas"/></g><rect style="fill:#',
                        cc.pwcols(sidx),
                        ";stroke:#",
                        cc.bgcols(0),
                        ';stroke-width:10" x="300" y="855" rx="10" width="400" height="55"/><g transform="translate(550,780)"><use transform="rotate(8)" href="#nas"/></g></g>'
                    )
                );
        }

        // Bat
        if (idx == 4) {
            return
                string(
                    abi.encodePacked(
                        '<path d="M500,880 q-50,-60 -200,-100 q100,60 60,120 q50,-30 80,30 q10,-30 60,-50 q50,-60 200,-100 q-100,60 -60,120 q-50,-30 -80,30 q-10,-30 -60,-50 z" style="fill:#',
                        cc.bats(sidx),
                        ';stroke:none"/><path d="M480,890 l10,20 10,-15 10,15 10,-20 v-40 h-40 v40" style="fill:#',
                        cc.bats(sidx),
                        ';stroke:none"/>'
                    )
                );
        }

        return "";
    }

    // Glasses
    function genGls(uint8 idx) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        // Circle
        if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M435,500 a100,80 0,0,1 130,0 M240,420 a80,80 0,0,1 160,160 a80,80 0,0,1 -160,-160 M600,420 a80,80 0,0,1 160,160 a80,80 0,0,1 -160,-160" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                )
            );
        }
        // 3D
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<path d="M450,400 l0,160 -40,40 -210,0 0,-200 z" style="fill:blue;opacity:0.35"/><path d="M550,400 l250,0 0,200 -210,0 -40,-40 z" style="fill:red;opacity:0.35"/><path d="M450,400 l0,160 -40,40 -210,0 0,-200 600,0 0,200 -210,0 -40,-40 0,-160" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;"/>'
                    )
                )
            );
        }
        // Polygon
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><mask id="g3m"><path d="M470,440 L530,440 860,390 880,490 660,610 560,550 530,450 470,450 440,550 340,610 120,490 140,390 470,440 z" fill="#',
                        cc.bgcols(1),
                        '"/></mask><mask id="g3c"><circle r="20" fill="#',
                        cc.bgcols(1),
                        '"><animateMotion dur="3s" repeatCount="indefinite" path="M470,440 L530,440 860,390 880,490 660,610 560,550 530,450 470,450 440,550 340,610 120,490 140,390 470,440 z"/></circle></mask><g id="g3n"><path d="M10,650 l200,-450 M430,650 l200,-450" style="stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:20;opacity:0.5"></path></g></defs><g mask="url(#g3m)"><use href="#g3n"><animate attributeName="x" values="0;410;0;410;410" keyTimes="0;0.2;0.2;0.4;1" dur="8s" repeatCount="indefinite"/></use></g><path d="M470,440 L530,440 860,390 880,490 660,610 560,550 530,450 470,450 440,550 340,610 120,490 140,390 470,440 z" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10;opacity:1"/>'
                    )
                )
            );
        }
        //Smart
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><symbol id="ufo" width="200" height="200" viewBox="0 0 200 200"><g><ellipse cx="50" cy="50" rx="45" ry="10" style="fill:#',
                        cc.blc1(1),
                        ';opacity:0.6;"/><ellipse cx="50" cy="55" rx="25" ry="6" style="fill:#',
                        cc.blc1(1),
                        ';opacity:0.4;"/><path d="M30,40 a30,50 0,0,1 40,0 z" style="fill:#',
                        cc.blc1(1),
                        ';opacity:0.7;"/></g></symbol><path id="g4p" d="M140,380 L860,380 C860,620 750,620 700,620 C560,620 560,520 500,520 C440,520 440,620 300,620 C250,620 140,620 140,400 z"/><mask id="g4m"><path id="g4p" d="M140,380 L860,380 C860,620 750,620 700,620 C560,620 560,520 500,520 C440,520 440,620 300,620 C250,620 140,620 140,400 z" fill="#fff"/></mask></defs><use href="#g4p" style="fill:#',
                        cc.blc1(2),
                        ';opacity:0.3;"/><use href="#g4p" style="fill:none;stroke:#',
                        cc.blc1(2),
                        ';stroke-width:10"/><g mask="url(#g4m)"><g><g transform="rotate(-18)"><use href="#ufo"/></g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="350,600;350,600;150,300" keyTimes="0;0.5;1"  dur="5.2s" repeatCount="indefinite"/></g><g><g transform="rotate(5)"><use href="#ufo"/></g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="400,620;400,620;510,300" keyTimes="0;0.56;1" dur="5.5s" repeatCount="indefinite"/></g><g><g transform="rotate(22)"><use href="#ufo"/></g><animateTransform attributeName="transform" attributeType="XML" type="translate" values="600,600;600,600;780,300" keyTimes="0;0.58;1" dur="7s" repeatCount="indefinite"/></g></g>'
                    )
                )
            );
        }
        //LED
        else if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><pattern id="g7p1" viewBox="0,0,10,10" width="1.5%" height="5.4%"><circle cx="5" cy="5" r="5" style="fill:#',
                        cc.bgcols(0),
                        '"/></pattern><pattern id="g7p2" viewBox="0,0,10,10" width="1.5%" height="5.4%"><circle cx="5" cy="5" r="5" style="fill:#',
                        cc.blc1(1),
                        '"/></pattern><rect id="g7r" x="120" y="390" rx="40" ry="40" width="760" height="200"/><mask id="g7msk"><g><path d="M340,430 h-100 v120 h100 M390,560 v-130 h100 v50 h-100 M550,420 v140 M720,430 h-110 v120 h100 v-60 h-60" style="fill:none;stroke:#fff;stroke-width:20"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="900,0;900,0;0,0;-20,0;-700,0" keyTimes="0;0.2;0.4;0.6;1" dur="8s" repeatCount="indefinite"/></g></mask></defs><use href="#g7r" style="fill:',
                        cc.bgcols(0),
                        ';opacity:0.3"/><use href="#g7r" style="fill:url(#g7p1);opacity:0.3"/><g mask="url(#g7msk)"><use href="#g7r" fill="url(#g7p2)"/></g><use href="#g7r" style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:10"/>'
                    )
                )
            );
        }

        //None
        return "";
    }

    // Earring
    function genErs(uint8 idx) external view returns (string memory) {
        CpigColor cc = CpigColor(addrColor);

        //Silver
        if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<circle cx="120" cy="380" r="5" fill="#',
                        cc.bgcols(0),
                        '"/><path d="M120,380 a10,30 30,1,0 -10,25" style="fill:none;stroke:#ccd;stroke-width:10"/>'
                    )
                )
            );
        }

        //Gold
        if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<circle cx="120" cy="380" r="5" fill="#',
                        cc.bgcols(0),
                        '"/><path d="M120,380 a10,30 30,1,0 -10,25" style="fill:none;stroke:gold;stroke-width:10"/>'
                    )
                )
            );
        }

        //Diamond
        if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><path id="d" d="M0,-13 l12,-7 -24,0z M12,-7 l12,7 -12,7z M0,13 l12,7 -24,0z M-12,7 l-12,-7,12,-7z"/></defs><g transform="scale(1.2,1.2),translate(-20,-60)"><path d="M150,348 l12,7 0,15 -12,7 -12,-6 0,-15 12,-7 z" fill="#eef"/><use href="#d" x="150" y="363" fill="#dde"/><g transform="translate(150,363)"><use href="#d" fill="#ccd" transform="rotate(120)"/></g><g transform="translate(150,363)"><use href="#d" fill="#aab" transform="rotate(-120)"/></g></g>'
                    )
                )
            );
        }

        //Spiral
        if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><g id="r4s" transform="rotate(160)"><path d="M0,0 a5,5 0,0,1 -5,5 a5,5 0,0,1 -5,-5 a10,10 0,0,1 10,-10 a15,15 0,0,1 15,15 a25,25 0,0,1 -25,25 a40,40 0,0,1 -40,-40 a65,65 0,0,1 65,-65 a105,105 0,0,1 105,105 a170,170 0,0,1 -170,170" style="fill:none;stroke:#',
                        cc.bats(1),
                        ';stroke-width:8;stroke-linecap:round"/></g><mask id="r4m"><rect x="0" y="300" width="250" height="400" fill="#fff"/><path d="M90,380 l20,25 20,-15 -20,-15z" fill="#000"/></mask></defs><circle cx="120" cy="380" r="8" fill="#a5a990"/><g mask="url(#r4m)"><use href="#r4s" x="180" y="565"/></g>'
                    )
                )
            );
        }

        //Neon
        if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        '<circle cx="120" cy="380" r="8" fill="#',
                        cc.bgcols(0),
                        '"/><defs><linearGradient id="r6g" gradientTransform="rotate(90)"><stop offset="0%" stop-color="#',
                        cc.blc1(0),
                        '"/><stop offset="25%" stop-color="#',
                        cc.blc1(1),
                        '"/><stop offset="75%" stop-color="#',
                        cc.blc1(2),
                        '"/><stop offset="100%" stop-color="#',
                        cc.blc1(0),
                        '"/></linearGradient><mask id="r6m"><g style="fill:none;stroke:#fff;stroke-width:8"><path d="M120,460 l-26,15 v30 l-26,15 v30 l26,15 l26,-15 v-30 l-26,-15 M120,460 l26,15 v30 l26,15 v30 l-26,15 l-26,-15 v-30 l26,-15"/><path d="M120,380 l34.6,20 v40 l-34.6,20 -34.6,-20 v-40 l14,-8"/></g></mask></defs><g mask="url(#r6m)"><g><rect id="r6r" x="40" y="0" width="150" height="300" fill="url(#r6g)" opacity="1"/><use href="#r6r" y="300"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;0,300" keyTimes="0;1" dur="5s" repeatCount="indefinite"/></g></g>'
                    )
                )
            );
        }

        //Alien
        if (idx == 6) {
            return (
                string(
                    abi.encodePacked(
                        '<mask id="r5m"><path d="M103,570 c-30,-20 -50,-70 0,-80 c50,10 30,60 0,80z" style="fill:#fff"/><path d="M80,510 a15,13 60,0,1 13,23 a15,13 60,0,1 -13,-23 M125,510 a15,13 -60,0,1 -13,23 a15,13 -60,0,1 13,-23z" style="fill:#000"/><circle cx="103" cy="500" r="5" fill="#000"/></mask><g fill="#',
                        cc.bgcols(0),
                        '"><rect mask="url(#r5m)" x="70" y="480" width="80" height="100" /><path d="M88,450 a25,60 0,0,1 28,0 M80,454 a20,5 0,0,1 46,0 a20,5 0,0,1 -46,0"/></g><circle cx="103" cy="360" r="5" fill="#',
                        cc.bgcols(0),
                        '"/><g style="fill:none;stroke:#',
                        cc.bgcols(0),
                        ';stroke-width:6"><path d="M103,500 v-40 M103,440 v-45"/><path d="M103,360 a8,8 0,0,1 10,10 l10,13"/></g>'
                    )
                )
            );
        }

        //None
        return "";
    }
}

// File contracts/CpigBG.sol

pragma solidity ^0.8.4;

contract CpigBG {
    address addrColor;

    constructor(address _addrColor) {
        addrColor = _addrColor;
    }

    string private bst =
        string(
            abi.encodePacked(
                '<defs><pattern id="star" viewBox="0,0,10,10" width="6%" height="6%"><circle cx="2" cy="2" r="1" fill="#9df6f6"/></pattern></defs><path d="M30,30 L250,285 50,235 250,10 350,250 600,20 400,50 550,240 850,30 980,300 700,80 970,500 880,560 960,700 880,950 700,990 850,800 500,970 400,860 300,965 200,840 30,980 150,600 20,760 160,400 10,360" style="fill:none;stroke:url(#star);stroke-width:20"/>'
            )
        );

    // Generate Background
    function genBG(uint8 idx, uint8 bidx)
        external
        view
        returns (string memory)
    {
        CpigColor cc = CpigColor(addrColor);

        // Ballons
        if (idx == 0) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(2),
                        '"/>',
                        cc.genBln(bidx)
                    )
                )
            );
        }
        // Clouds
        else if (idx == 1) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(2),
                        '"/><path id="cld1" d="M0,0 l200,0 a50,50 0,0,0 0,-100 a80,60 0,0,0 -160,-20 a60,60 0,0,0 -20,120 z" fill="#fef9ee"/><use href="#cld1" x="0"><animateMotion dur="50s" repeatCount="indefinite" path="M-300,200 l1500,0"/></use><use href="#cld1" x="0" transform="scale(0.6,0.6)"><animateMotion dur="60s" repeatCount="indefinite" path="M-300,300 l1500,0"/></use><use href="#cld1" x="0" transform="scale(0.6,0.6)"><animateMotion dur="70s" repeatCount="indefinite" path="M-200,150 l1500,0"/></use>'
                    )
                )
            );
        }
        // Starry Sky
        else if (idx == 2) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(3),
                        '"/>',
                        bst,
                        '<defs><symbol id="bss" width="100" height="100" viewBox="0 0 100 100"><circle cx="50" cy="50" r="15" fill="#',
                        cc.bgcols(5),
                        '" opacity="0.5"/><circle cx="50" cy="50" r="8" fill="#',
                        cc.bgcols(5),
                        '"/><path d="M0,50 h100 M50,0 v100" style="fill:none;stroke:#',
                        cc.bgcols(5),
                        ';stroke-width:5;opacity:0.6"/></symbol><symbol id="bird" width="200" height="200" viewBox="0 0 200 200"><g><path d="M50,100 l40,-5 50,-30 50,-10 -30,-5 -20,8 -18,0 -48,18 z"/><polygon points="125,58 70,130 75,78 125,58 140,110 75,78"><animate attributeName="points" values="125,58 70,130 75,78 125,58 140,110 75,78;125,58 50,40 75,78 125,58 120,40 75,78;125,58 70,130 75,78 125,58 140,110 75,78" dur="2s" repeatCount="indefinite"/></polygon><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,-10;0,10;0,-10" dur="2s" repeatCount="indefinite"/></g></symbol></defs><circle cx="720" cy="160" r="80" style="fill:#',
                        cc.bgcols(1),
                        ';stroke:none"/><use href="#bss" x="100" y="80"><animate attributeName="opacity" values="0.3;1;0.3" dur="7s" repeatCount="indefinite"/></use><g><use href="#bird" fill="#',
                        cc.bgcols(0),
                        '"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="-300,200;1050,30" dur="30s" repeatCount="indefinite"/></g>'
                    )
                )
            );
        }
        // Star Trails
        else if (idx == 3) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(6),
                        '"/><defs><g id="b3"><circle r="150" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:30,70"/><circle r="200" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:50,80"/><circle r="300" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:60,120"/><circle r="380" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:70,100"/><circle r="450" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:75,160"/><circle r="560" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:80,190"/><circle r="620" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:80,190"/><circle r="680" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:87,185"/><circle r="750" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:120,200"/><circle r="800" style="fill:none;stroke:#',
                        cc.bgcols(1),
                        ';stroke-width:5;stroke-dasharray:100,220"/><circle r="900" style="fill:none;stroke:#',
                        cc.bgcols(7),
                        ';stroke-width:5;stroke-dasharray:100,220"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0,0,0" to="360,0,0" dur="100s" repeatCount="indefinite"/></g></defs><use x="800" y="500" href="#b3"/>'
                    )
                )
            );
        }
        // Radar
        else if (idx == 4) {
            return (
                string(
                    abi.encodePacked(
                        '<defs><linearGradient id="bl4" gradientTransform="rotate(-45)"><stop offset="0%" stop-color="#',
                        cc.bgcols(6),
                        '"/><stop offset="50%" stop-color="#',
                        cc.pwcols(7),
                        '"/></linearGradient></defs><rect height="1000" width="1000" fill="#',
                        cc.bgcols(6),
                        '"/><path d="M500,500 l0,-560 a560,560 0,0,0 -560,560 l560,0 z" fill="url(#bl4)" opacity="0.8" stroke="none"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 500" to="360 500 500" dur="3s" repeatCount="indefinite"/></path><circle cx="500" cy="500" r="560" style="fill:#',
                        cc.pwcols(7),
                        ';opacity:0.3"/><g style="fill:none;stroke:#',
                        cc.pwcols(7),
                        ';stroke-width:5"><circle cx="500" cy="500" r="380"/><circle cx="500" cy="500" r="440"/><circle cx="500" cy="500" r="500"/><circle cx="500" cy="500" r="560"/><path d="M500,0 l0,1000 M0,500 l1000,0"/></g><circle cx="500" cy="500" r="550" style="fill:none;stroke:#',
                        cc.pwcols(7),
                        ';stroke-width:20;stroke-dasharray:4,20"/><g><circle cx="0" cy="0" r="20" style="fill:none;stroke:#',
                        cc.blc1(1),
                        ';stroke-width:10;opacity:0.5"><animate attributeName="r" dur="1s" values="20;60" repeatCount="indefinite"/></circle><circle cx="0" cy="0" r="10" style="fill:#',
                        cc.blc1(1),
                        '"><animate attributeName="opacity" dur="0.4s" values="0;1;0" repeatCount="indefinite"/></circle><animateMotion dur="60s" repeatCount="indefinite" path="M150,100 q130,150 350,100 q30,-50 200,-150 q150,0 130,180 q-50,80 -380,-140 q-150,-80 -300,10"></animateMotion></g>'
                    )
                )
            );
        }
        // Staturn
        else if (idx == 5) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(6),
                        '"/><defs><mask id="b5m"><circle cx="0" cy="0" r="250" fill="#fff"/><path d="M-86.6,50 a99,99 0,0,1 173,-100 z" fill="black"/></mask><g id="b5s" transform="scale(1,1)"><circle cx="0" cy="0" r="100" fill="#',
                        cc.prcols(0),
                        '"></circle><mask id="b5c"><circle cx="0" cy="0" r="100" fill="#fff"/></mask><g mask="url(#b5c)" style="fill:none;stroke:#',
                        cc.prcols(2),
                        ';stroke-width:20"><path d="M-120,30 a250,100 -30,0,0 250,-120"/><path d="M-120,-20 a250,100 -30,0,0 250,-120"/></g><g mask="url(#b5c)" style="fill:none;stroke:#',
                        cc.prcols(3),
                        ';stroke-width:20"><path d="M-120,120 a250,100 -30,0,0 250,-120"/></g><g mask="url(#b5m)"><circle cx="0" cy="0" r="70" style="fill:none;stroke:#',
                        cc.prcols(1),
                        ';stroke-width:20" transform="skewX(-60)"/><circle cx="0" cy="0" r="90" style="fill:none;stroke:#',
                        cc.prcols(1),
                        ';stroke-width:10" transform="skewX(-60)"/></g><circle cx="300" cy="500" r="30" fill="#',
                        cc.prcols(3),
                        '"/><circle cx="-100" cy="750" r="25" fill="#',
                        cc.prcols(2),
                        '"/><circle cx="-700" cy="450" r="20" fill="#',
                        cc.prcols(3),
                        '"/><circle cx="-600" cy="50" r="28" fill="#',
                        cc.prcols(1),
                        '"/></g></defs><use href="#b5s"><animateMotion dur="60s" repeatCount="indefinite" path="M150,200 C200,150 650,20 800,200 C800,300 100,300 150,200 z"/></use>'
                    )
                )
            );
        }
        // Meteor shower
        else if (idx == 6) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(3),
                        '"/><defs><linearGradient id="b6g"><stop offset="0%" stop-color="#',
                        cc.bgcols(5),
                        '"/><stop offset="95%" stop-color="#',
                        cc.bgcols(3),
                        '" /></linearGradient></defs>',
                        bst,
                        '<defs><path id="b6s" d="M0,0 a8,8 0,1,0 0,8 l400,-2 v-4 l-400,-2 z" fill="url(#b6g)" transform="rotate(-30)"/></defs><use href="#b6s"><animateMotion dur="3s" repeatCount="indefinite" path="M500,-50 l-900,519"></animateMotion></use><use href="#b6s"><animateMotion dur="3.2s" repeatCount="indefinite" path="M800,-50 l-1200,692"></animateMotion></use><use href="#b6s"><animateMotion dur="3.4s" repeatCount="indefinite" path="M1050,100 l-1400,808"></animateMotion></use><use href="#b6s"><animateMotion dur="3.15s" repeatCount="indefinite" path="M1050,600 l-1400,808"></animateMotion></use><use href="#b6s"><animateMotion dur="2.8s" repeatCount="indefinite" path="M1050,400 l-1400,808"></animateMotion></use>'
                    )
                )
            );
        }
        // DNA
        else if (idx == 7) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(4),
                        '"/><defs><pattern id="b7g" viewBox="0,0,200,400" width="20%" height="20%"><path d="M0,20 h100 M16,60 h70 M16,140 h70 M0,180 h100 M0,220 h100 M16,260 h70 M16,340 h70 M0,380 h100" style="fill:none;stroke:grey;stroke-width:5"/><path d="M0,0 c0,100 100,100 100,200" style="fill:none;stroke:#',
                        cc.blc0(0),
                        ';stroke-width:10"/><path d="M100,0 c0,100 -100,100 -100,200 c0,100 100,100 100,200" style="fill:none;stroke:#',
                        cc.blc0(2),
                        ';stroke-width:10"/><path d="M100,200 c0,100 -100,100 -100,200" style="fill:none;stroke:#',
                        cc.blc0(0),
                        ';stroke-width:10"/></pattern></defs><g><rect width="1400" height="1400" fill="url(#b7g)"/><animateTransform attributeName="transform" attributeType="XML" type="translate" from="0,0" to="0,-280" dur="5s" repeatCount="indefinite"/></g>'
                    )
                )
            );
        }
        // ECG
        else if (idx == 8) {
            return (
                string(
                    abi.encodePacked(
                        '<rect height="1000" width="1000" fill="#',
                        cc.bgcols(4),
                        '"/><defs><pattern id="b8p" viewBox="0,0,40,80" width="10%" height="25%"><path d="M0,60 l2,0 3,-10 3,15 q5,-10 6,20 l2,-60 2,45 2-5 q10,0 10,2 l2,-7 12,0" style="fill:none;stroke:#',
                        cc.blc1(1),
                        ';stroke-width:2"/></pattern><pattern id="b8a" viewBox="0,0,50,50" width="4%" height="4%"><path d="M50,0 l0,50 -50,0" style="fill:none;stroke:#',
                        cc.blc0(1),
                        ';stroke-width:2"/></pattern><pattern id="b8b" viewBox="0,0,50,50" width="8%" height="8%"><path d="M50,0 l0,50 -50,0" style="fill:none;stroke:#',
                        cc.blc0(1),
                        ';stroke-width:2"/></pattern></defs><rect width="1000" height="1000" style="fill:url(#b8a)"/><rect width="1000" height="1000" style="fill:url(#b8b)"/><rect y="-30" width="1200" height="1000" style="fill:url(#b8p)"><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;-120,0" dur="3s" repeatCount="indefinite"/></rect>'
                    )
                )
            );
        } else return "";
    }
}

// File contracts/CpigSVG.sol

pragma solidity ^0.8.4;
struct Cpig {
    uint8 bg;
    uint8 bg_s;
    uint8 eyes;
    uint8 eyes_s;
    uint8 glasses;
    uint8 hat;
    uint8 hat_s;
    uint8 neck;
    uint8 neck_s;
    uint8 earring;
}

contract CpigSVG {
    address addrParts;
    address addrParts2;
    address addrBG;

    constructor(
        address _addrParts,
        address _addrParts2,
        address _addrBG
    ) {
        addrParts = _addrParts;
        addrParts2 = _addrParts2;
        addrBG = _addrBG;
    }

    uint8[] private bg_ = [114, 74, 63, 55, 54, 38, 27, 11, 11];
    string[] private bg_t = [
        "Balloons",
        "Clouds",
        "Starry Sky",
        "Star Trails",
        "Radar",
        "Saturn",
        "Meteor Shower",
        "DNA",
        "ECG"
    ];
    uint8[] private es_ = [112, 73, 69, 58, 54, 51, 39, 22, 5];
    string[] private es_t = [
        "Galaxy",
        "Blink",
        "Rolling",
        "Cute",
        "Red Heart",
        "Star",
        "Wink",
        "Cyborg",
        "Laser"
    ];
    uint8[] private gl_ = [194, 175, 142, 128, 107, 65];
    string[] private gl_t = ["None", "Circle", "3D", "Polygon", "Smart", "LED"];
    uint8[] private hs_ = [136, 84, 68, 64, 61, 60, 41, 37, 36, 17, 9];
    string[] private hs_t = [
        "Pinwheel",
        "Party Hat",
        "Black Standing Hair",
        "Black Side Parting",
        "Antenna",
        "Green Lollipop",
        "Blue Lollipop",
        "Gold Standing Hair",
        "Gold Side Parting",
        "Red Lollipop",
        "Crown"
    ];
    uint8[] private bt_ = [253, 232, 201, 170, 36];
    string[] private bt_t = ["Bowtie", "Bowknot", "Tie", "Scarf", "Bat"];
    uint8[] private er_ = [145, 118, 101, 83, 58, 33, 7];
    string[] private er_t = [
        "None",
        "Silver",
        "Gold",
        "Diamond",
        "Spiral",
        "Neon",
        "Alien"
    ];
    uint8[] si_ = [6, 8, 8, 4, 8, 8, 8, 8, 3];
    string private ts0 = '{"trait_type": "Background","value": "';
    string private ts1 = '"},{"trait_type": "Eyes","value": "';
    string private ts2 = '"},{"trait_type": "Glasses","value": "';
    string private ts3 = '"},{"trait_type": "Hat","value": "';
    string private ts4 = '"},{"trait_type": "Neck","value": "';
    string private ts5 = '"},{"trait_type": "Earring","value": "';
    string private r0 = "C";
    string private r1 = "U";
    string private r2 = "B";
    string private r3 = "E";
    string private r4 = "P";
    string private r5 = "G";
    string private ns =
        '<path d="M80,360 l160,-150 a25,30 -20,0,1 -120,200 z M920,360 l-160,-150 a25,30 20,0,0 120,200 z" style="fill:#feb3af;stroke:#343238;stroke-width:10"/><path d="M380,730 q0,-120 120,-120 q120,0 120,120 a70,30 0,0,1 -240,0 z" style="fill:#feb3af;stroke:#343238;stroke-width:10" /><ellipse cx="455" cy="700" rx="20" ry="36" fill="#343238"/><ellipse cx="545" cy="700" rx="20" ry="36" fill="#343238"/>';
    string private ns1 =
        '<defs><g id="n1r"><circle cx="0" cy="0" r="25" fill="#ec6a5f"/><path d="M0,0 l0,600" style="stroke:#ec6a5f;stroke-width:30;opacity:0.8"/><circle cx="0" cy="0" r="10" fill="#fef9ee"/><path d="M0,0 l0,600" style="stroke:#fef9ee;stroke-width:12;opacity:0.8"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" values="30,0,0;-30,0,0;30,0,0" dur="10s" repeatCount="indefinite"/></g></defs><g id="n1l"><ellipse cx="320" cy="500" rx="70" ry="80" fill="#343238"/><g><use href="#n1r" x="300" y="510"/><animateTransform attributeName="transform" attributeType="XML" type="translate" values="0,0;40,0;0,0" dur="10s" repeatCount="indefinite"/></g></g><use href="#n1l" x="360"/>';

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) public pure returns (string memory) {
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

    function getIdx(uint8[] memory a, uint256 i) internal pure returns (uint8) {
        uint8 idx = 0;
        uint256 j = a[0];
        while (j < i) {
            idx += 1;
            j += uint256(a[idx]);
        }
        return idx;
    }

    function randomT(uint256 tokenId) external view returns (Cpig memory) {
        Cpig memory cpig;
        tokenId = 10252 - tokenId;
        uint256 r = uint256(
            (random(string(abi.encodePacked(r0, toString(tokenId))))) % 447
        );
        cpig.bg = getIdx(bg_, r);
        if (cpig.bg == 0) {
            cpig.bg_s = uint8(r % si_[0]);
        }

        r = uint256(
            (random(string(abi.encodePacked(r1, toString(tokenId))))) % 483
        );
        cpig.eyes = getIdx(es_, r);
        if (cpig.eyes == 0) {
            cpig.eyes_s = uint8(r % si_[1]);
        }

        cpig.glasses = getIdx(
            gl_,
            uint256(
                (random(string(abi.encodePacked(r2, toString(tokenId))))) % 811
            )
        );

        r = uint256(
            (random(string(abi.encodePacked(r3, toString(tokenId))))) % 613
        );
        cpig.hat = getIdx(hs_, r);
        if (cpig.hat == 0) {
            cpig.hat_s = uint8(r % si_[2]);
        }
        if (cpig.hat == 1) {
            cpig.hat_s = uint8(r % si_[3]);
        }

        r = uint256(
            (random(string(abi.encodePacked(r4, toString(tokenId))))) % 892
        );
        if (cpig.eyes == 8) {
            cpig.glasses = 0;
            cpig.neck = 4;
        } else cpig.neck = getIdx(bt_, r);
        cpig.neck_s = uint8(r % si_[cpig.neck + 4]);

        cpig.earring = getIdx(
            er_,
            uint256(
                (random(string(abi.encodePacked(r5, toString(tokenId))))) % 545
            )
        );
        if (tokenId == 7260 || tokenId == 9067) {
            cpig.earring += 2;
        }

        return cpig;
    }

    function getTraits(Cpig memory cpig) external view returns (string memory) {
        string[6] memory ts;
        ts[0] = string(abi.encodePacked(ts0, bg_t[cpig.bg]));
        ts[1] = string(abi.encodePacked(ts1, es_t[cpig.eyes]));
        ts[2] = string(abi.encodePacked(ts2, gl_t[cpig.glasses]));
        ts[3] = string(abi.encodePacked(ts3, hs_t[cpig.hat]));
        ts[4] = string(
            abi.encodePacked(
                ts4,
                bt_t[cpig.neck],
                " ",
                toString(cpig.neck_s + 1)
            )
        );
        ts[5] = string(abi.encodePacked(ts5, er_t[cpig.earring]));
        if (cpig.bg == 0) {
            ts[0] = string(
                abi.encodePacked(ts[0], " ", toString(cpig.bg_s + 1))
            );
        }
        if (cpig.eyes == 0) {
            ts[1] = string(
                abi.encodePacked(ts[1], " ", toString(cpig.eyes_s + 1))
            );
        }
        if (cpig.glasses == 0) {
            ts[2] = "";
        }
        if (cpig.hat <= 1) {
            ts[3] = string(
                abi.encodePacked(ts[3], " ", toString(cpig.hat_s + 1))
            );
        }
        if (cpig.earring == 0) {
            ts[5] = "";
        }
        return (
            string(abi.encodePacked(ts[0], ts[1], ts[2], ts[3], ts[4], ts[5]))
        );
    }

    function genSVG(uint256 tokenId, Cpig memory cpig)
        external
        view
        returns (string memory)
    {
        CpigParts cp = CpigParts(addrParts);
        CpigParts2 cp2 = CpigParts2(addrParts2);
        CpigBG cbg = CpigBG(addrBG);

        string
            memory ss = '<svg width="1000px" height="1000px" viewBox="0 0 1000 1000" version="1.1" xmlns="http://www.w3.org/2000/svg">';
        ss = string(
            abi.encodePacked(
                ss,
                cbg.genBG(cpig.bg, cpig.bg_s),
                '<rect x="150" y="260" rx="200" ry="200" width="700" height="600" style="fill:#feb3af;stroke:#343238;stroke-width:10"/>'
            )
        );
        ss = string(
            abi.encodePacked(
                ss,
                cp.genEyes(toString(tokenId), cpig.eyes, cpig.eyes_s)
            )
        );
        ss = string(abi.encodePacked(ss, cp2.genGls(cpig.glasses)));
        ss = string(
            abi.encodePacked(
                ss,
                cp.genHat(toString(tokenId), cpig.hat, cpig.hat_s)
            )
        );
        ss = string(abi.encodePacked(ss, cp2.genNeck(cpig.neck, cpig.neck_s)));
        ss = string(abi.encodePacked(ss, ns));
        ss = string(abi.encodePacked(ss, toString(tokenId)));
        if (cpig.eyes == 8) {
            ss = string(abi.encodePacked(ss, ns1));
        }
        ss = string(abi.encodePacked(ss, cp2.genErs(cpig.earring)));
        ss = string(abi.encodePacked(ss, "</svg>"));

        return ss;
    }
}

// File contracts/CubePigs.sol

pragma solidity ^0.8.4;

contract CubePigs is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supplyCounter;

    bool public enableMint = false;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_MINT = 5;
    uint256 public numLimit = 5000;
    uint256 private constant PRICE = 0.05 ether;
    mapping(address => uint256) private freeMintedWallets;

    address public immutable addrSVG;

    constructor(address _addrSVG) ERC721("CubePigs", "CPIG") Ownable() {
        addrSVG = _addrSVG;
    }

    function freeMint() external {
        require(enableMint, "not yet launched");
        require(totalSupply() < numLimit, "stop minting");
        require(totalSupply() < 1000, "exceeds max free mint");
        require(freeMintedWallets[msg.sender] < 1, "1 free mint per wallet");
        _safeMint(msg.sender, totalSupply());
        supplyCounter.increment();
        freeMintedWallets[msg.sender] = 1;
    }

    function mint(uint256 mintNum) external payable {
        require(enableMint, "not yet launched");
        require(totalSupply() < numLimit, "stop minting");
        require(MAX_MINT >= mintNum, "max 5 mints at a time");
        require(msg.value >= PRICE * mintNum, "invalid payment amount");
        require(
            MAX_SUPPLY > totalSupply() + mintNum - 1,
            "not enough mints remaining"
        );

        for (uint256 i = 0; i < mintNum; i++) {
            _safeMint(msg.sender, totalSupply());
            supplyCounter.increment();
        }
    }

    function ownerMint(address to, uint256 mintNum) external onlyOwner {
        require(enableMint, "not yet launched");
        require(totalSupply() < numLimit, "stop minting");
        require(
            MAX_SUPPLY > totalSupply() + mintNum - 1,
            "not enough mints remaining"
        );

        for (uint256 i = 0; i < mintNum; i++) {
            _safeMint(to, totalSupply());
            supplyCounter.increment();
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        CpigSVG cpigSvg = CpigSVG(addrSVG);

        Cpig memory cpig = cpigSvg.randomT(tokenId);
        string memory o = string(
            abi.encodePacked(cpigSvg.genSVG(tokenId, cpig))
        );
        string memory traits = string(
            abi.encodePacked(cpigSvg.getTraits(cpig))
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "CubePigs #',
                        cpigSvg.toString(tokenId),
                        '", "description": "A CubePig is taking interstellar journey. This NFT is also a membership card. Learn more at cubepigs.com","attributes": [',
                        traits,
                        '"}],"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(o)),
                        '"}'
                    )
                )
            )
        );

        string memory f = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return f;
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    function setMintActive(bool _enableMint) external onlyOwner {
        enableMint = _enableMint;
    }

    function setNumLimit(uint256 _numLimit) external onlyOwner {
        numLimit = _numLimit;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}