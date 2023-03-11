// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

/*
ERC20BondStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IStakingModule.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/IMetadata.sol";
import "./OwnerController.sol";
import "./TokenUtils.sol";

/**
 * @title ERC20 bond staking module
 *
 * @notice this staking module allows users to permanently sell an ERC20 token
 * in exchange for bond shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC20BondStakingModule is IStakingModule, OwnerController, ERC721 {
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;

    // events
    event MarketOpened(
        address token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    );
    event MarketClosed(address token);
    event MarketAdjusted(
        address token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    );
    event MarketBalanceWithdrawn(address token, uint256 amount);

    // bond market
    struct Market {
        uint256 price;
        uint256 coeff; // pricing coefficient
        uint256 max; // max debt for single stake
        uint256 capacity; // remaining debt capacity
        uint256 principal;
        uint256 vested;
        uint256 debt;
        uint256 updated;
    }

    // bond position
    struct Bond {
        address market;
        uint64 timestamp;
        uint256 principal; // shares
        uint256 debt; // shares
    }

    // adjustment
    struct Adjustment {
        uint256 price;
        uint256 coeff;
        uint256 timestamp;
    }

    // constant
    uint256 public constant INITIAL_SHARES_PER_TOKEN = 10 ** 6;
    uint256 public constant MAX_MARKETS = 16;
    uint256 public constant MAX_BONDS = 128;
    uint256 public constant MIN_PERIOD = 3600;

    // members: config
    uint256 public immutable period;
    bool public immutable burndown;
    address private immutable _factory;
    IConfiguration private immutable _config;

    // members: bonds
    mapping(address => Market) public markets;
    address[] private _markets;
    mapping(address => uint256) _marketIndex;
    mapping(uint256 => Bond) public bonds;
    mapping(address => Adjustment) public adjustments;

    // members: indexing
    mapping(address => mapping(uint256 => uint256)) public ownerBonds;
    mapping(uint256 => uint256) public bondIndex;
    uint256 public nonce;

    /**
     * @param period_ bond vesting period
     * @param burndown_ enable burndown period and opt-out for deposited user funds
     * @param config_ address for configuration contract
     * @param factory_ address of module factory
     */
    constructor(
        uint256 period_,
        bool burndown_,
        address config_,
        address factory_
    ) ERC721("GYSR Bond Position", "GYSR-BOND") {
        require(period_ > MIN_PERIOD, "bsm1");
        period = period_;
        burndown = burndown_;
        _config = IConfiguration(config_);
        _factory = factory_;

        nonce = 1;
    }

    // -- IStakingModule -------------------------------------------------

    /**
     * @inheritdoc IStakingModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        return _markets;
    }

    /**
     * @inheritdoc IStakingModule
     *
     * @dev user balances will dynamically decrease as bonds vest to reflect
     * the amount that can actually be withdrawn
     */
    function balances(
        address user
    ) external view override returns (uint256[] memory balances_) {
        balances_ = new uint256[](_markets.length);
        if (!burndown) return balances_;
        uint256 count = balanceOf(user);
        if (count > MAX_BONDS) count = MAX_BONDS;
        for (uint256 i = 0; i < count; i++) {
            Bond storage b = bonds[ownerBonds[user][i]];
            uint256 dt = block.timestamp - b.timestamp;
            if (dt > period) {
                continue;
            }
            uint256 s = (b.principal * (period - dt)) / period;
            uint256 amount = _amount(b.market, s);
            balances_[_marketIndex[b.market]] += amount;
        }
    }

    /**
     * @inheritdoc IStakingModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function totals()
        external
        view
        override
        returns (uint256[] memory totals_)
    {
        totals_ = new uint256[](_markets.length);
        for (uint256 i; i < _markets.length; i++) {
            totals_[0] = IERC20(_markets[i]).balanceOf(address(this));
        }
    }

    /**
     * @inheritdoc IStakingModule
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, uint256) {
        // validate
        require(amount > 0, "bsm2");
        require(data.length == 32 || data.length == 64, "bsm3");
        address token;
        assembly {
            token := calldataload(132)
        }
        uint256 minimum;
        if (data.length == 64) {
            assembly {
                minimum := calldataload(164)
            }
        }
        Market storage m = markets[token];
        uint256 capacity = m.capacity;
        require(capacity > 0, "bsm4");

        // update
        _update(token);

        // transfer and process fees
        uint256 minted;
        {
            (address receiver, uint256 rate) = _config.getAddressUint96(
                keccak256("gysr.core.bond.stake.fee")
            );
            minted = IERC20(token).receiveWithFee(
                m.principal,
                sender,
                amount,
                receiver,
                rate
            );
        }

        // pricing
        uint256 debt = (minted * 1e18) / (m.price + (m.coeff * m.debt) / 1e18);
        require(debt <= m.max, "bsm5");
        require(debt <= capacity, "bsm6");
        require(debt >= minimum, "bsm7");

        // create new bond
        uint256 id = nonce;
        nonce = id + 1;
        bonds[id] = Bond({
            market: token,
            timestamp: uint64(block.timestamp),
            principal: burndown ? minted : 0, // only need to store if burndown enabled
            debt: debt
        });

        // update bond market
        m.debt += debt;
        m.capacity = capacity - debt;
        m.principal += minted;
        if (!burndown) {
            m.vested += minted;
        }

        // mint position
        _safeMint(sender, id);

        // external
        emit Staked(bytes32(id), sender, token, amount, debt);

        return (bytes32(id), debt);
    }

    /**
     * @inheritdoc IStakingModule
     *
     * @dev pass amount zero to unstake all or to unstake fully vested bond
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(data.length == 32, "bsm8");
        uint256 id;
        assembly {
            id := calldataload(132)
        }
        require(ownerOf(id) == sender, "bsm9");

        // default unstake with no principal returned
        Bond storage b = bonds[id];
        address token = b.market;
        uint256 shares;
        uint256 debt = b.debt;
        uint256 elapsed = block.timestamp - b.timestamp;
        require(elapsed > 0, "bsm10");

        // update
        _update(token);

        if (amount > 0) {
            // unstake specific amount
            require(burndown, "bsm11");

            // timing
            require(elapsed < period, "bsm12");

            // convert to shares
            shares = IERC20(token).getShares(markets[token].principal, amount); // must have non zero unvested balance
            require(shares > 0, "bsm13");
            uint256 bprincipal = b.principal;
            uint256 bdebt = debt;
            require(
                shares < (bprincipal * (period - elapsed)) / period,
                "bsm14"
            ); // strictly less than total unvested

            // compute burned principal and debt shares
            uint256 burned = (shares * period) / (period - elapsed);
            debt = (bdebt * burned) / bprincipal;

            // decrease bond position
            b.principal = bprincipal - burned;
            b.debt = bdebt - debt;
        } else {
            // unstake all
            if (burndown) {
                if (elapsed < period) {
                    // return any unvested principal
                    shares = (b.principal * (period - elapsed)) / period;
                    amount = IERC20(token).getAmount(
                        markets[token].principal,
                        shares
                    );
                }
            }
            // delete bond position
            delete bonds[id];
            _burn(id);
        }

        // transfer principal back to user
        if (shares > 0) {
            // note: unwinding debt here does introduce a price drop and frontrunning opportunity,
            // but it also prevents manipulation of debt via repeated staking and unstaking
            markets[token].debt -= (debt * (period - elapsed)) / period;
            markets[token].principal -= shares;
            IERC20(token).safeTransfer(sender, amount);
        }

        // external
        emit Unstaked(bytes32(id), sender, token, amount, debt);
        return (bytes32(id), sender, debt);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address sender,
        uint256,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(data.length == 32, "bsm15");
        uint256 id;
        assembly {
            id := calldataload(132)
        }
        require(ownerOf(id) == sender, "bsm16");

        Bond storage b = bonds[id];
        address token = b.market;
        uint256 debt = b.debt;

        // update
        _update(token);

        // external
        emit Claimed(bytes32(id), sender, token, 0, debt);
        return (bytes32(id), sender, debt);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(
        address sender,
        bytes calldata data
    ) external override returns (bytes32) {
        // validate
        requireOwner();
        require(data.length == 32, "bsm17");
        uint256 id;
        assembly {
            id := calldataload(100)
        }
        require(ownerOf(id) == sender, "bsm18");

        // update
        _update(bonds[id].market);

        return bytes32(id);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function clean(bytes calldata) external override {}

    // -- ERC20BondStakingModule -----------------------------------------

    /**
     * @notice open a new bond market
     * @param token the principal token that will be deposited
     * @param price minimum and starting price of the bond in tokens
     * @param coeff bond pricing coefficient
     * @param max maximum size for an individual bond in debt shares
     * @param capacity the total debt available for this market in shares
     */
    function open(
        address token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    ) external {
        requireController();
        require(markets[token].max == 0, "bsm19");
        require(_markets.length < MAX_MARKETS, "bsm20");
        require(price > 0, "bsm21");
        require(max > 0, "bsm22");
        require(capacity > 0, "bsm23");

        markets[token] = Market({
            price: price,
            coeff: coeff,
            max: max,
            capacity: capacity,
            principal: 0,
            vested: 0,
            debt: 0,
            updated: block.timestamp
        });
        _markets.push(token);
        _marketIndex[token] = _markets.length - 1;

        emit MarketOpened(token, price, coeff, max, capacity);
    }

    /**
     * @notice close an existing bond market
     * @param token the token address of the market to close
     */
    function close(address token) external {
        requireController();
        require(markets[token].capacity > 0, "bsm24");
        markets[token].capacity = 0;
        emit MarketClosed(token);
    }

    /**
     * @notice adjust the configuration of an existing bond market
     * @param token the token address of the market to adjust
     * @param price minimum and starting price of the bond in tokens
     * @param coeff bond pricing coefficient
     * @param max maximum size for an individual bond in debt shares
     * @param capacity the total debt available for this market in shares
     */
    function adjust(
        address token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    ) external {
        requireController();
        require(markets[token].max > 0, "bsm25");
        require(price > 0, "bsm26");
        require(max > 0, "bsm27");
        require(capacity > 0, "bsm28");

        // update
        _update(token);

        // adjust market
        markets[token].max = max;
        markets[token].capacity = capacity;

        // gradual adjustment for price related params
        adjustments[token] = Adjustment({
            price: price,
            coeff: coeff,
            timestamp: block.timestamp
        });

        emit MarketAdjusted(token, price, coeff, max, capacity);
    }

    /**
     * @notice withdraw vested principal token from market
     * @param token the principal token address
     * @param amount number of tokens to withdraw
     */
    function withdraw(address token, uint256 amount) external {
        requireController();
        // validate
        Market storage m = markets[token];
        require(m.max > 0, "bsm29");
        require(amount > 0, "bsm30");

        // update
        _update(token);

        IERC20 tkn = IERC20(token);
        uint256 shares = tkn.getShares(m.principal, amount);
        require(shares <= m.vested, "bsm31");

        // withdraw
        m.vested -= shares;
        m.principal -= shares;
        tkn.safeTransfer(msg.sender, amount);

        emit MarketBalanceWithdrawn(token, amount);
    }

    // -- ERC721 ---------------------------------------------------------

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        address metadata = _config.getAddress(
            keccak256("gysr.core.module.bond.metadata.v3")
        );
        return IMetadata(metadata).metadata(address(this), tokenId, "");
    }

    // -- ERC20BondStakingModule internal --------------------------------

    /**
     * @dev internal helper to get token amount from shares
     * @param token address of token
     * @param shares number of shares
     */
    function _amount(
        address token,
        uint256 shares
    ) private view returns (uint256) {
        return IERC20(token).getAmount(markets[token].principal, shares);
    }

    /**
     * @dev internal market update helper for principal vesting, debt decay, and parameter tuning
     * @param token the token address of the market to update
     */
    function _update(address token) private {
        Market storage m = markets[token];

        uint256 elapsed = block.timestamp - m.updated;
        if (elapsed < period) {
            // vest principal
            if (burndown) {
                uint256 vested = m.vested;
                m.vested = vested + ((m.principal - vested) * elapsed) / period; // approximation, exact value upper bound
            }

            // decay debt
            uint256 debt = m.debt;
            m.debt = debt - (debt * elapsed) / period; // approximation, exact value lower bound
        } else {
            // vest principal
            if (burndown) m.vested = m.principal;

            // decay debt
            m.debt = 0;
        }

        // adjustments
        uint256 start = adjustments[token].timestamp;
        if (start > 0) {
            if (block.timestamp < start + period) {
                // interpolate
                uint256 target = adjustments[token].price;
                uint256 curr = m.price;
                uint256 remaining = start + period + elapsed - block.timestamp;
                if (target > curr) {
                    m.price = curr + ((target - curr) * elapsed) / remaining;
                } else {
                    m.price = curr - ((curr - target) * elapsed) / remaining;
                }
                target = adjustments[token].coeff;
                curr = m.coeff;
                if (target > curr) {
                    m.coeff = curr + ((target - curr) * elapsed) / remaining;
                } else {
                    m.coeff = curr - ((curr - target) * elapsed) / remaining;
                }
            } else {
                // complete adjustment
                m.price = adjustments[token].price;
                m.coeff = adjustments[token].coeff;
                delete adjustments[token];
            }
        }

        m.updated = block.timestamp;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from != address(0)) _remove(from, tokenId);
        if (to != address(0)) _append(to, tokenId);
    }

    /**
     * @dev internal helper function to add bond position
     */
    function _append(address user, uint256 id) private {
        uint256 len = balanceOf(user);
        ownerBonds[user][len] = id;
        bondIndex[id] = len;
    }

    /**
     * @dev internal helper function to delete and reindex bond position
     */
    function _remove(address user, uint256 id) private {
        uint256 index = bondIndex[id];
        uint256 lastIndex = balanceOf(user) - 1;
        if (index != lastIndex) {
            uint256 lastId = ownerBonds[user][lastIndex];
            ownerBonds[user][index] = lastId;
            bondIndex[lastId] = index;
        }
        delete ownerBonds[user][lastIndex];
        delete bondIndex[id];
    }
}

/*
ERC20BondStakingModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IModuleFactory.sol";
import "./ERC20BondStakingModule.sol";

/**
 * @title ERC20 bond staking module factory
 *
 * @notice this factory contract handles deployment for the
 * ERC20BondStakingModule contract
 *
 * @dev it is called by the parent PoolFactory and is responsible
 * for parsing constructor arguments before creating a new contract
 */
contract ERC20BondStakingModuleFactory is IModuleFactory {
    /**
     * @inheritdoc IModuleFactory
     */
    function createModule(
        address config,
        bytes calldata data
    ) external override returns (address) {
        // validate
        require(data.length == 64, "bsmf1");

        // parse staking token
        uint256 period;
        bool burndown;
        assembly {
            period := calldataload(100)
            burndown := calldataload(132)
        }

        // create module
        ERC20BondStakingModule module = new ERC20BondStakingModule(
            period,
            burndown,
            config,
            address(this)
        );
        module.transferOwnership(msg.sender);

        // output
        emit ModuleCreated(msg.sender, address(module));
        return address(module);
    }
}

/*
IConfiguration

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Configuration interface
 *
 * @notice this defines the protocol configuration interface
 */
interface IConfiguration {
    // events
    event ParameterUpdated(bytes32 indexed key, address value);
    event ParameterUpdated(bytes32 indexed key, uint256 value);
    event ParameterUpdated(bytes32 indexed key, address value0, uint96 value1);
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        uint256 value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value0,
        uint96 value1
    );

    /**
     * @notice set or update uint256 parameter
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function setUint256(bytes32 key, uint256 value) external;

    /**
     * @notice set or update address parameter
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function setAddress(bytes32 key, address value) external;

    /**
     * @notice set or update packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function setAddressUint96(
        bytes32 key,
        address value0,
        uint96 value1
    ) external;

    /**
     * @notice get uint256 parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice get address parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @notice get packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @return address parameter value
     * @return uint96 parameter value
     */
    function getAddressUint96(bytes32 key) external returns (address, uint96);

    /**
     * @notice override uint256 parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function overrideUint256(
        address caller,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function overrideAddress(
        address caller,
        bytes32 key,
        address value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function overrideAddressUint96(
        address caller,
        bytes32 key,
        address value0,
        uint96 value1
    ) external;
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.18;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        bytes32 indexed account,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Updated(bytes32 indexed account, address indexed user);

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsWithdrawn(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUpdated(bytes32 indexed account);

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
IMetadata

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Metadata interface
 *
 * @notice this defines the metadata library interface for tokenized staking modules
 */
interface IMetadata {
    /**
     * @notice provide the metadata URI for a tokenized staking module position
     * @param module address of staking module
     * @param id position identifier
     * @param data additional encoded data
     */
    function metadata(
        address module,
        uint256 id,
        bytes calldata data
    ) external view returns (string memory);
}

/*
IModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Module factory interface
 *
 * @notice this defines the common module factory interface used by the
 * main factory to create the staking and reward modules for a new Pool.
 */
interface IModuleFactory {
    // events
    event ModuleCreated(address indexed user, address module);

    /**
     * @notice create a new Pool module
     * @param config address for configuration contract
     * @param data binary encoded construction parameters
     * @return address of newly created module
     */
    function createModule(address config, bytes calldata data)
        external
        returns (address);
}

/*
IOwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Owner controller interface
 *
 * @notice this defines the interface for any contracts that use the
 * owner controller access pattern
 */
interface IOwnerController {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) external;
}

/*
IStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";
import "./IOwnerController.sol";

/**
 * @title Staking module interface
 *
 * @notice this contract defines the common interface that any staking module
 * must implement to be compatible with the modular Pool architecture.
 */
interface IStakingModule is IOwnerController, IEvents {
    /**
     * @return array of staking tokens
     */
    function tokens() external view returns (address[] memory);

    /**
     * @notice get balance of user
     * @param user address of user
     * @return balances of each staking token
     */
    function balances(address user) external view returns (uint256[] memory);

    /**
     * @return address of module factory
     */
    function factory() external view returns (address);

    /**
     * @notice get total staked amount
     * @return totals for each staking token
     */
    function totals() external view returns (uint256[] memory);

    /**
     * @notice stake an amount of tokens for user
     * @param sender address of sender
     * @param amount number of tokens to stake
     * @param data additional data
     * @return bytes32 id of staking account
     * @return number of shares minted for stake
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, uint256);

    /**
     * @notice unstake an amount of tokens for user
     * @param sender address of sender
     * @param amount number of tokens to unstake
     * @param data additional data
     * @return bytes32 id of staking account
     * @return address of reward receiver
     * @return number of shares burned for unstake
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, address, uint256);

    /**
     * @notice quote the share value for an amount of tokens without unstaking
     * @param sender address of sender
     * @param amount number of tokens to claim with
     * @param data additional data
     * @return bytes32 id of staking account
     * @return address of reward receiver
     * @return number of shares that the claim amount is worth
     */
    function claim(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32, address, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @dev will only be called ad hoc and should not contain essential logic
     * @param sender address of user for update
     * @param data additional data
     * @return bytes32 id of staking account
     */
    function update(
        address sender,
        bytes calldata data
    ) external returns (bytes32);

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     * @param data additional data
     */
    function clean(bytes calldata data) external;
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IOwnerController.sol";

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController is IOwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual override {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}

/*
TokenUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Token utilities
 *
 * @notice this library implements utility methods for token handling,
 * dynamic balance accounting, and fee processing
 */
library TokenUtils {
    using SafeERC20 for IERC20;

    uint256 constant INITIAL_SHARES_PER_TOKEN = 1e6;

    /**
     * @notice get token shares from amount
     * @param token erc20 token interface
     * @param total current total shares
     * @param amount balance of tokens
     */
    function getShares(
        IERC20 token,
        uint256 total,
        uint256 amount
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        return (total * amount) / token.balanceOf(address(this));
    }

    /**
     * @notice get token amount from shares
     * @param token erc20 token interface
     * @param total current total shares
     * @param shares balance of shares
     */
    function getAmount(
        IERC20 token,
        uint256 total,
        uint256 shares
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        return (token.balanceOf(address(this)) * shares) / total;
    }

    /**
     * @notice transfer tokens from sender into contract and convert to shares
     * for internal accounting
     * @param token erc20 token interface
     * @param shares current total shares
     * @param sender token sender
     * @param amount number of tokens to be sent
     */
    function receiveAmount(
        IERC20 token,
        uint256 shares,
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        //  transfer
        uint256 total = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount);
        uint256 actual = token.balanceOf(address(this)) - total;

        // mint shares at current rate
        uint256 minted = (total > 0)
            ? (shares * actual) / total
            : actual * INITIAL_SHARES_PER_TOKEN;
        require(minted > 0);
        return minted;
    }

    /**
     * @notice transfer tokens from sender into contract, process protocol fee,
     * and convert to shares for internal accounting
     * @param token erc20 token interface
     * @param shares current total shares
     * @param sender token sender
     * @param amount number of tokens to be sent
     * @param feeReceiver address to receive fee
     * @param feeRate portion of amount to take as fee in 18 decimals
     */
    function receiveWithFee(
        IERC20 token,
        uint256 shares,
        address sender,
        uint256 amount,
        address feeReceiver,
        uint256 feeRate
    ) internal returns (uint256) {
        // check initial token balance
        uint256 total = token.balanceOf(address(this));

        // process fee
        uint256 fee;
        if (feeReceiver != address(0) && feeRate > 0 && feeRate < 1e18) {
            fee = (amount * feeRate) / 1e18;
            token.safeTransferFrom(sender, feeReceiver, fee);
        }

        // do transfer
        token.safeTransferFrom(sender, address(this), amount - fee);
        uint256 actual = token.balanceOf(address(this)) - total;

        // mint shares at current rate
        uint256 minted = (total > 0)
            ? (shares * actual) / total
            : actual * INITIAL_SHARES_PER_TOKEN;
        require(minted > 0);
        return minted;
    }
}