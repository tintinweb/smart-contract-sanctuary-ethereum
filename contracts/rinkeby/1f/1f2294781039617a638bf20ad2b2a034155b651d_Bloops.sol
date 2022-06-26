/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// File contracts/Bloops.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

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

contract Bloops is ERC721 {
    string private js =
        "function makeMusic(root,il,vl,cl,bl,ol,rhpi,bpmii,bpmei,sc,seed){const seeds=[];for(let i=0;i<seed.length;i+=4){const slice=window.parseInt(seed.slice(i,i+4));seeds.push(slice)}const ROOT_NOTE_INDEX=root;const INTRO_LENGTH_OPTIONS=[0,2,4,6];const VERSE_LENGTH_OPTIONS=[2,4,8,10];const CHORUS_LENGTH_OPTIONS=[4,6,8,10];const BRIDGE_LENGTH_OPTIONS=[0,1,2,3];const OUTRO_LENGTH_OPTIONS=[0,2,4,6];const RANDOM_RHYTHM_PATTERN=rhpi;const RANDOM_RHYTHM_EFFECT=seeds[3]%4;const RANDOM_RHYTHM_SOUND=seeds[4]%4;const RANDOM_BASS_SOUND=seeds[5]%4;const RANDOM_LEAD_SOUND=seeds[6]%4;const RANDOM_BPM=bpmii;const RANDOM_BEATS_PER_MEASURE=bpmei;const canvas=document.querySelector('canvas');canvas.setAttribute('width','508px');canvas.setAttribute('height','508px');const canvasCtx=canvas.getContext('2d');function xmur3(str){for(var i=0,h=1779033703^str.length;i<str.length;i+=1){h=Math.imul(h^str.charCodeAt(i),3432918353);h=h<<13|h>>>19}return function(){h=Math.imul(h^(h>>>16),2246822507);h=Math.imul(h^(h>>>13),3266489909);return(h^=h>>>16)>>>0}}function mulberry32(a){return function(){var t=a+=0x6D2B79F5;t=Math.imul(t^t>>>15,t|1);t^=t+Math.imul(t^t>>>7,t|61);return((t^t>>>14)>>>0)/4294967296}}const seed4=xmur3(seed[0]+'outrobass');const rand=mulberry32(seed4());function generateSeed(section,instrument){let str='';const seedsForSection=[];const rand=mulberry32(seed4());for(let i=0;i<seed.length;i+=1){const seed4=xmur3(seed[i]+section+instrument);const rand=mulberry32(seed4());str+=Math.round(rand()*100000)}let temp='';for(let j=1;j<str.length;j+=1){if(j%4===0){seedsForSection.push(temp);temp='';continue}temp+=str[j]}return seedsForSection}const notes=[{name:'C4',frequency:261.63},{name:'C#4',frequency:277.18},{name:'D4',frequency:293.66},{name:'D#4',frequency:311.13},{name:'E4',frequency:329.63},{name:'F4',frequency:349.23},{name:'F#4',frequency:369.99},{name:'G4',frequency:392.0},{name:'G#4',frequency:415.3},{name:'A4',frequency:440.0},{name:'A#4',frequency:466.16},{name:'B4',frequency:493.88},];const noteTypeMap={'whole':4,'half':2,'quarter':1,'eighth':0.5,'sixteenth':0.25,};const synthSounds=['sine','square','sawtooth','triangle'];const tempos=[];for(let i=50;i<=160;i+=5){tempos.push(i)}tempos.push(69);console.log(tempos);const tempo=60/tempos[RANDOM_BPM];console.log(tempos[RANDOM_BPM]);const beatsPerMeasureArr=[2,3,4,5];let beatsPerMeasure=beatsPerMeasureArr[RANDOM_BEATS_PER_MEASURE];console.log(beatsPerMeasure);const majorScale=[0,2,4,5,7,9,11];const minorScale=[0,2,3,5,7,8,10];const pentaMajor=[0,2,4,7,9];const pentaMinor=[0,3,5,7,10];const randomScales=[{name:'major',notesPosition:majorScale},{name:'minor',notesPosition:minorScale},{name:'majorSeventh',notesPosition:majorScale},{name:'minorSeventh',notesPosition:minorScale},{name:'pentaMajor',notesPosition:pentaMajor},{name:'pentaMinor',notesPosition:pentaMinor}];const chordsInScaleMap={'major':['major','minor','minor','major','major','minor','diminished'],'minor':['minor','diminished','major','minor','minor','major','major'],'majorSeventh':['majorSeventh','minorSeventh','minorSeventh','majorSeventh','dominantSeventh','minorSeventh','minorSeventhFlat5'],'minorSeventh':['minorSeventh','minorSeventhFlat5','majorSeventh','minorSeventh','minorSeventh','majorSeventh','dominantSeventh'],'pentaMajor':['major','minor','minor','major','minor'],'pentaMinor':['minor','major','minor','minor','major']};const chordNotesMap={'major':[0,4,7],'minor':[0,3,7],'diminished':[0,3,6],'majorSeventh':[0,4,7,11],'minorSeventh':[0,3,7,10],'dominantSeventh':[0,4,7,10],'minorSeventhFlat5':[0,3,7,9]};const progressionsToChordsMap={'I-VI-VI-IV':[0,4,5,3],'III-VI-II-V':[2,5,1,4]};const rhythmPatterns=[[{type:'whole',dotted:false}],[{type:'half',dotted:false}],[{type:'quarter',dotted:false}],[{type:'eighth',dotted:false}],[{type:'half',dotted:false},{type:'quarter',dotted:false},{type:'quarter',dotted:false}]];const effects=['delay','distortion','reverb','none'];const seedsToIndexMap={scale:sc};const organizedNotes=[...notes.slice(ROOT_NOTE_INDEX,notes.length),...notes.slice(0,ROOT_NOTE_INDEX)];console.log(organizedNotes[0]);const randomScale=randomScales[seedsToIndexMap.scale];randomScale.scale=randomScale.notesPosition.map((pos)=>{return organizedNotes[pos]});randomScale.key=randomScale.scale[0].name;console.log(randomScale);const chordsInScale=chordsInScaleMap[randomScale.name];function organizeNotes(fromIndex){return[...notes.slice(fromIndex,notes.length),...notes.slice(0,fromIndex)]}function buildChord(){const organizedNotes=[...notes.slice(ROOT_NOTE_INDEX,notes.length),...notes.slice(0,ROOT_NOTE_INDEX)]}function getRandomIndex(arr){return Math.floor(Math.random()*arr.length)}function pushBeatsToSection(section,instrument){let totalIntroLeadBeats=0;const beats=[];let seedIter=0;let backupIter=0;let seedsForNotes=generateSeed(section,instrument+'notes');let seedsForType=generateSeed(section,instrument+'type');let seedsForDotted=generateSeed(section,instrument+'dotted');while(totalIntroLeadBeats<beatsPerMeasure){if(seedIter>=Math.min(seedsForNotes.length,seedsForType.length,seedsForDotted.length)){seedsForNotes=generateSeed(section,instrument+'notes'+seedsForDotted[seedIter-1]);seedsForType=generateSeed(section,instrument+'type'+seedsForNotes[seedIter-1]);seedsForDotted=generateSeed(section,instrument+'dotted'+seedsForType[seedIter-1]);seedIter=0}const note=randomScale.scale[seedsForNotes[seedIter]%randomScale.scale.length];const type=Object.keys(noteTypeMap)[seedsForType[seedIter]%Object.keys(noteTypeMap).length];seedIter++;let beatTime;const beat={name:note.name,frequency:note.frequency,type:type,dotted:[true,false][seedsForDotted[seedIter]%2]};if(beat.type==='whole'||beat.type==='sixteenth'){beat.dotted=false}if(beat.dotted){beatTime=noteTypeMap[beat.type]+(noteTypeMap[beat.type]/2)}else{beatTime=noteTypeMap[beat.type]}if(totalIntroLeadBeats+beatTime>beatsPerMeasure){seedsForNotes=generateSeed(section+seedIter++ +backupIter++,instrument+'notez'+seedIter++ +seedsForType[seedIter]);seedsForType=generateSeed(section+seedIter++ +backupIter++,instrument+'typez'+seedIter++ +seedsForNotes[seedIter]);seedsForDotted=generateSeed(section+seedIter++ +backupIter++,instrument+'dotz'+seedIter++ +seedsForDotted[seedIter]);continue}totalIntroLeadBeats+=beatTime;beats.push(beat)}return beats}function buildRhythmSection(length,section){const introRhythmBeats=[];let temp=[];let introRhythmBar=0;const scaleName=randomScale.name;const rhythmPattern=rhythmPatterns[RANDOM_RHYTHM_PATTERN];let rhythmPatternCounter=0;let overrideBeat=false;let seedIter=0;let backupIter=0;let seedsForNotes=generateSeed(section,'rhythmnotes');let seedsForType=generateSeed(section,'rhythmtype');let seedsForDotted=generateSeed(section,'rhythmdotted');while(introRhythmBar<length){let totalIntroRhythmBeats=0;const noteInScaleIndex=seedsForNotes[seedIter]%randomScale.scale.length;const rootNote=randomScale.scale[noteInScaleIndex];const index=notes.map((note)=>note.name).indexOf(rootNote.name);const organizedByIndex=organizeNotes(index);const chordType=chordsInScaleMap[randomScale.name][noteInScaleIndex];const notesArr=chordNotesMap[chordType].map((pos)=>organizedByIndex[pos]);while(totalIntroRhythmBeats<beatsPerMeasure){let beatTime;if(seedIter>=Math.min(seedsForNotes.length,seedsForType.length,seedsForDotted.length)){seedsForNotes=generateSeed(section,'rhythmtype'+seedsForDotted[seedIter]);seedsForType=generateSeed(section,'rhythmnotes'+seedsForNotes[seedIter]);seedsForDotted=generateSeed(section,'rhythmdotnotes'+seedsForType[seedIter]);}const type=Object.keys(noteTypeMap)[seedsForType[seedIter]%Object.keys(noteTypeMap).length];seedIter++;const beat={notes:notesArr,type:overrideBeat?type:rhythmPattern[rhythmPatternCounter].type,dotted:overrideBeat?[true,false][seedsForDotted[seedIter]%2]:rhythmPattern[rhythmPatternCounter].dotted};if(beat.type==='whole'||beat.type==='sixteenth'){beat.dotted=false}if(beat.dotted){beatTime=noteTypeMap[beat.type]+(noteTypeMap[beat.type]/2)}else{beatTime=noteTypeMap[beat.type]}if(totalIntroRhythmBeats+beatTime>beatsPerMeasure){overrideBeat=true;seedsForNotes=generateSeed(section+seedIter+backupIter++,'rhythm,notez1'+seedsForType[seedIter]);seedsForType=generateSeed(section+seedIter+backupIter++,'rhythm,typez1'+seedsForNotes[seedIter]);seedsForDotted=generateSeed(section+seedIter+backupIter++,'rhythm,dotz1'+seedsForDotted[seedIter]);seedIter=0;continue}totalIntroRhythmBeats+=beatTime;temp.push(beat);rhythmPatternCounter+=1;if(rhythmPatternCounter>=rhythmPattern.length){rhythmPatternCounter=0;overrideBeat=false}}introRhythmBeats.push(temp);temp=[];introRhythmBar+=1}return introRhythmBeats}const audioContext=new(window.AudioContext||window.webkitAudioContext);const masterVol=audioContext.createGain();const analyser=audioContext.createAnalyser();const mixer={lead:audioContext.createGain(),rhythm:audioContext.createGain(),bass:audioContext.createGain()};const compressor=audioContext.createDynamicsCompressor();compressor.threshold.value=-35;compressor.knee.value=40;compressor.ratio.value=8;compressor.attack.value=0;compressor.release.value=0.25;var distortion=audioContext.createWaveShaper();function makeDistortionCurve(amount){var k=typeof amount==='number'?amount:50,n_samples=44100,curve=new Float32Array(n_samples),deg=Math.PI/180,i=0,x;for(;i<n_samples;i+=1){x=i*2/n_samples-1;curve[i]=(3+k)*x*20*deg/(Math.PI+k*Math.abs(x))}return curve};distortion.curve=makeDistortionCurve(400);distortion.oversample='4x';mixer.lead.connect(masterVol);mixer.rhythm.connect(masterVol);mixer.bass.connect(masterVol);mixer.rhythm.gain.value=0.75;masterVol.connect(compressor).connect(analyser).connect(audioContext.destination);analyser.fftSize=2048;var bufferLength=analyser.frequencyBinCount;var dataArray=new Uint8Array(bufferLength);analyser.getByteTimeDomainData(dataArray);"
        "canvasCtx.clearRect(0,0,508,508);let red=seeds[8]%255;let blue=seeds[3]%255;let green=seeds[0]%255;canvasCtx.fillStyle=`rgb(${ green }, ${ red }, ${ blue })`;canvasCtx.fillRect(0,0,508,508);canvasCtx.lineWidth=5;canvasCtx.strokeStyle=`rgb(${ red },${ blue },${ green })`;canvasCtx.moveTo(0,508/2);canvasCtx.lineTo(canvas.width,canvas.height/2);canvasCtx.stroke();function draw(){var drawVisual=requestAnimationFrame(draw);analyser.getByteTimeDomainData(dataArray);canvasCtx.fillStyle=`rgb(${ green }, ${ red }, ${ blue })`;canvasCtx.fillRect(0,0,508,508);canvasCtx.lineWidth=5;canvasCtx.strokeStyle=`rgb(${ red },${ blue },${ green })`;canvasCtx.beginPath();var sliceWidth=508*1.0/bufferLength;var x=0;for(var i=0;i<bufferLength;i+=1){var v=dataArray[i]/128.0;var y=v*508/2;if(i===0){canvasCtx.moveTo(x,y)}else{canvasCtx.lineTo(x,y)}x+=sliceWidth}canvasCtx.lineTo(canvas.width,canvas.height/2);canvasCtx.stroke()}const songStructure=[];const leadNotes=[];const bassNotes=[];const rhythmNotes=[];const introLength=INTRO_LENGTH_OPTIONS[il];const introLeadBeats=pushBeatsToSection('leadintr0','lead');const introBassBeats=pushBeatsToSection('bass1ntro','bass');const introRhythmBeats=buildRhythmSection(introLength,'intro');for(let i=0;i<introLength;i+=1){leadNotes.push(pushBeatsToSection(`leadintr0${ i }`,`${ i }lead`));bassNotes.push(pushBeatsToSection(`bass1ntro${ i }`,`${ i }bass`))}introRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});const verseLength=VERSE_LENGTH_OPTIONS[vl];const verseLeadBeats=pushBeatsToSection('verse','lead');const verseBassBeats=pushBeatsToSection('verse','bass');const verseRhythmBeats=buildRhythmSection(verseLength,'verse');const verseLeadSection=[];const verseBassSection=[];for(let i=0;i<verseLength;i+=1){const leadBar=pushBeatsToSection(`verse${ i }`,`${ i }lead`);const bassBar=pushBeatsToSection(`verse${ i }`,`${ i }bass`);verseLeadSection.push(leadBar);verseBassSection.push(bassBar);leadNotes.push(leadBar);bassNotes.push(bassBar)}verseRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});const chorusLength=CHORUS_LENGTH_OPTIONS[cl];const chorusLeadBeats=pushBeatsToSection('chorus','lead');const chorusBassBeats=pushBeatsToSection('chorus','bass');const chorusRhythmBeats=buildRhythmSection(chorusLength,'chorus');const chorusLeadSection=[];const chorusBassSection=[];for(let i=0;i<chorusLength;i+=1){const leadBar=pushBeatsToSection(`verse${ i }`,`${ i }lead`);const bassBar=pushBeatsToSection(`verse${ i }`,`${ i }bass`);chorusLeadSection.push(leadBar);chorusBassSection.push(bassBar);leadNotes.push(leadBar);bassNotes.push(bassBar)}chorusRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});for(let i=0;i<verseLeadSection.length;i+=1){leadNotes.push(verseLeadSection[i]);bassNotes.push(verseBassSection[i])}verseRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});for(let i=0;i<chorusLeadSection.length;i+=1){leadNotes.push(chorusLeadSection[i]);bassNotes.push(chorusBassSection[i])}chorusRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});const bridgeLength=BRIDGE_LENGTH_OPTIONS[bl];const bridgeLeadBeats=pushBeatsToSection('bridge','lead');const bridgeBassBeats=pushBeatsToSection('bridge','bass');const bridgeRhythmBeats=buildRhythmSection(bridgeLength,'bridge');for(let i=0;i<bridgeLength;i+=1){leadNotes.push(pushBeatsToSection(`bridge${ i }`,`${ i }lead`));bassNotes.push(pushBeatsToSection(`bridge${ i }`,`${ i }bass`))}bridgeRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});for(let i=0;i<chorusLeadSection.length;i+=1){leadNotes.push(chorusLeadSection[i]);bassNotes.push(chorusBassSection[i])}chorusRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});const outroLength=OUTRO_LENGTH_OPTIONS[ol];const outroLeadBeats=pushBeatsToSection('outro','lead');const outroBassBeats=pushBeatsToSection('outro','bass');const outroRhythmBeats=buildRhythmSection(outroLength,'outro');for(let i=0;i<outroLength;i+=1){leadNotes.push(pushBeatsToSection(`outro${ i }`,`${ i }lead`));bassNotes.push(pushBeatsToSection(`outro${ i }`,`${ i }bass`))}outroRhythmBeats.forEach((beat)=>{rhythmNotes.push(beat)});console.log(rhythmNotes);function delay(){const delay=audioContext.createDelay();const feedback=audioContext.createGain();delay.delayTime.value=60000/tempo/1000;feedback.gain.value=0.25;delay.connect(feedback);feedback.connect(delay);return delay}function chorus(){const delay=audioContext.createDelay();const feedback=audioContext.createGain();const pitchOsc=audioContext.createOscillator();delay.delayTime.value=.001;delay.connect(feedback);return delay}function reverb(reverbTime=1){const reverb=audioContext.createConvolver();const wet=audioContext.createGain();reverb.connect(wet);return reverb}function playSound(instrument,effect,freq,time,dur){const inst=instrument;if(effect){inst.output.connect(effect);effect.connect(mixer[inst.type])}inst.output.connect(mixer[inst.type]);inst.oscillators.forEach((osc)=>{osc.start(time);osc.stop(time+dur)})}function instrument(type,freq,time,dur){const output=audioContext.createGain();const osc=audioContext.createOscillator();const gainNode=audioContext.createGain();const vol=audioContext.createGain();const oscillators=[];let attackTime=0.50;let releaseTime=0.20;if(type==='bass'){osc.type=synthSounds[RANDOM_BASS_SOUND]}if(type==='rhythm'){osc.type=synthSounds[RANDOM_RHYTHM_SOUND];}if(type==='lead'){osc.type=synthSounds[RANDOM_LEAD_SOUND];}osc.frequency.value=freq;gainNode.connect(osc.frequency);gainNode.gain.value=100;osc.connect(vol);vol.gain.exponentialRampToValueAtTime(0.0001,time+dur);vol.gain.setValueAtTime(vol.gain.value,time);vol.connect(output);oscillators.push(osc);return{type,output,oscillators}}function playSynthSound(freq,time,dur){const osc=audioContext.createOscillator();const osc2=audioContext.createOscillator();const osc3=audioContext.createOscillator();const gainNode=audioContext.createGain();const vol=audioContext.createGain();osc2.frequency.value=freq;osc.type='sine';osc.frequency.value=100;osc.connect(gainNode);osc3.type='square';osc3.frequency.value=freq;osc3.connect(vol);gainNode.connect(osc2.frequency);gainNode.gain.value=100;osc2.connect(vol);vol.connect(masterVol);vol.gain.setValueAtTime(vol.gain.value,time);vol.gain.exponentialRampToValueAtTime(0.0001,time+dur);osc2.start(time);osc2.stop(time+dur);}function playTestSynth(type,freq,now,duration){const output=audioContext.createGain();const vol=audioContext.createGain();const osc=audioContext.createOscillator();const triangle=audioContext.createOscillator();const osc2gain=audioContext.createGain();const oscillators=[];let attackTime=(seeds[10]%4)/10;let releaseTime=(seeds[11]%3)/10;osc.type='sawtooth';if(type=='lead'){osc.type=synthSounds[seeds[0]%5];osc2gain.gain.value=seeds[5]%6;triangle.frequency.value=seeds[6]%6;attackTime=(seeds[12]%4)/10;releaseTime=(seeds[13]%3)/10}if(type=='bass'){osc.type=synthSounds[seeds[1]%5];osc2gain.gain.value=seeds[6]%6;triangle.frequency.value=seeds[7]%6;attackTime=(seeds[13]%4)/10;releaseTime=(seeds[14]%3)/10}if(type=='rhythm'){osc.type=synthSounds[seeds[2]%5];osc2gain.gain.value=seeds[7]%6;triangle.frequency.value=seeds[8]%6;attackTime=(seeds[14]%4)/10;releaseTime=(seeds[15]%3)/10}osc.frequency.value=freq;triangle.type=synthSounds[seeds[9]%5];osc.connect(vol);triangle.connect(osc2gain);osc2gain.connect(osc.frequency);vol.gain.setValueAtTime(0.01,now);vol.gain.linearRampToValueAtTime(1,now+attackTime);vol.gain.setValueAtTime(1,now+duration-releaseTime);vol.gain.linearRampToValueAtTime(0,now+duration-0.01);vol.connect(output);oscillators.push(osc);return{type,output,oscillators};}function playMusic(){const numberOfBars=rhythmNotes.length;let currentTime=audioContext.currentTime+1;for(let bar=0;bar<numberOfBars;bar+=1){let counter1=0;let counter2=0;let counter3=0;for(let beat=0;beat<leadNotes[bar].length;beat+=1){const note=leadNotes[bar][beat].frequency;const beatTime=noteTypeMap[leadNotes[bar][beat].type];const dottedTime=leadNotes[bar][beat].dotted?beatTime/2:0;const duration=(beatTime+dottedTime)*tempo;const playAtTime=currentTime+((bar*beatsPerMeasure)+counter1)*tempo;counter1+=beatTime+dottedTime;const inst=instrument('lead',note,playAtTime,duration);const inst2=playTestSynth('lead',note*2,playAtTime,duration);playSound(inst,null,note,playAtTime,duration);playSound(inst2,null,note,playAtTime,duration);}for(let beat=0;beat<rhythmNotes[bar].length;beat+=1){let counter4=0;let beatTime=0;let dottedTime=0;for(let chord=0;chord<rhythmNotes[bar][beat].notes.length;chord+=1){const note=rhythmNotes[bar][beat].notes[chord].frequency;beatTime=noteTypeMap[rhythmNotes[bar][beat].type];dottedTime=rhythmNotes[bar][beat].dotted?beatTime/2:0;const duration=(beatTime+dottedTime)*tempo;const playAtTime=currentTime+((bar*beatsPerMeasure)+counter2)*tempo;const del=delay();const effectString=effects[RANDOM_RHYTHM_EFFECT];console.log(effectString);let effect;if(effectString==='delay'){effect=delay()}else if(effectString==='reverb'){effect=reverb()}else if(effectString==='distorion'){effect=distortion}else{effect=null}const inst=instrument('rhythm',note,playAtTime,duration);const inst2=playTestSynth('rhythm',note,playAtTime,duration);playSound(inst2,effect,note,playAtTime,duration);}counter2+=beatTime+dottedTime}for(let beat=0;beat<bassNotes[bar].length;beat+=1){const note=bassNotes[bar][beat].frequency;const beatTime=noteTypeMap[bassNotes[bar][beat].type];const dottedTime=bassNotes[bar][beat].dotted?beatTime/2:0;const duration=(beatTime+dottedTime)*tempo;const playAtTime=currentTime+((bar*beatsPerMeasure)+counter3)*tempo;counter3+=beatTime+dottedTime;const inst=instrument('bass',note/2,playAtTime,duration);const inst2=playTestSynth('bass',note/2,playAtTime,duration);playSound(inst,null,note/2,playAtTime,duration);playSound(inst2,null,note/2,playAtTime,duration);}}}const button=document.querySelector('button');button.addEventListener('click',()=>{playMusic();draw()})};makeMusic(";
    string private html_prefix =
        "<!DOCTYPE html><head><style>button{display:block;outline:none;background:black;border-radius:0px;color:white;padding:10px 40px;box-sizing:border-box;border:none;cursor:pointer;}</style></head><html><body><canvas></canvas><button>Play</button><script>";
    string private html_suffix = "</script></body></html>";
    uint256 private randNonce = 0;
    bool private paused = true;
    uint256 private totalMinted = 0;
    uint256[] introLengths = [0, 2, 4, 6];
    uint256[] verseLengths = [2, 4, 8, 10];
    uint256[] chorusLengths = [4, 6, 8, 10];
    uint256[] bridgeLengths = [0, 1, 2, 3];
    uint256[] outroLengths = [0, 2, 4, 6];
    uint256[] bpms = [
        50,
        55,
        60,
        65,
        70,
        75,
        80,
        85,
        90,
        95,
        100,
        105,
        110,
        115,
        120,
        125,
        130,
        135,
        140,
        145,
        150,
        155,
        160,
        69
    ];
    string[] scales = [
        "Major",
        "Minor",
        "Major Seventh",
        "Minor Seventh",
        "Pentatonic Major",
        "Pentatonic Minor"
    ];
    string[] notes = [
        "C4",
        "C#4",
        "D4",
        "D#4",
        "E4",
        "F4",
        "F#4",
        "G4",
        "G#4",
        "A4",
        "A#4",
        "B4"
    ];
    string[] timeSigs = ["2/4", "3/4", "4/4", "5/4"];
    string[] rhythmPatterns = [
        "Whole",
        "Half",
        "Quarter",
        "Eighth",
        "Half Quarter Quarter"
    ];
    mapping(uint256 => Tune) private tokenIdToTune;

    struct Tune {
        uint256 rootIndex;
        uint256 introLength;
        uint256 verseLength;
        uint256 chorusLength;
        uint256 bridgeLength;
        uint256 outroLength;
        uint256 rhythmPatternIndex;
        uint256 scaleIndex;
        uint256 beatsPerMinuteIndex;
        uint256 beatsPerMeasureIndex;
        string seed;
    }

    constructor() ERC721("Bloops", "BLOOPS") {}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Song #',
                                    Strings.toString(tokenId),
                                    '", ',
                                    '"animation_url": "data:text/html;base64,',
                                    Base64.encode(
                                        bytes(getHTMLDocument(tokenId))
                                    ),
                                    '",'
                                    '"attributes":',
                                    buildAttributesArrayOne(tokenId),
                                    buildAttributesArrayTwo(tokenId),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function buildAttributesArrayOne(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Key", "value": "',
                    notes[tokenIdToTune[tokenId].rootIndex],
                    '"},',
                    '{"trait_type": "BPM", "value": "',
                    Strings.toString(
                        bpms[tokenIdToTune[tokenId].beatsPerMinuteIndex]
                    ),
                    '"},',
                    '{"trait_type": "Scale", "value": "',
                    scales[tokenIdToTune[tokenId].scaleIndex],
                    '"},',
                    '{"trait_type": "Time Signature", "value": "',
                    timeSigs[tokenIdToTune[tokenId].beatsPerMeasureIndex],
                    '"},',
                    '{"trait_type": "Intro Length", "value": "',
                    Strings.toString(
                        introLengths[tokenIdToTune[tokenId].introLength]
                    ),
                    '"},',
                    '{"trait_type": "Verse Length", "value": "',
                    Strings.toString(
                        verseLengths[tokenIdToTune[tokenId].verseLength]
                    ),
                    '"},'
                )
            );
    }

    function buildAttributesArrayTwo(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Chorus Length", "value": "',
                    Strings.toString(
                        chorusLengths[tokenIdToTune[tokenId].chorusLength]
                    ),
                    '"},',
                    '{"trait_type": "Bridge Length", "value": "',
                    Strings.toString(
                        bridgeLengths[tokenIdToTune[tokenId].bridgeLength]
                    ),
                    '"},',
                    '{"trait_type": "Outro Length", "value": "',
                    Strings.toString(
                        outroLengths[tokenIdToTune[tokenId].outroLength]
                    ),
                    '"},',
                    '{"trait_type": "Rhythm Pattern", "value": "',
                    rhythmPatterns[tokenIdToTune[tokenId].rhythmPatternIndex],
                    '"}]'
                )
            );
    }

    function getHTMLDocument(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(abi.encodePacked(html_prefix, getJs(tokenId), html_suffix));
    }

    function claim() public {
        require(totalMinted < 1000, "All have been minted");
        _internalMint(totalMinted);
    }

    function _internalMint(uint256 tokenId) private {
        tokenIdToTune[tokenId] = generateTune(tokenId);
        _safeMint(_msgSender(), tokenId);
        totalMinted++;
    }

    function generateTune(uint256 tokenId) private returns (Tune memory) {
        Tune memory tune;

        tune.rootIndex = randMod(tokenId, 12);
        tune.introLength = randMod(tokenId, 4);
        tune.verseLength = randMod(tokenId, 4);
        tune.chorusLength = randMod(tokenId, 4);

        tune.bridgeLength = randMod(tokenId, 4);
        tune.outroLength = randMod(tokenId, 4);
        tune.rhythmPatternIndex = randMod(tokenId, 5);

        tune.scaleIndex = randMod(tokenId, 6);
        tune.beatsPerMinuteIndex = randMod(tokenId, 24);

        tune.beatsPerMeasureIndex = randMod(tokenId, 4);
        tune.seed = Strings.toString(createSeedFromTx(tokenId));
        return tune;
    }

    function tuneDataToStringOne(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        Tune memory tune = tokenIdToTune[tokenId];
        return
            string(
                abi.encodePacked(
                    Strings.toString(tune.rootIndex),
                    ",",
                    Strings.toString(tune.introLength),
                    ",",
                    Strings.toString(tune.verseLength),
                    ",",
                    Strings.toString(tune.chorusLength),
                    ",",
                    Strings.toString(tune.bridgeLength),
                    ",",
                    Strings.toString(tune.outroLength),
                    ","
                )
            );
    }

    function tuneDataToStringTwo(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        Tune memory tune = tokenIdToTune[tokenId];
        return
            string(
                abi.encodePacked(
                    Strings.toString(tune.rhythmPatternIndex),
                    ",",
                    Strings.toString(tune.beatsPerMinuteIndex),
                    ",",
                    Strings.toString(tune.beatsPerMeasureIndex),
                    ",",
                    Strings.toString(tune.scaleIndex),
                    ",",
                    "'",
                    tune.seed,
                    "'" // Seed is a super huge number, so just making it a string
                )
            );
    }

    function getJs(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    js,
                    tuneDataToStringOne(tokenId),
                    tuneDataToStringTwo(tokenId),
                    ");"
                )
            );
    }

    // Gets a seed
    function createSeedFromTx(uint256 tokenId) internal returns (uint256) {
        randNonce++;
        uint256 o = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    tokenId,
                    randNonce,
                    block.difficulty,
                    block.timestamp
                )
            )
        );
        return o;
    }

    function randMod(uint256 tokenId, uint8 _modulo)
        internal
        returns (uint256)
    {
        // increase nonce
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        randNonce,
                        tokenId
                    )
                )
            ) % _modulo;
    }
}