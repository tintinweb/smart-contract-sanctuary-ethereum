// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract IUnipeeps {
  enum Group {
      Design,
      Engineering,
      Executive,
      Legal,
      Operations,
      Product,
      Strategy
  }

  struct Peep {
      string first;
      string last;
      Group group;
      string role;
      string startDate;
      uint8 number;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './IUnipeeps.sol';
import './UnipeepsSVG.sol';
import 'base64-sol/base64.sol';

contract Unipeeps is ERC721, IUnipeeps {
    using Strings for *;

    error NonexistentTokenID(uint256 invalidId);

    UnipeepsSVG immutable svgContract;

    mapping(uint8 => Peep) peeps;

    constructor(
        string memory name_,
        string memory symbol_,
        address mintTo,
        UnipeepsSVG _svgContract,
        Peep[] memory _peeps
    ) ERC721(name_, symbol_) {
        svgContract = _svgContract;

        for (uint8 i = 0; i < _peeps.length; i++) {
            peeps[_peeps[i].number] = _peeps[i];
            _mint(mintTo, i);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentTokenID(tokenId);
        Peep memory peep = peeps[uint8(tokenId)];
        return
    string(
        abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"',
                        'UL ',
                        peep.number.toString(),
                        '/47'
                        '", "description":"',
                        'Commemorative NFTs for Uniswap Labs employees',
                        '", "image": "',
                        generateSVGURL(peep),
                        '"}'
                    )
                )
            )
        )
    );
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(generateSVGURL(peep))));
    }

    function generateSVGURL(Peep memory peep) internal view returns (bytes memory) {
        return abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svgContract.interpolateSVG(peep)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/utils/Strings.sol';
import './IUnipeeps.sol';

contract UnipeepsSVG {
    using Strings for *;

    struct Attributes {
        string color1;
        string color2;
        string color3;
        string coord1;
        string coord2;
        string coord3;
        string coord4;
    }

    mapping(uint8 => uint24[3][2]) colorMappings;

    constructor(uint24[3][2][7] memory _colorMappings) {
        for (uint8 i = 0; i < 7; i++) {
            colorMappings[i] = _colorMappings[i];
        }
    }

    function interpolateSVG(IUnipeeps.Peep memory peep) external view returns (bytes memory SVG) {
        uint256 numberHash1 = uint256(keccak256(abi.encode(peep.first)));
        uint256 numberHash2 = uint256(keccak256(abi.encode(peep.last)));
        string memory color1 = toHexStringNoPrefix(colorMappings[uint8(peep.group)][1][numberHash1 % uint8(3)], 3);
        string memory color2 = toHexStringNoPrefix(colorMappings[uint8(peep.group)][0][numberHash2 % uint8(3)], 3);
        string memory color3 = uint256(uint256(keccak256(abi.encodePacked(peep.first, peep.last))) % 360).toString();

        string memory coord1;
        string memory coord2;
        string memory coord3;
        string memory coord4;
        unchecked {
            coord1 = intToString(int256((numberHash1**numberHash2) % 190) - 50);
            coord2 = intToString(int256((numberHash2 + numberHash2) % 230) - 170);
            coord3 = intToString(int256((numberHash2 * numberHash2) % 190) - 10);
            coord4 = intToString(int256((numberHash1 % numberHash2) % 230));
        }

        return svgString(peep, Attributes(color1, color2, color3, coord1, coord2, coord3, coord4));
    }

    function svgString(IUnipeeps.Peep memory peep, Attributes memory attributes)
        internal
        pure
        returns (bytes memory SVG)
    {
        return
            abi.encodePacked(
                '<svg version="1.1" width="375" height="636" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 424" font-family="\'Inter\', sans-serif"><style>@import url(\'https://fonts.googleapis.com/css2?family=Inter:[email protected];300;500\');</style><defs><mask id="card"><rect width="100%" height="100%" fill="white" rx="4"/></mask><mask id="firstName"><text fill="white" x="16" y="330" font-size="36" font-weight="100" text-anchor="start">',
                peep.first,
                '</text></mask><mask id="lastName"><text fill="white" x="16" y="368" font-size="36" font-weight="100" text-anchor="start">',
                peep.last,
                '</text></mask><mask id="role"><text x="16" y="400" font-size="10" font-weight="300" text-anchor="start" fill="white">',
                peep.role,
                '</text></mask><mask id="joinDate"><text x="234" y="400" font-size="10" font-weight="300" text-anchor="end" fill="white">',
                peep.startDate,
                '</text></mask><mask id="title"><text x="16" y="32" font-size="12" font-family="sans-serif" font-weight="500" text-anchor="start" fill="none" stroke="white" stroke-width="0.5">UNISWAP LABS</text></mask><mask id="year"><text x="234" y="32" font-size="12" font-family="sans-serif" font-weight="500" text-anchor="end" fill="none" stroke="white" stroke-width="0.5">2022</text></mask><mask id="number"><text x="16" y="32" dy="4%" font-size="12" font-family="sans-serif" font-weight="500" text-anchor="start" fill="none" stroke="white" stroke-width="0.5">',
                peep.number.toString(),
                svgCenter(attributes),
                peep.number.toString(),
                '/47</text></g><g font-size="36" font-weight="lighter" text-anchor="start" fill="rgba(0,0,0,0.25)"><text mask="url(#firstName)" x="16" y="330" filter="url(#sh)">',
                peep.first,
                '</text><text mask="url(#lastName)" x="16" y="368" filter="url(#sh)">',
                peep.last,
                '</text></g><line x1="16" y1="382" x2="234" y2="382" stroke="rgba(0,0,0,0.25)" stroke-width="0.5" /><g font-size="10" fill="rgba(0,0,0,0.25)" font-weight="300"><text mask="url(#role)" x="16" y="400" text-anchor="start" filter="url(#sh)">',
                peep.role,
                '</text><text mask="url(#joinDate)" x="234" y="400" text-anchor="end" filter="url(#sh)">',
                peep.startDate,
                '</text></g></g></svg>'
            );
    }

    function svgCenter(Attributes memory attributes) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '/47</text></mask><mask id="border1"><rect width="234" height="408" x="8" y="8" stroke="white" /></mask><mask id="border2"><rect width="234" height="408" x="8" y="8" rx="24" stroke="white" /></mask><mask id="glimmer"><path d="M125.578 168V167.75H125.328H125.017H124.767V168L124.767 196.769C124.767 205.052 118.052 211.767 109.769 211.767L81 211.767H80.75V212.017V212.328V212.578H81L123.24 212.578V256.5V256.75H123.49H123.802H124.052V256.5V227.731C124.052 219.448 130.766 212.733 139.049 212.733H167.818H168.068V212.483V212.172V211.922H167.818H125.578L125.578 168Z" stroke="white" stroke-opacity="0.5" stroke-width="0.5"/></mask><mask id="circle"><circle cx="100" cy="220" r="40" fill="none" stroke="white" stroke-width="0.5" stroke-opacity="0.5"/></mask><mask id="star" maskUnits="objectBoundingBox"><path d="M37.25 0.99814L36.75 1C36.75 8.15363 36.3084 13.7289 35.3544 17.7352C34.3969 21.7566 32.9413 24.1209 30.9801 24.9763C29.0267 25.8284 26.4522 25.233 23.1202 23.0162C22.1515 22.3717 21.1245 21.5939 20.0373 20.6824C17.8024 18.0218 14.7895 15.0198 11.0032 11.6503L10.6503 12.0032C14.0198 15.7895 17.0218 18.8024 19.6824 21.0373C20.5939 22.1245 21.3717 23.1515 22.0162 24.1202C24.233 27.4522 24.8284 30.0267 23.9763 31.9801C23.1209 33.9413 20.7566 35.3969 16.7352 36.3544C12.7289 37.3084 7.15363 37.75 0 37.75V38V38.25C7.15363 38.25 12.7289 38.6916 16.7352 39.6456C20.7566 40.6031 23.1209 42.0587 23.9763 44.0199C24.8285 45.9733 24.233 48.5478 22.0162 51.8798C21.3717 52.8485 20.5939 53.8755 19.6824 54.9627C17.0218 57.1975 14.0198 60.2105 10.6503 63.9967L11.0032 64.3497C14.7895 60.9802 17.8025 57.9782 20.0373 55.3176C21.1245 54.4061 22.1515 53.6283 23.1202 52.9838C26.4522 50.767 29.0267 50.1715 30.9801 51.0237C32.9413 51.8791 34.3969 54.2434 35.3544 58.2648C36.3084 62.2711 36.75 67.8464 36.75 75L37.25 75.0019C37.3033 67.8367 37.7617 62.2626 38.7135 58.2626C39.6692 54.2467 41.1038 51.8959 43.041 51.0507C44.9704 50.209 47.5193 50.8108 50.8433 53.0264C51.8835 53.7196 52.9926 54.5664 54.1737 55.5671C56.3859 58.1655 59.3283 61.0851 62.9967 64.3497L63.3486 63.9955C60.0579 60.3478 57.1275 57.4178 54.5281 55.2121C53.5253 54.0322 52.6773 52.9223 51.9838 51.8798C49.767 48.5478 49.1715 45.9733 50.0237 44.0199C50.8791 42.0587 53.2434 40.6031 57.2648 39.6456C61.2711 38.6916 66.8464 38.25 74 38.25L74.0019 37.75C66.8367 37.6967 61.2626 37.2383 57.2626 36.2865C53.2467 35.3308 50.8959 33.8962 50.0507 31.959C49.209 30.0296 49.8108 27.4807 52.0264 24.1567C52.7711 23.0394 53.693 21.8424 54.7924 20.5622C57.3257 18.3837 60.1689 15.5292 63.3486 12.0045L62.9955 11.6514C59.4708 14.8311 56.6163 17.6743 54.4378 20.2076C53.1576 21.307 51.9606 22.2289 50.8433 22.9736C47.5193 25.1892 44.9704 25.791 43.041 24.9493C41.1038 24.1041 39.6692 21.7532 38.7135 17.7374C37.7617 13.7374 37.3033 8.16332 37.25 0.99814Z" stroke="white" stroke-width="0.5" stroke-opacity="0.5" /></mask><filter id="sh" x="0%" y="0%" width="100%" height="100%" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="1"/><feGaussianBlur stdDeviation="0.5"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.54 0"/><feBlend mode="normal" in2="shape" result="effect1_sh_1_537"/></filter><filter id="blur" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB"><feGaussianBlur stdDeviation="20" result="out"/><feGaussianBlur stdDeviation="20" result="out"/></filter><linearGradient id="backgroundGradient" x1="124" y1="245.012" x2="124" y2="424" gradientUnits="userSpaceOnUse"><stop stop-color="#',
                attributes.color1,
                '"/><stop offset="1" stop-color="#',
                attributes.color2,
                '"/></linearGradient></defs><g overflow="hidden" mask="url(#card)"><rect width="100%" height="100%" fill="url(#backgroundGradient)" rx="4"/><g filter="url(#blur)"><circle cx="120" r="160" fill="hsl(',
                attributes.color3,
                ',100%,90%)" /></g><g><path mask="url(#glimmer)" filter="url(#sh)" d="M125.578 168V167.75H125.328H125.017H124.767V168L124.767 196.769C124.767 205.052 118.052 211.767 109.769 211.767L81 211.767H80.75V212.017V212.328V212.578H81L123.24 212.578V256.5V256.75H123.49H123.802H124.052V256.5V227.731C124.052 219.448 130.766 212.733 139.049 212.733H167.818H168.068V212.483V212.172V211.922H167.818H125.578L125.578 168Z" stroke="black" stroke-opacity="0.24" stroke-width="0.5" style="mix-blend-mode:multiply"/></g><g transform="translate(',
                attributes.coord1,
                ' ',
                attributes.coord2,
                ')"><circle mask="url(#circle)" filter="url(#sh)" fill="none" cx="100" cy="220" r="40" stroke="black" stroke-opacity="0.24" stroke-width="0.5" style="mix-blend-mode:multiply"/></g><g transform="translate(',
                attributes.coord3,
                ' ',
                attributes.coord4,
                ')"><path mask="url(#star)" filter="url(#sh)" d="M37.25 0.99814L36.75 1C36.75 8.15363 36.3084 13.7289 35.3544 17.7352C34.3969 21.7566 32.9413 24.1209 30.9801 24.9763C29.0267 25.8284 26.4522 25.233 23.1202 23.0162C22.1515 22.3717 21.1245 21.5939 20.0373 20.6824C17.8024 18.0218 14.7895 15.0198 11.0032 11.6503L10.6503 12.0032C14.0198 15.7895 17.0218 18.8024 19.6824 21.0373C20.5939 22.1245 21.3717 23.1515 22.0162 24.1202C24.233 27.4522 24.8284 30.0267 23.9763 31.9801C23.1209 33.9413 20.7566 35.3969 16.7352 36.3544C12.7289 37.3084 7.15363 37.75 0 37.75V38V38.25C7.15363 38.25 12.7289 38.6916 16.7352 39.6456C20.7566 40.6031 23.1209 42.0587 23.9763 44.0199C24.8285 45.9733 24.233 48.5478 22.0162 51.8798C21.3717 52.8485 20.5939 53.8755 19.6824 54.9627C17.0218 57.1975 14.0198 60.2105 10.6503 63.9967L11.0032 64.3497C14.7895 60.9802 17.8025 57.9782 20.0373 55.3176C21.1245 54.4061 22.1515 53.6283 23.1202 52.9838C26.4522 50.767 29.0267 50.1715 30.9801 51.0237C32.9413 51.8791 34.3969 54.2434 35.3544 58.2648C36.3084 62.2711 36.75 67.8464 36.75 75L37.25 75.0019C37.3033 67.8367 37.7617 62.2626 38.7135 58.2626C39.6692 54.2467 41.1038 51.8959 43.041 51.0507C44.9704 50.209 47.5193 50.8108 50.8433 53.0264C51.8835 53.7196 52.9926 54.5664 54.1737 55.5671C56.3859 58.1655 59.3283 61.0851 62.9967 64.3497L63.3486 63.9955C60.0579 60.3478 57.1275 57.4178 54.5281 55.2121C53.5253 54.0322 52.6773 52.9223 51.9838 51.8798C49.767 48.5478 49.1715 45.9733 50.0237 44.0199C50.8791 42.0587 53.2434 40.6031 57.2648 39.6456C61.2711 38.6916 66.8464 38.25 74 38.25L74.0019 37.75C66.8367 37.6967 61.2626 37.2383 57.2626 36.2865C53.2467 35.3308 50.8959 33.8962 50.0507 31.959C49.209 30.0296 49.8108 27.4807 52.0264 24.1567C52.7711 23.0394 53.693 21.8424 54.7924 20.5622C57.3257 18.3837 60.1689 15.5292 63.3486 12.0045L62.9955 11.6514C59.4708 14.8311 56.6163 17.6743 54.4378 20.2076C53.1576 21.307 51.9606 22.2289 50.8433 22.9736C47.5193 25.1892 44.9704 25.791 43.041 24.9493C41.1038 24.1041 39.6692 21.7532 38.7135 17.7374C37.7617 13.7374 37.3033 8.16332 37.25 0.99814Z" stroke="black" stroke-opacity="0.24" stroke-width="0.5" style="mix-blend-mode:multiply"/></g><g stroke="rgba(0,0,0,0.24)" stroke-width="0.5" fill="none"><rect width="234" height="408" x="8" y="8" mask="url(#border1)"/><rect width="234" height="408" x="8" y="8" rx="24" mask="url(#border2)"/></g><g fill="none" stroke="rgba(0,0,0,0.24)" stroke-width="0.5" font-family="sans-serif" font-weight="500" font-size="12"><text mask="url(#title)" x="16" y="32" text-anchor="start" filter="url(#sh)">UNISWAP LABS</text><text mask="url(#year)" x="234" y="32" text-anchor="end" filter="url(#sh)">2022</text><text mask="url(#number)" x="16" y="32" dy="4%" filter="url(#sh)">'
            );
    }

    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function intToString(int256 value) internal pure returns (string memory) {
        if (value >= 0) {
            return uint256(value).toString();
        } else {
            return string(abi.encodePacked('-', uint256(value * -1).toString()));
        }
    }
}