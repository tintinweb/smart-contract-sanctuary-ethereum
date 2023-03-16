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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

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

        _afterTokenTransfer(address(0), to, tokenId, 1);
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

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

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

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

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

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PaymentProcessor.sol";
import "./OrbitNFT.sol";
import "./Subscription.sol";
import "./interfaces/IOrbitFactory.sol";

/// @title Orbit factory
/// @notice Factory with which content creator creates his subscription and access NFT
contract OrbitFactory is IOrbitFactory, PaymentProcessor, ReentrancyGuard, Ownable, Initializable {
    /// @inheritdoc IOrbitFactory
    IStaking public staking;
    // content creators list
    address[] public creators;
    /// @inheritdoc IOrbitFactory
    mapping(address => Creator) public getCreatorInfo;
    /// @inheritdoc IOrbitFactory
    uint256 public priceUSD;

    /// @notice Factory constructor
    /// @param _staking staking address
    /// @param _swapperOracle oracle address
    /// @param _usdCoin USD stablecoin address
    /// @param _WETH wrapped ethereum address
    /// @param _priceUSD default price for a subscription creation in USD
    constructor(
        address _staking,
        address _swapperOracle,
        address _usdCoin,
        address _WETH,
        uint256 _priceUSD
    ) PaymentProcessor(_usdCoin, _WETH, _swapperOracle) {
        require(_staking != address(0), "OF: STAKING CANT'T BE ZERO ADDRESS");
        validatePrice(_priceUSD);

        staking = IStaking(_staking);
        priceUSD = _priceUSD;
        emit NewPrice(_priceUSD);
    }
    /// @inheritdoc IOrbitFactory
    function setNewPrice(uint256 _newPriceUSD) external onlyOwner {
        validatePrice(_newPriceUSD);
        priceUSD = _newPriceUSD;
        emit NewPrice(_newPriceUSD);
    }
    /// @inheritdoc IOrbitFactory
    function getCreators() external view returns(address[] memory) {
        return creators;
    }
    
    // ----------- SUBSCRIPTION AND NFT CREATION FUNCTIONS -----------

    /// @inheritdoc IOrbitFactory
    function createSubscriptionWithETH(uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration, string memory _baseUri) external payable nonReentrant {
        uint256 fee = createSubscription(_prices, _limits, _duration, _baseUri); 
        (uint256 toOrbitETH, uint256 toStakingETH) = processPaymentETH(priceUSD, fee);
        distributeReceivedPayment(owner(), address(staking), toOrbitETH, toStakingETH);
    }

    /// @inheritdoc IOrbitFactory
    function createSubscriptionWithUSD(uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration, string memory _baseUri) external nonReentrant {
        uint256 fee = createSubscription(_prices, _limits, _duration, _baseUri); 
        (uint256 toOrbitETH, uint256 toStakingETH) = processPaymentUSD(priceUSD, fee);
        distributeReceivedPayment(owner(), address(staking), toOrbitETH, toStakingETH);
    }

    function createSubscription(uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration, string memory _baseUri) internal returns(uint256 fee){
        validatePrices(_prices);
        fee = staking.fee();
        Subscription newSubscription = new Subscription(
            msg.sender,
            address(staking),
            address(swapperOracle),
            address(USD),
            address(WETH)     
        );
        OrbitNFT newToken = new OrbitNFT(
            msg.sender,
            address(newSubscription),
            _baseUri
        );
        newSubscription.initialize(address(newToken), _prices, _limits, _duration);
        creators.push(msg.sender);
        getCreatorInfo[msg.sender] = Creator({
            subscription: address(newSubscription),
            accessNFT: address(newToken)
        });

        emit SubscriptionCreated(msg.sender, _prices.length, _duration, address(newSubscription), address(newToken));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./PaymentProcessor.sol";
import "./interfaces/IOrbitMarket.sol";
import "./interfaces/ISubscription.sol";

/// @title Orbit market
/// @notice Market contract where content creators can sell access to stand-alone content and subscription NFT owners can sell their tokens
contract OrbitMarket is
    IOrbitMarket,
    PaymentProcessor,
    ReentrancyGuard,
    IERC721Receiver,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _contentIdCounter;

    /// @inheritdoc IOrbitMarket
    IStaking public staking;
    /// @inheritdoc IOrbitMarket
    OrbitFactory public factory;

    /// @inheritdoc IOrbitMarket
    OrderInfo[] public orders;
    /// @inheritdoc IOrbitMarket
    mapping(address => mapping(uint256 => uint256)) public getOrderId;
    /// creator address => array of content ids
    mapping(address => uint256[]) public getCreatorContentId;
    /// @inheritdoc IOrbitMarket
    mapping(address => mapping(uint256 => bool)) public isEligibleUser;
    // creator address => content id => content info
    mapping(address => mapping(uint256 => ContentInfo))
        internal _getContentInfo;

    modifier onlyCreator() {
        (address subscription, ) = factory.getCreatorInfo(msg.sender);
        require(subscription != address(0), "OM: USER IS NOT A CREATOR");
        _;
    }

    /// @notice Market constructor
    /// @param _staking staking address
    /// @param _factory factory address
    /// @param _swapperOracle oracle address
    /// @param _usdCoin USD stablecoin address
    /// @param _WETH wrapped ethereum address
    constructor(
        address _staking,
        address _factory,
        address _swapperOracle,
        address _usdCoin,
        address _WETH
    ) PaymentProcessor(_usdCoin, _WETH, _swapperOracle) {
        require(_staking != address(0), "OM: STAKING CANT'T BE ZERO ADDRESS");
        require(_factory != address(0), "OM: FACTORY CANT'T BE ZERO ADDRESS");
        staking = IStaking(_staking);
        factory = OrbitFactory(_factory);
        orders.push();
    }

    // ----------- CONTENT PURCHASE FUNCTIONS -----------

    /// @inheritdoc IOrbitMarket
    function payForContentWithETH(
        address _creator,
        uint256 _contentId
    ) external payable nonReentrant {
        (uint256 priceUSD, uint256 fee) = payForContent(_creator, _contentId);
        (uint256 toCreatorETH, uint256 toStakingETH) = processPaymentETH(
            priceUSD,
            fee
        );
        distributeReceivedPayment(
            _creator,
            address(staking),
            toCreatorETH,
            toStakingETH
        );
    }

    /// @inheritdoc IOrbitMarket
    function payForContentWithUSD(
        address _creator,
        uint256 _contentId
    ) external nonReentrant {
        (uint256 priceUSD, uint256 fee) = payForContent(_creator, _contentId);
        (uint256 toCreatorETH, uint256 toStakingETH) = processPaymentUSD(
            priceUSD,
            fee
        );
        distributeReceivedPayment(
            _creator,
            address(staking),
            toCreatorETH,
            toStakingETH
        );
    }

    /// @inheritdoc IOrbitMarket
    function createContent(
        string calldata _contentUrl,
        uint256 _price
    ) external onlyCreator {
        uint256 contentId = _contentIdCounter.current();
        _contentIdCounter.increment();

        validatePrice(_price);
        _getContentInfo[msg.sender][contentId] = ContentInfo(
            _contentUrl,
            _price
        );
        getCreatorContentId[msg.sender].push(contentId);

        emit ContentCreated(
            msg.sender,
            contentId,
            _price
        );
    }

    /// @inheritdoc IOrbitMarket
    function setContentPrice(
        uint256 _contentId,
        uint256 _newPrice
    ) external onlyCreator {
        require(
            _getContentInfo[msg.sender][_contentId].price != 0,
            "OM: CONTENT DOESN'T EXIST"
        );
        validatePrice(_newPrice);
        _getContentInfo[msg.sender][_contentId].price = _newPrice;
        emit NewContentPrice(msg.sender, _contentId, _newPrice);
    }

    /// @inheritdoc IOrbitMarket
    function getAllCreatorContentIds(
        address _creator
    ) external view returns (uint256[] memory allCreatorContentIds) {
        allCreatorContentIds = getCreatorContentId[_creator];
    }

    /// @inheritdoc IOrbitMarket
    function getContentInfo(
        address _creator,
        uint256 _contentId
    ) external view returns (ContentInfo memory contentInfo) {
        contentInfo = _getContentInfo[_creator][_contentId];
    }

    // ----------- SECOND HAND NFT MARKET FUNCTIONS -----------

    /// @inheritdoc IOrbitMarket
    function createOrder(
        address _creator,
        uint256 _nftId,
        uint256 _price
    ) external {
        (, address nftAddress) = factory.getCreatorInfo(_creator);
        require(nftAddress != address(0), "OM: NFT DOESN'T EXIST");

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(msg.sender, address(this), _nftId);

        uint256 orderId = orders.length;

        validatePrice(_price);
        OrderInfo memory newOrder = OrderInfo(
            orderId,
            msg.sender,
            _creator,
            _nftId,
            _price
        );

        orders.push(newOrder);
        getOrderId[_creator][_nftId] = orderId;

        emit OrderCreated(msg.sender, _creator, _nftId, _price, orderId);
    }

    /// @inheritdoc IOrbitMarket
    function cancelOrder(address _creator, uint256 _nftId) external {
        (, address nftAddress) = factory.getCreatorInfo(_creator);
        require(nftAddress != address(0), "OM: NFT DOESN'T EXIST");

        IERC721 nft = IERC721(nftAddress);

        uint256 orderId = getOrderId[_creator][_nftId];
        require(orderId != 0, "OM: ORDER DOESN'T EXIST");
        require(orders[orderId].seller == msg.sender, "OM: ONLY SELLER");

        deleteOrder(_creator, _nftId, orderId);
        nft.safeTransferFrom(address(this), msg.sender, _nftId);

        emit OrderCancelled(msg.sender, _creator, _nftId, orderId);
    }

    /// @inheritdoc IOrbitMarket
    function buyOrderWithETH(
        address _creator,
        uint256 _nftId
    ) external payable nonReentrant {
        (uint256 priceUSD, uint256 fee, address seller) = fulfillOrder(
            _creator,
            _nftId
        );
        (uint256 toSellerETH, uint256 toStakingETH) = processPaymentETH(
            priceUSD,
            fee
        );
        distributeReceivedPayment(
            seller,
            address(staking),
            toSellerETH,
            toStakingETH
        );
    }

    /// @inheritdoc IOrbitMarket
    function buyOrderWithUSD(
        address _creator,
        uint256 _nftId
    ) external nonReentrant {
        (uint256 priceUSD, uint256 fee, address seller) = fulfillOrder(
            _creator,
            _nftId
        );
        (uint256 toSellerETH, uint256 toStakingETH) = processPaymentUSD(
            priceUSD,
            fee
        );
        distributeReceivedPayment(
            seller,
            address(staking),
            toSellerETH,
            toStakingETH
        );
    }

    /// @inheritdoc IOrbitMarket
    function getOrders() external view returns(OrderInfo[] memory) {
        return orders;
    }

    // ----------- INTERNAL FUNCTIONS -----------

    function payForContent(
        address _creator,
        uint256 _contentId
    ) internal returns (uint256 price, uint256 fee) {
        require(
            _getContentInfo[_creator][_contentId].price != 0,
            "OM: CONTENT DOESN'T EXIST"
        );
        require(
            isEligibleUser[msg.sender][_contentId] != true,
            "OM: USER IS ALREADY ELIGIBLE"
        );
        fee = staking.fee();
        price = _getContentInfo[_creator][_contentId].price;
        isEligibleUser[msg.sender][_contentId] = true;

        emit ContentPaid(msg.sender, _contentId);
    }

    function fulfillOrder(
        address _creator,
        uint256 _nftId
    ) internal returns (uint256 price, uint256 fee, address seller) {
        (, address nftAddress) = factory.getCreatorInfo(_creator);
        require(nftAddress != address(0), "OM: NFT DOESN'T EXIST");
        
        uint256 orderId = getOrderId[_creator][_nftId];
        OrderInfo memory order = orders[orderId];
        deleteOrder(_creator, _nftId, orderId);

        require(order.price != 0, "OM: ORDER DOESN'T EXIST");

        IOrbitNFT nft = IOrbitNFT(nftAddress);
        fee = staking.fee();
        price = order.price;
        seller = order.seller; 

        nft.safeTransferFrom(address(this), msg.sender, _nftId);
        emit OrderFulfilled(msg.sender, order.creator, order.nftId);
    }

    function deleteOrder(
        address _creator,
        uint256 _nftId,
        uint256 _orderId
    ) internal {
        OrderInfo memory lastOrder = orders[orders.length - 1];
        getOrderId[lastOrder.creator][lastOrder.nftId] = _orderId;

        delete getOrderId[_creator][_nftId];

        orders[_orderId] = lastOrder;
        orders[_orderId].orderId = _orderId;
        orders.pop();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IOrbitNFT.sol";

/// @title Orbit NFT
/// @notice Basic access NFT token for a content creator's subscription
contract OrbitNFT is IOrbitNFT, ERC721, ERC721Enumerable, ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    /// @inheritdoc IOrbitNFT
    mapping(uint256 => uint256) public tierSupply;
    /// @inheritdoc IOrbitNFT
    mapping(uint256 => uint256) public expiresAt;
    /// @inheritdoc IOrbitNFT
    mapping(uint256 => uint256) public getTier;
    /// @inheritdoc IOrbitNFT
    address public subscription; 
    /// @inheritdoc IOrbitNFT
    address public owner; 
    string private baseUri;

    modifier onlySubscription() {
        require(msg.sender == subscription, "ONFT: NOT THE SUBSCRIPTION CONTRACT");
        _;
    }

    /// @notice NFT constructor
    /// @param _owner content creator address
    /// @param _subscription subscription contract address
    /// @param _baseUri token URI
    constructor(address _owner, address _subscription, string memory _baseUri) ERC721("OrbitNFT", "ONFT") {
        owner = _owner;
        subscription = _subscription;    
        baseUri = _baseUri;
    }

    /// @inheritdoc IOrbitNFT
    function mint(address _to, uint256 _tier, uint256 _duration) external onlySubscription returns(uint256, uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        uint256 expiry = block.timestamp + _duration;

        tierSupply[_tier] += 1;
        expiresAt[tokenId] = expiry;
        getTier[tokenId] = _tier;

        _safeMint(_to, tokenId);
        string memory uri = string(abi.encodePacked("tier", Strings.toString(_tier)));
        _setTokenURI(tokenId, uri);

        return (tokenId, expiry);
    }

    /// @inheritdoc IOrbitNFT
    function updateDuration(uint256 _tokenId,  uint256 _duration) external onlySubscription returns(uint256) {
        uint256 expiry = expiresAt[_tokenId];
        uint256 newExpiry = expiry > block.timestamp ? expiry + _duration : block.timestamp + _duration; 
        expiresAt[_tokenId] = newExpiry;
        return newExpiry;
    }

    function _baseURI() internal view override returns(string memory) {
        return baseUri;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

   /// @notice Getter for a token's URI
   /// @param tokenId token's id
   /// @return URI in format <base URI>/<subscription tier>, e.g. https://mytoken.com/tier1
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ISwapperOracle.sol";
import "./interfaces/IWrappy.sol";

// This contract uses time-weighted average price to quote uniswap pools and convert prices from USD to ETH
contract PaymentProcessor {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWrappy;

    // Uniswap pool settings
    uint24 private constant POOL_FEE_TIER = 500;
    uint24 private constant PRICE_TIME_PERIOD_SEC = 10;
    uint24 private constant PCT_DIV = 100;
    
    IERC20 public USD;
    IWrappy public WETH;
    ISwapperOracle public swapperOracle;
    
    constructor(
        address _usdCoin,
        address _WETH,
        address _swapperOracle
    ) {
        require(_swapperOracle != address(0), "PP: ORACLE CANT'T BE ZERO ADDRESS");
        require(_usdCoin != address(0), "PP: USD CANT'T BE ZERO ADDRESS");
        require(_WETH != address(0), "PP: WETH CANT'T BE ZERO ADDRESS");

        USD = IERC20(_usdCoin);
        WETH = IWrappy(_WETH);
        swapperOracle = ISwapperOracle(_swapperOracle);
    }
    // If user wants to pay for the Orbit services with ETH
    // 1. He transfers ETH to the contract
    // 2. Contract checks that received ETH amount is equal to the base price + fees
    // 3. In order to do that we quote Uniswap WETH/USD pool
    // 4. Received ETH is wrapped
    function processPaymentETH(uint256 initialPriceUSD, uint256 fee) internal returns(uint256 initialPriceETH, uint256 feeETH) {
        // quote USD/ETH price
        (initialPriceETH, ) = swapperOracle.quoteAllAvailablePoolsWithTimePeriod(
            uint128(initialPriceUSD),
            address(USD),
            address(WETH),
            PRICE_TIME_PERIOD_SEC
        ); 
        feeETH = initialPriceETH * fee / PCT_DIV;
        // check msg.value
        require(msg.value >= initialPriceETH + feeETH, "PP: PROVIDED ETH AMOUNT TOO LOW");
        // wrap aquired ETH
        WETH.deposit{value: msg.value}();
    }

    // If user wants to pay for the Orbit services with USD
    // 1. He transfers USD tokens to the contract
    // 2. Contract swaps USD to WETH inside the uniswap WETH/USD pool
    function processPaymentUSD(uint256 initialPriceUSD, uint256 fee) internal returns(uint256 initialPriceETH, uint256 feeETH) {
        // receive payment in USD
        uint256 feeUSD = initialPriceUSD * fee / PCT_DIV;
        // convert USD to WETH
        uint256 paidAmountETH = swapperOracle.swapExactInputSingleHop(
            msg.sender,
            address(USD),
            address(WETH),
            POOL_FEE_TIER,
            initialPriceUSD + feeUSD
        );
        initialPriceETH = paidAmountETH * PCT_DIV / (fee + PCT_DIV);
        feeETH = paidAmountETH - initialPriceETH;
    }
    
    // Send base amount to the payment receiver and fees to the staking
    function distributeReceivedPayment(address baseTo, address feeTo, uint256 baseAmount, uint256 feeAmount) internal {
        WETH.transfer(baseTo, baseAmount);
        WETH.transfer(feeTo, feeAmount);
    } 

    function validatePrice(uint256 price) internal pure {
        if(price == 0) 
            revert("PP: PRICE CAN'T BE ZERO");
    }

    function validatePrices(uint256[] calldata prices) internal pure {
        for(uint256 i=0; i<prices.length; i++) {
            validatePrice(prices[i]);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./PaymentProcessor.sol";
import "./interfaces/ISubscription.sol";

/// @title Subscription
/// @notice Basic subscription contract produced by the Orbit Factory
contract Subscription is ISubscription, PaymentProcessor, ReentrancyGuard, Initializable {
    Tier[] public tiers;
    /// @inheritdoc ISubscription
    uint256 public subscriptionDuration;
    /// @inheritdoc ISubscription
    address public subscriptionFactory;

    /// @inheritdoc ISubscription
    IOrbitNFT public nft;
    /// @inheritdoc ISubscription
    IStaking public staking;

    /// @inheritdoc ISubscription
    address public owner;

    /// @notice Subscription constructor
    /// @param _owner content creator address
    /// @param _staking staking address
    /// @param _swapperOracle oracle address
    /// @param _usdCoin USD stablecoin address
    /// @param _WETH wrapped ethereum address
    constructor(
        address _owner,
        address _staking,
        address _swapperOracle,
        address _usdCoin,
        address _WETH
    ) PaymentProcessor(_usdCoin, _WETH, _swapperOracle) {
        owner = _owner;
        staking = IStaking(_staking);
    }

    /// @inheritdoc ISubscription
    function initialize(address _nft, uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration) external initializer {
        require(_prices.length == _limits.length, "SUB: ARRAYS SIZE DOESN'T MATCH");
        require(_prices.length > 0, "SUB: PLEASE CREATE AT LEAST ONE TIER");

        nft = IOrbitNFT(_nft);

        for(uint256 i=0; i<_prices.length; i++){
            tiers.push(Tier({
                price: _prices[i],
                subscribersLimit: _limits[i]
            }));
        }
        subscriptionDuration = _duration;
    }

    // ----------- SUBSCRIPTION FUNCTIONS -----------

    /// @inheritdoc ISubscription
    function payForSubscriptionWithETH(uint256 tier) external payable nonReentrant{
        (uint256 price, uint256 fee) = subscribeTo(tier);
        (uint256 toCreatorETH, uint256 toStakingETH) = processPaymentETH(price, fee);
        distributeReceivedPayment(owner, address(staking), toCreatorETH, toStakingETH);
    }

    /// @inheritdoc ISubscription
    function payForSubscriptionWithUSD(uint256 tier) external nonReentrant{
        (uint256 price, uint256 fee) = subscribeTo(tier);
        (uint256 toCreatorETH, uint256 toStakingETH) = processPaymentUSD(price, fee);
        distributeReceivedPayment(owner, address(staking), toCreatorETH, toStakingETH);
    }

    /// @inheritdoc ISubscription
    function renewSubscriptionWithETH(uint256 id) external payable nonReentrant{
        (uint256 price, uint256 fee) = renewSubscription(id);
        (uint256 toCreatorETH, uint256 toStakingETH) = processPaymentETH(price, fee);
        distributeReceivedPayment(owner, address(staking), toCreatorETH, toStakingETH);
    }

    /// @inheritdoc ISubscription
    function renewSubscriptionWithUSD(uint256 id) external nonReentrant{
        (uint256 price, uint256 fee) = renewSubscription(id);
        (uint256 toCreatorETH, uint256 toStakingETH) = processPaymentUSD(price, fee);
        distributeReceivedPayment(owner, address(staking), toCreatorETH, toStakingETH);
    }

    // ----------- VIEW -----------

    /// @inheritdoc ISubscription
    function getTiers() external view returns(Tier[] memory) {
        return tiers;
    }

    /// @inheritdoc ISubscription
    function getSubscribersLimit(uint256 tier) external view returns(uint256) {
        return tiers[tier].subscribersLimit;
    }

    // ----------- INTERNAL -----------

    function subscribeTo(uint256 tier) internal returns(uint256, uint256) {
        require(tiers.length > tier, "SUB: TIER DOES NOT EXIST");
        Tier memory tierInfo = tiers[tier];
        uint256 fee = staking.fee();

        if(tierInfo.subscribersLimit != 0 && nft.tierSupply(tier) == tierInfo.subscribersLimit){
            revert("SUB: TIER LIMIT EXCEEDED");
        }

        (uint256 tokenId, uint256 expiresAt) = nft.mint(msg.sender, tier, subscriptionDuration);
        emit SubscribedTo(msg.sender, tier, expiresAt, tokenId);
        return(tierInfo.price, fee);
    }

    function renewSubscription(uint256 id) internal returns(uint256, uint256) {
        require(msg.sender == nft.ownerOf(id), "SUB: NOT THE TOKEN OWNER");

        uint256 tier = nft.getTier(id);
        Tier memory tierInfo = tiers[tier];
        uint256 fee = staking.fee();

        uint256 expiresAt = nft.updateDuration(id, subscriptionDuration);  

        emit SubscriptionRenewed(msg.sender, tier, expiresAt, id);
        return(tierInfo.price, fee);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IStaking.sol";

/// @title Factory interface
/// @notice Interface for the factory contract
interface IOrbitFactory {
    /// @notice Creator structure, contains information on content creator
    /// @param subscription subscription contract address
    /// @param accessNFT address for NFT that is used to access the creator's content
    struct Creator {
        address subscription;
        address accessNFT;
    }

    /// @notice New contracts event
    /// @dev Event is triggered when content creator uses factory to create subscription and NFT contracts
    /// @param creator content creator address
    /// @param tiersCount amount of tiers in subscription
    /// @param subscriptionDuration subscription duration in seconds (e.g. 60*60*24*30 ~ 1 month)
    /// @param subscription subscription contract address
    /// @param nft access token address
    event SubscriptionCreated(address indexed creator, uint256 tiersCount, uint256 subscriptionDuration, address indexed subscription, address indexed nft);

    /// @notice New price event
    /// @dev Event is triggered when factory owner sets a new price for contracts creation
    /// @param _newPriceUSD new price in USD
    event NewPrice(uint256 _newPriceUSD);

    /// @notice Contracts creation with ETH
    /// @dev Will create subscription and NFT contracts with specified parameters for a content creator.
    /// User pays ETH equivalent of the USD price for a contracts creation + fees (ETH/USD is quoted by the oracle), 
    /// then price and fee amounts (in WETH tokens) are transfered to the factory owner and staking addresses respectively.
    /// Content creator address is placed into the creators list. 
    /// @param _prices array of prices for each tier (e.g. 100 * 10^6, 120 * 10^6, 140 * 10^6 for a 3 tiers subscription)
    /// @param _limits array of max users for each tier 
    /// for example 0, 0, 100 for 3 tiers subscription, means that first two tiers are unlimited, while third tier can only have 100 subscribers
    /// @param _duration subscription duration in seconds (e.g. 60*60*24*30 ~ 1 month)
    /// @param _baseUri URI of the NFT
    function createSubscriptionWithETH(uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration, string memory _baseUri) external payable;

    /// @notice Contracts creation with USD
    /// @dev Will create subscription and NFT contracts with specified parameters for a content creator.
    /// User pays price of the contracts creation + fees in USD tokens, then USD is swapped to WETH via Uniswap and transfered to the staking (fee) and to the factory owner (price) 
    /// Content creator address is placed into the creators list. 
    /// @param _prices array of prices for each tier (e.g. 100 * 10^6, 120 * 10^6, 140 * 10^6 for a 3 tiers subscription)
    /// @param _limits array of max users for each tier 
    /// for example 0, 0, 100 for 3 tiers subscription, means that first two tiers are unlimited, while third tier can only have 100 subscribers
    /// @param _duration subscription duration in seconds (e.g. 60*60*24*30 ~ 1 month)
    /// @param _baseUri URI of the NFT
    function createSubscriptionWithUSD(uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration, string memory _baseUri) external;

    /// @notice Setter for a contracts creation price via factory
    /// @dev Price must be >0. Can only be called by the factory owner.
    /// @param _newPriceUSD new price in USD
    function setNewPrice(uint256 _newPriceUSD) external;

    /// @notice Getter for a current contracts creation price
    /// @return price in USD
    function priceUSD() external view returns(uint256);

    /// @notice Getter for a creators list
    /// @return array of content creator addresses that interacted with factory through all it's history
    function getCreators() external view returns(address[] memory);

    /// @notice Getter for a content creator info (subscription and NFT addresses)
    /// @param creator content creator address
    /// @return subscription subscription address
    /// @return accessNFT NFT address
    function getCreatorInfo(address creator) external view returns(address subscription, address accessNFT);

    /// @notice Staking address
    /// @return staking address
    function staking() external view returns(IStaking);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IStaking.sol";
import "../OrbitFactory.sol";

/// @title Orbit market interface
/// @notice Interface for the Orbit market
interface IOrbitMarket {
    /// @notice Content info structure, contains information on selling content 
    /// @param url content URL 
    /// @param price for the content in USD
    struct ContentInfo {
        string url;
        uint256 price;
    }

    /// @notice Order info strucuture, contains information on NFT trade offer
    /// @param orderId order id
    /// @param seller NFT seller address
    /// @param creator content creator address of the token being sold
    /// @param nftId id of the NFT being sold
    /// @param price offer price in USD
    struct OrderInfo {
        uint256 orderId;
        address seller;
        address creator;
        uint256 nftId;
        uint256 price;
    }

    /// @notice New content offer event
    /// @dev Event is triggered when content creator creates individual content sale offer
    /// @param creator content creator address
    /// @param contentId content id in content list
    /// @param price for individual content in USD
    event ContentCreated(address indexed creator, uint256 contentId, uint256 price);

    /// @notice New content price event
    /// @dev Event is triggered when content creator changes the price for the individual content sale offer
    /// @param creator content creator address
    /// @param contentId content id in content list
    /// @param _newPriceUSD new price for individual content in USD
    event NewContentPrice(address indexed creator, uint256 contentId, uint256 _newPriceUSD);

    /// @notice Content purchase event
    /// @dev Event is triggered when user buys the individual content
    /// @param buyer content buyer address
    /// @param contentId content id in content list
    event ContentPaid(address indexed buyer, uint256 contentId);

    /// @notice New market order creation event
    /// @dev Event is triggered when seller puts his NFT for sale
    /// @param seller token seller address
    /// @param creator token creator address
    /// @param nftId id of the token being sold
    /// @param price price for the NFT
    /// @param orderId order id in the order book
    event OrderCreated(address indexed seller, address indexed creator, uint256 nftId, uint256 price, uint256 orderId);

    /// @notice Order cancellation event
    /// @dev Event is triggered when seller cancels his order
    /// @param seller token seller address
    /// @param creator token creator address
    /// @param nftId id of the token being sold
    /// @param orderId order id in the order book
    event OrderCancelled(address indexed seller, address indexed creator, uint256 nftId, uint256 orderId);

    /// @notice Order fulfillment event
    /// @dev Event is triggered when NFT sale order is fulfilled
    /// @param buyer content buyer address
    /// @param creator token creator address
    /// @param nftId id of the token being sold
    event OrderFulfilled(address indexed buyer, address indexed creator, uint256 nftId);

    /// @notice Individual content purchase with ETH
    /// @dev Will add user to the list of eligible users for the specified {_contentId} made by the {_creator}.
    /// User pays ETH equivalent of the USD price for a content + fees (ETH/USD is quoted by the oracle), 
    /// then price and fee amounts (in WETH tokens) are transfered to the content creator and staking addresses respectively.
    /// @param _creator content creator address whose content user is purchasing
    /// @param _contentId content id in the content list
    function payForContentWithETH(address _creator, uint256 _contentId) external payable;

    /// @notice Individual content purchase with USD
    /// @dev Will add user to the list of eligible users for the specified {_contentId} made by the {_creator}.
    /// User pays price of the content + fees in USD tokens, then USD is swapped to WETH via Uniswap and transfered to the staking (fee) and to the content creator (price) 
    /// then price and fee amounts (in WETH tokens) are transfered to the content creator and staking addresses respectively.
    /// @param _creator content creator address whose content user is purchasing
    /// @param _contentId content id in the content list
    function payForContentWithUSD(address _creator, uint256 _contentId) external;

    /// @notice Create individual content offer
    /// @dev Content creator can sell his individual content with this function. After specifiying content URL and price offer is put inside content list and assigned unique id
    /// @param _contentUrl URL of the content
    /// @param _price individual content price (e.g. 100 * 10^6 = 100 USD)
    function createContent(string calldata _contentUrl, uint256 _price) external;

    /// @notice Changes price for the individual content
    /// @dev Content creator can change price for his content with this function
    /// @param _contentId content id in the content list
    /// @param _newPrice new content price (e.g. 100 * 10^6 = 100 USD)
    function setContentPrice(uint256 _contentId, uint256 _newPrice) external;
    
    /// @notice Getter for all content that {_creator} is selling
    /// @dev Returns array of individual content numbers for a specified creator address
    /// @param _creator content creator address
    /// @return allCreatorContentIds array of content ids 
    function getAllCreatorContentIds(address _creator) external view returns(uint256[] memory allCreatorContentIds);

    /// @notice Getter for a content information
    /// @dev Returns URL and price for a specified {_contentId} of the {_creator}
    /// @param _creator content creator address
    /// @param _contentId content id in the content list
    /// @return contentInfo content info - URL and price in USD
    function getContentInfo(address _creator, uint256 _contentId) external view returns(ContentInfo memory contentInfo);

    /// @notice Checks if user can access individual content with {contentId}
    /// @dev Can be used in access control for the creator individual content
    /// @param user wallet address
    /// @param contentId content id in the content list
    /// @return true - user has paid for the individual content and can access it, false - access denied
    function isEligibleUser(address user, uint256 contentId) external view returns(bool);

    /// @notice Creates sell order for the token with {_nftId} that grants subscription to {_creator}
    /// @dev Will creater sell order for the NFT and put it in the order book. NFT is transfered from the seller to the market contract address.
    /// @param _creator content creator address whose NFT subscription is being sold
    /// @param _nftId id of the token being sold
    /// @param _price NFT price (e.g. 100 * 10^6 = 100 USD)
    function createOrder(address _creator, uint256 _nftId, uint256 _price) external;

    /// @notice Cancels sell order for the token with {_nftId} that grants subscription to {_creator}
    /// @dev Will cancel sell order for the NFT and remove it from the order book. NFT is transfered back to the seller address.
    /// @param _creator content creator address whose NFT subscription is being sold
    /// @param _nftId id of the token being sold
    function cancelOrder(address _creator, uint256 _nftId) external;

    /// @notice Purchase NFT from the seller with ETH
    /// @dev Will match orders and transfer seller's NFT to the buyer. Fulfilled order will be removed from the order book.
    /// User pays ETH equivalent of the USD price for a token + fees (ETH/USD is quoted by the oracle), 
    /// then price and fee amounts (in WETH tokens) are transfered to the token seller and staking addresses respectively.
    /// @param _creator content creator address whose NFT subscription is being sold
    /// @param _nftId id of the token being sold
    function buyOrderWithETH(address _creator, uint256 _nftId) external payable;

    /// @notice Purchase NFT from the seller with USD
    /// @dev Will match orders and transfer seller's NFT to the buyer. Fulfilled order will be removed from the order book.
    /// User pays price of the token + fees in USD tokens, then USD is swapped to WETH via Uniswap and transfered to the staking (fee) and to the token seller (price) 
    /// @param _creator content creator address whose NFT subscription is being sold
    /// @param _nftId id of the token being sold
    function buyOrderWithUSD(address _creator, uint256 _nftId) external;

    /// @notice Getter for all orders created on this market
    /// @dev Returns the order book which contains information on all current orders
    /// @return array of OrderInfo structs see OrderInfo
    function getOrders() external view returns(OrderInfo[] memory);

    /// @notice Getter for the order id
    /// @dev Returns order position inside the order book
    /// @param _creator content creator address whose NFT subscription is being sold
    /// @param _nftId id of the token being sold
    /// @return order id with which we can request info from the order book
    function getOrderId(address _creator, uint256 _nftId) external view returns(uint256);

    /// @notice Getter for the order info - seller, NFT id, price etc
    /// @dev Returns order information from the order book
    /// @param orderId order position inside the book, can be retrieved with getOrderId
    /// @return orderId order position inside the order book
    /// @return seller seller address
    /// @return creator creator address
    /// @return nftId id of the token being sold
    /// @return price price of the token in USD
    function orders(uint256 _orderId) external view returns(uint256 orderId, address seller, address creator, uint256 nftId, uint256 price);

    /// @notice Staking address
    /// @return staking address
    function staking() external view returns(IStaking);

    /// @notice Factory address
    /// @return factory address
    function factory() external view returns(OrbitFactory);
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma solidity ^0.8.0;

/// @title Orbit NFT interface
/// @notice Interface for the Orbit access token
interface IOrbitNFT is IERC721 {

   /// @notice Getter for a tier supply
   /// @dev Returns amount of minted tokens for a specified tier. Used in max supply check for limited tokens.
   /// @param tier subscription tier
   /// @return amount of minted tokens
   function tierSupply(uint256 tier) external view returns(uint256); 

   /// @notice Getter for a token's tier
   /// @dev Returns subscription tier that is token with {id} gives access to. Can be used in access control.
   /// @param id token id
   /// @return subscription tier
   function getTier(uint256 id) external view returns(uint256); 

   /// @notice Mints token for a {to} address with specified {tier} and duration.
   /// @dev Only subscription contract can call this function.
   /// @param to address of the receiver
   /// @param tier subscription tier
   /// @param expiresAt date of token's expiry in UNIX format (mint date + subscription duration)
   /// @return minted token's id
   /// @return token's expiry date in UNIX format
   function mint(address to, uint256 tier, uint256 expiresAt) external returns(uint256, uint256); 

   /// @notice Extends the subscription duration of the token {id}
   /// @dev Only subscription contract can call this function. Adds {duration} amount of seconds to token's expiry time
   /// OR current time is token is already expired
   /// @param id token id
   /// @param duration subscription duration in seconds
   /// @return new expiry date in UNIX format
   function updateDuration(uint256 id, uint256 duration) external returns(uint256); 

   /// @notice Getter for a token's expiry date
   /// @param id token's id
   /// @return token's expiry date in UNIX format
   function expiresAt(uint256 id) external view returns(uint256);

   /// @notice Getter for a subscription contract address
   /// @return subscription address to which the token provides access
   function subscription() external view returns(address);

   /// @notice NFT contract owner
   /// @return owner's address (content creator)
   function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20Burnable.sol";

/// @title Orbit staking interface
/// @notice Interface for the staking contract
interface IStaking {
   /// @notice Staking periods enumeration
   /// @param A pool A duration
   /// @param B pool B duration
   /// @param C pool C duration
   enum StakingPeriod {
      A,
      B,
      C
   }

   /// @notice User stake info struct
   /// @param staked amount of tokens staked
   /// @param rewardPerTokenPaid claimed reward
   /// @param reward awailable reward
   /// @param expiredAt unlock date in UNIX time
   struct Stake{
      uint256 staked;
      uint256 rewardPerTokenPaid;
      uint256 reward;
      uint256 expiredAt;
   }

   /// @notice Pool info struct
   /// @param duration lock duration in seconds
   /// @param rewardPercent percentage of all collected fees that goes to the pool
   /// @param rewardPerTokenStored sum of (reward * 1e18 / total stakes) 
   /// @param totalStakes total amount of staked tokens
   /// @param reward total reward to be distributed to stakers
   struct StakingPool{
      uint256 duration;
      uint8 rewardPercent;
      uint256 rewardPerTokenStored;
      uint256 totalStakes;
      uint256 reward;
   }

   /// @notice New stake added by the user
   /// @dev Event is triggered when user stakes his tokens.
   /// @param stakeholder staker address
   /// @param amount amount of tokens staked
   /// @param period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
   /// @param expiredAt stake unlock date in UNIX format
   event StakeAdded(
      address indexed stakeholder,
      uint256 amount,
      StakingPeriod period,
      uint256 expiredAt
  );

  /// @notice Staked tokens withdrawn by the user
  /// @dev Event is triggered when user withdraws his staked tokens
  /// @param stakeholder staker address
  /// @param amount amount of tokens withdrawn
  /// @param penaltyAmount amount of staking tokens burnes as a penalty if withdrawn before unlock date
  /// @param period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  event StakeWithdrawn(
      address indexed stakeholder,
      uint256 amount,
      uint256 penaltyAmount,
      StakingPeriod period
  );

  /// @notice Reward is claimed by the user
  /// @dev Event is triggered when user claims rewards for his stake
  /// @param stakeholder staker address
  /// @param amount reward amount
  /// @param period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  event RewardClaimed(
      address indexed stakeholder,
      uint256 amount,
      StakingPeriod period
  );

  /// @notice Getter for fee amount
  /// @return fee percentage for the operations with Orbit contracts (default 7%)
  function fee() external view returns(uint256); 

  /// @notice Setter for the staking token
  /// @dev Sets new staking token address. Only callable by the owner.
  /// @param _stakingToken new staking token address
  function setStakingToken(address _stakingToken) external;

  /// @notice Setter for the Orbit contracts fee
  /// @dev Sets new fee for purchasing subscriptions, content and NFTs. Must be >0 and <100. Only callable by the owner.
  /// @param _newFee new fee %
  function setFee(uint8 _newFee) external;

  /// @notice Distributes collected fee to the staking pools
  /// @dev Only callable by the owner. Distributes collected reward tokens between pools according to their percentage.
  /// for example we collected 1000 tokens from the fees
  /// pool A will receive 200 tokens
  /// pool B will receive 350 tokens
  /// pool C will receive 450 tokens
  /// @param _amount amount of tokens to distribute, must be <= total collected fees amount on the contract
  function distributeFees(uint256 _amount) external;

  /// @notice Withdraw collected fees to the owner address
  /// @dev Owner can withdraw fees accumulated by the staking to his wallet. Only callable by the owner.
  /// @param _amount amount of reward tokens to withdraw from staking address
  function claimFees(uint256 _amount) external;

  /// @notice Getter for the reward awailable to the staker
  /// @dev Returns weighted reward of a user for the specified pool
  /// @param _account staker address
  /// @param _period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  function earned(address _account, StakingPeriod _period) external view returns (uint256);

  /// @notice Stake tokens to a specified pool
  /// @dev User stakes his tokens for a period of time specified for the pool in exchange for a reward in future.
  /// @param _stakeAmount amount of tokens to stake
  /// @param _period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  function stake(uint256 _stakeAmount, StakingPeriod _period) external;

  /// @notice Withdraw tokens from a specified pool
  /// @dev User withdraws his tokens from the pool. If he withdraws before the unlock date part of his tokens are burned as a penalty.
  /// @param _period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  function withdraw(StakingPeriod _period) external;

  /// @notice Claim reward from a pool
  /// @dev Transfers reward to a user if he has any.
  /// @param _period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  function claimReward(StakingPeriod _period) external;

  /// @notice Total reward supply of the staking
  /// @return reward tokens amount awailable for distribution to pools
  function collectedFees() external view returns(uint256);

  /// @notice Getter for a user stake info
  /// @param account user address
  /// @param period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  /// @return staked amount of tokens staked
  /// @return rewardPerTokenPaid claimed reward
  /// @return reward awailable reward
  /// @return expiredAt unlock date in UNIX time
  function stakeHolderToStake(address account, StakingPeriod period) external view returns(
      uint256 staked,
      uint256 rewardPerTokenPaid,
      uint256 reward,
      uint256 expiredAt
  );

  /// @notice Getter for a pool info
  /// @param period lock duration (0 - pool A duration, 1 - pool B duration, 2 - pool C duration)
  /// @return duration lock duration in seconds
  /// @return rewardPercent percentage of all collected fees that goes to the pool
  /// @return rewardPerTokenStored sum of (reward * 1e18 / total stakes) 
  /// @return totalStakes total amount of staked tokens
  /// @return reward total reward to be distributed to stakers
  function stakePeriodToPool(StakingPeriod period) external view returns(
      uint256 duration,
      uint8 rewardPercent,
      uint256 rewardPerTokenStored,
      uint256 totalStakes,
      uint256 reward
  );

  /// @notice Staking token address
  /// @return Staking token address
  function stakingToken() external view returns(IERC20Burnable);

  /// @notice Reward token address
  /// @return Reward token address
  function rewardToken() external view returns(IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOrbitNFT.sol";
import "./IStaking.sol";

/// @title Subscription interface
/// @notice Interface for the subscription contract
interface ISubscription {
    /// @notice Tier structure, contains information on subscription tier
    /// @dev Tiers are assigned inside the factory during initialization of the subscription
    /// @param price tier price in USD (e.g. 100 * 10^6 = $100)
    /// @param subscribersLimit max amount of subscribers for the tier, if 0 we assume there is no limit 
    struct Tier {
        uint256 price; //Price should be listed in USD !!!
        uint256 subscribersLimit;
    }

    /// @notice New subscription event
    /// @dev Event is triggered when user buys a new subscription
    /// @param subscriber address of the subscriber
    /// @param tier acquired subscription tier
    /// @param expiresAt expiry time for the aquired subscription in UNIX format
    /// @param id subscription token id
    event SubscribedTo(address indexed subscriber, uint256 tier, uint256 expiresAt, uint256 id);

    /// @notice Subscription renewal address
    /// @dev Event is triggered when user renews existing subscription
    /// @param subscriber address of the subscriber
    /// @param tier subscription tier
    /// @param expiresAt expiry time for the subscription in UNIX format
    /// @param id subscription token id
    event SubscriptionRenewed(address indexed subscriber, uint256 tier, uint256 expiresAt, uint256 id);

    /// @notice Subscription contract initialization, configures the contract tiers and duration
    /// @dev Called once inside the factory during the subscription creation
    /// @param _nft NFT token contract address
    /// @param _prices array of prices for each tier (e.g. 100 * 10^6, 120 * 10^6, 140 * 10^6 for a 3 tiers subscription)
    /// @param _limits array of max users for each tier 
    /// for example 0, 0, 100 for 3 tiers subscription, means that first two tiers are unlimited, while third tier can only have 100 subscribers
    /// @param _duration subscription duration in seconds (e.g. 60*60*24*30 ~ 1 month)
    function initialize(address _nft, uint256[] calldata _prices, uint256[] calldata _limits, uint256 _duration) external;

    /// @notice Buys subscription with ETH
    /// @dev Will mint NFT token with specified tier and expiry time (block.timestamp + duration) for a user.
    /// User pays ETH equivalent of the USD price for a tier + fees (ETH/USD is quoted by the oracle), 
    /// then price and fee amounts (in WETH tokens) are transfered to the creator and staking addresses respectively 
    /// @param tier Tier that user wishes to acquire
    function payForSubscriptionWithETH(uint256 tier) external payable;

    /// @notice Buys subscription with USD
    /// @dev Will mint NFT token with specified tier and expiry time (block.timestamp + duration) for a user.
    /// User pays price of the tier + fees in USD tokens, then USD is swapped to WETH via Uniswap and transfered to the staking (fee) and to the creator (price) 
    /// @param tier Tier that user wishes to acquire
    function payForSubscriptionWithUSD(uint256 tier) external;

    /// @notice Renews existing subscription with ETH
    /// @dev Extends {id} token adding {duration} amount to it's expiry time OR to block.timestamp if we are past the expiry date.
    /// Will revert if user doesn't have a token with specified id. 
    /// Payment process is the same as in the subscription purchase with ETH
    /// @param id NFT token id which user wishes to renew
    function renewSubscriptionWithETH(uint256 id) external payable;

    /// @notice Renews existing subscription with USD
    /// @dev Extends {id} token adding {duration} amount to it's expiry time OR to block.timestamp if we are past the expiry date.
    /// Will revert if user doesn't have a token with specified id. 
    /// Payment process is the same as in the subscription purchase with USD
    /// @param id NFT token id which user wishes to renew
    function renewSubscriptionWithUSD(uint256 id) external;

    /// @notice Tiers getter for the subscription
    /// @return array of tier struct with information on each tier (price, max subscribers)
    function getTiers() external view returns(Tier[] memory);

    /// @notice Getter for a subscribers limit
    /// @param tier tier level
    /// @return max subscribers for a specified tier
    function getSubscribersLimit(uint256 tier) external view returns(uint256);

    /// @notice Getter for a subscription duration
    /// @return duration in seconds
    function subscriptionDuration() external view returns(uint256);
    
    /// @notice Orbit factory
    /// @return factory address
    function subscriptionFactory() external view returns(address);

    /// @notice ERC721 access token binded to this subscription
    /// @return NFT token address
    function nft() external view returns(IOrbitNFT);

    /// @notice Staking address
    /// @return staking address
    function staking() external view returns(IStaking);

    /// @notice Owner of the subscription aka content creator
    /// @return content creator address
    function owner() external view returns(address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/// @title Uniswap V3 Swapper Oracle interface
/// @notice Oracle contract interface for calculating price quoting and swapping against Uniswap V3
interface ISwapperOracle {
    /// @notice Returns the address of the Uniswap V3 factory
    /// @dev This value is assigned during deployment and cannot be changed
    /// @return The address of the Uniswap V3 factory
    function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory);

    /// @notice Returns the address of the Uniswap V3 router
    /// @dev This value is assigned during deployment and cannot be changed
    /// @return The address of the Uniswap V3 router
    function UNISWAP_V3_ROUTER() external view returns (ISwapRouter);

    /// @notice Returns all supported fee tiers
    /// @return The supported fee tiers
    function supportedFeeTiers() external view returns (uint24[] memory);

    /// @notice Returns whether a specific pair can be supported by the oracle
    /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
    /// @return Whether the given pair can be supported by the oracle
    function isPairSupported(address tokenA, address tokenB) external view returns (bool);

    /// @notice Returns all existing pools for the given pair
    /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
    /// @return All existing pools for the given pair
    function getAllPoolsForPair(address tokenA, address tokenB) external view returns (address[] memory);

    /// @notice Returns a quote, based on the given tokens and amount, by querying all of the pair's pools
    /// @dev If some pools are not configured correctly for the given period, then they will be ignored
    /// @dev Will revert if there are no pools available/configured for the pair and period combination
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @param period Number of seconds from which to calculate the TWAP
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    /// @return queriedPools The pools that were queried to calculate the quote
    function quoteAllAvailablePoolsWithTimePeriod(
        uint128 baseAmount,
        address baseToken,
        address quoteToken,
        uint32 period
    ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

    /// @notice Adds support for a new fee tier
    /// @dev Will revert if the given tier is invalid, or already supported
    /// @param feeTier The new fee tier to add
    function addNewFeeTier(uint24 feeTier) external;

    /// @notice Swaps an exact amount of ``tokenIn`` for a ``tokenOut`` using given fee tier pool
    /// @param tokenIn Address of token to be swapped
    /// @param tokenOut Address of token we are swapping for
    /// @param poolFee Pool fee tier
    /// @param amountIn Amount of tokens to be swapped
    /// @return amountOut Amount of tokens received
    function swapExactInputSingleHop(
        address from,
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountIn
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWrappy {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}