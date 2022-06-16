// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication is InfinityMintObject {
	address deployer;

	mapping(address => bool) internal approved;

	constructor() {
		deployer = sender();
		approved[sender()] = true;
	}

	modifier onlyDeployer() {
		if (sender() != deployer) revert();
		_;
	}

	modifier onlyApproved() {
		if (approved[sender()] == false) revert();
		_;
	}

	function togglePrivilages(address addr) public onlyDeployer {
		approved[addr] = !approved[addr];
	}

	function transferOwnership(address addr) public onlyDeployer {
		deployer = addr;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./IRandomNumber.sol";
import "./InfinityMintObject.sol";

abstract contract IInfinityMintAsset is InfinityMintObject {
	function getColours(
		uint64 pathSize,
		uint64 pathId,
		IRandomNumber randomNumberController
	) public virtual returns (bytes memory result);

	function getObjectURI() public view virtual returns (string memory) {
		return "";
	}

	function getDefaultName() public virtual returns (string memory);

	function addColour(uint64 pathId, bytes memory colours) public virtual;

	function getNames(uint64 nameCount, IRandomNumber randomNumberController)
		public
		virtual
		returns (string[] memory results);

	function getRandomAsset(uint64 pathId, IRandomNumber randomNumberController)
		public
		virtual
		returns (uint64[] memory assetsId);

	function getAsset(uint64 assetId)
		public
		view
		virtual
		returns (bytes memory);

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		IRandomNumber randomNumberController
	) public virtual returns (bytes memory);

	function addAsset(uint256 rarity, bytes memory asset) public virtual;

	function getNextName(IRandomNumber randomNumberController)
		public
		virtual
		returns (string memory);

	function getPathGroup(uint64 pathId)
		public
		view
		virtual
		returns (bytes memory, uint64);

	function setNextPathId(uint64 pathId) public virtual;

	function getPathSize(uint64 pathId) public view virtual returns (uint64);

	function getNextPathId(IRandomNumber randomNumberController)
		public
		virtual
		returns (uint64);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

/**
    Used by the sticker contract + other contract to implemented the interface needed to call functions relating to ERC721 Royalties
 */

abstract contract IInfinityMintRoyalties {
	function withdraw() public virtual;

	//can only be called by InfinityMint sticker contracts that are attached to the tokenId and is used to
	//deposit the royalties from stickers to the main ERC721 contract and is automatically called by
	//the sticker contract
	function depositStickerRoyalty(uint64 tokenId) public payable virtual;
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";
import "./InfinityMintStorage.sol";
import "./IInfinityMintAsset.sol";
import "./IRandomNumber.sol";

abstract contract IInfinityMinter is Authentication {
	InfinityMintValues valuesController;
	InfinityMintStorage storageController;
	IInfinityMintAsset assetController;
	IRandomNumber randomNumberController;

	/*
	 */
	constructor(
		address valuesContract,
		address storageContract,
		address assetContract,
		address randomNumberContract
	) {
		valuesController = InfinityMintValues(valuesContract);
		storageController = InfinityMintStorage(storageContract);
		assetController = IInfinityMintAsset(assetContract);
		randomNumberController = IRandomNumber(randomNumberContract);
	}

	function mint(uint64 currentTokenId, address sender)
		public
		virtual
		returns (bytes memory);

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		bytes memory colours,
		bytes memory mintData,
		address sender
	) public virtual returns (bytes memory);

	/**

     */
	function getPreview(
		uint64 currentTokenId,
		uint64 currentPreviewId,
		address sender
	) public virtual returns (bytes[] memory);

	function selectiveMint(
		uint64 currentTokenId,
		uint256 pathId,
		address sender
	) public virtual returns (bytes memory);

	/*

    */
	function mintPreview(
		uint64 previewId,
		uint64 currentTokenId,
		address sender
	) public virtual returns (bytes memory);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;
//SafeMath Contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./InfinityMintValues.sol";

abstract contract IRandomNumber {
	uint256 internal numberSeed = 42069420;
	uint256 public randomnessFactor;
	uint256 internal nonce = 14928;
	bool public hasDeployed = false;

	InfinityMintValues valuesController;

	modifier hasNotSetup() {
		if (hasDeployed) revert();
		_;
		hasDeployed = true;
	}

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);
		randomnessFactor = valuesController.getValue("randomessFactor");
	}

	function getNumber() public returns (uint256) {
		return returnNumber(valuesController.getValue("maxRandomNumber"));
	}

	function getMaxNumber(uint256 maxNumber) public returns (uint256) {
		return returnNumber(maxNumber);
	}

	//called upon main deployment of the main kazooKid contract, can only be called once!
	function setup(
		address infinityMint,
		address infinityMintStorage,
		address infinityMintAsset
	) public virtual hasNotSetup {}

	function returnNumber(uint256 maxNumber)
		internal
		virtual
		returns (uint256)
	{
		if (maxNumber < 0) maxNumber = 0;
		uint256 c = uint256(
			keccak256(
				abi.encode(
					nonce++,
					numberSeed,
					maxNumber,
					msg.sender,
					block.timestamp,
					randomnessFactor
				)
			)
		);

		(bool safe, uint256 result) = SafeMath.tryMod(c, maxNumber);

		if (safe) return result;

		return 0;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

abstract contract IRoyalty is Authentication {
	//globals
	InfinityMintValues public valuesController;

	//payout values
	mapping(address => uint256) public values;

	uint256 private executionCount;
	uint256 public tokenPrice;
	uint256 public originalTokenPrice;
	uint256 public lastTokenPrice;
	uint256 public freeMints;
	uint256 public stickerSplit;

	uint256 public constant MINT_TYPE = 0;
	uint256 public constant STICKER_TYPE = 1;

	event Withdraw(address indexed sender, uint256 amount, uint256 newTotal);

	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);

		tokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");
		lastTokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");
		originalTokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");

		if (valuesController.tryGetValue("stickerSplit") > 100) revert();
		stickerSplit = valuesController.tryGetValue("stickerSplit");
	}

	function changePrice(uint256 _tokenPrice) public onlyDeployer {
		if (_tokenPrice < originalTokenPrice) revert();

		lastTokenPrice = tokenPrice;
		tokenPrice = _tokenPrice;
	}

	function registerFreeMint() public onlyApproved {
		freeMints = freeMints + 1;
	}

	function withdraw(address addr)
		public
		onlyApproved
		onlyOnce
		returns (uint256 total)
	{
		if (values[addr] <= 0) revert("Invalid or Empty address");

		total = values[addr];
		values[addr] = 0;

		emit Withdraw(addr, total, values[addr]);
	}

	function incrementBalance(uint256 value, uint256 typeOfSplit)
		public
		virtual;
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintWallet.sol";
import "./Authentication.sol";

abstract contract ITokenStickers is Authentication {
	address public currentOwner;
	address public mainController;
	uint64 public currentKazooId;
	uint256 public stickerPrice;
	uint64 public currentRequestId;
	uint64 public currentStickerId;

	InfinityMintWallet ownerWallet;

	mapping(address => bool) acceptedAddress; //list of accepted addresses
	mapping(uint64 => bytes) requests; //requests to add stickers
	mapping(uint64 => bytes) stickers; //accepted stickers

	//events
	event KazooRequestAccepted(
		uint64 stickerId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event KazooRequestDenied(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event KazooRequestWithdrew(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event KazooRequestAdded(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);

	/**
        acceptRequest

        should edmit KazooRequestAccepted if sucessful
     */
	function acceptRequest(uint64 requestId) public virtual;

	/**
        addRequest

        should edmit KazooRequestAdded if sucessful
     */
	function addRequest(bytes memory packed) public payable virtual;

	/**
        withdrawRequest

        should edmit KazooRequestAdded if sucessful
     */
	function withdrawRequest(uint64 requestId) public virtual;

	/**
        denyRequest

        should edmit KazooRequestAdded if sucessful
     */
	function denyRequest(uint64 requestId) public virtual;

	function setStickerPrice(uint256 price) public onlyApproved {
		stickerPrice = price;
	}

	function hasAcceptedStickers(address addr) public view returns (bool) {
		return acceptedAddress[addr];
	}

	/**
    function getRequestedStickers()
        public
        view
        onlyApproved
        returns (bytes[] memory result)
    {
        //count how many stickers we have that are valid
        uint64 count = 0;
        for (uint64 i = 0; i < currentRequestId; i++)
            if (!InfinityMintUtil.isEqual(requests[i], bytes(""))) count++;

        if (count != 0) {
            //ceate new array with the size of count
            result = new bytes[](count);
            count = 0; //reset count
            for (uint64 i = 0; i < currentRequestId; i++)
                if (!InfinityMintUtil.isEqual(requests[i], bytes("")))
                    //do it again
                    result[count++] = requests[i]; //add to result
        }
    }

    //NOTE: this actually does unpack requests, maybe move to mapping?
    function getMyRequestedStickers()
        public
        view
        returns (bytes[] memory result)
    {
        //count how many stickers we have that are valid
        uint64 count = 0;
        for (uint64 i = 0; i < currentRequestId; i++)
            if (
                !InfinityMintUtil.isEqual(requests[i], bytes("")) &&
                isRequestOwner(requests[i], sender())
            ) count++;

        if (count != 0) {
            //ceate new array with the size of count
            result = new bytes[](count);
            count = 0; //reset count
            for (uint64 i = 0; i < currentRequestId; i++)
                if (
                    !InfinityMintUtil.isEqual(requests[i], bytes("")) &&
                    isRequestOwner(requests[i], sender())
                )
                    //do it again
                    result[count++] = requests[i]; //add to result
        }
    }

    function getStickers() public view returns (bytes[] memory result) {
        //count how many stickers we have that are valid
        uint64 count = 0;
        for (uint64 i = 0; i < currentStickerId; i++)
            if (!InfinityMintUtil.isEqual(stickers[i], bytes(""))) count++;

        if (count != 0) {
            //ceate new array with the size of count
            result = new bytes[](count);
            count = 0; //reset count
            for (uint64 i = 0; i < currentStickerId; i++)
                if (!InfinityMintUtil.isEqual(stickers[i], bytes("")))
                    //do it again
                    result[count++] = stickers[i]; //add to result
        }
    }

    */

	/**

        Code to switch from returning a byte array full of stickers to Ids (non broken up) and id based
        get (broken up)
     */

	function getMyRequestedSticker(uint64 stickerRequestId)
		public
		view
		returns (bytes memory result)
	{
		if (
			InfinityMintUtil.isEqual(requests[stickerRequestId], bytes("")) ||
			!isRequestOwner(requests[stickerRequestId], sender())
		) revert();

		return requests[stickerRequestId];
	}

	function getSticker(uint64 stickerId)
		public
		view
		returns (bytes memory result)
	{
		if (InfinityMintUtil.isEqual(stickers[stickerId], bytes(""))) revert();

		return stickers[stickerId];
	}

	function getRequestedSticker(uint64 stickerId)
		public
		view
		onlyApproved
		returns (bytes memory result)
	{
		if (InfinityMintUtil.isEqual(requests[stickerId], bytes(""))) revert();

		return requests[stickerId];
	}

	function getStickers() public view returns (uint64[] memory result) {
		uint64 count = 0;
		for (uint64 i = 0; i < currentStickerId; i++)
			if (!InfinityMintUtil.isEqual(stickers[i], bytes(""))) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentStickerId; i++)
				if (!InfinityMintUtil.isEqual(stickers[i], bytes("")))
					result[count++] = i;
		}
	}

	function getRequestedStickers()
		public
		view
		onlyApproved
		returns (uint64[] memory result)
	{
		uint64 count = 0;
		for (uint64 i = 0; i < currentRequestId; i++)
			if (!InfinityMintUtil.isEqual(requests[i], bytes(""))) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentRequestId; i++)
				if (!InfinityMintUtil.isEqual(requests[i], bytes("")))
					result[count++] = i;
		}
	}

	function getMyRequestedStickers()
		public
		view
		returns (uint64[] memory result)
	{
		uint64 count = 0;
		for (uint64 i = 0; i < currentRequestId; i++)
			if (!InfinityMintUtil.isEqual(requests[i], bytes(""))) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentRequestId; i++)
				if (
					!InfinityMintUtil.isEqual(requests[i], bytes("")) &&
					isRequestOwner(requests[i], sender())
				) result[count++] = i;
		}
	}

	function isSafe(bytes memory _p) internal view returns (bool) {
		//will call exception if it is bad
		(uint64 kazooId, , , ) = InfinityMintUtil.unpackSticker(_p);
		return kazooId == currentKazooId;
	}

	function isRequestOwner(bytes memory _p, address addr)
		internal
		pure
		returns (bool)
	{
		(, address owner, , ) = abi.decode(
			_p,
			(uint256, address, bytes, uint64)
		);
		return owner == addr;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
//
import "./InfinityMintStorage.sol";
import "./IInfinityMinter.sol";
import "./IRoyalty.sol";
import "./Authentication.sol";
import "./IInfinityMintRoyalties.sol";

contract InfinityMint is
	ERC721URIStorage,
	Authentication,
	IInfinityMintRoyalties
{
	InfinityMintStorage private storageController;
	IRandomNumber private randomNumberController;
	IInfinityMinter private minterController;
	IRoyalty private royaltyController;

	//globals
	InfinityMintValues public valuesController;

	//events
	event KazooMinted(
		uint64 kazooId,
		bytes encodedData,
		address indexed sender
	);
	event KazooPreviewMinted(
		uint64 kazooId,
		bytes encodedData,
		address indexed sender,
		uint64 previewId
	);
	event KazooPreviewComplete(address indexed sender, bytes[] encodedPreviews);

	/**
        I did have all sorts of error events defined here but they don't even work/display and take up so much contract
        space so I removed them :)
     */

	//public
	uint64 public currentKazooId;
	uint64 public currentPreviewId;
	bool public mintsEnabled;

	//private
	uint256 private executionCount;
	string private tokenName;
	string private tokenSymbol;

	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	constructor(
		string memory _tokenName,
		string memory _tokenSymbol,
		address storageContract,
		address randomNumberContract,
		address valuesContract,
		address minterContract,
		address royaltyContract
	) ERC721("InfinityMint", "NFT") {
		//this name and symbol above is unused
		storageController = InfinityMintStorage(storageContract); //address of the storage controlller
		randomNumberController = IRandomNumber(randomNumberContract); //addess of the random number controller
		valuesController = InfinityMintValues(valuesContract);
		minterController = IInfinityMinter(minterContract);
		royaltyController = IRoyalty(royaltyContract);
		//token name and symbol
		tokenName = _tokenName;
		tokenSymbol = _tokenSymbol;
	}

	//uses our name instead
	function name() public view override returns (string memory) {
		return tokenName;
	}

	//uses our symbol instead
	function symbol() public view override returns (string memory) {
		return tokenSymbol;
	}

	//the total amount of kazoos
	function totalSupply() public view returns (uint256) {
		return valuesController.tryGetValue("maxSupply");
	}

	function toggleMints() public onlyDeployer {
		mintsEnabled = !mintsEnabled;
	}

	function getPreview() public {
		_mintCheck(false); //does not check the price

		address sender = sender();

		//if the user has already had their daily preview mints
		if (
			InfinityMintStorage(storageController).previewBlocked(sender) ||
			valuesController.tryGetValue("previewCount") <= 0
		) revert("Preview Blocked");

		bytes[] memory previews = minterController.getPreview(
			currentKazooId,
			currentPreviewId,
			sender
		);

		currentPreviewId = uint64(currentPreviewId + previews.length);

		//set the sender to be preview blocked for a while
		storageController.setPreviewBlock(sender, true);

		//once done, emit an event
		emit KazooPreviewComplete(sender, previews);
	}

	/*

	*/
	function mintPreview(uint64 previewId) public payable onlyOnce {
		_mintCheck(!approved[sender()]); //will not check the price for approved members

		completeMint(
			minterController.mintPreview(previewId, currentKazooId, sender()),
			sender(),
			previewId,
			true
		);
	}

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 pathId,
		uint64 pathSize,
		bytes memory colours,
		bytes memory mintData
	) public onlyDeployer {
		if (!mintsEnabled) revert();

		royaltyController.registerFreeMint();

		completeMint(
			minterController.implicitMint(
				currentKazooId,
				pathId,
				pathSize,
				colours,
				mintData,
				sender()
			),
			sender(),
			currentKazooId,
			false
		);
	}

	function completeMint(
		bytes memory data,
		address owner,
		uint64 tokenId,
		bool flag
	) internal {
		//mint it
		_safeMint(owner, currentKazooId);
		//store the chosen path
		storageController.set(currentKazooId, data);
		storageController.registerKazoo(currentKazooId, owner);

		//if the value is greater than zero
		if (msg.value > 0) {
			royaltyController.incrementBalance(
				msg.value,
				royaltyController.MINT_TYPE()
			);
		} else {
			require(approved[owner]);
			royaltyController.registerFreeMint();
		}

		//untoggle preview block
		if (InfinityMintStorage(storageController).isPreviewBlocked(owner)) {
			storageController.setPreviewBlock(owner, false);
			storageController.wipePreviews(owner, currentPreviewId);
		}

		if (flag)
			//if true then its a preview mint
			emit KazooPreviewMinted(currentKazooId++, data, owner, tokenId);
		else emit KazooMinted(currentKazooId++, data, owner);
	}

	function _mintCheck(bool checkPrice) private {
		if (checkPrice && msg.value != royaltyController.tokenPrice()) revert();
		if (!mintsEnabled) revert();
		if (currentKazooId == valuesController.tryGetValue("maxSupply"))
			revert();
	}

	function tokenPrice() public view returns (uint) {
		return royaltyController.tokenPrice();
	}

	function selectiveMint(uint256 pathId) public payable onlyOnce {
		//check if mint is valid
		_mintCheck(!approved[sender()]);

		if (!valuesController.isTrue("selectiveMode")) revert();

		completeMint(
			minterController.selectiveMint(currentKazooId, pathId, sender()),
			sender(),
			currentKazooId,
			false
		); //4th arg false meaning not a preview mint
	}

	function mint() public payable onlyOnce {
		//check if mint is valid
		_mintCheck(!approved[sender()]);

		completeMint(
			minterController.mint(currentKazooId, sender()),
			sender(),
			currentKazooId,
			false
		); //4th arg false meaning not a preview mint
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 kazooId,
		bytes memory _data
	) public override onlyOnce {
		if (!_isApprovedOrOwner(sender(), kazooId)) revert();
		storageController.transferKazoo(to, uint64(kazooId));
		_safeTransfer(from, to, uint64(kazooId), _data);
	}

	/**
		Withdraws from the current contract the amount that the sender is
		entitled too.

		Will only work for people who have balances with the royaltyController
	 */
	function withdraw() public override onlyOnce {
		if (royaltyController.values(sender()) == 0) revert();

		if (address(this).balance - royaltyController.values(sender()) < 0)
			revert("Cannot afford to withdraw");

		uint256 value = royaltyController.withdraw(sender()); //will revert if bad, results in the value to be deposited. Has Re-entry protection.
		if (value <= 0) revert("Invalid or Empty value");
		payable(sender()).transfer(value);
	}

	/**
		Can only be called by a sticker contract
	 */
	function depositStickerRoyalty(uint64 tokenId)
		public
		payable
		override
		onlyContract
		onlyOnce
	{
		address sticker;

		//just take the owner/sticker
		(, , , , , sticker, , , , ) = abi.decode(
			storageController.get(tokenId),
			(
				uint64,
				uint64,
				uint64,
				address,
				address,
				address,
				bytes,
				bytes,
				uint64[],
				string[]
			)
		);

		//if the sender isn't the sticker contract attached to this token
		if (sender() != sticker) revert();

		//increment
		royaltyController.incrementBalance(
			msg.value,
			royaltyController.STICKER_TYPE()
		);

		//dont revert allow deposit
	}

	function transferFrom(
		address from,
		address to,
		uint256 kazooId
	) public override onlyOnce {
		if (!_isApprovedOrOwner(sender(), kazooId)) revert();
		storageController.transferKazoo(to, uint64(kazooId));
		_transfer(from, to, uint64(kazooId));
	}

	function setTokenURI(uint64 kazooId, string memory json) public {
		if (!_isApprovedOrOwner(sender(), kazooId)) revert();
		_setTokenURI(kazooId, json);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMint.sol";
import "./IInfinityMintAsset.sol";
import "./ITokenStickers.sol";
import "./InfinityMintValues.sol";
import "./IRoyalty.sol";

contract InfinityMintApi is InfinityMintObject {
	InfinityMint mainContract;
	InfinityMintStorage storageContract;
	IInfinityMintAsset assetContract;
	InfinityMintValues valueContract;
	IRoyalty royaltyContract;

	struct Kazoo {
		uint64 pathId;
		uint64 pathSize;
		uint64 kazooId;
		address owner;
		address walletContract;
		address stickersContract;
		bytes colours;
		bytes mintData;
		uint64[] assets;
		string[] names;
	}

	constructor(
		address kazooKid,
		address storageController,
		address assetController,
		address valueController,
		address royaltyController
	) {
		mainContract = InfinityMint(kazooKid);
		storageContract = InfinityMintStorage(storageController);
		assetContract = IInfinityMintAsset(assetController);
		valueContract = InfinityMintValues(valueController);
		royaltyContract = IRoyalty(royaltyController);
	}

	function kazooPrice() public view returns (uint256) {
		return royaltyContract.tokenPrice();
	}

	function previewTimeout() public view returns (uint256) {
		return valueContract.tryGetValue("previewTimeout");
	}

	function ownerOf(uint64 kazooId) public view returns (address result) {
		result = storageContract.getOwner(kazooId);

		if (result == address(0x0)) revert();
	}

	function getStickers(address stickerContract)
		public
		view
		returns (uint64[] memory)
	{
		if (stickerContract == address(0x0)) return new uint64[](0);

		ITokenStickers sticker = ITokenStickers(stickerContract);
		return sticker.getStickers();
	}

	function getObjectURI() public view returns (string memory) {
		return assetContract.getObjectURI();
	}

	function isPreviewBlocked(address sender) public view returns (bool) {
		return storageContract.isPreviewBlocked(sender);
	}

	function allKazooPaged(
		uint64 page,
		uint64 pageMax,
		address owner
	) public view returns (uint64[] memory kazoos) {
		uint64 currentKazooId = totalMints();

		require(pageMax < 1000);

		if (currentKazooId != 0) {
			uint64 kazooId = uint64(storageContract.firstHeldAt(owner));
			uint64 count = 0;
			uint64 throwAway = (pageMax * page);
			//count how many we have
			while (kazooId < currentKazooId && count < pageMax) {
				if (
					owner == storageContract.getOwner(kazooId) &&
					throwAway-- <= 0
				) count++;
				kazooId++;
			}

			//if we did infact find any
			if (count != 0) {
				//create a new array for the ids with the count of that
				kazoos = new uint64[](count);
				//reset back to zero
				count = 0;
				kazooId = uint64(storageContract.firstHeldAt(owner));
				throwAway = (pageMax * page);
				//do it again, this time populating the array.
				while (kazooId < currentKazooId && count < pageMax) {
					if (
						owner == storageContract.getOwner(kazooId) &&
						throwAway-- <= 0
					) kazoos[count++] = kazooId;

					kazooId++;
				}
			}
		}
	}

	function allKazoos(address owner)
		public
		view
		returns (uint64[] memory kazoos)
	{
		uint64 currentKazooId = totalMints();

		if (owner == address(0x0)) revert();

		if (storageContract.holders(owner) > 2500)
			revert("please use allKazooPaged");

		if (currentKazooId != 0) {
			uint64 kazooId = uint64(storageContract.firstHeldAt(owner));
			uint64 count = 0;

			//count how many we have
			while (kazooId < currentKazooId) {
				if (owner == storageContract.getOwner(kazooId)) count++;

				kazooId++;
			}

			//if we did infact find any
			if (count != 0) {
				//create a new array for the ids with the count of that
				kazoos = new uint64[](count);
				//reset back to zero
				count = 0;
				//set the starting kazooId to be the Id of the first kazoo we own
				kazooId = uint64(storageContract.firstHeldAt(owner));
				//do it again, this time populating the array.
				while (kazooId < currentKazooId) {
					if (owner == storageContract.getOwner(kazooId))
						kazoos[count++] = kazooId;

					kazooId++;
				}
			}
		}
	}

	function getRaw(uint64 kazooId) public view returns (bytes memory) {
		if (kazooId < 0 || kazooId >= totalMints()) revert();

		return storageContract.get(kazooId);
	}

	function getPath(uint64 pathId) public view returns (bytes memory path) {
		(path, ) = assetContract.getPathGroup(pathId);
	}

	function getAsset(uint64 pathId) public view returns (bytes memory) {
		return assetContract.getAsset(pathId);
	}

	function getCount() public view returns (uint256) {
		return storageContract.holders(sender());
	}

	function get(uint64 kazooId) public view returns (Kazoo memory result) {
		if (kazooId < 0 || kazooId >= totalMints()) revert();

		//unpack
		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner,
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(storageContract.get(kazooId));

		//set
		result = Kazoo(
			pathId,
			pathSize,
			_kazooId,
			owner,
			wallet,
			stickers,
			colours,
			mintData,
			assets,
			names
		);
	}

	function getWalletContract(uint64 tokenId)
		public
		view
		returns (address result)
	{
		(, , , , result, , , , , ) = InfinityMintUtil.unpackKazoo(
			storageContract.get(tokenId)
		);
	}

	function getStickerContract(uint64 tokenId)
		public
		view
		returns (address result)
	{
		(, , , , , result, , , , ) = InfinityMintUtil.unpackKazoo(
			storageContract.get(tokenId)
		);
	}

	function allPreviews(address addr) public view returns (uint64[] memory) {
		return
			storageContract.allPreviews(addr, mainContract.currentPreviewId());
	}

	function getPreview(uint64 previewId) public view returns (bytes memory) {
		if (storageContract.getPreviewOwner(previewId) != sender()) revert();

		return storageContract.getPreview(previewId);
	}

	function isEnabled() public view returns (bool) {
		return mainContract.mintsEnabled();
	}

	function isReady() public view returns (bool) {
		return mainContract.mintsEnabled();
	}

	function totalMints() public view returns (uint64) {
		return mainContract.currentKazooId();
	}

	function originalPrice() public view returns (uint256) {
		return royaltyContract.originalTokenPrice();
	}

	//the total amount of kazoos
	function totalSupply() public view returns (uint256) {
		return valueContract.tryGetValue("maxSupply");
	}

	function maxKazoos() public view returns (uint256) {
		return valueContract.tryGetValue("maxSupply");
	}

	function lastPrice() public view returns (uint256) {
		return royaltyContract.lastTokenPrice();
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./IRandomNumber.sol";
import "./InfinityMintStickers.sol";
import "./InfinityMintStorage.sol";
import "./InfinityMintApi.sol";

contract InfinityMintFactory is InfinityMintObject {
	InfinityMintStorage storageController;
	InfinityMintApi infinityMintApi;
	InfinityMintValues valuesController;
	address infinityMint;

	event StickerContractDeployed(
		uint64 tokenId,
		address stickerContract,
		address indexed sender
	);

	event WalletContractDeployed(
		uint64 tokenId,
		address stickerContract,
		address indexed sender
	);

	constructor(
		address _storageController,
		address _infinityMintApi,
		address _infinityMint,
		address valuesContract
	) {
		storageController = InfinityMintStorage(_storageController);
		infinityMintApi = InfinityMintApi(_infinityMintApi);
		infinityMint = _infinityMint;
		valuesController = InfinityMintValues(valuesContract);
	}

	/**
		This is the only method that can create sticker contracts to ensure it is
		our contract that is deployed
	 */
	function deployStickerContract(uint64 tokenId) public {
		if (sender() != infinityMintApi.ownerOf(tokenId)) revert("not owner");
		if (infinityMintApi.getStickerContract(tokenId) != address(0x0))
			revert("contract already set");

		address wallet = infinityMintApi.getWalletContract(tokenId);

		if (wallet == address(0x0)) revert("no wallet for token");

		InfinityMintStickers stickerContract = new InfinityMintStickers(
			tokenId,
			sender(),
			infinityMint,
			payable(wallet),
			address(valuesController)
		);

		storageController.setStickerContract(address(stickerContract), tokenId);

		emit StickerContractDeployed(
			tokenId,
			address(stickerContract),
			sender()
		);
	}

	//can deploy a wallet contract in case it was not done in the mint phase
	function deployWalletContract(uint64 tokenId) public {
		if (sender() != infinityMintApi.ownerOf(tokenId)) revert("not owner");
		if (infinityMintApi.getWalletContract(tokenId) != address(0x0))
			revert("contract already set");

		InfinityMintWallet wallet = new InfinityMintWallet(tokenId, sender());
		storageController.setWalletContract(address(wallet), tokenId);

		emit WalletContractDeployed(tokenId, address(wallet), sender());
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
	/*
		Isn't a garuntee
	*/
	modifier onlyContract() {
		uint256 size;
		address account = sender();

		assembly {
			size := extcodesize(account)
		}
		if (size > 0) _;
		else revert();
	}

	//does the same as open zepps contract
	function sender() public view virtual returns (address) {
		return msg.sender;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./ITokenStickers.sol";
import "./IInfinityMintRoyalties.sol";

contract InfinityMintStickers is ITokenStickers {
	uint256 executionCount;
	uint256 tokenValue;

	InfinityMintValues valuesController;

	constructor(
		uint64 kazooId,
		address owner,
		address mainContract,
		address payable kazooWalletAddress,
		address valuesContract
	) ITokenStickers() {
		currentOwner = owner;
		currentKazooId = kazooId;
		valuesController = InfinityMintValues(valuesContract);

		stickerPrice = 1 * valuesController.tryGetValue("baseTokenValue");
		mainController = mainContract;
		ownerWallet = InfinityMintWallet(kazooWalletAddress);
		approved[currentOwner] = true;

		transferOwnership(currentOwner);
	}

	//prevents re-entry attack
	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	function setPrice(uint256 tokenPrice) public onlyDeployer {
		stickerPrice = tokenPrice * tokenValue;
	}

	function acceptRequest(uint64 requestId)
		public
		override
		onlyApproved
		onlyOnce
	{
		if (InfinityMintUtil.isEqual(requests[requestId], bytes(""))) revert();

		(
			uint256 price,
			address sender,
			bytes memory packed,
			uint64 savedRequestId
		) = abi.decode(requests[requestId], (uint256, address, bytes, uint64));

		//price is not the current sticker price
		if (price != stickerPrice) revert();

		//not the saved Id
		if (savedRequestId != requestId) revert();

		//delete first to stop re-entry attack
		delete requests[requestId];

		//percentage cut
		uint256 cut = ( price / 100 ) * valuesController.tryGetValue("stickerSplit");


		//deduct the cut from the price but only if it does not completely take the price
		if (price - cut > 0)
			price = price - cut;
			//else set the cut to zero
		else cut = 0;

		//deposit the royalties for this sticker to the main contract
		IInfinityMintRoyalties(mainController).depositStickerRoyalty{
			value: cut
		}(currentKazooId);

		ownerWallet.deposit{ value: price }(); //deposit it
		stickers[currentStickerId] = packed;

		//add this address to the accepted addresses
		acceptedAddress[sender] = true;
		emit KazooRequestAccepted(currentStickerId++, sender, price, packed);
	}

	function addRequest(bytes memory packed) public payable override onlyOnce {
		if (msg.value != stickerPrice) revert();

		//will revert/call execption if the unpack is bad
		if (!isSafe(packed)) revert();
		//add it!
		requests[currentRequestId] = abi.encode(
			msg.value,
			sender(),
			packed,
			currentRequestId
		);

		emit KazooRequestAdded(currentRequestId++, sender(), msg.value, packed); //emit
	}

	function withdrawRequest(uint64 requestId) public override onlyOnce {
		if (InfinityMintUtil.isEqual(requests[requestId], bytes(""))) revert();

		(
			uint256 price,
			address _sender,
			bytes memory packed,
			uint64 savedRequestId
		) = abi.decode(requests[requestId], (uint256, address, bytes, uint64));

		//sender
		if (_sender != sender()) revert();

		//not the saved Id
		if (savedRequestId != requestId) revert();

		//delete first to stop re-entry attack
		delete requests[requestId];
		//transfer
		address payable senderPayable = payable(_sender);
		senderPayable.transfer(price); //transfer back the price to the sender

		emit KazooRequestWithdrew(requestId, _sender, price, packed);
	}

	function denyRequest(uint64 requestId)
		public
		override
		onlyApproved
		onlyOnce
	{
		if (InfinityMintUtil.isEqual(requests[requestId], bytes(""))) revert();

		(uint256 price, address sender, bytes memory packed) = abi.decode(
			requests[requestId],
			(uint256, address, bytes)
		);

		//delete first to stop re-entry attack
		delete requests[requestId];
		address payable senderPayable = payable(sender);
		senderPayable.transfer(price); //transfer back the price to the sender

		emit KazooRequestDenied(requestId, sender, price, packed);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

//written by Llydia Cross
contract InfinityMintStorage is InfinityMintObject {
	address private deployer;
	mapping(uint64 => bytes) private previews;
	mapping(uint64 => bytes) private cards;
	mapping(uint64 => bytes) private kazoos;
	mapping(uint64 => address) private registeredKazoos;
	mapping(uint64 => address) private registeredPreviews;
	//public stuff
	mapping(address => bool) public authenticated;
	mapping(address => bool) public previewBlocked;
	mapping(address => uint256) public holders; //holders of token and the number they have
	mapping(address => uint256) public firstHeldAt; //first held a token at this id ( for fast look up)

	constructor() {
		deployer = sender();
		authenticated[deployer] = true;
	}

	modifier onlyAuthenticated() {
		if (authenticated[sender()] == false) revert();
		_;
	}

	modifier onlyDeployer() {
		if (deployer != sender()) revert();
		_;
	}

	function registerPreview(uint64 previewId, address owner)
		public
		onlyAuthenticated
	{
		if (registeredPreviews[previewId] != address(0x0))
			revert("Already Registered");

		registeredPreviews[previewId] = owner;
	}

	function registerKazoo(uint64 kazooId, address owner)
		public
		onlyAuthenticated
	{
		if (registeredKazoos[kazooId] != address(0x0)) revert();

		if (kazooId != 0 && firstHeldAt[owner] == 0)
			firstHeldAt[owner] = kazooId;

		holders[owner] = holders[owner] + 1;
		registeredKazoos[kazooId] = owner;
	}

	function transferKazoo(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		transferKazoo(kazooId, to);

		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner, //change it over
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(get(kazooId));

		owner = to;

		set(
			kazooId,
			abi.encode(
				pathId,
				pathSize,
				_kazooId,
				owner,
				wallet,
				stickers,
				colours,
				mintData,
				assets,
				names
			)
		);
	}

	function setStickerContract(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		transferKazoo(kazooId, to);

		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner, //change it over
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(get(kazooId));

		stickers = to;

		set(
			kazooId,
			abi.encode(
				pathId,
				pathSize,
				_kazooId,
				owner,
				wallet,
				stickers,
				colours,
				mintData,
				assets,
				names
			)
		);
	}

	function setWalletContract(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		transferKazoo(kazooId, to);

		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner, //change it over
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(get(kazooId));

		wallet = to;

		set(
			kazooId,
			abi.encode(
				pathId,
				pathSize,
				_kazooId,
				owner,
				wallet,
				stickers,
				colours,
				mintData,
				assets,
				names
			)
		);
	}

	function isPreviewBlocked(address addr) public view returns (bool) {
		return previewBlocked[addr] == true;
	}

	function transferKazoo(uint64 kazooId, address to) public {
		if (registeredKazoos[kazooId] == address(0x0)) revert();

		registeredKazoos[kazooId] = to;
	}

	function wipePreviews(address addr, uint64 currentPreviewId) public {
		uint64[] memory rPreviews = allPreviews(addr, currentPreviewId);

		for (uint256 i = 0; i < rPreviews.length; i++) {
			delete registeredPreviews[rPreviews[i]];
			delete previews[rPreviews[i]];
		}
	}

	function allPreviews(address owner, uint64 currentPreviewId)
		public
		view
		returns (uint64[] memory rPreviews)
	{
		if (owner == address(0x0)) revert();

		if (currentPreviewId != 0) {
			uint64 previewId = 0;
			uint64 count = 0;

			//count how many we have
			while (previewId < currentPreviewId) {
				if (owner == getPreviewOwner(previewId)) count++;
				previewId++;
			}

			//if we did infact find any
			if (count != 0) {
				//create a new array for the ids with the count of that
				rPreviews = new uint64[](count);
				//reset back to zero
				count = 0;
				previewId = 0;
				//do it again, this time populating the array.
				while (previewId < currentPreviewId) {
					if (owner == getPreviewOwner(previewId))
						rPreviews[count++] = previewId;

					previewId++;
				}
			}
		}
	}

	function getOwner(uint64 kazooId) public view returns (address) {
		return registeredKazoos[kazooId];
	}

	function getPreviewOwner(uint64 previewId) public view returns (address) {
		return registeredPreviews[previewId];
	}

	function setAuthenticationStatus(address sender, bool value)
		public
		onlyDeployer
	{
		authenticated[sender] = value;
	}

	function set(uint64 kazooId, bytes memory data) public onlyAuthenticated {
		kazoos[kazooId] = data;
	}

	function setPreviewBlock(address sender, bool value)
		public
		onlyAuthenticated
	{
		previewBlocked[sender] = value;
	}

	function setPreview(uint64 previewId, bytes calldata data)
		public
		onlyAuthenticated
	{
		previews[previewId] = data;
	}

	function getPreview(uint64 previewId)
		public
		view
		onlyAuthenticated
		returns (bytes memory)
	{
		if (InfinityMintUtil.isEqual(previews[previewId], "")) revert();

		return previews[previewId];
	}

	function deletePreview(uint64 previewId) public onlyAuthenticated {
		if (InfinityMintUtil.isEqual(previews[previewId], "")) revert();

		delete previews[previewId];
	}

	function get(uint64 kazooId) public view returns (bytes memory) {
		if (InfinityMintUtil.isEqual(kazoos[kazooId], "")) revert();

		return kazoos[kazooId];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

library InfinityMintUtil {
	function toString(uint256 _i)
		internal
		pure
		returns (string memory _uintAsString)
	{
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	// https://solidity-by-example.org/signature/
	function getRSV(bytes memory signature)
		public
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(signature.length == 65, "invalid length");
		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}
	}

	//checks if two strings (or bytes) are equal
	function isEqual(bytes memory s1, bytes memory s2)
		internal
		pure
		returns (bool)
	{
		bytes memory b1 = bytes(s1);
		bytes memory b2 = bytes(s2);
		uint256 l1 = b1.length;
		if (l1 != b2.length) return false;
		for (uint256 i = 0; i < l1; i++) {
			//check each byte
			if (b1[i] != b2[i]) return false;
		}
		return true;
	}

	function unpackSticker(bytes memory sticker)
		internal
		pure
		returns (
			uint64 tokenId,
			string memory checkSum,
			string memory object,
			address owner
		)
	{
		return abi.decode(sticker, (uint64, string, string, address));
	}

	function unpackKazoo(bytes memory preview)
		internal
		pure
		returns (
			uint64 pathId,
			uint64 pathSize,
			uint64 kazooId,
			address owner,
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory data,
			uint64[] memory assets,
			string[] memory names
		)
	{
		return
			abi.decode(
				preview,
				(
					uint64,
					uint64,
					uint64,
					address,
					address,
					address,
					bytes,
					bytes,
					uint64[],
					string[]
				)
			);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

contract InfinityMintValues {
	mapping(string => uint256) private values;
	mapping(string => bool) private booleanValues;
	mapping(string => bool) private registeredValues;

	address deployer;

	constructor() {
		deployer = msg.sender;
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert();
		_;
	}

	function setValue(string memory key, uint256 value) public onlyDeployer {
		values[key] = value;
		registeredValues[key] = true;
	}

	function setupValues(
		string[] memory keys,
		uint256[] memory _values,
		string[] memory booleanKeys,
		bool[] memory _booleanValues
	) public onlyDeployer {
		require(keys.length == _values.length);
		require(booleanKeys.length == _booleanValues.length);
		for (uint256 i = 0; i < keys.length; i++) {
			setValue(keys[i], _values[i]);
		}

		for (uint256 i = 0; i < booleanKeys.length; i++) {
			setBooleanValue(booleanKeys[i], _booleanValues[i]);
		}
	}

	function setBooleanValue(string memory key, bool value)
		public
		onlyDeployer
	{
		booleanValues[key] = value;
		registeredValues[key] = true;
	}

	function isTrue(string memory key) public view returns (bool) {
		return booleanValues[key];
	}

	function getValue(string memory key) public view returns (uint256) {
		if (!registeredValues[key]) revert("Invalid Value");

		return values[key];
	}

	function tryGetValue(string memory key) public view returns (uint256) {
		if (!registeredValues[key]) return 1;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

contract InfinityMintWallet is InfinityMintObject, Authentication {
	address payable public currentOwner;
	uint64 public currentKazooId;
	uint256 private walletValue;
	uint256 private executionCount;

	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	event Deposit(address indexed sender, uint256 amount, uint256 newTotal);
	event Withdraw(address indexed sender, uint256 amount, uint256 newTotal);

	constructor(uint64 kazooId, address owner) Authentication() {
		//this only refers to being allowed to deposit into the wallet
		approved[owner] = true;
		currentKazooId = kazooId;
		transferOwnership(owner);
	}

	function getBalance() public view onlyApproved returns (uint256) {
		return walletValue;
	}

	//allows the contract to receive tokens immediately calling the deposit
	receive() external payable {
		deposit();
	}

	function deposit() public payable onlyOnce {
		if (msg.value <= 0) revert();

		walletValue = walletValue + msg.value;
		emit Deposit(sender(), msg.value, walletValue);
	}

	function withdraw() public onlyOnce {
		if (sender() != currentOwner) revert();

		//to stop re-entry attack
		uint256 balance = walletValue;
		walletValue = 0;
		currentOwner.transfer(balance);
		emit Withdraw(sender(), balance, walletValue);
	}
}