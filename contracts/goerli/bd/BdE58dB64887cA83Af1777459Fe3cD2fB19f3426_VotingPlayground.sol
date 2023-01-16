// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IVotingRegistry} from "../../registration/registry/IVotingRegistry.sol";
import {IGetDeadline} from "../../extensions/interfaces/IGetDeadline.sol";
import {IGetQuorum} from "../../extensions/interfaces/IGetQuorum.sol";
import {IGetToken} from "../../extensions/interfaces/IGetToken.sol";
import {IImplementResult} from "../../extensions/interfaces/IImplementResult.sol";
import { IPlaygroundVotingBadge, CalculateId} from "./VotingBadge.sol";

import {HandleDoubleVotingGuard} from "../../extensions/primitives/NoDoubleVoting.sol";
import {IGetDoubleVotingGuard} from "../../extensions/interfaces/IGetDoubleVotingGuard.sol";

// import {Deployer} from "../../registration/registrar/Deployer.sol";
import {StartVoteAndImplementHybridVotingImplRemoteHooks} from "../../integration/abstracts/StartVoteAndImplementRemote.sol";
import {
    OnlyVoteImplementer,
    AssignedContractPrimitive,
    LegitInstanceHash,
    SecurityThroughAssignmentPrimitive
} from "../../integration/primitives/AssignedContractPrimitive.sol";

error BadgeDoesntExist(uint256 mainBadge, uint256 numberOfBadges);

struct VotingMetaParams {
    uint256 minDuration;
    uint256 minQuorum;
    address token;
}

struct Analytics {
        uint256 numberOfInstances;
        uint256 numberOfVotes;
        uint256 numberOfImplementations;
        uint24 numberOfSimpleVotingContracts;
    }

struct Counter {
    uint256 counter;
    Operation operation;
}


struct NFTsAndBadgesInfo {
    uint256 mainBadge;
    bool acceptingNFTs;
}

struct Incumbent {
    address incumbent;
    uint256 indexPlusOne;
}

struct ImmutableAddresses {
    address deployer;
    address REGISTRY;
}

enum Operation {add, subtract, divide, multiply, modulo, exponentiate}
enum ApprovalTypes {limitedApproval, unapproveAll, approveAll}

contract VotingPlayground is 
IERC721Receiver,
LegitInstanceHash,
AssignedContractPrimitive,
SecurityThroughAssignmentPrimitive,
CalculateId,
StartVoteAndImplementHybridVotingImplRemoteHooks {

    // Badges and contracts
    IPlaygroundVotingBadge[] public badges;
    address[] public deployedContracts;

    // Meta Parameters for Voting
    uint256 public minXpToStartAnything; // Experience RequiredForStart
    mapping(bytes4=>uint256) public minXpToStartThisFunction;
    NFTsAndBadgesInfo public nftAndBadgesInfo;

    // Change the Counter
    Counter public counter;

    // Change people
    string[] public offices;
    mapping(string=>Incumbent) internal _incumbents;
    mapping(address=>uint256) internal _numberOfOffices;
    mapping(uint256=>bytes4) internal _selectorOfThisVote;

    mapping(bytes4=>VotingMetaParams) public votingMetaParams;
    address public immutable VOTING_REGISTRY;
    mapping(address=>uint256) public donationsBy;
    Analytics public analytics;
    mapping(uint24=>address) public simpleVotingContract;
    mapping(bytes4=>bool) public fixedVotingContract;
    // setting parameters

    event VotingInstanceStarted(uint256 indexed index, address sender, bytes target);

    constructor(
        address votingContractRegistry,
        bytes5[] memory flagAndSelectors,
        address[] memory votingContracts,
        uint256[] memory minDurations,
        uint256[] memory minQuorums,
        bool[] memory badgeWeightedVote,
        bytes32 hashedBadgeBytecode
        )
    {
        // set the registry;
        VOTING_REGISTRY = votingContractRegistry;

        // // set a few voting contracts
        // // assign the voting contract the increment function.
        address badgeToken = _computeDeploymentAddress(hashedBadgeBytecode);
        // badges.push(IPlaygroundVotingBadge(badgeToken));
        nftAndBadgesInfo.mainBadge = uint256(uint160(badgeToken));
        for (uint8 j; j<votingContracts.length; j++){
            bytes4 selector = bytes4(flagAndSelectors[j] << 8);
            fixedVotingContract[selector] = bytes1(flagAndSelectors[j])!=bytes1(0x00);
            votingMetaParams[selector] = VotingMetaParams({
                minDuration: minDurations[j],
                minQuorum: minQuorums[j],
                token: badgeWeightedVote[j] ? badgeToken : address(0)
            });
            assignedContract[selector] = votingContracts[j];
        }
    }

    function addSimpleVotingContract(address votingContract) external {
        // check whether it is Registered
        require(IVotingRegistry(VOTING_REGISTRY).isRegistered(votingContract));
        simpleVotingContract[uint24(analytics.numberOfSimpleVotingContracts)] = votingContract;
        analytics.numberOfSimpleVotingContracts += 1;
    }

    // change the contract for certain functions
    function changeAssignedContract(bytes4 selector, address newVotingContract) 
    external 
    OnlyByVote(true)
    {
        // check whether it is Registered
        require(IVotingRegistry(VOTING_REGISTRY).isRegistered(newVotingContract));
        require(!fixedVotingContract[selector]);
        assignedContract[selector] = newVotingContract;
    }

    function _computeDeploymentAddress(bytes32 _hashedByteCode) internal view returns(address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff),address(this),bytes32(0),_hashedByteCode)))));
    }

    // change the metaParameters for those functions
    function changeMetaParameters(
        bytes4 selector,
        uint256 minDuration,
        uint256 minQuorum,
        address token
    )
    external
    OnlyByVote(true)
    {
        require(!fixedVotingContract[selector]);
        votingMetaParams[selector] = VotingMetaParams({
            minDuration: minDuration,
            minQuorum: minQuorum,
            token: token
        });
    }
        

    //////////////////////////////////////////////
    // PARAMETER SETTINGS                       //
    //////////////////////////////////////////////

    function setMainBadge(uint256 newMainBadge) 
    external 
    OnlyByVote(true)
    {
        if(newMainBadge>=badges.length) revert BadgeDoesntExist(newMainBadge, badges.length);
        nftAndBadgesInfo.mainBadge = newMainBadge;
    }

    function setMinXpToStartAnything(uint256 newXP) external
    OnlyByVote(true)
    {
        require(newXP>0 && newXP<30, "Must be within bounds");
        minXpToStartAnything = newXP;
    }

    function setMinXpToStartThisFunction(bytes4 selector, uint256 newXP) external
    OnlyByVote(true)
    {
        require(newXP<40, "Must be within bounds");
        minXpToStartThisFunction[selector] = newXP;
    }

    function setEnableTradingThreshold(uint256 newThreshold)
    external 
    OnlyByVote(true)
    {
        badges[nftAndBadgesInfo.mainBadge].changeEnableTradingThreshold(newThreshold);
    }

    function setTradingEnabledGlobally(bool enable)
    external 
    OnlyByVote(true)
    {
        badges[nftAndBadgesInfo.mainBadge].changeTradingEnabledGlobally(enable);
    }

    function setAcceptingNFTs(bool accept) 
    external 
    OnlyByVote(true)
    {
        nftAndBadgesInfo.acceptingNFTs = accept;
    }

    

    //////////////////////////////////////////////
    // DO INTERACTIVE STUFF                     //
    //////////////////////////////////////////////

    function changeCounter(uint256 by) 
    external 
    returns (bool)
    {
        require((_numberOfOffices[msg.sender]>0) || _isImplementer(true), "not allowed");
        if (counter.operation==Operation.add){
            counter.counter += by;
        } else if (counter.operation==Operation.subtract) {
            counter.counter -= by;
        } else if (counter.operation==Operation.multiply) {
            counter.counter *= by;
        }
        // } else if (counter.operation==Operation.divide) {
        //     counter.counter = counter.counter / by;
        // } else if (counter.operation==Operation.modulo) {
        //     counter.counter = counter.counter % by;
        // } else if (counter.operation==Operation.exponentiate) {
        //     counter.counter = counter.counter ** by;
        // } 
        
    }

    function changeOperation(Operation newOperation)
    external
    returns (bool)
    {
        require(donationsBy[msg.sender]>1e18 || _isImplementer(true), "not allowed");
        counter.operation = newOperation;
    }

    function newIncumbent(string memory office, address _newIncumbent)
    external
    OnlyByVote(true) 
    returns (bool)
    {
        // no empty incumbents
        require(_newIncumbent!=address(0));
        // check whether we should add a new office
        if (_incumbents[office].indexPlusOne==0){
            offices.push(office);
            _incumbents[office].indexPlusOne = offices.length;
        } else {
            _numberOfOffices[_incumbents[office].incumbent] -= 1;
        }
        // set the new _incumbents and office
        _incumbents[office].incumbent = _newIncumbent;
        _numberOfOffices[_newIncumbent] += 1;
    }

    function getAssignedContract(bytes4 selector) external view returns(address _assignedContract) {
        _assignedContract = assignedContract[selector];
    }

    function getIncumbentFromOffice(string memory office) external view returns(address incumbent) {
        incumbent = _incumbents[office].incumbent;
    }

    // function getOfficesFromAddress(address incumbent) external view returns(string[] memory) {
    //     uint256[] memory indices;
    //     uint256 j;
    //     for(uint256 i=0; i<offices.length; i++){
    //         if (_incumbents[offices[i]].incumbent == incumbent) {
    //             indices[j] = i;
    //             j ++;
    //         }
    //     }
    //     string[] memory _offices = new string[](indices.length);
    //     for (uint256 k=0; k<indices.length; k++){
    //         _offices[k] = offices[indices[k]];
    //     }
    //     return _offices;
        
    // }

    //////////////////////////////////////////////
    // CREATE CONTRACTS                         //
    //////////////////////////////////////////////

    function deployNewBadge(bytes32 salt, bytes memory bytecode, address badger) 
    external
    returns(address deployedContract){
        if(badges.length==0){
            require(_computeDeploymentAddress(keccak256(bytecode))==address(uint160(nftAndBadgesInfo.mainBadge)), "Wrong ByteCode");
            salt = bytes32(0);
            nftAndBadgesInfo.mainBadge = 0;
            // return deployedContract;IPlaygroundVotingBadge
        } else {
            if(!_isImplementer(true)) revert OnlyVoteImplementer(msg.sender);
        }
        deployedContract = _deployContract(salt, bytecode);
        badges.push(IPlaygroundVotingBadge(deployedContract));
        
        badges[badges.length - 1].mint(
            badger,
            0,
            msg.sig,
            msg.sender);
    }


    function deployNewContract(bytes32 salt, bytes memory bytecode) 
    external
    OnlyByVote(true) 
    returns(address deployedContract){
        deployedContract = _deployContract(salt, bytecode);
        deployedContracts.push(deployedContract);
    }



    //////////////////////////////////////////////
    // SENDING THINGS                           //
    //////////////////////////////////////////////

    function sendNFT(address token, address from, address to, uint256 tokenId) 
    external 
    OnlyByVote(true)
    {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }


    function sendNativeToken(address payable to, uint256 amount) 
    external 
    OnlyByVote(true)
    {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send");
    }

    function sendERC20Token(address token, address from, address to, uint256 amount) 
    external 
    OnlyByVote(true)
    {
        (from==address(this)) ? IERC20(token).transfer(to, amount) : IERC20(token).transferFrom(from,to, amount); 
    }

    function approveNFT(address token, address spender, uint256 tokenId)
    external 
    OnlyByVote(true)
    {
        // check whether NFT or ERC20
        // (approvalType==ApprovalTypes.limitedApproval)?
        IERC721(token).approve(spender, tokenId);
        // :
        // IERC721(token).setApprovalForAll(spender, approvalType==ApprovalTypes.approveAll);
    }


    function approveERC20Token(address token, address spender, uint256 amount)
    external 
    OnlyByVote(true)
    {
        IERC20(token).approve(spender, amount);
    }

    function wildCard(address contractAddress, bytes calldata data, uint256 value) 
    external 
    payable
    OnlyByVote(true)
    {
        require(address(this).balance>=value, "not enough funds");
        (bool success, ) = contractAddress.call{value: value}(data);
        require(success, "not successful");
    }

    //////////////////////////////////////////////
    // HELPER FUNCTIONS                         //
    //////////////////////////////////////////////

    function _deployContract(bytes32 salt, bytes memory bytecode) internal returns(address deployedContract) {
        assembly {
            deployedContract := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }
    

    function _beforeStart(bytes memory votingParams, bytes calldata callback) internal view
    override(StartVoteAndImplementHybridVotingImplRemoteHooks) 
    {
        uint256 callSpecificXp = (callback.length>=4) ? minXpToStartThisFunction[bytes4(callback[0:4])] : 0;
        uint256 balance = badges[nftAndBadgesInfo.mainBadge].balanceOf(msg.sender);
        // Only allow to start a vote when you have at least one badge
        require(
            balance >= minXpToStartAnything && balance >= callSpecificXp,
            "Not enough badges");
    }

    function _getSimpleVotingContract(bytes calldata callback) internal view
    override(StartVoteAndImplementHybridVotingImplRemoteHooks) 
    returns(address) {
        return simpleVotingContract[uint24(bytes3(callback))];
    }

    function _afterStart(uint256 identifier, bytes memory votingParams, bytes calldata callback)
    internal override(StartVoteAndImplementHybridVotingImplRemoteHooks)
    {
        // check whether conditions are met
        uint256 index = instances[identifier].identifier;
        address votingContract = instances[identifier].votingContract;
        if (callback.length>=4){
            bytes4 selector = bytes4(callback[0:4]);
            // set the selector of this voting instance. If there there is none, then it's just bytes4(0)
            _selectorOfThisVote[identifier] = selector;
            // check whether specs are met
            bool goodSpecs = true;
            bool success;
            bytes memory response;
            
            if (votingMetaParams[selector].minDuration!=0){
                (success, response) = votingContract.call(abi.encodeWithSelector(IGetDeadline.getDeadline.selector, index));
                if (success) goodSpecs = goodSpecs && votingMetaParams[selector].minDuration + block.timestamp <= abi.decode(response, (uint256));
                // if(!goodSpecs) revert Blaab2DurationError(abi.decode(response, (uint256)), response, votingMetaParams[selector].minDuration, block.timestamp, instances[identifier].votingContract);
            }    
            if (votingMetaParams[selector].token!=address(0)){
                (success, response) = votingContract.call(abi.encodeWithSelector(IGetToken.getToken.selector, index));
                if (success) goodSpecs = goodSpecs && abi.decode(response, (address)) == votingMetaParams[selector].token;
            }
            if (votingMetaParams[selector].minQuorum!=0){
                (success, response) = votingContract.call(abi.encodeWithSelector(IGetQuorum.getQuorum.selector, index));
                (uint256 _quorum, uint256 inUnitsOf) = abi.decode(response, (uint256, uint256));
                // when inUnitsOf is zero (i.e. the quorum is measured in absolute terms, then the absolute values are compared).
                goodSpecs = goodSpecs && (votingMetaParams[selector].minQuorum <= ((inUnitsOf==0) ? _quorum : ((_quorum * 1e5) / inUnitsOf)));                
            }
            require(goodSpecs, "Invalid Parameters");
            emit VotingInstanceStarted(identifier, msg.sender, callback);
        }
        

        badges[nftAndBadgesInfo.mainBadge].mint(
            msg.sender,
            index,
            msg.sig,
            votingContract);

        analytics.numberOfInstances += 1;
    }

    
    function _beforeVote(uint256 identifier, bytes calldata votingData) 
    internal override(StartVoteAndImplementHybridVotingImplRemoteHooks)
    {
        // if the voting instance requires the voter to be an incumbent of an office, then we should check here
        bytes4 selector = _selectorOfThisVote[identifier];
        if(selector!=bytes4(0) && votingMetaParams[selector].token==address(0)){
            require(_numberOfOffices[msg.sender]>0);
        }
        uint256 index = instances[identifier].identifier;
        address votingContract = instances[identifier].votingContract;
        if (!badges[nftAndBadgesInfo.mainBadge].exists(calculateId(index, msg.sig, votingContract, msg.sender))){
            // e.g. in tournament this might be interesting
            badges[nftAndBadgesInfo.mainBadge].mint(
                msg.sender,
                index,
                msg.sig,
                votingContract);
        }
    }

    function _afterVote(uint256 identifier, uint256 status, bytes calldata votingData) 
    internal override(StartVoteAndImplementHybridVotingImplRemoteHooks) 
    {
        analytics.numberOfVotes += 1;
    }



    // function _beforeImplement(uint256 identifier) 
    // internal override(StartVoteAndImplementHybridVotingImplRemoteHooks)
    // {
    //     analytics.numberOfImplementations += 1;
    // }

    function _afterImplement(uint256 identifier, bool responseFlag)
    internal override(StartVoteAndImplementHybridVotingImplRemoteHooks) 
    {
        if (responseFlag){
            badges[nftAndBadgesInfo.mainBadge].mint(
                msg.sender,
                instances[identifier].identifier,
                msg.sig,
                instances[identifier].votingContract);
        }
        
        analytics.numberOfImplementations += 1;
    }

    function _modifyVotingData(uint256 identifier, bytes calldata votingData) virtual internal 
    override(StartVoteAndImplementHybridVotingImplRemoteHooks)
    returns(bytes memory newVotingData)
    { 
        (bool success, bytes memory response) = instances[identifier].votingContract.call(abi.encodeWithSelector(
            IGetDoubleVotingGuard.getDoubleVotingGuard.selector,
            instances[identifier].identifier));
        if (success){
            bool onVotingDataCondition = abi.decode(response, (HandleDoubleVotingGuard.VotingGuard)) == HandleDoubleVotingGuard.VotingGuard.onVotingData;
            if (onVotingDataCondition) return abi.encodePacked(msg.sender, votingData);
        }
        return votingData;
        
    }


    receive() external payable {
        donationsBy[msg.sender] += msg.value;
    }


    // interface IERC721Receiver {
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
    ) 
    external 
    view
    override(IERC721Receiver)
    returns(bytes4)
    {
        data;
        return nftAndBadgesInfo.acceptingNFTs ? msg.sig: bytes4(0);
    }


    
    modifier OnlyByVote(bool checkIdentifier) {
        if(!_isImplementer(checkIdentifier)) revert OnlyVoteImplementer(msg.sender);
        _;
    }



    
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";


error NotApprovedContract(address sender);
error TransferNotAllowed(uint256 tokenId);
error OnlyMotherContract(address sender, address _motherContract);

abstract contract CalculateId {
    function calculateId(uint256 index, bytes4 selector, address votingContract, address minter) public pure returns (uint256) {
        return uint256(bytes32(abi.encodePacked(
            uint32(bytes4(bytes32(index) << 224)),
            bytes12(bytes20(minter)),
            selector,
            bytes12(bytes20(votingContract)))));
    }
}

interface IPlaygroundVotingBadge is IERC721{
    function mint(address to, uint256 index, bytes4 selector, address votingContract) external; 
    function exists(uint256 tokenId) external view returns(bool);
    function balanceOfSignature(address owner, bytes4 selector) external returns(uint256);
    function changeEnableTradingThreshold(uint256 newThreshold) external;
    function changeTradingEnabledGlobally(bool enable) external;
    function approveContract(address newContract, bool approval) external returns(bool);
}

contract PlaygroundVotingBadge is 
CalculateId, ERC721 {

    mapping(address=>bool) public isApprovedContract;
    mapping(address=>bool) public tradingEnabled;
    address public motherContract;
    uint256 public enableTradingThreshold;
    bool public tradingEnabledGlobally;

    mapping(address=>mapping(bytes4=>uint256)) private _balanceOfSignature;

    // e.g. name and symbol = "Playground Voting Badge", "VOT"
    constructor(string memory name, string memory symbol) ERC721(name, symbol){
        motherContract = msg.sender;
        isApprovedContract[msg.sender] = true;
    }

    function balanceOfSignature(address owner, bytes4 selector) public view returns(uint256 balance) {
        balance = _balanceOfSignature[owner][selector];
    } 

    event Blaab(uint256 tokenId, address to, bytes4 selector, address votingContract, uint256 index);
    // minting can only happen through approved contracts
    function mint(address to, uint256 index, bytes4 selector, address votingContract) 
    external 
    onlyApprovedContract
    {
        uint256 tokenId = calculateId(index, selector, votingContract, to);
        emit Blaab(tokenId, to, selector, votingContract, index);

        _mint(to, tokenId);
        
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        bytes4 selector = bytes4(bytes32(tokenId) << 128);
        if (from==address(0)){
            // minting
            _balanceOfSignature[to][selector] += 1;
        } else {
            // burning or transfer
            uint addAmount = (to==address(0)) ? 0 : 1;
            _balanceOfSignature[to][selector] += addAmount;
            _balanceOfSignature[from][selector] -= 1;
        }
    }
    

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        if(from!=address(0) && to!=address(0) && !_transferAllowed(tokenId)){
            revert TransferNotAllowed(tokenId);
        }
    }


    function _transferAllowed(uint256 tokenId) internal returns(bool){
        // you need to have at least a certain amount of voting badges
        // transferral must be enabled
        if (!tradingEnabled[msg.sender] && balanceOf(ownerOf(tokenId)) >= enableTradingThreshold){
            // it's sufficient to be above the threshold once.
            tradingEnabled[msg.sender] = true;
        }

        return tradingEnabled[msg.sender] && tradingEnabledGlobally;
    }

    
    function changeEnableTradingThreshold(uint256 newThreshold) 
    external 
    onlyByCallFromMotherContract
    returns(bool)
    {
        enableTradingThreshold = newThreshold;
    }

    function changeTradingEnabledGlobally(bool enable)
    external
    onlyByCallFromMotherContract
    returns(bool)
    {
        tradingEnabledGlobally = enable;
    }

    function approveContract(address newContract, bool approval) 
    external
    onlyByCallFromMotherContract 
    returns(bool)
    {
        isApprovedContract[newContract] = approval;
    }

    
    modifier onlyByCallFromMotherContract {
        if(msg.sender!=motherContract) {
            revert OnlyMotherContract(msg.sender, motherContract);
        }
        _;
    }


    modifier onlyApprovedContract {
        if(!isApprovedContract[msg.sender]) {
            revert NotApprovedContract(msg.sender);
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


interface IGetDeadline {
    function getDeadline(uint256 identifier) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {HandleDoubleVotingGuard} from "../primitives/NoDoubleVoting.sol";

interface IGetDoubleVotingGuard{
    function getDoubleVotingGuard(uint256 identifier) external view returns(HandleDoubleVotingGuard.VotingGuard);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


interface IGetQuorum {
    function getQuorum(uint256 identifier) external view returns(uint256 quorum, uint256 inUnitsOf);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


interface IGetToken {
    function getToken(uint256 identifier) external view returns(address token);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


interface IHasAlreadyVoted {
    function hasAlreadyVoted(uint256 identifier, address voter) external view returns(bool alreadyVoted);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IImplementResult {

    enum VotingStatusImplement {inactive, completed, failed, active, awaitcall}
    
    enum Response {precall, successful, failed}

    /// @dev Checks whether the current voting instance permits voting. This is customizable.
    /// @param identifier the index for the voting instance in question
    /// @param callback data that is passed along with the function call.
    /// @return response information on whether the call was successful or unsuccessful.
    function implement(uint256 identifier, bytes calldata callback) 
    external payable
    returns(Response response); 
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


import {IHasAlreadyVoted} from "../interfaces/IHasAlreadyVoted.sol";


abstract contract NoDoubleVoting  {
    
    error AlreadyVoted(uint256 identifier, address voter);
    
    mapping(uint256=>mapping(address=>bool)) internal _alreadyVoted;

}

abstract contract HandleDoubleVotingGuard {

    enum VotingGuard {none, onSender, onVotingData}

    mapping(uint256=>VotingGuard) internal _guardOnSenderVotingDataOrNone; //_guardOnSenderVotingDataOrNone;

}


abstract contract NoDoubleVotingPublic is 
IHasAlreadyVoted,
NoDoubleVoting 
{
    function hasAlreadyVoted(uint256 identifier, address voter) 
    external 
    view 
    override(IHasAlreadyVoted)
    returns(bool alreadyVoted)
    {
        alreadyVoted = _alreadyVoted[identifier][voter]; 
    }   
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IStartVoteAndImplement} from "../interface/IVotingIntegration.sol";
import {IVotingContract} from "../../votingContractStandard/IVotingContract.sol";
import {LegitInstanceHash, AssignedContractPrimitive} from "../primitives/AssignedContractPrimitive.sol";
import { Instance, InstanceInfoPrimitive } from "../primitives/InstanceInfoPrimitive.sol";
import {IImplementResult} from "../../extensions/interfaces/IImplementResult.sol";


abstract contract StartVoteAndImplementOnlyCallbackImplRemoteMinml is
IStartVoteAndImplement,
LegitInstanceHash,
AssignedContractPrimitive,
InstanceInfoPrimitive
{

    function start(bytes memory votingParams, bytes calldata callback) 
    external 
    override(IStartVoteAndImplement){
        _beforeStart(votingParams);
        bytes4 selector = bytes4(callback[0:4]);
        if (!AssignedContractPrimitive._isVotableFunction(selector)){
            revert AssignedContractPrimitive.IsNotVotableFunction(selector);
        }
        address votingContract = assignedContract[selector];
        uint256 identifier = IVotingContract(votingContract).start(votingParams, callback);
        instances.push(Instance({
            identifier: identifier,
            votingContract: votingContract
        }));
        bytes32 instanceHash = LegitInstanceHash._getInstanceHash(assignedContract[selector], identifier);
        LegitInstanceHash._isLegitInstanceHash[instanceHash] = true;
        
    }

    
    function vote(uint256 identifier, bytes calldata votingData) 
    external 
    override(IStartVoteAndImplement){
        _beforeVote(identifier);
        IVotingContract(instances[identifier].votingContract).vote(
            instances[identifier].identifier,
            votingData);
    }

    function implement(uint256 identifier, bytes calldata callback)
    external 
    payable
    override(IStartVoteAndImplement) 
    {
        IImplementResult(instances[identifier].votingContract).implement(
                instances[identifier].identifier,
                callback);
        
    }

    function _beforeStart(bytes memory votingParams) virtual internal {}

    function _beforeVote(uint256 identifier) virtual internal {}
}

abstract contract StartVoteAndImplementOnlyCallbackImplRemoteHooks is 
IStartVoteAndImplement,
LegitInstanceHash,
AssignedContractPrimitive,
InstanceInfoPrimitive
{

    function start(bytes memory votingParams, bytes calldata callback) 
    external 
    override(IStartVoteAndImplement){
        _beforeStart(votingParams, callback);
        bytes4 selector = bytes4(callback[0:4]);
        if (!AssignedContractPrimitive._isVotableFunction(selector)){
            revert AssignedContractPrimitive.IsNotVotableFunction(selector);
        }
        address votingContract = assignedContract[selector];
        uint256 identifier = IVotingContract(votingContract).start(votingParams, callback);
        instances.push(Instance({
            identifier: identifier,
            votingContract: votingContract
        }));
        bytes32 instanceHash = LegitInstanceHash._getInstanceHash(assignedContract[selector], identifier);
        LegitInstanceHash._isLegitInstanceHash[instanceHash] = true;
        
        _afterStart(instances.length - 1, votingParams, callback);
    }

    
    function vote(uint256 identifier, bytes calldata votingData) 
    external 
    override(IStartVoteAndImplement){
        _beforeVote(identifier, votingData);
        uint256 status = IVotingContract(instances[identifier].votingContract).vote(
            instances[identifier].identifier,
            _modifyVotingData(identifier, votingData));
        _afterVote(identifier, status, votingData);
    }

    function implement(uint256 identifier, bytes calldata callback)
    external 
    payable
    override(IStartVoteAndImplement) 
    {
        _beforeImplement(identifier);
        IImplementResult.Response _response = IImplementResult(instances[identifier].votingContract).implement(
                instances[identifier].identifier,
                callback);
        _afterImplement(identifier, _response==IImplementResult.Response.successful);
        
    }

    function _beforeStart(bytes memory votingParams, bytes calldata callback) virtual internal {}

    function _afterStart(uint256 identifier, bytes memory votingParams, bytes calldata callback) virtual internal {}
    
    function _beforeVote(uint256 identifier, bytes calldata votingData) virtual internal {}

    function _modifyVotingData(uint256 identifier, bytes calldata votingData) virtual internal returns(bytes memory newVotingData){ return votingData;}

    function _afterVote(uint256 identifier, uint256 status, bytes calldata votingData) virtual internal {}

    function _beforeImplement(uint256 identifier) virtual internal {}
    
    function _afterImplement(uint256 identifier, bool responseFlag) virtual internal {}    

}


abstract contract StartVoteAndImplementHybridVotingImplRemoteMinml is
IStartVoteAndImplement,
LegitInstanceHash,
AssignedContractPrimitive,
InstanceInfoPrimitive 
{
    
    address public votingContract;

    function start(bytes memory votingParams, bytes calldata callback) 
    external 
    override(IStartVoteAndImplement){
         _beforeStart(votingParams);
        address _votingContract;
        uint256 identifier;
        if (callback.length<4){
            _votingContract = votingContract;
            identifier = IVotingContract(_votingContract).start(votingParams, callback);
        } else {
            bytes4 selector = bytes4(callback[0:4]);
            if (!AssignedContractPrimitive._isVotableFunction(selector)){
                revert AssignedContractPrimitive.IsNotVotableFunction(selector);
            }
            _votingContract = assignedContract[selector];
            identifier = IVotingContract(_votingContract).start(votingParams, callback);
            bytes32 instanceHash = LegitInstanceHash._getInstanceHash(assignedContract[selector], identifier);
            LegitInstanceHash._isLegitInstanceHash[instanceHash] = true;
        
        }
        instances.push(Instance({
            identifier: identifier,
            votingContract: _votingContract
        }));
    }

    
    function vote(uint256 identifier, bytes calldata votingData) 
    external 
    override(IStartVoteAndImplement){
        _beforeVote(identifier);
        IVotingContract(instances[identifier].votingContract).vote(
            instances[identifier].identifier,
            votingData);
    }

    function implement(uint256 identifier, bytes calldata callback)
    external 
    payable
    override(IStartVoteAndImplement) 
    {
        _beforeImplement(identifier);
        IImplementResult(instances[identifier].votingContract).implement(
                instances[identifier].identifier,
                callback);
        
    }

    function _beforeStart(bytes memory votingParams) virtual internal {}

    function _beforeVote(uint256 identifier) virtual internal {}

    function _beforeImplement(uint256 identifier) virtual internal {}
    
}

abstract contract StartVoteAndImplementHybridVotingImplRemoteHooks is 
IStartVoteAndImplement,
LegitInstanceHash,
AssignedContractPrimitive,
InstanceInfoPrimitive
{
    function start(bytes memory votingParams, bytes calldata callback) 
    external 
    override(IStartVoteAndImplement){
        _beforeStart(votingParams, callback);
        address _votingContract;
        uint256 identifier;
        if (callback.length<4){
            _votingContract = _getSimpleVotingContract(callback);
            identifier = IVotingContract(_votingContract).start(votingParams, callback);
        } else {
            bytes4 selector = bytes4(callback[0:4]);
            if (!AssignedContractPrimitive._isVotableFunction(selector)){
                revert AssignedContractPrimitive.IsNotVotableFunction(selector);
            }
            _votingContract = assignedContract[selector];
            identifier = IVotingContract(_votingContract).start(votingParams, callback);
            bytes32 instanceHash = LegitInstanceHash._getInstanceHash(assignedContract[selector], identifier);
            LegitInstanceHash._isLegitInstanceHash[instanceHash] = true;
        }
        instances.push(Instance({
            identifier: identifier,
            votingContract: _votingContract
        }));
        _afterStart(instances.length - 1, votingParams, callback);
    }

    
    function vote(uint256 identifier, bytes calldata votingData) 
    external 
    override(IStartVoteAndImplement){
        _beforeVote(identifier, votingData);
        uint256 status = IVotingContract(instances[identifier].votingContract).vote(
            instances[identifier].identifier,
            _modifyVotingData(identifier, votingData));
        _afterVote(identifier, status, votingData);
    }

    function implement(uint256 identifier, bytes calldata callback)
    external
    payable 
    override(IStartVoteAndImplement) 
    {
        _beforeImplement(identifier);
        bytes memory data = abi.encodeWithSelector(
                IImplementResult.implement.selector, 
                instances[identifier].identifier,
                callback);
        (bool success, bytes memory responsedata) = instances[identifier].votingContract.call{value: msg.value}(data);
       
        _afterImplement(identifier, success);
        
    }

    event WhatsNow(bool success, bytes response);

    

    function _beforeStart(bytes memory votingParams, bytes calldata callback) virtual internal {}

    function _afterStart(uint256 identifier, bytes memory votingParams, bytes calldata callback) virtual internal {}
    
    function _getSimpleVotingContract(bytes calldata callback) virtual internal view returns(address) {}

    function _beforeVote(uint256 identifier, bytes calldata votingData) virtual internal {}

    function _modifyVotingData(uint256 identifier, bytes calldata votingData) virtual internal returns(bytes memory newVotingData){ return votingData;}

    function _afterVote(uint256 identifier, uint256 status, bytes calldata votingData) virtual internal {}

    function _beforeImplement(uint256 identifier) virtual internal {}
    
    function _afterImplement(uint256 identifier, bool responseFlag) virtual internal {}    

}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


interface IStart {

    function start(bytes memory votingParams, bytes calldata callback) external; 

}

interface IStartAndVote {

    function start(bytes memory votingParams, bytes calldata callback) external; 

    function vote(uint256 identifier, bytes calldata votingData) external;

}

interface IStartVoteAndImplement {
   
    function start(bytes memory votingParams, bytes calldata callback) external; 

    function vote(uint256 identifier, bytes calldata votingData) external;

    function implement(uint256 identifier, bytes calldata callback) external payable;

}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

error OnlyVoteImplementer(address implementer);
error NotLegitIdentifer(address votingContract, uint256 identifier);

abstract contract AssignedContractPrimitive {
    
    error IsNotVotableFunction(bytes4 selector);

    mapping(bytes4=>address) internal assignedContract; 

    function _isVotableFunction(bytes4 selector) internal view returns(bool votable){
        return assignedContract[selector]!=address(0);
    }
}

abstract contract LegitInstanceHash {
    mapping(bytes32=>bool) internal _isLegitInstanceHash;

    function _getInstanceHash(address votingContract, uint256 identifier) pure internal returns(bytes32) {
        return keccak256(abi.encode(votingContract, identifier));
    }
}

abstract contract SecurityPrimitive {
    
    error IsNotImplementer(address imposter);

    function _isImplementer(bool checkIdentifier) virtual internal returns(bool){}

}

abstract contract SecurityThroughAssignmentPrimitive is 
LegitInstanceHash,
AssignedContractPrimitive, 
SecurityPrimitive 
{

    function _isImplementer(bool checkIdentifier)
    virtual 
    internal 
    override(SecurityPrimitive)
    returns(bool){

        bool isImplementer = assignedContract[msg.sig]==msg.sender;
        
        if (!checkIdentifier || !isImplementer) return isImplementer;
        if (msg.data.length<36) return false;

        uint256 identifier = uint256(bytes32(msg.data[(msg.data.length - 32):msg.data.length]));
        
        // only need to check whether identifier is legit
        // because if the assigned contract was wrong the 
        // first if-condition would have returned false
        return _isLegitInstanceHash[_getInstanceHash(msg.sender, identifier)];
    }

}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

struct Instance {
    uint256 identifier;
    address votingContract;
}

struct InstanceWithStatus {
    uint256 identifier;
    address votingContract;
    uint256 implementationStatus;
}

struct InstanceWithCallback {
    uint256 identifier;
    address votingContract;
    bytes callback;
}

struct InstanceWithCallbackAndResponse {
    uint256 identifier;
    address votingContract;
    bytes callback;
    uint256 status;
}

abstract contract InstanceInfoPrimitive {
    Instance[] public instances;
}

abstract contract InstanceInfoWithCallback {
    InstanceWithCallback[] public instances;
}

abstract contract InstanceInfoWithCallbackAndResponse {
    InstanceWithCallbackAndResponse[] public instances;
}

abstract contract InstanceInfoWithStatusPrimitive {
    InstanceWithStatus[] public instances;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface IVotingRegistry {
    
    /// @notice register a new voting contract
    /// @param contractAddress address of the new voting contract
    /// @param resolver address of the resolver contract
    function register(address contractAddress, address resolver) external;

    /// @notice change resolver
    /// @param contractAddress address of the new voting contract
    /// @param resolver new resolver contract address
    function changeResolver(address contractAddress, address resolver) external;

    /// @notice getter function for the registrar address
    /// @param votingContract address of the new voting contract
    /// @return registrar address of the registrar
    function getRegistrar(address votingContract) external view returns (address registrar);

    /// @notice getter function for the resolver address
    /// @param votingContract address of the new voting contract
    /// @return resolver address of the resolver
    function getResolver(address votingContract) external view returns(address resolver);

    /// @notice checks whether the voting contract is registered
    /// @param votingContract address of the new voting contract
    /// @return registrationStatus a boolean flag that yields true when the contract is registered
    function isRegistered(address votingContract) external view returns(bool registrationStatus);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";


/// @title Configurable Voting Contract Interface
/// @author Leonhard Horstmeyer <[email protected]>
/// @dev A Voting Contract is an implementations of a particular type of voting mechanism. 
///      It can be thought of as a standalone contract that handles the entire life-cycle of voting, 
///      from the initialization, via the casting of votes to the retrieval of results. Optionally it can
///      be extended by the functionality of triggering the outcome of the vote through a call whose calldata is already passsed at the initialization. 
///      The standard allows for a great deal of versatility and modularity. Versatility stems from the fact that 
///      the standard doesn't prescribe any particular way of defining the votes and the status of the vote. But it does
///      define a universal interface used by them all.  



interface IVotingContract is IERC165{
    ///  Note: the ERC-165 identifier for this interface is 0x9452d78d.
    ///  0x9452d78d ===
    ///         bytes4(keccak256('start(bytes,bytes)')) ^
    ///         bytes4(keccak256('vote(uint256,bytes)')) ^
    ///         bytes4(keccak256('result(uint256)'));
    ///

    /// @notice The states first three statuses are recommended to be 
    ///         'inactive', 'completed' and 'failed'.
    enum VotingStatus {inactive, completed, failed, active}

    /// @notice When a new instance is started this event gets triggered.
    event VotingInstanceStarted(uint256 indexed identifier, address caller);

    /// @notice starts a new voting instance.
    /// @param votingParams byte-encoded parameters that configure the voting instance
    /// @param callback calldata that gets executed when the motion passes
    /// @return identifier the instance identifier that needs to be referenced to vote on this motion.
    function start(bytes memory votingParams, bytes calldata callback) external returns(uint256 identifier); 

    /// @notice casts a vote on a voting instance referenced by the identifier
    /// @param identifier unique identifier of the voting instance on which one would like to cast a vote
    /// @param votingData carries byte-encoded information about the vote
    /// @return status information for the caller, whether the vote has triggered any changes to the status
    function vote(uint256 identifier, bytes calldata votingData) external returns(uint256 status);

    /// @notice returns the result of the voting instance
    /// @dev The result can be the byte-encoded version of an address, an integer or a pointer to a mapping that contains the entire result.
    /// @param identifier unique identifier for which one would like to know the result
    /// @return resultData byte-encoded data that encodes the result.
    function result(uint256 identifier) external view returns(bytes memory resultData);

}