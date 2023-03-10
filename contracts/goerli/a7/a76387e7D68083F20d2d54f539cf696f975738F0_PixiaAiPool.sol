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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: MIT

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File: contracts/UniversalERC20Upgradeable.sol

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

library UniversalERC20Upgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant ZERO_ADDRESS =
        IERC20Upgradeable(0x0000000000000000000000000000000000000000);
    IERC20Upgradeable public constant ETH_ADDRESS =
        IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    error WrongUsage();

    function universalTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            payable(address(uint160(to))).sendValue(amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransfer(to, amount);
            return token.balanceOf(to) - balanceBefore;
        }
    }

    function universalTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            if (from != msg.sender || msg.value < amount) revert WrongUsage();
            if (to != address(this))
                payable(address(uint160(to))).sendValue(amount);
            // refund redundant amount
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);
            return token.balanceOf(to) - balanceBefore;
        }
    }

    function universalTransferFromSenderToThis(
        IERC20Upgradeable token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) return 0;

        if (isETH(token)) {
            if (msg.value < amount) revert WrongUsage();
            // Return remainder if exist
            if (msg.value > amount)
                payable(msg.sender).sendValue(msg.value - amount);
            return amount;
        } else {
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            return token.balanceOf(address(this)) - balanceBefore;
        }
    }

    function universalApprove(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0)
                token.safeApprove(to, 0);
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(
        IERC20Upgradeable token,
        address who
    ) internal view returns (uint256) {
        if (isETH(token)) return who.balance;
        return token.balanceOf(who);
    }

    function universalDecimals(
        IERC20Upgradeable token
    ) internal view returns (uint256) {
        if (isETH(token)) return 18;

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20Upgradeable token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommon {
    enum LaunchPlan {
        FREE,
        PAID
    }

    error InvalidZeroAddress();
    error ValueOverflow(uint16 expected, uint16 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IETHPlugin {
    function unwrap(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICommon.sol";

interface IPixiaAiPoolFactory {
    /// @notice Get default admin address
    function defaultAdmin() external view returns (address);

    /// @notice View treasury address
    function treasury() external view returns (address payable);

    /// @notice View free plan commission fee
    function freePlanCommission() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/IUniswapAmm.sol";
import "../interfaces/IWETH.sol";
import "../libs/UniversalERC20Upgradeable.sol";
import "./ICommon.sol";
import "./IETHPlugin.sol";
import "./IPixiaAiPoolFactory.sol";

contract PixiaAiPool is
    ICommon,
    Initializable,
    ContextUpgradeable,
    IERC721ReceiverUpgradeable,
    ReentrancyGuardUpgradeable
{
    using UniversalERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    struct UserInfo {
        EnumerableSetUpgradeable.Bytes32Set stakings; // Store staking ids per this user
        /// Interesting calculation for the staking id by using user address and the block time
        /// stakingId = keccak256(abi.encodePacked(address,uint64));
        /// we set time 0 for the general staking
    }

    struct StakingInfo {
        address account; // User account who made this staking
        uint256 amount; // How many staked tokens the user has provided
        uint256 boostedAmount; // Boosted amount by nft and lock
        uint256 rewardDebt; // Reward debt
        uint64 lastRewardAt; // Last reward harvested time. Its used in the locked staking
        uint64 lastDepositAt; // Last deposited time.
        uint64 lockTime; // How long token is locked
        EnumerableSetUpgradeable.UintSet nfts;
    }

    /// @notice The address of the pool factory
    address public poolFactory;
    /// @notice The staking token (ETH is supported)
    address public stakingToken;
    /// @notice The reward token (ETH is supported)
    address public rewardToken;
    /// @notice The boosting ERC721 nft collection
    address public boostingNft;
    /// @notice ETH plugin
    address public ethPlugin;
    /// @notice Dex router address is used when commission fee is paid in FREE plan
    address private _dexRouter;
    /// @notice Commission fee is swapped to this token and transferred to the commission treasury address
    address private _commissionToken;
    /// @notice The admin address of this pool
    address private _admin;
    /// @notice Pool treasury address
    address payable private _treasury;

    /// @notice Plan how to pay the commission (paid mode or free mode)
    ICommon.LaunchPlan public launchPlan;

    // Accrued token per share
    uint256 public accRewardPerShare;
    /// @notice The precision factor
    uint256 public PRECISION_FACTOR;
    /// @notice Total staked supply by users
    uint256 public stakedSupply;
    /// @notice Total staked boosted supply by users
    /// @dev Real calculation is done with this supply
    uint256 public boostedSupply;
    /// @notice Total reward supply that was given by the pool owner
    uint256 public rewardSupply;

    /// @notice Reward amount distributed per second
    uint256 private _emission;

    /// @notice The last reward calculated time
    uint64 public lastRewardAt;

    /// @notice Pool reward distribution start time (reward is calculated from this time)
    uint64 private _startAt;
    /// @notice Pool reward distribution end time
    uint64 private _endAt;

    /// @notice Max lock time in the pool
    uint64 public maxLockTime;
    /// @notice Boost multiplier when locked max time. 12x is 120000, 5x is 50000 (10000 precision)
    uint32 public maxLockMultiplier;

    uint16 public constant MAX_FEE = 2000;

    /// @notice Deposit fee, default 0%
    uint16 private _depositFee;
    /// @notice Too early withdraw fee
    uint16 private _earlyWithdrawFee;

    /// @notice Multiplier to be got when stake 1 nft. 1x is 100 (precision 100)
    uint16 public nftMultiplier;

    /// @notice Timeline for withdrawning without fee
    uint64 private _earlyFeeTime;

    /// @notice Info of each user - lock ids
    mapping(address => UserInfo) private _userInfo;
    /// @notice Staking info, including locked staking and general staking
    mapping(bytes32 => StakingInfo) private _stakingInfo;

    event Harvested(address user, uint256 amount);
    event TokenRelocked(
        address user,
        uint256 amount,
        uint64 nftAmount,
        uint64 lockTime
    );
    event TokenStaked(address user, uint256 amount, uint64 lockTime);
    event TokenUnstaked(bytes32 stakingId, address user, uint256 amount);
    event TokenAndNftReleased(address user, uint256 amount, uint64 nftAmount);
    event NftStaked(bytes32 stakingId, address user, uint256 amount);
    event NftUnstaked(bytes32 stakingId, address user, uint256 amount);

    event EmergencyWithdrawn(
        address user,
        uint16 nftAmount,
        uint256 tokenAmount
    );
    event Withdrawn(address user, uint16 nftAmount, uint256 tokenAmount);

    error InsufficientAmount();
    error InvalidAddresses();
    error InvalidEndTime();
    error InvalidLockTime();
    error InvalidOperation();
    error InvalidStartTime();
    error OverflowNftLimit();
    error PoolNotOpened();
    error StakingDuplicated(bytes32 stakingId);
    error StillLocked();
    error Unpermitted();

    modifier onlyAdmins() {
        address _defaultAdmin = IPixiaAiPoolFactory(poolFactory).defaultAdmin();
        if (_msgSender() != _admin && _msgSender() != _defaultAdmin)
            revert Unpermitted();
        _;
    }

    /// @notice Initialize the pool contract with given args
    /// @param plan_ Pool creators should determine the commission plan (paid or free)
    /// @param numbers_ Packed value of startTime, endTime, maxLockTime, nftMultiplier and maxLockMultiplier
    /// startAt_ Pool reward distribution start time (reward is calculated from this time)
    /// endAt_ Pool reward distribution end time
    /// nftMultiplier_ Nft boost multiplier
    /// maxLockTime_ Max lock timeline
    /// maxLockMultiplier_ Max lock boost multiplier
    /// @param addresses_ encodePacked bytes of stakingToken, rewardToken, boostingNft, treasury and admin account
    /// stakingToken_: Staking token address (ETH is supported, address(0) means ETH)
    /// rewardToken_: Reward token address (ETH is supported, address(0) means ETH)
    /// boostingNft_: Boosting Nft collection address
    /// dexRouter_: Dex router address for the commission fee swap
    /// commissionToken_: Commission token to get paid
    /// treasury_: Pool treasury address
    /// admin_: Pool admin address
    /// @param ethPlugin_ Plugin for unwrap WETH to ETH
    /// @param emission_ Reward amount per second
    function initialize(
        ICommon.LaunchPlan plan_,
        address ethPlugin_,
        uint240 numbers_,
        uint256 emission_,
        bytes calldata addresses_
    ) public initializer {
        __Context_init();

        _initializeNumbers(numbers_);
        _initializeAddresses(addresses_);

        launchPlan = plan_;
        _emission = emission_;
        ethPlugin = ethPlugin_;

        poolFactory = _msgSender();

        _earlyWithdrawFee = 300; // Early withdraw fee default 3%
        _earlyFeeTime = 3 days; // Early fee time is 3 days in default
    }

    /// @notice Initialize number props
    /// @param numbers_ startTime|endTime|maxLockTime|nftMultiplier|maxLockMultiplier
    function _initializeNumbers(uint240 numbers_) internal {
        maxLockMultiplier = uint32(numbers_);
        nftMultiplier = uint16(numbers_ >> 32);
        maxLockTime = uint64(numbers_ >> 48);
        uint64 endAt_ = uint64(numbers_ >> 112);
        uint64 startAt_ = uint64(numbers_ >> 176);

        if (startAt_ > endAt_) revert InvalidEndTime();
        if (startAt_ < block.timestamp) revert InvalidStartTime();

        _startAt = startAt_;
        _endAt = endAt_;
        lastRewardAt = startAt_;
    }

    /// @notice Initialize address props
    /// @param addresses_ stakingToken|rewardToken|boostingNft|treasury|admin
    function _initializeAddresses(bytes memory addresses_) internal {
        // 4 addresses encode packed bytes should be 80 bytes length
        uint16 ADDRESS_LENGTH = 20;
        if (addresses_.length != 20 * 7) revert InvalidAddresses();
        address stakingToken_;
        address rewardToken_;
        address boostingNft_;
        address dexRouter_;
        address commissionToken_;
        address treasury_;
        address admin_;
        assembly {
            stakingToken_ := mload(add(addresses_, ADDRESS_LENGTH))
            rewardToken_ := mload(add(addresses_, mul(ADDRESS_LENGTH, 2)))
            boostingNft_ := mload(add(addresses_, mul(ADDRESS_LENGTH, 3)))
            dexRouter_ := mload(add(addresses_, mul(ADDRESS_LENGTH, 4)))
            commissionToken_ := mload(add(addresses_, mul(ADDRESS_LENGTH, 5)))
            treasury_ := mload(add(addresses_, mul(ADDRESS_LENGTH, 6)))
            admin_ := mload(add(addresses_, mul(ADDRESS_LENGTH, 7)))
        }
        if (
            admin_ == address(0) ||
            treasury_ == address(0) ||
            dexRouter_ == address(0)
        ) revert InvalidZeroAddress();

        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        boostingNft = boostingNft_;

        _dexRouter = dexRouter_;
        _commissionToken = commissionToken_;

        _treasury = payable(treasury_);
        _admin = admin_;

        uint256 decimalsRewardToken = IERC20Upgradeable(rewardToken_)
            .universalDecimals();
        PRECISION_FACTOR = 10 ** (30 - decimalsRewardToken);
    }

    /// @notice Stake boosting nft to the given `stakingId`
    /// @param stakingId_ 0x00 for the general staking, valid value for the locked staking
    function stakeBoostNft(
        bytes32 stakingId_,
        uint256[] calldata nftIds_
    ) external nonReentrant {
        uint256 nftAmount = nftIds_.length;
        if (nftAmount == 0) revert InsufficientAmount();

        StakingInfo storage stakingInfo = _stakingInfo[stakingId_];
        // Validate the staking id is owned by the user
        if (stakingInfo.account != _msgSender()) revert Unpermitted();

        updatePool();
        uint256 rewardAmount = pendingReward(stakingId_);
        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        uint16 i;
        IERC721Upgradeable _boostingNft = IERC721Upgradeable(boostingNft);

        for (; i < nftAmount; i++) {
            _boostingNft.safeTransferFrom(
                _msgSender(),
                address(this),
                nftIds_[i]
            );
            stakingInfo.nfts.add(nftIds_[i]);
        }

        uint256 oldBoostedAmount = stakingInfo.boostedAmount;
        uint256 newBoostedAmount = (stakingInfo.amount *
            getBooster(
                uint64(stakingInfo.nfts.length()),
                stakingInfo.lockTime
            )) / 1e6;

        boostedSupply += newBoostedAmount - oldBoostedAmount;
        stakingInfo.boostedAmount = newBoostedAmount;

        stakingInfo.rewardDebt =
            (newBoostedAmount * accRewardPerShare) /
            PRECISION_FACTOR;

        emit NftStaked(stakingId_, _msgSender(), nftAmount);
    }

    /// @notice Unstake boosting nft from the given `stakingId`
    /// @param stakingId_ 0x00 for the general staking, valid value for the locked staking
    function unstakeBoostNft(
        bytes32 stakingId_,
        uint256[] calldata nftIds_
    ) external nonReentrant {
        uint256 nftAmount = nftIds_.length;
        if (nftAmount == 0) revert InsufficientAmount();

        StakingInfo storage stakingInfo = _stakingInfo[stakingId_];
        UserInfo storage userInfo = _userInfo[_msgSender()];
        // Validate the staking id is owned by the user
        if (stakingInfo.account != _msgSender()) revert Unpermitted();

        updatePool();

        uint256 rewardAmount = pendingReward(stakingId_);
        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        uint256 i;
        IERC721Upgradeable _boostingNft = IERC721Upgradeable(boostingNft);
        for (; i < nftAmount; i++) {
            _boostingNft.safeTransferFrom(
                address(this),
                _msgSender(),
                nftIds_[i]
            );

            // Check if nft is not user's owned one
            if (!stakingInfo.nfts.remove(nftIds_[i])) revert Unpermitted();
        }

        uint256 oldBoostedAmount = stakingInfo.boostedAmount;
        uint256 newBoostedAmount = (stakingInfo.amount *
            getBooster(
                uint64(stakingInfo.nfts.length()),
                stakingInfo.lockTime
            )) / 1e6;

        boostedSupply -= oldBoostedAmount - newBoostedAmount;
        stakingInfo.boostedAmount = newBoostedAmount;

        stakingInfo.rewardDebt =
            (newBoostedAmount * accRewardPerShare) /
            PRECISION_FACTOR;

        // when all tokens and nfts are unstaked
        if (newBoostedAmount == 0 && stakingInfo.nfts.length() == 0)
            userInfo.stakings.remove(stakingId_);

        emit NftUnstaked(stakingId_, _msgSender(), nftAmount);
    }

    /// @notice Stake tokens without lock time
    /// @dev Reward is harvested to the user
    function stakeToken(uint256 amount_) external payable nonReentrant {
        bytes32 stakingId = _generateStakingId(_msgSender(), false);
        StakingInfo storage stakingInfo = _stakingInfo[stakingId];
        UserInfo storage userInfo = _userInfo[_msgSender()];

        updatePool();
        uint256 rewardAmount = pendingReward(stakingId);
        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        amount_ = _stakeToken(amount_);

        uint256 boostedAmount_ = stakingInfo.boostedAmount;
        // Calculate newly added boosted amount by the token deposit
        uint256 deltaBoostedAmount = (amount_ *
            (100 + stakingInfo.nfts.length() * nftMultiplier)) / 100;
        boostedAmount_ += deltaBoostedAmount;

        stakingInfo.account = _msgSender();
        stakingInfo.lastDepositAt = uint64(block.timestamp);
        stakingInfo.amount += amount_;
        stakingInfo.boostedAmount = boostedAmount_;
        stakedSupply += amount_;
        boostedSupply += deltaBoostedAmount;

        stakingInfo.rewardDebt =
            (boostedAmount_ * accRewardPerShare) /
            PRECISION_FACTOR;

        // This will not add staking id when its already added
        userInfo.stakings.add(stakingId);

        emit TokenStaked(_msgSender(), amount_, 0);
    }

    /// @notice Harvest from user's stakings
    function harvest() external {
        bytes32[] memory stakingIds = _userInfo[_msgSender()].stakings.values();
        uint256 stakingCount = stakingIds.length;
        uint256 i;
        uint256 rewardAmount;

        updatePool();

        for (; i < stakingCount; i++) rewardAmount += _harvest(stakingIds[i]);

        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        emit Harvested(_msgSender(), rewardAmount);
    }

    function _harvest(bytes32 stakingId_) internal returns (uint256) {
        StakingInfo storage stakingInfo = _stakingInfo[stakingId_];
        uint256 rewardAmount = pendingReward(stakingId_);

        stakingInfo.rewardDebt =
            (stakingInfo.boostedAmount * accRewardPerShare) /
            PRECISION_FACTOR;

        return rewardAmount;
    }

    /// @notice Release tokens and nfts from the lock and stake in the general staking
    function _releaseTokenAndNfts(
        uint256 tokenAmount_,
        uint256[] memory nftIds_
    ) internal {
        bytes32 stakingId = _generateStakingId(_msgSender(), false);
        StakingInfo storage stakingInfo = _stakingInfo[stakingId];
        UserInfo storage userInfo = _userInfo[_msgSender()];

        updatePool();
        uint256 rewardAmount = pendingReward(stakingId);
        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        uint16 i;
        IERC721Upgradeable _boostingNft = IERC721Upgradeable(boostingNft);
        for (; i < nftIds_.length; i++) {
            _boostingNft.safeTransferFrom(
                _msgSender(),
                address(this),
                nftIds_[i]
            );
            stakingInfo.nfts.add(nftIds_[i]);
        }
        stakingInfo.amount += tokenAmount_;

        uint256 boostedAmount_ = stakingInfo.boostedAmount;
        // Calculate newly added boosted amount by the token deposit
        uint256 newBoostedAmount = (stakingInfo.amount *
            (100 + stakingInfo.nfts.length() * nftMultiplier)) / 100;

        stakingInfo.account = _msgSender();
        stakingInfo.lastDepositAt = uint64(block.timestamp);

        stakingInfo.boostedAmount = newBoostedAmount;
        boostedSupply += newBoostedAmount - boostedAmount_;

        stakingInfo.rewardDebt =
            (newBoostedAmount * accRewardPerShare) /
            PRECISION_FACTOR;

        // This will not add staking id when its already added
        userInfo.stakings.add(stakingId);

        emit TokenStaked(_msgSender(), tokenAmount_, uint64(nftIds_.length));
    }

    /// @notice Unstake tokens from the general staking
    function unstakeToken(uint256 amount_) external nonReentrant {
        if (amount_ == 0) revert InsufficientAmount();
        bytes32 stakingId = _generateStakingId(_msgSender(), false);

        UserInfo storage userInfo = _userInfo[_msgSender()];
        StakingInfo storage stakingInfo = _stakingInfo[stakingId];

        updatePool();
        uint256 rewardAmount = pendingReward(stakingId);
        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        uint256 boostedAmount_ = stakingInfo.boostedAmount;
        // Calculate decreased boosted amount by the token withdraw
        uint256 deltaBoostedAmount = (amount_ *
            (100 + stakingInfo.nfts.length() * nftMultiplier)) / 100;
        boostedAmount_ -= deltaBoostedAmount;

        stakingInfo.amount -= amount_;
        stakingInfo.boostedAmount = boostedAmount_;
        stakedSupply -= amount_;
        boostedSupply -= deltaBoostedAmount;

        IERC20Upgradeable _stakingToken = IERC20Upgradeable(stakingToken);
        // Too early withdraw pays fee
        if (block.timestamp < stakingInfo.lastDepositAt + _earlyFeeTime) {
            uint256 feeAmount = (amount_ * _earlyWithdrawFee) / 10000;
            if (feeAmount > 0) {
                _stakingToken.universalTransfer(_treasury, feeAmount);
                amount_ -= feeAmount;
            }
        }
        _stakingToken.universalTransfer(_msgSender(), amount_);

        stakingInfo.rewardDebt =
            (boostedAmount_ * accRewardPerShare) /
            PRECISION_FACTOR;

        // when all tokens and nfts are unstaked
        if (boostedAmount_ == 0 && stakingInfo.nfts.length() == 0)
            userInfo.stakings.remove(stakingId);

        emit TokenUnstaked(stakingId, _msgSender(), amount_);
    }

    /// @notice Lock token into the pool
    /// @param lockTime_ How long we lock tokens. It should not be 0.
    function lockToken(
        uint256 amount_,
        uint64 lockTime_
    ) external payable nonReentrant {
        if (lockTime_ == 0 || lockTime_ > maxLockTime) revert InvalidLockTime();

        updatePool();

        bytes32 stakingId = _generateStakingId(_msgSender(), true);
        StakingInfo storage stakingInfo = _stakingInfo[stakingId];
        UserInfo storage userInfo = _userInfo[_msgSender()];

        // We always make sure that stakingId is not used before
        if (stakingInfo.account != address(0))
            revert StakingDuplicated(stakingId);

        amount_ = _stakeToken(amount_);

        stakingInfo.account = _msgSender();
        stakingInfo.lockTime = lockTime_;
        stakingInfo.lastDepositAt = uint64(block.timestamp);

        stakingInfo.amount = amount_;
        stakedSupply += amount_;

        // Calculate boosted amount from the locked boosting
        uint256 boostedAmount_ = (amount_ *
            (10000 + (lockTime_ * maxLockMultiplier) / maxLockTime)) / 10000;
        stakingInfo.boostedAmount = boostedAmount_;
        boostedSupply += boostedAmount_;

        stakingInfo.rewardDebt =
            (boostedAmount_ * accRewardPerShare) /
            PRECISION_FACTOR;

        userInfo.stakings.add(stakingId);

        emit TokenStaked(_msgSender(), amount_, lockTime_);
    }

    /// @notice Unlock / Relock / Release lock-expired staking
    /// @param isWithdrawing_ true for unlock, false for relock and release
    /// @param newLockTime_ 0 for release, non-zero value for relock
    /// @dev In case of unlock, all locked tokens and boosted nfts will be unstaked
    /// @dev In case of relock, tokens will be locked with new lock time, and nfts will be boosted
    /// @dev In case of release, tokens will be staked in the general staking, and nfts will be boosted
    function unlockToken(
        bytes32 stakingId_,
        uint64 newLockTime_,
        bool isWithdrawing_
    ) external nonReentrant {
        StakingInfo storage stakingInfo = _stakingInfo[stakingId_];
        UserInfo storage userInfo = _userInfo[_msgSender()];

        uint256 stakedAmount_ = stakingInfo.amount;
        uint64 oldLockTime = stakingInfo.lockTime;
        if (stakingInfo.account != _msgSender()) revert Unpermitted();
        if (stakedAmount_ == 0) revert InsufficientAmount();
        if (oldLockTime == 0) revert InvalidOperation(); // This function should be called for the locked staking only
        if (oldLockTime + stakingInfo.lastDepositAt < block.timestamp)
            revert StillLocked();

        updatePool();
        uint256 rewardAmount = pendingReward(stakingId_);
        if (rewardAmount > 0) _safeRewardTransfer(_msgSender(), rewardAmount);

        uint256 boostedAmount_ = stakingInfo.boostedAmount;
        boostedSupply -= boostedAmount_;

        // In case of relock, we just reuse this staking data
        if (newLockTime_ > 0) {
            stakingInfo.lockTime = newLockTime_;
            stakingInfo.lastDepositAt = uint64(block.timestamp);

            // Calculate the boosted amount from the new lock time
            boostedAmount_ =
                (stakedAmount_ *
                    (10000 +
                        (newLockTime_ * maxLockMultiplier) /
                        maxLockTime)) /
                10000;
            stakingInfo.boostedAmount = boostedAmount_;
            boostedSupply += boostedAmount_;

            stakingInfo.rewardDebt =
                (boostedAmount_ * accRewardPerShare) /
                PRECISION_FACTOR;
            emit TokenRelocked(
                _msgSender(),
                stakedAmount_,
                uint64(stakingInfo.nfts.length()),
                newLockTime_
            );
        } else {
            stakingInfo.amount = 0;
            stakingInfo.boostedAmount = 0;
            userInfo.stakings.remove(stakingId_);

            // In case of unlock, transfer tokens and nfts to the user
            if (isWithdrawing_) {
                stakedSupply -= stakedAmount_; // stakedSupply is only deducted in case of unlock

                IERC20Upgradeable(stakingToken).universalTransfer(
                    _msgSender(),
                    stakedAmount_
                );
                emit TokenUnstaked(stakingId_, _msgSender(), stakedAmount_);

                uint256[] memory nftIds = stakingInfo.nfts.values();
                uint256 nftAmount = nftIds.length;
                // Withdraw user boosting nfts
                if (nftAmount > 0) {
                    uint256 i;
                    IERC721Upgradeable _boostingNft = IERC721Upgradeable(
                        boostingNft
                    );
                    for (; i < nftAmount; i++)
                        _boostingNft.safeTransferFrom(
                            address(this),
                            _msgSender(),
                            nftIds[i]
                        );
                    emit NftUnstaked(stakingId_, _msgSender(), nftAmount);
                }
            }
            // We stake the tokens and nfts to the general staking
            else {
                uint256[] memory nftIds = stakingInfo.nfts.values();
                _releaseTokenAndNfts(stakedAmount_, nftIds);
            }
        }
    }

    /// @notice Withdraw staked tokens without any rewards in case of emergency
    // function emergencyWithdraw() external nonReentrant {
    //     UserInfo storage user = _userInfo[_msgSender()];
    //     uint256 userTokenAmount = user.amount;

    //     user.amount = 0;
    //     user.rewardDebt = 0;
    //     stakedSupply -= userTokenAmount;
    //     boostedSupply -= user.boostedAmount;
    //     user.boostedAmount = 0;

    //     // Withdraw staked tokens
    //     IERC20Upgradeable _stakingToken = IERC20Upgradeable(stakingToken);
    //     // Too early withdraw pays fee
    //     if (block.timestamp < user.lastDepositAt + _earlyFeeTime) {
    //         uint256 feeAmount = (userTokenAmount * _earlyWithdrawFee) / 10000;
    //         if (feeAmount > 0) {
    //             _stakingToken.universalTransfer(_treasury, feeAmount);
    //             userTokenAmount -= feeAmount;
    //         }
    //     }
    //     _stakingToken.universalTransfer(_msgSender(), userTokenAmount);

    //     // Withdraw nfts
    //     uint256[] memory userNfts = user.nfts.values();
    //     IERC721Upgradeable _boostingNft = IERC721Upgradeable(boostingNft);
    //     uint16 userNftAmount = uint16(userNfts.length);
    //     uint256 i;
    //     for (; i < userNftAmount; i++) {
    //         _boostingNft.safeTransferFrom(
    //             address(this),
    //             _msgSender(),
    //             userNfts[i]
    //         );
    //         user.nfts.remove(userNfts[i]);
    //     }

    //     emit EmergencyWithdrawn(_msgSender(), userNftAmount, userTokenAmount);
    // }

    /// @notice Perform token deposit operation
    /// @dev Fee will be deducted
    /// @param amount_ Amount to be deposited. It should not be zero.
    /// @return - Token amount which is added to the user staking
    function _stakeToken(uint256 amount_) internal returns (uint256) {
        if (amount_ == 0) revert InsufficientAmount();
        IERC20Upgradeable _stakingToken = IERC20Upgradeable(stakingToken);
        amount_ = _stakingToken.universalTransferFromSenderToThis(amount_);

        uint256 feeAmount = (amount_ * _depositFee) / 10000;
        if (feeAmount > 0) {
            _stakingToken.universalTransfer(_treasury, feeAmount);
            amount_ -= feeAmount;
        }
        return amount_;
    }

    /// @notice Safe reward transfer, just in case if rounding error causes pool to not have enough reward tokens.
    function _safeRewardTransfer(address to_, uint256 amount_) internal {
        address _rewardToken = rewardToken;
        uint256 balanceInContract = IERC20Upgradeable(_rewardToken)
            .universalBalanceOf(address(this));
        // If staking token is same as reward token, it should not touch staked tokens
        if (stakingToken == _rewardToken) balanceInContract -= stakedSupply;

        if (balanceInContract > rewardSupply) balanceInContract = rewardSupply;

        if (amount_ > balanceInContract) revert InsufficientAmount();

        IERC20Upgradeable(_rewardToken).universalTransfer(to_, amount_);
        rewardSupply -= amount_;

        emit Harvested(to_, amount_);
    }

    /// @notice Get pending reward of staking
    /// @param stakingId_ to get the pending reward
    function pendingReward(bytes32 stakingId_) public view returns (uint256) {
        StakingInfo storage stakingInfo = _stakingInfo[stakingId_];
        uint256 adjustedRewardPerShare = accRewardPerShare;
        uint64 lastRewardAt_ = lastRewardAt;
        uint256 boostedSupply_ = boostedSupply;
        if (block.timestamp > lastRewardAt_ && boostedSupply_ != 0) {
            uint256 rewardAmount = _getRewardAmount(
                lastRewardAt_,
                block.timestamp
            );

            adjustedRewardPerShare +=
                (rewardAmount * PRECISION_FACTOR) /
                boostedSupply_;
        }
        uint256 userRewardAmount = (stakingInfo.boostedAmount *
            adjustedRewardPerShare) /
            PRECISION_FACTOR -
            stakingInfo.rewardDebt;

        uint64 lockEndTime = stakingInfo.lockTime + stakingInfo.lastDepositAt;

        // For general staking or still locked staking, we just return calculated result
        if (stakingInfo.lockTime == 0 || lockEndTime >= block.timestamp)
            return userRewardAmount;

        // User last harvested time might not be set when there is no harvest. In such cases,
        // last harvested time is the latest one among last deposited time and pool reward start time
        uint64 stakingLastRewardAt = stakingInfo.lastRewardAt;
        if (stakingLastRewardAt < stakingInfo.lastDepositAt)
            stakingLastRewardAt = stakingInfo.lastDepositAt;
        if (stakingLastRewardAt < _startAt) stakingLastRewardAt = _startAt;

        // For the lock-expired staking, we need to calculate the reward just until the lock end time
        return
            (userRewardAmount * (lockEndTime - stakingLastRewardAt)) /
            (block.timestamp - stakingLastRewardAt);
    }

    /// @notice Get pending reward of the user
    /// @dev It calculates sum of all stakings made by this user
    function pendingReward(address user_) public view returns (uint256) {
        bytes32[] memory stakingIds = _userInfo[user_].stakings.values();
        uint256 i;
        uint256 rewardAmount;

        for (; i < stakingIds.length; i++)
            rewardAmount += pendingReward(stakingIds[i]);

        return rewardAmount;
    }

    /// @notice Generate lock id
    /// @param account_ address who stakes in the pool
    /// @param isLock_ indicates that the lock id is for the general staking (false) or locked staking (true)
    function _generateStakingId(
        address account_,
        bool isLock_
    ) internal view returns (bytes32) {
        uint64 seed = isLock_ ? uint64(block.timestamp) : 0;
        return keccak256(abi.encodePacked(account_, seed));
    }

    /// @notice Calculate multiplier from the nft boosting and lock
    /// @dev Booster precision is 1e6 because lock booster's precision is 10000 and nft booster's precision is 100
    function getBooster(
        uint64 nftAmount_,
        uint64 lockTime_
    ) public view returns (uint256) {
        uint256 lockBooster = 10000 +
            (lockTime_ * maxLockMultiplier) /
            maxLockTime;
        uint256 nftBooster = nftAmount_ * nftMultiplier + 100;
        return lockBooster * nftBooster;
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.timestamp <= lastRewardAt) return;

        if (boostedSupply == 0) {
            lastRewardAt = uint64(block.timestamp);
            return;
        }

        uint256 rewardAmount = _getRewardAmount(lastRewardAt, block.timestamp);
        accRewardPerShare += (rewardAmount * PRECISION_FACTOR) / boostedSupply;
        lastRewardAt = uint64(block.timestamp);
    }

    /// @notice Calculate reward distribution amount 'from' ~ 'to'
    function _getRewardAmount(
        uint256 from_,
        uint256 to_
    ) internal view returns (uint256) {
        if (to_ <= _endAt) return _emission * (to_ - from_);
        else if (from_ >= _endAt) return 0;
        else return _emission * (_endAt - from_);
    }

    /// @notice Swap commission fee paid with reward token to the commission token, and then send to treasury account
    function _swapCommissionFee(
        address treasury_,
        uint256 feeAmount_
    ) internal {
        IERC20Upgradeable rewardToken_ = IERC20Upgradeable(rewardToken);
        IERC20Upgradeable commissionToken_ = IERC20Upgradeable(
            _commissionToken
        );
        IUniswapV2Router02 dexRouter_ = IUniswapV2Router02(_dexRouter);
        address weth = dexRouter_.WETH();
        if (
            (rewardToken_.isETH() && commissionToken_.isETH()) ||
            address(rewardToken_) == address(commissionToken_)
        ) rewardToken_.universalTransfer(treasury_, feeAmount_);
        else if (rewardToken_.isETH() && address(commissionToken_) == weth) {
            // ETH => WETH
            IWETH(weth).deposit{value: feeAmount_}();
            IERC20Upgradeable(weth).universalTransfer(treasury_, feeAmount_);
        } else if (commissionToken_.isETH() && address(rewardToken_) == weth) {
            // WETH => ETH
            IERC20Upgradeable(weth).universalApprove(ethPlugin, feeAmount_);
            IETHPlugin(ethPlugin).unwrap(weth, feeAmount_);
            commissionToken_.universalTransfer(treasury_, feeAmount_);
        } else if (rewardToken_.isETH()) {
            // ETH => ERC20
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = address(commissionToken_);
            dexRouter_.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: feeAmount_
            }(0, path, treasury_, block.timestamp + 300);
        } else if (commissionToken_.isETH()) {
            // ERC20 => ETH
            address[] memory path = new address[](2);
            path[0] = address(rewardToken_);
            path[1] = weth;
            rewardToken_.universalApprove(address(dexRouter_), feeAmount_);
            dexRouter_.swapExactTokensForETHSupportingFeeOnTransferTokens(
                feeAmount_,
                0,
                path,
                treasury_,
                block.timestamp + 300
            );
        } else {
            // ERC20 => ERC20
            address[] memory path = new address[](2);
            path[0] = address(rewardToken_);
            path[1] = address(commissionToken_);
            rewardToken_.universalApprove(address(dexRouter_), feeAmount_);
            dexRouter_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                feeAmount_,
                0,
                path,
                treasury_,
                block.timestamp + 300
            );
        }
    }

    /// @notice Add reward to this pool contract
    /// @dev Anyone can call this function
    function addReward(uint256 amount_) external payable {
        IERC20Upgradeable _rewardToken = IERC20Upgradeable(rewardToken);
        amount_ = _rewardToken.universalTransferFromSenderToThis(amount_);

        if (launchPlan == ICommon.LaunchPlan.FREE) {
            uint16 commissionFee = IPixiaAiPoolFactory(poolFactory).freePlanCommission();            
            address payable pixiaAiTreasury = IPixiaAiPoolFactory(poolFactory).treasury();
            uint256 feeAmount = (amount_ * commissionFee) / 10000;
            if (feeAmount > 0) {
                _swapCommissionFee(pixiaAiTreasury, feeAmount);
                amount_ -= feeAmount;
            }
        }
        rewardSupply += amount_;
    }

    /// @notice Stop pool reward distribution
    function stopPool() external onlyAdmins {
        if (block.timestamp < _startAt || block.timestamp > _endAt)
            revert PoolNotOpened();

        _endAt = uint64(block.timestamp);
    }

    /// @notice View staking info
    // / @return tokenAmount User deposited token amount
    // / @return nftIds User deposited boosting nft ids
    // / @return lastDepositAt User last deposited time
    // / @return lockTime User lock time
    function viewStakingInfo(
        bytes32 stakingId_
    )
        external
        view
        returns (
            address account,
            uint256 tokenAmount,
            uint256 boostedAmount,
            uint256[] memory nftIds,
            uint64 lastDepositAt,
            uint64 lockTime
        )
    {
        StakingInfo storage stakingInfo = _stakingInfo[stakingId_];
        account = stakingInfo.account;
        tokenAmount = stakingInfo.amount;
        boostedAmount = stakingInfo.boostedAmount;
        lastDepositAt = stakingInfo.lastDepositAt;
        lockTime = stakingInfo.lockTime;
        nftIds = stakingInfo.nfts.values();
    }

    /// @notice View staking ids of the given user account
    function viewUserInfo(
        address account_
    ) external view returns (bytes32[] memory stakingIds) {
        return _userInfo[account_].stakings.values();
    }

    /// @notice Update commission props including swap dex router and commission token
    /// @dev Only default admin can change this props
    function updateCommissionProps(
        address dexRouter_,
        address commissionToken_
    ) external {
        address _defaultAdmin = IPixiaAiPoolFactory(poolFactory).defaultAdmin();
        if (_msgSender() != _defaultAdmin) revert Unpermitted();
        if (dexRouter_ == address(0)) revert InvalidZeroAddress();

        _dexRouter = dexRouter_;
        _commissionToken = commissionToken_;
    }

    /// @notice View dex router for swapping reward token to commission token
    function dexRouter() external view returns (address) {
        return _dexRouter;
    }

    /// @notice View commission token to get paid for the commission fee
    function commissionToken() external view returns (address) {
        return _commissionToken;
    }

    /// @notice Update reward distribution amount per second
    function updateEmission(uint256 emission_) external onlyAdmins {
        updatePool();
        _emission = emission_;
    }

    /// @notice View reward distribution amount per second
    function emission() external view returns (uint256) {
        return _emission;
    }

    /// @notice Update pool reward distribution start & end time
    function updateRewardTime(
        uint256 startAt_,
        uint256 endAt_
    ) external onlyAdmins {
        if (block.timestamp > _startAt) revert InvalidOperation();

        if (startAt_ > endAt_) revert InvalidEndTime();
        if (startAt_ < block.timestamp) revert InvalidStartTime();

        _startAt = uint64(startAt_);
        _endAt = uint64(endAt_);

        // Set the lastRewardTime as the new startAt_
        lastRewardAt = uint64(startAt_);
    }

    /// @notice View pool reward distribution end time
    function endAt() external view returns (uint64) {
        return _endAt;
    }

    /// @notice View pool reward distribution start time
    function startAt() external view returns (uint64) {
        return _startAt;
    }

    /// @notice Update deposit fee
    function updateDepositFee(uint16 fee_) external onlyAdmins {
        if (fee_ > MAX_FEE) revert ValueOverflow(MAX_FEE, fee_);
        _depositFee = fee_;
    }

    /// @notice View deposit fee
    function depositFee() external view returns (uint16) {
        return _depositFee;
    }

    /// @notice Update early withdraw fee
    function updateEarlyWithdawFee(uint16 fee_) external onlyAdmins {
        if (fee_ > MAX_FEE) revert ValueOverflow(MAX_FEE, fee_);
        _earlyWithdrawFee = fee_;
    }

    /// @notice View early withdraw fee
    function earlyWithdrawFee() external view returns (uint16) {
        return _earlyWithdrawFee;
    }

    /// @notice Update early withdraw fee timeline
    function updateEarlyFeeTime(uint64 timeline_) external onlyAdmins {
        _earlyFeeTime = timeline_;
    }

    /// @notice View early fee timeline
    function earlyFeeTime() external view returns (uint64) {
        return _earlyFeeTime;
    }

    /// @notice Update pool treasury address
    function updateTreasury(address payable treasury_) external onlyAdmins {
        if (treasury_ == address(0)) revert InvalidZeroAddress();
        _treasury = treasury_;
    }

    /// @notice View pool treasury address
    function treasury() external view returns (address payable) {
        return _treasury;
    }

    /// @notice Transfer ownership to the new admin address
    function transferOwnership(address admin_) external onlyAdmins {
        _admin = admin_;
    }

    /// @notice Renounce ownership of the contract
    function renounceOwnership() external {
        if (_msgSender() != _admin) revert Unpermitted();
        _admin = address(0);
    }

    /// @notice View the pool owner address
    function owner() external view returns (address) {
        return _admin;
    }

    /// @notice View default admin of its pool factory
    function defaultAdmin() external view returns (address) {
        return IPixiaAiPoolFactory(poolFactory).defaultAdmin();
    }

    /// @notice It allows the admin to recover wrong tokens sent to the contract
    /// @param token_ the address of the token to recover
    /// @param amount_ the amount of tokens to recover
    /// @dev This function is only callable by admins
    function recoverTokens(
        address token_,
        uint256 amount_
    ) external onlyAdmins {
        uint256 balanceInContract = IERC20Upgradeable(token_)
            .universalBalanceOf(address(this));
        // If recover staking token, it should not access the users' staked tokens
        if (token_ == stakingToken)
            balanceInContract -= stakedSupply;
            // If recover reward token, it should not access the reward tokens to be distributed
        else if (token_ == rewardToken) balanceInContract -= rewardSupply;

        if (amount_ > balanceInContract) revert InsufficientAmount();

        IERC20Upgradeable(token_).universalTransfer(_msgSender(), amount_);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice To recieve ETH
    receive() external payable {}
}