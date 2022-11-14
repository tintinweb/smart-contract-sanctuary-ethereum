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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Based on code from MACI (https://github.com/appliedzkp/maci/blob/7f36a915244a6e8f98bacfe255f8bd44193e7919/contracts/sol/IncrementalMerkleTree.sol)
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { SNARK_SCALAR_FIELD } from "./Globals.sol";

import { PoseidonT3 } from "./Poseidon.sol";

/**
 * @title Commitments
 * @author Railgun Contributors
 * @notice Batch Incremental Merkle Tree for commitments
 * @dev Publicly accessible functions to be put in RailgunLogic
 * Relevant external contract calls should be in those functions, not here
 */
contract Commitments is Initializable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Commitment nullifiers (tree number -> nullifier -> seen)
  mapping(uint256 => mapping(bytes32 => bool)) public nullifiers;

  // The tree depth
  uint256 internal constant TREE_DEPTH = 16;

  // Tree zero value
  bytes32 public constant ZERO_VALUE = bytes32(uint256(keccak256("Railgun")) % SNARK_SCALAR_FIELD);

  // Next leaf index (number of inserted leaves in the current tree)
  uint256 public nextLeafIndex;

  // The Merkle root
  bytes32 public merkleRoot;

  // Store new tree root to quickly migrate to a new tree
  bytes32 private newTreeRoot;

  // Tree number
  uint256 public treeNumber;

  // The Merkle path to the leftmost leaf upon initialization. It *should
  // not* be modified after it has been set by the initialize function.
  // Caching these values is essential to efficient appends.
  bytes32[TREE_DEPTH] public zeros;

  // Right-most elements at each level
  // Used for efficient updates of the merkle tree
  bytes32[TREE_DEPTH] private filledSubTrees;

  // Whether the contract has already seen a particular Merkle tree root
  // treeNumber -> root -> seen
  mapping(uint256 => mapping(bytes32 => bool)) public rootHistory;

  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev OpenZeppelin initializer ensures this can only be called once
   */
  function initializeCommitments() internal onlyInitializing {
    /*
    To initialize the Merkle tree, we need to calculate the Merkle root
    assuming that each leaf is the zero value.
    H(H(a,b), H(c,d))
      /          \
    H(a,b)     H(c,d)
    /   \       /  \
    a    b     c    d
    `zeros` and `filledSubTrees` will come in handy later when we do
    inserts or updates. e.g when we insert a value in index 1, we will
    need to look up values from those arrays to recalculate the Merkle
    root.
    */

    // Calculate zero values
    zeros[0] = ZERO_VALUE;

    // Store the current zero value for the level we just calculated it for
    bytes32 currentZero = ZERO_VALUE;

    // Loop through each level
    for (uint256 i = 0; i < TREE_DEPTH; i += 1) {
      // Push it to zeros array
      zeros[i] = currentZero;

      // Set filled subtrees to a value so users don't pay storage allocation costs
      filledSubTrees[i] = currentZero;

      // Calculate the zero value for this level
      currentZero = hashLeftRight(currentZero, currentZero);
    }

    // Set merkle root and store root to quickly retrieve later
    newTreeRoot = merkleRoot = currentZero;
    rootHistory[treeNumber][currentZero] = true;
  }

  /**
   * @notice Hash 2 uint256 values
   * @param _left - Left side of hash
   * @param _right - Right side of hash
   * @return hash result
   */
  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    return PoseidonT3.poseidon([_left, _right]);
  }

  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev Insert leaves into the current merkle tree
   * Note: this function INTENTIONALLY causes side effects to save on gas.
   * _leafHashes and _count should never be reused.
   * @param _leafHashes - array of leaf hashes to be added to the merkle tree
   */
  function insertLeaves(bytes32[] memory _leafHashes) internal {
    /*
    Loop through leafHashes at each level, if the leaf is on the left (index is even)
    then hash with zeros value and update subtree on this level, if the leaf is on the
    right (index is odd) then hash with subtree value. After calculating each hash
    push to relevant spot on leafHashes array. For gas efficiency we reuse the same
    array and use the count variable to loop to the right index each time.

    Example of updating a tree of depth 4 with elements 13, 14, and 15
    [1,7,15]    {1}                    1
                                       |
    [3,7,15]    {1}          2-------------------3
                             |                   |
    [6,7,15]    {2}     4---------5         6---------7
                       / \       / \       / \       / \
    [13,14,15]  {3}  08   09   10   11   12   13   14   15
    [] = leafHashes array
    {} = count variable
    */

    // Get initial count
    uint256 count = _leafHashes.length;

    // If 0 leaves are passed in no-op
    if (count == 0) {
      return;
    }

    // Create new tree if current one can't contain new leaves
    // We insert all new commitment into a new tree to ensure they can be spent in the same transaction
    if ((nextLeafIndex + count) > (2**TREE_DEPTH)) {
      newTree();
    }

    // Current index is the index at each level to insert the hash
    uint256 levelInsertionIndex = nextLeafIndex;

    // Update nextLeafIndex
    nextLeafIndex += count;

    // Variables for starting point at next tree level
    uint256 nextLevelHashIndex;
    uint256 nextLevelStartIndex;

    // Loop through each level of the merkle tree and update
    for (uint256 level = 0; level < TREE_DEPTH; level += 1) {
      // Calculate the index to start at for the next level
      // >> is equivalent to / 2 rounded down
      nextLevelStartIndex = levelInsertionIndex >> 1;

      uint256 insertionElement = 0;

      // If we're on the right, hash and increment to get on the left
      if (levelInsertionIndex % 2 == 1) {
        // Calculate index to insert hash into leafHashes[]
        // >> is equivalent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(
          filledSubTrees[level],
          _leafHashes[insertionElement]
        );

        // Increment
        insertionElement += 1;
        levelInsertionIndex += 1;
      }

      // We'll always be on the left side now
      for (insertionElement; insertionElement < count; insertionElement += 2) {
        bytes32 right;

        // Calculate right value
        if (insertionElement < count - 1) {
          right = _leafHashes[insertionElement + 1];
        } else {
          right = zeros[level];
        }

        // If we've created a new subtree at this level, update
        if (insertionElement == count - 1 || insertionElement == count - 2) {
          filledSubTrees[level] = _leafHashes[insertionElement];
        }

        // Calculate index to insert hash into leafHashes[]
        // >> is equivalent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(_leafHashes[insertionElement], right);

        // Increment level insertion index
        levelInsertionIndex += 2;
      }

      // Get starting levelInsertionIndex value for next level
      levelInsertionIndex = nextLevelStartIndex;

      // Get count of elements for next level
      count = nextLevelHashIndex + 1;
    }

    // Update the Merkle tree root
    merkleRoot = _leafHashes[0];
    rootHistory[treeNumber][merkleRoot] = true;
  }

  /**
   * @notice Creates new merkle tree
   */
  function newTree() internal {
    // Restore merkleRoot to newTreeRoot
    merkleRoot = newTreeRoot;

    // Existing values in filledSubtrees will never be used so overwriting them is unnecessary

    // Reset next leaf index to 0
    nextLeafIndex = 0;

    // Increment tree number
    treeNumber += 1;
  }

  /**
   * @notice Gets tree number that new commitments will get inserted to
   * @param _newCommitments - number of new commitments
   * @return treeNumber, startingIndex
   */
  function getInsertionTreeNumberAndStartingIndex(uint256 _newCommitments)
    public
    view
    returns (uint256, uint256)
  {
    // New tree will be created if current one can't contain new leaves
    if ((nextLeafIndex + _newCommitments) > (2**TREE_DEPTH)) return (treeNumber + 1, 0);

    // Else return current state
    return (treeNumber, nextLeafIndex);
  }

  uint256[10] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// Constants
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
// Verification bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
// Use 0x000000000000000000000000000000000000dEaD as an alternative known burn address
// https://etherscan.io/address/0x000000000000000000000000000000000000dEaD
address constant VERIFICATION_BYPASS = 0x000000000000000000000000000000000000dEaD;

struct ShieldRequest {
  CommitmentPreimage preimage;
  ShieldCiphertext ciphertext;
}

enum TokenType {
  ERC20,
  ERC721,
  ERC1155
}

struct TokenData {
  TokenType tokenType;
  address tokenAddress;
  uint256 tokenSubID;
}

struct CommitmentCiphertext {
  bytes32[4] ciphertext; // Ciphertext order: IV & tag (16 bytes each), encodedMPK (senderMPK XOR receiverMPK), random & amount (16 bytes each), token
  bytes32 blindedSenderViewingKey;
  bytes32 blindedReceiverViewingKey;
  bytes annotationData; // Only for sender to decrypt
  bytes memo; // Added to note ciphertext for decryption
}

struct ShieldCiphertext {
  bytes32[3] encryptedBundle; // IV shared (16 bytes), tag (16 bytes), random (16 bytes), IV sender (16 bytes), receiver viewing public key (32 bytes)
  bytes32 shieldKey; // Public key to generate shared key from
}

enum UnshieldType {
  NONE,
  NORMAL,
  REDIRECT
}

struct BoundParams {
  uint16 treeNumber;
  uint72 minGasPrice; // Only for type 0 transactions
  UnshieldType unshield;
  uint64 chainID;
  address adaptContract;
  bytes32 adaptParams;
  // For unshields do not include an element in ciphertext array
  // Ciphertext array length = commitments - unshields
  CommitmentCiphertext[] commitmentCiphertext;
}

struct Transaction {
  SnarkProof proof;
  bytes32 merkleRoot;
  bytes32[] nullifiers;
  bytes32[] commitments;
  BoundParams boundParams;
  CommitmentPreimage unshieldPreimage;
}

struct CommitmentPreimage {
  bytes32 npk; // Poseidon(Poseidon(spending public key, nullifying key), random)
  TokenData token; // Token field
  uint120 value; // Note value
}

struct G1Point {
  uint256 x;
  uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
  uint256[2] x;
  uint256[2] y;
}

struct VerifyingKey {
  string artifactsIPFSHash;
  G1Point alpha1;
  G2Point beta2;
  G2Point gamma2;
  G2Point delta2;
  G1Point[] ic;
}

struct SnarkProof {
  G1Point a;
  G2Point b;
  G1Point c;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

/*
Functions here are stubs for the solidity compiler to generate the right interface.
The deployed library is generated bytecode from the circomlib toolchain
*/

library PoseidonT3 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(bytes32[2] memory input) public pure returns (bytes32) {}
}

library PoseidonT4 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(bytes32[3] memory input) public pure returns (bytes32) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { SNARK_SCALAR_FIELD, TokenType, UnshieldType, TokenData, ShieldCiphertext, CommitmentCiphertext, CommitmentPreimage, Transaction } from "./Globals.sol";

import { Verifier } from "./Verifier.sol";
import { Commitments } from "./Commitments.sol";
import { TokenBlocklist } from "./TokenBlocklist.sol";
import { PoseidonT4 } from "./Poseidon.sol";

// Core validation logic should remain here

/**
 * @title Railgun Logic
 * @author Railgun Contributors
 * @notice Logic to process transactions
 */
contract RailgunLogic is Initializable, OwnableUpgradeable, Commitments, TokenBlocklist, Verifier {
  using SafeERC20 for IERC20;

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Treasury variables
  address payable public treasury; // Treasury contract
  uint120 private constant BASIS_POINTS = 10000; // Number of basis points that equal 100%
  // % fee in 100ths of a %. 100 = 1%.
  uint120 public shieldFee; // Previously called as depositFee
  uint120 public unshieldFee; // Previously called withdrawFee

  // Flat fee in wei that applies to NFT transactions
  // LOGIC IS NOT IMPLEMENTED
  // TODO: Revisit adapt module structure if we want to implement this
  uint256 public nftFee; // Previously called transferFee

  // Safety vectors
  mapping(uint256 => bool) public snarkSafetyVector;

  // Token ID mapping
  mapping(bytes32 => TokenData) public tokenIDMapping;

  // Last event block - to assist with scanning
  uint256 public lastEventBlock;

  // Treasury events
  event TreasuryChange(address treasury);
  event FeeChange(uint256 shieldFee, uint256 unshieldFee, uint256 nftFee);

  // Transaction events
  event Transact(
    uint256 treeNumber,
    uint256 startPosition,
    bytes32[] hash,
    CommitmentCiphertext[] ciphertext
  );

  event Shield(
    uint256 treeNumber,
    uint256 startPosition,
    CommitmentPreimage[] commitments,
    ShieldCiphertext[] shieldCiphertext
  );

  event Unshield(address to, TokenData token, uint256 amount, uint256 fee);

  event Nullified(uint16 treeNumber, bytes32[] nullifier);

  /**
   * @notice Initialize Railgun contract
   * @dev OpenZeppelin initializer ensures this can only be called once
   * This function also calls initializers on inherited contracts
   * @param _treasury - address to send usage fees to
   * @param _shieldFee - Shield fee
   * @param _unshieldFee - Unshield fee
   * @param _nftFee - Flat fee in wei that applies to NFT transactions
   * @param _owner - governance contract
   */
  function initializeRailgunLogic(
    address payable _treasury,
    uint120 _shieldFee,
    uint120 _unshieldFee,
    uint256 _nftFee,
    address _owner
  ) public initializer {
    // Call initializers
    OwnableUpgradeable.__Ownable_init();
    Commitments.initializeCommitments();

    // Set treasury and fee
    changeTreasury(_treasury);
    changeFee(_shieldFee, _unshieldFee, _nftFee);

    // Change Owner
    OwnableUpgradeable.transferOwnership(_owner);

    // Set safety vectors
    snarkSafetyVector[11991246288605609459798790887503763024866871101] = true;
    snarkSafetyVector[135932600361240492381964832893378343190771392134] = true;
    snarkSafetyVector[1165567609304106638376634163822860648671860889162] = true;
  }

  /**
   * @notice Change treasury address, only callable by owner (governance contract)
   * @dev This will change the address of the contract we're sending the fees to in the future
   * it won't transfer tokens already in the treasury
   * @param _treasury - Address of new treasury contract
   */
  function changeTreasury(address payable _treasury) public onlyOwner {
    // Do nothing if the new treasury address is same as the old
    if (treasury != _treasury) {
      // Change treasury
      treasury = _treasury;

      // Emit treasury change event
      emit TreasuryChange(_treasury);
    }
  }

  /**
   * @notice Change fee rate for future transactions
   * @param _shieldFee - Shield fee
   * @param _unshieldFee - Unshield fee
   * @param _nftFee - Flat fee in wei that applies to NFT transactions
   */
  function changeFee(
    uint120 _shieldFee,
    uint120 _unshieldFee,
    uint256 _nftFee
  ) public onlyOwner {
    if (_shieldFee != shieldFee || _unshieldFee != unshieldFee || _nftFee != nftFee) {
      require(_shieldFee <= BASIS_POINTS / 2, "RailgunLogic: Shield Fee exceeds 50%");
      require(_unshieldFee <= BASIS_POINTS / 2, "RailgunLogic: Unshield Fee exceeds 50%");

      // Change fee
      shieldFee = _shieldFee;
      unshieldFee = _unshieldFee;
      nftFee = _nftFee;

      // Emit fee change event
      emit FeeChange(_shieldFee, _unshieldFee, _nftFee);
    }
  }

  /**
   * @notice Get base and fee amount
   * @param _amount - Amount to calculate for
   * @param _isInclusive - Whether the amount passed in is inclusive of the fee
   * @param _feeBP - Fee basis points
   */
  function getFee(
    uint136 _amount,
    bool _isInclusive,
    uint120 _feeBP
  ) public pure returns (uint120, uint120) {
    // Expand width of amount to uint136 to accommodate full size of (2**120-1)*BASIS_POINTS
    uint136 amountExpanded = _amount;

    // Base is the amount sent into the railgun contract or sent to the target eth address
    // for shields and unshields respectively
    uint136 base;
    // Fee is the amount sent to the treasury
    uint136 fee;

    if (_isInclusive) {
      base = amountExpanded - (amountExpanded * _feeBP) / BASIS_POINTS;
      fee = amountExpanded - base;
    } else {
      base = amountExpanded;
      fee = (BASIS_POINTS * base) / (BASIS_POINTS - _feeBP) - base;
    }

    return (uint120(base), uint120(fee));
  }

  /**
   * @notice Gets token ID value from tokenData
   */
  function getTokenID(TokenData memory _tokenData) public pure returns (bytes32) {
    // ERC20 tokenID is just the address
    if (_tokenData.tokenType == TokenType.ERC20) {
      return bytes32(uint256(uint160(_tokenData.tokenAddress)));
    }

    // Other token types are the keccak256 hash of the token data
    return bytes32(uint256(keccak256(abi.encode(_tokenData))) % SNARK_SCALAR_FIELD);
  }

  /**
   * @notice Hashes a commitment
   */
  function hashCommitment(CommitmentPreimage memory _commitmentPreimage)
    public
    pure
    returns (bytes32)
  {
    return
      PoseidonT4.poseidon(
        [
          _commitmentPreimage.npk,
          getTokenID(_commitmentPreimage.token),
          bytes32(uint256(_commitmentPreimage.value))
        ]
      );
  }

  /**
   * @notice Checks commitment ranges for validity
   * @return valid, reason
   */
  function validateCommitmentPreimage(CommitmentPreimage calldata _note)
    public
    view
    returns (bool, string memory)
  {
    // Note must be more than 0
    if (_note.value == 0) return (false, "Invalid Note Value");

    // Note token must not be blocklisted
    if (TokenBlocklist.tokenBlocklist[_note.token.tokenAddress])
      return (false, "Unsupported Token");

    // Note NPK must be in field
    if (uint256(_note.npk) >= SNARK_SCALAR_FIELD) return (false, "Invalid Note NPK");

    // ERC721 notes should have a value of 1
    if (_note.token.tokenType == TokenType.ERC721 && _note.value != 1)
      return (false, "Invalid NFT Note Value");

    return (true, "");
  }

  /**
   * @notice Transfers tokens to contract and adjusts preimage with fee values
   * @param _note - note to process
   * @return adjusted note
   */
  function transferTokenIn(CommitmentPreimage calldata _note)
    internal
    returns (CommitmentPreimage memory)
  {
    // validateTransaction and accumulateAndNullifyTransaction functions MUST be called
    // in that order BEFORE invoking this function to process an unshield on a transaction
    // else reentrancy attacks are possible

    CommitmentPreimage memory adjustedNote;

    // Process shield request
    if (_note.token.tokenType == TokenType.ERC20) {
      // ERC20

      // Get ERC20 interface
      IERC20 token = IERC20(address(uint160(_note.token.tokenAddress)));

      // Get base and fee amounts
      (uint120 base, uint120 fee) = getFee(_note.value, true, RailgunLogic.shieldFee);

      // Set adjusted preimage
      adjustedNote = CommitmentPreimage({ npk: _note.npk, value: base, token: _note.token });

      // Transfer base to contract address
      token.safeTransferFrom(address(msg.sender), address(this), base);

      // Transfer fee to treasury
      token.safeTransferFrom(address(msg.sender), treasury, fee);
    } else if (_note.token.tokenType == TokenType.ERC721) {
      // ERC721 token

      // Get ERC721 interface
      IERC721 token = IERC721(address(uint160(_note.token.tokenAddress)));

      // No need to adjust note
      adjustedNote = _note;

      // Set tokenID mapping
      tokenIDMapping[getTokenID(_note.token)] = _note.token;

      // Transfer NFT to contract address
      token.transferFrom(address(msg.sender), address(this), _note.token.tokenSubID);
    } else {
      // ERC1155 token
      revert("RailgunLogic: ERC1155 not yet supported");
    }

    return adjustedNote;
  }

  /**
   * @notice Transfers tokens to contract and adjusts preimage with fee values
   * @param _note - note to process
   */
  function transferTokenOut(CommitmentPreimage calldata _note) internal {
    // validateTransaction and accumulateAndNullifyTransaction functions MUST be called
    // in that order BEFORE invoking this function to process an unshield on a transaction
    // else reentrancy attacks are possible

    // Process unshield request
    if (_note.token.tokenType == TokenType.ERC20) {
      // ERC20

      // Get ERC20 interface
      IERC20 token = IERC20(address(uint160(_note.token.tokenAddress)));

      // Get base and fee amounts
      (uint120 base, uint120 fee) = getFee(_note.value, true, unshieldFee);

      // Transfer base to output address
      token.safeTransfer(address(uint160(uint256(_note.npk))), base);

      // Transfer fee to treasury
      token.safeTransfer(treasury, fee);

      // Emit unshield event
      emit Unshield(address(uint160(uint256(_note.npk))), _note.token, base, fee);
    } else if (_note.token.tokenType == TokenType.ERC721) {
      // ERC721 token

      // Get ERC721 interface
      IERC721 token = IERC721(address(uint160(_note.token.tokenAddress)));

      // Transfer NFT to output address
      token.transferFrom(
        address(this),
        address(uint160(uint256(_note.npk))),
        _note.token.tokenSubID
      );

      // Emit unshield event
      emit Unshield(address(uint160(uint256(_note.npk))), _note.token, 1, 0);
    } else {
      // ERC1155 token
      revert("RailgunLogic: ERC1155 not yet supported");
    }
  }

  /**
   * @notice Safety check for badly behaving code
   */
  function checkSafetyVectors() external {
    // Set safety bit
    StorageSlot
      .getBooleanSlot(0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450)
      .value = true;

    // Setup behavior check
    bool result = false;

    // Execute behavior check
    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(0, caller())
      mstore(32, snarkSafetyVector.slot)
      let hash := keccak256(0, 64)
      result := sload(hash)
    }

    require(result, "RailgunLogic: Unsafe vectors");
  }

  /**
   * @notice Adds safety vector
   */
  function addVector(uint256 vector) external onlyOwner {
    snarkSafetyVector[vector] = true;
  }

  /**
   * @notice Removes safety vector
   */
  function removeVector(uint256 vector) external onlyOwner {
    snarkSafetyVector[vector] = false;
  }

  /**
   * @notice Sums number commitments in transaction batch
   */
  function sumCommitments(Transaction[] calldata _transactions) public pure returns (uint256) {
    uint256 commitments = 0;

    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      // The last commitment should NOT be counted if transaction includes unshield
      // The ciphertext length is validated in the transaction validity function to reflect this
      commitments += _transactions[transactionIter].boundParams.commitmentCiphertext.length;
    }

    return commitments;
  }

  /**
   * @notice Verifies transaction validity
   * @return valid, reason
   */
  function validateTransaction(Transaction calldata _transaction)
    public
    view
    returns (bool, string memory)
  {
    // Gas price of eth transaction should be equal or greater than railgun transaction specified min gas price
    // This will only work correctly for type 0 transactions, set to 0 for EIP-1559 transactions
    if (tx.gasprice < _transaction.boundParams.minGasPrice) return (false, "Gas price too low");

    // Adapt contract must either equal 0 or msg.sender
    if (
      _transaction.boundParams.adaptContract != address(0) &&
      _transaction.boundParams.adaptContract != msg.sender
    ) return (false, "Invalid Adapt Contract as Sender");

    // ChainID should match the current EVM chainID
    if (_transaction.boundParams.chainID != block.chainid) return (false, "ChainID mismatch");

    // Merkle root must be a seen historical root
    if (!Commitments.rootHistory[_transaction.boundParams.treeNumber][_transaction.merkleRoot])
      return (false, "Invalid Merkle Root");

    // Loop through each nullifier
    for (
      uint256 nullifierIter = 0;
      nullifierIter < _transaction.nullifiers.length;
      nullifierIter += 1
    ) {
      // If nullifier has been seen before return false
      if (
        Commitments.nullifiers[_transaction.boundParams.treeNumber][
          _transaction.nullifiers[nullifierIter]
        ]
      ) return (false, "Note already spent");
    }

    if (_transaction.boundParams.unshield != UnshieldType.NONE) {
      // Ensure ciphertext length matches the commitments length (minus 1 for unshield output)
      if (
        _transaction.boundParams.commitmentCiphertext.length != _transaction.commitments.length - 1
      ) return (false, "Invalid Note Ciphertext Array Length");

      // Check unshield preimage hash is correct
      bytes32 hash;

      if (_transaction.boundParams.unshield == UnshieldType.REDIRECT) {
        // If redirect is allowed unshield MUST be submitted by original recipient
        hash = hashCommitment(
          CommitmentPreimage({
            npk: bytes32(uint256(uint160(msg.sender))),
            token: _transaction.unshieldPreimage.token,
            value: _transaction.unshieldPreimage.value
          })
        );
      } else {
        hash = hashCommitment(_transaction.unshieldPreimage);
      }

      // Check hash equals the last commitment in array
      if (hash != _transaction.commitments[_transaction.commitments.length - 1])
        return (false, "Invalid Withdraw Note");
    } else {
      // Ensure ciphertext length matches the commitments length
      if (_transaction.boundParams.commitmentCiphertext.length != _transaction.commitments.length)
        return (false, "Invalid Note Ciphertext Array Length");
    }

    // Verify SNARK proof
    if (!Verifier.verify(_transaction)) return (false, "Invalid Snark Proof");

    return (true, "");
  }

  /**
   * @notice Accumulates transaction fields and nullifies nullifiers
   * @param _transaction - transaction to process
   * @param _commitments - commitments accumulator
   * @param _commitmentsStartOffset - number of commitments already in the accumulator
   * @param _ciphertext - commitment ciphertext accumulator, count will be identical to commitments accumulator
   * @return New nullifier start offset, new commitments start offset
   */
  function accumulateAndNullifyTransaction(
    Transaction calldata _transaction,
    bytes32[] memory _commitments,
    uint256 _commitmentsStartOffset,
    CommitmentCiphertext[] memory _ciphertext
  ) internal returns (uint256) {
    // Loop through each nullifier
    for (
      uint256 nullifierIter = 0;
      nullifierIter < _transaction.nullifiers.length;
      nullifierIter += 1
    ) {
      // Set nullifier to seen
      Commitments.nullifiers[_transaction.boundParams.treeNumber][
        _transaction.nullifiers[nullifierIter]
      ] = true;
    }

    // Emit nullifier event
    emit Nullified(_transaction.boundParams.treeNumber, _transaction.nullifiers);

    // Loop through each commitment
    for (
      uint256 commitmentsIter = 0;
      // The last commitment should NOT be accumulated if transaction includes unshield
      // The ciphertext length is validated in the transaction validity function to reflect this
      commitmentsIter < _transaction.boundParams.commitmentCiphertext.length;
      commitmentsIter += 1
    ) {
      // Push commitment to commitments accumulator
      _commitments[_commitmentsStartOffset + commitmentsIter] = _transaction.commitments[
        commitmentsIter
      ];

      // Push ciphertext to ciphertext accumulator
      _ciphertext[_commitmentsStartOffset + commitmentsIter] = _transaction
        .boundParams
        .commitmentCiphertext[commitmentsIter];
    }

    // Return new starting offset
    return _commitmentsStartOffset + _transaction.boundParams.commitmentCiphertext.length;
  }

  uint256[43] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { TokenBlocklist } from "./TokenBlocklist.sol";
import { Commitments } from "./Commitments.sol";
import { RailgunLogic } from "./RailgunLogic.sol";
import { SNARK_SCALAR_FIELD, CommitmentPreimage, CommitmentCiphertext, ShieldCiphertext, TokenType, UnshieldType, Transaction, ShieldRequest } from "./Globals.sol";

/**
 * @title Railgun Smart Wallet
 * @author Railgun Contributors
 * @notice Railgun private smart wallet
 * @dev Entry point for processing private meta-transactions
 */
contract RailgunSmartWallet is RailgunLogic {
  /**
   * @notice Shields requested amount and token, creates a commitment hash from supplied values and adds to tree
   * @param _shieldRequests - list of commitments to shield
   */
  function shield(ShieldRequest[] calldata _shieldRequests) external payable {
    // Insertion and event arrays
    bytes32[] memory insertionLeaves = new bytes32[](_shieldRequests.length);
    CommitmentPreimage[] memory commitments = new CommitmentPreimage[](_shieldRequests.length);
    ShieldCiphertext[] memory shieldCiphertext = new ShieldCiphertext[](_shieldRequests.length);

    // Loop through each note and process
    for (uint256 notesIter = 0; notesIter < _shieldRequests.length; notesIter += 1) {
      // Check note is valid
      (bool valid, string memory reason) = RailgunLogic.validateCommitmentPreimage(
        _shieldRequests[notesIter].preimage
      );
      require(valid, string.concat("RailgunSmartWallet: ", reason));

      // Process shield request and store adjusted note
      commitments[notesIter] = RailgunLogic.transferTokenIn(_shieldRequests[notesIter].preimage);

      // Hash note for merkle tree insertion
      insertionLeaves[notesIter] = RailgunLogic.hashCommitment(commitments[notesIter]);

      // Push shield ciphertext
      shieldCiphertext[notesIter] = _shieldRequests[notesIter].ciphertext;
    }

    // Emit Shield events (for wallets) for the commitments
    emit Shield(Commitments.treeNumber, Commitments.nextLeafIndex, commitments, shieldCiphertext);

    // Push new commitments to merkle tree
    Commitments.insertLeaves(insertionLeaves);

    // Store block number of last event for easier sync
    RailgunLogic.lastEventBlock = block.number;
  }

  /**
   * @notice Execute batch of Railgun snark transactions
   * @param _transactions - Transactions to execute
   */
  function transact(Transaction[] calldata _transactions) external payable {
    uint256 commitmentsCount = RailgunLogic.sumCommitments(_transactions);

    // Create accumulators
    bytes32[] memory commitments = new bytes32[](commitmentsCount);
    uint256 commitmentsStartOffset = 0;
    CommitmentCiphertext[] memory ciphertext = new CommitmentCiphertext[](commitmentsCount);

    // Loop through each transaction, validate, and nullify
    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      // Validate transaction
      (bool valid, string memory reason) = RailgunLogic.validateTransaction(
        _transactions[transactionIter]
      );
      require(valid, string.concat("RailgunSmartWallet: ", reason));

      // Nullify, accumulate, and update offset
      commitmentsStartOffset = RailgunLogic.accumulateAndNullifyTransaction(
        _transactions[transactionIter],
        commitments,
        commitmentsStartOffset,
        ciphertext
      );
    }

    // Loop through each transaction and process unshields
    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      // If unshield is specified, process
      if (_transactions[transactionIter].boundParams.unshield != UnshieldType.NONE) {
        RailgunLogic.transferTokenOut(_transactions[transactionIter].unshieldPreimage);
      }
    }

    // Get insertion parameters
    (
      uint256 insertionTreeNumber,
      uint256 insertionStartIndex
    ) = getInsertionTreeNumberAndStartingIndex(commitments.length);

    // Emit commitment state update
    emit Transact(insertionTreeNumber, insertionStartIndex, commitments, ciphertext);

    // Push commitments to tree after events due to insertLeaves causing side effects
    Commitments.insertLeaves(commitments);

    // Store block number of last event for easier sync
    RailgunLogic.lastEventBlock = block.number;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { G1Point, G2Point, VerifyingKey, SnarkProof, SNARK_SCALAR_FIELD } from "./Globals.sol";

library Snark {
  uint256 private constant PRIME_Q =
    21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint256 private constant PAIRING_INPUT_SIZE = 24;
  uint256 private constant PAIRING_INPUT_WIDTH = 768; // PAIRING_INPUT_SIZE * 32

  /**
   * @notice Computes the negation of point p
   * @dev The negation of p, i.e. p.plus(p.negate()) should be zero.
   * @return result
   */
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    if (p.x == 0 && p.y == 0) return G1Point(0, 0);

    // check for valid points y^2 = x^3 +3 % PRIME_Q
    uint256 rh = mulmod(p.x, p.x, PRIME_Q); //x^2
    rh = mulmod(rh, p.x, PRIME_Q); //x^3
    rh = addmod(rh, 3, PRIME_Q); //x^3 + 3
    uint256 lh = mulmod(p.y, p.y, PRIME_Q); //y^2
    require(lh == rh, "Snark: Invalid negation");

    return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
  }

  /**
   * @notice Adds 2 G1 points
   * @return result
   */
  function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
    // Format inputs
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;

    // Setup output variables
    bool success;
    G1Point memory result;

    // Add points
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0x80, result, 0x40)
    }

    // Check if operation succeeded
    require(success, "Snark: Add Failed");

    return result;
  }

  /**
   * @notice Scalar multiplies two G1 points p, s
   * @dev The product of a point on G1 and a scalar, i.e.
   * p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
   * points p.
   * @return r - result
   */
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
    }

    // Check multiplication succeeded
    require(success, "Snark: Scalar Multiplication Failed");
  }

  /**
   * @notice Performs pairing check on points
   * @dev The result of computing the pairing check
   * e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   * For example,
   * pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   * @return if pairing check passed
   */
  function pairing(
    G1Point memory _a1,
    G2Point memory _a2,
    G1Point memory _b1,
    G2Point memory _b2,
    G1Point memory _c1,
    G2Point memory _c2,
    G1Point memory _d1,
    G2Point memory _d2
  ) internal view returns (bool) {
    uint256[PAIRING_INPUT_SIZE] memory input = [
      _a1.x,
      _a1.y,
      _a2.x[0],
      _a2.x[1],
      _a2.y[0],
      _a2.y[1],
      _b1.x,
      _b1.y,
      _b2.x[0],
      _b2.x[1],
      _b2.y[0],
      _b2.y[1],
      _c1.x,
      _c1.y,
      _c2.x[0],
      _c2.x[1],
      _c2.y[0],
      _c2.y[1],
      _d1.x,
      _d1.y,
      _d2.x[0],
      _d2.x[1],
      _d2.y[0],
      _d2.y[1]
    ];

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, input, PAIRING_INPUT_WIDTH, out, 0x20)
    }

    // Check if operation succeeded
    require(success, "Snark: Pairing Verification Failed");

    return out[0] != 0;
  }

  /**
   * @notice Verifies snark proof against proving key
   * @param _vk - Verification Key
   * @param _proof - snark proof
   * @param _inputs - inputs
   */
  function verify(
    VerifyingKey memory _vk,
    SnarkProof memory _proof,
    uint256[] memory _inputs
  ) internal view returns (bool) {
    // Compute the linear combination vkX
    G1Point memory vkX = G1Point(0, 0);

    // Loop through every input
    for (uint256 i = 0; i < _inputs.length; i += 1) {
      // Make sure inputs are less than SNARK_SCALAR_FIELD
      require(_inputs[i] < SNARK_SCALAR_FIELD, "Snark: Input > SNARK_SCALAR_FIELD");

      // Add to vkX point
      vkX = add(vkX, scalarMul(_vk.ic[i + 1], _inputs[i]));
    }

    // Compute final vkX point
    vkX = add(vkX, _vk.ic[0]);

    // Verify pairing and return
    return
      pairing(
        negate(_proof.a),
        _proof.b,
        _vk.alpha1,
        _vk.beta2,
        vkX,
        _vk.gamma2,
        _proof.c,
        _vk.delta2
      );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Token Blocklist
 * @author Railgun Contributors
 * @notice Blocklist of tokens that are incompatible with the protocol
 * @dev Tokens on this blocklist can't be shielded to railgun.
 * Tokens on this blocklist will still be transferrable
 * internally (as internal transactions have a shielded token ID) and
 * unshieldable (to prevent user funds from being locked)
 * THIS WILL ALWAYS BE A NON-EXHAUSTIVE LIST, DO NOT RELY ON IT BLOCKING ALL
 * INCOMPATIBLE TOKENS
 */
contract TokenBlocklist is OwnableUpgradeable {
  // Events for offchain building of blocklist index
  event AddToBlocklist(address indexed token);
  event RemoveFromBlocklist(address indexed token);

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading
  mapping(address => bool) public tokenBlocklist;

  /**
   * @notice Adds tokens to Blocklist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that are already in the Blocklist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to add to Blocklist
   */
  function addToBlocklist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      // Don't do anything if the token is already blocklisted
      if (!tokenBlocklist[_tokens[i]]) {
        // Set token address in blocklist map to true
        tokenBlocklist[_tokens[i]] = true;

        // Emit event for building index of blocklisted tokens offchain
        emit AddToBlocklist(_tokens[i]);
      }
    }
  }

  /**
   * @notice Removes token from blocklist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that aren't in the blocklist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to remove from blocklist
   */
  function removeFromBlocklist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      // Don't do anything if the token isn't blocklisted
      if (tokenBlocklist[_tokens[i]]) {
        // Set token address in blocklisted map to false (default value)
        delete tokenBlocklist[_tokens[i]];

        // Emit event for building index of blocklisted tokens off chain
        emit RemoveFromBlocklist(_tokens[i]);
      }
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { VERIFICATION_BYPASS, SnarkProof, Transaction, BoundParams, VerifyingKey, SNARK_SCALAR_FIELD } from "./Globals.sol";

import { Snark } from "./Snark.sol";

/**
 * @title Verifier
 * @author Railgun Contributors
 * @notice Verifies snark proof
 * @dev Functions in this contract statelessly verify proofs, nullifiers and adaptID should be checked in RailgunLogic.
 */
contract Verifier is OwnableUpgradeable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement __gap
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Verifying key set event
  event VerifyingKeySet(uint256 nullifiers, uint256 commitments, VerifyingKey verifyingKey);

  // Nullifiers => Commitments => Verification Key
  mapping(uint256 => mapping(uint256 => VerifyingKey)) private verificationKeys;

  /**
   * @notice Sets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   * @param _verifyingKey - verifyingKey to set
   */
  function setVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments,
    VerifyingKey calldata _verifyingKey
  ) public onlyOwner {
    verificationKeys[_nullifiers][_commitments] = _verifyingKey;

    emit VerifyingKeySet(_nullifiers, _commitments, _verifyingKey);
  }

  /**
   * @notice Gets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function getVerificationKey(uint256 _nullifiers, uint256 _commitments)
    public
    view
    returns (VerifyingKey memory)
  {
    // Manually add getter so dynamic IC array is included in response
    return verificationKeys[_nullifiers][_commitments];
  }

  /**
   * @notice Calculates hash of transaction bound params for snark verification
   * @param _boundParams - bound parameters
   * @return bound parameters hash
   */
  function hashBoundParams(BoundParams calldata _boundParams) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(_boundParams))) % SNARK_SCALAR_FIELD;
  }

  /**
   * @notice Verifies inputs against a verification key
   * @param _verifyingKey - verifying key to verify with
   * @param _proof - proof to verify
   * @param _inputs - input to verify
   * @return proof validity
   */
  function verifyProof(
    VerifyingKey memory _verifyingKey,
    SnarkProof calldata _proof,
    uint256[] memory _inputs
  ) public view returns (bool) {
    return Snark.verify(_verifyingKey, _proof, _inputs);
  }

  /**
   * @notice Verifies a transaction
   * @param _transaction to verify
   * @return transaction validity
   */
  function verify(Transaction calldata _transaction) public view returns (bool) {
    uint256 nullifiersLength = _transaction.nullifiers.length;
    uint256 commitmentsLength = _transaction.commitments.length;

    // Retrieve verification key
    VerifyingKey memory verifyingKey = verificationKeys[nullifiersLength][commitmentsLength];

    // Check if verifying key is set
    require(verifyingKey.alpha1.x != 0, "Verifier: Key not set");

    // Calculate inputs
    uint256[] memory inputs = new uint256[](2 + nullifiersLength + commitmentsLength);
    inputs[0] = uint256(_transaction.merkleRoot);

    // Hash bound parameters
    inputs[1] = hashBoundParams(_transaction.boundParams);

    // Loop through nullifiers and add to inputs
    for (uint256 i = 0; i < nullifiersLength; i += 1) {
      inputs[2 + i] = uint256(_transaction.nullifiers[i]);
    }

    // Loop through commitments and add to inputs
    for (uint256 i = 0; i < commitmentsLength; i += 1) {
      inputs[2 + nullifiersLength + i] = uint256(_transaction.commitments[i]);
    }

    // Verify snark proof
    bool validity = verifyProof(verifyingKey, _transaction.proof, inputs);

    // Always return true in gas estimation transaction
    // This is so relayer fees can be calculated without needing to compute a proof
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin == VERIFICATION_BYPASS) {
      return true;
    } else {
      return validity;
    }
  }

  uint256[49] private __gap;
}