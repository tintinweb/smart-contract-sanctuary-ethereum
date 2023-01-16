// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC165.sol";

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
pragma solidity ^0.8.0;

import "./utils/String.sol";
import "./utils/Context.sol";
import "./utils/Address.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC165.sol";
import "./ERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";

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


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/String.sol";
import "./ERC721.sol";
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
pragma solidity ^0.8.0;

import "./IERC165.sol";

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
pragma solidity ^0.8.0;

import "./IERC721.sol";


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
pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./utils/Ownable.sol";
import "./utils/Counters.sol";

/* Voomio NFT-ERC721 */
contract VoomioNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private imageURI;
    uint256 private royaltyFee;
    address private royaltyRecipient;

     struct Artwork{
        address payable creator;
        uint8 royalty;
    }

    event NewNFT(
        uint256 tokenId
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _imageURI,
        address _owner,
        uint256 _royaltyFee,
        address _royaltyRecipient
    ) ERC721(_name, _symbol) {
        require(_royaltyFee <= 10000, "can't more than 10 percent");
        require(_royaltyRecipient != address(0), "The royalty recipient can't be 0 address");
        imageURI = _imageURI;
        royaltyFee = _royaltyFee;
        royaltyRecipient = _royaltyRecipient;
        transferOwnership(_owner);
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit NewNFT(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getRoyaltyFee() external view returns (uint256) {
        return royaltyFee;
    }

    function getRoyaltyRecipient() external view returns(address) {
        return royaltyRecipient;
    }

    function updateRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        require(_royaltyFee <= 10000, "can't more than 10 percent");
        royaltyFee = _royaltyFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Counters.sol";
import "./utils/Ownable.sol";
import "./interfaces/IERC721.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./VoomioNFT.sol";

contract VoomioNFTFactory {
    // owner address => nft list
    mapping(address => address[]) private nfts;

    mapping(address => bool) private voomioNFT;

    event CreatedNFTCollection(
        address creator,
        address nft,
        string name,
        string symbol
    );

    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        string memory _imageURI,
        uint256 _royaltyFee,
        address _royaltyRecipient
    ) external {
        VoomioNFT nft = new VoomioNFT(
            _name,
            _symbol,
            _imageURI,
            msg.sender,
            _royaltyFee,
            _royaltyRecipient
        );
        nfts[msg.sender].push(address(nft));
        voomioNFT[address(nft)] = true;
        emit CreatedNFTCollection(msg.sender, address(nft), _name, _symbol);
    }

    function getOwnCollections() external view returns (address[] memory) {
        return nfts[msg.sender];
    }

    function isVoomioNFT(address _nft) external view returns (bool) {
        return voomioNFT[_nft];
    }
}

interface IVoomioNFTFactory {
    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        uint256 _royaltyFee
    ) external;

    function isVoomioNFT(address _nft) external view returns (bool);
}

interface IVoomioNFT {
    function getRoyaltyFee() external view returns (uint256);

    function getRoyaltyRecipient() external view returns (address);
}

contract VoomioNFTMarketplace is Ownable, ReentrancyGuard {
    IVoomioNFTFactory private immutable voomioNFTFactory;

    uint256 private platformFee;
    address private feeRecipient;

    struct ListNFT {
        address nft;
        uint256 tokenId;
        address seller;
        address payToken;
        uint256 price;
        bool sold;
    }

    struct OfferNFT {
        address nft;
        uint256 tokenId;
        address offerer;
        address payToken;
        uint256 offerPrice;
        bool accepted;
    }

    struct AuctionNFT {
        address nft;
        uint256 tokenId;
        address creator;
        address payToken;
        uint256 initialPrice;
        uint256 minBid;
        uint256 startTime;
        uint256 endTime;
        address lastBidder;
        uint256 heighestBid;
        address winner;
        bool success;
    }

    mapping(address => bool) private payableToken;
    address[] private tokens;

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => ListNFT)) private listNfts;

    // nft => tokenId => offerer address => offer struct
    mapping(address => mapping(uint256 => mapping(address => OfferNFT)))
        private offerNfts;

    // nft => tokenId => acuton struct
    mapping(address => mapping(uint256 => AuctionNFT)) private auctionNfts;

    // auciton index => bidding counts => bidder address => bid price
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private bidPrices;

    // events
    event ListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address indexed seller
    );
    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        // uint256 price,
        address seller,
        address indexed buyer
    );
    event OfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address indexed offerer
    );
    event CanceledOfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address indexed offerer
    );
    event AcceptedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );
    event CreatedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );
    event PlacedBid(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 bidPrice,
        address indexed bidder
    );

    event ResultedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address creator,
        address indexed winner,
        uint256 price,
        address caller
    );

    constructor(
        uint256 _platformFee,
        address _feeRecipient,
        IVoomioNFTFactory _voomioNFTFactory
    ) {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        voomioNFTFactory = _voomioNFTFactory;
    }

    modifier isVoomioNFT(address _nft) {
        require(voomioNFTFactory.isVoomioNFT(_nft), "not Voomio NFT");
        _;
    }

    modifier isListedNFT(address _nft, uint256 _tokenId) {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(
            listedNFT.seller != address(0) && !listedNFT.sold,
            "not listed"
        );
        _;
    }

    modifier isNotListedNFT(address _nft, uint256 _tokenId) {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(
            listedNFT.seller == address(0) || listedNFT.sold,
            "already listed"
        );
        _;
    }

    modifier isAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft != address(0) && !auction.success,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft == address(0) || auction.success,
            "auction already created"
        );
        _;
    }

    modifier isOfferredNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    ) {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][_offerer];
        require(
            offer.offerPrice > 0 && offer.offerer != address(0),
            "not offerred nft"
        );
        _;
    }

    modifier isPayableToken(address _payToken) {
        require(
            _payToken != address(0) && payableToken[_payToken],
            "invalid pay token"
        );
        _;
    }

    /**
     * @notice put the NFT on marketplace
     * @param _nft specified NFT collection address
     * @param _tokenId specified NFT id to sell
     * @param _payToken ERC-20 token address for trading
     * @param _price the price of NFT
     */
    function createSell(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isNotListedNFT(_nft, _tokenId) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(
            (_payToken != address(0) && payableToken[_payToken]) ||
                _payToken == address(0),
            "invalid pay token"
        );
        nft.transferFrom(msg.sender, address(this), _tokenId);

        listNfts[_nft][_tokenId] = ListNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: msg.sender,
            payToken: _payToken,
            price: _price,
            sold: false
        });

        emit ListedNFT(_nft, _tokenId, _payToken, _price, msg.sender);
    }

    /**
     * @notice update sell price
     * @param _nft specified NFT collection address
     * @param _tokenId specified NFT id to sell
     * @param _price the price of NFT
     */
    function updateSellPrice(
        address _nft,
        uint256 _tokenId,
        uint256 _price
    ) external isListedNFT(_nft, _tokenId) {
        require(listNfts[_nft][_tokenId].seller == msg.sender, "not nft owner");

        listNfts[_nft][_tokenId] = ListNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: msg.sender,
            payToken: listNfts[_nft][_tokenId].payToken,
            price: _price,
            sold: false
        });

        emit ListedNFT(
            _nft,
            _tokenId,
            listNfts[_nft][_tokenId].payToken,
            _price,
            msg.sender
        );
    }

    /**
     * @notice cancel listed NFT from marketplace
     * @param _nft NFT collection address to sell
     * @param _tokenId specified NFT id to sell
     */
    function cancelListedNFT(address _nft, uint256 _tokenId)
        external
        isListedNFT(_nft, _tokenId)
    {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(listedNFT.seller == msg.sender, "not listed owner");
        IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
        delete listNfts[_nft][_tokenId];
    }

    /**
     * @notice buy a NFT from marketplace
     * @param _nft NFT collection address to buy
     * @param _tokenId specified NFT id to buy
     * @param _payToken ERC-20 token address for trading
     * @param _price NFT price
     */
    function buy(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isListedNFT(_nft, _tokenId) {
        ListNFT storage listedNft = listNfts[_nft][_tokenId];
        require(
            _payToken != address(0) && _payToken == listedNft.payToken,
            "invalid pay token"
        );
        require(!listedNft.sold, "nft already sold");
        require(_price >= listedNft.price, "invalid price");

        listedNft.sold = true;

        uint256 totalPrice = _price;
        IVoomioNFT nft = IVoomioNFT(listedNft.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, _price);

            // Transfer royalty fee to collection owner
            IERC20(listedNft.payToken).transferFrom(
                msg.sender,
                royaltyRecipient,
                royaltyTotal
            );
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(_price);
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            feeRecipient,
            platformFeeTotal
        );

        // Transfer to nft owner
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            listedNft.seller,
            totalPrice - platformFeeTotal
        );

        // Transfer NFT to buyer
        IERC721(listedNft.nft).safeTransferFrom(
            address(this),
            msg.sender,
            listedNft.tokenId
        );

        emit BoughtNFT(
            listedNft.nft,
            listedNft.tokenId,
            listedNft.payToken,
            // _price,
            listedNft.seller,
            msg.sender
        );
    }

    /**
     * @notice buy a NFT from marketplace
     * @param _nft NFT collection address to buy
     * @param _tokenId specified NFT id to buy
     */
    function buyByETH(address _nft, uint256 _tokenId)
        external
        payable
        isListedNFT(_nft, _tokenId)
    {
        ListNFT storage listedNft = listNfts[_nft][_tokenId];
        require(
            listedNft.payToken == address(0),
            "invalid pay token. try with buy function"
        );
        require(!listedNft.sold, "nft already sold");

        listedNft.sold = true;

        uint256 totalPrice = listedNft.price;
        IVoomioNFT nft = IVoomioNFT(listedNft.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(
                royaltyFee,
                listedNft.price
            );

            // Transfer royalty fee to collection owner
            (bool sent, ) = payable(royaltyRecipient).call{value: royaltyTotal}(
                ""
            );
            require(sent, "Failure! Fee ether not sent");

            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(listedNft.price);
        (bool sent2, ) = payable(feeRecipient).call{value: platformFeeTotal}(
            ""
        );
        require(sent2, "Failure! Platform fee ether not sent");

        // Transfer eth to nft owner
        (bool sent3, ) = payable(listedNft.seller).call{
            value: totalPrice - platformFeeTotal
        }("");
        require(sent3, "Failure! Platform fee ether not sent");

        // Transfer NFT to buyer
        IERC721(listedNft.nft).safeTransferFrom(
            address(this),
            msg.sender,
            listedNft.tokenId
        );

        emit BoughtNFT(
            listedNft.nft,
            listedNft.tokenId,
            listedNft.payToken,
            // _price,
            listedNft.seller,
            msg.sender
        );
    }

    // @notice Offer listed NFT
    function makeETHOffer(
        address _nft,
        uint256 _tokenId,
        uint256 _offerPrice
    ) external payable isListedNFT(_nft, _tokenId) {
        require(_offerPrice > 0, "price can not 0");

        ListNFT memory nft = listNfts[_nft][_tokenId];
        require(
            nft.payToken == address(0),
            "invalied pay token. try with makeOffer function"
        );
        (bool sent, ) = address(this).call{value: _offerPrice}("");
        require(sent, "Failure! Offer price ether not sent");

        offerNfts[_nft][_tokenId][msg.sender] = OfferNFT({
            nft: nft.nft,
            tokenId: nft.tokenId,
            offerer: msg.sender,
            payToken: address(0),
            offerPrice: _offerPrice,
            accepted: false
        });

        emit OfferredNFT(
            nft.nft,
            nft.tokenId,
            nft.payToken,
            _offerPrice,
            msg.sender
        );
    }

    // @notice Offer listed NFT
    function makeOffer(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _offerPrice
    ) external isListedNFT(_nft, _tokenId) {
        require(_offerPrice > 0, "price can not 0");

        ListNFT memory nft = listNfts[_nft][_tokenId];
        require(
            nft.payToken != address(0) && nft.payToken == _payToken,
            "invalied pay token"
        );
        IERC20(nft.payToken).transferFrom(
            msg.sender,
            address(this),
            _offerPrice
        );

        offerNfts[_nft][_tokenId][msg.sender] = OfferNFT({
            nft: nft.nft,
            tokenId: nft.tokenId,
            offerer: msg.sender,
            payToken: _payToken,
            offerPrice: _offerPrice,
            accepted: false
        });

        emit OfferredNFT(
            nft.nft,
            nft.tokenId,
            nft.payToken,
            _offerPrice,
            msg.sender
        );
    }

    /**
     * @notice cancel the made offer
     * @param _nft NFT collection address to buy
     * @param _tokenId NFT id to buy
     */
    function cancelETHOffer(address _nft, uint256 _tokenId)
        external
        isOfferredNFT(_nft, _tokenId, msg.sender)
    {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][msg.sender];
        require(offer.payToken == address(0), "invalied pay token");
        require(offer.offerer == msg.sender, "not offerer");
        require(!offer.accepted, "offer already accepted");
        delete offerNfts[_nft][_tokenId][msg.sender];

        payable(offer.offerer).transfer(offer.offerPrice);
        emit CanceledOfferredNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            msg.sender
        );
    }

    /**
     * @notice cancel the made offer
     * @param _nft NFT collection address to buy
     * @param _tokenId NFT id to buy
     */
    function cancelOffer(address _nft, uint256 _tokenId)
        external
        isOfferredNFT(_nft, _tokenId, msg.sender)
    {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][msg.sender];
        require(offer.payToken != address(0), "invalied pay token");
        require(offer.offerer == msg.sender, "not offerer");
        require(!offer.accepted, "offer already accepted");
        delete offerNfts[_nft][_tokenId][msg.sender];
        IERC20(offer.payToken).transfer(offer.offerer, offer.offerPrice);
        emit CanceledOfferredNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            msg.sender
        );
    }

    /**
     * @notice listed NFT owner accept offerring
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _offerer the user address that created this offer
     */
    function acceptOfferNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    )
        external
        isOfferredNFT(_nft, _tokenId, _offerer)
        isListedNFT(_nft, _tokenId)
    {
        require(
            listNfts[_nft][_tokenId].seller == msg.sender,
            "not listed owner"
        );
        OfferNFT storage offer = offerNfts[_nft][_tokenId][_offerer];
        require(offer.payToken != address(0), "invalied pay token");
        ListNFT storage list = listNfts[offer.nft][offer.tokenId];
        require(!list.sold, "already sold");
        require(!offer.accepted, "offer already accepted");

        list.sold = true;
        offer.accepted = true;

        uint256 offerPrice = offer.offerPrice;
        uint256 totalPrice = offerPrice;

        IVoomioNFT nft = IVoomioNFT(offer.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        IERC20 payToken = IERC20(offer.payToken);

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, offerPrice);

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(offerPrice);
        payToken.transfer(feeRecipient, platformFeeTotal);

        // Transfer to seller
        payToken.transfer(list.seller, totalPrice - platformFeeTotal);

        // Transfer NFT to offerer
        IERC721(list.nft).safeTransferFrom(
            address(this),
            offer.offerer,
            list.tokenId
        );

        emit AcceptedNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            offer.offerer,
            list.seller
        );
    }

    /**
     * @notice listed NFT owner accept offerring
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _offerer the user address that created this offer
     */
    function acceptETHOfferNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    )
        external
        isOfferredNFT(_nft, _tokenId, _offerer)
        isListedNFT(_nft, _tokenId)
    {
        require(
            listNfts[_nft][_tokenId].seller == msg.sender,
            "not listed owner"
        );
        OfferNFT storage offer = offerNfts[_nft][_tokenId][_offerer];
        require(offer.payToken == address(0), "invalied pay token");
        ListNFT storage list = listNfts[offer.nft][offer.tokenId];
        require(!list.sold, "already sold");
        require(!offer.accepted, "offer already accepted");

        list.sold = true;
        offer.accepted = true;

        uint256 offerPrice = offer.offerPrice;
        uint256 totalPrice = offerPrice;

        IVoomioNFT nft = IVoomioNFT(offer.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, offerPrice);

            // Transfer royalty fee to collection owner
            payable(royaltyRecipient).transfer(royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(offerPrice);
        payable(feeRecipient).transfer(platformFeeTotal);

        // Transfer to seller
        payable(list.seller).transfer(totalPrice - platformFeeTotal);

        // Transfer NFT to offerer
        IERC721(list.nft).safeTransferFrom(
            address(this),
            offer.offerer,
            list.tokenId
        );

        emit AcceptedNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            offer.offerer,
            list.seller
        );
    }

    /**
     * @notice create a auction to buy
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _payToken ERC-20 token address for trading
     * @param _price NFT price
     * @param _minBid minimum bid price
     * @param _startTime the time to start bid.
     * @param _endTime the time to end bid and NFT is transfered to max bider.
     */
    function createAuction(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime
    ) external isNotAuction(_nft, _tokenId) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(_endTime > _startTime, "invalid end time");
        require(
            (_payToken != address(0) && payableToken[_payToken]) ||
                _payToken == address(0),
            "invalid pay token"
        );

        nft.transferFrom(msg.sender, address(this), _tokenId);

        auctionNfts[_nft][_tokenId] = AuctionNFT({
            nft: _nft,
            tokenId: _tokenId,
            creator: msg.sender,
            payToken: _payToken,
            initialPrice: _price,
            minBid: _minBid,
            startTime: _startTime,
            endTime: _endTime,
            lastBidder: address(0),
            heighestBid: _price,
            winner: address(0),
            success: false
        });

        emit CreatedAuction(
            _nft,
            _tokenId,
            _payToken,
            _price,
            _minBid,
            _startTime,
            _endTime,
            msg.sender
        );
    }

    /**
     * @notice cancel the auction to buy
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function cancelAuction(address _nft, uint256 _tokenId)
        external
        isAuction(_nft, _tokenId)
    {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(auction.creator == msg.sender, "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.lastBidder == address(0), "already have bidder");

        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete auctionNfts[_nft][_tokenId];
    }

    /**
     * @notice Bid place auction
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _bidPrice bid price
     */
    function placeBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external isAuction(_nft, _tokenId) {
        require(
            block.timestamp >= auctionNfts[_nft][_tokenId].startTime,
            "auction not start"
        );
        require(
            block.timestamp <= auctionNfts[_nft][_tokenId].endTime,
            "auction ended"
        );
        require(
            _bidPrice >=
                auctionNfts[_nft][_tokenId].heighestBid +
                    auctionNfts[_nft][_tokenId].minBid,
            "less than min bid price"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        require(auction.payToken != address(0), "not erc20 auction");

        IERC20 payToken = IERC20(auction.payToken);
        payToken.transferFrom(msg.sender, address(this), _bidPrice);

        if (auction.lastBidder != address(0)) {
            address lastBidder = auction.lastBidder;
            uint256 lastBidPrice = auction.heighestBid;

            // Transfer back to last bidder
            payToken.transfer(lastBidder, lastBidPrice);
        }

        // Set new heighest bid price
        auction.lastBidder = msg.sender;
        auction.heighestBid = _bidPrice;

        emit PlacedBid(_nft, _tokenId, auction.payToken, _bidPrice, msg.sender);
    }

    /**
     * @notice Bid place auction
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _bidPrice bid price
     */
    function placeETHBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external payable isAuction(_nft, _tokenId) {
        require(
            block.timestamp >= auctionNfts[_nft][_tokenId].startTime,
            "auction not start"
        );
        require(
            block.timestamp <= auctionNfts[_nft][_tokenId].endTime,
            "auction ended"
        );
        require(
            _bidPrice >=
                auctionNfts[_nft][_tokenId].heighestBid +
                    auctionNfts[_nft][_tokenId].minBid,
            "less than min bid price"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        require(auction.payToken == address(0), "not eth auction");

        (bool sent, ) = payable(address(this)).call{value: _bidPrice}("");
        require(sent, "Failure! bid price ether not sent");

        if (auction.lastBidder != address(0)) {
            address lastBidder = auction.lastBidder;
            uint256 lastBidPrice = auction.heighestBid;

            // Transfer back to last bidder
            payable(lastBidder).transfer(lastBidPrice);
        }

        // Set new heighest bid price
        auction.lastBidder = msg.sender;
        auction.heighestBid = _bidPrice;

        emit PlacedBid(_nft, _tokenId, auction.payToken, _bidPrice, msg.sender);
    }

    /**
     * @notice complete auction, can call by auction creator, heighest bidder, or marketplace owner only!
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function completeBid(address _nft, uint256 _tokenId) external {
        require(!auctionNfts[_nft][_tokenId].success, "already resulted");
        require(
            msg.sender == owner() ||
                msg.sender == auctionNfts[_nft][_tokenId].creator ||
                msg.sender == auctionNfts[_nft][_tokenId].lastBidder,
            "not creator, winner, or owner"
        );
        require(
            block.timestamp > auctionNfts[_nft][_tokenId].endTime,
            "auction not ended"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        require(auction.payToken != address(0), "not erc20 auction");

        IERC20 payToken = IERC20(auction.payToken);
        IERC721 nft = IERC721(auction.nft);

        auction.success = true;
        auction.winner = auction.creator;

        IVoomioNFT VoomioNft = IVoomioNFT(_nft);
        address royaltyRecipient = VoomioNft.getRoyaltyRecipient();
        uint256 royaltyFee = VoomioNft.getRoyaltyFee();

        uint256 heighestBid = auction.heighestBid;
        uint256 totalPrice = heighestBid;

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, heighestBid);

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(heighestBid);
        payToken.transfer(feeRecipient, platformFeeTotal);

        // Transfer to auction creator
        payToken.transfer(auction.creator, totalPrice - platformFeeTotal);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        emit ResultedAuction(
            _nft,
            _tokenId,
            auction.creator,
            auction.lastBidder,
            auction.heighestBid,
            msg.sender
        );
    }

    /**
     * @notice complete auction, can call by auction creator, heighest bidder, or marketplace owner only!
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function completeETHBid(address _nft, uint256 _tokenId) external {
        require(!auctionNfts[_nft][_tokenId].success, "already resulted");
        require(
            msg.sender == owner() ||
                msg.sender == auctionNfts[_nft][_tokenId].creator ||
                msg.sender == auctionNfts[_nft][_tokenId].lastBidder,
            "not creator, winner, or owner"
        );
        require(
            block.timestamp > auctionNfts[_nft][_tokenId].endTime,
            "auction not ended"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        require(auction.payToken == address(0), "not eth auction");

        IERC721 nft = IERC721(auction.nft);

        auction.success = true;
        auction.winner = auction.creator;

        IVoomioNFT VoomioNft = IVoomioNFT(_nft);
        address royaltyRecipient = VoomioNft.getRoyaltyRecipient();
        uint256 royaltyFee = VoomioNft.getRoyaltyFee();

        uint256 heighestBid = auction.heighestBid;
        uint256 totalPrice = heighestBid;

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, heighestBid);

            // Transfer royalty fee to collection owner
            payable(royaltyRecipient).transfer(royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(heighestBid);
        payable(feeRecipient).transfer(platformFeeTotal);

        // Transfer to auction creator
        payable(auction.creator).transfer(totalPrice - platformFeeTotal);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        emit ResultedAuction(
            _nft,
            _tokenId,
            auction.creator,
            auction.lastBidder,
            auction.heighestBid,
            msg.sender
        );
    }

    function calculatePlatformFee(uint256 _price)
        public
        view
        returns (uint256)
    {
        return (_price * platformFee) / 10000;
    }

    function calculateRoyalty(uint256 _royalty, uint256 _price)
        public
        pure
        returns (uint256)
    {
        return (_price * _royalty) / 10000;
    }

    function getListedNFT(address _nft, uint256 _tokenId)
        public
        view
        returns (ListNFT memory)
    {
        return listNfts[_nft][_tokenId];
    }

    function getPayableTokens() external view returns (address[] memory) {
        return tokens;
    }

    function checkIsPayableToken(address _payableToken)
        external
        view
        returns (bool)
    {
        return payableToken[_payableToken];
    }

    function addPayableToken(address _token) external onlyOwner {
        require(_token != address(0), "invalid token");
        require(!payableToken[_token], "already payable token");
        payableToken[_token] = true;
        tokens.push(_token);
    }

    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "can't be 0 address");
        feeRecipient = _feeRecipient;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}