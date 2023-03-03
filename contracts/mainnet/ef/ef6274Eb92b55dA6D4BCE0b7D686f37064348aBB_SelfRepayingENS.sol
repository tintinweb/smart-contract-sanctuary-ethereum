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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
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

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
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

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
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
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
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
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
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

    /**
     * @dev Hook that is called before "consecutive token transfers" as defined in ERC2309 and implemented in
     * {ERC721Consecutive}.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after "consecutive token transfers" as defined in ERC2309 and implemented in
     * {ERC721Consecutive}.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity ^0.8.4;

import "../registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseRegistrar is Ownable, IERC721 {
    uint constant public GRACE_PERIOD = 90 days;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    // The ENS registry
    ENS public ens;

    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) virtual external;

    // Revoke controller permission for an address.
    function removeController(address controller) virtual external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) virtual external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) virtual external view returns(uint);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) virtual public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner, uint duration) virtual external returns(uint);

    function renew(uint256 id, uint duration) virtual external returns(uint);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) virtual external;
}

pragma solidity >=0.8.4;

import "../registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./BaseRegistrar.sol";
contract BaseRegistrarImplementation is ERC721, BaseRegistrar  {
    // A map of expiry times
    mapping(uint256=>uint) expiries;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("isApprovedForAll(address,address)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );
    bytes4 constant private RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    constructor(ENS _ens, bytes32 _baseNode) ERC721("","") {
        ens = _ens;
        baseNode = _baseNode;
    }

    modifier live {
        require(ens.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController {
        require(controllers[msg.sender]);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override(IERC721, ERC721) returns (address) {
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external override onlyOwner {
        ens.setResolver(baseNode, resolver);
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view override returns(uint) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view override returns(bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] + GRACE_PERIOD < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(uint256 id, address owner, uint duration) external override returns(uint) {
      return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(uint256 id, address owner, uint duration) external returns(uint) {
      return _register(id, owner, duration, false);
    }

    function _register(uint256 id, address owner, uint duration, bool updateRegistry) internal live onlyController returns(uint) {
        require(available(id));
        require(block.timestamp + duration + GRACE_PERIOD > block.timestamp + GRACE_PERIOD); // Prevent future overflow

        expiries[id] = block.timestamp + duration;
        if(_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if(updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    function renew(uint256 id, uint duration) external override live onlyController returns(uint) {
        require(expiries[id] + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period
        require(expiries[id] + duration + GRACE_PERIOD > duration + GRACE_PERIOD); // Prevent future overflow

        expiries[id] += duration;
        emit NameRenewed(id, expiries[id]);
        return expiries[id];
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external override live {
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function supportsInterface(bytes4 interfaceID) public override(ERC721, IERC165) view returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == ERC721_ID ||
               interfaceID == RECLAIM_ID;
    }
}

pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../resolvers/Resolver.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract ETHRegistrarController is Ownable {
    using StringUtils for *;

    uint constant public MIN_REGISTRATION_DURATION = 28 days;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string,uint256)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,uint256,bytes32)") ^
        keccak256("renew(string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );

    BaseRegistrarImplementation base;
    PriceOracle prices;
    uint public minCommitmentAge;
    uint public maxCommitmentAge;

    mapping(bytes32=>uint) public commitments;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

    constructor(BaseRegistrarImplementation _base, PriceOracle _prices, uint _minCommitmentAge, uint _maxCommitmentAge) public {
        require(_maxCommitmentAge > _minCommitmentAge);

        base = _base;
        prices = _prices;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function rentPrice(string memory name, uint duration) view public returns(uint) {
        bytes32 hash = keccak256(bytes(name));
        return prices.price(name, base.nameExpires(uint256(hash)), duration);
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(string memory name, address owner, bytes32 secret) pure public returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable {
      registerWithConfig(name, owner, duration, secret, address(0), address(0));
    }

    function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable {
        bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        uint cost = _consumeCommitment(name, duration, commitment);

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        uint expires;
        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(tokenId, address(this), duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.ens().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            require(addr == address(0));
            expires = base.register(tokenId, owner, duration);
        }

        emit NameRegistered(name, label, owner, cost, expires);

        // Refund any extra payment
        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function renew(string calldata name, uint duration) external payable {
        uint cost = rentPrice(name, duration);
        require(msg.value >= cost);

        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), duration);

        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(name, label, cost, expires);
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setCommitmentAges(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);        
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == COMMITMENT_CONTROLLER_ID ||
               interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(string memory name, uint duration, bytes32 commitment) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(name));

        delete(commitments[commitment]);

        uint cost = rentPrice(name, duration);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        return cost;
    }
}

pragma solidity >=0.8.4;

interface PriceOracle {
    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return The price of this renewal or registration, in wei.
     */
    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}

pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./profiles/IABIResolver.sol";
import "./profiles/IAddressResolver.sol";
import "./profiles/IAddrResolver.sol";
import "./profiles/IContentHashResolver.sol";
import "./profiles/IDNSRecordResolver.sol";
import "./profiles/IDNSZoneResolver.sol";
import "./profiles/IInterfaceResolver.sol";
import "./profiles/INameResolver.sol";
import "./profiles/IPubkeyResolver.sol";
import "./profiles/ITextResolver.sol";
import "./ISupportsInterface.sol";
/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver is ISupportsInterface, IABIResolver, IAddressResolver, IAddrResolver, IContentHashResolver, IDNSRecordResolver, IDNSZoneResolver, IInterfaceResolver, INameResolver, IPubkeyResolver, ITextResolver {
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SupportsInterface.sol";

abstract contract ResolverBase is SupportsInterface {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Gelatofied} from "./vendor/gelato/Gelatofied.sol";
import {GelatoBytes} from "./vendor/gelato/GelatoBytes.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {OpsStorage} from "./OpsStorage.sol";
import {LibDataTypes} from "./libraries/LibDataTypes.sol";
import {LibEvents} from "./libraries/LibEvents.sol";
import {LibLegacyTask} from "./libraries/LibLegacyTask.sol";
import {LibTaskId} from "./libraries/LibTaskId.sol";
import {LibTaskModule} from "./libraries/LibTaskModule.sol";
import {
    ITaskTreasuryUpgradable
} from "./interfaces/ITaskTreasuryUpgradable.sol";
import {IOps} from "./interfaces/IOps.sol";

/**
 * @notice Ops enables everyone to have Gelato monitor and execute transactions.
 * @notice ExecAddress refers to the contract that has the function which Gelato will call.
 * @notice Modules allow users to customise conditions and specifications when creating a task.
 */
contract Ops is Gelatofied, Proxied, OpsStorage, IOps {
    using GelatoBytes for bytes;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // solhint-disable const-name-snakecase
    string public constant version = "5";
    ITaskTreasuryUpgradable public immutable override taskTreasury;

    constructor(address payable _gelato, ITaskTreasuryUpgradable _taskTreasury)
        Gelatofied(_gelato)
    {
        taskTreasury = _taskTreasury;
    }

    // prettier-ignore
    fallback(bytes calldata _callData) external returns(bytes memory returnData){
        returnData = _handleLegacyTaskCreation(_callData);
    }

    ///@inheritdoc IOps
    function createTask(
        address _execAddress,
        bytes calldata _execDataOrSelector,
        LibDataTypes.ModuleData calldata _moduleData,
        address _feeToken
    ) external override returns (bytes32 taskId) {
        address taskCreator;

        (taskCreator, _execAddress) = LibTaskModule.preCreateTask(
            msg.sender,
            _execAddress,
            taskModuleAddresses
        );

        taskId = _createTask(
            taskCreator,
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    ///@inheritdoc IOps
    function cancelTask(bytes32 _taskId) external {
        address _taskCreator = LibTaskModule.preCancelTask(
            _taskId,
            msg.sender,
            taskModuleAddresses
        );

        _cancelTask(_taskCreator, _taskId);
    }

    ///@inheritdoc IOps
    function exec(
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.ModuleData calldata _moduleData,
        uint256 _txFee,
        address _feeToken,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure
    ) external onlyGelato {
        bytes32 taskId = LibTaskId.getTaskId(
            _taskCreator,
            _execAddress,
            _execData.memorySliceSelector(),
            _moduleData,
            _useTaskTreasuryFunds ? address(0) : _feeToken
        );

        _exec(
            taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _moduleData.modules,
            _txFee,
            _feeToken,
            _useTaskTreasuryFunds,
            _revertOnFailure
        );
    }

    ///@inheritdoc IOps
    function setModule(
        LibDataTypes.Module[] calldata _modules,
        address[] calldata _moduleAddresses
    ) external onlyProxyAdmin {
        uint256 length = _modules.length;
        for (uint256 i; i < length; i++) {
            taskModuleAddresses[_modules[i]] = _moduleAddresses[i];
        }
    }

    ///@inheritdoc IOps
    function getFeeDetails() external view returns (uint256, address) {
        return (fee, feeToken);
    }

    ///@inheritdoc IOps
    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory taskIds = _createdTasks[_taskCreator].values();

        return taskIds;
    }

    ///@inheritdoc IOps
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) external pure returns (bytes32 taskId) {
        taskId = LibTaskId.getTaskId(
            taskCreator,
            execAddress,
            execSelector,
            moduleData,
            feeToken
        );
    }

    ///@inheritdoc IOps
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) external pure returns (bytes32 taskId) {
        taskId = LibTaskId.getLegacyTaskId(
            taskCreator,
            execAddress,
            execSelector,
            useTaskTreasuryFunds,
            feeToken,
            resolverHash
        );
    }

    function _createTask(
        address _taskCreator,
        address _execAddress,
        bytes memory _execDataOrSelector,
        LibDataTypes.ModuleData memory _moduleData,
        address _feeToken
    ) private returns (bytes32 taskId) {
        taskId = LibTaskId.getTaskId(
            _taskCreator,
            _execAddress,
            _execDataOrSelector.memorySliceSelector(),
            _moduleData,
            _feeToken
        );

        require(
            !_createdTasks[_taskCreator].contains(taskId),
            "Ops.createTask: Duplicate task"
        );

        LibTaskModule.onCreateTask(
            taskId,
            _taskCreator,
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            taskModuleAddresses
        );

        _createdTasks[_taskCreator].add(taskId);

        emit LibEvents.TaskCreated(
            _taskCreator,
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken,
            taskId
        );
    }

    function _cancelTask(address _taskCreator, bytes32 _taskId) private {
        require(
            _createdTasks[_taskCreator].contains(_taskId),
            "Ops.cancelTask: Task not found"
        );

        _createdTasks[_taskCreator].remove(_taskId);

        emit LibEvents.TaskCancelled(_taskId, _taskCreator);
    }

    // solhint-disable function-max-lines
    function _exec(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        uint256 _txFee,
        address _feeToken,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure
    ) private {
        require(
            _createdTasks[_taskCreator].contains(_taskId),
            "Ops.exec: Task not found"
        );

        if (!_useTaskTreasuryFunds) {
            fee = _txFee;
            feeToken = _feeToken;
        }

        bool success = LibTaskModule.onExecTask(
            _taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _modules,
            _revertOnFailure,
            taskModuleAddresses
        );

        if (_useTaskTreasuryFunds) {
            taskTreasury.useFunds(_taskCreator, _feeToken, _txFee);
        } else {
            delete fee;
            delete feeToken;
        }

        emit LibEvents.ExecSuccess(
            _txFee,
            _feeToken,
            _execAddress,
            _execData,
            _taskId,
            success
        );
    }

    function _handleLegacyTaskCreation(bytes calldata _callData)
        private
        returns (bytes memory returnData)
    {
        bytes4 funcSig = _callData.calldataSliceSelector();

        (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken_
        ) = LibLegacyTask.getCreateTaskArg(funcSig, _callData);

        bytes32 taskId = _createTask(
            msg.sender,
            execAddress,
            execData,
            moduleData,
            feeToken_
        );

        returnData = abi.encodePacked(taskId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibDataTypes} from "./libraries/LibDataTypes.sol";

/**
 * @notice Storage layout of Ops smart contract.
 */
// solhint-disable max-states-count
abstract contract OpsStorage {
    mapping(bytes32 => address) public taskCreator; ///@dev Deprecated
    mapping(bytes32 => address) public execAddresses; ///@dev Deprecated
    mapping(address => EnumerableSet.Bytes32Set) internal _createdTasks;

    uint256 public fee;
    address public feeToken;

    ///@dev Appended State
    mapping(bytes32 => LibDataTypes.Time) public timedTask;
    mapping(LibDataTypes.Module => address) public taskModuleAddresses;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility

function _call(
    address _add,
    bytes memory _data,
    uint256 _value,
    bool _revertOnFailure,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.call{value: _value}(_data);

    if (!success && _revertOnFailure)
        GelatoBytes.revertWithError(returnData, _tracingInfo);
}

function _delegateCall(
    address _add,
    bytes memory _data,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.delegatecall(_data);

    if (!success) GelatoBytes.revertWithError(returnData, _tracingInfo);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility
function _transfer(
    address payable _to,
    address _paymentToken,
    uint256 _amount
) {
    if (_paymentToken == ETH) {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "_transfer: ETH transfer failed");
    } else {
        SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITaskTreasuryUpgradable} from "./ITaskTreasuryUpgradable.sol";

/**
 * @notice Legacy Ops interface with individual create task function for each task type.
 * @notice These function signatures are still supported via fallback. {See Ops.sol-fallback}
 */
interface ILegacyOps {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 taskId);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 taskId);

    function createTimedTask(
        uint128 _startTime,
        uint128 _interval,
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken,
        bool _useTreasury
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 _taskId) external;

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external;

    function getFeeDetails() external view returns (uint256, address);

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {LibDataTypes} from "../libraries/LibDataTypes.sol";
import {ITaskTreasuryUpgradable} from "./ITaskTreasuryUpgradable.sol";

// solhint-disable max-line-length
interface IOps {
    /**
     * @notice Initiates a task with conditions which Gelato will monitor and execute when conditions are met.
     *
     * @param execAddress Address of contract that should be called by Gelato.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param moduleData Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     *
     * @return taskId Unique hash of the task created.
     */
    function createTask(
        address execAddress,
        bytes calldata execData,
        LibDataTypes.ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    /**
     * @notice Terminates a task that was created and Gelato can no longer execute it.
     *
     * @param taskId Unique hash of the task that is being cancelled. {See LibTaskId-getTaskId}
     */
    function cancelTask(bytes32 taskId) external;

    /**
     * @notice Execution API called by Gelato.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called by Gelato.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param moduleData Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param txFee Fee paid to Gelato for execution, deducted on the TaskTreasury or transfered to Gelato.
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param useTaskTreasuryFunds If taskCreator's balance on TaskTreasury should pay for the tx.
     * @param revertOnFailure To revert or not if call to execAddress fails. (Used for off-chain simulations)
     */
    function exec(
        address taskCreator,
        address execAddress,
        bytes memory execData,
        LibDataTypes.ModuleData calldata moduleData,
        uint256 txFee,
        address feeToken,
        bool useTaskTreasuryFunds,
        bool revertOnFailure
    ) external;

    /**
     * @notice Sets the address of task modules. Only callable by proxy admin.
     *
     * @param modules List of modules to be set
     * @param moduleAddresses List of addresses for respective modules.
     */
    function setModule(
        LibDataTypes.Module[] calldata modules,
        address[] calldata moduleAddresses
    ) external;

    /**
     * @notice Helper function to query fee and feeToken to be used for payment. (For executions which pays itself)
     *
     * @return uint256 Fee amount to be paid.
     * @return address Token to be paid. (Determined and passed by taskCreator during createTask)
     */
    function getFeeDetails() external view returns (uint256, address);

    /**
     * @notice Helper func to query all open tasks by a task creator.
     *
     * @param taskCreator Address of task creator to query.
     *
     * @return bytes32[] List of taskIds created.
     */
    function getTaskIdsByUser(address taskCreator)
        external
        view
        returns (bytes32[] memory);

    /**
     * @notice Helper function to compute task id with module arguments
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param moduleData  Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) external pure returns (bytes32 taskId);

    /**
     * @notice (Legacy) Helper function to compute task id.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param useTaskTreasuryFunds Wether fee should be deducted from TaskTreasury.
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     * @param resolverHash Hash of resolverAddress and resolverData {See getResolverHash}
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) external pure returns (bytes32);

    /**
     * @notice TaskTreasury contract where user deposit funds to be used for fee payments.
     *
     * @return ITaskTreasuryUpgradable TaskTreasury contract interface
     */
    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxy {
    /**
     * @notice Emitted when proxy calls a contract successfully in `executeCall`
     *
     * @param target Address of contract that is called
     * @param data Data used in the call.
     * @param value Native token value used in the call.
     * @param returnData Data returned by the call.
     */
    event ExecuteCall(
        address indexed target,
        bytes data,
        uint256 value,
        bytes returnData
    );

    /**
     * @notice Multicall to different contracts with different datas.
     *
     * @param targets Addresses of contracts to be called.
     * @param datas Datas for each contract call.
     * @param values Native token value for each contract call.
     */
    function batchExecuteCall(
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values
    ) external payable;

    /**
     * @notice Call to a single contract.
     *
     * @param target Address of contracts to be called.
     * @param data Data for contract call.
     * @param value Native token value for contract call.
     */
    function executeCall(
        address target,
        bytes calldata data,
        uint256 value
    ) external payable;

    /**
     * @return address Ops smart contract address
     */
    function ops() external view returns (address);

    /**
     * @return address Owner of the proxy
     */
    function owner() external view returns (address);

    /**
     * @return uint256 version of OpsProxy.
     */
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxyFactory {
    /**
     * @notice Emitted when an OpsProxy is deployed.
     *
     * @param deployer Address which initiated the deployment
     * @param owner The address which the proxy is for.
     * @param proxy Address of deployed proxy.
     */
    event DeployProxy(
        address indexed deployer,
        address indexed owner,
        address indexed proxy
    );

    /**
     * @notice Emitted when OpsProxy implementation to be deployed is changed.
     *
     * @param oldImplementation Previous OpsProxy implementation.
     * @param newImplementation Current OpsProxy implementation.
     */
    event SetImplementation(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /**
     * @notice Emitted when OpsProxy implementation is added or removed from whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelisted Added or removed from whitelist.
     */
    event UpdateWhitelistedImplementation(
        address indexed implementation,
        bool indexed whitelisted
    );

    /**
     * @notice Deploys OpsProxy for the msg.sender.
     *
     * @return proxy Address of deployed proxy.
     */
    function deploy() external returns (address payable proxy);

    /**
     * @notice Deploys OpsProxy for another address.
     *
     * @param owner Address to deploy the proxy for.
     *
     * @return proxy Address of deployed proxy.
     */
    function deployFor(address owner) external returns (address payable proxy);

    /**
     * @notice Sets the OpsProxy implementation that will be deployed by OpsProxyFactory.
     *
     * @param newImplementation New implementation to be set.
     */
    function setImplementation(address newImplementation) external;

    /**
     * @notice Add or remove OpsProxy implementation from the whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelist Added or removed from whitelist.
     */
    function updateWhitelistedImplementations(
        address implementation,
        bool whitelist
    ) external;

    /**
     * @notice Determines the OpsProxy address when it is not deployed.
     *
     * @param account Address to determine the proxy address for.
     */
    function determineProxyAddress(address account)
        external
        view
        returns (address);

    /**
     * @return address Proxy address owned by account.
     * @return bool Whether if proxy is deployed
     */
    function getProxyOf(address account) external view returns (address, bool);

    /**
     * @return address Owner of deployed proxy.
     */
    function ownerOf(address proxy) external view returns (address);

    /**
     * @return bool Whether if implementation is whitelisted.
     */
    function whitelistedImplementations(address implementation)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable max-line-length
interface ITaskModule {
    /**
     * @notice Called before generating taskId.
     * @dev Modules can override execAddress or taskCreator. {See ProxyModule-preCreateTask}
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     *
     * @return address Overriden or original taskCreator.
     * @return address Overriden or original execAddress.
     */
    function preCreateTask(address taskCreator, address execAddress)
        external
        returns (address, address);

    /**
     * @notice Initiates task module whenever `createTask` is being called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param initModuleArg Encoded arguments for module if any.
     */
    function onCreateTask(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData,
        bytes calldata initModuleArg
    ) external;

    /**
     * @notice Called before taskId is removed from _createdTasks[].
     * @dev Modules can override taskCreator.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     *
     * @return address Overriden or original taskCreator.
     */
    function preCancelTask(bytes32 taskId, address taskCreator)
        external
        returns (address);

    /**
     * @notice Called during `exec` and before execAddress is called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     *
     * @return address Overriden or original execution address.
     * @return bytes Overriden or original execution data.
     */
    function preExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external returns (address, bytes memory);

    /**
     * @notice Called during `exec` and after execAddress is called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     */
    function postExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaskTreasuryUpgradable {
    /// @notice Events ///

    event FundsDeposited(
        address indexed sender,
        address indexed token,
        uint256 indexed amount
    );

    event FundsWithdrawn(
        address indexed receiver,
        address indexed initiator,
        address indexed token,
        uint256 amount
    );

    event LogDeductFees(
        address indexed user,
        address indexed executor,
        address indexed token,
        uint256 fees,
        address service
    );

    event UpdatedService(address indexed service, bool add);

    event UpdatedMaxFee(uint256 indexed maxFee);

    /// @notice External functions ///

    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function useFunds(
        address user,
        address token,
        uint256 amount
    ) external;

    function updateMaxFee(uint256 _newMaxFee) external;

    function updateWhitelistedService(address service, bool isWhitelist)
        external;

    /// @notice External view functions ///

    function getCreditTokensByUser(address user)
        external
        view
        returns (address[] memory);

    function getTotalCreditTokensByUser(address user)
        external
        view
        returns (address[] memory);

    function getWhitelistedServices() external view returns (address[] memory);

    function totalUserTokenBalance(address user, address token)
        external
        view
        returns (uint256);

    function userTokenBalance(address user, address token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable max-line-length
library LibDataTypes {
    /**
     * @notice Whitelisted modules that are available for users to customise conditions and specifications of their tasks.
     *
     * @param RESOLVER Use dynamic condition & input data for execution. {See ResolverModule.sol}
     * @param TIME Repeated execution of task at a specified timing and interval. {See TimeModule.sol}
     * @param PROXY Creates a dedicated caller (msg.sender) to be used when executing the task. {See ProxyModule.sol}
     * @param SINGLE_EXEC Task is cancelled after one execution. {See SingleExecModule.sol}
     */
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    /**
     * @notice Struct to contain modules and their relative arguments that are used for task creation.
     *
     * @param modules List of selected modules.
     * @param args Arguments of modules if any. Pass "0x" for modules which does not require args {See encodeModuleArg}
     */
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    /**
     * @notice Struct for time module.
     *
     * @param nextExec Time when the next execution should occur.
     * @param interval Time interval between each execution.
     */
    struct Time {
        uint128 nextExec;
        uint128 interval;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {LibDataTypes} from "./LibDataTypes.sol";

library LibEvents {
    /**
     * @notice Emitted when `createTask` is called.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that is called by Gelato.
     * @param execDataOrSelector Execution data / function selector.
     * @param moduleData Conditional modules used. {See LibDataTypes-ModuleData}
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     */
    event TaskCreated(
        address indexed taskCreator,
        address indexed execAddress,
        bytes execDataOrSelector,
        LibDataTypes.ModuleData moduleData,
        address feeToken,
        bytes32 indexed taskId
    );

    /**
     * @notice Emitted when `cancelTask` is called.
     *
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param taskCreator The address which owned the task.
     */
    event TaskCancelled(bytes32 taskId, address taskCreator);

    /**
     * @notice Emitted when `exec` is called.
     *
     * @param txFee Fee paid to Gelato for execution
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execData Execution data / function selector.
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param callSuccess Status of the call to execAddress.
     */
    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed execAddress,
        bytes execData,
        bytes32 taskId,
        bool callSuccess
    );

    /**
     * @notice Emitted when TimeModule is initialised.
     *
     * @param taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param nextExec Time when the next execution will occur.
     * @param interval Time interval between each execution.
     */
    event TimerSet(
        bytes32 indexed taskId,
        uint128 indexed nextExec,
        uint128 indexed interval
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {LibDataTypes} from "./LibDataTypes.sol";
import {ILegacyOps} from "../interfaces/ILegacyOps.sol";

/**
 * @notice Library to keep task creation methods backwards compatible.
 * @notice Legacy create task methods can be found in ILegacyOps.sol
 */
library LibLegacyTask {
    /**
     * @notice Use legacy ops create task calldata to construct
     * arguments that conforms to current create task format.
     *
     * @param _funcSig Function signature of calldata.
     * @param _callData Calldata that was passed from fallback function.
     */
    function getCreateTaskArg(bytes4 _funcSig, bytes calldata _callData)
        internal
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        if (_funcSig == ILegacyOps.createTask.selector) {
            (execAddress, execData, moduleData, feeToken) = _resolveCreateTask(
                _callData[4:]
            );
        } else if (_funcSig == ILegacyOps.createTaskNoPrepayment.selector) {
            (
                execAddress,
                execData,
                moduleData,
                feeToken
            ) = _resolveCreateTaskNoPrepayment(_callData[4:]);
        } else if (_funcSig == ILegacyOps.createTimedTask.selector) {
            (
                execAddress,
                execData,
                moduleData,
                feeToken
            ) = _resolveCreateTimedTask(_callData[4:]);
        } else revert("Ops.createTask: Function not found");
    }

    function _resolveCreateTask(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        bytes4 execSelector;
        address resolverAddress;
        bytes memory resolverData;

        (execAddress, execSelector, resolverAddress, resolverData) = abi.decode(
            _callDataSliced,
            (address, bytes4, address, bytes)
        );

        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](1);
        modules[0] = LibDataTypes.Module.RESOLVER;

        bytes[] memory args = new bytes[](1);
        args[0] = abi.encode(resolverAddress, resolverData);

        moduleData = LibDataTypes.ModuleData(modules, args);

        execData = abi.encodePacked(execSelector);
        feeToken = address(0);
    }

    function _resolveCreateTaskNoPrepayment(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        bytes4 execSelector;
        address resolverAddress;
        bytes memory resolverData;

        (
            execAddress,
            execSelector,
            resolverAddress,
            resolverData,
            feeToken
        ) = abi.decode(
            _callDataSliced,
            (address, bytes4, address, bytes, address)
        );

        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](1);
        modules[0] = LibDataTypes.Module.RESOLVER;

        bytes[] memory args = new bytes[](1);
        args[0] = abi.encode(resolverAddress, resolverData);

        moduleData = LibDataTypes.ModuleData(modules, args);

        execData = abi.encodePacked(execSelector);
    }

    function _resolveCreateTimedTask(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address execAddress,
            bytes memory execData,
            LibDataTypes.ModuleData memory moduleData,
            address feeToken
        )
    {
        bytes memory resolverModuleArgs;
        bytes memory timeModuleArgs;
        (
            execAddress,
            execData,
            feeToken,
            resolverModuleArgs,
            timeModuleArgs
        ) = _decodeTimedTaskCallData(_callDataSliced);
        LibDataTypes.Module[] memory modules = new LibDataTypes.Module[](2);
        modules[0] = LibDataTypes.Module.RESOLVER;
        modules[1] = LibDataTypes.Module.TIME;

        bytes[] memory args = new bytes[](2);
        args[0] = resolverModuleArgs;
        args[1] = timeModuleArgs;

        moduleData = LibDataTypes.ModuleData(modules, args);
    }

    function _decodeTimedTaskCallData(bytes calldata _callDataSliced)
        private
        pure
        returns (
            address,
            bytes memory,
            address,
            bytes memory,
            bytes memory
        )
    {
        (
            uint128 startTime,
            uint128 interval,
            address execAddress,
            bytes4 execSelector,
            address resolverAddress,
            bytes memory resolverData,
            address feeToken,
            bool useTreasury
        ) = abi.decode(
                _callDataSliced,
                (
                    uint128,
                    uint128,
                    address,
                    bytes4,
                    address,
                    bytes,
                    address,
                    bool
                )
            );

        return (
            execAddress,
            abi.encodePacked(execSelector),
            feeToken = useTreasury ? address(0) : feeToken,
            abi.encode(resolverAddress, resolverData),
            abi.encode(startTime, interval)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDataTypes} from "./LibDataTypes.sol";

/**
 * @notice Library to compute taskId of legacy and current tasks.
 */
// solhint-disable max-line-length
library LibTaskId {
    /**
     * @notice Returns taskId of taskCreator.
     * @notice To maintain the taskId of legacy tasks, if
     * resolver module or resolver and time module is used,
     * we will compute task id the legacy way.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param moduleData  Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        LibDataTypes.ModuleData memory moduleData,
        address feeToken
    ) internal pure returns (bytes32 taskId) {
        if (_shouldGetLegacyTaskId(moduleData.modules)) {
            bytes32 resolverHash = _getResolverHash(moduleData.args[0]);

            taskId = getLegacyTaskId(
                taskCreator,
                execAddress,
                execSelector,
                feeToken == address(0),
                feeToken,
                resolverHash
            );
        } else {
            taskId = keccak256(
                abi.encode(
                    taskCreator,
                    execAddress,
                    execSelector,
                    moduleData,
                    feeToken
                )
            );
        }
    }

    /**
     * @notice Returns taskId of taskCreator.
     * @notice Legacy way of computing taskId.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param useTaskTreasuryFunds Wether fee should be deducted from TaskTreasury.
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     * @param resolverHash Hash of resolverAddress and resolverData {See getResolverHash}
     */
    function getLegacyTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    taskCreator,
                    execAddress,
                    execSelector,
                    useTaskTreasuryFunds,
                    feeToken,
                    resolverHash
                )
            );
    }

    /**
     * @dev For legacy tasks, resolvers are compulsory. Time tasks were also introduced.
     * The sequence of Module is enforced in {LibTaskModule-_validModules}
     */
    function _shouldGetLegacyTaskId(LibDataTypes.Module[] memory _modules)
        private
        pure
        returns (bool)
    {
        uint256 length = _modules.length;

        if (
            (length == 1 && _modules[0] == LibDataTypes.Module.RESOLVER) ||
            (length == 2 &&
                _modules[0] == LibDataTypes.Module.RESOLVER &&
                _modules[1] == LibDataTypes.Module.TIME)
        ) return true;

        return false;
    }

    /**
     * @dev Acquire resolverHash which is required to compute legacyTaskId.
     *
     * @param _resolverModuleArg Encoded value of resolverAddress and resolverData
     */
    function _getResolverHash(bytes memory _resolverModuleArg)
        private
        pure
        returns (bytes32)
    {
        return keccak256(_resolverModuleArg);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {_call, _delegateCall} from "../functions/FExec.sol";
import {LibDataTypes} from "./LibDataTypes.sol";
import {LibTaskModuleConfig} from "./LibTaskModuleConfig.sol";
import {ITaskModule} from "../interfaces/ITaskModule.sol";

/**
 * @notice Library to call task modules on task creation and execution.
 */
library LibTaskModule {
    using LibTaskModuleConfig for LibDataTypes.Module;

    /**
     * @notice Delegate calls task modules before generating taskId.
     *
     * @param _execAddress Address of contract that will be called by Gelato.
     * @param _taskCreator The address which created the task.
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function preCreateTask(
        address _taskCreator,
        address _execAddress,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal returns (address, address) {
        uint256 length = uint256(type(LibDataTypes.Module).max);

        for (uint256 i; i <= length; i++) {
            LibDataTypes.Module module = LibDataTypes.Module(i);
            if (!module.requirePreCreate()) continue;

            address moduleAddress = taskModuleAddresses[module];
            _moduleInitialised(moduleAddress);

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.preCreateTask.selector,
                _taskCreator,
                _execAddress
            );

            (, bytes memory returnData) = _delegateCall(
                moduleAddress,
                delegatecallData,
                "Ops.preCreateTask: "
            );

            (_taskCreator, _execAddress) = abi.decode(
                returnData,
                (address, address)
            );
        }

        return (_taskCreator, _execAddress);
    }

    /**
     * @notice Delegate calls task modules on create task to initialise them.
     *
     * @param _taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param _taskCreator The address which created the task.
     * @param _execAddress Address of contract that will be called by Gelato.
     * @param _execData Execution data to be called with / function selector.
     * @param _moduleData Modules that will be used for the task. {See LibDataTypes-ModuleData}
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function onCreateTask(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.ModuleData memory _moduleData,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal {
        uint256 length = _moduleData.modules.length;

        _validModules(length, _moduleData.modules);

        for (uint256 i; i < length; i++) {
            LibDataTypes.Module module = _moduleData.modules[i];
            if (!module.requireOnCreate()) continue;

            address moduleAddress = taskModuleAddresses[module];
            _moduleInitialised(moduleAddress);

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.onCreateTask.selector,
                _taskId,
                _taskCreator,
                _execAddress,
                _execData,
                _moduleData.args[i]
            );

            _delegateCall(
                moduleAddress,
                delegatecallData,
                "Ops.onCreateTask: "
            );
        }
    }

    /**
     * @notice Delegate calls task modules before removing task.
     *
     * @param _taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param _taskCreator The address which created the task.
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function preCancelTask(
        bytes32 _taskId,
        address _taskCreator,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal returns (address) {
        uint256 length = uint256(type(LibDataTypes.Module).max);

        for (uint256 i; i <= length; i++) {
            LibDataTypes.Module module = LibDataTypes.Module(i);

            if (!module.requirePreCancel()) continue;

            address moduleAddress = taskModuleAddresses[module];
            _moduleInitialised(moduleAddress);

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.preCancelTask.selector,
                _taskId,
                _taskCreator
            );

            (, bytes memory returnData) = _delegateCall(
                moduleAddress,
                delegatecallData,
                "Ops.preCancelTask: "
            );

            (_taskCreator) = abi.decode(returnData, (address));
        }

        return _taskCreator;
    }

    /**
     * @notice Delegate calls task modules on exec.
     *
     * @param _taskId Unique hash of the task. {See LibTaskId-getTaskId}
     * @param _taskCreator The address which created the task.
     * @param _execAddress Address of contract that will be called by Gelato.
     * @param _execData Execution data to be called with / function selector.
     * @param _modules Modules that is used for the task. {See LibDataTypes-Module}
     * @param _revertOnFailure To revert or not if call to execAddress fails.
     * @param taskModuleAddresses The storage reference to the mapping of modules to their address.
     */
    function onExecTask(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        bool _revertOnFailure,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) internal returns (bool callSuccess) {
        address[] memory moduleAddresses = _getModuleAddresses(
            _modules,
            taskModuleAddresses
        );

        (_execAddress, _execData) = _preExecCall(
            _taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _modules,
            moduleAddresses
        );

        (callSuccess, ) = _call(
            _execAddress,
            abi.encodePacked(_execData, _taskCreator),
            0,
            _revertOnFailure,
            "Ops.exec: "
        );

        _postExecCall(
            _taskId,
            _taskCreator,
            _execAddress,
            _execData,
            _modules,
            moduleAddresses
        );
    }

    function _preExecCall(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        address[] memory _moduleAddresses
    ) private returns (address, bytes memory) {
        uint256 length = _modules.length;

        for (uint256 i; i < length; i++) {
            if (!_modules[i].requirePreExec()) continue;

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.preExecCall.selector,
                _taskId,
                _taskCreator,
                _execAddress,
                _execData
            );

            (, bytes memory returnData) = _delegateCall(
                _moduleAddresses[i],
                delegatecallData,
                "Ops.preExecCall: "
            );

            (_execAddress, _execData) = abi.decode(
                returnData,
                (address, bytes)
            );
        }
        return (_execAddress, _execData);
    }

    function _postExecCall(
        bytes32 _taskId,
        address _taskCreator,
        address _execAddress,
        bytes memory _execData,
        LibDataTypes.Module[] memory _modules,
        address[] memory _moduleAddresses
    ) private {
        uint256 length = _moduleAddresses.length;

        for (uint256 i; i < length; i++) {
            if (!_modules[i].requirePostExec()) continue;

            bytes memory delegatecallData = abi.encodeWithSelector(
                ITaskModule.postExecCall.selector,
                _taskId,
                _taskCreator,
                _execAddress,
                _execData
            );

            _delegateCall(
                _moduleAddresses[i],
                delegatecallData,
                "Ops.postExecCall: "
            );
        }
    }

    function _getModuleAddresses(
        LibDataTypes.Module[] memory _modules,
        mapping(LibDataTypes.Module => address) storage taskModuleAddresses
    ) private view returns (address[] memory) {
        uint256 length = _modules.length;
        address[] memory moduleAddresses = new address[](length);

        for (uint256 i; i < length; i++) {
            moduleAddresses[i] = taskModuleAddresses[_modules[i]];
        }

        return moduleAddresses;
    }

    function _moduleInitialised(address _moduleAddress) private pure {
        require(
            _moduleAddress != address(0),
            "Ops._moduleInitialised: Not init"
        );
    }

    ///@dev Check for duplicate modules.
    function _validModules(
        uint256 _length,
        LibDataTypes.Module[] memory _modules
    ) private pure {
        if (_length > 1)
            for (uint256 i; i < _length - 1; i++)
                require(
                    _modules[i + 1] > _modules[i],
                    "Ops._validModules: Asc only"
                );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {LibDataTypes} from "./LibDataTypes.sol";

/**
 * @notice Library to determine wether to call task modules to reduce unnecessary calls.
 */
library LibTaskModuleConfig {
    function requirePreCreate(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (_module == LibDataTypes.Module.PROXY) return true;

        return false;
    }

    function requirePreCancel(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (
            _module == LibDataTypes.Module.TIME ||
            _module == LibDataTypes.Module.PROXY
        ) return true;

        return false;
    }

    function requireOnCreate(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (
            _module == LibDataTypes.Module.TIME ||
            _module == LibDataTypes.Module.PROXY
        ) return true;

        return false;
    }

    function requirePreExec(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (
            _module == LibDataTypes.Module.TIME ||
            _module == LibDataTypes.Module.PROXY
        ) return true;

        return false;
    }

    function requirePostExec(LibDataTypes.Module _module)
        internal
        pure
        returns (bool)
    {
        if (_module == LibDataTypes.Module.SINGLE_EXEC) return true;

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {TaskModuleBase} from "./TaskModuleBase.sol";
import {IOpsProxy} from "../interfaces/IOpsProxy.sol";
import {IOpsProxyFactory} from "../interfaces/IOpsProxyFactory.sol";

contract ProxyModule is TaskModuleBase {
    IOpsProxyFactory public immutable opsProxyFactory;

    constructor(IOpsProxyFactory _opsProxyFactory) {
        opsProxyFactory = _opsProxyFactory;
    }

    /**
     * @inheritdoc TaskModuleBase
     */
    function onCreateTask(
        bytes32,
        address _taskCreator,
        address,
        bytes calldata,
        bytes calldata
    ) external override {
        _deployIfNoProxy(_taskCreator);
    }

    /**
     * @inheritdoc TaskModuleBase
     * @dev _taskCreator cannot create task to other user's proxy
     */
    function preCreateTask(address _taskCreator, address _execAddress)
        external
        view
        override
        returns (address, address)
    {
        address ownerOfExecAddress = opsProxyFactory.ownerOf(_execAddress);

        if (ownerOfExecAddress != address(0)) {
            // creating task to proxy
            require(
                _taskCreator == ownerOfExecAddress ||
                    _taskCreator == _execAddress,
                "ProxyModule: Only owner of proxy"
            );

            return (ownerOfExecAddress, _execAddress);
        } else {
            address ownerOfTaskCreator = opsProxyFactory.ownerOf(_taskCreator);

            if (ownerOfTaskCreator != address(0)) {
                // creating task to non proxy, with proxy
                // give task ownership to proxy owner
                return (ownerOfTaskCreator, _execAddress);
            }

            // creating task to non proxy, without proxy
            return (_taskCreator, _execAddress);
        }
    }

    function preCancelTask(bytes32, address _taskCreator)
        external
        view
        override
        returns (address)
    {
        address ownerOfTaskCreator = opsProxyFactory.ownerOf(_taskCreator);

        if (ownerOfTaskCreator != address(0)) {
            return ownerOfTaskCreator;
        }

        return _taskCreator;
    }

    /**
     * @inheritdoc TaskModuleBase
     * @dev _execData is encoded with proxy's `executeCall` function
     * unless _execAddress is OpsProxy which assumes that _execData is encoded
     * with `executeCall` or `batchExecuteCall`.
     */
    function preExecCall(
        bytes32,
        address _taskCreator,
        address _execAddress,
        bytes calldata _execData
    ) external view override returns (address, bytes memory execData) {
        (address proxy, ) = opsProxyFactory.getProxyOf(_taskCreator);

        execData = _execAddress == proxy
            ? _execData
            : _encodeWithOpsProxy(_execAddress, _execData);

        _execAddress = proxy;

        return (_execAddress, execData);
    }

    function _deployIfNoProxy(address _taskCreator) private {
        bool isTaskCreatorProxy = opsProxyFactory.ownerOf(_taskCreator) !=
            address(0);

        if (!isTaskCreatorProxy) {
            (, bool deployed) = opsProxyFactory.getProxyOf(_taskCreator);
            if (!deployed) opsProxyFactory.deployFor(_taskCreator);
        }
    }

    function _encodeWithOpsProxy(address _execAddress, bytes calldata _execData)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                IOpsProxy.executeCall.selector,
                _execAddress,
                _execData,
                0
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {OpsStorage} from "../OpsStorage.sol";
import {ITaskModule} from "../interfaces/ITaskModule.sol";

// solhint-disable no-empty-blocks
abstract contract TaskModuleBase is OpsStorage, ITaskModule {
    ///@inheritdoc ITaskModule
    function preCreateTask(address _taskCreator, address _execAddress)
        external
        virtual
        override
        returns (address, address)
    {
        return (_taskCreator, _execAddress);
    }

    ///@inheritdoc ITaskModule
    function onCreateTask(
        bytes32,
        address,
        address,
        bytes calldata,
        bytes calldata
    ) external virtual override {}

    ///@inheritdoc ITaskModule
    function preCancelTask(bytes32, address _taskCreator)
        external
        virtual
        override
        returns (address)
    {
        return _taskCreator;
    }

    ///@inheritdoc ITaskModule
    function preExecCall(
        bytes32,
        address,
        address _execAddress,
        bytes calldata _execData
    ) external virtual override returns (address, bytes memory) {
        return (_execAddress, _execData);
    }

    ///@inheritdoc ITaskModule
    function postExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external virtual override {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {_transfer, ETH} from "../../functions/FUtils.sol";

abstract contract Gelatofied {
    address payable public immutable gelato;

    modifier gelatofy(uint256 _amount, address _paymentToken) {
        require(msg.sender == gelato, "Gelatofied: Only gelato");
        _;
        _transfer(gelato, _paymentToken, _amount);
    }

    modifier onlyGelato() {
        require(msg.sender == gelato, "Gelatofied: Only gelato");
        _;
    }

    constructor(address payable _gelato) {
        gelato = _gelato;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {IllegalArgument, IllegalState, Unauthorized} from "./base/Errors.sol";

import {IERC3156FlashLender} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";

/// @title  AlchemicTokenV2
/// @author Alchemix Finance
///
/// @notice This is the contract for version two alchemic tokens.
contract AlchemicTokenV2 is AccessControl, ReentrancyGuard, ERC20, IERC3156FlashLender {

  /// @notice The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @notice The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");

  /// @notice The expected return value from a flash mint receiver
  bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

  /// @notice The maximum number of basis points needed to represent 100%.
  uint256 public constant BPS = 10_000;

  /// @notice A set of addresses which are whitelisted for minting new tokens.
  mapping(address => bool) public whitelisted;

  /// @notice A set of addresses which are paused from minting new tokens.
  mapping(address => bool) public paused;

  /// @notice Fee for flash minting
  uint256 public flashMintFee;

  /// @notice Max flash mint amount
  uint256 public maxFlashLoanAmount;

  /// @notice An event which is emitted when a minter is paused from minting.
  ///
  /// @param minter The address of the minter which was paused.
  /// @param state  A flag indicating if the alchemist is paused or unpaused.
  event Paused(address minter, bool state);

  /// @notice An event which is emitted when the flash mint fee is updated.
  ///
  /// @param fee The new flash mint fee.
  event SetFlashMintFee(uint256 fee);

  /// @notice An event which is emitted when the max flash loan is updated.
  ///
  /// @param maxFlashLoan The new max flash loan.
  event SetMaxFlashLoan(uint256 maxFlashLoan);

  constructor(string memory _name, string memory _symbol, uint256 _flashFee) ERC20(_name, _symbol) {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(SENTINEL_ROLE, msg.sender);
    _setRoleAdmin(SENTINEL_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    flashMintFee = _flashFee;
    emit SetFlashMintFee(_flashFee);
  }

  /// @dev A modifier which checks that the caller has the admin role.
  modifier onlyAdmin() {
    if (!hasRole(ADMIN_ROLE, msg.sender)) {
      revert Unauthorized();
    }
    _;
  }

  /// @dev A modifier which checks that the caller has the sentinel role.
  modifier onlySentinel() {
    if(!hasRole(SENTINEL_ROLE, msg.sender)) {
      revert Unauthorized();
    }
    _;
  }

  /// @dev A modifier which checks if whitelisted for minting.
  modifier onlyWhitelisted() {
    if(!whitelisted[msg.sender]) {
      revert Unauthorized();
    }
    _;
  }

  /// @notice Sets the flash minting fee.
  ///
  /// @notice This function reverts if `msg.sender` is not an admin.
  ///
  /// @param newFee The new flash mint fee.
  function setFlashFee(uint256 newFee) external onlyAdmin {
    if (newFee >= BPS) {
      revert IllegalArgument();
    }
    flashMintFee = newFee;
    emit SetFlashMintFee(flashMintFee);
  }

  /// @notice Mints tokens to `a recipient.`
  ///
  /// @notice This function reverts if `msg.sender` is not whitelisted.
  /// @notice This function reverts if `msg.sender` is paused.
  ///
  /// @param recipient The address to mint the tokens to.
  /// @param amount    The amount of tokens to mint.
  function mint(address recipient, uint256 amount) external onlyWhitelisted {
    if (paused[msg.sender]) {
      revert IllegalState();
    }

    _mint(recipient, amount);
  }

  /// @notice Sets `minter` as whitelisted to mint.
  ///
  /// @notice This function reverts if `msg.sender` is not an admin.
  ///
  /// @param minter The account to permit to mint.
  /// @param state  A flag indicating if the minter should be able to mint.
  function setWhitelist(address minter, bool state) external onlyAdmin {
    whitelisted[minter] = state;
  }

  /// @notice Sets `sentinel` as a sentinel.
  ///
  /// @notice This function reverts if `msg.sender` is not an admin.
  ///
  /// @param sentinel The address to set as a sentinel.
  function setSentinel(address sentinel) external onlyAdmin {
    _setupRole(SENTINEL_ROLE, sentinel);
  }

  /// @notice Pauses `minter` from minting tokens.
  ///
  /// @notice This function reverts if `msg.sender` is not a sentinel.
  ///
  /// @param minter The address to set as paused or unpaused.
  /// @param state  A flag indicating if the minter should be paused or unpaused.
  function pauseMinter(address minter, bool state) external onlySentinel {
    paused[minter] = state;
    emit Paused(minter, state);
  }

  /// @notice Burns `amount` tokens from `msg.sender`.
  ///
  /// @param amount The amount of tokens to be burned.
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  /// @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
  ///
  /// @param account The address the burn tokens from.
  /// @param amount  The amount of tokens to burn.
  function burnFrom(address account, uint256 amount) external {
    uint256 newAllowance = allowance(account, msg.sender) - amount;

    _approve(account, msg.sender, newAllowance);
    _burn(account, amount);
  }

  /// @notice Adjusts the maximum flashloan amount.
  ///
  /// @param _maxFlashLoanAmount The maximum flashloan amount.
  function setMaxFlashLoan(uint256 _maxFlashLoanAmount) external onlyAdmin {
    maxFlashLoanAmount = _maxFlashLoanAmount;
    emit SetMaxFlashLoan(_maxFlashLoanAmount);
  }

  /// @notice Gets the maximum amount to be flash loaned of a token.
  ///
  /// @param token The address of the token.
  ///
  /// @return The maximum amount of `token` that can be flashed loaned.
  function maxFlashLoan(address token) public view override returns (uint256) {
    if (token != address(this)) {
      return 0;
    }
    return maxFlashLoanAmount;
  }

  /// @notice Gets the flash loan fee of `amount` of `token`.
  ///
  /// @param token  The address of the token.`
  /// @param amount The amount of `token` to flash mint.
  ///
  /// @return The flash loan fee.
  function flashFee(address token, uint256 amount) public view override returns (uint256) {
    if (token != address(this)) {
      revert IllegalArgument();
    }
    return amount * flashMintFee / BPS;
  }

  /// @notice Performs a flash mint (called flash loan to confirm with ERC3156 standard).
  ///
  /// @param receiver The address which will receive the flash minted tokens.
  /// @param token    The address of the token to flash mint.
  /// @param amount   How much to flash mint.
  /// @param data     ABI encoded data to pass to the receiver.
  ///
  /// @return If the flash loan was successful.
  function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  ) external override nonReentrant returns (bool) {
    if (token != address(this)) {
      revert IllegalArgument();
    }

    if (amount > maxFlashLoan(token)) {
      revert IllegalArgument();
    }

    uint256 fee = flashFee(token, amount);

    _mint(address(receiver), amount);

    if (receiver.onFlashLoan(msg.sender, token, amount, fee, data) != CALLBACK_SUCCESS) {
      revert IllegalState();
    }

    _burn(address(receiver), amount + fee); // Will throw error if not enough to burn

    return true;
  }
}

pragma solidity ^0.8.13;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

pragma solidity >=0.5.0;

import "./alchemist/IAlchemistV2Actions.sol";
import "./alchemist/IAlchemistV2AdminActions.sol";
import "./alchemist/IAlchemistV2Errors.sol";
import "./alchemist/IAlchemistV2Immutables.sol";
import "./alchemist/IAlchemistV2Events.sol";
import "./alchemist/IAlchemistV2State.sol";

/// @title  IAlchemistV2
/// @author Alchemix Finance
interface IAlchemistV2 is
    IAlchemistV2Actions,
    IAlchemistV2AdminActions,
    IAlchemistV2Errors,
    IAlchemistV2Immutables,
    IAlchemistV2Events,
    IAlchemistV2State
{ }

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Actions
/// @author Alchemix Finance
///
/// @notice Specifies user actions.
interface IAlchemistV2Actions {
    /// @notice Approve `spender` to mint `amount` debt tokens.
    ///
    /// **_NOTE:_** This function is WHITELISTED.
    ///
    /// @param spender The address that will be approved to mint.
    /// @param amount  The amount of tokens that `spender` will be allowed to mint.
    function approveMint(address spender, uint256 amount) external;

    /// @notice Approve `spender` to withdraw `amount` shares of `yieldToken`.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @param spender    The address that will be approved to withdraw.
    /// @param yieldToken The address of the yield token that `spender` will be allowed to withdraw.
    /// @param shares     The amount of shares that `spender` will be allowed to withdraw.
    function approveWithdraw(
        address spender,
        address yieldToken,
        uint256 shares
    ) external;

    /// @notice Synchronizes the state of the account owned by `owner`.
    ///
    /// @param owner The owner of the account to synchronize.
    function poke(address owner) external;

    /// @notice Deposit a yield token into a user's account.
    ///
    /// @notice An approval must be set for `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **_NOTE:_** When depositing, the `AlchemistV2` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **yieldToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amount = 50000;
    /// @notice IERC20(ydai).approve(alchemistAddress, amount);
    /// @notice AlchemistV2(alchemistAddress).deposit(ydai, amount, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The yield-token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The owner of the account that will receive the resulting shares.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function deposit(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 sharesIssued);

    /// @notice Deposit an underlying token into the account of `recipient` as `yieldToken`.
    ///
    /// @notice An approval must be set for the underlying token of `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** When depositing, the `AlchemistV2` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **underlyingToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amount = 50000;
    /// @notice AlchemistV2(alchemistAddress).depositUnderlying(ydai, amount, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to wrap the underlying tokens into.
    /// @param amount           The amount of the underlying token to deposit.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be deposited to `recipient`.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositUnderlying(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesIssued);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares. The number of yield tokens withdrawn to `recipient` will depend on the value of shares for that yield token at the time of the call.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getYieldTokensPerShare(ydai);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdraw(ydai, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdraw(
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares from the account of `owner`
    ///
    /// @notice `owner` must have an withdrawal allowance which is greater than `amount` for this call to succeed.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getYieldTokensPerShare(ydai);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdrawFrom(msg.sender, ydai, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param owner      The address of the account owner to withdraw from.
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw underlying tokens to `recipient` by burning `share` shares and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `withdrawFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getUnderlyingTokensPerShare(ydai);
    /// @notice uint256 amountUnderlyingTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdrawUnderlying(ydai, amountUnderlyingTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of underlying tokens that were withdrawn to `recipient`.
    function withdrawUnderlying(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw underlying tokens to `recipient` by burning `share` shares from the account of `owner` and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `withdrawFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getUnderlyingTokensPerShare(ydai);
    /// @notice uint256 amtUnderlyingTokens = 5000 * 10**ydai.decimals();
    /// @notice AlchemistV2(alchemistAddress).withdrawUnderlying(msg.sender, ydai, amtUnderlyingTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param owner            The address of the account owner to withdraw from.
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of underlying tokens that were withdrawn to `recipient`.
    function withdrawUnderlyingFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Mint `amount` debt tokens.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Mint} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice AlchemistV2(alchemistAddress).mint(amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to mint.
    /// @param recipient The address of the recipient.
    function mint(uint256 amount, address recipient) external;

    /// @notice Mint `amount` debt tokens from the account owned by `owner` to `recipient`.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Mint} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `mintFrom()` must have **mintAllowance()** to mint debt from the `Account` controlled by **owner** for at least the amount of **yieldTokens** that **shares** will be converted to.  This can be done via the `approveMint()` or `permitMint()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice AlchemistV2(alchemistAddress).mintFrom(msg.sender, amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param owner     The address of the owner of the account to mint from.
    /// @param amount    The amount of tokens to mint.
    /// @param recipient The address of the recipient.
    function mintFrom(
        address owner,
        uint256 amount,
        address recipient
    ) external;

    /// @notice Burn `amount` debt tokens to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must have non-zero debt or this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Burn} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtBurn = 5000;
    /// @notice AlchemistV2(alchemistAddress).burn(amtBurn, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to burn.
    /// @param recipient The address of the recipient.
    ///
    /// @return amountBurned The amount of tokens that were burned.
    function burn(uint256 amount, address recipient) external returns (uint256 amountBurned);

    /// @notice Repay `amount` debt using `underlyingToken` to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `underlyingToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `amount` must be less than or equal to the current available repay limit or this call will revert with a {ReplayLimitExceeded} error.
    ///
    /// @notice Emits a {Repay} event.
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address dai = 0x6b175474e89094c44da98b954eedeac495271d0f;
    /// @notice uint256 amtRepay = 5000;
    /// @notice AlchemistV2(alchemistAddress).repay(dai, amtRepay, msg.sender);
    /// @notice ```
    ///
    /// @param underlyingToken The address of the underlying token to repay.
    /// @param amount          The amount of the underlying token to repay.
    /// @param recipient       The address of the recipient which will receive credit.
    ///
    /// @return amountRepaid The amount of tokens that were repaid.
    function repay(
        address underlyingToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 amountRepaid);

    /// @notice
    ///
    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    ///
    /// @notice `shares` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    /// @notice `amount` must be less than or equal to the current available liquidation limit or this call will revert with a {LiquidationLimitExceeded} error.
    ///
    /// @notice Emits a {Liquidate} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amtSharesLiquidate = 5000 * 10**ydai.decimals();
    /// @notice AlchemistV2(alchemistAddress).liquidate(ydai, amtSharesLiquidate, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to liquidate.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be liquidated.
    ///
    /// @return sharesLiquidated The amount of shares that were liquidated.
    function liquidate(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesLiquidated);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amtSharesLiquidate = 5000;
    /// @notice AlchemistV2(alchemistAddress).liquidate(dai, amtSharesLiquidate, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    function donate(address yieldToken, uint256 amount) external;

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    function harvest(address yieldToken, uint256 minimumAmountOut) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/// @title  IAlchemistV2AdminActions
/// @author Alchemix Finance
///
/// @notice Specifies admin and or sentinel actions.
interface IAlchemistV2AdminActions {
    /// @notice Contract initialization parameters.
    struct InitializationParams {
        // The initial admin account.
        address admin;
        // The ERC20 token used to represent debt.
        address debtToken;
        // The initial transmuter or transmuter buffer.
        address transmuter;
        // The minimum collateralization ratio that an account must maintain.
        uint256 minimumCollateralization;
        // The percentage fee taken from each harvest measured in units of basis points.
        uint256 protocolFee;
        // The address that receives protocol fees.
        address protocolFeeReceiver;
        // A limit used to prevent administrators from making minting functionality inoperable.
        uint256 mintingLimitMinimum;
        // The maximum number of tokens that can be minted per period of time.
        uint256 mintingLimitMaximum;
        // The number of blocks that it takes for the minting limit to be refreshed.
        uint256 mintingLimitBlocks;
        // The address of the whitelist.
        address whitelist;
    }

    /// @notice Configuration parameters for an underlying token.
    struct UnderlyingTokenConfig {
        // A limit used to prevent administrators from making repayment functionality inoperable.
        uint256 repayLimitMinimum;
        // The maximum number of underlying tokens that can be repaid per period of time.
        uint256 repayLimitMaximum;
        // The number of blocks that it takes for the repayment limit to be refreshed.
        uint256 repayLimitBlocks;
        // A limit used to prevent administrators from making liquidation functionality inoperable.
        uint256 liquidationLimitMinimum;
        // The maximum number of underlying tokens that can be liquidated per period of time.
        uint256 liquidationLimitMaximum;
        // The number of blocks that it takes for the liquidation limit to be refreshed.
        uint256 liquidationLimitBlocks;
    }

    /// @notice Configuration parameters of a yield token.
    struct YieldTokenConfig {
        // The adapter used by the system to interop with the token.
        address adapter;
        // The maximum percent loss in expected value that can occur before certain actions are disabled measured in
        // units of basis points.
        uint256 maximumLoss;
        // The maximum value that can be held by the system before certain actions are disabled measured in the
        // underlying token.
        uint256 maximumExpectedValue;
        // The number of blocks that credit will be distributed over to depositors.
        uint256 creditUnlockBlocks;
    }

    /// @notice Initialize the contract.
    ///
    /// @notice `params.protocolFee` must be in range or this call will with an {IllegalArgument} error.
    /// @notice The minting growth limiter parameters must be valid or this will revert with an {IllegalArgument} error. For more information, see the {Limiters} library.
    ///
    /// @notice Emits an {AdminUpdated} event.
    /// @notice Emits a {TransmuterUpdated} event.
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    /// @notice Emits a {ProtocolFeeUpdated} event.
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    /// @notice Emits a {MintingLimitUpdated} event.
    ///
    /// @param params The contract initialization parameters.
    function initialize(InitializationParams memory params) external;

    /// @notice Sets the pending administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {PendingAdminUpdated} event.
    ///
    /// @dev This is the first step in the two-step process of setting a new administrator. After this function is called, the pending administrator will then need to call {acceptAdmin} to complete the process.
    ///
    /// @param value the address to set the pending admin to.
    function setPendingAdmin(address value) external;

    /// @notice Allows for `msg.sender` to accepts the role of administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice The current pending administrator must be non-zero or this call will revert with an {IllegalState} error.
    ///
    /// @dev This is the second step in the two-step process of setting a new administrator. After this function is successfully called, this pending administrator will be reset and the new administrator will be set.
    ///
    /// @notice Emits a {AdminUpdated} event.
    /// @notice Emits a {PendingAdminUpdated} event.
    function acceptAdmin() external;

    /// @notice Sets an address as a sentinel.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param sentinel The address to set or unset as a sentinel.
    /// @param flag     A flag indicating of the address should be set or unset as a sentinel.
    function setSentinel(address sentinel, bool flag) external;

    /// @notice Sets an address as a keeper.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param keeper The address to set or unset as a keeper.
    /// @param flag   A flag indicating of the address should be set or unset as a keeper.
    function setKeeper(address keeper, bool flag) external;

    /// @notice Adds an underlying token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param underlyingToken The address of the underlying token to add.
    /// @param config          The initial underlying token configuration.
    function addUnderlyingToken(
        address underlyingToken,
        UnderlyingTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {AddYieldToken} event.
    /// @notice Emits a {TokenAdapterUpdated} event.
    /// @notice Emits a {MaximumLossUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(address yieldToken, YieldTokenConfig calldata config)
        external;

    /// @notice Sets an underlying token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits an {UnderlyingTokenEnabled} event.
    ///
    /// @param underlyingToken The address of the underlying token to enable or disable.
    /// @param enabled         If the underlying token should be enabled or disabled.
    function setUnderlyingTokenEnabled(address underlyingToken, bool enabled)
        external;

    /// @notice Sets a yield token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {YieldTokenEnabled} event.
    ///
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the underlying token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Configures the the repay limit of `underlyingToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {ReplayLimitUpdated} event.
    ///
    /// @param underlyingToken The address of the underlying token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address underlyingToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the liquidation limiter of `underlyingToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {LiquidationLimitUpdated} event.
    ///
    /// @param underlyingToken The address of the underlying token to configure the liquidation limit of.
    /// @param maximum         The maximum liquidation limit.
    /// @param blocks          The number of blocks it will take for the maximum liquidation limit to be replenished when it is completely exhausted.
    function configureLiquidationLimit(
        address underlyingToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Set the address of the transmuter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {TransmuterUpdated} event.
    ///
    /// @param value The address of the transmuter.
    function setTransmuter(address value) external;

    /// @notice Set the minimum collateralization ratio.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    ///
    /// @param value The new minimum collateralization ratio.
    function setMinimumCollateralization(uint256 value) external;

    /// @notice Sets the fee that the protocol will take from harvests.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be in range or this call will with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeUpdated} event.
    ///
    /// @param value The value to set the protocol fee to measured in basis points.
    function setProtocolFee(uint256 value) external;

    /// @notice Sets the address which will receive protocol fees.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    ///
    /// @param value The address to set the protocol fee receiver to.
    function setProtocolFeeReceiver(address value) external;

    /// @notice Configures the minting limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MintingLimitUpdated} event.
    ///
    /// @param maximum The maximum minting limit.
    /// @param blocks  The number of blocks it will take for the maximum minting limit to be replenished when it is completely exhausted.
    function configureMintingLimit(uint256 maximum, uint256 blocks) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    ///
    /// @notice Emits a {CreditUnlockRateUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(address yieldToken, uint256 blocks) external;

    /// @notice Sets the token adapter of a yield token.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The token that `adapter` supports must be `yieldToken` or this call will revert with a {IllegalState} error.
    ///
    /// @notice Emits a {TokenAdapterUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its underlying token.
    function setMaximumExpectedValue(address yieldToken, uint256 value)
        external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev There are two types of loss of value for yield bearing assets: temporary or permanent. The system will automatically restrict actions which are sensitive to both forms of loss when detected. For example, deposits must be restricted when an excessive loss is encountered to prevent users from having their collateral harvested from them. While the user would receive credit, which then could be exchanged for value equal to the collateral that was harvested from them, it is seen as a negative user experience because the value of their collateral should have been higher than what was originally recorded when they made their deposit.
    ///
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of underlying tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external;

    /// @notice Sweep all of 'rewardtoken' from the alchemist into the rewardCollector;
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `rewardToken` must not be a yield or underlying token or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param rewardToken The address of the reward token sweep.
    /// @param yieldToken The address of the yield token whose rewards are being swept.
    function sweepRewardTokens(address rewardToken, address yieldToken) external;

    /// @notice Set the address of the V1 transfer adapter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param transferAdapterAddress The address of the V1 transfer adapter to be set in the alchemist.
    function setTransferAdapterAddress(address transferAdapterAddress) external;

    /// @notice Accept debt from the V1 transfer vault adapter.
    ///
    /// @notice `msg.sender` must be a sentinal or the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param owner    The owner of the account whos debt to increase.
    /// @param debt     The amount of debt incoming from the V1 tranfer adapter.
    function transferDebtV1(address owner, int256 debt) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/// @title  IAlchemistV2Errors
/// @author Alchemix Finance
///
/// @notice Specifies errors.
interface IAlchemistV2Errors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the underlying token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the underlying token.
    error ExpectedValueExceeded(address yieldToken, uint256 expectedValue, uint256 maximumExpectedValue);

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a minting operation failed because the minting limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be minted.
    /// @param available The amount of debt tokens which are available to mint.
    error MintingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an underlying token has been exceeded.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of underlying tokens that were requested to be repaid.
    /// @param available       The amount of underlying tokens that are available to be repaid.
    error RepayLimitExceeded(address underlyingToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the liquidation limit for an underlying token has been exceeded.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of underlying tokens that were requested to be liquidated.
    /// @param available       The amount of underlying tokens that are available to be liquidated.
    error LiquidationLimitExceeded(address underlyingToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Events
/// @author Alchemix Finance
interface IAlchemistV2Events {
    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The address of the pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the administrator is updated.
    ///
    /// @param admin The address of the administrator.
    event AdminUpdated(address admin);

    /// @notice Emitted when an address is set or unset as a sentinel.
    ///
    /// @param sentinel The address of the sentinel.
    /// @param flag     A flag indicating if `sentinel` was set or unset as a sentinel.
    event SentinelSet(address sentinel, bool flag);

    /// @notice Emitted when an address is set or unset as a keeper.
    ///
    /// @param sentinel The address of the keeper.
    /// @param flag     A flag indicating if `keeper` was set or unset as a sentinel.
    event KeeperSet(address sentinel, bool flag);

    /// @notice Emitted when an underlying token is added.
    ///
    /// @param underlyingToken The address of the underlying token that was added.
    event AddUnderlyingToken(address indexed underlyingToken);

    /// @notice Emitted when a yield token is added.
    ///
    /// @param yieldToken The address of the yield token that was added.
    event AddYieldToken(address indexed yieldToken);

    /// @notice Emitted when an underlying token is enabled or disabled.
    ///
    /// @param underlyingToken The address of the underlying token that was enabled or disabled.
    /// @param enabled         A flag indicating if the underlying token was enabled or disabled.
    event UnderlyingTokenEnabled(address indexed underlyingToken, bool enabled);

    /// @notice Emitted when an yield token is enabled or disabled.
    ///
    /// @param yieldToken The address of the yield token that was enabled or disabled.
    /// @param enabled    A flag indicating if the yield token was enabled or disabled.
    event YieldTokenEnabled(address indexed yieldToken, bool enabled);

    /// @notice Emitted when the repay limit of an underlying token is updated.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param maximum         The updated maximum repay limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    event RepayLimitUpdated(address indexed underlyingToken, uint256 maximum, uint256 blocks);

    /// @notice Emitted when the liquidation limit of an underlying token is updated.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param maximum         The updated maximum liquidation limit.
    /// @param blocks          The updated number of blocks it will take for the maximum liquidation limit to be replenished when it is completely exhausted.
    event LiquidationLimitUpdated(address indexed underlyingToken, uint256 maximum, uint256 blocks);

    /// @notice Emitted when the transmuter is updated.
    ///
    /// @param transmuter The updated address of the transmuter.
    event TransmuterUpdated(address transmuter);

    /// @notice Emitted when the minimum collateralization is updated.
    ///
    /// @param minimumCollateralization The updated minimum collateralization.
    event MinimumCollateralizationUpdated(uint256 minimumCollateralization);

    /// @notice Emitted when the protocol fee is updated.
    ///
    /// @param protocolFee The updated protocol fee.
    event ProtocolFeeUpdated(uint256 protocolFee);
    
    /// @notice Emitted when the protocol fee receiver is updated.
    ///
    /// @param protocolFeeReceiver The updated address of the protocol fee receiver.
    event ProtocolFeeReceiverUpdated(address protocolFeeReceiver);

    /// @notice Emitted when the minting limit is updated.
    ///
    /// @param maximum The updated maximum minting limit.
    /// @param blocks  The updated number of blocks it will take for the maximum minting limit to be replenished when it is completely exhausted.
    event MintingLimitUpdated(uint256 maximum, uint256 blocks);

    /// @notice Emitted when the credit unlock rate is updated.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param blocks     The number of blocks that distributed credit will unlock over.
    event CreditUnlockRateUpdated(address yieldToken, uint256 blocks);

    /// @notice Emitted when the adapter of a yield token is updated.
    ///
    /// @param yieldToken   The address of the yield token.
    /// @param tokenAdapter The updated address of the token adapter.
    event TokenAdapterUpdated(address yieldToken, address tokenAdapter);

    /// @notice Emitted when the maximum expected value of a yield token is updated.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param maximumExpectedValue The updated maximum expected value.
    event MaximumExpectedValueUpdated(address indexed yieldToken, uint256 maximumExpectedValue);

    /// @notice Emitted when the maximum loss of a yield token is updated.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param maximumLoss The updated maximum loss.
    event MaximumLossUpdated(address indexed yieldToken, uint256 maximumLoss);

    /// @notice Emitted when the expected value of a yield token is snapped to its current value.
    ///
    /// @param yieldToken    The address of the yield token.
    /// @param expectedValue The updated expected value measured in the yield token's underlying token.
    event Snap(address indexed yieldToken, uint256 expectedValue);

    /// @notice Emitted when a the admin sweeps all of one reward token from the Alchemist
    ///
    /// @param rewardToken The address of the reward token.
    /// @param amount      The amount of 'rewardToken' swept into the admin.
    event SweepRewardTokens(address indexed rewardToken, uint256 amount);

    /// @notice Emitted when a the admin sweeps all of one token from the Alchemist
    ///
    /// @param token The address of the reward token.
    /// @param amount      The amount of 'token' swept into the admin.
    event SweepTokens(address indexed token, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to mint debt tokens on its behalf.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address which is being permitted to mint tokens on the behalf of `owner`.
    /// @param amount  The amount of debt tokens that `spender` is allowed to mint.
    event ApproveMint(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to withdraw `yieldToken` from its account.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address which is being permitted to mint tokens on the behalf of `owner`.
    /// @param yieldToken The address of the yield token that `spender` is allowed to withdraw.
    /// @param amount     The amount of shares of `yieldToken` that `spender` is allowed to withdraw.
    event ApproveWithdraw(address indexed owner, address indexed spender, address indexed yieldToken, uint256 amount);

    /// @notice Emitted when a user deposits `amount of `yieldToken` to `recipient`.
    ///
    /// @notice This event does not imply that `sender` directly deposited yield tokens. It is possible that the
    ///         underlying tokens were wrapped.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param yieldToken   The address of the yield token that was deposited.
    /// @param amount       The amount of yield tokens that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event Deposit(address indexed sender, address indexed yieldToken, uint256 amount, address recipient);

    /// @notice Emitted when `shares` shares of `yieldToken` are burned to withdraw `yieldToken` from the account owned
    ///         by `owner` to `recipient`.
    ///
    /// @notice This event does not imply that `recipient` received yield tokens. It is possible that the yield tokens
    ///         were unwrapped.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token that was withdrawn.
    /// @param shares     The amount of shares that were burned.
    /// @param recipient  The address that received the withdrawn funds.
    event Withdraw(address indexed owner, address indexed yieldToken, uint256 shares, address recipient);

    /// @notice Emitted when `amount` debt tokens are minted to `recipient` using the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount of tokens that were minted.
    /// @param recipient The recipient of the minted tokens.
    event Mint(address indexed owner, uint256 amount, address recipient);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to `recipient`.
    ///
    /// @param sender    The address which is burning tokens.
    /// @param amount    The amount of tokens that were burned.
    /// @param recipient The address that received credit for the burned tokens.
    event Burn(address indexed sender, uint256 amount, address recipient);

    /// @notice Emitted when `amount` of `underlyingToken` are repaid to grant credit to `recipient`.
    ///
    /// @param sender          The address which is repaying tokens.
    /// @param underlyingToken The address of the underlying token that was used to repay debt.
    /// @param amount          The amount of the underlying token that was used to repay debt.
    /// @param recipient       The address that received credit for the repaid tokens.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event Repay(address indexed sender, address indexed underlyingToken, uint256 amount, address recipient, uint256 credit);

    /// @notice Emitted when `sender` liquidates `share` shares of `yieldToken`.
    ///
    /// @param owner           The address of the account owner liquidating shares.
    /// @param yieldToken      The address of the yield token.
    /// @param underlyingToken The address of the underlying token.
    /// @param shares          The amount of the shares of `yieldToken` that were liquidated.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event Liquidate(address indexed owner, address indexed yieldToken, address indexed underlyingToken, uint256 shares, uint256 credit);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to users who have deposited `yieldToken`.
    ///
    /// @param sender     The address which burned debt tokens.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of debt tokens which were burned.
    event Donate(address indexed sender, address indexed yieldToken, uint256 amount);

    /// @notice Emitted when `yieldToken` is harvested.
    ///
    /// @param yieldToken       The address of the yield token that was harvested.
    /// @param minimumAmountOut The maximum amount of loss that is acceptable when unwrapping the underlying tokens into yield tokens, measured in basis points.
    /// @param totalHarvested   The total amount of underlying tokens harvested.
    /// @param credit           The total amount of debt repaid to depositors of `yieldToken`.
    event Harvest(address indexed yieldToken, uint256 minimumAmountOut, uint256 totalHarvested, uint256 credit);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/// @title  IAlchemistV2Immutables
/// @author Alchemix Finance
interface IAlchemistV2Immutables {
    /// @notice Returns the version of the alchemist.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Returns the address of the debt token used by the system.
    ///
    /// @return The address of the debt token.
    function debtToken() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/// @title  IAlchemistV2State
/// @author Alchemix Finance
interface IAlchemistV2State {
    /// @notice Defines underlying token parameters.
    struct UnderlyingTokenParams {
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A coefficient used to normalize the token to a value comparable to the debt token. For example, if the
        // underlying token is 8 decimals and the debt token is 18 decimals then the conversion factor will be
        // 10^10. One unit of the underlying token will be comparably equal to one unit of the debt token.
        uint256 conversionFactor;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Defines yield token parameters.
    struct YieldTokenParams {
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // The associated underlying token that can be redeemed for the yield-token.
        address underlyingToken;
        // The adapter used by the system to wrap, unwrap, and lookup the conversion rate of this token into its
        // underlying token.
        address adapter;
        // The maximum percentage loss that is acceptable before disabling certain actions.
        uint256 maximumLoss;
        // The maximum value of yield tokens that the system can hold, measured in units of the underlying token.
        uint256 maximumExpectedValue;
        // The percent of credit that will be unlocked per block. The representation of this value is a 18  decimal
        // fixed point integer.
        uint256 creditUnlockRate;
        // The current balance of yield tokens which are held by users.
        uint256 activeBalance;
        // The current balance of yield tokens which are earmarked to be harvested by the system at a later time.
        uint256 harvestableBalance;
        // The total number of shares that have been minted for this token.
        uint256 totalShares;
        // The expected value of the tokens measured in underlying tokens. This value controls how much of the token
        // can be harvested. When users deposit yield tokens, it increases the expected value by how much the tokens
        // are exchangeable for in the underlying token. When users withdraw yield tokens, it decreases the expected
        // value by how much the tokens are exchangeable for in the underlying token.
        uint256 expectedValue;
        // The current amount of credit which is will be distributed over time to depositors.
        uint256 pendingCredit;
        // The amount of the pending credit that has been distributed.
        uint256 distributedCredit;
        // The block number which the last credit distribution occurred.
        uint256 lastDistributionBlock;
        // The total accrued weight. This is used to calculate how much credit a user has been granted over time. The
        // representation of this value is a 18 decimal fixed point integer.
        uint256 accruedWeight;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Gets the address of the admin.
    ///
    /// @return admin The admin address.
    function admin() external view returns (address admin);

    /// @notice Gets the address of the pending administrator.
    ///
    /// @return pendingAdmin The pending administrator address.
    function pendingAdmin() external view returns (address pendingAdmin);

    /// @notice Gets the address of the transfer adapter.
    ///
    /// @return transferAdapter The transfer adapter address.
    function transferAdapter() external view returns (address transferAdapter);

    /// @notice Gets if an address is a sentinel.
    ///
    /// @param sentinel The address to check.
    ///
    /// @return isSentinel If the address is a sentinel.
    function sentinels(address sentinel) external view returns (bool isSentinel);

    /// @notice Gets if an address is a keeper.
    ///
    /// @param keeper The address to check.
    ///
    /// @return isKeeper If the address is a keeper
    function keepers(address keeper) external view returns (bool isKeeper);

    /// @notice Gets the address of the transmuter.
    ///
    /// @return transmuter The transmuter address.
    function transmuter() external view returns (address transmuter);

    /// @notice Gets the minimum collateralization.
    ///
    /// @notice Collateralization is determined by taking the total value of collateral that a user has deposited into their account and dividing it their debt.
    ///
    /// @dev The value returned is a 18 decimal fixed point integer.
    ///
    /// @return minimumCollateralization The minimum collateralization.
    function minimumCollateralization() external view returns (uint256 minimumCollateralization);

    /// @notice Gets the protocol fee.
    ///
    /// @return protocolFee The protocol fee.
    function protocolFee() external view returns (uint256 protocolFee);

    /// @notice Gets the protocol fee receiver.
    ///
    /// @return protocolFeeReceiver The protocol fee receiver.
    function protocolFeeReceiver() external view returns (address protocolFeeReceiver);

    /// @notice Gets the address of the whitelist contract.
    ///
    /// @return whitelist The address of the whitelist contract.
    function whitelist() external view returns (address whitelist);
    
    /// @notice Gets the conversion rate of underlying tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of underlying tokens per share.
    function getUnderlyingTokensPerShare(address yieldToken) external view returns (uint256 rate);

    /// @notice Gets the conversion rate of yield tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of yield tokens per share.
    function getYieldTokensPerShare(address yieldToken) external view returns (uint256 rate);

    /// @notice Gets the supported underlying tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported underlying tokens.
    function getSupportedUnderlyingTokens() external view returns (address[] memory tokens);

    /// @notice Gets the supported yield tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported yield tokens.
    function getSupportedYieldTokens() external view returns (address[] memory tokens);

    /// @notice Gets if an underlying token is supported.
    ///
    /// @param underlyingToken The address of the underlying token to check.
    ///
    /// @return isSupported If the underlying token is supported.
    function isSupportedUnderlyingToken(address underlyingToken) external view returns (bool isSupported);

    /// @notice Gets if a yield token is supported.
    ///
    /// @param yieldToken The address of the yield token to check.
    ///
    /// @return isSupported If the yield token is supported.
    function isSupportedYieldToken(address yieldToken) external view returns (bool isSupported);

    /// @notice Gets information about the account owned by `owner`.
    ///
    /// @param owner The address that owns the account.
    ///
    /// @return debt            The unrealized amount of debt that the account had incurred.
    /// @return depositedTokens The yield tokens that the owner has deposited.
    function accounts(address owner) external view returns (int256 debt, address[] memory depositedTokens);

    /// @notice Gets information about a yield token position for the account owned by `owner`.
    ///
    /// @param owner      The address that owns the account.
    /// @param yieldToken The address of the yield token to get the position of.
    ///
    /// @return shares            The amount of shares of that `owner` owns of the yield token.
    /// @return lastAccruedWeight The last recorded accrued weight of the yield token.
    function positions(address owner, address yieldToken)
        external view
        returns (
            uint256 shares,
            uint256 lastAccruedWeight
        );

    /// @notice Gets the amount of debt tokens `spender` is allowed to mint on behalf of `owner`.
    ///
    /// @param owner   The owner of the account.
    /// @param spender The address which is allowed to mint on behalf of `owner`.
    ///
    /// @return allowance The amount of debt tokens that `spender` can mint on behalf of `owner`.
    function mintAllowance(address owner, address spender) external view returns (uint256 allowance);

    /// @notice Gets the amount of shares of `yieldToken` that `spender` is allowed to withdraw on behalf of `owner`.
    ///
    /// @param owner      The owner of the account.
    /// @param spender    The address which is allowed to withdraw on behalf of `owner`.
    /// @param yieldToken The address of the yield token.
    ///
    /// @return allowance The amount of shares that `spender` can withdraw on behalf of `owner`.
    function withdrawAllowance(address owner, address spender, address yieldToken) external view returns (uint256 allowance);

    /// @notice Gets the parameters of an underlying token.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return params The underlying token parameters.
    function getUnderlyingTokenParameters(address underlyingToken)
        external view
        returns (UnderlyingTokenParams memory params);

    /// @notice Get the parameters and state of a yield-token.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return params The yield token parameters.
    function getYieldTokenParameters(address yieldToken)
        external view
        returns (YieldTokenParams memory params);

    /// @notice Gets current limit, maximum, and rate of the minting limiter.
    ///
    /// @return currentLimit The current amount of debt tokens that can be minted.
    /// @return rate         The maximum possible amount of tokens that can be liquidated at a time.
    /// @return maximum      The highest possible maximum amount of debt tokens that can be minted at a time.
    function getMintLimitInfo()
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );

    /// @notice Gets current limit, maximum, and rate of a repay limiter for `underlyingToken`.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return currentLimit The current amount of underlying tokens that can be repaid.
    /// @return rate         The rate at which the the current limit increases back to its maximum in tokens per block.
    /// @return maximum      The maximum possible amount of tokens that can be repaid at a time.
    function getRepayLimitInfo(address underlyingToken)
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );

    /// @notice Gets current limit, maximum, and rate of the liquidation limiter for `underlyingToken`.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return currentLimit The current amount of underlying tokens that can be liquidated.
    /// @return rate         The rate at which the function increases back to its maximum limit (tokens / block).
    /// @return maximum      The highest possible maximum amount of debt tokens that can be liquidated at a time.
    function getLiquidationLimitInfo(address underlyingToken)
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AlchemicTokenV2} from "../lib/alchemix/src/AlchemicTokenV2.sol";
import {IAlchemistV2} from "../lib/alchemix/src/interfaces/IAlchemistV2.sol";

import {ICurveCalc} from "./interfaces/ICurveCalc.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";

/// @title SelfRepayingETH
/// @author Wary
///
/// @notice An contract helper to borrow alETH from an Alchemix account, exchange it for ETH.
abstract contract SelfRepayingETH {
    /// @notice The Alchemix alETH alchemistV2 contract.
    IAlchemistV2 immutable alchemist;

    /// @notice The Alchemix alETH AlchemicTokenV2 contract.
    AlchemicTokenV2 immutable alETH;

    /// @notice The CurveCalc contract.
    ICurveCalc immutable curveCalc;

    /// @notice The alETH-ETH Curve Pool contract.
    ICurvePool immutable alETHPool;

    /// @notice Emitted when `sreth` borrows `alETHAmount` of alETH from `owner` for `ethAmount` of ETH.
    ///
    /// @param owner The address of the Alchemix account owner.
    /// @param alETHAmount The amount of alETH debt tokens that were minted in wei.
    /// @param ethAmount The amount of exchanged ETH received in wei.
    event Borrow(address indexed owner, uint256 alETHAmount, uint256 ethAmount);

    /// @notice Initialize the contract.
    //
    /// @dev We annotate it payable to make it cheaper. Do not send ETH.
    constructor(IAlchemistV2 _alchemist, ICurvePool _alETHPool, ICurveCalc _curveCalc) payable {
        alchemist = _alchemist;
        alETHPool = _alETHPool;
        curveCalc = _curveCalc;

        alETH = AlchemicTokenV2(alchemist.debtToken());

        // Approve the `alETHPool` Curve Pool to transfer an (almost) unlimited amount of `alETH` tokens.
        alETH.approve(address(_alETHPool), type(uint256).max);
    }

    /// @notice Borrow some self repaying ETH `amount` from the `alETH` account owned by `owner`.
    ///
    /// @notice Emits a {Borrow} event.
    ///
    /// @notice **_NOTE:_** The `SelfRepayingETH` contract must have enough `AlchemistV2.mintAllowance()` to borrow `amount` ETH. The can be done via the `AlchemistV2.approveMint()` method.
    ///
    /// @dev **_NOTE:_** 💀 There is no protection against the alETH-ETH depeg.
    /// @dev **_NOTE:_** 💀 A large `amount` exchange will be taken advantage off by MEV bots in a sandwich attack.
    ///
    /// @param owner The address of the Alchemix account owner to mint alETH from.
    /// @param amount The amount of ETH to borrow in wei.
    function _borrowSelfRepayingETHFrom(address owner, uint256 amount) internal {
        // Get the EXACT amount of ETH debt (i.e. alETH) to mint from the Curve Pool by asking the CurveCalc contract.
        // ⚠️ Due to a Curve Pool limitation, we use `curveCalc.get_dx()` to get the EXACT ETH amount back in a transaction when ideally it should be called in a staticcall.
        // ⚠️ We do not check the alETH-ETH depeg.
        uint256 alETHToMint = _getAlETHToMint(amount);

        // Mint `alETHToMint` amount of alETH (i.e. debt token) from `owner` to `recipient` Alchemix account.
        alchemist.mintFrom(owner, alETHToMint, address(this));
        // Execute a Curve Pool exchange for `alETHToMint` amount of alETH tokens to at least `amount` ETH.
        alETHPool.exchange(
            1, // alETH
            0, // ETH
            alETHToMint,
            amount
        );

        emit Borrow(owner, alETHToMint, amount);
    }

    /// @dev Get the current alETH amount to get `amount` ETH amount back in from a Curve Pool exchange.
    ///
    /// @param amount The ETH amount to get back from the Curve alETH exchange in wei.
    /// @return alETHToMint The exact alETH amount to swap to get `amount` ETH back from a Curve exchange.
    function _getAlETHToMint(uint256 amount) internal view returns (uint256 alETHToMint) {
        unchecked {
            // Optimizing this solidity code:
            //
            // uint256[2] memory b = alETHPool.get_balances();
            // curveCalc.get_dx(
            //     2,
            //     [b[0], b[1], 0, 0, 0, 0, 0, 0],
            //     alETHPool.A(),
            //     alETHPool.fee(),
            //     [uint256(1e18), 1e18, 0, 0, 0, 0, 0, 0],
            //     [uint256(1), 1, 0, 0, 0, 0, 0, 0],
            //     false,
            //     1, // alETH
            //     0, // ETH
            //     amount + 1 // Because of rounding errors
            // );
            address pool = address(alETHPool);
            address calc = address(curveCalc);

            assembly ("memory-safe") {
                // Get the non allocated memory offset.
                let offset := mload(0x40)

                // Building the `curveCalc.get_dx()` calldata.
                //
                // Calldata layout:
                // fn sig (4 bytes): 0x00 -> 0x03
                // bytes4(keccak256("get_dx(int128,uint256[8],uint256,uint256,uint256[8],uint256[8],bool,int128,int128,uint256)"))
                // 0x9e440fb1
                // n_coins (32 bytes): 0x04 -> 0x23
                // 00...002
                // balances (256 bytes): 0x24 -> 0x0123
                // amp (32 bytes): 0x0124 -> 0x0143
                // fee (32 bytes): 0x0144 -> 0x0163
                // rates (256 bytes): 0x0164 -> 0x0263
                // precisions (256 bytes): 0x0263 -> 0x0363
                // underlying (32 bytes): 0x0364 -> 0x0383
                // i (32 bytes): 0x0384 -> 0x03A3
                // j (32 bytes): 0x03A4 -> 0x03C3
                // dy (32 bytes): 0x03C4 -> 0x03E3
                //
                // Optimizing MSTOREs.
                // 0x00 -> 0x1F: We concat the fn sig with the first 28 bytes of n_coins which are 0s.
                // So we can store the hardcoded fn sig << 0x70 (28 * 4 bits).
                mstore(offset, 0x9e440fb100000000000000000000000000000000000000000000000000000000)
                // 0x20 -> 0x23: First we store the value 0x02 at 0x23.
                mstore8(add(offset, 0x23), 0x02)
                // 0x24 -> 0x63: Then we call alETHPool.get_balances() and store its result at 0x24.
                // Prepare its calldata. fn sig = 0x14f05979
                let o := add(offset, 0x24)
                mstore(o, 0x14f0597900000000000000000000000000000000000000000000000000000000)
                // Execute the staticcall.
                let success :=
                    staticcall(
                        gas(), // gas
                        pool, // address
                        o, // argsOffset
                        0x04, // argsSize
                        // Reuse the memory used for the args.
                        o, // retOffset
                        0x40 // retSize
                    )
                // 0x0124 -> 0x0143: Call alETHPool.A() and store its result at 0x0124. It expands the memory and fills it with 0s.
                // Prepare its calldata.
                o := add(offset, 0x0124)
                mstore(o, 0xf446c1d000000000000000000000000000000000000000000000000000000000)
                // Execute the staticcall.
                success := staticcall(gas(), pool, o, 0x04, o, 0x20)
                // 0x0144 -> 0x0163: Call alETHPool.fee() and store its result at 0x0144.
                // Prepare its calldata.
                o := add(offset, 0x0144)
                mstore(o, 0xddca3f4300000000000000000000000000000000000000000000000000000000)
                // Execute the staticcall.
                success := staticcall(gas(), pool, o, 0x04, o, 0x20)
                // 0x0164 -> 0x0263: Store 2 1e18 on the first 64 bytes. The rest of the rates array will filled during the memory expand.
                mstore(add(offset, 0x0164), 1000000000000000000)
                mstore(add(offset, 0x0184), 1000000000000000000)
                // 0x0264 -> 0x0363: Store two 1 on the first 64 bytes and use the next memory expand to fill the rest.
                mstore(add(offset, 0x0264), 0x01)
                mstore(add(offset, 0x0284), 0x01)
                // 0x0364 -> 0x0383: Do nothing as false is 0.
                // 0x0384 -> 0x03A3
                mstore(add(offset, 0x0384), 0x01)
                // 0x03A4 -> 0x03C3: Do nothing as value is 0.
                // 0x03C4 -> 0x03E3
                mstore(add(offset, 0x03C4), add(amount, 0x01))

                // Execute the `get_dx()` call.
                o := add(offset, 0x03E4)
                success := staticcall(gas(), calc, offset, 0x03E4, o, 0x20)
                // Revert if call failed.
                if iszero(success) { revert(0x00, 0x00) }
                // Return `alETHToMint`.
                alETHToMint := mload(o)

                // Update the free memory pointer.
                mstore(0x40, add(o, 0x20))
            }
        }
    }

    /// @notice To receive ETH payments.
    /// @dev To receive ETH from alETHPool.exchange(). ⚠️ The contract can receive ETH from another Ethereum account.
    receive() external payable virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @dev Solidity Curve Calc interface because it is written in vyper.
interface ICurveCalc {
    /// @notice Calculate amount of of coin i taken when exchanging for coin j
    /// @param n_coins Number of coins in the pool
    /// @param balances Array with coin balances
    /// @param amp Amplification coefficient
    /// @param fee Pool's fee at 1e10 basis
    /// @param rates Array with rates for "lent out" tokens
    /// @param precisions Precision multipliers to get the coin to 1e18 basis
    /// @param i Index of the changed coin (trade in)
    /// @param j Index of the other changed coin (trade out)
    /// @param dy Amount of coin j (trade out)
    /// @return Amount of coin i (trade in)
    function get_dx(
        int128 n_coins,
        uint256[8] calldata balances,
        uint256 amp,
        uint256 fee,
        uint256[8] calldata rates,
        uint256[8] calldata precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @dev Solidity Curve Pool interface because it is written in vyper.
interface ICurvePool {
    function get_balances() external view returns (uint256[2] memory);
    function A() external view returns (uint256);
    function fee() external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 amount, uint256 minAmount) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

/// @dev Will not work with negative bases, only use when x is positive.
function wadPow(int256 x, int256 y) pure returns (int256) {
    // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
    return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/* --- External dependencies --- */
/* --- ENS --- */
import {
    BaseRegistrarImplementation,
    ETHRegistrarController
} from "../lib/ens-contracts/contracts/ethregistrar/ETHRegistrarController.sol";
/* --- Openzeppelin --- */
import {Multicall} from "../lib/openzeppelin/contracts/utils/Multicall.sol";
/* --- Gelato --- */
import {LibDataTypes, Ops} from "../lib/ops/contracts/Ops.sol";
import {ProxyModule} from "../lib/ops/contracts/taskModules/ProxyModule.sol";
import {IOpsProxyFactory} from "../lib/ops/contracts/interfaces/IOpsProxyFactory.sol";
/* --- Self Repaying ENS --- */
import {IAlchemistV2, ICurveCalc, ICurvePool, SelfRepayingETH} from "../lib/self-repaying-eth/src/SelfRepayingETH.sol";
/* --- Solmate --- */
import {toDaysWadUnsafe, wadDiv, wadExp} from "../lib/solmate/src/utils/SignedWadMath.sol";

/* --- Internal dependencies --- */
import {EnumerableSet} from "./libraries/EnumerableSet.sol";

/// @title SelfRepayingENS
/// @author Wary
contract SelfRepayingENS is SelfRepayingETH, Multicall {
    using EnumerableSet for EnumerableSet.StringSet;

    /// @notice The ENS name renewal duration in seconds.
    uint256 constant renewalDuration = 365 days;

    /// @notice The ENS ETHRegistrarController (i.e. .eth controller) contract.
    ETHRegistrarController immutable controller;

    /// @notice The ENS BaseRegistrarImplementation (i.e. .eth registrar) contract.
    BaseRegistrarImplementation immutable registrar;

    /// @notice The Gelato contract.
    address payable immutable gelato;

    /// @notice The Gelato Ops contract.
    Ops immutable gelatoOps;

    /// @notice The Gelato address for ETH.
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The Gelato taskIds per subscriber.
    mapping(address => bytes32) internal _taskIds;

    /// @notice The Set of names to renew per subscriber.
    mapping(address => EnumerableSet.StringSet) internal _subscribedNames;

    /// @notice An event which is emitted when a user subscribe for an self repaying ENS name renewals.
    ///
    /// @param subscriber The address of the user subscribed to this service.
    /// @param indexedName The ENS name to renew.
    /// @param name The ENS name to renew.
    /// @dev We also expose the non indexed name for consumers (e.g. UI).
    event Subscribe(address indexed subscriber, string indexed indexedName, string name);

    /// @notice An event which is emitted when a user unsubscribe to the self repaying ENS name renewal service.
    ///
    /// @param subscriber The address of the user unsubscribed from this service.
    /// @param indexedName The ENS name to renew.
    /// @param name The ENS name to not renew anymore.
    /// @dev We also expose the non i
    /// ndexed name for consumers.
    event Unsubscribe(address indexed subscriber, string indexed indexedName, string name);

    /// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed to the function.
    error IllegalArgument();

    /// @notice An error used to indicate that a transfer failed.
    error FailedTransfer();

    /// @notice Initialize the contract.
    ///
    /// @dev We annotate it payable to make it cheaper. Do not send ETH.
    constructor(
        ETHRegistrarController _controller,
        BaseRegistrarImplementation _registrar,
        Ops _gelatoOps,
        IAlchemistV2 _alchemist,
        ICurvePool _alETHPool,
        ICurveCalc _curveCalc
    ) payable SelfRepayingETH(_alchemist, _alETHPool, _curveCalc) {
        controller = _controller;
        registrar = _registrar;
        gelatoOps = _gelatoOps;

        gelato = _gelatoOps.gelato();
    }

    /// @notice Subscribe to the self repaying ENS renewals service for `name`.
    ///
    /// @dev It creates ONCE a Gelato task to monitor `subscriber`'s subscribed names expiry. Fees are paid on task execution.
    ///
    /// @notice `name` must exist and not be in `subscriber`'s to be renewed list or this call will revert an {IllegalArgument} error.
    /// @notice Emits a {Subscribed} event.
    ///
    /// @notice **_NOTE:_** The `SelfRepayingENS` contract must have enough `AlchemistV2.mintAllowance()` to renew `name`. The can be done via the `AlchemistV2.approveMint()` method.
    /// @notice **_NOTE:_** The `msg.sender` must make sure they have enough `AlchemistV2.totalValue()` to cover `name` renewal fee.
    ///
    /// @param name The ENS name to monitor and renew.
    function subscribe(string memory name) external {
        EnumerableSet.StringSet storage subNames = _subscribedNames[msg.sender];
        // Check `name` exists and is within its grace period if expired.
        // The ENS grace period is 90 days.
        // Checks if `subscriber` already subscribed to renew `name`.
        if (
            registrar.nameExpires(uint256(keccak256(bytes(name)))) + 90 days < block.timestamp
                || subNames.contains(name)
        ) {
            revert IllegalArgument();
        }

        // Create ONCE a gelato task to monitor `subscriber`'s names expiry and renew them.
        // If `msg.sender` doesn't have a taskId it means it's their first time subscribing.
        if (_taskIds[msg.sender] == 0) {
            // We choose to pay Gelato when executing the task.
            _taskIds[msg.sender] =
                gelatoOps.createTask(address(this), abi.encode(this.renew.selector), _getModuleData(msg.sender), ETH);
        }

        // Add `name` to `subscriber`'s names to renew.
        subNames.add(name);

        emit Subscribe(msg.sender, name, name);
    }

    /// @notice Unsubscribe to the self repaying ENS renewals service for `name`.
    ///
    /// @notice Emits a {Unsubscribed} event.
    ///
    /// @notice **_NOTE:_** The `subscriber` (i.e. caller) can only unsubscribe from one of their renewals.
    ///
    /// @param name The ENS name to not monitor anymore.
    function unsubscribe(string memory name) external {
        // Not cancelling `msg.sender`'s Gelato task make the last unsubscribe and its following subscribe cheaper.

        // Remove `name` from `subscriber`'s names to renew.
        bool removed = _subscribedNames[msg.sender].remove(name);
        // Revert if `name` was not part of `subscriber`'s names to renew.
        if (!removed) {
            revert IllegalArgument();
        }

        emit Unsubscribe(msg.sender, name, name);
    }

    /// @notice Check if some of `subscriber`'s names should be renewed.
    ///
    /// @dev This is a Gelato resolver function. It is called by their network to know when and how to execute the renew task.
    ///
    /// @param subscriber The address of the subscriber.
    ///
    /// @return canExec The bool is true when some name is expired.
    /// @dev It tells Gelato when to execute the task (i.e. when it is true).
    /// @return execPayload The abi encoded call to execute.
    /// @dev It tells Gelato how to execute the task.
    function checker(address subscriber) external view returns (bool canExec, bytes memory execPayload) {
        unchecked {
            // We loop over `subscriber`'s names to find the most expensive renewable name since it is the closest to its expiry.
            EnumerableSet.StringSet storage subNames = _subscribedNames[subscriber];
            uint256 len = subNames.length();
            uint256 highestLimit;
            string memory mostExpensiveNameToRenew;

            // ⚠️ The loop is unbounded but we access each element from storage to avoid the in memory copy of the entire array.
            for (uint256 i; i < len; i++) {
                string memory name = subNames.at(i);
                // Try to limit the renew transaction gas price which means limiting the gelato fee.
                uint256 nameGasPriceLimit = getVariableMaxGasPrice(name);
                if (tx.gasprice <= nameGasPriceLimit && nameGasPriceLimit > highestLimit) {
                    highestLimit = nameGasPriceLimit;
                    mostExpensiveNameToRenew = name;
                }
            }

            return highestLimit == 0
                // Log the reason.
                ? (false, bytes("no names to renew"))
                // Return the Gelato task payload to execute. It must call `this.renew(name, subscriber)`.
                : (true, abi.encodeCall(this.renew, (mostExpensiveNameToRenew, subscriber)));
        }
    }

    /// @notice Renew `name` by minting new debt from `subscriber`'s Alchemix account.
    ///
    /// @notice **_NOTE:_** When renewing, the `SelfRepayingENS` contract must have **mintAllowance()** to mint new alETH debt tokens on behalf of **subscriber** to cover **name** renewal and the Gelato fee costs. This can be done via the `AlchemistV2.approveMint()` method.
    ///
    /// @dev It is called by the `GelatoOps` contract.
    /// @dev We annotate it payable to make it cheaper. Do not send ETH.
    ///
    /// @param name The ENS name to renew.
    /// @param subscriber The address of the subscriber.
    function renew(string calldata name, address subscriber) external payable {
        unchecked {
            // We do not trust the Gelato Executors to execute the task with the correct payload. We check it ourselves.
            // Checks `name` is one of `subscriber`'s names to renew and `tx.gasprice` is lower or equal to `name`'s gas price limit.
            if (!_subscribedNames[subscriber].contains(name) || tx.gasprice > getVariableMaxGasPrice(name)) {
                revert IllegalArgument();
            }

            // Get `name` rent price.
            uint256 namePrice = controller.rentPrice(name, renewalDuration);
            // Get the gelato fee in ETH.
            (uint256 gelatoFee,) = gelatoOps.getFeeDetails();
            // The amount of ETH needed to pay the ENS renewal using Gelato.
            uint256 neededETH = namePrice + gelatoFee;

            // Borrow `neededETH` amount of ETH from `subscriber` Alchemix account.
            _borrowSelfRepayingETHFrom(subscriber, neededETH);

            // Renew `name` for its expiry data + `renewalDuration` first.
            controller.renew{value: namePrice}(name, renewalDuration);

            // Pay the Gelato executor with all the ETH left. No ETH will be stuck in this contract.
            // Do not pay Gelato if `renew()` was called by someone else.
            if (msg.sender != address(gelatoOps)) return;
            (bool success,) = gelato.call{value: address(this).balance}("");
            if (!success) revert FailedTransfer();
        }
    }

    /// @notice Get the Set of names to renew for a subscriber.
    ///
    /// @param subscriber The address of the subscriber.
    /// @return names The Set of names to renew for `subscriber`.
    function subscribedNames(address subscriber) external view returns (string[] memory names) {
        return _subscribedNames[subscriber].values();
    }

    /// @notice Get the Self Repaying ENS task id created by `subscriber`.
    ///
    /// @dev This is a helper function to get a Gelato task id.
    ///
    /// @notice **_NOTE:_** This function returns 0 if the task does not exists. Make sure you call it with a subscribed `subscriber`.
    ///
    /// @param subscriber The address of the subscriber.
    /// @return taskId The Gelato task id.
    function getTaskId(address subscriber) public view returns (bytes32 taskId) {
        return _taskIds[subscriber];
    }

    /// @dev Helper function to get the Gelato module data.
    function _getModuleData(address subscriber) internal view returns (LibDataTypes.ModuleData memory moduleData) {
        moduleData = LibDataTypes.ModuleData({modules: new LibDataTypes.Module[](1), args: new bytes[](1)});

        moduleData.modules[0] = LibDataTypes.Module.RESOLVER;

        moduleData.args[0] = abi.encode(address(this), abi.encodeCall(this.checker, (subscriber)));
    }

    /// @dev Get the variable maximum gas price for this name.
    ///
    /// @notice **_NOTE:_** Returns type(uint256).max when called with a name that doesn't exist or that is expired.
    ///
    /// @param name The ENS name to renew.
    /// @return The maximum gas price in wei allowed to renew `name`.
    function getVariableMaxGasPrice(string memory name) public view returns (uint256) {
        unchecked {
            uint256 expiryDate = registrar.nameExpires(uint256(keccak256(bytes(name))));
            return _getVariableMaxGasPrice(int256(block.timestamp) - int256(expiryDate));
        }
    }

    /// @dev Get the variable maximum gas price allowed to renew a name depending on its expiry time.
    ///
    /// @dev The formula is: y = x + e^(x / 2.62 - 30); where y is the gas price limit in gwei and x is the number of days before (expiry time - 90 days).
    ///
    /// @param expiredDuration The expired time in seconds of an ENS name.
    /// @dev expiredDuration can be negative since we want to try to renew BEFORE the ENS name is expired.
    /// @return The maximum gas price allowed in wei.
    function _getVariableMaxGasPrice(int256 expiredDuration) internal pure returns (uint256) {
        unchecked {
            if (expiredDuration < -90 days) {
                // We don't want to try to renew before.
                return 0;
            } else if (expiredDuration > 0) {
                // Remove the gas price limit after expiry.
                return type(uint256).max;
            }
            // Between 90 and 0 days before expiry.
            // x = (expiredDuration + 90 days) / 1 days; in wad.
            uint256 x = uint256(toDaysWadUnsafe(uint256(expiredDuration + int256(90 days)))); // Safe here.
            // exp = x / 2.62 - 30; can be negative, in wad.
            int256 exponant = wadDiv(int256(x), 2.62e18) - 30e18;
            // a = e^exp; in wad.
            uint256 a = uint256(wadExp(exponant));
            // y = x + a; in wad.
            uint256 maxGasPriceWad = x + a;
            // In gwei;
            return maxGasPriceWad / 1e9;
        }
    }

    /// @notice To receive ETH payments.
    /// @dev See {SelfRepayingETH.receive}.
    receive() external payable override {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @dev See {@openzeppelin/contracts/utils/structs/EnumerableSet.sol}.
library EnumerableSet {
    struct StringSet {
        // Storage of set values.
        string[] _values;
        // Position of the value in the `_values` array, plus 1 because index 0 means a value is not in the set.
        mapping(string => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not already present.
     */
    function add(StringSet storage set, string memory value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes and use 0 as a sentinel value.
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was present.
     */
    function remove(StringSet storage set, string memory value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot.
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value).
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is.
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value.
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex.
            }

            // Delete the slot where the moved value was stored.
            set._values.pop();

            // Delete the index for the deleted slot.
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(StringSet storage set, string memory value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(StringSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(StringSet storage set, uint256 index) internal view returns (string memory) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array.
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(StringSet storage set) internal view returns (string[] memory) {
        return set._values;
    }
}