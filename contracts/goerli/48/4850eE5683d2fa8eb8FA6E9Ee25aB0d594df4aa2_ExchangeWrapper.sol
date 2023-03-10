// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

pragma solidity ^0.8.9;

import "./ExchangeWrapperCore.sol";

contract ExchangeWrapper is ExchangeWrapperCore {
    function __ExchangeWrapper_init(
        address _exchangeV2,
        address _rarible,
        address _seaport_1_4,
        address _seaport_1_1,
        address _x2y2,
        address _looksrare,
        address _sudoswap,
        address _blur
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ExchangeWrapper_init_unchained(_exchangeV2, _rarible, _seaport_1_4, _seaport_1_1, _x2y2, _looksrare, _sudoswap, _blur);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibTransfer.sol";
import "../librairies/BpLibrary.sol";
import "../librairies/LibPart.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IExchangeV2.sol";
import "./interfaces/ISeaPort.sol";
import "./interfaces/Ix2y2.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IBlurExchange.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ISwapRouterV3.sol";
import "./interfaces/ISwapRouterV2.sol";
import "../interfaces/INftTransferProxy.sol";
import "../interfaces/IERC20TransferProxy.sol";

abstract contract ExchangeWrapperCore is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721Holder,
    ERC1155Holder
{
    using LibTransfer for address;
    using BpLibrary for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public exchangeV2;
    address public rarible;
    address public seaport_1_4;
    address public seaport_1_1;
    address public x2y2;
    address public looksrare;
    address public sudoswap;
    address public blur;
    ISwapRouterV2 public uniswapRouterV2;
    ISwapRouterV3 public uniswapRouterV3;
    address public wrappedToken;
    address public erc20TransferProxy;

    // mapping market id <> market erc20 proxy
    mapping(Markets => address) public proxies;

    event Execution(bool result, address indexed sender);

    enum Markets {
        Rarible,
        SeaPort_1_4,
        SeaPort_1_1,
        X2Y2,
        LooksRare,
        SudoSwap,
        ExchangeV2,
        Blur
    }

    enum AdditionalDataTypes {
        NoAdditionalData,
        RoyaltiesAdditionalData
    }

    /**
        @notice struct for the purchase data
        @param marketId - market key from Markets enum (what market to use)
        @param amount - eth price (amount of eth that needs to be send to the marketplace)
        @param paymentToken - payment token required for the order
        @param fees - 2 fees (in base points) that are going to be taken on top of order amount encoded in 1 uint256
                        bytes (27,28) used for dataType
                        bytes (29,30) used for the first value (goes to feeRecipientFirst)
                        bytes (31,32) are used for the second value (goes to feeRecipientSecond)
        @param data - data for market call
     */
    struct PurchaseDetails {
        Markets marketId;
        uint256 amount;
        address paymentToken;
        uint fees;
        bytes data;
    }

    /**
        @notice struct for the data with additional data
        @param data - data for market call
        @param additionalRoyalties - array additional Royalties (in base points plus address Royalty recipient)
     */
    struct AdditionalData {
        bytes data;
        uint[] additionalRoyalties;
    }

    /**
        @notice struct for the swap in v3 data
        @param path - tokenIn
        @param amountOut - amountOut
        @param amountInMaximum - amountInMaximum
        @param unwrap - unwrap
     */
    struct SwapDetailsIn {
        bytes path;
        uint256 amountOut;
        uint256 amountInMaximum;
        bool unwrap;
    }

    /**
        @notice struct for the swap in v2 data
        @param path - tokenIn
        @param amountOut - amountOut
        @param amountInMaximum - amountInMaximum
        @param binSteps - binSteps
        @param unwrap - unwrap
     */
    struct SwapV2DetailsIn {
        address[] path;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint256[] binSteps;
        bool unwrap;
    }

    function __ExchangeWrapper_init_unchained(
        address _exchangeV2,
        address _rarible,
        address _seaport_1_4,
        address _seaport_1_1,
        address _x2y2,
        address _looksrare,
        address _sudoswap,
        address _blur
    ) internal {
        exchangeV2 = _exchangeV2;
        rarible = _rarible;
        seaport_1_4 = _seaport_1_4;
        seaport_1_1 = _seaport_1_1;
        x2y2 = _x2y2;
        looksrare = _looksrare;
        sudoswap = _sudoswap;
        blur = _blur;
    }

    /// @notice Pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Set uniswap v2 router
    function setUniswapV2(ISwapRouterV2 _uniswapRouterV2) external onlyOwner {
        uniswapRouterV2 = _uniswapRouterV2;
    }

    /// @notice Set uniswap v3 router
    function setUniswapV3(ISwapRouterV3 _uniswapRouterV3) external onlyOwner {
        uniswapRouterV3 = _uniswapRouterV3;
    }

    /// @notice Set wrapped token
    function setWrapped(address _wrappedToken) external onlyOwner {
        wrappedToken = _wrappedToken;
    }

    /// @notice Set erc20 transfer proxy
    function setTransferProxy(address _erc20TransferProxy) external onlyOwner {
        erc20TransferProxy = _erc20TransferProxy;
    }

    /// @notice Set erc20 proxy for market
    function setMarketProxy(Markets marketId, address proxy) external onlyOwner {
        proxies[marketId] = proxy;
    }

    /// @notice set seaport 1.4 - temporary to remove
    function setSeaport(address _seaport) external onlyOwner {
        seaport_1_4 = _seaport;
    }

    /**
        @notice executes a single purchase
        @param purchaseDetails - details about the purchase (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
     */
    function singlePurchase(
        PurchaseDetails memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond
    ) external payable whenNotPaused {
        (bool success, uint feeAmountFirst, uint feeAmountSecond) = purchase(purchaseDetails, false);
        emit Execution(success, _msgSender());

        if (purchaseDetails.paymentToken == address(0)) {
            transferFee(feeAmountFirst, feeRecipientFirst);
            transferFee(feeAmountSecond, feeRecipientSecond);
        } else {
            transferFeeToken(purchaseDetails.paymentToken, feeAmountFirst, feeRecipientFirst);
            transferFeeToken(purchaseDetails.paymentToken, feeAmountSecond, feeRecipientSecond);

            transferFeeChange(purchaseDetails.paymentToken);
        }

        transferChange();
    }

    /**
        @notice executes an array of purchases - with swap v2 - tokens for tokens or tokens for eth/weth
        @param purchaseDetails - array of details about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
        @param swapDetails - swapDetails v2
     */

    function bulkPurchaseWithV2Swap(
        PurchaseDetails[] memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond,
        bool allowFail,
        SwapV2DetailsIn memory swapDetails
    ) external payable whenNotPaused {
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];
        // tokens for eth or weth
        if (tokenOut == wrappedToken) {
            bool isSwapExecuted = swapV2TokensForExactETHOrWETH(swapDetails);
            require(isSwapExecuted, "swap not successful");
        }
        // eth or weth for tokens
        else if (tokenIn == wrappedToken) {
            bool isSwapExecuted = swapV2ETHOrWETHForExactTokens(swapDetails);
            require(isSwapExecuted, "swap not successful");
        }
        // tokens for tokens
        else {
            bool isSwapExecuted = swapV2TokensForExactTokens(swapDetails);
            require(isSwapExecuted, "swap not successful");
        }

        bulkPurchase(purchaseDetails, feeRecipientFirst, feeRecipientSecond, allowFail);
    }

    /**
        @notice executes an array of purchases - with swap v3
        @param purchaseDetails - array of details about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
        @param swapDetails - swapDetails v3
     */

    function bulkPurchaseWithSwap(
        PurchaseDetails[] memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond,
        bool allowFail,
        SwapDetailsIn memory swapDetails
    ) external payable whenNotPaused {
        bool isSwapExecuted = swapTokensForExactTokens(swapDetails);
        require(isSwapExecuted, "swap not successful");
        bulkPurchase(purchaseDetails, feeRecipientFirst, feeRecipientSecond, allowFail);
    }

    /**
        @notice executes an array of purchases
        @param purchaseDetails - array of details about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
     */

    function bulkPurchase(
        PurchaseDetails[] memory purchaseDetails,
        address feeRecipientFirst,
        address feeRecipientSecond,
        bool allowFail
    ) public payable whenNotPaused {
        uint sumFirstFees = 0;
        uint sumSecondFees = 0;
        bool result = false;

        uint length = purchaseDetails.length;
        for (uint i; i < length; ++i) {
            (bool success, uint firstFeeAmount, uint secondFeeAmount) = purchase(purchaseDetails[i], allowFail);

            result = result || success;
            emit Execution(success, _msgSender());

            if (purchaseDetails[i].paymentToken == address(0)) {
                sumFirstFees = sumFirstFees + (firstFeeAmount);
                sumSecondFees = sumSecondFees + (secondFeeAmount);
            }
            // erc20 fees transferred right after each purchase to avoid having to store total
            else {
                transferFeeToken(purchaseDetails[i].paymentToken, firstFeeAmount, feeRecipientFirst);
                transferFeeToken(purchaseDetails[i].paymentToken, secondFeeAmount, feeRecipientSecond);
            }
        }

        require(result, "no successful executions");

        transferFee(sumFirstFees, feeRecipientFirst);
        transferFee(sumSecondFees, feeRecipientSecond);

        transferFeeChange(purchaseDetails);
        transferChange();
    }

    /**
        @notice executes one purchase
        @param purchaseDetails - details about the purchase
        @param allowFail - true if errors are handled, false if revert on errors
        @return result false if execution failed, true if succeded
        @return firstFeeAmount amount of the first fee of the purchase, 0 if failed
        @return secondFeeAmount amount of the second fee of the purchase, 0 if failed
     */
    function purchase(PurchaseDetails memory purchaseDetails, bool allowFail) internal returns (bool, uint, uint) {
        (bytes memory marketData, uint[] memory additionalRoyalties) = getDataAndAdditionalData(
            purchaseDetails.data,
            purchaseDetails.fees,
            purchaseDetails.marketId
        );

        uint nativeAmountToSend = purchaseDetails.amount;

        (uint firstFeeAmount, uint secondFeeAmount) = getFees(purchaseDetails.fees, purchaseDetails.amount);

        // purchase with ERC20
        if (purchaseDetails.paymentToken != address(0)) {
            // Set native value to 0 for ERC20
            nativeAmountToSend = 0;

            // Check balance in contract as there might be some from swap
            uint currentBalance = IERC20Upgradeable(purchaseDetails.paymentToken).balanceOf(address(this));

            // set token value to amount + fees
            uint tokenAmountToSend = purchaseDetails.amount + firstFeeAmount + secondFeeAmount;

            // Move tokenIn to contract and move what's missing if any
            if (tokenAmountToSend > currentBalance) {
                IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                    IERC20Upgradeable(purchaseDetails.paymentToken),
                    _msgSender(),
                    address(this),
                    tokenAmountToSend - currentBalance
                );
            }

            // Approve tokenIn on market proxy
            address marketProxy = getMarketProxy(purchaseDetails.marketId);
            uint256 allowance = IERC20Upgradeable(purchaseDetails.paymentToken).allowance(marketProxy, address(this));
            if (allowance < tokenAmountToSend) {
                IERC20Upgradeable(purchaseDetails.paymentToken).approve(address(marketProxy), type(uint256).max);
            }
        }

        if (purchaseDetails.marketId == Markets.SeaPort_1_1) {
            (bool success, ) = address(seaport_1_1).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase SeaPort_1_1 failed");
            }
        }
        else if (purchaseDetails.marketId == Markets.SeaPort_1_4) {
            (bool success, ) = address(seaport_1_4).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase SeaPort_1_4 failed");
            }
        }
        else if (purchaseDetails.marketId == Markets.ExchangeV2) {
            (bool success, ) = address(exchangeV2).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase GhostMarket failed");
            }
        } else if (purchaseDetails.marketId == Markets.Rarible) {
            (bool success, ) = address(rarible).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase Rarible failed");
            }
        } else if (purchaseDetails.marketId == Markets.X2Y2) {
            Ix2y2.RunInput memory input = abi.decode(marketData, (Ix2y2.RunInput));

            if (allowFail) {
                try Ix2y2(x2y2).run{value: nativeAmountToSend}(input) {} catch {
                    return (false, 0, 0);
                }
            } else {
                Ix2y2(x2y2).run{value: nativeAmountToSend}(input);
            }

            // for every element in input.details[] getting
            // order = input.details[i].orderIdx
            // and from that order getting item = input.details[i].itemId
            uint length = input.details.length;
            for (uint i; i < length; ++i) {
                uint orderId = input.details[i].orderIdx;
                uint itemId = input.details[i].itemIdx;
                bytes memory data = input.orders[orderId].items[itemId].data;
                {
                    if (input.orders[orderId].dataMask.length > 0 && input.details[i].dataReplacement.length > 0) {
                        _arrayReplace(data, input.details[i].dataReplacement, input.orders[orderId].dataMask);
                    }
                }

                // 1 = erc-721
                if (input.orders[orderId].delegateType == 1) {
                    Ix2y2.Pair721[] memory pairs = abi.decode(data, (Ix2y2.Pair721[]));

                    for (uint256 j = 0; j < pairs.length; j++) {
                        Ix2y2.Pair721 memory p = pairs[j];
                        IERC721Upgradeable(address(p.token)).safeTransferFrom(address(this), _msgSender(), p.tokenId);
                    }
                } else if (input.orders[orderId].delegateType == 2) {
                    // 2 = erc-1155
                    Ix2y2.Pair1155[] memory pairs = abi.decode(data, (Ix2y2.Pair1155[]));

                    for (uint256 j = 0; j < pairs.length; j++) {
                        Ix2y2.Pair1155 memory p = pairs[j];
                        IERC1155Upgradeable(address(p.token)).safeTransferFrom(
                            address(this),
                            _msgSender(),
                            p.tokenId,
                            p.amount,
                            ""
                        );
                    }
                } else {
                    revert("unknown delegateType x2y2");
                }
            }
        } else if (purchaseDetails.marketId == Markets.LooksRare) {
            (LibLooksRare.TakerOrder memory takerOrder, LibLooksRare.MakerOrder memory makerOrder, bytes4 typeNft) = abi
                .decode(marketData, (LibLooksRare.TakerOrder, LibLooksRare.MakerOrder, bytes4));
            if (allowFail) {
                try
                    ILooksRare(looksrare).matchAskWithTakerBidUsingETHAndWETH{value: nativeAmountToSend}(
                        takerOrder,
                        makerOrder
                    )
                {} catch {
                    return (false, 0, 0);
                }
            } else {
                ILooksRare(looksrare).matchAskWithTakerBidUsingETHAndWETH{value: nativeAmountToSend}(
                    takerOrder,
                    makerOrder
                );
            }
            if (typeNft == LibAsset.ERC721_ASSET_CLASS) {
                IERC721Upgradeable(makerOrder.collection).safeTransferFrom(
                    address(this),
                    _msgSender(),
                    makerOrder.tokenId
                );
            } else if (typeNft == LibAsset.ERC1155_ASSET_CLASS) {
                IERC1155Upgradeable(makerOrder.collection).safeTransferFrom(
                    address(this),
                    _msgSender(),
                    makerOrder.tokenId,
                    makerOrder.amount,
                    ""
                );
            } else {
                revert("Unknown token type");
            }
        } else if (purchaseDetails.marketId == Markets.SudoSwap) {
            (bool success, ) = address(sudoswap).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase SudoSwap failed");
            }
        } else if (purchaseDetails.marketId == Markets.Blur) {
            (bool success, ) = address(blur).call{value: nativeAmountToSend}(marketData);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase blurio failed");
            }
        } else {
            revert("Unknown purchase details");
        }

        //transferring royalties
        transferAdditionalRoyalties(additionalRoyalties, purchaseDetails.amount);

        return (true, firstFeeAmount, secondFeeAmount);
    }

    /**
        @notice transfers fee native to feeRecipient
        @param feeAmount - amount to be transfered
        @param feeRecipient - address of the recipient
     */
    function transferFee(uint feeAmount, address feeRecipient) internal {
        if (feeAmount > 0 && feeRecipient != address(0)) {
            LibTransfer.transferEth(feeRecipient, feeAmount);
        }
    }

    /**
        @notice transfers fee token to feeRecipient
        @param paymentToken - token to be transfered
        @param feeAmount - amount to be transfered
        @param feeRecipient - address of the recipient
     */
    function transferFeeToken(address paymentToken, uint feeAmount, address feeRecipient) internal {
        if (feeAmount > 0 && feeRecipient != address(0)) {
            IERC20Upgradeable(paymentToken).transfer(feeRecipient, feeAmount);
        }
    }

    /**
        @notice transfers change native back to sender
     */
    function transferChange() internal {
        uint ethAmount = address(this).balance;
        if (ethAmount > 0) {
            address(msg.sender).transferEth(ethAmount);
        }
    }

    /**
        @notice transfers change fee back to sender
     */
    function transferFeeChange(address paymentToken) internal {
        uint tokenAmount = IERC20Upgradeable(paymentToken).balanceOf(address(this));
        if (tokenAmount > 0) {
            IERC20Upgradeable(paymentToken).transfer(_msgSender(), tokenAmount);
        }
    }

    /**
        @notice transfers change fees back to sender
     */
    function transferFeeChange(PurchaseDetails[] memory purchaseDetails) internal {
        uint length = purchaseDetails.length;
        for (uint i; i < length; ++i) {
            if (purchaseDetails[i].paymentToken != address(0)) {
                transferFeeChange(purchaseDetails[i].paymentToken);
            }
        }
    }

    /**
        @notice return market proxy based on market id
        @param marketId market id
        @return address market proxy address
     */
    function getMarketProxy(Markets marketId) internal view returns (address) {
        return proxies[marketId];
    }

    /**
        @notice parses fees in base points from one uint and calculates real amount of fees
        @param fees two fees encoded in one uint, 29 and 30 bytes are used for the first fee, 31 and 32 bytes for second fee
        @param amount price of the order
        @return firstFeeAmount real amount for the first fee
        @return secondFeeAmount real amount for the second fee
     */
    function getFees(uint fees, uint amount) internal pure returns (uint, uint) {
        uint firstFee = uint(uint16(fees >> 16));
        uint secondFee = uint(uint16(fees));
        return (amount.bp(firstFee), amount.bp(secondFee));
    }

    /**
        @notice parses _data to data for market call and additionalData
        @param feesAndDataType 27 and 28 bytes for dataType
        @return marketData data for market call
        @return additionalRoyalties array uint256, (base point + address)
     */
    function getDataAndAdditionalData(
        bytes memory _data,
        uint feesAndDataType,
        Markets marketId
    ) internal pure returns (bytes memory, uint[] memory) {
        AdditionalDataTypes dataType = AdditionalDataTypes(uint16(feesAndDataType >> 32));
        uint[] memory additionalRoyalties;

        //return no royalties if wrong data type
        if (dataType == AdditionalDataTypes.NoAdditionalData) {
            return (_data, additionalRoyalties);
        }

        if (dataType == AdditionalDataTypes.RoyaltiesAdditionalData) {
            AdditionalData memory additionalData = abi.decode(_data, (AdditionalData));

            //return no royalties if market doesn't support royalties
            if (supportsRoyalties(marketId)) {
                return (additionalData.data, additionalData.additionalRoyalties);
            } else {
                return (additionalData.data, additionalRoyalties);
            }
        }

        revert("unknown additionalDataType");
    }

    /**
        @notice transfer additional royalties
        @param _additionalRoyalties array uint256 (base point + royalty recipient address)
     */
    function transferAdditionalRoyalties(uint[] memory _additionalRoyalties, uint amount) internal {
        uint length = _additionalRoyalties.length;
        for (uint i; i < length; ++i) {
            if (_additionalRoyalties[i] > 0) {
                address payable account = payable(address(uint160(_additionalRoyalties[i])));
                uint basePoint = uint(_additionalRoyalties[i] >> 160);
                uint value = amount.bp(basePoint);
                transferFee(value, account);
            }
        }
    }

    // modifies `src`
    function _arrayReplace(bytes memory src, bytes memory replacement, bytes memory mask) internal view virtual {
        require(src.length == replacement.length);
        require(src.length == mask.length);

        uint256 length = src.length;
        for (uint256 i; i < length; ++i) {
            if (mask[i] != 0) {
                src[i] = replacement[i];
            }
        }
    }

    /**
        @notice returns true if this contract supports additional royalties for the marketplace
        now royalties support only for marketId = sudoswap & looksrare
    */
    function supportsRoyalties(Markets marketId) internal pure returns (bool) {
        if (marketId == Markets.SudoSwap || marketId == Markets.LooksRare) {
            return true;
        }

        return false;
    }

    /**
     * @notice swaps tokens for exact tokens - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2TokensForExactTokens(SwapV2DetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn from path
        address tokenIn = swapDetails.path[0];

        // Move tokenIn to contract
        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(tokenIn),
            _msgSender(),
            address(this),
            swapDetails.amountInMaximum
        );

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV2), address(this));
        if (allowance < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV2), type(uint256).max);
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;
        uint256 amountIn;

        if (isAvalanche) {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactTokens(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.binSteps, // binSteps
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        } else {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactTokens(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        return true;
    }

    /**
     * @notice swaps tokens for exact ETH or WETH - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2TokensForExactETHOrWETH(SwapV2DetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];

        // Move tokenIn to contract
        IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
            IERC20Upgradeable(tokenIn),
            _msgSender(),
            address(this),
            swapDetails.amountInMaximum
        );

        // if source = wrapped and destination = native, unwrap and return
        if (tokenIn == wrappedToken && swapDetails.unwrap) {
            try IWETH(wrappedToken).withdraw(swapDetails.amountInMaximum) {} catch {
                return false;
            }
            return true;
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            try IWETH(wrappedToken).deposit{value: msg.value}() {} catch {
                return false;
            }
            return true;
        }

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV2), address(this));
        if (allowance < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV2), type(uint256).max);
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;
        uint256 amountIn;
        uint256 balanceEthBefore = address(this).balance;

        if (isAvalanche) {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactAVAX(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.binSteps, // binSteps
                swapDetails.path, // path
                payable(address(this)), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        } else {
            uint[] memory amounts = uniswapRouterV2.swapTokensForExactETH(
                swapDetails.amountOut, // amountOut
                swapDetails.amountInMaximum, // amountInMaximum
                swapDetails.path, // path
                payable(address(this)), // recipient
                block.timestamp // deadline
            );
            amountIn = amounts[0];
        }

        uint256 balanceEthAfter = address(this).balance;

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
        }

        // Wrap if required
        if (swapDetails.unwrap) {
            try IWETH(wrappedToken).deposit{value: balanceEthAfter - balanceEthBefore}() {} catch {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice swaps ETH or WETH for exact tokens - uniswap v2
     * @param swapDetails swapDetails required
     */
    function swapV2ETHOrWETHForExactTokens(SwapV2DetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn = swapDetails.path[0];
        address tokenOut = swapDetails.path[swapDetails.path.length - 1];

        // Move tokenIn to contract if ERC20
        if (msg.value == 0) {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(tokenIn),
                _msgSender(),
                address(this),
                swapDetails.amountInMaximum
            );

            try IWETH(wrappedToken).withdraw(swapDetails.amountInMaximum) {} catch {
                return false;
            }
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            try IWETH(wrappedToken).deposit{value: msg.value}() {} catch {
                return false;
            }
            IERC20Upgradeable(tokenOut).transfer(_msgSender(), swapDetails.amountInMaximum);
            return true;
        }

        // Swap
        uint256 chainId = block.chainid;
        bool isAvalanche = chainId == 43114 || chainId == 43113;

        if (isAvalanche) {
            uniswapRouterV2.swapAVAXForExactTokens{value: swapDetails.amountInMaximum}(
                swapDetails.amountOut, // amountOutMinimum
                swapDetails.binSteps, // binSteps
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
        } else {
            uniswapRouterV2.swapETHForExactTokens{value: swapDetails.amountInMaximum}(
                swapDetails.amountOut, // amountOutMinimum
                swapDetails.path, // path
                address(this), // recipient
                block.timestamp // deadline
            );
        }

        return true;
    }

    /**
     * @notice swaps tokens for exact tokens - uniswap v3
     * @param swapDetails swapDetails required
     */
    function swapTokensForExactTokens(SwapDetailsIn memory swapDetails) internal returns (bool) {
        // extract tokenIn / tokenOut from path
        address tokenIn;
        address tokenOut;
        bytes memory _path = swapDetails.path;
        uint _start = _path.length - 20;
        assembly {
            tokenIn := div(mload(add(add(_path, 0x20), _start)), 0x1000000000000000000000000)
            tokenOut := div(mload(add(add(_path, 0x20), 0)), 0x1000000000000000000000000)
        }

        // Move tokenIn to contract if ERC20
        if (msg.value == 0) {
            IERC20TransferProxy(erc20TransferProxy).erc20safeTransferFrom(
                IERC20Upgradeable(tokenIn),
                _msgSender(),
                address(this),
                swapDetails.amountInMaximum
            );
        }

        // if source = wrapped and destination = native, unwrap and return
        if (tokenIn == wrappedToken && swapDetails.unwrap) {
            try IWETH(wrappedToken).withdraw(swapDetails.amountOut) {} catch {
                return false;
            }
            return true;
        }

        // if source = native and destination = wrapped, wrap and return
        if (msg.value > 0 && tokenOut == wrappedToken) {
            try IWETH(wrappedToken).deposit{value: msg.value}() {} catch {
                return false;
            }
            return true;
        }

        // Approve tokenIn on uniswap
        uint256 allowance = IERC20Upgradeable(tokenIn).allowance(address(uniswapRouterV3), address(this));
        if (allowance < swapDetails.amountInMaximum) {
            IERC20Upgradeable(tokenIn).approve(address(uniswapRouterV3), type(uint256).max);
        }

        // Set the order parameters
        ISwapRouterV3.ExactOutputParams memory params = ISwapRouterV3.ExactOutputParams(
            swapDetails.path, // path
            address(this), // recipient
            block.timestamp, // deadline
            swapDetails.amountOut, // amountOut
            swapDetails.amountInMaximum // amountInMaximum
        );

        // Swap
        uint256 amountIn;
        try uniswapRouterV3.exactOutput{ value: msg.value }(params) returns (uint256 amount) {
            amountIn = amount;
        } catch {
            return false;
        }

        // Refund ETH from swap if any
        uniswapRouterV3.refundETH();

        // Unwrap if required
        if (swapDetails.unwrap) {
            try IWETH(wrappedToken).withdraw(swapDetails.amountOut) {} catch {
                return false;
            }
        }

        // Refund tokenIn left if any
        if (amountIn < swapDetails.amountInMaximum) {
            if (msg.value == 0)
            {
                IERC20Upgradeable(tokenIn).transfer(_msgSender(), swapDetails.amountInMaximum - amountIn);
            }
        }

        return true;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Input, Order} from "../librairies/OrderStructs.sol";

interface IBlurExchange {
    function nonces(address) external view returns (uint256);

    function cancelOrder(Order calldata order) external;

    function cancelOrders(Order[] calldata orders) external;

    function incrementNonce() external;

    function execute(Input calldata sell, Input calldata buy) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../librairies/LibOrder.sol";
import "../../librairies/LibDirectTransfer.sol";

interface IExchangeV2 {
    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

    function directPurchase(LibDirectTransfer.Purchase calldata direct) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibLooksRare.sol";

interface ILooksRare {
    function matchAskWithTakerBidUsingETHAndWETH(
        LibLooksRare.TakerOrder calldata takerBid,
        LibLooksRare.MakerOrder calldata makerAsk
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibSeaPort.sol";

interface ISeaPort {
    function fulfillAdvancedOrder(
        LibSeaPort.AdvancedOrder calldata advancedOrder,
        LibSeaPort.CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvailableAdvancedOrders(
        LibSeaPort.AdvancedOrder[] memory advancedOrders,
        LibSeaPort.CriteriaResolver[] calldata criteriaResolvers,
        LibSeaPort.FulfillmentComponent[][] calldata offerFulfillments,
        LibSeaPort.FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    ) external payable returns (bool[] memory availableOrders, LibSeaPort.Execution[] memory executions);

    function fulfillBasicOrder(
        LibSeaPort.BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface ISwapRouterV2 {
    // regular
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMinimum,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMaximum,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMinimum,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint amountOut);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMaximum,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMinimum,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    // avalanche
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMinimum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMaximum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactAVAXForTokens(
        uint amountOutMinimum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint amountOut);

    function swapTokensForExactAVAX(
        uint amountOut,
        uint amountInMaximum,
        uint[] calldata binSteps,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForAVAX(
        uint amountIn,
        uint amountOutMinimum,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapAVAXForExactTokens(
        uint amountOut,
        uint[] calldata binSteps,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouterV3 is IUniswapV3SwapCallback {
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

    function refundETH() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface Ix2y2 {
    struct OrderItem {
        uint256 price;
        bytes data;
    }

    struct Pair721 {
        address token;
        uint256 tokenId;
    }

    struct Pair1155 {
        address token;
        uint256 tokenId;
        uint256 amount;
    }

    struct Order {
        uint256 salt;
        address user;
        uint256 network;
        uint256 intent;
        uint256 delegateType;
        uint256 deadline;
        address currency;
        bytes dataMask;
        OrderItem[] items;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 signVersion;
    }

    struct Fee {
        uint256 percentage;
        address to;
    }

    struct SettleDetail {
        Op op;
        uint256 orderIdx;
        uint256 itemIdx;
        uint256 price;
        bytes32 itemHash;
        address executionDelegate;
        bytes dataReplacement;
        uint256 bidIncentivePct;
        uint256 aucMinIncrementPct;
        uint256 aucIncDurationSecs;
        Fee[] fees;
    }

    struct SettleShared {
        uint256 salt;
        uint256 deadline;
        uint256 amountToEth;
        uint256 amountToWeth;
        address user;
        bool canFail;
    }

    struct RunInput {
        Order[] orders;
        SettleDetail[] details;
        SettleShared shared;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum Op {
        INVALID,
        // off-chain
        COMPLETE_SELL_OFFER,
        COMPLETE_BUY_OFFER,
        CANCEL_OFFER,
        // auction
        BID,
        COMPLETE_AUCTION,
        REFUND_AUCTION,
        REFUND_AUCTION_STUCK_ITEM
    }

    function run(RunInput memory input) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibLooksRare {
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibSeaPort {
    /**
     * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
     *      matching, a group of six functions may be called that only requires a
     *      subset of the usual order arguments. Note the use of a "basicOrderType"
     *      enum; this represents both the usual order type as well as the "route"
     *      of the basic order (a simple derivation function for the basic order
     *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
     */
    struct BasicOrderParameters {
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        BasicOrderType basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
    }
    /**
     * @dev Basic orders can supply any number of additional recipients, with the
     *      implied assumption that they are supplied from the offered ETH (or other
     *      native token) or ERC20 token for the order.
     */
    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    // prettier-ignore
    enum BasicOrderType {
        // 0: no partial fills, anyone can execute
        ETH_TO_ERC721_FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        ETH_TO_ERC721_PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        ETH_TO_ERC721_FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC721_PARTIAL_RESTRICTED,

        // 4: no partial fills, anyone can execute
        ETH_TO_ERC1155_FULL_OPEN,

        // 5: partial fills supported, anyone can execute
        ETH_TO_ERC1155_PARTIAL_OPEN,

        // 6: no partial fills, only offerer or zone can execute
        ETH_TO_ERC1155_FULL_RESTRICTED,

        // 7: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,

        // 8: no partial fills, anyone can execute
        ERC20_TO_ERC721_FULL_OPEN,

        // 9: partial fills supported, anyone can execute
        ERC20_TO_ERC721_PARTIAL_OPEN,

        // 10: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC721_FULL_RESTRICTED,

        // 11: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,

        // 12: no partial fills, anyone can execute
        ERC20_TO_ERC1155_FULL_OPEN,

        // 13: partial fills supported, anyone can execute
        ERC20_TO_ERC1155_PARTIAL_OPEN,

        // 14: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC1155_FULL_RESTRICTED,

        // 15: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

        // 16: no partial fills, anyone can execute
        ERC721_TO_ERC20_FULL_OPEN,

        // 17: partial fills supported, anyone can execute
        ERC721_TO_ERC20_PARTIAL_OPEN,

        // 18: no partial fills, only offerer or zone can execute
        ERC721_TO_ERC20_FULL_RESTRICTED,

        // 19: partial fills supported, only offerer or zone can execute
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,

        // 20: no partial fills, anyone can execute
        ERC1155_TO_ERC20_FULL_OPEN,

        // 21: partial fills supported, anyone can execute
        ERC1155_TO_ERC20_PARTIAL_OPEN,

        // 22: no partial fills, only offerer or zone can execute
        ERC1155_TO_ERC20_FULL_RESTRICTED,

        // 23: partial fills supported, only offerer or zone can execute
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }

    /**
     * @dev The full set of order components, with the exception of the counter,
     *      must be supplied when fulfilling more sophisticated orders or groups of
     *      orders. The total number of original consideration items must also be
     *      supplied, as the caller may specify additional consideration items.
     */
    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    /**
     * @dev Orders require a signature in addition to the other order parameters.
     */
    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    /**
     * @dev A consideration item has the same five components as an offer item and
     *      an additional sixth component designating the required recipient of the
     *      item.
     */
    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    // prettier-ignore
    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    // prettier-ignore
    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,

        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,

        // 2: ERC721 items
        ERC721,

        // 3: ERC1155 items
        ERC1155,

        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,

        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    /**
     * @dev A fulfillment is applied to a group of orders. It decrements a series of
     *      offer and consideration items, then generates a single execution
     *      element. A given fulfillment can be applied to as many offer and
     *      consideration items as desired, but must contain at least one offer and
     *      at least one consideration that match. The fulfillment must also remain
     *      consistent on all key parameters across all offer items (same offerer,
     *      token, type, tokenId, and conduit preference) as well as across all
     *      consideration items (token, type, tokenId, and recipient).
     */
    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    /**
     * @dev Each fulfillment component contains one index referencing a specific
     *      order and another referencing a specific offer or consideration item.
     */
    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    /**
     * @dev An execution is triggered once all consideration items have been zeroed
     *      out. It sends the item in question from the offerer to the item's
     *      recipient, optionally sourcing approvals from either this contract
     *      directly or from the offerer's chosen conduit if one is specified. An
     *      execution is not provided as an argument, but rather is derived via
     *      orders, criteria resolvers, and fulfillments (where the total number of
     *      executions will be less than or equal to the total number of indicated
     *      fulfillments) and returned as part of `matchOrders`.
     */
    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }

    /**
     * @dev A received item is translated from a utilized consideration item and has
     *      the same four components as a spent item, as well as an additional fifth
     *      component designating the required recipient of the item.
     */
    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address payable recipient;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    // prettier-ignore
    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

enum Side {
    Buy,
    Sell
}
enum SignatureVersion {
    Single,
    Bulk
}
enum AssetType {
    ERC721,
    ERC1155
}

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Order {
    address trader;
    Side side;
    address matchingPolicy;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    /* Order expiration timestamp - 0 for oracle cancellations. */
    uint256 expirationTime;
    Fee[] fees;
    uint256 salt;
    bytes extraParams;
}

struct Input {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes extraSignature;
    SignatureVersion signatureVersion;
    uint256 blockNumber;
}

struct Execution {
    Input sell;
    Input buy;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INftTransferProxy {
    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external;

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library BpLibrary {
    function bp(uint256 value, uint256 bpValue) internal pure returns (uint256) {
        return (value * (bpValue)) / (10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibAsset {
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 public constant COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 public constant CRYPTO_PUNKS = bytes4(keccak256("CRYPTO_PUNKS"));

    bytes32 public constant ASSET_TYPE_TYPEHASH = keccak256("AssetType(bytes4 assetClass,bytes data)");

    bytes32 public constant ASSET_TYPEHASH =
        keccak256("Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)");

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPE_TYPEHASH, assetType.assetClass, keccak256(assetType.data)));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibAsset.sol";

library LibDirectTransfer {
    //LibDirectTransfers
    /*All buy parameters need for create buyOrder and sellOrder*/
    struct Purchase {
        address sellOrderMaker; //
        uint256 sellOrderNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 sellOrderPaymentAmount;
        address paymentToken;
        uint256 sellOrderSalt;
        uint sellOrderStart;
        uint sellOrderEnd;
        bytes4 sellOrderDataType;
        bytes sellOrderData;
        bytes sellOrderSignature;
        uint256 buyOrderPaymentAmount;
        uint256 buyOrderNftAmount;
        bytes buyOrderData;
    }

    /*All accept bid parameters need for create buyOrder and sellOrder*/
    struct AcceptBid {
        address bidMaker; //
        uint256 bidNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 bidPaymentAmount;
        address paymentToken;
        uint256 bidSalt;
        uint bidStart;
        uint bidEnd;
        bytes4 bidDataType;
        bytes bidData;
        bytes bidSignature;
        uint256 sellOrderPaymentAmount;
        uint256 sellOrderNftAmount;
        bytes sellOrderData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibMath {
    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = (numerator * (target)) / (denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(target, numerator, denominator);
        isError = remainder * (1000) >= numerator * (target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = (numerator * (target)) + (denominator - (1)) / (denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(target, numerator, denominator);
        remainder = denominator - ((remainder) % denominator);
        isError = remainder * (1000) >= numerator * (target);
        return isError;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibAsset.sol";
import "./LibMath.sol";
import "./LibOrderDataV3.sol";
import "./LibOrderDataV2.sol";
import "./LibOrderDataV1.sol";

library LibOrder {
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    bytes4 public constant DEFAULT_ORDER_TYPE = 0xffffffff;

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }

    function calculateRemaining(
        Order memory order,
        uint fill,
        bool isMakeFill
    ) internal pure returns (uint makeValue, uint takeValue) {
        if (isMakeFill) {
            makeValue = order.makeAsset.value - (fill);
            takeValue = LibMath.safeGetPartialAmountFloor(order.takeAsset.value, order.makeAsset.value, makeValue);
        } else {
            takeValue = order.takeAsset.value - (fill);
            makeValue = LibMath.safeGetPartialAmountFloor(order.makeAsset.value, order.takeAsset.value, takeValue);
        }
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        if (order.dataType == LibOrderDataV1.V1 || order.dataType == DEFAULT_ORDER_TYPE) {
            return
                keccak256(
                    abi.encode(
                        order.maker,
                        LibAsset.hash(order.makeAsset.assetType),
                        LibAsset.hash(order.takeAsset.assetType),
                        order.salt
                    )
                );
        } else {
            //order.data is in hash for V2, V3 and all new order
            return
                keccak256(
                    abi.encode(
                        order.maker,
                        LibAsset.hash(order.makeAsset.assetType),
                        LibAsset.hash(order.takeAsset.assetType),
                        order.salt,
                        order.data
                    )
                );
        }
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    LibAsset.hash(order.makeAsset),
                    order.taker,
                    LibAsset.hash(order.takeAsset),
                    order.salt,
                    order.start,
                    order.end,
                    order.dataType,
                    keccak256(order.data)
                )
            );
    }

    function validateOrderTime(LibOrder.Order memory order) internal view {
        require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
        require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

library LibOrderDataV1 {
    bytes4 public constant V1 = bytes4(keccak256("V1"));

    struct DataV1 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

library LibOrderDataV2 {
    bytes4 public constant V2 = bytes4(keccak256("V2"));

    struct DataV2 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        bool isMakeFill;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

library LibOrderDataV3 {
    bytes4 public constant V3_SELL = bytes4(keccak256("V3_SELL"));
    bytes4 public constant V3_BUY = bytes4(keccak256("V3_BUY"));

    struct DataV3_SELL {
        uint payouts;
        uint originFeeFirst;
        uint originFeeSecond;
        uint maxFeesBasePoint;
        bytes32 marketplaceMarker;
    }

    struct DataV3_BUY {
        uint payouts;
        uint originFeeFirst;
        uint originFeeSecond;
        bytes32 marketplaceMarker;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibTransfer {
    function transferEth(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "LibTransfer BaseCurrency transfer failed");
    }
}