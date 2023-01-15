// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title IDebtToken
 * @author Unlockd
 * @notice Defines the basic interface for a debt token.
 **/
interface IDebtToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lend pool
   * @param incentivesController The address of the incentives controller
   * @param debtTokenDecimals the decimals of the debt token
   * @param debtTokenName the name of the debt token
   * @param debtTokenSymbol the symbol of the debt token
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol
  );

  /**
   * @dev Initializes the debt token.
   * @param addressProvider The address of the lend pool
   * @param underlyingAsset The address of the underlying asset
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints debt token to the `user` address
   * @param user The address receiving the borrowed underlying
   * @param onBehalfOf The beneficiary of the mint
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /**
   * @dev Burns user variable debt
   * @param user The user which debt is burnt
   * @param amount The amount to be burnt
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IIncentivesController {
  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param totalSupply The total supply of the asset in the lending pool
   * @param userBalance The balance of the user of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title IInterestRate interface
 * @dev Interface for the calculation of the interest rates
 * @author Unlockd
 */
interface IInterestRate {
  /**
   * @dev Get the variable borrow rate
   * @return the base variable borrow rate
   **/
  function baseVariableBorrowRate() external view returns (uint256);

  /**
   * @dev Get the maximum variable borrow rate
   * @return the maximum variable borrow rate
   **/
  function getMaxVariableBorrowRate() external view returns (uint256);

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations
   * @param reserve The address of the reserve
   * @param availableLiquidity The available liquidity for the reserve
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   **/
  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) external view returns (uint256, uint256);

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations
   * @param reserve The address of the reserve
   * @param uToken The uToken address
   * @param liquidityAdded The liquidity added during the operation
   * @param liquidityTaken The liquidity taken during the operation
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   **/
  function calculateInterestRates(
    address reserve,
    address uToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) external view returns (uint256 liquidityRate, uint256 variableBorrowRate);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPool {
  /**
   * @dev Emitted when _rescuer is modified in the LendPool
   * @param newRescuer The address of the new rescuer
   **/
  event RescuerChanged(address indexed newRescuer);

  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the uTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of uTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(address indexed user, address indexed reserve, uint256 amount, address indexed to);

  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   * @param nftConfigFee an estimated gas cost fee for configuring the NFT
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral,
    uint256 nftConfigFee
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated on NFTX.
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event LiquidateNFTX(
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );
  /**
   * @dev Emitted when an NFT configuration is triggered.
   * @param user The NFT holder
   * @param nftAsset The NFT collection address
   * @param nftTokenId The NFT token Id
   **/
  event ValuationApproved(address indexed user, address indexed nftAsset, uint256 indexed nftTokenId);
  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when the pause time is updated.
   */
  event PausedTimeUpdated(uint256 startTime, uint256 durationTime);

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
   * gets added to the LendPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
  @dev Emitted after the address of the interest rate strategy contract has been updated
  */
  event ReserveInterestRateAddressChanged(address indexed asset, address indexed rateAddress);

  /**
  @dev Emitted after setting the configuration bitmap of the reserve as a whole
  */
  event ReserveConfigurationChanged(address indexed asset, uint256 configuration);

  /**
  @dev Emitted after setting the configuration bitmap of the NFT collection as a whole
  */
  event NftConfigurationChanged(address indexed asset, uint256 configuration);

  /**
  @dev Emitted after setting the configuration bitmap of the NFT as a whole
  */
  event NftConfigurationByIdChanged(address indexed asset, uint256 indexed nftTokenId, uint256 configuration);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying uTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 uusdc
   * @param reserve The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the uTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of uTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address reserve, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent uTokens owned
   * E.g. User has 100 uusdc, calls withdraw() and receives 100 USDC, burning the 100 uusdc
   * @param reserve The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole uToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address reserve, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256, bool);

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(address nftAsset, uint256 nftTokenId, uint256 bidPrice, address onBehalfOf) external;

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(address nftAsset, uint256 nftTokenId, uint256 amount, uint256 bidFine) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX & Sushiswap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateNFTX(address nftAsset, uint256 nftTokenId) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX & Sushiswap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateSudoSwap(address nftAsset, uint256 nftTokenId, address LSSVMPair) external returns (uint256);

  /**
   * @dev Approves valuation of an NFT for a user
   * @dev Just the NFT holder can trigger the configuration
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function approveValuation(address nftAsset, uint256 nftTokenId) external payable;

  /**
   * @dev Validates and finalizes an uToken transfer
   * - Only callable by the overlying uToken of the `asset`
   * @param asset The address of the underlying asset of the uToken
   * @param from The user from which the uTokens are transferred
   * @param to The user receiving the uTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The uToken balance of the `from` user before the transfer
   * @param balanceToBefore The uToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external view;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getReserveConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfiguration(address asset) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @param tokenId the Token Id of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfigByTokenId(
    address asset,
    uint256 tokenId
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @dev Returns the list of the initialized reserves
   * @return the list of initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @dev Returns the state and configuration of the nft
   * @param asset The address of the underlying asset of the nft
   * @return The status of the nft
   **/
  function getNftData(address asset) external view returns (DataTypes.NftData memory);

  /**
   * @dev Returns the configuration of the nft asset
   * @param asset The address of the underlying asset of the nft
   * @param tokenId NFT asset ID
   * @return The configuration of the nft asset
   **/
  function getNftAssetConfig(
    address asset,
    uint256 tokenId
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  )
    external
    view
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    );

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    );

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (uint256 loanId, address bidderAddress, uint256 bidPrice, uint256 bidBorrowAmount, uint256 bidFine);

  /**
   * @dev Returns the state and configuration of the nft
   * @param nftAsset The address of the underlying asset of the nft
   * @param nftAsset The token ID of the asset
   **/
  function getNftLiquidatePrice(
    address nftAsset,
    uint256 nftTokenId
  ) external view returns (uint256 liquidatePrice, uint256 paybackAmount);

  /**
   * @dev Returns the list of nft addresses in the protocol
   **/
  function getNftsList() external view returns (address[] memory);

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendPool contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external;

  function setPausedTime(uint256 startTime, uint256 durationTime) external;

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view returns (bool);

  function getPausedTime() external view returns (uint256, uint256);

  /**
   * @dev Returns the cached LendPoolAddressesProvider connected to this contract
   **/

  function getAddressesProvider() external view returns (ILendPoolAddressesProvider);

  /**
   * @dev Initializes a reserve, activating it, assigning an uToken and nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param uTokenAddress The address of the uToken that will be assigned to the reserve
   * @param debtTokenAddress The address of the debtToken that will be assigned to the reserve
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address uTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external;

  /**
   * @dev Initializes a nft, activating it, assigning nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the nft
   **/
  function initNft(address asset, address uNftAddress) external;

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateAddress(address asset, address rateAddress) external;

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setReserveConfiguration(address asset, uint256 configuration) external;

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param configuration The new configuration bitmap
   **/
  function setNftConfiguration(address asset, uint256 configuration) external;

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param nftTokenId the NFT tokenId
   * @param configuration The new configuration bitmap
   **/
  function setNftConfigByTokenId(address asset, uint256 nftTokenId, uint256 configuration) external;

  /**
   * @dev Sets the max supply and token ID for a given asset
   * @param asset The address to set the data
   * @param maxSupply The max supply value
   * @param maxTokenId The max token ID value
   **/
  function setNftMaxSupplyAndTokenId(address asset, uint256 maxSupply, uint256 maxTokenId) external;

  /**
   * @dev Sets the max number of reserves in the protocol
   * @param val the value to set the max number of reserves
   **/
  function setMaxNumberOfReserves(uint256 val) external;

  /**
   * @dev Sets the max number of NFTs in the protocol
   * @param val the value to set the max number of NFTs
   **/
  function setMaxNumberOfNfts(uint256 val) external;

  /**
   * @notice Assigns the rescuer role to a given address.
   * @param newRescuer New rescuer's address
   */
  function updateRescuer(address newRescuer) external;

  /**
   * @notice Rescue tokens or ETH locked up in this contract.
   * @param tokenContract ERC20 token contract address
   * @param to        Recipient address
   * @param amount    Amount to withdraw
   * @param rescueETH bool to know if we want to rescue ETH or other token
   */
  function rescue(IERC20 tokenContract, address to, uint256 amount, bool rescueETH) external;

  /**
   * @notice Rescue NFTs locked up in this contract.
   * @param nftAsset ERC721 asset contract address
   * @param tokenId ERC721 token id
   * @param to Recipient address
   */
  function rescueNFT(IERC721Upgradeable nftAsset, uint256 tokenId, address to) external;

  /**
   * @dev Sets the fee percentage for liquidations
   * @param percentage the fee percentage to be set
   **/
  function setLiquidateFeePercentage(uint256 percentage) external;

  /**
   * @dev Sets the max timeframe between NFT config triggers and borrows
   * @param timeframe the number of seconds for the timeframe
   **/
  function setTimeframe(uint256 timeframe) external;

  /**
   * @dev Adds and address to be allowed to sell on NFTX
   * @param nftAsset the nft address of the NFT to sell
   * @param val if true is allowed to sell if false is not
   **/
  function setIsMarketSupported(address nftAsset, uint8 market, bool val) external;

  /**
   * @dev sets the fee for configuringNFTAsCollateral
   * @param configFee the amount to charge to the user
   **/
  function setConfigFee(uint256 configFee) external;

  /**
   * @dev sets the fee to be charged on first bid on nft
   * @param auctionDurationConfigFee the amount to charge to the user
   **/
  function setAuctionDurationConfigFee(uint256 auctionDurationConfigFee) external;

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendPool
   */
  function getMaxNumberOfReserves() external view returns (uint256);

  /**
   * @dev Returns the maximum number of nfts supported to be listed in this LendPool
   */
  function getMaxNumberOfNfts() external view returns (uint256);

  /**
   * @dev Returns the fee percentage for liquidations
   **/
  function getLiquidateFeePercentage() external view returns (uint256);

  /**
   * @notice Returns current rescuer
   * @return Rescuer's address
   */
  function rescuer() external view returns (address);

  /**
   * @dev Returns the max timeframe between NFT config triggers and borrows
   **/
  function getTimeframe() external view returns (uint256);

  /**
   * @dev Returns the configFee amount
   **/
  function getConfigFee() external view returns (uint256);

  /**
   * @dev Returns the auctionDurationConfigFee amount
   **/
  function getAuctionDurationConfigFee() external view returns (uint256);

  /**
   * @dev Returns if the address is allowed to sell or not on NFTX
   */
  function getIsMarketSupported(address nftAsset, uint8 market) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Unlockd Governance
 * @author Unlockd
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event UNFTRegistryUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event UnlockdDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);
  event NFTXVaultFactoryUpdated(address indexed newAddress);
  event SushiSwapRouterUpdated(address indexed newAddress);
  event LSSVMRouterUpdated(address indexed newAddress);
  event LendPoolLiquidatorUpdated(address indexed newAddress);
  event LtvManagerUpdated(address indexed newAddress);

  /**
   * @dev Returns the id of the Unlockd market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @dev Returns the WETH address
   * @return The WETH address
   **/
  function getWETHAddress() external view returns (address);

  /**
   * @dev Allows to set the WETH address for the market
   * @param _wethAddress The WETH address to set
   */
  function setWETHAddress(address _wethAddress) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl, bytes memory encodedCallData) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @dev Returns the address of the LendPool proxy
   * @return The LendPool proxy address
   **/
  function getLendPool() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendPool implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  /**
   * @dev Returns the address of the LendPoolConfigurator proxy
   * @return The LendPoolConfigurator proxy address
   **/
  function getLendPoolConfigurator() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendPoolConfigurator implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the LendPool admin
   * @return the LendPoolAdmin address
   **/
  function getPoolAdmin() external view returns (address);

  /**
   * @dev sets the address of the LendPool admin
   * @param admin the LendPoolAdmin address
   **/
  function setPoolAdmin(address admin) external;

  /**
   * @dev returns the address of the emergency admin
   * @return the EmergencyAdmin address
   **/
  function getEmergencyAdmin() external view returns (address);

  /**
   * @dev sets the address of the emergency admin
   * @param admin the EmergencyAdmin address
   **/
  function setEmergencyAdmin(address admin) external;

  /**
   * @dev returns the address of the reserve oracle
   * @return the ReserveOracle address
   **/
  function getReserveOracle() external view returns (address);

  /**
   * @dev sets the address of the reserve oracle
   * @param reserveOracle the ReserveOracle address
   **/
  function setReserveOracle(address reserveOracle) external;

  /**
   * @dev returns the address of the NFT oracle
   * @return the NFTOracle address
   **/
  function getNFTOracle() external view returns (address);

  /**
   * @dev sets the address of the NFT oracle
   * @param nftOracle the NFTOracle address
   **/
  function setNFTOracle(address nftOracle) external;

  /**
   * @dev returns the address of the lendpool loan
   * @return the LendPoolLoan address
   **/
  function getLendPoolLoan() external view returns (address);

  /**
   * @dev sets the address of the lendpool loan
   * @param loan the LendPoolLoan address
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the UNFT Registry
   * @return the UNFTRegistry address
   **/
  function getUNFTRegistry() external view returns (address);

  /**
   * @dev sets the address of the UNFT registry
   * @param factory the UNFTRegistry address
   **/
  function setUNFTRegistry(address factory) external;

  /**
   * @dev returns the address of the incentives controller
   * @return the IncentivesController address
   **/
  function getIncentivesController() external view returns (address);

  /**
   * @dev sets the address of the incentives controller
   * @param controller the IncentivesController address
   **/
  function setIncentivesController(address controller) external;

  /**
   * @dev returns the address of the UI data provider
   * @return the UIDataProvider address
   **/
  function getUIDataProvider() external view returns (address);

  /**
   * @dev sets the address of the UI data provider
   * @param provider the UIDataProvider address
   **/
  function setUIDataProvider(address provider) external;

  /**
   * @dev returns the address of the Unlockd data provider
   * @return the UnlockdDataProvider address
   **/
  function getUnlockdDataProvider() external view returns (address);

  /**
   * @dev sets the address of the Unlockd data provider
   * @param provider the UnlockdDataProvider address
   **/
  function setUnlockdDataProvider(address provider) external;

  /**
   * @dev returns the address of the wallet balance provider
   * @return the WalletBalanceProvider address
   **/
  function getWalletBalanceProvider() external view returns (address);

  /**
   * @dev sets the address of the wallet balance provider
   * @param provider the WalletBalanceProvider address
   **/
  function setWalletBalanceProvider(address provider) external;

  function getNFTXVaultFactory() external view returns (address);

  /**
   * @dev sets the address of the NFTXVault Factory contract
   * @param factory the NFTXVault Factory address
   **/
  function setNFTXVaultFactory(address factory) external;

  /**
   * @dev returns the address of the SushiSwap router contract
   **/
  function getSushiSwapRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the LSSVM router address
   **/
  function setSushiSwapRouter(address router) external;

  /**
   * @dev returns the address of the LSSVM router contract
   **/
  function getLSSVMRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the SushiSwap router address
   **/
  function setLSSVMRouter(address router) external;

  /**
   * @dev returns the address of the LendPool liquidator contract
   **/
  function getLendPoolLiquidator() external view returns (address);

  /**
   * @dev sets the address of the LendPool liquidator contract
   * @param liquidator the LendPool liquidator address
   **/
  function setLendPoolLiquidator(address liquidator) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface ILendPoolLoan {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    address indexed onBehalfOf,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is updated
   * @param user The address initiating the action
   */
  event LoanUpdated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is auction by the liquidator
   * @param user The address initiating the action
   */
  event LoanAuctioned(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 borrowIndex,
    address bidder,
    uint256 price,
    address previousBidder,
    uint256 previousPrice
  );

  /**
   * @dev Emitted when a loan is redeemed
   * @param user The address initiating the action
   */
  event LoanRedeemed(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate on NFTX
   */
  event LoanLiquidatedNFTX(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex,
    uint256 sellPrice
  );

  /**
   * @dev Emitted when a loan is liquidate on SudoSwap
   */
  event LoanLiquidatedSudoSwap(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex,
    uint256 sellPrice,
    address LSSVMPair
  );

  function initNft(address nftAsset, address uNftAddress) external;

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow
   * @param onBehalfOf The address receiving the loan
   * @param nftAsset The address of the underlying NFT asset
   * @param nftTokenId The token Id of the underlying NFT asset
   * @param uNftAddress The address of the uNFT token
   * @param reserveAsset The address of the underlying reserve asset
   * @param amount The loan amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address uNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external returns (uint256);

  /**
   * @dev Update the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Active
   * @param initiator The address of the user updating the loan
   * @param loanId The loan ID
   * @param amountAdded The amount added to the loan
   * @param amountTaken The amount taken from the loan
   * @param borrowIndex The index to get the scaled loan amount
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param amount The amount repaid
   * @param borrowIndex The index to get the scaled loan amount
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Auction the given loan
   *
   * Requirements:
   *  - The price must be greater than current highest price
   *  - The loan must be in state Active or Auction
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting auctioned
   * @param bidPrice The bid price of this auction
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Redeem the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Auction
   * @param initiator The address of the user initiating the borrow
   * @param loanId The loan getting redeemed
   * @param amountTaken The taken amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function redeemLoan(
    address initiator,
    uint256 loanId,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param borrowAmount The borrow amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan on NFTX
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Auction
   *
   * @param loanId The loan getting burned
   */
  function liquidateLoanNFTX(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external returns (uint256 sellPrice);

  /**
   * @dev Liquidate the given loan on SudoSwap
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Auction
   *
   * @param loanId The loan getting burned
   */
  function liquidateLoanSudoSwap(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    address LSSVMPair
  ) external returns (uint256 sellPrice);

  /**
   *  @dev returns the borrower of a specific loan
   * param loanId the loan to get the borrower from
   */
  function borrowerOf(uint256 loanId) external view returns (address);

  /**
   *  @dev returns the loan corresponding to a specific NFT
   * param nftAsset the underlying NFT asset
   * param tokenId the underlying token ID for the NFT
   */
  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  /**
   *  @dev returns the loan corresponding to a specific loan Id
   * param loanId the loan Id
   */
  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  /**
   *  @dev returns the collateral and reserve corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    returns (
      address nftAsset,
      uint256 nftTokenId,
      address reserveAsset,
      uint256 scaledAmount
    );

  /**
   *  @dev returns the reserve and borrow __scaled__ amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the reserve and borrow  amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanHighestBid(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the collateral amount for a given NFT
   * param nftAsset the underlying NFT asset
   */
  function getNftCollateralAmount(address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the collateral amount for a given NFT and a specific user
   * param user the user
   * param nftAsset the underlying NFT asset
   */
  function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the counter tracker for all the loan ID's in the protocol
   */
  function getLoanIdTracker() external view returns (CountersUpgradeable.Counter memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
    @param assetContract the underlying NFT asset
    @param tokenId the underlying NFT token Id
  */
  function getNFTPrice(address assetContract, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title IReserveOracleGetter interface
@notice Interface for getting Reserve price oracle.*/
interface IReserveOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address asset) external view returns (uint256);

  // get twap price depending on _period
  function getTwapPrice(address _priceFeedKey, uint256 _interval) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IUNFT is IERC721MetadataUpgradeable, IERC721ReceiverUpgradeable, IERC721EnumerableUpgradeable {
  /**
   * @dev Emitted when an uNFT is initialized
   * @param underlyingAsset The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the uNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned uNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Initializes the uNFT
   * @param underlyingAsset The address of the underlying asset of this uNFT (E.g. PUNK for bPUNK)
   */
  function initialize(address underlyingAsset, string calldata uNftName, string calldata uNftSymbol) external;

  /**
   * @dev Mints uNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the uNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user uNFT token
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IUToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when an uToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this uToken
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController
  );

  /**
   * @dev Initializes the bToken
   * @param addressProvider The address of the address provider where this bToken will be used
   * @param treasury The address of the Unlockd treasury, receiving the fees on this bToken
   * @param underlyingAsset The address of the underlying asset of this bToken
   * @param uTokenDecimals The amount of token decimals
   * @param uTokenName The name of the token
   * @param uTokenSymbol The token symbol
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 uTokenDecimals,
    string calldata uTokenName,
    string calldata uTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` uTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(address user, uint256 amount, uint256 index) external returns (bool);

  /**
   * @dev Emitted after uTokens are burned
   * @param from The owner of the uTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns uTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the uTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;

  /**
   * @dev Mints uTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow() and withdraw()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this uToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @dev Returns the address of the treasury set to this uToken
   **/
  function RESERVE_TREASURY_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/interface/INFTXVault.sol
 */
interface INFTXVault is IERC20 {
  function mint(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts /* ignored for ERC721 vaults */
  ) external returns (uint256);

  function allValidNFTs(uint256[] calldata tokenIds) external view returns (bool);

  function vaultId() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @dev https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/interface/INFTXVaultFactory.sol
 */
interface INFTXVaultFactoryV2 {
  // Read functions.
  function feeDistributor() external view returns (address);

  function numVaults() external view returns (uint256);

  function vaultsForAsset(address asset) external view returns (address[] memory);

  function vaultFees(uint256 vaultId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // Write functions.
  function createVault(
    string calldata name,
    string calldata symbol,
    address _assetAddress,
    bool is1155,
    bool allowAllItems
  ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILSSVMPair {
  enum CurveErrorCodes {
    OK, // No error
    INVALID_NUMITEMS, // The numItem value is 0
    SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
  }

  function getBuyNFTQuote(uint256 numNFTs)
    external
    view
    returns (
      CurveErrorCodes error,
      uint256 newSpotPrice,
      uint256 newDelta,
      uint256 inputAmount,
      uint256 protocolFee
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {SudoSwapSeller} from "../../libraries/markets/SudoSwapSeller.sol";

/**
 * @title ILSSVMRouter
 * @author Unlockd
 * @notice Defines the basic interface for the NFTX Marketplace Zap.
 **/

interface ILSSVMRouter {
  function swapNFTsForToken(
    SudoSwapSeller.PairSwapSpecific[] calldata swapList,
    uint256 minOutput,
    address tokenRecipient,
    uint256 deadline
  ) external returns (uint256 outputAmount);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title NftConfiguration library
 * @author Unlockd
 * @notice Implements the bitmap logic to handle the NFT configuration
 */
library NftConfiguration { 
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_DURATION_MASK =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant AUCTION_DURATION_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_FINE_MASK =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_THRESHOLD_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant MIN_BIDFINE_MASK      =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant CONFIG_TIMESTAMP_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant REDEEM_DURATION_START_BIT_POSITION = 64;
  uint256 constant AUCTION_DURATION_START_BIT_POSITION = 72;
  uint256 constant REDEEM_FINE_START_BIT_POSITION = 80;
  uint256 constant REDEEM_THRESHOLD_START_BIT_POSITION = 96;
  uint256 constant MIN_BIDFINE_START_BIT_POSITION = 112;
  uint256 constant CONFIG_TIMESTAMP_START_BIT_POSITION = 128;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_REDEEM_DURATION = 255;
  uint256 constant MAX_VALID_AUCTION_DURATION = 255;
  uint256 constant MAX_VALID_REDEEM_FINE = 65535;
  uint256 constant MAX_VALID_REDEEM_THRESHOLD = 65535;
  uint256 constant MAX_VALID_MIN_BIDFINE = 65535;
  uint256 constant MAX_VALID_CONFIG_TIMESTAMP = 4294967295;

  /**
   * @dev Sets the Loan to Value of the NFT
   * @param self The NFT configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.NftConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the NFT
   * @param self The NFT configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the NFT
   * @param self The NFT configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.NftConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the NFT
   * @param self The NFT configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the NFT
   * @param self The NFT configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.NftConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the NFT
   * @param self The NFT configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the NFT
   * @param self The NFT configuration
   * @param active The active state
   **/
  function setActive(DataTypes.NftConfigurationMap memory self, bool active) internal pure {
    self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the NFT
   * @param self The NFT configuration
   * @return The active state
   **/
  function getActive(DataTypes.NftConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the NFT
   * @param self The NFT configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.NftConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the NFT
   * @param self The NFT configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.NftConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Sets the redeem duration of the NFT
   * @param self The NFT configuration
   * @param redeemDuration The redeem duration
   **/
  function setRedeemDuration(DataTypes.NftConfigurationMap memory self, uint256 redeemDuration) internal pure {
    require(redeemDuration <= MAX_VALID_REDEEM_DURATION, Errors.RC_INVALID_REDEEM_DURATION);

    self.data = (self.data & REDEEM_DURATION_MASK) | (redeemDuration << REDEEM_DURATION_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem duration of the NFT
   * @param self The NFT configuration
   * @return The redeem duration
   **/
  function getRedeemDuration(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION;
  }

  /**
   * @dev Sets the auction duration of the NFT
   * @param self The NFT configuration
   * @param auctionDuration The auction duration
   **/
  function setAuctionDuration(DataTypes.NftConfigurationMap memory self, uint256 auctionDuration) internal pure {
    require(auctionDuration <= MAX_VALID_AUCTION_DURATION, Errors.RC_INVALID_AUCTION_DURATION);

    self.data = (self.data & AUCTION_DURATION_MASK) | (auctionDuration << AUCTION_DURATION_START_BIT_POSITION);
  }

  /**
   * @dev Gets the auction duration of the NFT
   * @param self The NFT configuration
   * @return The auction duration
   **/
  function getAuctionDuration(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION;
  }

  /**
   * @dev Sets the redeem fine of the NFT
   * @param self The NFT configuration
   * @param redeemFine The redeem duration
   **/
  function setRedeemFine(DataTypes.NftConfigurationMap memory self, uint256 redeemFine) internal pure {
    require(redeemFine <= MAX_VALID_REDEEM_FINE, Errors.RC_INVALID_REDEEM_FINE);

    self.data = (self.data & REDEEM_FINE_MASK) | (redeemFine << REDEEM_FINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem fine of the NFT
   * @param self The NFT configuration
   * @return The redeem fine
   **/
  function getRedeemFine(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION;
  }

  /**
   * @dev Sets the redeem threshold of the NFT
   * @param self The NFT configuration
   * @param redeemThreshold The redeem duration
   **/
  function setRedeemThreshold(DataTypes.NftConfigurationMap memory self, uint256 redeemThreshold) internal pure {
    require(redeemThreshold <= MAX_VALID_REDEEM_THRESHOLD, Errors.RC_INVALID_REDEEM_THRESHOLD);

    self.data = (self.data & REDEEM_THRESHOLD_MASK) | (redeemThreshold << REDEEM_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem threshold of the NFT
   * @param self The NFT configuration
   * @return The redeem threshold
   **/
  function getRedeemThreshold(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the min & max threshold of the NFT
   * @param self The NFT configuration
   * @param minBidFine The min bid fine
   **/
  function setMinBidFine(DataTypes.NftConfigurationMap memory self, uint256 minBidFine) internal pure {
    require(minBidFine <= MAX_VALID_MIN_BIDFINE, Errors.RC_INVALID_MIN_BID_FINE);

    self.data = (self.data & MIN_BIDFINE_MASK) | (minBidFine << MIN_BIDFINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the min bid fine of the NFT
   * @param self The NFT configuration
   * @return The min bid fine
   **/
  function getMinBidFine(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return ((self.data & ~MIN_BIDFINE_MASK) >> MIN_BIDFINE_START_BIT_POSITION);
  }

  /**
   * @dev Sets the timestamp when the NFTconfig was triggered
   * @param self The NFT configuration
   * @param configTimestamp The config timestamp
   **/
  function setConfigTimestamp(DataTypes.NftConfigurationMap memory self, uint256 configTimestamp) internal pure {
    require(configTimestamp <= MAX_VALID_CONFIG_TIMESTAMP, Errors.RC_INVALID_MAX_CONFIG_TIMESTAMP);

    self.data = (self.data & CONFIG_TIMESTAMP_MASK) | (configTimestamp << CONFIG_TIMESTAMP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the timestamp when the NFTconfig was triggered
   * @param self The NFT configuration
   * @return The config timestamp
   **/
  function getConfigTimestamp(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return ((self.data & ~CONFIG_TIMESTAMP_MASK) >> CONFIG_TIMESTAMP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the configuration flags of the NFT
   * @param self The NFT configuration
   * @return The state flags representing active, frozen
   **/
  function getFlags(DataTypes.NftConfigurationMap storage self) internal view returns (bool, bool) {
    uint256 dataLocal = self.data;

    return ((dataLocal & ~ACTIVE_MASK) != 0, (dataLocal & ~FROZEN_MASK) != 0);
  }

  /**
   * @dev Gets the configuration flags of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state flags representing active, frozen
   **/
  function getFlagsMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (bool, bool) {
    return ((self.data & ~ACTIVE_MASK) != 0, (self.data & ~FROZEN_MASK) != 0);
  }

  /**
   * @dev Gets the collateral configuration paramters of the NFT
   * @param self The NFT configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus
   **/
  function getCollateralParams(
    DataTypes.NftConfigurationMap storage self
  ) internal view returns (uint256, uint256, uint256) {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the auction configuration paramters of the NFT
   * @param self The NFT configuration
   * @return The state params representing redeem duration, auction duration, redeem fine
   **/
  function getAuctionParams(
    DataTypes.NftConfigurationMap storage self
  ) internal view returns (uint256, uint256, uint256, uint256) {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION,
      (dataLocal & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION,
      (dataLocal & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION,
      (dataLocal & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the collateral configuration paramters of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus
   **/
  function getCollateralParamsMemory(
    DataTypes.NftConfigurationMap memory self
  ) internal pure returns (uint256, uint256, uint256) {
    return (
      self.data & ~LTV_MASK,
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the auction configuration paramters of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state params representing redeem duration, auction duration, redeem fine
   **/
  function getAuctionParamsMemory(
    DataTypes.NftConfigurationMap memory self
  ) internal pure returns (uint256, uint256, uint256, uint256) {
    return (
      (self.data & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION,
      (self.data & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION,
      (self.data & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION,
      (self.data & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the min & max bid fine of the NFT
   * @param self The NFT configuration
   * @return The min & max bid fine
   **/
  function getMinBidFineMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (uint256) {
    return ((self.data & ~MIN_BIDFINE_MASK) >> MIN_BIDFINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the timestamp the NFT was configured
   * @param self The NFT configuration
   * @return The timestamp value
   **/
  function getConfigTimestampMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (uint256) {
    return ((self.data & ~CONFIG_TIMESTAMP_MASK) >> CONFIG_TIMESTAMP_START_BIT_POSITION);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Unlockd
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_DECIMALS = 255;
  uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

  /**
   * @dev Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
    require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @dev Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @dev Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

    self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @dev Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @dev Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlags(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParams(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      self.data & ~LTV_MASK,
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the configuration flags of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    return (
      (self.data & ~ACTIVE_MASK) != 0,
      (self.data & ~FROZEN_MASK) != 0,
      (self.data & ~BORROWING_MASK) != 0,
      (self.data & ~STABLE_BORROWING_MASK) != 0
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title Errors library
 * @author Unlockd
 * @notice Defines the error messages emitted by the different contracts of the Unlockd protocol
 */
library Errors {
  enum ReturnCode {
    SUCCESS,
    FAILED
  }

  string public constant SUCCESS = "0";

  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
  string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
  string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
  string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
  string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";
  string public constant CALLER_NOT_POOL_LIQUIDATOR = "105";
  string public constant INVALID_ZERO_ADDRESS = "106";
  string public constant CALLER_NOT_LTV_MANAGER = "107";
  string public constant CALLER_NOT_PRICE_MANAGER = "108";

  //math library erros
  string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
  string public constant MATH_ADDITION_OVERFLOW = "201";
  string public constant MATH_DIVISION_BY_ZERO = "202";

  //validation & check errors
  string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "307"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_ACTIVE_NFT = "310";
  string public constant VL_NFT_FROZEN = "311";
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
  string public constant VL_INVALID_HEALTH_FACTOR = "313";
  string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
  string public constant VL_INVALID_TARGET_ADDRESS = "315";
  string public constant VL_INVALID_RESERVE_ADDRESS = "316";
  string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
  string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
  string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD = "319";
  string public constant VL_TIMEFRAME_EXCEEDED = "320";
  string public constant VL_VALUE_EXCEED_TREASURY_BALANCE = "321";

  //lend pool errors
  string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
  string public constant LP_NOT_CONTRACT = "403";
  string public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD = "404";
  string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
  string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
  string public constant LP_INVALID_USER_NFT_AMOUNT = "407";
  string public constant LP_INCONSISTENT_PARAMS = "408";
  string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
  string public constant LP_CALLER_MUST_BE_AN_UTOKEN = "410";
  string public constant LP_INVALID_NFT_AMOUNT = "411";
  string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
  string public constant LP_DELEGATE_CALL_FAILED = "413";
  string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
  string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
  string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
  string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
  string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
  string public constant LP_CALLER_NOT_LEND_POOL_LIQUIDATOR_NOR_GATEWAY = "419";
  string public constant LP_CONSECUTIVE_BIDS_NOT_ALLOWED = "420";
  string public constant LP_INVALID_OVERFLOW_VALUE = "421";
  string public constant LP_CALLER_NOT_NFT_HOLDER = "422";
  string public constant LP_NFT_NOT_ALLOWED_TO_SELL = "423";
  string public constant LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY = "424";
  string public constant LP_COLLECTION_NOT_SUPPORTED = "425";
  string public constant MSG_VALUE_DIFFERENT_FROM_CONFIG_FEE = "426";

  //lend pool loan errors
  string public constant LPL_INVALID_LOAN_STATE = "480";
  string public constant LPL_INVALID_LOAN_AMOUNT = "481";
  string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
  string public constant LPL_AMOUNT_OVERFLOW = "483";
  string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
  string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
  string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
  string public constant LPL_BID_USER_NOT_SAME = "487";
  string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
  string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
  string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
  string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
  string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
  string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
  string public constant LPL_INVALID_BID_FINE = "494";
  string public constant LPL_BID_PRICE_LESS_THAN_MIN_BID_REQUIRED = "495";

  //common token errors
  string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
  string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
  string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

  //reserve logic errors
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

  //configure errors
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
  string public constant LPC_INVALID_UNFT_ADDRESS = "703";
  string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
  string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";
  string public constant LPC_PARAMS_MISMATCH = "706"; // NFT assets & token ids mismatch
  string public constant LPC_FEE_PERCENTAGE_TOO_HIGH = "707";
  string public constant LPC_INVALID_LTVMANAGER_ADDRESS = "708";
  string public constant LPC_INCONSISTENT_PARAMS = "709";
  //reserve config errors
  string public constant RC_INVALID_LTV = "730";
  string public constant RC_INVALID_LIQ_THRESHOLD = "731";
  string public constant RC_INVALID_LIQ_BONUS = "732";
  string public constant RC_INVALID_DECIMALS = "733";
  string public constant RC_INVALID_RESERVE_FACTOR = "734";
  string public constant RC_INVALID_REDEEM_DURATION = "735";
  string public constant RC_INVALID_AUCTION_DURATION = "736";
  string public constant RC_INVALID_REDEEM_FINE = "737";
  string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
  string public constant RC_INVALID_MIN_BID_FINE = "739";
  string public constant RC_INVALID_MAX_BID_FINE = "740";
  string public constant RC_INVALID_MAX_CONFIG_TIMESTAMP = "741";

  //address provider erros
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";

  //NFTXHelper
  string public constant NFTX_INVALID_VAULTS_LENGTH = "800";

  //NFTOracleErrors
  string public constant NFTO_INVALID_PRICEM_ADDRESS = "900";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUToken} from "../../interfaces/IUToken.sol";
import {IDebtToken} from "../../interfaces/IDebtToken.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";

import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

/**
 * @title BorrowLogic library
 * @author Unlockd
 * @notice Implements the logic to borrow feature
 */
library BorrowLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;

  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  struct ExecuteBorrowLocalVars {
    address initiator;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 loanId;
    address reserveOracle;
    address nftOracle;
    address loanAddress;
    uint256 totalSupply;
  }

  /**
   * @notice Implements the borrow feature. Through `borrow()`, users borrow assets from the protocol.
   * @dev Emits the `Borrow()` event.
   * @param addressesProvider The addresses provider
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the borrow function
   */
  function executeBorrow(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteBorrowParams memory params
  ) external {
    _borrow(addressesProvider, reservesData, nftsData, nftsConfig, params);
  }

  /**
   * @notice Implements the borrow feature. Through `_borrow()`, users borrow assets from the protocol.
   * @dev Emits the `Borrow()` event.
   * @param addressesProvider The addresses provider
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the borrow function
   */
  function _borrow(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteBorrowParams memory params
  ) internal {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    ExecuteBorrowLocalVars memory vars;
    vars.initiator = params.initiator;

    DataTypes.ReserveData storage reserveData = reservesData[params.asset];
    DataTypes.NftData storage nftData = nftsData[params.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[params.nftAsset][params.nftTokenId];

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();
    // Convert asset amount to ETH
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();
    vars.loanAddress = addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    vars.totalSupply = IERC721EnumerableUpgradeable(params.nftAsset).totalSupply();
    require(vars.totalSupply <= nftData.maxSupply, Errors.LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT);
    require(params.nftTokenId <= nftData.maxTokenId, Errors.LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT);
    ValidationLogic.validateBorrow(
      params,
      reserveData,
      nftData,
      nftConfig,
      vars.loanAddress,
      vars.loanId,
      vars.reserveOracle,
      vars.nftOracle
    );

    require(
      IERC20Upgradeable(params.asset).balanceOf(reserveData.uTokenAddress) >= params.amount,
      Errors.LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY
    );

    if (vars.loanId == 0) {
      IERC721Upgradeable(params.nftAsset).safeTransferFrom(vars.initiator, address(this), params.nftTokenId);

      vars.loanId = ILendPoolLoan(vars.loanAddress).createLoan(
        vars.initiator,
        params.onBehalfOf,
        params.nftAsset,
        params.nftTokenId,
        nftData.uNftAddress,
        params.asset,
        params.amount,
        reserveData.variableBorrowIndex
      );
    } else {
      ILendPoolLoan(vars.loanAddress).updateLoan(
        vars.initiator,
        vars.loanId,
        params.amount,
        0,
        reserveData.variableBorrowIndex
      );
    }

    IDebtToken(reserveData.debtTokenAddress).mint(
      vars.initiator,
      params.onBehalfOf,
      params.amount,
      reserveData.variableBorrowIndex
    );

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(params.asset, reserveData.uTokenAddress, 0, params.amount);

    IUToken(reserveData.uTokenAddress).transferUnderlyingTo(vars.initiator, params.amount);

    emit Borrow(
      vars.initiator,
      params.asset,
      params.amount,
      params.nftAsset,
      params.nftTokenId,
      params.onBehalfOf,
      reserveData.currentVariableBorrowRate,
      vars.loanId,
      params.referralCode
    );
  }

  struct RepayLocalVars {
    address initiator;
    address poolLoan;
    address onBehalfOf;
    uint256 loanId;
    bool isUpdate;
    uint256 borrowAmount;
    uint256 repayAmount;
  }

  /**
   * @notice Implements the repay feature. Through `repay()`, users repay assets to the protocol.
   * @dev Emits the `Repay()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of nfts
   * @param params The additional parameters needed to execute the repay function
   */
  function executeRepay(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteRepayParams memory params
  ) external returns (uint256, bool) {
    return _repay(addressesProvider, reservesData, nftsData, nftsConfig, params);
  }

  /**
   * @notice Implements the repay feature. Through `repay()`, users repay assets to the protocol.
   * @dev Emits the `Repay()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the repay function
   */
  function _repay(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteRepayParams memory params
  ) internal returns (uint256, bool) {
    RepayLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.poolLoan = addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[params.nftAsset][params.nftTokenId];

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (, vars.borrowAmount) = ILendPoolLoan(vars.poolLoan).getLoanReserveBorrowAmount(vars.loanId);

    ValidationLogic.validateRepay(reserveData, nftData, nftConfig, loanData, params.amount, vars.borrowAmount);

    vars.repayAmount = vars.borrowAmount;
    vars.isUpdate = false;
    if (params.amount < vars.repayAmount) {
      vars.isUpdate = true;
      vars.repayAmount = params.amount;
    }

    if (vars.isUpdate) {
      ILendPoolLoan(vars.poolLoan).updateLoan(
        vars.initiator,
        vars.loanId,
        0,
        vars.repayAmount,
        reserveData.variableBorrowIndex
      );
    } else {
      ILendPoolLoan(vars.poolLoan).repayLoan(
        vars.initiator,
        vars.loanId,
        nftData.uNftAddress,
        vars.repayAmount,
        reserveData.variableBorrowIndex
      );
    }

    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, vars.repayAmount, 0);

    // transfer repay amount to uToken
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
      vars.initiator,
      reserveData.uTokenAddress,
      vars.repayAmount
    );

    // transfer erc721 to borrower
    if (!vars.isUpdate) {
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.borrower, params.nftTokenId);
    }

    emit Repay(
      vars.initiator,
      loanData.reserveAsset,
      vars.repayAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.repayAmount, !vars.isUpdate);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title GenericLogic library
 * @author Unlockd
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

  struct CalculateLoanDataVars {
    uint256 reserveUnitPrice;
    uint256 reserveUnit;
    uint256 reserveDecimals;
    uint256 healthFactor;
    uint256 totalCollateralInETH;
    uint256 totalCollateralInReserve;
    uint256 totalDebtInETH;
    uint256 totalDebtInReserve;
    uint256 nftLtv;
    uint256 nftLiquidationThreshold;
    address nftAsset;
    uint256 nftTokenId;
    uint256 nftUnitPrice;
  }

  /**
   * @dev Calculates the nft loan data.
   * this includes the total collateral/borrow balances in Reserve,
   * the Loan To Value, the Liquidation Ratio, and the Health factor.
   * @param reserveAddress the underlying asset of the reserve
   * @param reserveData Data of the reserve
   * @param nftAddress the underlying NFT asset
   * @param nftTokenId the token Id for the NFT
   * @param nftConfig Config of the nft by tokenId
   * @param loanAddress The loan address
   * @param loanId The loan identifier
   * @param reserveOracle The price oracle address of reserve
   * @param nftOracle The price oracle address of nft
   * @return The total collateral and total debt of the loan in Reserve, the ltv, liquidation threshold and the HF
   **/
  function calculateLoanData(
    address reserveAddress,
    DataTypes.ReserveData storage reserveData,
    address nftAddress,
    uint256 nftTokenId,
    DataTypes.NftConfigurationMap storage nftConfig,
    address loanAddress,
    uint256 loanId,
    address reserveOracle,
    address nftOracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    CalculateLoanDataVars memory vars;
    (vars.nftLtv, vars.nftLiquidationThreshold, ) = nftConfig.getCollateralParams();

    // calculate total borrow balance for the loan
    if (loanId != 0) {
      (vars.totalDebtInETH, vars.totalDebtInReserve) = calculateNftDebtData(
        reserveAddress,
        reserveData,
        loanAddress,
        loanId,
        reserveOracle
      );
    }

    // calculate total collateral balance for the nft
    (vars.totalCollateralInETH, vars.totalCollateralInReserve) = calculateNftCollateralData(
      reserveAddress,
      reserveData,
      nftAddress,
      nftTokenId,
      reserveOracle,
      nftOracle
    );

    // calculate health by borrow and collateral
    vars.healthFactor = calculateHealthFactorFromBalances(
      vars.totalCollateralInReserve,
      vars.totalDebtInReserve,
      vars.nftLiquidationThreshold
    );
    return (vars.totalCollateralInReserve, vars.totalDebtInReserve, vars.healthFactor);
  }

  /**
   * @dev Calculates the nft debt data.
   * this includes the total collateral/borrow balances in Reserve,
   * the Loan To Value, the Liquidation Ratio, and the Health factor.
   * @param reserveAddress the underlying asset of the reserve
   * @param reserveData Data of the reserve
   * @param loanAddress The loan address
   * @param loanId The loan identifier
   * @param reserveOracle The price oracle address of reserve
   * @return The total debt in ETH and the total debt in the Reserve
   **/
  function calculateNftDebtData(
    address reserveAddress,
    DataTypes.ReserveData storage reserveData,
    address loanAddress,
    uint256 loanId,
    address reserveOracle
  ) internal view returns (uint256, uint256) {
    CalculateLoanDataVars memory vars;

    // all asset price has converted to ETH based, unit is in WEI (18 decimals)

    vars.reserveDecimals = reserveData.configuration.getDecimals();
    vars.reserveUnit = 10**vars.reserveDecimals;

    vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAddress);

    (, vars.totalDebtInReserve) = ILendPoolLoan(loanAddress).getLoanReserveBorrowAmount(loanId);
    vars.totalDebtInETH = (vars.totalDebtInReserve * vars.reserveUnitPrice) / vars.reserveUnit;

    return (vars.totalDebtInETH, vars.totalDebtInReserve);
  }

  /**
   * @dev Calculates the nft collateral data.
   * this includes the total collateral/borrow balances in Reserve,
   * the Loan To Value, the Liquidation Ratio, and the Health factor.
   * @param reserveAddress the underlying asset of the reserve
   * @param reserveData Data of the reserve
   * @param nftAddress The underlying NFT asset
   * @param nftTokenId The underlying NFT token Id
   * @param reserveOracle The price oracle address of reserve
   * @param nftOracle The nft price oracle address
   * @return The total debt in ETH and the total debt in the Reserve
   **/
  function calculateNftCollateralData(
    address reserveAddress,
    DataTypes.ReserveData storage reserveData,
    address nftAddress,
    uint256 nftTokenId,
    address reserveOracle,
    address nftOracle
  ) internal view returns (uint256, uint256) {
    reserveData;

    CalculateLoanDataVars memory vars;

    // calculate total collateral balance for the nft
    // all asset price has converted to ETH based, unit is in WEI (18 decimals)
    vars.nftUnitPrice = INFTOracleGetter(nftOracle).getNFTPrice(nftAddress, nftTokenId);
    vars.totalCollateralInETH = vars.nftUnitPrice;

    if (reserveAddress != address(0)) {
      vars.reserveDecimals = reserveData.configuration.getDecimals();
      vars.reserveUnit = 10**vars.reserveDecimals;

      vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAddress);
      vars.totalCollateralInReserve = (vars.totalCollateralInETH * vars.reserveUnit) / vars.reserveUnitPrice;
    }

    return (vars.totalCollateralInETH, vars.totalCollateralInReserve);
  }

  /**
   * @dev Calculates the health factor from the corresponding balances
   * @param totalCollateral The total collateral
   * @param totalDebt The total debt
   * @param liquidationThreshold The avg liquidation threshold
   * @return The health factor calculated from the balances provided
   **/
  function calculateHealthFactorFromBalances(
    uint256 totalCollateral,
    uint256 totalDebt,
    uint256 liquidationThreshold
  ) internal pure returns (uint256) {
    if (totalDebt == 0) return type(uint256).max;

    return (totalCollateral.percentMul(liquidationThreshold)).wadDiv(totalDebt);
  }

  /**
   * @dev Calculates the equivalent amount that an user can borrow, depending on the available collateral and the
   * average Loan To Value
   * @param totalCollateral The total collateral
   * @param totalDebt The total borrow balance
   * @param ltv The average loan to value
   * @return the amount available to borrow for the user
   **/

  function calculateAvailableBorrows(
    uint256 totalCollateral,
    uint256 totalDebt,
    uint256 ltv
  ) internal pure returns (uint256) {
    uint256 availableBorrows = totalCollateral.percentMul(ltv);

    if (availableBorrows < totalDebt) {
      return 0;
    }

    availableBorrows = availableBorrows - totalDebt;
    return availableBorrows;
  }

  struct CalcLiquidatePriceLocalVars {
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 nftPriceInETH;
    uint256 nftPriceInReserve;
    uint256 reserveDecimals;
    uint256 reservePriceInETH;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 borrowAmount;
  }

  /**
   * @dev Calculates the loan liquidation price
   * @param loanId the loan Id
   * @param reserveAsset The underlying asset of the reserve
   * @param reserveData the reserve data
   * @param nftAsset the underlying NFT asset
   * @param nftTokenId the NFT token Id
   * @param nftConfig The NFT data
   * @param poolLoan The pool loan address
   * @param reserveOracle The price oracle address of reserve
   * @param nftOracle The price oracle address of nft
   * @return The borrow amount, threshold price and liquidation price
   **/
  function calculateLoanLiquidatePrice(
    uint256 loanId,
    address reserveAsset,
    DataTypes.ReserveData storage reserveData,
    address nftAsset,
    uint256 nftTokenId,
    DataTypes.NftConfigurationMap storage nftConfig,
    address poolLoan,
    address reserveOracle,
    address nftOracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    CalcLiquidatePriceLocalVars memory vars;

    /*
     * 0                   CR                  LH                  100
     * |___________________|___________________|___________________|
     *  <       Borrowing with Interest        <
     * CR: Callteral Ratio;
     * LH: Liquidate Threshold;
     * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
     * Liquidate Price: (100% - BonusRatio) * NFT Price;
     */

    vars.reserveDecimals = reserveData.configuration.getDecimals();

    (, vars.borrowAmount) = ILendPoolLoan(poolLoan).getLoanReserveBorrowAmount(loanId);

    (vars.ltv, vars.liquidationThreshold, vars.liquidationBonus) = nftConfig.getCollateralParams();

    vars.nftPriceInETH = INFTOracleGetter(nftOracle).getNFTPrice(nftAsset, nftTokenId);
    vars.reservePriceInETH = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAsset);

    vars.nftPriceInReserve = ((10**vars.reserveDecimals) * vars.nftPriceInETH) / vars.reservePriceInETH;

    vars.thresholdPrice = vars.nftPriceInReserve.percentMul(vars.liquidationThreshold);

    vars.liquidatePrice = vars.nftPriceInReserve.percentMul(PercentageMath.PERCENTAGE_FACTOR - vars.liquidationBonus);

    return (vars.borrowAmount, vars.thresholdPrice, vars.liquidatePrice);
  }

  struct CalcLoanBidFineLocalVars {
    uint256 reserveDecimals;
    uint256 reservePriceInETH;
    uint256 baseBidFineInReserve;
    uint256 minBidFinePct;
    uint256 minBidFineInReserve;
    uint256 bidFineInReserve;
    uint256 debtAmount;
  }

  function calculateLoanBidFine(
    address reserveAsset,
    DataTypes.ReserveData storage reserveData,
    address nftAsset,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    address poolLoan,
    address reserveOracle
  ) internal view returns (uint256, uint256) {
    nftAsset;

    if (loanData.bidPrice == 0) {
      return (0, 0);
    }

    CalcLoanBidFineLocalVars memory vars;

    vars.reserveDecimals = reserveData.configuration.getDecimals();
    vars.reservePriceInETH = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAsset);
    vars.baseBidFineInReserve = (1 ether * 10**vars.reserveDecimals) / vars.reservePriceInETH;

    vars.minBidFinePct = nftConfig.getMinBidFine();
    vars.minBidFineInReserve = vars.baseBidFineInReserve.percentMul(vars.minBidFinePct);

    (, vars.debtAmount) = ILendPoolLoan(poolLoan).getLoanReserveBorrowAmount(loanData.loanId);

    vars.bidFineInReserve = vars.debtAmount.percentMul(nftConfig.getRedeemFine());
    if (vars.bidFineInReserve < vars.minBidFineInReserve) {
      vars.bidFineInReserve = vars.minBidFineInReserve;
    }

    return (vars.minBidFineInReserve, vars.bidFineInReserve);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUToken} from "../../interfaces/IUToken.sol";
import {IDebtToken} from "../../interfaces/IDebtToken.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";
import {ILSSVMPair} from "../../interfaces/sudoswap/ILSSVMPair.sol";

import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import {NFTXSeller} from "../markets/NFTXSeller.sol";

/**
 * @title LiquidateLogic library
 * @author Unlockd
 * @notice Implements the logic to liquidate feature
 */
library LiquidateLogic {
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  struct AuctionLocalVars {
    address loanAddress;
    address reserveOracle;
    address nftOracle;
    address initiator;
    uint256 loanId;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 borrowAmount;
    uint256 auctionEndTimestamp;
    uint256 minBidDelta;
    uint256 extraAuctionDuration;
  }

  /**
   * @notice Implements the auction feature. Through `auction()`, users auction assets in the protocol.
   * @dev Emits the `Auction()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param poolStates The state of the lend pool
   * @param params The additional parameters needed to execute the auction function
   */
  function executeAuction(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    mapping(address => mapping(uint8 => bool)) storage isMarketSupported,
    mapping(address => address[2]) storage sudoswapPairs,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteAuctionParams memory params
  ) external {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    AuctionLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.loanAddress = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();

    vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.loanAddress).getLoan(vars.loanId);

    //Initiator can not bid for same onBehalfOf address, as the new auction would be the same as the currently existing auction
    //created by them previously. Nevertheless, it is possible for the initiator to bid for a different `onBehalfOf` address,
    //as the new bidderAddress will be different.
    require(params.onBehalfOf != loanData.bidderAddress, Errors.LP_CONSECUTIVE_BIDS_NOT_ALLOWED);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];

    ValidationLogic.validateAuction(reserveData, nftData, nftConfig, loanData, params.bidPrice);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, vars.thresholdPrice, vars.liquidatePrice) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.loanAddress,
      vars.reserveOracle,
      vars.nftOracle
    );

    uint256 maxPrice = vars.borrowAmount;

    // Check if collection is supported by NFTX market
    if (isMarketSupported[loanData.nftAsset][0]) {
      uint256 priceNFTX = NFTXSeller.getNFTXPrice(
        addressesProvider,
        loanData.nftAsset,
        loanData.nftTokenId,
        loanData.reserveAsset
      );
      if (priceNFTX > maxPrice) {
        maxPrice = priceNFTX;
      }
    }

    // Check if collection is supported by SudoSwap market
    if (isMarketSupported[loanData.nftAsset][1]) {
      address[2] memory pairs = sudoswapPairs[loanData.nftAsset];
      for (uint256 i = 0; i < 2; ) {
        (, uint256 newSpotPrice, , , ) = ILSSVMPair(pairs[i]).getBuyNFTQuote(1);
        if (newSpotPrice > maxPrice) {
          maxPrice = newSpotPrice;
        }
        unchecked {
          ++i;
        }
      }
    } 

    // first time bid need to burn debt tokens and transfer reserve to uTokens
    if (loanData.state == DataTypes.LoanState.Active) {
      // loan's accumulated debt must exceed threshold (heath factor below 1.0)
      require(vars.borrowAmount > vars.thresholdPrice, Errors.LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD);

      // bid price must greater than liquidate price
      require(params.bidPrice >= vars.liquidatePrice, Errors.LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE);

      // bid price must greater than biggest between borrow and markets price, as well as a timestamp configuration fee
      require(
        params.bidPrice >= (maxPrice + params.auctionDurationConfigFee),
        Errors.LPL_BID_PRICE_LESS_THAN_MIN_BID_REQUIRED
      ); 
    } else {
      // bid price must greater than borrow debt
      require(params.bidPrice >= vars.borrowAmount, Errors.LPL_BID_PRICE_LESS_THAN_BORROW);

      if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
        vars.extraAuctionDuration = poolStates.pauseDurationTime;
      }
      vars.auctionEndTimestamp =
        loanData.bidStartTimestamp +
        vars.extraAuctionDuration +
        (nftConfig.getAuctionDuration() * 1 minutes);
      require(block.timestamp <= vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_HAS_END);

      // bid price must greater than highest bid + delta
      vars.minBidDelta = vars.borrowAmount.percentMul(PercentageMath.ONE_PERCENT);
      require(params.bidPrice >= (loanData.bidPrice + vars.minBidDelta), Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
    }

    ILendPoolLoan(vars.loanAddress).auctionLoan(
      vars.initiator,
      vars.loanId,
      params.onBehalfOf,
      params.bidPrice,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // lock highest bidder bid price amount to lend pool
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), params.bidPrice);

    // transfer (return back) last bid price amount to previous bidder from lend pool
    if (loanData.bidderAddress != address(0)) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);
    }

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, 0, 0);

    emit Auction(
      vars.initiator,
      loanData.reserveAsset,
      params.bidPrice,
      params.nftAsset,
      params.nftTokenId,
      params.onBehalfOf,
      loanData.borrower,
      vars.loanId
    );
  }

  struct RedeemLocalVars {
    address initiator;
    address poolLoan;
    address reserveOracle;
    address nftOracle;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 minRepayAmount;
    uint256 maxRepayAmount;
    uint256 bidFine;
    uint256 redeemEndTimestamp;
    uint256 minBidFinePct;
    uint256 minBidFine;
    uint256 extraRedeemDuration;
  }

  /**
   * @notice Implements the redeem feature. Through `redeem()`, users redeem assets in the protocol.
   * @dev Emits the `Redeem()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param poolStates The state of the lend pool
   * @param params The additional parameters needed to execute the redeem function
   */
  function executeRedeem(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteRedeemParams memory params
  ) external returns (uint256) {
    RedeemLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    ValidationLogic.validateRedeem(reserveData, nftData, nftConfig, loanData, params.amount);

    if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
      vars.extraRedeemDuration = poolStates.pauseDurationTime;
    }
    vars.redeemEndTimestamp = (loanData.bidStartTimestamp +
      vars.extraRedeemDuration +
      nftConfig.getRedeemDuration() *
      1 minutes);
    require(block.timestamp <= vars.redeemEndTimestamp, Errors.LPL_BID_REDEEM_DURATION_HAS_END);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    );

    // check bid fine in min & max range
    (, vars.bidFine) = GenericLogic.calculateLoanBidFine(
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftConfig,
      loanData,
      vars.poolLoan,
      vars.reserveOracle
    );

    // check bid fine is enough
    require(vars.bidFine <= params.bidFine, Errors.LPL_INVALID_BID_FINE);

    // check the minimum debt repay amount, use redeem threshold in config
    vars.repayAmount = params.amount;
    vars.minRepayAmount = vars.borrowAmount.percentMul(nftConfig.getRedeemThreshold());
    require(vars.repayAmount >= vars.minRepayAmount, Errors.LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD);

    // check the maxinmum debt repay amount, 90%?
    vars.maxRepayAmount = vars.borrowAmount.percentMul(PercentageMath.PERCENTAGE_FACTOR - PercentageMath.TEN_PERCENT);
    require(vars.repayAmount <= vars.maxRepayAmount, Errors.LP_AMOUNT_GREATER_THAN_MAX_REPAY);

    ILendPoolLoan(vars.poolLoan).redeemLoan(
      vars.initiator,
      vars.loanId,
      vars.repayAmount,
      reserveData.variableBorrowIndex
    );

    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, vars.repayAmount, 0);

    // transfer repay amount from borrower to uToken
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
      vars.initiator,
      reserveData.uTokenAddress,
      vars.repayAmount
    );

    if (loanData.bidderAddress != address(0)) {
      // transfer (return back) last bid price amount from lend pool to bidder
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);

      // transfer bid penalty fine amount from borrower to the first bidder
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
        vars.initiator,
        loanData.firstBidderAddress,
        vars.bidFine
      );
    }

    emit Redeem(
      vars.initiator,
      loanData.reserveAsset,
      vars.repayAmount,
      vars.bidFine,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.repayAmount + vars.bidFine);
  }

  struct LiquidateLocalVars {
    address initiator;
    address poolLoan;
    address reserveOracle;
    address nftOracle;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 extraDebtAmount;
    uint256 remainAmount;
    uint256 auctionEndTimestamp;
    uint256 extraAuctionDuration;
  }

  /**
   * @notice Implements the liquidate feature. Through `liquidate()`, users liquidate assets in the protocol.
   * @dev Emits the `Liquidate()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param nftsConfig The state of the nft by tokenId
   * @param poolStates The state of the lend pool
   * @param params The additional parameters needed to execute the liquidate function
   */
  function executeLiquidate(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteLiquidateParams memory params
  ) external returns (uint256) {
    LiquidateLocalVars memory vars;
    vars.initiator = params.initiator;

    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    ValidationLogic.validateLiquidate(reserveData, nftData, nftConfig, loanData);

    // If pool paused after bidding start, add pool pausing time as extra auction duration
    if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
      vars.extraAuctionDuration = poolStates.pauseDurationTime;
    }
    vars.auctionEndTimestamp =
      loanData.bidStartTimestamp +
      vars.extraAuctionDuration +
      (nftConfig.getAuctionDuration() * 1 minutes);
    require(block.timestamp > vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_NOT_END);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    );

    // Last bid price can not cover borrow amount
    if (loanData.bidPrice < vars.borrowAmount) {
      vars.extraDebtAmount = vars.borrowAmount - loanData.bidPrice;
      require(params.amount >= vars.extraDebtAmount, Errors.LP_AMOUNT_LESS_THAN_EXTRA_DEBT);
    }

    if (loanData.bidPrice > vars.borrowAmount) {
      vars.remainAmount = loanData.bidPrice - vars.borrowAmount;
    }

    ILendPoolLoan(vars.poolLoan).liquidateLoan(
      loanData.bidderAddress,
      vars.loanId,
      nftData.uNftAddress,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    IDebtToken(reserveData.debtTokenAddress).burn(
      loanData.borrower,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, vars.borrowAmount, 0);

    // transfer extra borrow amount from liquidator to lend pool
    if (vars.extraDebtAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), vars.extraDebtAmount);
    }

    // transfer borrow amount from lend pool to uToken, repay debt
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(reserveData.uTokenAddress, vars.borrowAmount);

    // transfer remain amount to borrower
    if (vars.remainAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
    }

    // transfer erc721 to bidder.
    //avoid DoS by transferring NFT to a malicious contract that reverts on ERC721 receive
    (bool success, ) = address(loanData.nftAsset).call(
      abi.encodeWithSignature(
        "safeTransferFrom(address,address,uint256)",
        address(this),
        loanData.bidderAddress,
        params.nftTokenId
      )
    );
    //If transfer was made to a malicious contract, send NFT to treasury
    if (!success)
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(
        address(this),
        IUToken(reserveData.uTokenAddress).RESERVE_TREASURY_ADDRESS(),
        params.nftTokenId
      );

    emit Liquidate(
      vars.initiator,
      loanData.reserveAsset,
      vars.borrowAmount,
      vars.remainAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.extraDebtAmount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUToken} from "../../interfaces/IUToken.sol";
import {IDebtToken} from "../../interfaces/IDebtToken.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";

import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title LiquidateLogic library
 * @author Unlockd
 * @notice Implements the logic to liquidate feature
 */
library LiquidateMarketsLogic {
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Emitted when a borrower's loan is liquidated on NFTX.
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event LiquidateNFTX(
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated on Sudoswap.
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event LiquidateSudoSwap(
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  struct LiquidateMarketsLocalVars {
    address poolLoan;
    address reserveOracle;
    address nftOracle;
    address liquidator;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 extraDebtAmount;
    uint256 remainAmount;
    uint256 feeAmount;
    uint256 auctionEndTimestamp;
    uint256 extraAuctionDuration;
    address WETH;
  }

  /**
   * @notice Implements the liquidate feature on NFTX. Through `liquidateNFTX()`, users liquidate assets in the protocol.
   * @dev Emits the `LiquidateNFTX()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the liquidate function
   */
  function executeLiquidateNFTX(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    mapping(address => mapping(uint8 => bool)) storage isMarketSupported,
    DataTypes.ExecuteLiquidateMarketsParams memory params
  ) external returns (uint256) {
    LiquidateMarketsLocalVars memory vars;

    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();
    vars.liquidator = addressesProvider.getLendPoolLiquidator();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    // Check NFT is allowed to be sold on NFTX market
    ValidationLogic.validateLiquidateMarkets(reserveData, nftData, nftConfig, loanData);
    require(isMarketSupported[loanData.nftAsset][0], Errors.LP_NFT_NOT_ALLOWED_TO_SELL);

    // Check for health factor
    (, , uint256 healthFactor) = GenericLogic.calculateLoanData(
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.loanId,
      vars.reserveOracle,
      vars.nftOracle
    );

    //Loan must be unhealthy in order to get liquidated
    require(
      healthFactor <= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    );

    uint256 priceNFTX = ILendPoolLoan(vars.poolLoan).liquidateLoanNFTX(
      vars.loanId,
      nftData.uNftAddress,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // Liquidation Fee
    vars.feeAmount = priceNFTX.percentMul(params.liquidateFeePercentage);
    priceNFTX = priceNFTX - vars.feeAmount;

    // Remaining Amount
    if (priceNFTX > vars.borrowAmount) {
      vars.remainAmount = priceNFTX - vars.borrowAmount;
    }

    // Extra Debt Amount
    if (priceNFTX < vars.borrowAmount) {
      vars.extraDebtAmount = vars.borrowAmount - priceNFTX;
    }

    IDebtToken(reserveData.debtTokenAddress).burn(
      loanData.borrower,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, vars.borrowAmount, 0);

    // NFTX selling price was lower than borrow amount. Treasury must cover the loss
    if (vars.extraDebtAmount > 0) {
      address treasury = IUToken(reserveData.uTokenAddress).RESERVE_TREASURY_ADDRESS();
      require(
        IERC20Upgradeable(loanData.reserveAsset).balanceOf(treasury) > vars.extraDebtAmount,
        Errors.VL_VALUE_EXCEED_TREASURY_BALANCE
      );
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(treasury, address(this), vars.extraDebtAmount);
    }

    // transfer borrow amount from lend pool to uToken, repay debt
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(reserveData.uTokenAddress, vars.borrowAmount);

    // transfer fee amount from lend pool to liquidator
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(vars.liquidator, vars.feeAmount);

    // transfer remain amount to borrower
    if (vars.remainAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
    }

    emit LiquidateNFTX(
      loanData.reserveAsset,
      vars.borrowAmount,
      vars.remainAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.remainAmount);
  }

  /**
   * @notice Implements the liquidate feature on SudoSwap. Through `liquidateSudoSwap()`, users liquidate assets in the protocol.
   * @dev Emits the `LiquidateSudoSwap()` event.
   * @param reservesData The state of all the reserves
   * @param nftsData The state of all the nfts
   * @param params The additional parameters needed to execute the liquidate function
   */
  function executeLiquidateSudoSwap(
    ILendPoolAddressesProvider addressesProvider,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(address => DataTypes.NftData) storage nftsData,
    mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) storage nftsConfig,
    mapping(address => mapping(uint8 => bool)) storage isMarketSupported,
    DataTypes.ExecuteLendPoolStates memory poolStates,
    DataTypes.ExecuteLiquidateMarketsParams memory params
  ) external returns (uint256) {
    LiquidateMarketsLocalVars memory vars;

    vars.poolLoan = addressesProvider.getLendPoolLoan();
    vars.reserveOracle = addressesProvider.getReserveOracle();
    vars.nftOracle = addressesProvider.getNFTOracle();
    vars.liquidator = addressesProvider.getLendPoolLiquidator();
    vars.WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    //addressesProvider.getWETHAddress();

    address sushiSwapRouterAddress = addressesProvider.getSushiSwapRouter();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(params.nftAsset, params.nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);
  
    DataTypes.ReserveData storage reserveData = reservesData[loanData.reserveAsset];
    DataTypes.NftData storage nftData = nftsData[loanData.nftAsset];
    DataTypes.NftConfigurationMap storage nftConfig = nftsConfig[loanData.nftAsset][loanData.nftTokenId];

    ValidationLogic.validateLiquidateMarkets(reserveData, nftData, nftConfig, loanData);
 
    if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
      vars.extraAuctionDuration = poolStates.pauseDurationTime;
    }
    vars.auctionEndTimestamp =
      loanData.bidStartTimestamp +
      vars.extraAuctionDuration +
      (nftConfig.getAuctionDuration() * 1 minutes);
    require(block.timestamp > vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_NOT_END);

    // Check NFT is allowed to be sold on SudoSwap market
    require(isMarketSupported[loanData.nftAsset][1], Errors.LP_NFT_NOT_ALLOWED_TO_SELL);
  
    // Check for health factor
    (, , uint256 healthFactor) = GenericLogic.calculateLoanData(
      loanData.reserveAsset,
      reserveData, 
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.loanId,
      vars.reserveOracle,
      vars.nftOracle
    );

    //Loan must be unhealthy in order to get liquidated
    require(
      healthFactor <= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState(); 

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice( 
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      vars.reserveOracle,
      vars.nftOracle
    ); 

    uint256 priceSudoSwap = ILendPoolLoan(vars.poolLoan).liquidateLoanSudoSwap(
      vars.loanId,
      nftData.uNftAddress,
      vars.borrowAmount,
      reserveData.variableBorrowIndex,
      params.LSSVMPair
    ); 

    if (loanData.reserveAsset == vars.WETH) {
      IWETH(vars.WETH).deposit{value: priceSudoSwap}();
    } else {
      address[] memory swapPath = new address[](2);
      swapPath[0] = vars.WETH;
      swapPath[1] = loanData.reserveAsset;

      uint256[] memory amounts = IUniswapV2Router02(sushiSwapRouterAddress).swapExactETHForTokens{value: priceSudoSwap}(
        0,
        swapPath,
        address(this),
        block.timestamp
      );
      priceSudoSwap = amounts[1];
    }

    // Liquidation Fee
    vars.feeAmount = priceSudoSwap.percentMul(params.liquidateFeePercentage);
    priceSudoSwap = priceSudoSwap - vars.feeAmount;

    // Remaining Amount
    if (priceSudoSwap > vars.borrowAmount) {
      vars.remainAmount = priceSudoSwap - vars.borrowAmount;
    }

    // Extra Debt Amount
    if (priceSudoSwap < vars.borrowAmount) {
      vars.extraDebtAmount = vars.borrowAmount - priceSudoSwap;
    }

    IDebtToken(reserveData.debtTokenAddress).burn(
      loanData.borrower,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );
    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.uTokenAddress, vars.borrowAmount, 0);

    // SudoSwap selling price was lower than borrow amount. Treasury must cover the loss
    if (vars.extraDebtAmount > 0) {
      address treasury = IUToken(reserveData.uTokenAddress).RESERVE_TREASURY_ADDRESS();
      require(
        IERC20Upgradeable(loanData.reserveAsset).balanceOf(treasury) > vars.extraDebtAmount,
        Errors.VL_VALUE_EXCEED_TREASURY_BALANCE
      );
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(treasury, address(this), vars.extraDebtAmount);
    }

    // transfer borrow amount from lend pool to uToken, repay debt
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(reserveData.uTokenAddress, vars.borrowAmount);

    // transfer fee amount from lend pool to liquidator
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(vars.liquidator, vars.feeAmount);

    // transfer remain amount to borrower
    if (vars.remainAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
    }

    emit LiquidateSudoSwap(
      loanData.reserveAsset,
      vars.borrowAmount,
      vars.remainAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.remainAmount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title NftLogic library
 * @author Unlockd
 * @notice Implements the logic to update the nft state
 */
library NftLogic {
  /**
   * @dev Initializes a nft
   * @param nft The nft object
   * @param uNftAddress The address of the uNFT contract
   **/
  function init(DataTypes.NftData storage nft, address uNftAddress) external {
    require(nft.uNftAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

    nft.uNftAddress = uNftAddress;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUToken} from "../../interfaces/IUToken.sol";
import {IDebtToken} from "../../interfaces/IDebtToken.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ReserveLogic library
 * @author Unlockd
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev Emitted when the state of a reserve is updated
   * @param asset The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed asset,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @dev Returns the ongoing normalized income for the reserve
   * A value of 1e27 means there is no income. As time passes, the income is accrued
   * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return the normalized income. expressed in ray
   **/
  function getNormalizedIncome(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    }

    uint256 cumulated = MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
      reserve.liquidityIndex
    );

    return cumulated;
  }

  /**
   * @dev Returns the ongoing normalized variable debt for the reserve
   * A value of 1e27 means there is no debt. As time passes, the income is accrued
   * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt. expressed in ray
   **/
  function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    }

    uint256 cumulated = MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
      reserve.variableBorrowIndex
    );

    return cumulated;
  }

  /**
   * @dev Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve the reserve object
   **/
  function updateState(DataTypes.ReserveData storage reserve) internal {
    uint256 scaledVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledTotalSupply();
    uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
    uint256 previousLiquidityIndex = reserve.liquidityIndex;
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

    (uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) = _updateIndexes(
      reserve,
      scaledVariableDebt,
      previousLiquidityIndex,
      previousVariableBorrowIndex,
      lastUpdatedTimestamp
    );

    _mintToTreasury(
      reserve,
      scaledVariableDebt,
      previousVariableBorrowIndex,
      newLiquidityIndex,
      newVariableBorrowIndex,
      lastUpdatedTimestamp
    );
  }

  /**
   * @dev Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income.
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accomulate
   **/
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal {
    uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(totalLiquidity.wadToRay());

    uint256 result = amountToLiquidityRatio + (WadRayMath.ray());

    result = result.rayMul(reserve.liquidityIndex);
    require(result <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

    reserve.liquidityIndex = uint128(result);
  }

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param uTokenAddress The address of the overlying uToken contract
   * @param debtTokenAddress The address of the overlying debtToken contract
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address uTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external {
    require(reserve.uTokenAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

    reserve.liquidityIndex = uint128(WadRayMath.ray());
    reserve.variableBorrowIndex = uint128(WadRayMath.ray());
    reserve.uTokenAddress = uTokenAddress;
    reserve.debtTokenAddress = debtTokenAddress;
    reserve.interestRateAddress = interestRateAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 newLiquidityRate;
    uint256 newVariableRate;
    uint256 totalVariableDebt;
  }

  /**
   * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
   * @param reserve The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (withdraw or borrow)
   **/
  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    address reserveAddress,
    address uTokenAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    //calculates the total variable debt locally using the scaled borrow amount instead
    //of borrow amount(), as it's noticeably cheaper. Also, the index has been
    //updated by the previous updateState() call
    vars.totalVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledTotalSupply().rayMul(
      reserve.variableBorrowIndex
    );

    (vars.newLiquidityRate, vars.newVariableRate) = IInterestRate(reserve.interestRateAddress).calculateInterestRates(
      reserveAddress,
      uTokenAddress,
      liquidityAdded,
      liquidityTaken,
      vars.totalVariableDebt,
      reserve.configuration.getReserveFactor()
    );
    require(vars.newLiquidityRate <= type(uint128).max, Errors.RL_LIQUIDITY_RATE_OVERFLOW);
    require(vars.newVariableRate <= type(uint128).max, Errors.RL_VARIABLE_BORROW_RATE_OVERFLOW);

    reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
    reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

    emit ReserveDataUpdated(
      reserveAddress,
      vars.newLiquidityRate,
      vars.newVariableRate,
      reserve.liquidityIndex,
      reserve.variableBorrowIndex
    );
  }

  struct MintToTreasuryLocalVars {
    uint256 currentVariableDebt;
    uint256 previousVariableDebt;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
    uint256 reserveFactor;
  }

  /**
   * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
   * specific asset.
   * @param reserve The reserve reserve to be updated
   * @param scaledVariableDebt The current scaled total variable debt
   * @param previousVariableBorrowIndex The variable borrow index before the last accumulation of the interest
   * @param newLiquidityIndex The new liquidity index
   * @param newVariableBorrowIndex The variable borrow index after the last accumulation of the interest
   **/
  function _mintToTreasury(
    DataTypes.ReserveData storage reserve,
    uint256 scaledVariableDebt,
    uint256 previousVariableBorrowIndex,
    uint256 newLiquidityIndex,
    uint256 newVariableBorrowIndex,
    uint40 timestamp
  ) internal {
    timestamp;
    MintToTreasuryLocalVars memory vars;

    vars.reserveFactor = reserve.configuration.getReserveFactor();

    if (vars.reserveFactor == 0) {
      return;
    }

    //calculate the last principal variable debt
    vars.previousVariableDebt = scaledVariableDebt.rayMul(previousVariableBorrowIndex);

    //calculate the new total supply after accumulation of the index
    vars.currentVariableDebt = scaledVariableDebt.rayMul(newVariableBorrowIndex);

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued = vars.currentVariableDebt - (vars.previousVariableDebt);

    vars.amountToMint = vars.totalDebtAccrued.percentMul(vars.reserveFactor);

    if (vars.amountToMint != 0) {
      IUToken(reserve.uTokenAddress).mintToTreasury(vars.amountToMint, newLiquidityIndex);
    }
  }

  /**
   * @dev Updates the reserve indexes and the timestamp of the update
   * @param reserve The reserve reserve to be updated
   * @param scaledVariableDebt The scaled variable debt
   * @param liquidityIndex The last stored liquidity index
   * @param variableBorrowIndex The last stored variable borrow index
   **/
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    uint256 scaledVariableDebt,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex,
    uint40 timestamp
  ) internal returns (uint256, uint256) {
    uint256 currentLiquidityRate = reserve.currentLiquidityRate;

    uint256 newLiquidityIndex = liquidityIndex;
    uint256 newVariableBorrowIndex = variableBorrowIndex;

    //only cumulating if there is any income being produced
    if (currentLiquidityRate > 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
      newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);
      require(newLiquidityIndex <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

      reserve.liquidityIndex = uint128(newLiquidityIndex);

      //as the liquidity rate might come only from stable rate loans, we need to ensure
      //that there is actual variable debt before accumulating
      if (scaledVariableDebt != 0) {
        uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
          reserve.currentVariableBorrowRate,
          timestamp
        );
        newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(variableBorrowIndex);
        require(newVariableBorrowIndex <= type(uint128).max, Errors.RL_VARIABLE_BORROW_INDEX_OVERFLOW);
        reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
      }
    }

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
    return (newLiquidityIndex, newVariableBorrowIndex);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUToken} from "../../interfaces/IUToken.sol";

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {ReserveLogic} from "./ReserveLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

/**
 * @title SupplyLogic library
 * @author Unlockd
 * @notice Implements the logic to supply feature
 */
library SupplyLogic {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;

  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the uTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of uTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(address indexed user, address indexed reserve, uint256 amount, address indexed to);

  /**
   * @notice Implements the supply feature. Through `deposit()`, users deposit assets to the protocol.
   * @dev Emits the `Deposit()` event.
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the deposit function
   */
  function executeDeposit(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteDepositParams memory params
  ) external {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    address uToken = reserve.uTokenAddress;
    require(uToken != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    ValidationLogic.validateDeposit(reserve, params.amount);

    reserve.updateState();
    reserve.updateInterestRates(params.asset, uToken, params.amount, 0);

    IERC20Upgradeable(params.asset).safeTransferFrom(params.initiator, uToken, params.amount);

    IUToken(uToken).mint(params.onBehalfOf, params.amount, reserve.liquidityIndex);

    emit Deposit(params.initiator, params.asset, params.amount, params.onBehalfOf, params.referralCode);
  }

  /**
   * @notice Implements the withdraw feature. Through `withdraw()`, users withdraw assets from the protocol.
   * @dev Emits the `Withdraw()` event.
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the withdraw function
   */
  function executeWithdraw(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteWithdrawParams memory params
  ) external returns (uint256) {
    require(params.to != address(0), Errors.VL_INVALID_TARGET_ADDRESS);

    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    address uToken = reserve.uTokenAddress;
    require(uToken != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    uint256 userBalance = IUToken(uToken).balanceOf(params.initiator);

    uint256 amountToWithdraw = params.amount;

    if (params.amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(reserve, amountToWithdraw, userBalance);

    reserve.updateState();

    reserve.updateInterestRates(params.asset, uToken, 0, amountToWithdraw);

    IUToken(uToken).burn(params.initiator, params.to, amountToWithdraw, reserve.liquidityIndex);

    emit Withdraw(params.initiator, params.asset, amountToWithdraw, params.to);

    return amountToWithdraw;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../../interfaces/ILendPool.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ValidationLogic library
 * @author Unlockd
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Validates a deposit action
   * @param reserve The reserve object on which the user is depositing
   * @param amount The amount to be deposited
   */
  function validateDeposit(DataTypes.ReserveData storage reserve, uint256 amount) external view {
    (bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);
  }

  /**
   * @dev Validates a withdraw action
   * @param reserveData The reserve state
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   */
  function validateWithdraw(
    DataTypes.ReserveData storage reserveData,
    uint256 amount,
    uint256 userBalance
  ) external view {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , ) = reserveData.configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
  }

  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 currentLiquidationThreshold;
    uint256 amountOfCollateralNeeded;
    uint256 userCollateralBalance;
    uint256 userBorrowBalance;
    uint256 availableLiquidity;
    uint256 healthFactor;
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
    bool stableRateBorrowingEnabled;
    bool nftIsActive;
    bool nftIsFrozen;
    address loanReserveAsset;
    address loanBorrower;
  }

  /**
   * @dev Validates a borrow action
   * @param reserveData The reserve state from which the user is borrowing
   * @param nftData The state of the user for the specific nft
   */
  function validateBorrow(
    DataTypes.ExecuteBorrowParams memory params,
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    address loanAddress,
    uint256 loanId,
    address reserveOracle,
    address nftOracle
  ) external view {
    ValidateBorrowLocalVars memory vars;
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(params.amount > 0, Errors.VL_INVALID_AMOUNT);

    if (loanId != 0) {
      DataTypes.LoanData memory loanData = ILendPoolLoan(loanAddress).getLoan(loanId);

      require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
      require(params.asset == loanData.reserveAsset, Errors.VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER);
      require(params.onBehalfOf == loanData.borrower, Errors.VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER);
    }

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.stableRateBorrowingEnabled) = reserveData
      .configuration
      .getFlags();
    require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
    require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);
    (vars.nftIsActive, vars.nftIsFrozen) = nftData.configuration.getFlags();
    require(vars.nftIsActive, Errors.VL_NO_ACTIVE_NFT);
    require(!vars.nftIsFrozen, Errors.VL_NFT_FROZEN);

    /**
     * @dev additional check for individual asset
     */
    (vars.nftIsActive, vars.nftIsFrozen) = nftConfig.getFlags();
    require(vars.nftIsActive, Errors.VL_NO_ACTIVE_NFT);
    require(!vars.nftIsFrozen, Errors.VL_NFT_FROZEN);

    require(
      (nftConfig.getConfigTimestamp() + ILendPool(address(this)).getTimeframe()) >= block.timestamp,
      Errors.VL_TIMEFRAME_EXCEEDED
    );

    (vars.currentLtv, vars.currentLiquidationThreshold, ) = nftConfig.getCollateralParams();

    (vars.userCollateralBalance, vars.userBorrowBalance, vars.healthFactor) = GenericLogic.calculateLoanData(
      params.asset,
      reserveData,
      params.nftAsset,
      params.nftTokenId,
      nftConfig,
      loanAddress,
      loanId,
      reserveOracle,
      nftOracle
    );

    require(vars.userCollateralBalance > 0, Errors.VL_COLLATERAL_BALANCE_IS_0);
    require(
      vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    //LTV is calculated in percentage
    vars.amountOfCollateralNeeded = (vars.userBorrowBalance + params.amount).percentDiv(vars.currentLtv);

    require(vars.amountOfCollateralNeeded <= vars.userCollateralBalance, Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW);
  }

  /**
   * @dev Validates a repay action
   * @param reserveData The reserve state from which the user is repaying
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param borrowAmount The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    uint256 amountSent,
    uint256 borrowAmount
  ) external view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

    require(borrowAmount > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);

    require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
  }

  /**
   * @dev Validates the auction action
   * @param reserveData The reserve data of the principal
   * @param nftData The nft data of the underlying nft
   * @param bidPrice Total variable debt balance of the user
   **/
  function validateAuction(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    uint256 bidPrice
  ) internal view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(
      loanData.state == DataTypes.LoanState.Active || loanData.state == DataTypes.LoanState.Auction,
      Errors.LPL_INVALID_LOAN_STATE
    );

    require(bidPrice > 0, Errors.VL_INVALID_AMOUNT);
  }

  /**
   * @dev Validates a redeem action
   * @param reserveData The reserve state
   * @param nftData The nft state
   */
  function validateRedeem(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData,
    uint256 amount
  ) external view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(loanData.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    require(amount > 0, Errors.VL_INVALID_AMOUNT);
  }

  /**
   * @dev Validates the liquidation action
   * @param reserveData The reserve data of the principal
   * @param nftData The data of the underlying NFT
   * @param loanData The loan data of the underlying NFT
   **/
  function validateLiquidate(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData
  ) internal view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(loanData.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);
  }

  /**
   * @dev Validates the liquidation NFTX action
   * @param reserveData The reserve data of the principal
   * @param nftData The data of the underlying NFT
   * @param loanData The loan data of the underlying NFT
   **/
  function validateLiquidateMarkets(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.NftConfigurationMap storage nftConfig,
    DataTypes.LoanData memory loanData
  ) internal view {
    require(nftData.uNftAddress != address(0), Errors.LPC_INVALID_UNFT_ADDRESS);
    require(reserveData.uTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev additional check for individual asset
     */
    require(nftConfig.getActive(), Errors.VL_NO_ACTIVE_NFT);

    /**
     * @dev Loan requires to be in `Active` state. The Markets liquidate process is triggered if there has not been any auction
     * and the auction time has passed. In that case, loan is not in `Auction` nor `Defaulted`,  and needs to be liquidated in a third-party market.
     */
    require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
  }

  /**
   * @dev Validates an uToken transfer
   * @param from The user from which the uTokens are being transferred
   * @param reserveData The state of the reserve
   */
  function validateTransfer(address from, DataTypes.ReserveData storage reserveData) internal pure {
    from;
    reserveData;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {INFTXVaultFactoryV2} from "../../interfaces/nftx/INFTXVaultFactoryV2.sol";
import {INFTXVault} from "../../interfaces/nftx/INFTXVault.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

import {Errors} from "../../libraries/helpers/Errors.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title NFTXSeller library
 * @author Unlockd
 * @notice Implements NFTX selling logic
 */
library NFTXSeller {
  /**
   * @dev Sells an asset in an NFTX liquid market
   * @param addressesProvider The addresses provider
   * @param nftAsset The underlying NFT address
   * @param nftTokenId The underlying NFT token Id
   * @param reserveAsset The reserve asset to exchange for the NFT
   */
  function sellNFTX(
    ILendPoolAddressesProvider addressesProvider,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  ) internal returns (uint256) {
    address vaultFactoryAddress = addressesProvider.getNFTXVaultFactory();
    address sushiSwapRouterAddress = addressesProvider.getSushiSwapRouter();
    address lendPoolAddress = addressesProvider.getLendPool();
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    //addressesProvider.getWETHAddress();

    // Get NFTX Vaults for the asset
    address[] memory vaultAddresses = INFTXVaultFactoryV2(vaultFactoryAddress).vaultsForAsset(nftAsset);

    require(vaultAddresses.length > 0, Errors.NFTX_INVALID_VAULTS_LENGTH);

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = nftTokenId;

    //Always get the first vault address
    address vaultAddress = vaultAddresses[0];
    INFTXVault nftxVault = INFTXVault(vaultAddress);

    if (nftxVault.allValidNFTs(tokenIds)) {
      // Deposit NFT to NFTX Vault
      IERC721Upgradeable(nftAsset).approve(vaultAddress, nftTokenId);
      nftxVault.mint(tokenIds, new uint256[](1));
      uint256 depositAmount = IERC20Upgradeable(vaultAddress).balanceOf(address(this));

      // Swap on SushiSwap
      IERC20Upgradeable(vaultAddress).approve(sushiSwapRouterAddress, depositAmount);

      address[] memory swapPath;
      if (reserveAsset != address(WETH)) {
        swapPath = new address[](3);
        swapPath[2] = reserveAsset;
      } else {
        swapPath = new address[](2);
      }
      swapPath[0] = vaultAddress;
      swapPath[1] = WETH;

      uint256[] memory amounts = IUniswapV2Router02(sushiSwapRouterAddress).swapExactTokensForTokens(
        depositAmount,
        0,
        swapPath,
        lendPoolAddress,
        block.timestamp
      );

      return amounts[1];
    }

    revert("NFTX: vault not available");
  }

  /**
   * @dev Get the NFTX price in reserve asset
   * @param addressesProvider The addresses provider
   * @param nftAsset The underlying NFT address
   * @param nftTokenId The underlying NFT token Id
   * @param reserveAsset The ERC20 reserve asset
   */
  function getNFTXPrice(
    ILendPoolAddressesProvider addressesProvider,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  ) internal view returns (uint256) {
    address vaultFactoryAddress = addressesProvider.getNFTXVaultFactory();
    address sushiSwapRouterAddress = addressesProvider.getSushiSwapRouter();
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    //addressesProvider.getWETHAddress();

    // Get NFTX Vaults for the asset
    address[] memory vaultAddresses = INFTXVaultFactoryV2(vaultFactoryAddress).vaultsForAsset(nftAsset);

    require(vaultAddresses.length > 0, Errors.NFTX_INVALID_VAULTS_LENGTH);

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = nftTokenId;

    // Always get the first vault address
    address vaultAddress = vaultAddresses[0];
    INFTXVault nftxVault = INFTXVault(vaultAddress);
    (uint256 mintFee, , , , ) = INFTXVaultFactoryV2(vaultFactoryAddress).vaultFees(nftxVault.vaultId());

    if (nftxVault.allValidNFTs(tokenIds)) {
      address[] memory swapPath;
      if (reserveAsset != address(WETH)) {
        swapPath = new address[](3);
        swapPath[2] = reserveAsset;
      } else {
        swapPath = new address[](2);
      }
      swapPath[0] = vaultAddress;
      swapPath[1] = WETH;

      uint256 depositAmount = 1 ether - mintFee;

      uint256[] memory amounts = IUniswapV2Router02(sushiSwapRouterAddress).getAmountsOut(depositAmount, swapPath);

      if (amounts.length == 3) {
        return amounts[2];
      }
      return amounts[1];
    }

    revert("NFTX: vault not available");
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {ILSSVMRouter} from "../../interfaces/sudoswap/ILSSVMRouter.sol";
import {ILSSVMPair} from "../../interfaces/sudoswap/ILSSVMPair.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

/*
 * @title SudoSwap library
 * @author Unlockd
 * @notice Implements SudoSwap selling logic
 */
library SudoSwapSeller {
  struct PairSwapSpecific {
    ILSSVMPair pair;
    uint256[] nftIds;
  }

  bytes32 public constant ADDRESS_ID_LSSVM_ROUTER = 0xADDE000000000000000000000000000000000000000000000000000000000003;

  /**
   * @dev Sells an asset in a SudoSwap liquid market
   * @param addressesProvider The addresses provider
   * @param nftTokenId The underlying NFT token Id
   */
  function sellSudoSwap(
    ILendPoolAddressesProvider addressesProvider,
    address nftAsset,
    uint256 nftTokenId,
    address LSSVMPair
  ) internal returns (uint256 amount) { 
    
    address LSSVMRouterAddress = addressesProvider.getAddress(ADDRESS_ID_LSSVM_ROUTER);
    address lendPoolAddress = addressesProvider.getLendPool();
 
    ILSSVMRouter LSSVMRouter = ILSSVMRouter(LSSVMRouterAddress);

    uint256[] memory nftTokenIds = new uint256[](1);
    nftTokenIds[0] = nftTokenId;

    PairSwapSpecific[] memory pairSwaps = new PairSwapSpecific[](1);
    pairSwaps[0] = PairSwapSpecific({pair: ILSSVMPair(LSSVMPair), nftIds: nftTokenIds});

    IERC721Upgradeable(nftAsset).approve(LSSVMRouterAddress, nftTokenId);
    amount = LSSVMRouter.swapNFTsForToken(pairSwaps, 0, lendPoolAddress, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {WadRayMath} from "./WadRayMath.sol";

library MathUtils {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/

  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

    return ((rate * (timeDifference)) / SECONDS_PER_YEAR) + (WadRayMath.ray());
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - (uint256(lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * (expMinusOne) * (basePowerTwo)) / 2;
    uint256 thirdTerm = (exp * (expMinusOne) * (expMinusTwo) * (basePowerThree)) / 6;

    return WadRayMath.ray() + (ratePerSecond * (exp)) + (secondTerm) + (thirdTerm);
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Unlockd
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
  uint256 constant ONE_PERCENT = 1e2; //100, 1%
  uint256 constant TEN_PERCENT = 1e3; //1000, 10%
  uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
  uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(value <= (type(uint256).max - HALF_PERCENT) / percentage, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title WadRayMath library
 * @author Unlockd
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return HALF_RAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return HALF_WAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - HALF_WAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + HALF_WAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - HALF_RAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + HALF_RAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../helpers/Errors.sol";

contract UnlockdUpgradeableProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

  modifier OnlyAdmin() {
    require(msg.sender == _getAdmin(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
  @dev Returns the implementation contract for the proxy
   */
  function getImplementation() external view OnlyAdmin returns (address) {
    return _getImplementation();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address uTokenAddress;
    address debtTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NftData {
    //stores the nft configuration
    NftConfigurationMap configuration;
    //address of the uNFT contract
    address uNftAddress;
    //the id of the nft. Represents the position in the list of the active nfts
    uint8 id;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct NftConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 56: NFT is active
    //bit 57: NFT is frozen
    //bit 64-71: Redeem duration
    //bit 72-79: Auction duration
    //bit 80-95: Redeem fine
    //bit 96-111: Redeem threshold
    //bit 112-127: Min bid fine
    //bit 128-159: Timestamp Config
    uint256 data;
  }

  /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> Auction -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }

  struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the id of nft token
    uint256 nftTokenId;
    //address of reserve asset token
    address reserveAsset;
    //scaled borrow amount. Expressed in ray
    uint256 scaledAmount;
    //start time of first bid time
    uint256 bidStartTimestamp;
    //bidder address of higest bid
    address bidderAddress;
    //price of higest bid
    uint256 bidPrice;
    //borrow amount of loan
    uint256 bidBorrowAmount;
    //bidder address of first bid
    address firstBidderAddress;
  }

  struct ExecuteDepositParams {
    address initiator;
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteWithdrawParams {
    address initiator;
    address asset;
    uint256 amount;
    address to;
  }

  struct ExecuteBorrowParams {
    address initiator;
    address asset;
    uint256 amount;
    address nftAsset;
    uint256 nftTokenId;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteRepayParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteAuctionParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 bidPrice;
    address onBehalfOf;
    uint256 auctionDurationConfigFee;
  }

  struct ExecuteRedeemParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
    uint256 bidFine;
  }

  struct ExecuteLiquidateParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteLiquidateMarketsParams {
    address nftAsset;
    uint256 nftTokenId;
    uint256 liquidateFeePercentage;
    address LSSVMPair;
  }

  struct ExecuteLendPoolStates {
    uint256 pauseStartTime;
    uint256 pauseDurationTime;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../protocol/LendPool.sol";

contract MockLendPoolVersionN is LendPool {
  uint256 public dummy1;
  uint256 public dummy2;

  function initializeVersionN(uint256 dummy1_, uint256 dummy2_) external initializer {
    dummy1 = dummy1_;
    dummy2 = dummy2_;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUNFT} from "../../interfaces/IUNFT.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

/**
 * @title UNFT contract
 * @dev Implements the methods for the uNFT protocol
 **/
contract UNFT is ERC721EnumerableUpgradeable, IUNFT {
  address private _underlyingAsset;

  // Mapping from token ID to minter address
  mapping(uint256 => address) private _minters;

  /**
   * @dev Initializes the uNFT
   * @param underlyingAsset The address of the underlying asset of this uNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset,
    string calldata uNftName,
    string calldata uNftSymbol
  ) external override initializer {
    __ERC721_init(uNftName, uNftSymbol);

    _underlyingAsset = underlyingAsset;

    emit Initialized(underlyingAsset);
  }

  /**
   * @dev Mints uNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address
   *
   * @param to The owner address receive the uNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external override {
    require(AddressUpgradeable.isContract(_msgSender()), "UNFT: caller is not contract");
    require(!_exists(tokenId), "UNFT: exist token");
    require(IERC721Upgradeable(_underlyingAsset).ownerOf(tokenId) == _msgSender(), "UNFT: caller is not owner");

    // Receive NFT Tokens
    IERC721Upgradeable(_underlyingAsset).safeTransferFrom(_msgSender(), address(this), tokenId);

    // mint uNFT to user
    _mint(to, tokenId);

    _minters[tokenId] = _msgSender();

    emit Mint(_msgSender(), _underlyingAsset, tokenId, to);
  }

  /**
   * @dev Burns user uNFT token
   *
   * Requirements:
   *  - The caller must be contract address
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external override {
    require(AddressUpgradeable.isContract(_msgSender()), "UNFT: caller is not contract");
    require(_exists(tokenId), "UNFT: nonexist token");
    require(_minters[tokenId] == _msgSender(), "UNFT: caller is not minter");

    address owner = ERC721Upgradeable.ownerOf(tokenId);

    IERC721Upgradeable(_underlyingAsset).safeTransferFrom(address(this), _msgSender(), tokenId);

    _burn(tokenId);
 
    delete _minters[tokenId];

    emit Burn(_msgSender(), _underlyingAsset, tokenId, owner);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override(ERC721Upgradeable, IERC721MetadataUpgradeable) returns (string memory) {
    return IERC721MetadataUpgradeable(_underlyingAsset).tokenURI(tokenId);
  }

  /**
   * @dev See {ERC721EnumerableUpgradeable}.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /**
   * @dev See {IUNFT-minterOf}.
   */
  function minterOf(uint256 tokenId) external view override returns (address) {
    address minter = _minters[tokenId];
    require(minter != address(0), "UNFT: minter query for nonexistent token");
    return minter;
  }

  /**
   * @dev Being non transferrable, the uNFT token does not implement any of the
   * standard ERC721 functions for transfer and allowance.
   **/
  function approve(address to, uint256 tokenId) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    to;
    tokenId;
    revert("APPROVAL_NOT_SUPPORTED");
  }

  /**
   * @dev See {ERC721EnumerableUpgradeable}.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    operator;
    approved;
    revert("APPROVAL_NOT_SUPPORTED");
  }

  /**
   * @dev See {ERC721EnumerableUpgradeable}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    from;
    to;
    tokenId;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  /**
   * @dev See {ERC721EnumerableUpgradeable}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    from;
    to;
    tokenId;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  /**
   * @dev See {ERC721EnumerableUpgradeable}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    from;
    to;
    tokenId;
    _data;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  /**
   * @dev See {ERC721EnumerableUpgradeable}.
   */
  function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable) {
    from;
    to;
    tokenId;
    revert("TRANSFER_NOT_SUPPORTED");
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {NftLogic} from "../libraries/logic/NftLogic.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {SupplyLogic} from "../libraries/logic/SupplyLogic.sol";
import {BorrowLogic} from "../libraries/logic/BorrowLogic.sol";
import {LiquidateLogic} from "../libraries/logic/LiquidateLogic.sol";
import {LiquidateMarketsLogic} from "../libraries/logic/LiquidateMarketsLogic.sol";

import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {LendPoolStorage} from "./LendPoolStorage.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title LendPool contract
 * @dev Main point of interaction with an Unlockd protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Auction
 *   # Liquidate
 * - To be covered by a proxy contract, owned by the LendPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendPoolConfigurator contract defined also in the
 *   LendPoolAddressesProvider
 * @author Unlockd
 **/
// !!! For Upgradable: DO NOT ADJUST Inheritance Order !!!
contract LendPool is Initializable, ILendPool, ContextUpgradeable, IERC721ReceiverUpgradeable, LendPoolStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20 for IERC20;
  using ReserveLogic for DataTypes.ReserveData;
  using NftLogic for DataTypes.NftData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  bytes32 public constant ADDRESS_ID_WETH_GATEWAY = 0xADDE000000000000000000000000000000000000000000000000000000000001;
  bytes32 public constant ADDRESS_ID_PUNK_GATEWAY = 0xADDE000000000000000000000000000000000000000000000000000000000002;

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

  modifier whenNotPaused() {
    _whenNotPaused();
    _;
  }

  modifier onlyLendPoolConfigurator() {
    _onlyLendPoolConfigurator();
    _;
  }

  modifier onlyLendPoolLiquidatorOrGateway() {
    _onlyLendPoolLiquidatorOrGateway();
    _;
  }

  /**
   * @notice Revert if called by any account other than the rescuer.
   */
  modifier onlyRescuer() {
    require(_msgSender() == _rescuer, "Rescuable: caller is not the rescuer");
    _;
  }

  modifier onlyHolder(address nftAsset, uint256 nftTokenId) {
    require(
      _msgSender() == IERC721Upgradeable(nftAsset).ownerOf(nftTokenId) ||
        _msgSender() == IERC721Upgradeable(_nfts[nftAsset].uNftAddress).ownerOf(nftTokenId),
      Errors.LP_CALLER_NOT_NFT_HOLDER
    );
    _;
  }

  modifier onlyCollection(address nftAsset) {
    DataTypes.NftData memory data = _nfts[nftAsset];
    require(data.uNftAddress != address(0), Errors.LP_COLLECTION_NOT_SUPPORTED);
    _;
  }

  function _whenNotPaused() internal view {
    require(!_paused, Errors.LP_IS_PAUSED);
  }

  function _onlyLendPoolConfigurator() internal view {
    require(_addressesProvider.getLendPoolConfigurator() == _msgSender(), Errors.LP_CALLER_NOT_LEND_POOL_CONFIGURATOR);
  }

  function _onlyLendPoolLiquidatorOrGateway() internal view {
    require(
      _addressesProvider.getLendPoolLiquidator() == _msgSender() ||
        _addressesProvider.getAddress(ADDRESS_ID_WETH_GATEWAY) == _msgSender() ||
        _addressesProvider.getAddress(ADDRESS_ID_PUNK_GATEWAY) == _msgSender(),
      Errors.LP_CALLER_NOT_LEND_POOL_LIQUIDATOR_NOR_GATEWAY
    );
  }

  /**
   * @dev Address allowed to recover accidentally sent ERC20 tokens to the LendPool
   **/
  address private _rescuer;

  /**
   * @dev Function is invoked by the proxy contract when the LendPool contract is added to the
   * LendPoolAddressesProvider of the market.
   * - Caching the address of the LendPoolAddressesProvider in order to reduce gas consumption
   *   on subsequent operations
   * @param provider The address of the LendPoolAddressesProvider
   **/
  function initialize(ILendPoolAddressesProvider provider) public initializer {
    require(address(provider) != address(0), Errors.INVALID_ZERO_ADDRESS);

    _maxNumberOfReserves = 32;
    _maxNumberOfNfts = 255;
    _liquidateFeePercentage = 250;
    _addressesProvider = provider;
  }

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying uTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 uusdc
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the uTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of uTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant whenNotPaused {
    SupplyLogic.executeDeposit(
      _reserves,
      DataTypes.ExecuteDepositParams({
        initiator: _msgSender(),
        asset: asset,
        amount: amount,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent uTokens owned
   * E.g. User has 100 uusdc, calls withdraw() and receives 100 USDC, burning the 100 uusdc
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole uToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external override nonReentrant whenNotPaused returns (uint256) {
    return
      SupplyLogic.executeWithdraw(
        _reserves,
        DataTypes.ExecuteWithdrawParams({initiator: _msgSender(), asset: asset, amount: amount, to: to})
      );
  }

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying nft used as collateral
   * @param nftTokenId The token ID of the underlying nft used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   * 0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address asset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant whenNotPaused {
    BorrowLogic.executeBorrow(
      _addressesProvider,
      _reserves,
      _nfts,
      _nftConfig,
      DataTypes.ExecuteBorrowParams({
        initiator: _msgSender(),
        asset: asset,
        amount: amount,
        nftAsset: nftAsset,
        nftTokenId: nftTokenId,
        onBehalfOf: onBehalfOf,
        referralCode: referralCode
      })
    );
  }

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   **/
  function repay(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external override nonReentrant whenNotPaused returns (uint256, bool) {
    return
      BorrowLogic.executeRepay(
        _addressesProvider,
        _reserves,
        _nfts,
        _nftConfig,
        DataTypes.ExecuteRepayParams({
          initiator: _msgSender(),
          nftAsset: nftAsset,
          nftTokenId: nftTokenId,
          amount: amount
        })
      );
  }

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The bidder want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the bidder want to buy underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidPrice,
    address onBehalfOf
  ) external override nonReentrant whenNotPaused {
    LiquidateLogic.executeAuction(
      _addressesProvider,
      _reserves,
      _nfts,
      _nftConfig,
      _isMarketSupported,
      _sudoswapPairs,
      _buildLendPoolVars(),
      DataTypes.ExecuteAuctionParams({
        initiator: _msgSender(),
        nftAsset: nftAsset,
        nftTokenId: nftTokenId,
        bidPrice: bidPrice,
        onBehalfOf: onBehalfOf,
        auctionDurationConfigFee: _auctionDurationConfigFee
      })
    );
  }

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external override nonReentrant whenNotPaused returns (uint256) {
    return
      LiquidateLogic.executeRedeem(
        _addressesProvider,
        _reserves,
        _nfts,
        _nftConfig,
        _buildLendPoolVars(),
        DataTypes.ExecuteRedeemParams({
          initiator: _msgSender(),
          nftAsset: nftAsset,
          nftTokenId: nftTokenId,
          amount: amount,
          bidFine: bidFine
        })
      );
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external override nonReentrant whenNotPaused returns (uint256) {
    return
      LiquidateLogic.executeLiquidate(
        _addressesProvider,
        _reserves,
        _nfts,
        _nftConfig,
        _buildLendPoolVars(),
        DataTypes.ExecuteLiquidateParams({
          initiator: _msgSender(),
          nftAsset: nftAsset,
          nftTokenId: nftTokenId,
          amount: amount
        })
      );
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateNFTX(
    address nftAsset,
    uint256 nftTokenId
  ) external override nonReentrant onlyLendPoolLiquidatorOrGateway whenNotPaused returns (uint256) {
    return
      LiquidateMarketsLogic.executeLiquidateNFTX(
        _addressesProvider,
        _reserves,
        _nfts,
        _nftConfig, 
        _isMarketSupported,
        DataTypes.ExecuteLiquidateMarketsParams({
          nftAsset: nftAsset,
          nftTokenId: nftTokenId,
          liquidateFeePercentage: _liquidateFeePercentage,
          LSSVMPair: address(0)
        })
      );
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on SudoSwap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateSudoSwap(
    address nftAsset,
    uint256 nftTokenId,
    address LSSVMPair
  ) external override nonReentrant onlyLendPoolLiquidatorOrGateway whenNotPaused returns (uint256) {
    return
      LiquidateMarketsLogic.executeLiquidateSudoSwap(
        _addressesProvider,
        _reserves,
        _nfts,
        _nftConfig,
        _isMarketSupported,
        _buildLendPoolVars(),
        DataTypes.ExecuteLiquidateMarketsParams({
          nftAsset: nftAsset,
          nftTokenId: nftTokenId,
          liquidateFeePercentage: _liquidateFeePercentage,
          LSSVMPair: LSSVMPair
        })
      );
  }

  function approveValuation(
    address nftAsset,
    uint256 nftTokenId
  ) external payable override onlyHolder(nftAsset, nftTokenId) onlyCollection(nftAsset) whenNotPaused {
    require(_configFee == msg.value, Errors.MSG_VALUE_DIFFERENT_FROM_CONFIG_FEE);

    emit ValuationApproved(_msgSender(), nftAsset, nftTokenId);
  }

  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getReserveConfiguration(
    address asset
  ) external view override returns (DataTypes.ReserveConfigurationMap memory) {
    return _reserves[asset].configuration;
  }

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfiguration(address asset) external view override returns (DataTypes.NftConfigurationMap memory) {
    return _nfts[asset].configuration;
  }

  function getNftConfigByTokenId(
    address asset,
    uint256 nftTokenId
  ) external view override returns (DataTypes.NftConfigurationMap memory) {
    return _nftConfig[asset][nftTokenId];
  }

  /**
   * @dev Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view override returns (uint256) {
    return _reserves[asset].getNormalizedIncome();
  }

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view override returns (uint256) {
    return _reserves[asset].getNormalizedDebt();
  }

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view override returns (DataTypes.ReserveData memory) {
    return _reserves[asset];
  }

  /**
   * @dev Returns the state and configuration of the nft
   * @param asset The address of the underlying asset of the nft
   * @return The state of the nft
   **/
  function getNftData(address asset) external view override returns (DataTypes.NftData memory) {
    return _nfts[asset];
  }

  /**
   * @dev Returns the configuration of the nft asset
   * @param asset The address of the underlying asset of the nft
   * @param tokenId NFT asset ID
   * @return The configuration of the nft asset
   **/
  function getNftAssetConfig(
    address asset,
    uint256 tokenId
  ) external view override returns (DataTypes.NftConfigurationMap memory) {
    return _nftConfig[asset][tokenId];
  }

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  )
    external
    view
    override
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    )
  {
    DataTypes.NftConfigurationMap storage nftConfig = _nftConfig[nftAsset][nftTokenId];

    DataTypes.ReserveData storage reserveData = _reserves[reserveAsset];

    (ltv, liquidationThreshold, liquidationBonus) = nftConfig.getCollateralParams();

    (totalCollateralInETH, totalCollateralInReserve) = GenericLogic.calculateNftCollateralData(
      reserveAsset,
      reserveData,
      nftAsset,
      nftTokenId,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    availableBorrowsInETH = GenericLogic.calculateAvailableBorrows(totalCollateralInETH, 0, ltv);
    availableBorrowsInReserve = GenericLogic.calculateAvailableBorrows(totalCollateralInReserve, 0, ltv);
  }

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    override
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    )
  {
    DataTypes.NftConfigurationMap storage nftConfig = _nftConfig[nftAsset][nftTokenId];

    (uint256 ltv, uint256 liquidationThreshold, ) = nftConfig.getCollateralParams();

    loanId = ILendPoolLoan(_addressesProvider.getLendPoolLoan()).getCollateralLoanId(nftAsset, nftTokenId);
    if (loanId == 0) {
      return (0, address(0), 0, 0, 0, 0);
    }

    DataTypes.LoanData memory loan = ILendPoolLoan(_addressesProvider.getLendPoolLoan()).getLoan(loanId);

    reserveAsset = loan.reserveAsset;
    DataTypes.ReserveData storage reserveData = _reserves[reserveAsset];

    (, totalCollateral) = GenericLogic.calculateNftCollateralData(
      reserveAsset,
      reserveData,
      nftAsset,
      nftTokenId,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    (, totalDebt) = GenericLogic.calculateNftDebtData(
      reserveAsset,
      reserveData,
      _addressesProvider.getLendPoolLoan(),
      loanId,
      _addressesProvider.getReserveOracle()
    );

    availableBorrows = GenericLogic.calculateAvailableBorrows(totalCollateral, totalDebt, ltv);

    if (loan.state == DataTypes.LoanState.Active) {
      healthFactor = GenericLogic.calculateHealthFactorFromBalances(totalCollateral, totalDebt, liquidationThreshold);
    }
  }

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    override
    returns (uint256 loanId, address bidderAddress, uint256 bidPrice, uint256 bidBorrowAmount, uint256 bidFine)
  {
    DataTypes.NftConfigurationMap storage nftConfig = _nftConfig[nftAsset][nftTokenId];
    ILendPoolLoan poolLoan = ILendPoolLoan(_addressesProvider.getLendPoolLoan());

    loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    if (loanId != 0) {
      DataTypes.LoanData memory loan = ILendPoolLoan(_addressesProvider.getLendPoolLoan()).getLoan(loanId);
      DataTypes.ReserveData storage reserveData = _reserves[loan.reserveAsset];

      bidderAddress = loan.bidderAddress;
      bidPrice = loan.bidPrice;
      bidBorrowAmount = loan.bidBorrowAmount;

      (, bidFine) = GenericLogic.calculateLoanBidFine(
        loan.reserveAsset,
        reserveData,
        nftAsset,
        nftConfig,
        loan,
        address(poolLoan),
        _addressesProvider.getReserveOracle()
      );
    }
  }

  struct GetLiquidationPriceLocalVars {
    address poolLoan;
    uint256 loanId;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 paybackAmount;
    uint256 remainAmount;
  }

  /**
   * @dev Returns the state and configuration of the nft
   * @param nftAsset The address of the underlying asset of the nft
   * @param nftTokenId The token ID of the asset
   **/
  function getNftLiquidatePrice(
    address nftAsset,
    uint256 nftTokenId
  ) external view override returns (uint256 liquidatePrice, uint256 paybackAmount) {
    GetLiquidationPriceLocalVars memory vars;

    vars.poolLoan = _addressesProvider.getLendPoolLoan();
    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(nftAsset, nftTokenId);
    if (vars.loanId == 0) {
      return (0, 0);
    }

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = _reserves[loanData.reserveAsset];
    DataTypes.NftConfigurationMap storage nftConfig = _nftConfig[nftAsset][nftTokenId];

    (vars.paybackAmount, vars.thresholdPrice, vars.liquidatePrice) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      loanData.nftTokenId,
      nftConfig,
      vars.poolLoan,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    if (vars.liquidatePrice < vars.paybackAmount) {
      vars.liquidatePrice = vars.paybackAmount;
    }

    return (vars.liquidatePrice, vars.paybackAmount);
  }

  /**
   * @dev Validates and finalizes an uToken transfer
   * - Only callable by the overlying uToken of the `asset`
   * @param asset The address of the underlying asset of the uToken
   * @param from The user from which the uToken are transferred
   */
  function finalizeTransfer(
    address asset,
    address from,
    address,
    uint256,
    uint256,
    uint256
  ) external view override whenNotPaused {
    DataTypes.ReserveData storage reserve = _reserves[asset];
    require(_msgSender() == reserve.uTokenAddress, Errors.LP_CALLER_MUST_BE_AN_UTOKEN);

    ValidationLogic.validateTransfer(from, reserve);
  }

  /**
   * @dev Returns the list of the initialized reserves
   **/
  function getReservesList() external view override returns (address[] memory) {
    address[] memory _activeReserves = new address[](_reservesCount);

    for (uint256 i = 0; i != _reservesCount; ) {
      _activeReserves[i] = _reservesList[i];
      unchecked {
        ++i;
      }
    }
    return _activeReserves;
  }

  /**
   * @dev Returns the list of the initialized nfts
   **/
  function getNftsList() external view override returns (address[] memory) {
    address[] memory _activeNfts = new address[](_nftsCount);
    for (uint256 i = 0; i != _nftsCount; ) {
      _activeNfts[i] = _nftsList[i];
      unchecked {
        ++i;
      }
    }
    return _activeNfts;
  }

  /**
   * @dev Set the _pause state of the pool
   * - Only callable by the LendPoolConfigurator contract
   * @param val `true` to pause the pool, `false` to un-pause it
   */
  function setPause(bool val) external override onlyLendPoolConfigurator {
    if (_paused != val) {
      _paused = val;
      if (_paused) {
        _pauseStartTime = block.timestamp;
        emit Paused();
      } else {
        _pauseDurationTime = block.timestamp - _pauseStartTime;
        emit Unpaused();
      }
    }
  }

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view override returns (bool) {
    return _paused;
  }

  function setPausedTime(uint256 startTime, uint256 durationTime) external override onlyLendPoolConfigurator {
    _pauseStartTime = startTime;
    _pauseDurationTime = durationTime;
    emit PausedTimeUpdated(startTime, durationTime);
  }

  function getPausedTime() external view override returns (uint256, uint256) {
    return (_pauseStartTime, _pauseDurationTime);
  }

  /**
   * @dev Returns the cached LendPoolAddressesProvider connected to this contract
   **/
  function getAddressesProvider() external view override returns (ILendPoolAddressesProvider) {
    return _addressesProvider;
  }

  /**
   * @dev Sets the max number of reserves in the protocol
   * @param val the value to set the max number of reserves
   **/
  function setMaxNumberOfReserves(uint256 val) external override onlyLendPoolConfigurator {
    require(val <= 255, Errors.LP_INVALID_OVERFLOW_VALUE); //Sanity check to avoid overflows in `_addReserveToList`
    _maxNumberOfReserves = val;
  }

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendPool
   */
  function getMaxNumberOfReserves() external view override returns (uint256) {
    return _maxNumberOfReserves;
  }

  /**
   * @dev Sets the max number of NFTs in the protocol
   * @param val the value to set the max number of NFTs
   **/
  function setMaxNumberOfNfts(uint256 val) external override onlyLendPoolConfigurator {
    require(val <= 255, Errors.LP_INVALID_OVERFLOW_VALUE); //Sanity check to avoid overflows in `_addNftToList`
    _maxNumberOfNfts = val;
  }

  /**
   * @dev Returns the maximum number of nfts supported to be listed in this LendPool
   */
  function getMaxNumberOfNfts() external view override returns (uint256) {
    return _maxNumberOfNfts;
  }

  function setLiquidateFeePercentage(uint256 percentage) external override onlyLendPoolConfigurator {
    _liquidateFeePercentage = percentage;
  }

  /**
   * @dev Returns the liquidate fee percentage
   */
  function getLiquidateFeePercentage() external view override returns (uint256) {
    return _liquidateFeePercentage;
  }

  /**
   * @dev Sets the max timeframe between NFT config triggers and borrows
   * @param timeframe the number of seconds for the timeframe
   **/
  function setTimeframe(uint256 timeframe) external override onlyLendPoolConfigurator {
    _timeframe = timeframe;
  }

  /**
   * @dev Returns the max timeframe between NFT config triggers and borrows
   **/
  function getTimeframe() external view override returns (uint256) {
    return _timeframe;
  }

  /**
   * @dev Allows and address to be sold on NFTX
   * @param nftAsset the address of the NFT
   **/
  function setIsMarketSupported(address nftAsset, uint8 market, bool val) external override onlyLendPoolConfigurator {
    require(nftAsset != address(0), Errors.INVALID_ZERO_ADDRESS);
    _isMarketSupported[nftAsset][market] = val;
  }

  /**
   * @dev Returns the max timeframe between NFT config triggers and borrows
   **/
  function getIsMarketSupported(address nftAsset, uint8 market) external view override returns (bool) {
    return _isMarketSupported[nftAsset][market];
  }

  /**
   * @dev Sets configFee amount to be charged for ConfigureNFTAsColleteral
   * @param configFee the number of seconds for the timeframe
   **/
  function setConfigFee(uint256 configFee) external override onlyLendPoolConfigurator {
    _configFee = configFee;
  }

  /**
   * @dev Returns the configFee amount
   **/
  function getConfigFee() external view override returns (uint256) {
    return _configFee;
  }

  /**
   * @dev sets the fee to be charged on first bid on nft
   * @param auctionDurationConfigFee the amount to charge to the user
   **/
  function setAuctionDurationConfigFee(uint256 auctionDurationConfigFee) external override onlyLendPoolConfigurator {
    _auctionDurationConfigFee = auctionDurationConfigFee;
  }

  /**
   * @dev Returns the auctionDurationConfigFee amount
   **/
  function getAuctionDurationConfigFee() public view override returns (uint256) {
    return _auctionDurationConfigFee;
  }

  /**
   * @dev Initializes a reserve, activating it, assigning an uToken and nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param uTokenAddress The address of the uToken that will be assigned to the reserve
   * @param debtTokenAddress The address of the debtToken that will be assigned to the reserve
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address uTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external override onlyLendPoolConfigurator {
    require(AddressUpgradeable.isContract(asset), Errors.LP_NOT_CONTRACT);
    require(
      uTokenAddress != address(0) && debtTokenAddress != address(0) && interestRateAddress != address(0),
      Errors.INVALID_ZERO_ADDRESS
    );
    _reserves[asset].init(uTokenAddress, debtTokenAddress, interestRateAddress);
    _addReserveToList(asset);
  }

  /**
   * @dev Initializes a nft, activating it, assigning nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the nft
   * @param uNftAddress the address of the UNFT regarding the chosen asset
   **/
  function initNft(address asset, address uNftAddress) external override onlyLendPoolConfigurator {
    require(AddressUpgradeable.isContract(asset), Errors.LP_NOT_CONTRACT);
    require(uNftAddress != address(0), Errors.INVALID_ZERO_ADDRESS);
    _nfts[asset].init(uNftAddress);
    _addNftToList(asset);

    require(_addressesProvider.getLendPoolLoan() != address(0), Errors.LPC_INVALIED_LOAN_ADDRESS);
    IERC721Upgradeable(asset).setApprovalForAll(_addressesProvider.getLendPoolLoan(), true);

    ILendPoolLoan(_addressesProvider.getLendPoolLoan()).initNft(asset, uNftAddress);
  }

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateAddress(
    address asset,
    address rateAddress
  ) external override onlyLendPoolConfigurator {
    require(asset != address(0) && rateAddress != address(0), Errors.INVALID_ZERO_ADDRESS);
    _reserves[asset].interestRateAddress = rateAddress;
    emit ReserveInterestRateAddressChanged(asset, rateAddress);
  }

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setReserveConfiguration(address asset, uint256 configuration) external override onlyLendPoolConfigurator {
    _reserves[asset].configuration.data = configuration;
    emit ReserveConfigurationChanged(asset, configuration);
  }

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param configuration The new configuration bitmap
   **/
  function setNftConfiguration(address asset, uint256 configuration) external override onlyLendPoolConfigurator {
    _nfts[asset].configuration.data = configuration;
    emit NftConfigurationChanged(asset, configuration);
  }

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param nftTokenId the tokenId of the asset
   * @param configuration The new configuration bitmap
   **/
  function setNftConfigByTokenId(
    address asset,
    uint256 nftTokenId,
    uint256 configuration
  ) external override onlyLendPoolConfigurator {
    _nftConfig[asset][nftTokenId].data = configuration;
    emit NftConfigurationByIdChanged(asset, nftTokenId, configuration);
  }

  /**
   * @dev Sets the max supply and token ID for a given asset
   * @param asset The address to set the data
   * @param maxSupply The max supply value
   * @param maxTokenId The max token ID value
   **/
  function setNftMaxSupplyAndTokenId(
    address asset,
    uint256 maxSupply,
    uint256 maxTokenId
  ) external override onlyLendPoolConfigurator {
    _nfts[asset].maxSupply = maxSupply;
    _nfts[asset].maxTokenId = maxTokenId;
  }

  /**
   * @notice Rescue tokens and ETH locked up in this contract.
   * @param tokenContract ERC20 token contract address
   * @param to        Recipient address
   * @param amount    Amount to withdraw
   */
  function rescue(
    IERC20 tokenContract,
    address to,
    uint256 amount,
    bool rescueETH
  ) external override nonReentrant onlyRescuer {
    if (rescueETH) {
      (bool sent, ) = to.call{value: amount}("");
      require(sent, "Failed to send Ether");
    } else {
      tokenContract.safeTransfer(to, amount);
    }
  }

  /**
   * @notice Rescue NFTs locked up in this contract.
   * @param nftAsset ERC721 asset contract address
   * @param tokenId ERC721 token id
   * @param to Recipient address
   */
  function rescueNFT(
    IERC721Upgradeable nftAsset,
    uint256 tokenId,
    address to
  ) external override nonReentrant onlyRescuer {
    nftAsset.safeTransferFrom(address(this), to, tokenId);
  }

  /**
   * @notice Assign the rescuer role to a given address.
   * @param newRescuer New rescuer's address
   */
  function updateRescuer(address newRescuer) external override onlyLendPoolConfigurator {
    require(newRescuer != address(0), "Rescuable: new rescuer is the zero address");
    _rescuer = newRescuer;
    emit RescuerChanged(newRescuer);
  }

  /**
   * @notice Returns current rescuer
   * @return Rescuer's address
   */
  function rescuer() external view override returns (address) {
    return _rescuer;
  }

  function _addReserveToList(address asset) internal {
    uint256 reservesCount = _reservesCount;

    require(reservesCount < _maxNumberOfReserves, Errors.LP_NO_MORE_RESERVES_ALLOWED);

    bool reserveAlreadyAdded = _reserves[asset].id != 0 || _reservesList[0] == asset;

    if (!reserveAlreadyAdded) {
      _reserves[asset].id = uint8(reservesCount);
      _reservesList[reservesCount] = asset;

      _reservesCount = reservesCount + 1;
    }
  }

  function _addNftToList(address asset) internal {
    uint256 nftsCount = _nftsCount;

    require(nftsCount < _maxNumberOfNfts, Errors.LP_NO_MORE_NFTS_ALLOWED);

    bool nftAlreadyAdded = _nfts[asset].id != 0 || _nftsList[0] == asset;

    if (!nftAlreadyAdded) {
      _nfts[asset].id = uint8(nftsCount);
      _nftsList[nftsCount] = asset;

      _nftsCount = nftsCount + 1;
    }
  }

  function _buildLendPoolVars() internal view returns (DataTypes.ExecuteLendPoolStates memory) {
    return DataTypes.ExecuteLendPoolStates({pauseStartTime: _pauseStartTime, pauseDurationTime: _pauseDurationTime});
  }

  receive() external payable {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {UnlockdUpgradeableProxy} from "../libraries/proxy/UnlockdUpgradeableProxy.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Unlockd Governance
 * @author Unlockd
 **/
contract LendPoolAddressesProvider is Ownable, ILendPoolAddressesProvider {
  string private _marketId;
  mapping(bytes32 => address) private _addresses;
  address private wethAddress;
  bytes32 private constant LEND_POOL = "LEND_POOL";
  bytes32 private constant LEND_POOL_CONFIGURATOR = "LEND_POOL_CONFIGURATOR";
  bytes32 private constant POOL_ADMIN = "POOL_ADMIN";
  bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
  bytes32 private constant RESERVE_ORACLE = "RESERVE_ORACLE";
  bytes32 private constant NFT_ORACLE = "NFT_ORACLE";
  bytes32 private constant LEND_POOL_LOAN = "LEND_POOL_LOAN";
  bytes32 private constant UNFT_REGISTRY = "UNFT_REGISTRY";
  bytes32 private constant LEND_POOL_LIQUIDATOR = "LEND_POOL_LIQUIDATOR";
  bytes32 private constant INCENTIVES_CONTROLLER = "INCENTIVES_CONTROLLER";
  bytes32 private constant UNLOCKD_DATA_PROVIDER = "UNLOCKD_DATA_PROVIDER";
  bytes32 private constant UI_DATA_PROVIDER = "UI_DATA_PROVIDER";
  bytes32 private constant WALLET_BALANCE_PROVIDER = "WALLET_BALANCE_PROVIDER";
  bytes32 private constant NFTX_VAULT_FACTORY = "NFTX_VAULT_FACTORY";
  bytes32 private constant SUSHI_SWAP_ROUTER = "SUSHI_SWAP_ROUTER";
  bytes32 private constant LSSVM_ROUTER = "LSSVM_ROUTER";

  constructor(string memory marketId) {
    _setMarketId(marketId);
  }

  /**
   * @dev Returns the id of the Unlockd market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string memory marketId) external override onlyOwner {
    _setMarketId(marketId);
  }

  /**
   * @dev Returns the WETH address
   * @return The WETH address
   **/
  function getWETHAddress() external view override returns (address) {
    return wethAddress;
  }

  /**
   * @dev Allows to set the WETH address for the market
   * @param _wethAddress The WETH address to set
   */
  function setWETHAddress(address _wethAddress) external override onlyOwner {
    require(_wethAddress != address(0), Errors.INVALID_ZERO_ADDRESS);
    wethAddress = _wethAddress;
  }

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param implementationAddress The address of the new implementation
   */
  function setAddressAsProxy(
    bytes32 id,
    address implementationAddress,
    bytes memory encodedCallData
  ) external override onlyOwner {
    require(implementationAddress != address(0), Errors.INVALID_ZERO_ADDRESS);
    _updateImpl(id, implementationAddress);
    emit AddressSet(id, implementationAddress, true, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[id], encodedCallData);
    }
  }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    require(newAddress != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false, new bytes(0));
  }

  /** 
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /**
   * @dev Returns the address of the LendPool proxy
   * @return The LendPool proxy address
   **/
  function getLendPool() external view override returns (address) {
    return getAddress(LEND_POOL);
  }

  /**
   * @dev Updates the implementation of the LendPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendPool implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolImpl(address pool, bytes memory encodedCallData) external override onlyOwner {
    require(pool != address(0), Errors.INVALID_ZERO_ADDRESS);
    _updateImpl(LEND_POOL, pool);
    emit LendPoolUpdated(pool, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[LEND_POOL], encodedCallData);
    }
  }

  /**
   * @dev Returns the address of the LendPoolConfigurator proxy
   * @return The LendPoolConfigurator proxy address
   **/
  function getLendPoolConfigurator() external view override returns (address) {
    return getAddress(LEND_POOL_CONFIGURATOR);
  }

  /**
   * @dev Updates the implementation of the LendPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendPoolConfigurator implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external override onlyOwner {
    require(configurator != address(0), Errors.INVALID_ZERO_ADDRESS);
    _updateImpl(LEND_POOL_CONFIGURATOR, configurator);
    emit LendPoolConfiguratorUpdated(configurator, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[LEND_POOL_CONFIGURATOR], encodedCallData);
    }
  }

  /**
   * @dev returns the address of the LendPool admin
   * @return the LendPoolAdmin address
   **/

  function getPoolAdmin() external view override returns (address) {
    return getAddress(POOL_ADMIN);
  }

  /**
   * @dev sets the address of the LendPool admin
   * @param admin the LendPoolAdmin address
   **/
  function setPoolAdmin(address admin) external override onlyOwner {
    require(admin != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[POOL_ADMIN] = admin;
    emit ConfigurationAdminUpdated(admin);
  }

  /**
   * @dev returns the address of the emergency admin
   * @return the EmergencyAdmin address
   **/
  function getEmergencyAdmin() external view override returns (address) {
    return getAddress(EMERGENCY_ADMIN);
  }

  /**
   * @dev sets the address of the emergency admin
   * @param emergencyAdmin the EmergencyAdmin address
   **/
  function setEmergencyAdmin(address emergencyAdmin) external override onlyOwner {
    require(emergencyAdmin != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    emit EmergencyAdminUpdated(emergencyAdmin);
  }

  /**
   * @dev returns the address of the reserve oracle
   * @return the ReserveOracle address
   **/
  function getReserveOracle() external view override returns (address) {
    return getAddress(RESERVE_ORACLE);
  }

  /**
   * @dev sets the address of the reserve oracle
   * @param reserveOracle the ReserveOracle address
   **/
  function setReserveOracle(address reserveOracle) external override onlyOwner {
    require(reserveOracle != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[RESERVE_ORACLE] = reserveOracle;
    emit ReserveOracleUpdated(reserveOracle);
  }

  /**
   * @dev returns the address of the NFT oracle
   * @return the NFTOracle address
   **/
  function getNFTOracle() external view override returns (address) {
    return getAddress(NFT_ORACLE);
  }

  /**
   * @dev sets the address of the NFT oracle
   * @param nftOracle the NFTOracle address
   **/
  function setNFTOracle(address nftOracle) external override onlyOwner {
    require(nftOracle != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[NFT_ORACLE] = nftOracle;
    emit NftOracleUpdated(nftOracle);
  }

  /**
   * @dev returns the address of the lendpool loan
   * @return the LendPoolLoan address
   **/
  function getLendPoolLoan() external view override returns (address) {
    return getAddress(LEND_POOL_LOAN);
  }

  /**
   * @dev sets the address of the lendpool loan
   * @param loanAddress the LendPoolLoan address
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolLoanImpl(address loanAddress, bytes memory encodedCallData) external override onlyOwner {
    require(loanAddress != address(0), Errors.INVALID_ZERO_ADDRESS);
    _updateImpl(LEND_POOL_LOAN, loanAddress);
    emit LendPoolLoanUpdated(loanAddress, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[LEND_POOL_LOAN], encodedCallData);
    }
  }

  /**
   * @dev returns the address of the UNFT Registry
   * @return the UNFTRegistry address
   **/
  function getUNFTRegistry() external view override returns (address) {
    return getAddress(UNFT_REGISTRY);
  }

  /**
   * @dev sets the address of the UNFT registry
   * @param factory the UNFTRegistry address
   **/
  function setUNFTRegistry(address factory) external override onlyOwner {
    require(factory != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[UNFT_REGISTRY] = factory;
    emit UNFTRegistryUpdated(factory);
  }

  /**
   * @dev returns the address of the incentives controller
   * @return the IncentivesController address
   **/
  function getIncentivesController() external view override returns (address) {
    return getAddress(INCENTIVES_CONTROLLER);
  }

  /**
   * @dev sets the address of the incentives controller
   * @param controller the IncentivesController address
   **/
  function setIncentivesController(address controller) external override onlyOwner {
    require(controller != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[INCENTIVES_CONTROLLER] = controller;
    emit IncentivesControllerUpdated(controller);
  }

  /**
   * @dev returns the address of the UI data provider
   * @return the UIDataProvider address
   **/
  function getUIDataProvider() external view override returns (address) {
    return getAddress(UI_DATA_PROVIDER);
  }

  /**
   * @dev sets the address of the UI data provider
   * @param provider the UIDataProvider address
   **/
  function setUIDataProvider(address provider) external override onlyOwner {
    _addresses[UI_DATA_PROVIDER] = provider;
    emit UIDataProviderUpdated(provider);
  }

  /**
   * @dev returns the address of the Unlockd data provider
   * @return the UnlockdDataProvider address
   **/
  function getUnlockdDataProvider() external view override returns (address) {
    return getAddress(UNLOCKD_DATA_PROVIDER);
  }

  /**
   * @dev sets the address of the Unlockd data provider
   * @param provider the UnlockdDataProvider address
   **/
  function setUnlockdDataProvider(address provider) external override onlyOwner {
    require(provider != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[UNLOCKD_DATA_PROVIDER] = provider;
    emit UnlockdDataProviderUpdated(provider);
  }

  /**
   * @dev returns the address of the wallet balance provider
   * @return the WalletBalanceProvider address
   **/
  function getWalletBalanceProvider() external view override returns (address) {
    return getAddress(WALLET_BALANCE_PROVIDER);
  }

  /**
   * @dev sets the address of the wallet balance provider
   * @param provider the WalletBalanceProvider address
   **/
  function setWalletBalanceProvider(address provider) external override onlyOwner {
    require(provider != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[WALLET_BALANCE_PROVIDER] = provider;
    emit WalletBalanceProviderUpdated(provider);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function getNFTXVaultFactory() external view override returns (address) {
    return getAddress(NFTX_VAULT_FACTORY);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function setNFTXVaultFactory(address factory) external override onlyOwner {
    require(factory != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[NFTX_VAULT_FACTORY] = factory;
    emit NFTXVaultFactoryUpdated(factory);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function getLSSVMRouter() external view override returns (address) {
    return getAddress(LSSVM_ROUTER);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function setLSSVMRouter(address router) external override onlyOwner {
    require(router != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[LSSVM_ROUTER] = router;
    emit LSSVMRouterUpdated(router);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function getSushiSwapRouter() external view override returns (address) {
    return getAddress(SUSHI_SWAP_ROUTER);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function setSushiSwapRouter(address router) external override onlyOwner {
    require(router != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[SUSHI_SWAP_ROUTER] = router;
    emit SushiSwapRouterUpdated(router);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function getLendPoolLiquidator() external view override returns (address) {
    return getAddress(LEND_POOL_LIQUIDATOR);
  }

  /**
   * @inheritdoc ILendPoolAddressesProvider
   */
  function setLendPoolLiquidator(address liquidator) external override onlyOwner {
    require(liquidator != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addresses[LEND_POOL_LIQUIDATOR] = liquidator;
    emit LendPoolLiquidatorUpdated(liquidator);
  }

  /**
   * @dev Returns the implementation contract pointed by a proxy
   * @param proxyAddress the proxy to request the implementation from
   */
  function getImplementation(address proxyAddress) external view onlyOwner returns (address) {
    UnlockdUpgradeableProxy proxy = UnlockdUpgradeableProxy(payable(proxyAddress));
    return proxy.getImplementation();
  }

  /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the encoded method function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress) internal {
    address payable proxyAddress = payable(_addresses[id]);

    if (proxyAddress == address(0)) {
      bytes memory params = abi.encodeWithSignature("initialize(address)", address(this));

      // create proxy, then init proxy & implementation
      UnlockdUpgradeableProxy proxy = new UnlockdUpgradeableProxy(newAddress, address(this), params);

      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      // upgrade implementation
      UnlockdUpgradeableProxy proxy = UnlockdUpgradeableProxy(proxyAddress);

      proxy.upgradeTo(newAddress);
    }
  }

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function _setMarketId(string memory marketId) internal {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUNFT} from "../interfaces/IUNFT.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {NFTXSeller} from "../libraries/markets/NFTXSeller.sol";
import {SudoSwapSeller} from "../libraries/markets/SudoSwapSeller.sol";

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract LendPoolLoan is Initializable, ILendPoolLoan, ContextUpgradeable, IERC721ReceiverUpgradeable {
  using WadRayMath for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  ILendPoolAddressesProvider private _addressesProvider;

  CountersUpgradeable.Counter private _loanIdTracker;
  mapping(uint256 => DataTypes.LoanData) private _loans;

  // nftAsset + nftTokenId => loanId
  mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
  mapping(address => uint256) private _nftTotalCollateral;
  mapping(address => mapping(address => uint256)) private _userNftCollateral;

  /**
   * @dev Only lending pool can call functions marked by this modifier
   **/
  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }

  // called once by the factory at time of deployment
  function initialize(ILendPoolAddressesProvider provider) external initializer {
    require(address(provider) != address(0), Errors.INVALID_ZERO_ADDRESS);

    __Context_init();
    require(address(provider) != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addressesProvider = provider;

    // Avoid having loanId = 0
    _loanIdTracker.increment();

    emit Initialized(address(_getLendPool()));
  }

  function initNft(address nftAsset, address uNftAddress) external override onlyLendPool {
    IERC721Upgradeable(nftAsset).setApprovalForAll(uNftAddress, true);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address uNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external override onlyLendPool returns (uint256) {
    require(_nftToLoanIds[nftAsset][nftTokenId] == 0, Errors.LP_NFT_HAS_USED_AS_COLLATERAL);

    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(borrowIndex);

    uint256 loanId = _loanIdTracker.current();
    _loanIdTracker.increment();

    _nftToLoanIds[nftAsset][nftTokenId] = loanId;

    // transfer underlying NFT asset to pool and mint uNFT to onBehalfOf
    IERC721Upgradeable(nftAsset).safeTransferFrom(_msgSender(), address(this), nftTokenId);

    IUNFT(uNftAddress).mint(onBehalfOf, nftTokenId);

    // Save Info
    DataTypes.LoanData storage loanData = _loans[loanId];
    loanData.loanId = loanId;
    loanData.state = DataTypes.LoanState.Active;
    loanData.borrower = onBehalfOf;
    loanData.nftAsset = nftAsset;
    loanData.nftTokenId = nftTokenId;
    loanData.reserveAsset = reserveAsset;
    loanData.scaledAmount = amountScaled;

    _userNftCollateral[onBehalfOf][nftAsset] += 1;

    _nftTotalCollateral[nftAsset] += 1;

    emit LoanCreated(initiator, onBehalfOf, loanId, nftAsset, nftTokenId, reserveAsset, amount, borrowIndex);

    return (loanId);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    uint256 amountScaled = 0;

    if (amountAdded > 0) {
      amountScaled = amountAdded.rayDiv(borrowIndex);
      require(amountScaled != 0, Errors.LPL_INVALID_LOAN_AMOUNT);

      loan.scaledAmount += amountScaled;
    }

    if (amountTaken > 0) {
      amountScaled = amountTaken.rayDiv(borrowIndex);
      require(amountScaled != 0, Errors.LPL_INVALID_TAKEN_AMOUNT);

      require(loan.scaledAmount >= amountScaled, Errors.LPL_AMOUNT_OVERFLOW);
      loan.scaledAmount -= amountScaled;
    }

    emit LoanUpdated(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      amountAdded,
      amountTaken,
      borrowIndex
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Repaid;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and transfer underlying NFT asset to user
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanRepaid(initiator, loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, amount, borrowIndex);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];
    address previousBidder = loan.bidderAddress;
    uint256 previousPrice = loan.bidPrice;

    // Ensure valid loan state
    if (loan.bidStartTimestamp == 0) {
      require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

      loan.state = DataTypes.LoanState.Auction;
      loan.bidStartTimestamp = block.timestamp;
      loan.firstBidderAddress = onBehalfOf;
    } else {
      require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

      require(bidPrice > loan.bidPrice, Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
    }

    loan.bidBorrowAmount = borrowAmount;
    loan.bidderAddress = onBehalfOf;
    loan.bidPrice = bidPrice;

    emit LoanAuctioned(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.bidBorrowAmount,
      borrowIndex,
      onBehalfOf,
      bidPrice,
      previousBidder,
      previousPrice
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function redeemLoan(
    address initiator,
    uint256 loanId,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    uint256 amountScaled = amountTaken.rayDiv(borrowIndex);
    require(amountScaled != 0, Errors.LPL_INVALID_TAKEN_AMOUNT);

    require(loan.scaledAmount >= amountScaled, Errors.LPL_AMOUNT_OVERFLOW);
    loan.scaledAmount -= amountScaled;

    loan.state = DataTypes.LoanState.Active;
    loan.bidStartTimestamp = 0;
    loan.bidBorrowAmount = 0;
    loan.bidderAddress = address(0);
    loan.bidPrice = 0;
    loan.firstBidderAddress = address(0);

    emit LoanRedeemed(initiator, loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, amountTaken, borrowIndex);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Defaulted;
    _loans[loanId].bidBorrowAmount = borrowAmount;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and transfer underlying NFT asset to user
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanLiquidated(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoanNFTX(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool returns (uint256 sellPrice) {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Defaulted;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and sell underlying NFT on NFTX
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    require(IERC721Upgradeable(loan.nftAsset).ownerOf(loan.nftTokenId) == address(this), "Invalid Call");

    // Sell NFT on NFTX
    sellPrice = NFTXSeller.sellNFTX(_addressesProvider, loan.nftAsset, loan.nftTokenId, loan.reserveAsset);

    emit LoanLiquidatedNFTX(
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex,
      sellPrice
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */ 
  function liquidateLoanSudoSwap(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    address LSSVMPair
  ) external override onlyLendPool returns (uint256 sellPrice) {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    loan.state = DataTypes.LoanState.Defaulted;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and sell underlying NFT on SudoSwap
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    require(IERC721Upgradeable(loan.nftAsset).ownerOf(loan.nftTokenId) == address(this), "Invalid Call");

    // Sell NFT on SudoSwap
    sellPrice = SudoSwapSeller.sellSudoSwap(_addressesProvider, loan.nftAsset, loan.nftTokenId, LSSVMPair);

    emit LoanLiquidatedSudoSwap(
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex,
      sellPrice,
      LSSVMPair
    );
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external pure override returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function borrowerOf(uint256 loanId) external view override returns (address) {
    return _loans[loanId].borrower;
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view override returns (uint256) {
    return _nftToLoanIds[nftAsset][nftTokenId];
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoan(uint256 loanId) external view override returns (DataTypes.LoanData memory loanData) {
    return _loans[loanId];
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    override
    returns (
      address nftAsset,
      uint256 nftTokenId,
      address reserveAsset,
      uint256 scaledAmount
    )
  {
    return (
      _loans[loanId].nftAsset,
      _loans[loanId].nftTokenId,
      _loans[loanId].reserveAsset,
      _loans[loanId].scaledAmount
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanReserveBorrowAmount(uint256 loanId) external view override returns (address, uint256) {
    uint256 scaledAmount = _loans[loanId].scaledAmount;
    if (scaledAmount == 0) {
      return (_loans[loanId].reserveAsset, 0);
    }
    uint256 amount = scaledAmount.rayMul(_getLendPool().getReserveNormalizedVariableDebt(_loans[loanId].reserveAsset));

    return (_loans[loanId].reserveAsset, amount);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view override returns (address, uint256) {
    return (_loans[loanId].reserveAsset, _loans[loanId].scaledAmount);
  }

  function getLoanHighestBid(uint256 loanId) external view override returns (address, uint256) {
    return (_loans[loanId].bidderAddress, _loans[loanId].bidPrice);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getNftCollateralAmount(address nftAsset) external view override returns (uint256) {
    return _nftTotalCollateral[nftAsset];
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getUserNftCollateralAmount(address user, address nftAsset) external view override returns (uint256) {
    return _userNftCollateral[user][nftAsset];
  }

  /**
   * @dev returns the LendPool address
   */
  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressesProvider.getLendPool());
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanIdTracker() external view override returns (CountersUpgradeable.Counter memory) {
    return _loanIdTracker;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {NftLogic} from "../libraries/logic/NftLogic.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

contract LendPoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using NftLogic for DataTypes.NftData;

  ILendPoolAddressesProvider internal _addressesProvider;

  uint256 internal _reservesCount;
  uint256 internal _maxNumberOfReserves;
  uint256 internal _nftsCount;
  uint256 internal _maxNumberOfNfts;
  uint256 internal constant _NOT_ENTERED = 0;
  uint256 internal constant _ENTERED = 1;
  uint256 internal _status;
  uint256 internal _pauseStartTime;
  uint256 internal _pauseDurationTime;
  uint256 internal _liquidateFeePercentage;
  uint256 internal _timeframe;
  uint256 internal _configFee;
  bool internal _paused;

  mapping(address => DataTypes.ReserveData) internal _reserves;
  mapping(uint256 => address) internal _reservesList;
  mapping(address => DataTypes.NftData) internal _nfts;
  mapping(address => mapping(uint256 => DataTypes.NftConfigurationMap)) internal _nftConfig;
  mapping(uint256 => address) internal _nftsList;
  /*
   * @dev Markets supported for each NFT
   * @param address -> the collection address
   * @param uint8 -> market id (0 for NFTX, 1 for SudoSwap)
   * @param bool -> whether it is supported in the corresponding market or not
   */
  mapping(address => mapping(uint8 => bool)) public _isMarketSupported;

  mapping(address => address[2]) internal _sudoswapPairs;

  uint256 internal _auctionDurationConfigFee;

  // For upgradable, add one new variable above, minus 1 at here
  uint256[49] private __gap;
}