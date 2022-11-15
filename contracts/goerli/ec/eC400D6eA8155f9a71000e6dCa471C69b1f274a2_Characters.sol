// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./TypeVVriter.sol";

/**
         █
         █
         █
 ▄       █                             █
 █       █       ▄         ▃ █         █
 █       █     █ █         █ █     ▆ █ █
 █     ▄ █     █ █     ▃   █ █     █ █ █
 █   ▂ █ █     █ █     █   █ █     █ █ █ ▃
 █ ▂ █ █ █ █ ▆ █ █     █ █ █ █ ▆   █ █ █ █   █   ▆
 █ █ █ █ █ █ █ █ █ ▂ ▆ █ █ █ █ █ ▂ █ █ █ █ ▇ █ ▂ █ ▁
----------------------------------------------------
 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
----------------------------------------------------
  _______ _____   ___  ___  __________________  ____
 / ___/ // / _ | / _ \/ _ |/ ___/_  __/ __/ _ \/ __/
/ /__/ _  / __ |/ , _/ __ / /__  / / / _// , _/\ \
\___/_//_/_/ |_/_/|_/_/ |_\___/ /_/ /___/_/|_/___/

====================================================
@title  CHRCTRS
@author VisualizeValue
@notice Everything is a derivative of this.
*/
contract Characters is ERC721 {
    /// @notice Our general purpose TypeVVriter. Write with Characters on chain.
    TypeVVriter public typeVVriter;

    /// @notice The 26 base characters of the modern Latin alphabet.
    string[26] public CHARACTERS = [
        "A", "B", "C", "D", "E", "F", "G",
        "H", "I", "J", "K", "L", "M", "N",
        "O", "P", "Q", "R", "S", "T", "U",
        "V", "W", "X", "Y", "Z"
    ];

    /// @notice The rarities of characters in the Concise Oxford Dictionary.
    /// Samuel Morse used these to assign the simplest keys
    /// to the most common letters in Morse code.
    string[26] public CHARACTER_RARITIES = [
        "8.4966", "2.0720", "4.5388", "3.3844", "11.1607", "1.8121", "2.4705",
        "3.0034", "7.5448", "0.1965", "1.1016", "5.4893", "3.0129", "6.6544",
        "7.1635", "3.1671", "0.1962", "7.5809", "5.7351", "6.9509", "3.6308",
        "1.0074", "1.2899", "0.2902", "1.7779", "0.2722"
    ];

    /// @dev Create the new Characters collection.
    constructor() ERC721("Characters", "CHRCTRS") {
        // Deploy the TypeVVriter
        typeVVriter = new TypeVVriter();

        // Mint all character tokens
        for (uint256 id = 1; id <= CHARACTERS.length; id++) {
            _mint(address(this), id);
        }
    }

    /// @notice Get the Metadata for a given Character ID.
    /// @dev The token URI for a given character.
    /// @param tokenId The character ID to show.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory character = CHARACTERS[tokenId - 1];
        string memory letter = typeVVriter.LETTERS(character);
        string memory rarity = CHARACTER_RARITIES[tokenId - 1];

        uint256 characterWidth = typeVVriter.LETTER_WIDTHS(character) > 0
            ? typeVVriter.LETTER_WIDTHS(character)
            : typeVVriter.LETTER_WIDTHS("DEFAULT");
        uint256 center = 285;
        uint256 em = 30;

        string memory left = Strings.toString(center - characterWidth);
        string memory top = Strings.toString(center - em);

        string memory svg = string(abi.encodePacked(
            '<svg ',
                'viewBox="0 0 570 570" width="1400" height="1400" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg"',
            '>',
                '<rect width="570" height="570" fill="black"/>',
                '<path transform="translate(', left, ',', top, ') ',
                    'scale(2)" d="', letter, '" fill="white"',
                '/>'
            '</svg>'
        ));

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "', character, '",',
                '"description": "Rarity: ', rarity, '%",',
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @notice Number of characters in the modern Latin alphabet.
    /// @dev Returns the total amount of tokens stored by the contract.
    function totalSupply() external pure returns (uint256) {
        return 26;
    }

    /// @dev Hook for `saveTransferFrom` of ERC721 tokens to this contract.
    /// @param from The address which previously owned the token.
    /// @param tokenId The ID of the token being transferred.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public returns (bytes4) {
        require(
            msg.sender == 0x6600a2c1dcb2ffA98a6D71F4Bf9e5b34173E6D36,
            "Only accepting deposits from the old Character collection"
        );

        uint256 id = 27 - tokenId;

        _transfer(address(this), from, id);

        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

contract TypeVVriter {
    /// @notice The SVG path definition for each character in the VV alphabet.
    mapping(string => string) public LETTERS;

    /// @notice Width in pixels for characters in the VV alphabet.
    mapping(string => uint256) public LETTER_WIDTHS;

    constructor() {
        initializeFont();
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a text as an SVG font inheriting text color and letter-spaced with 1px.
    /// @param text The text you want to write out.
    function write(string memory text) public view returns (string memory) {
        return write(text, "currentColor", 6);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a text as an SVG font with 1px space between letters.
    /// @param text The text you want to write out.
    /// @param color The SVG-compatible color code to use for the text.
    function write(string memory text, string memory color) public view returns (string memory) {
        return write(text, color, 6);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a given text as an SVG font in given `color` and letter `spacing`.
    /// @param text The text you want to write out.
    /// @param color The SVG-compatible color code to use for the text.
    /// @param spacing The space between letters in pixels.
    function write(
        string memory text,
        string memory color,
        uint256 spacing
    ) public view returns (string memory) {
        bytes memory byteText = upper(bytes(text));

        uint256 letterPos = 0;
        string memory letters = "";

        for (uint256 i = 0; i < byteText.length; i++) {
            bytes memory character = new bytes(1);
            character[0] = byteText[i];
            string memory normalized = string(character);

            string memory path = LETTERS[normalized];
            if (bytes(path).length <= 0) continue;

            letters = string(abi.encodePacked(
                letters,
                '<g transform="translate(', Strings.toString(letterPos), ')">',
                    '<path d="', path, '"/>',
                '</g>'
            ));

            uint256 width = LETTER_WIDTHS[normalized] == 0
                ? LETTER_WIDTHS["DEFAULT"]
                : LETTER_WIDTHS[normalized];

            letterPos = letterPos + width + spacing;
        }

        uint256 lineWidth = letterPos - spacing;
        string memory svg = string(abi.encodePacked(
            '<svg ',
                'viewBox="0 0 ', Strings.toString(lineWidth), ' 30" ',
                'width="', Strings.toString(lineWidth), '" height="30" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg"',
            '>',
                '<g fill-rule="evenodd" clip-rule="evenodd" fill="', color, '">',
                    letters,
                '</g>',
            '</svg>'
        ));

        return svg;
    }

    /// @dev Uppercase some byte text.
    function upper(bytes memory _text) internal pure returns (bytes memory) {
        for (uint i = 0; i < _text.length; i++) {
            _text[i] = _upper(_text[i]);
        }
        return _text;
    }

    /// @dev Uppercase a single byte letter.
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /// @dev Store all font assets on chain.
    function initializeFont() private {
        // Special
        LETTERS[" "] = "m0";

        // Signs
        LETTERS["*"] = "";
        LETTERS["="] = "";
        LETTERS["<"] = "";
        LETTERS[">"] = "";
        LETTERS[","] = "";
        LETTERS["."] = "";
        LETTERS[":"] = "";
        LETTERS[";"] = "";
        LETTERS["!"] = "";
        LETTERS["?"] = "";
        LETTERS["+"] = "";
        LETTERS["-"] = "";
        LETTERS["$"] = "";
        LETTERS["#"] = "";

        // Numbers
        LETTERS["0"] = "m16.667 2.758-1.371-1.423a1.132 1.132 0 0 0-.79-.335H2.452c-.29 0-.54.126-.748.335L.291 2.758c-.208.21-.291.46-.291.753v23.02c0 .293.083.544.291.753l1.413 1.423c.208.21.457.293.748.293h12.054c.291 0 .582-.084.79-.293l1.371-1.423c.208-.21.333-.46.333-.753V3.51c0-.293-.125-.544-.333-.753ZM12.76 24.06c0 .377-.332.67-.665.67h-7.19a.659.659 0 0 1-.665-.67V5.981c0-.377.29-.67.665-.67h7.19c.333 0 .665.293.665.67v18.08Z";
        LETTERS["1"] = "M9.943 24.737h-1.26c-.367 0-.61-.292-.61-.627V2.087C8.072 1.5 7.583 1 7.014 1H5.022c-.284 0-.57.125-.772.334L.305 5.346c-.407.46-.407 1.17 0 1.588l1.423 1.463c.407.418 1.098.418 1.546 0l.61-.669V24.11c0 .335-.285.627-.61.627H2.013c-.57 0-1.057.502-1.057 1.087v2.131c0 .585.488 1.045 1.057 1.045h7.93c.569 0 1.057-.46 1.057-1.045v-2.131c0-.585-.488-1.087-1.057-1.087Z";
        LETTERS["2"] = "M4.863 18.16h9.643c.291 0 .582-.126.79-.335l1.372-1.423c.207-.21.332-.46.332-.753V3.51c0-.293-.125-.544-.332-.753l-1.372-1.423a1.132 1.132 0 0 0-.79-.335H2.452c-.29 0-.54.126-.748.335L.291 2.758c-.208.21-.291.46-.291.753v5.65c0 .586.457 1.089 1.08 1.089h2.08c.582 0 1.08-.503 1.08-1.089V5.94c0-.335.292-.628.624-.628h7.232c.374 0 .665.293.665.628v7.282c0 .335-.29.628-.665.628H2.452c-.29 0-.54.126-.748.335L.291 15.607c-.208.21-.291.46-.291.753v10.17c0 .294.083.545.291.754l1.413 1.423c.208.21.457.293.748.293H15.92c.582 0 1.081-.46 1.081-1.088v-2.093c0-.586-.499-1.088-1.08-1.088H4.862a.641.641 0 0 1-.623-.628v-5.315a.64.64 0 0 1 .623-.628Z";
        LETTERS["3"] = "m16.876 12.342.041-.042c.041-.125.083-.293.083-.418v-8.37c0-.294-.124-.545-.332-.754l-1.41-1.423c-.207-.21-.455-.335-.746-.335H2.488c-.29 0-.54.126-.746.335L.332 2.758c-.208.21-.332.46-.332.753v5.65c0 .586.498 1.089 1.078 1.089h2.115c.58 0 1.078-.503 1.078-1.089V5.94c0-.335.249-.628.622-.628h7.214a.64.64 0 0 1 .622.628v4.98a.54.54 0 0 1-.166.419l-1.326 1.34a.663.663 0 0 1-.457.208H5.97c-.58 0-1.077.46-1.077 1.089v2.092c0 .628.497 1.088 1.078 1.088h4.81c.165 0 .331.084.456.21l1.326 1.297a.633.633 0 0 1 .166.46v4.981a.64.64 0 0 1-.622.628H4.893a.614.614 0 0 1-.622-.628V20.88c0-.585-.498-1.088-1.078-1.088H1.078c-.58 0-1.078.502-1.078 1.088v5.65c0 .294.124.545.332.754l1.41 1.423c.207.21.456.293.746.293h12.024c.29 0 .54-.084.746-.293l1.41-1.423c.208-.21.332-.46.332-.753V18.16c0-.168-.041-.293-.083-.419l-.041-.041-1.493-2.219c-.207-.293-.207-.627 0-.962l1.493-2.177Z";
        LETTERS["4"] = "M16.754 17.842a.66.66 0 0 1-.643-.669V2.087C16.11 1.5 15.596 1 14.953 1h-2.874c-.386 0-.772.209-.944.501L.2 18.385a.99.99 0 0 0-.043 1.128l1.158 2.048c.171.334.557.544.986.544h8.75a.66.66 0 0 1 .643.668v5.14c0 .627.515 1.087 1.158 1.087h2.102c.643 0 1.158-.46 1.158-1.087v-5.14c0-.376.3-.668.643-.668h3.13c.601 0 1.116-.502 1.116-1.087v-2.09c0-.585-.515-1.086-1.115-1.086h-3.131Zm-5.061-9.236v9.236H5.731l5.962-9.236Z";
        LETTERS["5"] = "M4.893 5.31H15.88A1.12 1.12 0 0 0 17 4.18V2.13A1.12 1.12 0 0 0 15.88 1H2.489c-.29 0-.54.126-.746.335L.332 2.758c-.208.21-.332.46-.332.753v10.17c0 .294.124.545.332.754l1.41 1.423c.207.21.455.293.746.293h9.578c.373 0 .663.335.663.67v7.24c0 .377-.29.67-.663.67H4.893c-.332 0-.622-.293-.622-.67v-2.176c0-.586-.498-1.088-1.12-1.088H1.12c-.621 0-1.119.502-1.119 1.088v4.646c0 .293.124.544.332.753l1.41 1.423c.207.21.455.293.746.293h12.024c.29 0 .54-.084.747-.293l1.41-1.423c.207-.21.331-.46.331-.753V14.393c0-.293-.124-.586-.332-.795l-1.41-1.381c-.207-.21-.456-.335-.746-.335h-9.62c-.331 0-.621-.293-.621-.67V5.981c0-.377.29-.67.622-.67Z";
        LETTERS["6"] = "m17.649 13.58-1.493-1.38a1.125 1.125 0 0 0-.79-.334H5.18a.667.667 0 0 1-.659-.669V5.931c0-.334.307-.627.659-.627h10.624c.614 0 1.141-.501 1.141-1.128V2.128c0-.627-.527-1.128-1.141-1.128H2.635c-.308 0-.572.125-.791.334L.351 2.755c-.22.21-.351.46-.351.752v22.985c0 .293.132.544.351.753l1.493 1.42c.22.21.483.335.79.335h12.732c.307 0 .57-.125.79-.334l1.493-1.421c.22-.21.351-.46.351-.753V14.373c0-.292-.132-.585-.351-.794Zm-4.171 3.217v7.23a.667.667 0 0 1-.658.668H5.18a.667.667 0 0 1-.658-.668v-7.23c0-.334.307-.669.659-.669h7.639c.35 0 .658.335.658.669Z";
        LETTERS["7"] = "m17.811 3.507-1.266-1.988c-.21-.303-.549-.519-.928-.519H1.097C.464 1 0 1.519 0 2.124v2.204c0 .605.464 1.124 1.097 1.124h10.721c.211 0 .422.086.507.302.126.173.168.432.084.605L2.406 29.654l-.085.216.211.13h3.715c.422 0 .844-.26 1.013-.692L17.896 4.544a1.016 1.016 0 0 0-.085-1.037Z";
        LETTERS["8"] = "m16.668 2.755-1.41-1.42c-.207-.21-.455-.335-.746-.335H2.488c-.29 0-.54.125-.747.334L.331 2.755c-.207.21-.331.46-.331.752v22.985c0 .293.124.544.332.753l1.41 1.42c.207.21.456.335.746.335h12.024c.29 0 .54-.125.747-.334l1.41-1.421c.207-.21.331-.46.331-.753V3.508c0-.292-.124-.543-.332-.752ZM12.066 12.87H4.893c-.332 0-.622-.293-.622-.669V5.973c0-.376.29-.669.622-.669h7.173c.373 0 .663.293.663.67V12.2c0 .376-.29.669-.663.669Zm-7.173 4.26h7.173c.373 0 .663.293.663.669v6.227c0 .376-.29.668-.663.668H4.893c-.332 0-.622-.292-.622-.668V17.8c0-.376.29-.669.622-.669Z";
        LETTERS["9"] = "m16.667 2.758-1.371-1.423a1.131 1.131 0 0 0-.79-.335H2.494a1.06 1.06 0 0 0-.79.335L.291 2.758c-.208.21-.291.46-.291.753V15.65c0 .293.083.586.29.795l1.414 1.381c.208.21.457.335.79.335h9.56c.374 0 .706.293.706.67v5.231c0 .377-.332.67-.706.67H2.078c-.623 0-1.122.502-1.122 1.13v2.05c0 .629.499 1.089 1.122 1.089h12.428c.291 0 .582-.084.79-.293l1.371-1.423c.208-.21.333-.46.333-.795V3.51c0-.293-.125-.544-.333-.753ZM12.76 13.179c0 .377-.332.67-.706.67h-7.15a.659.659 0 0 1-.664-.67V5.981c0-.377.29-.67.665-.67h7.149c.374 0 .706.293.706.67v7.198Z";

        // Letters
        LETTERS["A"] = "m19.917 10.181-.417-.997a.605.605 0 0 0-.25-.374l-7.458-7.436A1.112 1.112 0 0 0 10.958 1H9.042c-.292 0-.625.125-.834.374L.75 8.81c-.083.083-.208.208-.25.374l-.417.997a1.49 1.49 0 0 0-.083.457v17.157C0 28.46.542 29 1.208 29h1.834c.666 0 1.208-.54 1.208-1.205v-7.81a.82.82 0 0 1 .792-.79h9.916a.79.79 0 0 1 .792.79v7.81c0 .665.542 1.205 1.208 1.205h1.834c.666 0 1.208-.54 1.208-1.205V10.638c0-.166-.042-.332-.083-.457ZM10 5.902c.208 0 .417.083.542.25l4.958 4.943c.167.125.25.332.25.54v2.534c0 .457-.333.79-.792.79H5.042a.79.79 0 0 1-.792-.79v-2.534c0-.208.083-.415.25-.54l4.958-4.944c.167-.166.334-.249.542-.249Z";
        LETTERS["B"] = "M20.212 13.682a.609.609 0 0 0 .263-.377l.438-1.005c.087-.125.087-.293.087-.46V6.315c0-.167 0-.334-.087-.46l-.438-1.004c-.044-.126-.131-.293-.263-.377l-2.8-2.72-.393-.252-1.05-.418A2.343 2.343 0 0 0 15.488 1H2.668c-.35 0-.655.126-.874.377L.35 2.716c-.219.21-.35.502-.35.837V26.49c0 .293.131.586.35.837l1.444 1.34c.219.208.525.334.875.334h12.819c.13 0 .306 0 .48-.084l1.05-.418a1.05 1.05 0 0 0 .395-.251l2.8-2.679a.984.984 0 0 0 .262-.377l.438-1.004c.087-.168.087-.293.087-.46V18.16c0-.126 0-.293-.087-.46l-.438-1.005a.984.984 0 0 0-.263-.377l-.83-.795a.71.71 0 0 1 0-1.046l.83-.795ZM5.25 24.73c-.438 0-.787-.335-.787-.753v-6.07c0-.418.35-.753.787-.753h9.188c.175 0 .393.084.524.21l1.357 1.297a.679.679 0 0 1 .219.502v3.558c0 .21-.088.377-.22.502l-1.356 1.298a.827.827 0 0 1-.524.209H5.25Zm9.713-12.096a.695.695 0 0 1-.525.251H5.25c-.438 0-.787-.334-.787-.753v-6.11c0-.377.35-.712.787-.712h9.188c.175 0 .393.042.524.21l1.357 1.255c.131.167.219.335.219.544v3.516a.776.776 0 0 1-.22.544l-1.356 1.255Z";
        LETTERS["C"] = "M19.898 23.224a1.818 1.818 0 0 0-.428-.67c-.171-.25-.428-.418-.685-.543a1.8 1.8 0 0 0-.813-.21c-.342-.042-.685 0-.984.126a2.43 2.43 0 0 0-.77.502l-1.755 2.05a.854.854 0 0 1-.599.252H5.477a.854.854 0 0 1-.599-.251l-.257-.21a.987.987 0 0 1-.214-.585V6.357c0-.209.086-.418.214-.586l.257-.25c.171-.126.385-.21.6-.21h8.386c.214 0 .428.084.6.21l1.754 2.05c.128.167.3.293.47.377.214.125.471.209.728.25.342.085.684.085.984-.041a1.806 1.806 0 0 0 1.07-.67c.17-.209.342-.418.428-.67.085-.292.128-.627.085-.962a1.898 1.898 0 0 0-.642-1.256l-2.696-2.971A2.227 2.227 0 0 0 15.105 1H4.665a3.28 3.28 0 0 0-2.312.963L.941 3.302C.342 3.93 0 4.725 0 5.562V24.48c0 .837.342 1.632.941 2.26l1.412 1.34c.642.627 1.455.92 2.311.92h10.441c.6 0 1.155-.21 1.54-.586l2.696-2.972c.3-.293.514-.67.6-1.046.085-.418.085-.795-.043-1.172Z";
        LETTERS["D"] = "m19.917 5.813-.417-.92a1 1 0 0 0-.25-.461l-2.667-2.637a1.497 1.497 0 0 0-.416-.293l-.959-.376a1.105 1.105 0 0 0-.5-.126H2.583a1.29 1.29 0 0 0-.916.377L.375 2.674a1.3 1.3 0 0 0-.375.92v22.811c0 .377.125.712.375.963l1.292 1.255c.25.251.583.377.916.377h12.125c.167 0 .334 0 .5-.084l.959-.418a.864.864 0 0 0 .416-.251l2.667-2.679a.87.87 0 0 0 .25-.419l.417-.962c.083-.168.083-.335.083-.502V6.315c0-.167 0-.334-.083-.502ZM15.75 22.638c0 .251-.083.46-.25.628l-1.208 1.214a.846.846 0 0 1-.625.25H5.125a.882.882 0 0 1-.875-.878V6.148c0-.46.417-.837.875-.837h8.542c.25 0 .458.084.625.251L15.5 6.734c.167.167.25.377.25.628v15.276Z";
        LETTERS["E"] = "M5.353 5.27h12.33C18.43 5.27 19 4.682 19 4.012V2.256C19 1.544 18.43 1 17.684 1H2.72c-.352 0-.703.126-.966.377L.395 2.674c-.263.251-.395.544-.395.88v22.851c0 .335.132.67.395.92l1.36 1.298c.263.251.615.377.966.377h14.963C18.43 29 19 28.414 19 27.744v-1.758c0-.711-.57-1.297-1.316-1.297H5.354c-.483 0-.878-.335-.878-.795V17.95c0-.46.395-.837.877-.837h10.268c.702 0 1.317-.544 1.317-1.256V14.1c0-.67-.615-1.255-1.317-1.255H5.353c-.482 0-.877-.377-.877-.838v-5.9c0-.461.395-.838.877-.838Z";
        LETTERS["F"] = "M2.577 1c-.332 0-.665.167-.873.376L.374 2.713c-.25.21-.374.544-.374.878v24.155C0 28.456.582 29 1.247 29h1.83c.664 0 1.205-.543 1.205-1.254v-9.82c0-.418.332-.795.748-.795h9.81a1.21 1.21 0 0 0 1.206-1.212v-1.838a1.21 1.21 0 0 0-1.205-1.212H5.03c-.416 0-.748-.377-.748-.794V6.099c0-.46.332-.795.748-.795h11.764A1.21 1.21 0 0 0 18 4.093v-1.84C18 1.586 17.46 1 16.794 1H2.577Z";
        LETTERS["G"] = "M19.667 14.602 18.25 13.18c-.208-.209-.458-.293-.75-.293h-6.583a1.08 1.08 0 0 0-1.084 1.089v2.092c0 .586.459 1.088 1.084 1.088h4.166c.334 0 .625.293.625.67v4.939a.631.631 0 0 1-.166.46l-1.334 1.34a.625.625 0 0 1-.458.167H6.208a.625.625 0 0 1-.458-.168l-1.333-1.339a.631.631 0 0 1-.167-.46V7.278a.63.63 0 0 1 .167-.46l1.333-1.34a.625.625 0 0 1 .458-.167h7.542c.167 0 .333.042.458.167l1.875 1.926c.209.209.5.293.792.293.292 0 .583-.084.75-.293l1.5-1.507c.208-.21.292-.46.292-.753s-.084-.586-.292-.796l-2.583-2.595c-.125-.083-.209-.167-.375-.209l-1-.46C15 1.042 14.875 1 14.75 1h-9.5c-.167 0-.292.042-.417.084l-1.041.46c-.125.042-.25.126-.375.21L.708 4.473A1.704 1.704 0 0 0 .5 4.85L.083 5.897C0 6.022 0 6.148 0 6.315v17.412c0 .167 0 .292.083.418L.5 25.191c.042.126.125.251.208.377l2.709 2.72c.125.084.25.168.375.21l1.041.46c.125.042.25.042.417.042h9.5c.125 0 .25 0 .417-.042l1-.46c.166-.042.25-.126.375-.21l2.708-2.72c.083-.126.167-.251.208-.377l.459-1.046c.041-.126.083-.251.083-.418v-8.33a1.15 1.15 0 0 0-.333-.795Z";
        LETTERS["H"] = "M16.917 1c-.667 0-1.167.542-1.167 1.208v9.917c0 .417-.375.75-.792.75H5a.747.747 0 0 1-.75-.75V2.208A1.21 1.21 0 0 0 3.042 1H1.167C.542 1 0 1.542 0 2.208v25.625C0 28.458.542 29 1.167 29h1.875c.666 0 1.208-.542 1.208-1.167v-9.958c0-.417.333-.75.75-.75h9.958c.417 0 .792.333.792.75v9.958c0 .625.5 1.167 1.167 1.167h1.875c.666 0 1.208-.542 1.208-1.167V2.208A1.21 1.21 0 0 0 18.792 1h-1.875Z";
        LETTERS["I"] = "M8.866 5.27h1.938c.66 0 1.196-.545 1.196-1.215V2.214C12 1.544 11.464 1 10.804 1H1.196C.536 1 0 1.544 0 2.214v1.841c0 .67.536 1.214 1.196 1.214h1.938c.412 0 .742.335.742.795v17.872c0 .418-.33.795-.742.795H1.196c-.66 0-1.196.544-1.196 1.214v1.841C0 28.456.536 29 1.196 29h9.608c.66 0 1.196-.544 1.196-1.214v-1.841c0-.67-.536-1.214-1.196-1.214H8.866c-.412 0-.742-.377-.742-.795V6.064c0-.46.33-.795.742-.795Z";
        LETTERS["J"] = "M17.794 1h-1.829c-.707 0-1.247.544-1.247 1.214v20.675c0 .042 0 .586-.291 1.089-.208.376-.54.753-1.497.753H6.07c-.998 0-1.289-.377-1.497-.753a2.677 2.677 0 0 1-.332-1.089v-5.86a1.21 1.21 0 0 0-1.206-1.213h-1.83A1.21 1.21 0 0 0 0 17.03v5.901c0 .251.042 1.549.707 2.93C1.747 27.87 3.617 29 6.07 29h6.86c2.453 0 4.324-1.13 5.322-3.139.706-1.381.748-2.679.748-2.93V2.214C19 1.544 18.46 1 17.794 1Z";
        LETTERS["K"] = "M19.785 27.188 10.12 14.42a.74.74 0 0 1 .041-.906l8.55-9.35c.207-.206.29-.494.29-.824a1.222 1.222 0 0 0-.414-.782L17.1 1.28c-.495-.412-1.28-.37-1.693.123L5.7 12.031c-.248.288-.578.288-.826.206a.73.73 0 0 1-.496-.7v-8.98c0-.617-.537-1.153-1.197-1.153H1.198C.537 1.404 0 1.94 0 2.558v25.248c0 .659.537 1.153 1.198 1.153H3.18c.66 0 1.197-.494 1.197-1.153v-7.661c0-.165.083-.33.207-.495l1.61-1.77a.816.816 0 0 1 .58-.248c.247.041.453.124.577.33l7.972 10.585c.207.288.579.453.992.453h2.478c.454 0 .867-.206 1.074-.618.206-.37.165-.824-.083-1.194Z";
        LETTERS["L"] = "M17.742 24.73H5.249c-.434 0-.824-.334-.824-.752V2.214C4.425 1.544 3.86 1 3.167 1H1.258C.564 1 0 1.544 0 2.214v24.275c0 .293.13.628.347.837l1.388 1.34c.26.208.564.334.911.334h15.096c.694 0 1.258-.502 1.258-1.172v-1.883c0-.67-.564-1.214-1.258-1.214Z";
        LETTERS["M"] = "m21.207 1.74-2.171-.676a1.07 1.07 0 0 0-1.294.464l-6.137 8.904a.665.665 0 0 1-.584.338.734.734 0 0 1-.626-.338L4.3 1.528a1.125 1.125 0 0 0-1.336-.464l-2.13.675C.335 1.908 0 2.33 0 2.88v24.94C0 28.493.543 29 1.169 29h1.92c.668 0 1.169-.506 1.169-1.182V11.445c0-.38.292-.633.543-.675.25-.085.584-.085.835.253l3.34 4.895c.208.338.584.507.96.507h2.129c.417 0 .75-.17 1.001-.507l3.34-4.895c.209-.338.585-.338.835-.253.25.042.501.295.501.675v16.373c0 .676.543 1.182 1.169 1.182h1.92C21.5 29 22 28.494 22 27.818V2.878c0-.548-.334-.97-.793-1.139Z";
        LETTERS["N"] = "M18.917 1h-2.084c-.583 0-1.083.5-1.083 1.168v15.607c0 .417-.292.668-.5.71-.208.083-.542 0-.708-.293L4.292 1.584a1.362 1.362 0 0 0-.625-.459 1.108 1.108 0 0 0-.5-.125H1.083C.5 1 0 1.5 0 2.168v25.664C0 28.499.5 29 1.083 29h2.084c.583 0 1.083-.5 1.083-1.168V12.225c0-.417.292-.626.5-.71.25-.041.542 0 .708.293L15.75 28.416c.125.25.333.375.583.459.167.083.334.125.5.125h2.084C19.5 29 20 28.5 20 27.832V2.168C20 1.501 19.5 1 18.917 1Z";
        LETTERS["O"] = "m19.875 5.813-.375-.962a1.503 1.503 0 0 0-.292-.419l-2.666-2.679c-.084-.125-.25-.209-.375-.25l-1-.42A1.492 1.492 0 0 0 14.708 1H5.292c-.167 0-.334.042-.5.084l-.959.418a.864.864 0 0 0-.416.251L.75 4.432a1.503 1.503 0 0 0-.292.419l-.375.962C0 5.981 0 6.148 0 6.315v17.37c0 .167 0 .334.083.46l.375 1.005c.084.125.167.292.292.418l2.667 2.637c.125.125.25.209.416.293l.959.418c.166.042.333.084.5.084h9.416c.167 0 .334-.042.459-.084l1-.418c.125-.084.291-.168.375-.293l2.666-2.637c.125-.126.209-.293.292-.419l.375-1.004a.847.847 0 0 0 .125-.46V6.315c0-.167-.042-.334-.125-.502Zm-6.208 18.918H6.292a.82.82 0 0 1-.584-.251L4.5 23.224a.676.676 0 0 1-.25-.544V7.32c0-.21.083-.419.25-.586L5.708 5.52a.82.82 0 0 1 .584-.25h7.375c.25 0 .458.083.583.25l1.25 1.214c.125.167.208.377.208.586v15.36c0 .21-.083.419-.208.544l-1.25 1.256c-.125.167-.333.25-.583.25Z";
        LETTERS["P"] = "m19.875 5.813-.375-.962a1.503 1.503 0 0 0-.292-.419l-2.625-2.679c-.125-.083-.291-.209-.416-.25l-.959-.42a2.082 2.082 0 0 0-.5-.083H2.583c-.375 0-.708.126-.958.377L.375 2.674c-.25.251-.375.544-.375.92v24.067C0 28.414.583 29 1.292 29h1.666c.709 0 1.292-.586 1.292-1.34v-8.663c0-.46.375-.879.875-.879h9.583c.167 0 .334-.042.5-.084l.959-.418c.125-.042.291-.168.416-.293l2.625-2.637c.125-.126.209-.251.292-.418l.375-.963c.083-.168.125-.335.125-.502V6.315c0-.167-.042-.334-.125-.502Zm-4.125 5.943c0 .252-.125.46-.292.628l-1.166 1.214a.846.846 0 0 1-.625.251H5.125a.882.882 0 0 1-.875-.879V6.148c0-.46.375-.879.875-.879h8.542c.25 0 .458.084.625.251l1.166 1.214c.167.167.292.377.292.628v4.394Z";
        LETTERS["Q"] = "m20.613 26.53-2.147-2.099 1.331-1.328c.13-.128.215-.257.301-.428l.43-.985c.043-.172.085-.343.085-.514V6.44c0-.171-.043-.343-.085-.514l-.43-.985a1.537 1.537 0 0 0-.3-.428L17.091 1.77a1.145 1.145 0 0 0-.43-.257l-.987-.428C15.503 1 15.33 1 15.159 1H5.454c-.172 0-.343 0-.515.086l-.988.428a.892.892 0 0 0-.43.257L.773 4.513a.888.888 0 0 0-.258.428l-.43.985C.044 6.097 0 6.27 0 6.44v17.777c0 .172.043.343.086.471l.43 1.028c.042.129.128.3.257.386l2.748 2.741c.13.129.258.215.43.3l.988.429c.171.043.343.085.515.085h6.657c.171 0 .343-.043.515-.085l.988-.429c.171-.085.3-.171.429-.3l1.331-1.328 2.104 2.142c.258.257.602.343.945.343.344 0 .645-.086.902-.343l1.288-1.285c.215-.257.387-.557.387-.9 0-.342-.172-.685-.387-.942Zm-10.478-6.04c-.258.215-.386.557-.386.9 0 .343.128.685.386.9l2.147 2.141-.601.6a1.028 1.028 0 0 1-.601.214H6.485c-.215 0-.43-.085-.602-.214l-1.245-1.285c-.172-.129-.258-.343-.258-.6V7.468c0-.214.086-.428.258-.6l1.245-1.242a.849.849 0 0 1 .602-.257h7.644c.215 0 .43.086.601.257l1.245 1.243a.845.845 0 0 1 .258.6v12.679a.845.845 0 0 1-.258.6l-.6.556-2.148-2.099c-.215-.257-.558-.385-.902-.385-.343 0-.687.128-.902.385l-1.288 1.285Z";
        LETTERS["R"] = "M19.757 27.161 13.2 18.092h1.277c.17 0 .298 0 .469-.083l1.022-.418c.127-.042.255-.125.383-.25l2.725-2.675a.987.987 0 0 0 .255-.376l.426-1.003a.94.94 0 0 0 .128-.46v-5.6a.775.775 0 0 0-.085-.334l-.298-.878c-.043-.125-.085-.25-.17-.334l-2.768-3.636a1.079 1.079 0 0 0-.426-.335l-1.15-.585A1.197 1.197 0 0 0 14.435 1H2.555c-.298 0-.596.125-.852.334L.341 2.714c-.256.208-.341.5-.341.835v24.24c0 .626.51 1.17 1.192 1.17h1.959c.639 0 1.192-.544 1.192-1.17v-9.697h3.45L15.2 28.5c.213.334.596.501.98.501h2.597c.468 0 .894-.209 1.107-.627.17-.376.17-.878-.128-1.212ZM13.455 13.83H5.067c-.383 0-.724-.335-.724-.71V6.014c0-.418.34-.752.724-.752H13.2a.75.75 0 0 1 .596.292l1.575 2.048a.83.83 0 0 1 .128.46v3.76a.686.686 0 0 1-.213.502l-1.32 1.296a.712.712 0 0 1-.51.209Z";
        LETTERS["S"] = "m19.917 17.7-.417-.963a.87.87 0 0 0-.25-.419l-2.667-2.678a.864.864 0 0 0-.416-.251l-.959-.419a2.068 2.068 0 0 0-.5-.084H6.292a.67.67 0 0 1-.542-.25L4.5 11.38a.676.676 0 0 1-.25-.544V7.32c0-.21.083-.377.25-.544L5.75 5.52a.79.79 0 0 1 .542-.21H18.25c.667 0 1.208-.543 1.208-1.255v-1.8c0-.669-.541-1.255-1.208-1.255H5.292a.837.837 0 0 0-.459.126l-1 .376a1.497 1.497 0 0 0-.416.293L.75 4.474c-.083.125-.208.251-.25.377L.083 5.855c-.041.167-.083.293-.083.46v5.525c0 .168.042.335.083.502l.417.963c.042.167.167.293.25.418l2.667 2.68c.125.083.25.208.416.25l1 .419c.125.042.292.084.459.084h8.416a.67.67 0 0 1 .542.25l1.25 1.214c.167.168.25.377.25.586v3.474c0 .21-.083.419-.25.586l-1.25 1.256a.79.79 0 0 1-.542.209H1.792a1.23 1.23 0 0 0-1.25 1.255v1.8c0 .67.541 1.214 1.25 1.214h12.916c.167 0 .334 0 .5-.084l.959-.418a.864.864 0 0 0 .416-.251l2.667-2.679a.99.99 0 0 0 .25-.377l.417-1.004c.041-.168.083-.293.083-.46v-5.525c0-.168-.042-.335-.083-.503Z";
        LETTERS["T"] = "M20.877 1H1.123C.499 1 0 1.502 0 2.13v2.01c0 .628.5 1.172 1.123 1.172h7.07c.374 0 .665.293.665.67V27.87c0 .628.5 1.13 1.123 1.13h2.038c.624 0 1.123-.502 1.123-1.13V5.98c0-.376.29-.67.665-.67h7.07c.624 0 1.123-.542 1.123-1.17V2.13C22 1.502 21.501 1 20.877 1Z";
        LETTERS["U"] = "M17.75 1H16c-.708 0-1.25.585-1.25 1.296v20.56c0 .042-.042.628-.292 1.13-.208.375-.541.71-1.5.71H6.042c-.959 0-1.292-.335-1.5-.71-.25-.502-.292-1.088-.292-1.088V2.296C4.25 1.586 3.667 1 3 1H1.25C.542 1 0 1.585 0 2.296v20.602c0 .251 0 1.547.708 2.926C1.708 27.872 3.625 29 6.042 29h6.916c2.417 0 4.334-1.128 5.334-3.176.666-1.38.708-2.675.708-2.926V2.296C19 1.586 18.458 1 17.75 1Z";
        LETTERS["V"] = "M15.75 1.866v16.581a.834.834 0 0 1-.25.619l-4.875 4.781a.841.841 0 0 1-1.25 0L4.5 19.066c-.125-.165-.25-.371-.25-.619V1.866A.85.85 0 0 0 3.375 1h-2.5A.85.85 0 0 0 0 1.866V19.56c0 .083.042.206.083.33l.459 1.072a.663.663 0 0 0 .166.288l7.584 7.503a.924.924 0 0 0 .625.247h2.166c.25 0 .459-.082.625-.247l7.584-7.503c.083-.082.125-.165.208-.288l.458-1.072c.042-.124.042-.247.042-.33V1.866A.85.85 0 0 0 19.125 1h-2.5a.85.85 0 0 0-.875.866Z";
        LETTERS["W"] = "m25.076 1.173-2.093-.163c-.544-.08-1.004.325-1.046.853l-1.298 16.941a.706.706 0 0 1-.586.65c-.25.04-.628 0-.795-.365L15.03 11.37a.964.964 0 0 0-.837-.528h-2.386c-.377 0-.67.203-.837.528l-4.228 7.718c-.209.365-.544.406-.795.365a.705.705 0 0 1-.628-.65L4.063 1.864c-.041-.529-.502-.935-1.046-.854l-2.135.163a.932.932 0 0 0-.879 1.015L2.013 27.7c.041.406.376.731.753.853L5.152 29h.167c.377 0 .712-.163.88-.487L12.35 17.26a.694.694 0 0 1 .628-.366c.293 0 .544.122.67.366l6.153 11.252A.993.993 0 0 0 20.85 29l2.344-.447c.418-.122.753-.447.795-.853l2.01-25.512c.041-.528-.378-.975-.922-1.015Z";
        LETTERS["X"] = "M20.29 7.697a.61.61 0 0 0 .25-.377l.377-.963c.083-.125.083-.293.083-.46V2.214C21 1.544 20.457 1 19.79 1h-1.838c-.668 0-1.21.544-1.21 1.214v2.72c0 .21-.084.419-.21.544l-5.468 5.818c-.126.126-.334.251-.543.251-.25 0-.418-.126-.585-.251L4.467 5.478a.797.797 0 0 1-.209-.544v-2.72c0-.67-.542-1.214-1.21-1.214H1.21C.543 1 0 1.544 0 2.214v3.683c0 .167 0 .335.084.46l.375.963a.61.61 0 0 0 .25.377l6.347 6.78a.734.734 0 0 1 0 1.046L.71 22.303a.61.61 0 0 0-.25.377l-.376.963c-.084.125-.084.293-.084.46v3.683C0 28.456.543 29 1.21 29h1.838c.668 0 1.21-.544 1.21-1.214v-2.72c0-.21.084-.377.21-.544l5.468-5.818a.904.904 0 0 1 .585-.21c.209 0 .417.084.543.21l5.469 5.818c.125.167.208.335.208.544v2.72c0 .67.543 1.214 1.211 1.214h1.837c.668 0 1.211-.544 1.211-1.214v-3.683c0-.167 0-.335-.084-.46l-.375-.963a.61.61 0 0 0-.25-.377l-6.347-6.78a.734.734 0 0 1 0-1.046l6.346-6.78Z";
        LETTERS["Y"] = "M18.833 1h-1.875c-.666 0-1.208.544-1.208 1.214V8.45c0 .293-.125.502-.375.67l-4.958 3.097c-.25.167-.584.167-.792 0l-5-3.097c-.208-.168-.375-.377-.375-.67V2.214C4.25 1.544 3.75 1 3.083 1H1.208C.542 1 0 1.544 0 2.214V9.83c0 .168.042.377.167.586l.625 1.172c.125.167.25.335.416.418l6.334 3.977a.739.739 0 0 1 .333.627v11.217c0 .628.542 1.172 1.208 1.172h1.875c.667 0 1.167-.544 1.167-1.172V16.611c0-.25.167-.502.375-.627l6.292-3.976c.166-.084.333-.252.416-.42l.667-1.171A1.65 1.65 0 0 0 20 9.831V2.214C20 1.544 19.458 1 18.833 1Z";
        LETTERS["Z"] = "M19.825 4.809c.204-.335.245-.754.041-1.089l-1.06-2.134c-.163-.335-.53-.586-.896-.586H2.627c-.57 0-1.019.46-1.019 1.046v2.219c0 .586.449 1.046 1.02 1.046h10.595c.245 0 .408.125.53.293.082.21.082.46-.04.628L.181 25.233A1.145 1.145 0 0 0 .1 26.321l1.1 2.135a.964.964 0 0 0 .897.544h16.79c.53 0 .978-.46.978-1.005v-2.218c0-.586-.448-1.046-.978-1.046H6.743a.53.53 0 0 1-.489-.335c-.122-.167-.081-.418.041-.586l13.53-19";

        // Letter Widths
        LETTER_WIDTHS["DEFAULT"] = 20;
        LETTER_WIDTHS[" "] = 10;
        LETTER_WIDTHS["0"] = 17;
        LETTER_WIDTHS["1"] = 11;
        LETTER_WIDTHS["2"] = 17;
        LETTER_WIDTHS["3"] = 17;
        LETTER_WIDTHS["4"] = 21;
        LETTER_WIDTHS["5"] = 17;
        LETTER_WIDTHS["6"] = 18;
        LETTER_WIDTHS["7"] = 18;
        LETTER_WIDTHS["8"] = 17;
        LETTER_WIDTHS["9"] = 17;
        LETTER_WIDTHS["B"] = 21;
        LETTER_WIDTHS["E"] = 19;
        LETTER_WIDTHS["F"] = 18;
        LETTER_WIDTHS["I"] = 12;
        LETTER_WIDTHS["J"] = 19;
        LETTER_WIDTHS["L"] = 19;
        LETTER_WIDTHS["M"] = 22;
        LETTER_WIDTHS["Q"] = 21;
        LETTER_WIDTHS["T"] = 22;
        LETTER_WIDTHS["U"] = 19;
        LETTER_WIDTHS["W"] = 26;
        LETTER_WIDTHS["X"] = 21;
    }
}