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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

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
        _requireMinted(tokenId);

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
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IBaseIncomeStream {
    function getIncomeStreamContracts(address _erc721, uint256 _tokenId)
        external
        view
        returns (address[] memory);
}

struct RoyaltyBeneficiary {
    address payable beneficiary; // beneficiary address
    uint256 priceIncreasePercent; // royalty for price increase
    uint256 salePricePercent; // royalty for sale price
}

struct NFTInformation {
    uint256 NFTID; // NFT ID
    uint256 lastPrice; // last price
    uint256 minimumPriceIncrease; // percentage value using for calculate increasing value each new purchase
    address creator; // NFT's creator address
    address payable currentOwner; // current NFT's onwer address
    bool isBuyingAvailable; // is buying available status
    bool isOwnershipRoyalty; // is ownership royalty status
    bool enabledOffer; // Allow owner to have right to match offers to refuse sale
    uint256 totalSales; // total sales
}

struct Offer {
    uint256 NFTID;
    address buyer;
    uint256 bidAmount; // wei
    uint256 startTime; //start time of the offer
    uint256 endTime; // end time of the offer
    bool isActive;
    address incomeStreamAdmin;
}

// NFT contract
contract ExitAndUtility is
    ERC721,
    IERC2981,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private supply;

    uint256 private constant SUPPORT_PERCENTAGE_DECIMALS = 10**18;
    uint256 private expireOfferTime = 2 days;
    bool private paused = false;
    uint256 public constant version = 1;
    // mapping NFTID to struct NFTInformation
    mapping(uint256 => NFTInformation) private NFTSInformation;

    // mapping NFTID to struct RoyaltyBeneficiary
    mapping(uint256 => mapping(uint256 => RoyaltyBeneficiary))
        private royaltyBeneficiaries;

    mapping(uint256 => Offer) public offers;

    event LogCreateNFT(uint256 indexed _tokenId, address indexed _from);
    event LogPriceHistory(
        uint256 indexed _tokenId,
        address indexed _seller,
        uint256 _price,
        uint256 _timestamp
    );
    event LogBuyNFT(
        uint256 indexed _tokenId,
        address indexed _seller,
        address indexed _buyer,
        uint256 _price
    );
    event LogOfferNFT(
        uint256 indexed _tokenId,
        address indexed _seller,
        address indexed _buyer,
        uint256 _price
    );

    event LogSetExpireOfferTime(address indexed _caller, uint256 _time);
    event LogEnableForceBuy(uint256 indexed _tokenId, address indexed _caller);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _price,
        uint256 _minimumPriceIncrease,
        bool _isOwnershipRoyalty,
        uint256 _priceIncreasePercent,
        uint256 _salePricePercent,
        address _beneficiary,
        bool _isBuyingAvailable,
        bool _enabledOffer
    ) ERC721(_name, _symbol) {
        create(
            _uri,
            _price,
            _minimumPriceIncrease,
            _isOwnershipRoyalty,
            _priceIncreasePercent,
            _salePricePercent,
            address(_beneficiary),
            _isBuyingAvailable,
            _enabledOffer
        );
    }

    // Modifier check contract not pause
    modifier whenNotPaused() {
        require(!paused, "CONTRACT_PAUSED!");
        _;
    }
    // Modifier check contract not pause
    modifier whenNotZeroAddress(address _user) {
        require(_user != address(0), "NOT_A_ZERO_ADDRESS!");
        _;
    }

    /// @dev Function create NFT
    /// @param _uri Metadata NFT uri (json uri)
    /// @param _price NFT price(wei)
    /// @param _minimumPriceIncrease Minimum Price Increase Percentage
    /// @param _isOwnershipRoyalty ownership royalty status(true/false)
    /// @param _priceIncreasePercent Price increasing percent
    /// @param _salePricePercent Sale Price percent
    /// @param _enabledOffer Allow owner to have right to match offers to refuse sale
    /// @param _beneficiary beneficiary address
    function create(
        string memory _uri,
        uint256 _price,
        uint256 _minimumPriceIncrease,
        bool _isOwnershipRoyalty,
        uint256 _priceIncreasePercent,
        uint256 _salePricePercent,
        address _beneficiary,
        bool _isBuyingAvailable,
        bool _enabledOffer
    ) public whenNotPaused whenNotZeroAddress(_beneficiary) returns (uint256) {
        require(
            _priceIncreasePercent + _salePricePercent <= 50,
            "ROYALTY_MUST_BE_LESS_OR_EQUAL_50_PERCENTAGE"
        );
        if (_isBuyingAvailable) {
            require(_price > 0, "PRICE_MUST_BE_GREATER_THAN_ZERO");
        }
        // next NFT ID will be  currentSupply + 1
        uint256 NFTID = supply.current() + 1;
        address currentCreator = _beneficiary;
        if (NFTID > 1) {
            currentCreator == msg.sender;
        }

        // set NFT Information
        NFTSInformation[NFTID] = NFTInformation(
            NFTID,
            _price,
            _minimumPriceIncrease,
            currentCreator,
            payable(_beneficiary),
            _isBuyingAvailable,
            _isOwnershipRoyalty,
            _enabledOffer,
            0
        );
        // set royalty beneficiaries for owner (first user)
        if (_isBuyingAvailable) {
            royaltyBeneficiaries[NFTID][0] = RoyaltyBeneficiary(
                payable(_beneficiary),
                _priceIncreasePercent * SUPPORT_PERCENTAGE_DECIMALS,
                _salePricePercent * SUPPORT_PERCENTAGE_DECIMALS
            );
        }

        // increase current supply
        supply.increment();
        emit LogCreateNFT(NFTID, currentCreator);
        emit LogPriceHistory(NFTID, currentCreator, _price, block.timestamp);
        // mint a new NFT and beneficiary is owner of that NFT
        _safeMint(_beneficiary, NFTID);
        // set metadata uri to that NFT
        _setTokenURI(NFTID, _uri);
        return NFTID;
    }

    /// @dev Function enable force buy NFT
    /// @param _tokenId NFT ID
    /// @param _price NFT price(wei)
    /// @param _minimumPriceIncrease Minimum Price Increase Percentage
    /// @param _isOwnershipRoyalty ownership royalty status(true/false)
    /// @param _priceIncreasePercent Price increasing percent
    /// @param _salePricePercent Sale Price percent
    /// @param _enabledOffer Allow owner to have right to match offers to refuse sale
    function enableForceBuy(
        uint256 _tokenId,
        uint256 _price,
        uint256 _minimumPriceIncrease,
        bool _isOwnershipRoyalty,
        uint256 _priceIncreasePercent,
        uint256 _salePricePercent,
        bool _enabledOffer
    ) public whenNotPaused  returns (uint256) {
        require(
            _priceIncreasePercent + _salePricePercent <= 50,
            "ROYALTY_MUST_BE_LESS_OR_EQUAL_50_PERCENTAGE"
        );
        require(_price > 0, "PRICE_MUST_BE_GREATER_THAN_ZERO");
        // require only NFT's owner do this method
        require(msg.sender == ownerOf(_tokenId), "ONLY_NFT_OWNER");

        NFTInformation memory currentNFT = getNFTInformation(_tokenId);
        require(!currentNFT.isBuyingAvailable, "NFT_ALREADY_ENABLE_FORCE_BUY");

        // set NFT Information
        NFTSInformation[_tokenId] = NFTInformation(
            _tokenId,
            _price,
            _minimumPriceIncrease,
            currentNFT.creator,
            payable(currentNFT.currentOwner),
            true,
            _isOwnershipRoyalty,
            _enabledOffer,
            0
        );
        // set royalty beneficiaries for owner (first user)
        royaltyBeneficiaries[_tokenId][0] = RoyaltyBeneficiary(
            payable(currentNFT.currentOwner),
            _priceIncreasePercent * SUPPORT_PERCENTAGE_DECIMALS,
            _salePricePercent * SUPPORT_PERCENTAGE_DECIMALS
        );
        emit LogEnableForceBuy(_tokenId, msg.sender);
        return _tokenId;
    }


    /// @dev Function check all current tokenId of the _owner address.
    /// @param _owner Address wallet that want to get.
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 totalToken = totalSupply();
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= totalToken; i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[currentIndex++] = uint256(i);
            }
        }
        return tokenIds;
    }

    /// @dev Function return metadate uri of a token ID.
    /// @param _tokenId token ID.
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    /// @dev Function set metadata uri of a token ID.
    /// @param _tokenId token ID.
    /// @param _tokenURI token uri
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) whenNotPaused public {
        require(msg.sender == ownerOf(_tokenId), "ONLY_NFT_OWNER");
        super._setTokenURI(_tokenId, _tokenURI);
    }

    /// @dev Function burn NFT by token ID.
    function _burn(uint256 _tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(_tokenId);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view override {
        require(msg.sender == super.ownerOf(1), "ONLY_APP_OWNER");
    }

    /// @dev Function pause status
    /// @param _status status(true/false).
    function setPaused(bool _status) public onlyOwner {
        paused = _status;
    }

    /// @dev Function get pause status
    function getPaused() public view returns (bool) {
        return paused;
    }

    /// @dev Function set expire time offer
    /// @param _time time expire offer. (second)
    function setExpireOfferTime(uint256 _time) public onlyOwner {
        expireOfferTime = _time;
        emit LogSetExpireOfferTime(msg.sender, _time);
    }

    /// @dev Function get expire time offer
    function getExpireOfferTime() public view returns (uint256) {
        return expireOfferTime;
    }

    // Modifier check token exists by token ID
    modifier whenTokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "INVALID_TOKEN");
        _;
    }

    // Modifier check valid index in royaltyBeneficiaries
    modifier whenValidIndex(uint256 _tokenId, uint256 _index) {
        require(
            NFTSInformation[_tokenId].totalSales >= _index,
            "INVALID_INDEX"
        );
        _;
    }

    /// @dev Function get support percentage decimals
    function supportPercentageDecimals() public pure returns (uint256) {
        return SUPPORT_PERCENTAGE_DECIMALS;
    }

    /// @dev Function get NFT information by tokenId
    /// @param _tokenId token ID.
    function getNFTInformation(uint256 _tokenId)
        public
        view
        whenTokenExists(_tokenId)
        returns (NFTInformation memory)
    {
        return NFTSInformation[_tokenId];
    }

    /// @dev Function get royalty Beneficiary
    /// @param _tokenId token ID.
    /// @param _index index need to get in royaltyBeneficiaries
    function getRoyaltyBeneficiary(uint256 _tokenId, uint256 _index)
        public
        view
        whenTokenExists(_tokenId)
        whenValidIndex(_tokenId, _index)
        returns (RoyaltyBeneficiary memory)
    {
        return royaltyBeneficiaries[_tokenId][_index];
    }

    /// @dev Function get royalty Beneficiaries
    /// @param _tokenId token ID.
    function getRoyaltyBeneficiaries(uint256 _tokenId)
        public
        view
        whenTokenExists(_tokenId)
        returns (RoyaltyBeneficiary[] memory)
    {
        NFTInformation memory currentNFT = getNFTInformation(_tokenId);
        RoyaltyBeneficiary[] memory lists = new RoyaltyBeneficiary[](
            currentNFT.totalSales + 1
        );
        for (uint256 i = 0; i <= currentNFT.totalSales; i++) {
            lists[i] = royaltyBeneficiaries[_tokenId][i];
        }
        return lists;
    }

    function getOffer(uint256 _tokenId)
        public
        view
        whenTokenExists(_tokenId)
        returns (Offer memory)
    {
        return offers[_tokenId];
    }

    /// @dev Function set  NFT information
    /// @param _tokenId token ID.
    /// @param _newPrice new price.
    /// @param _owner new owner.
    /// @param _totalSales new total Sales.
    function setNFTInformation(
        uint256 _tokenId,
        uint256 _newPrice,
        address _owner,
        uint256 _totalSales
    ) private whenTokenExists(_tokenId) whenNotZeroAddress(_owner) {
        NFTSInformation[_tokenId].lastPrice = _newPrice;
        NFTSInformation[_tokenId].currentOwner = payable(_owner);
        NFTSInformation[_tokenId].totalSales = _totalSales;
    }

    /// @dev Function set royalty Beneficiaries
    /// @param _tokenId token ID.
    /// @param _index index need to get in royaltyBeneficiaries
    /// @param _beneficiary new beneficiary.
    function setRoyaltyBeneficiary(
        uint256 _tokenId,
        uint256 _index,
        address payable _beneficiary,
        uint256 _priceIncreasePercent,
        uint256 _salePricePercent
    ) private whenTokenExists(_tokenId) whenNotZeroAddress(_beneficiary) {
        royaltyBeneficiaries[_tokenId][_index].beneficiary = payable(
            _beneficiary
        );
        royaltyBeneficiaries[_tokenId][_index]
            .priceIncreasePercent = _priceIncreasePercent;
        royaltyBeneficiaries[_tokenId][_index]
            .salePricePercent = _salePricePercent;
    }

    /// @dev Function get total supply
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /// @dev Function with draw eth in contract balance
    function withdraw() public nonReentrant onlyOwner {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(super.ownerOf(1)).call{
            value: address(this).balance
        }("");
        require(os);
        // =============================================================================
    }

    /// @dev Function get Royalty
    /// @param _tokenId token ID.
    /// @param _index token index
    function getRoyalty(uint256 _tokenId, uint256 _index)
        public
        view
        returns (RoyaltyBeneficiary memory)
    {
        return royaltyBeneficiaries[_tokenId][_index];
    }

    /// @dev Function get NFT admin address
    function appAdmin() public view returns (address payable) {
        return payable(NFTSInformation[1].currentOwner);
    }

    function incomeStreamContracts(address _baseIncomeStream)
        private
        view
        returns (address[] memory)
    {
        return
            IBaseIncomeStream(_baseIncomeStream).getIncomeStreamContracts(
                address(this),
                1
            );
    }

    /// @dev Function create offer.
    /// @param _tokenId token ID.
    /// @param _baseIncomeStream contract address of Base income sctream contract.
    function createPurchase(
        uint256 _tokenId,
        address _baseIncomeStream,
        address _appAdminIncomeStream
    ) public payable whenNotPaused {
        NFTInformation memory currentNFT = getNFTInformation(_tokenId);
        require(
            NFTSInformation[_tokenId].isBuyingAvailable,
            "METHOD_NOT_AVAILABLE"
        );
        Offer memory offer = offers[_tokenId];
        uint256 currentAmount = currentNFT.lastPrice;
        if (offer.isActive) {
            require(
                offer.endTime > block.timestamp,
                "TIME_END"
            );
            currentAmount = offer.bidAmount;
        }
        uint256 minOffer = (currentAmount *
            (100 + currentNFT.minimumPriceIncrease)) / 100;
        // There are 2 cases seller can buy the same price with nft price
        // 1. When enable offer for the nft, seller can purchase a same price with NFT price
        // 2. Seller buy the first time
        if (msg.sender == ownerOf(_tokenId)) {
            if (currentNFT.enabledOffer || currentNFT.totalSales == 0) {
                 minOffer = currentAmount;
            }
        }
        require(msg.value >= minOffer, "INVALID_AMOUNT");
        address[] memory incomeStreamAddresses = incomeStreamContracts(
            _baseIncomeStream
        );
        require(
            incomeStreamAddresses.length > 0,
            "INVALID_BASE_INCOME_STREAM_ADDRESS"
        );
        require(
            incomeStreamAddresses[0] == _appAdminIncomeStream,
            "INVALID_APP_INCOME_STREAM_ADDRESS"
        );
        offers[_tokenId] = Offer(
            _tokenId,
            msg.sender,
            msg.value,
            block.timestamp,
            block.timestamp + expireOfferTime,
            true,
            _appAdminIncomeStream
        );
        // only do this action when the NFT enable offer
        if (currentNFT.enabledOffer) {
            emit LogOfferNFT(_tokenId, ownerOf(_tokenId), msg.sender, msg.value);
        }
      
        if (msg.sender == ownerOf(_tokenId) || !currentNFT.enabledOffer) {
            forceBuy(_tokenId, msg.value, msg.sender);
        }
        if (currentNFT.enabledOffer || offer.isActive) {
            (bool sentPreviousBuyer, ) = payable(offer.buyer).call{
                value: offer.bidAmount
            }("");
            require(sentPreviousBuyer, "FAILED_SEND_PAYMENT_PREVIOUS_BUYER");
        }
    }

    /// @dev Function confirm offer.
    /// @param _tokenId token ID.
    function confirmPurchase(uint256 _tokenId) public whenNotPaused {
        require(
            NFTSInformation[_tokenId].isBuyingAvailable,
            "METHOD_NOT_AVAILABLE"
        );
        Offer memory offer = offers[_tokenId];
        require(offer.isActive, "OFFER_NOT_ACTIVE");
        require(
            offer.endTime < block.timestamp,
            "OFFER_NOT_END_YET"
        );
        forceBuy(_tokenId, offer.bidAmount, offer.buyer);
    }

    function calculateRoyaltyPrice(
        RoyaltyBeneficiary memory _royalty,
        uint256 _nftPrice,
        uint256 _buyingPirce
    ) private pure returns (uint256) {
        if (
            _royalty.salePricePercent > 0 && _royalty.priceIncreasePercent > 0
        ) {
            return
                ((_buyingPirce - _nftPrice) * _royalty.priceIncreasePercent) /
                (100 * supportPercentageDecimals()) +
                (_buyingPirce * _royalty.salePricePercent) /
                (100 * supportPercentageDecimals());
        } else if (_royalty.priceIncreasePercent > 0) {
            return
                ((_buyingPirce - _nftPrice) * _royalty.priceIncreasePercent) /
                (100 * supportPercentageDecimals());
        } else if (_royalty.salePricePercent > 0) {
            return
                (_buyingPirce * _royalty.salePricePercent) /
                (100 * supportPercentageDecimals());
        } else {
            return 0;
        }
    }

    /// @dev Function execute buying .
    /// @param _tokenId token ID.
    /// @param _buyingPrice buying amount.
    /// @param _buyer address of buyer.
    function forceBuy(
        uint256 _tokenId,
        uint256 _buyingPrice,
        address _buyer
    ) private {
        NFTInformation memory currentNFT = getNFTInformation(_tokenId);
        Offer memory offer = offers[_tokenId];
        setNFTInformation(
            _tokenId,
            _buyingPrice,
            _buyer,
            currentNFT.totalSales + 1
        );
        if (_tokenId == 1) {
            // update first NFT beneficiary
            royaltyBeneficiaries[1][0].beneficiary = payable(_buyer);
            // transfer ownership to new owner
            super._transferOwnership(_buyer);
        }
        // transfer token from current owner to buyer
        super._transfer(currentNFT.currentOwner, _buyer, _tokenId);
        if (offer.isActive) {
            delete offers[_tokenId];
        }
        if (currentNFT.isOwnershipRoyalty) {
            // finalRoyalty is store last Royalty
            RoyaltyBeneficiary memory finalRoyalty = RoyaltyBeneficiary(
                payable(address(this)),
                0,
                0
            );

            // check if this is the first purchase
            if (currentNFT.totalSales == 0) {
                finalRoyalty = getRoyalty(_tokenId, 0);
                // add current buyer to royalty beneficiary mapping, Royalty will be a half of final beneficiary
                setRoyaltyBeneficiary(
                    _tokenId,
                    currentNFT.totalSales + 1,
                    payable(_buyer),
                    finalRoyalty.priceIncreasePercent / 2,
                    finalRoyalty.salePricePercent / 2
                );
                // transfer all ether from buyer waller to current NFT's owner wallet
                bool sentAwardFirstBeneficiary = false;
                (sentAwardFirstBeneficiary, ) = currentNFT.currentOwner.call{
                    value: _buyingPrice
                }("");
                require(sentAwardFirstBeneficiary, "FAILED_SEND_PAYMENT_OWNER");
            } else {
                // total award to beneficiaries
                uint256 totalAwardToBeneficiaries = 0;
                for (uint256 i = 0; i <= currentNFT.totalSales; i++) {
                    // get current royalty beneficiaries list information
                    RoyaltyBeneficiary
                        memory currentRoyaltyBeneficiary = getRoyaltyBeneficiary(
                            _tokenId,
                            i
                        );
                    // store current royalty to finalRoyalty variables
                    finalRoyalty = currentRoyaltyBeneficiary;
                    if (i < currentNFT.totalSales) {
                        // calculate for Beneficiary's i
                        uint256 awardToBeneficiary = calculateRoyaltyPrice(
                            finalRoyalty,
                            currentNFT.lastPrice,
                            _buyingPrice
                        );
                        if (awardToBeneficiary > 1) {
                            // transfer calculate ether from buyer waller to  Beneficiary's i
                            bool sentAwardCurrentBeneficiary = false;
                            (
                                sentAwardCurrentBeneficiary,

                            ) = currentRoyaltyBeneficiary.beneficiary.call{
                                value: awardToBeneficiary
                            }("");
                            require(
                                sentAwardCurrentBeneficiary,
                                "FAILED_SEND_PAYMENT_BENEFICIARY"
                            );
                            // add awardToBeneficiary to totalAwardToBeneficiaries
                            totalAwardToBeneficiaries += awardToBeneficiary;
                        } else {
                            break;
                        }
                    }
                }
                uint256 appFee = calculateRoyaltyPrice(
                    finalRoyalty,
                    currentNFT.lastPrice,
                    _buyingPrice
                );
                // add current buyer to royalty beneficiary mapping, Royalty will be a half of final beneficiary
                setRoyaltyBeneficiary(
                    _tokenId,
                    currentNFT.totalSales + 1,
                    payable(_buyer),
                    finalRoyalty.priceIncreasePercent / 2,
                    finalRoyalty.salePricePercent / 2
                );
                // transfer to Income stream admin address
                if (appFee > 1) {
                    bool sentAdmin = false;
                    (sentAdmin, ) = payable(offer.incomeStreamAdmin).call{
                        value: appFee
                    }("");
                    require(sentAdmin, "FAILED_SEND_PAYMENT_ADMIN");
                }

                // transfer remaining ether from buyer to seller
                bool sentOwner = false;
                (sentOwner, ) = currentNFT.currentOwner.call{
                    value: _buyingPrice - totalAwardToBeneficiaries - appFee
                }("");
                require(sentOwner, "FAILED_SEND_PAYMENT_OWNER");
            }
        } else {
            uint256 appFee = 0;
            uint256 firstSellerAdward = 0;
            if (currentNFT.totalSales > 0) {
                // get current royalty beneficiaries list information
                RoyaltyBeneficiary
                    memory currentRoyaltyBeneficiary = getRoyaltyBeneficiary(
                        _tokenId,
                        0
                    );
                // store current royalty to finalRoyalty variables
                RoyaltyBeneficiary
                    memory firstRoyalty = currentRoyaltyBeneficiary;
                firstSellerAdward = calculateRoyaltyPrice(
                    firstRoyalty,
                    currentNFT.lastPrice,
                    _buyingPrice
                );

                appFee = firstSellerAdward / 2;

                // transfer to first seller
                (bool sentFirstSeller, ) = currentRoyaltyBeneficiary
                    .beneficiary
                    .call{value: firstSellerAdward}("");
                require(sentFirstSeller, "FAILED_SEND_PAYMENT_FIRST_SELLER");
                // transfer to NFT admin address
                if (appFee > 1) {
                    bool sentAdmin = false;
                    (sentAdmin, ) = payable(offer.incomeStreamAdmin).call{
                        value: appFee
                    }("");
                    require(sentAdmin, "FAILED_SEND_PAYMENT_ADMIN");
                }
            }
            // transfer all ether from buyer to seller
            bool sentOwner = false;
            (sentOwner, ) = currentNFT.currentOwner.call{
                value: _buyingPrice - appFee - firstSellerAdward
            }("");
            require(sentOwner, "FAILED_SEND_PAYMENT_OWNER");
        }

        // call event
        emit LogBuyNFT(_tokenId, currentNFT.currentOwner, _buyer, _buyingPrice);
        emit LogPriceHistory(_tokenId, _buyer, _buyingPrice, block.timestamp);
    }

    /// @dev Function update first NFT (admin is owner)
    /// @param _newOwner address of new owner.
    function updateAdminNFT(address _newOwner)
        private
        whenNotZeroAddress(_newOwner)
    {
        // get current nft owner
        address currentOwner = NFTSInformation[1].currentOwner;
        // transfer nft form old owner to new owner
        super._transfer(currentOwner, _newOwner, 1);
        // update first NFT owner
        NFTSInformation[1].currentOwner = payable(_newOwner);
        // update first NFT beneficiary
        royaltyBeneficiaries[1][0].beneficiary = payable(_newOwner);
        // transfer ownership to new owner
        super._transferOwnership(_newOwner);
    }

    /// @dev Function update users'sNFT
    /// @param _tokenId token ID.
    /// @param _from current owner address.
    /// @param _to new owner.
    function updateUsersNFT(
        uint256 _tokenId,
        address _from,
        address _to
    ) private whenNotZeroAddress(_to) {
        // get current nft owner
        NFTInformation memory currentNFT = NFTSInformation[_tokenId];
        // get newest beneficiary
        RoyaltyBeneficiary
            memory currentRoyaltyBeneficiary = getRoyaltyBeneficiary(
                _tokenId,
                currentNFT.totalSales
            );
        require(
            currentRoyaltyBeneficiary.beneficiary == _from &&
                currentNFT.currentOwner == _from,
            "INVALID_NFT_OWNER"
        );
        // update new beneficiary
        royaltyBeneficiaries[_tokenId][currentNFT.totalSales]
            .beneficiary = payable(_to);
        // update new owner
        NFTSInformation[_tokenId].currentOwner = payable(_to);
    }

    /**
     * @dev Transfers ownership of the contract to a new account ("newOwner").
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner)
        public
        override
        onlyOwner
        whenNotZeroAddress(_newOwner)
    {
        updateAdminNFT(_newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * "onlyOwner" functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override onlyOwner {
        // prevent this function
        // do nothing
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
        require(
            super._isApprovedOrOwner(super._msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        if (tokenId == 1) {
            updateAdminNFT(to);
        } else {
            updateUsersNFT(tokenId, from, to);
            super._safeTransfer(from, to, tokenId, data);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            super._isApprovedOrOwner(super._msgSender(), _tokenId),
            "ERC721: caller is not token owner or approved"
        );
        if (_tokenId == 1) {
            updateAdminNFT(_to);
        } else {
            updateUsersNFT(_tokenId, _from, _to);
            super._transfer(_from, _to, _tokenId);
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            _interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _price)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyBeneficiary
            memory currentRoyaltyBeneficiary = getRoyaltyBeneficiary(
                _tokenId,
                0
            );
        NFTInformation memory currentNFT = getNFTInformation(_tokenId);

        receiver = currentRoyaltyBeneficiary.beneficiary;
        royaltyAmount = calculateRoyaltyPrice(
            currentRoyaltyBeneficiary,
            currentNFT.lastPrice,
            _price
        );
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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