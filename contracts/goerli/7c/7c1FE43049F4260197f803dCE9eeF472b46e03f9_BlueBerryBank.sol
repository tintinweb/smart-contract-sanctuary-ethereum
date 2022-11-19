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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
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

pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol';

import './BlueBerryErrors.sol';
import './utils/ERC1155NaiveReceiver.sol';
import './interfaces/IBank.sol';
import './interfaces/IOracle.sol';
import './interfaces/ISafeBox.sol';
import './interfaces/compound/ICErc20.sol';
import './libraries/BBMath.sol';

contract BlueBerryBank is OwnableUpgradeable, ERC1155NaiveReceiver, IBank {
    using BBMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private constant _NO_ID = type(uint256).max;
    address private constant _NO_ADDRESS = address(1);

    uint256 public _GENERAL_LOCK; // TEMPORARY: re-entrancy lock guard.
    uint256 public _IN_EXEC_LOCK; // TEMPORARY: exec lock guard.
    uint256 public override POSITION_ID; // TEMPORARY: position ID currently under execution.
    address public override SPELL; // TEMPORARY: spell currently under execution.

    IProtocolConfig public config;
    IOracle public oracle; // The oracle address for determining prices.
    uint256 public feeBps; // The fee collected as protocol reserve in basis points from interest.
    uint256 public override nextPositionId; // Next available position ID, starting from 1 (see initialize).

    address[] public allBanks; // The list of all listed banks.
    mapping(address => Bank) public banks; // Mapping from token to bank data.
    mapping(address => bool) public cTokenInBank; // Mapping from cToken to its existence in bank.
    mapping(uint256 => Position) public positions; // Mapping from position ID to position data.

    bool public allowContractCalls; // The boolean status whether to allow call from contract (false = onlyEOA)
    mapping(address => bool) public whitelistedTokens; // Mapping from token to whitelist status
    mapping(address => bool) public whitelistedSpells; // Mapping from spell to whitelist status
    mapping(address => bool) public whitelistedContracts; // Mapping from user to whitelist status

    uint256 public bankStatus; // Each bit stores certain bank status, e.g. borrow allowed, repay allowed

    /// @dev Ensure that the function is called from EOA
    /// when allowContractCalls is set to false and caller is not whitelisted
    modifier onlyEOAEx() {
        if (!allowContractCalls && !whitelistedContracts[msg.sender]) {
            if (msg.sender != tx.origin) revert NOT_EOA(msg.sender);
        }
        _;
    }

    /// @dev Reentrancy lock guard.
    modifier lock() {
        if (_GENERAL_LOCK != _NOT_ENTERED) revert LOCKED();
        _GENERAL_LOCK = _ENTERED;
        _;
        _GENERAL_LOCK = _NOT_ENTERED;
    }

    /// @dev Ensure that the function is called from within the execution scope.
    modifier inExec() {
        if (POSITION_ID == _NO_ID) revert NOT_IN_EXEC();
        if (SPELL != msg.sender) revert NOT_FROM_SPELL(msg.sender);
        if (_IN_EXEC_LOCK != _NOT_ENTERED) revert LOCKED();
        _IN_EXEC_LOCK = _ENTERED;
        _;
        _IN_EXEC_LOCK = _NOT_ENTERED;
    }

    /// @dev Ensure that the interest rate of the given token is accrued.
    modifier poke(address token) {
        accrue(token);
        _;
    }

    /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
    /// @param _oracle The oracle smart contract address.
    /// @param _feeBps The fee collected to BlueBerry bank.
    function initialize(
        IOracle _oracle,
        IProtocolConfig _config,
        uint256 _feeBps
    ) external initializer {
        __Ownable_init();
        if (address(_oracle) == address(0) || address(_config) == address(0)) {
            revert ZERO_ADDRESS();
        }
        if (_feeBps > 10000) {
            revert FEE_TOO_HIGH(_feeBps);
        }

        _GENERAL_LOCK = _NOT_ENTERED;
        _IN_EXEC_LOCK = _NOT_ENTERED;
        POSITION_ID = _NO_ID;
        SPELL = _NO_ADDRESS;

        config = _config;
        oracle = _oracle;
        feeBps = _feeBps;
        nextPositionId = 1;
        bankStatus = 7; // allow borrow, lend, repay

        emit SetOracle(address(_oracle));
        emit SetFeeBps(_feeBps);
    }

    /// @dev Return the current executor (the owner of the current position).
    function EXECUTOR() external view override returns (address) {
        uint256 positionId = POSITION_ID;
        if (positionId == _NO_ID) {
            revert NOT_UNDER_EXECUTION();
        }
        return positions[positionId].owner;
    }

    /// @dev Set allowContractCalls
    /// @param ok The status to set allowContractCalls to (false = onlyEOA)
    function setAllowContractCalls(bool ok) external onlyOwner {
        allowContractCalls = ok;
    }

    /// @notice Set whitelist user status
    /// @param contracts list of users to change status
    /// @param statuses list of statuses to change to
    function whitelistContracts(
        address[] calldata contracts,
        bool[] calldata statuses
    ) external onlyOwner {
        if (contracts.length != statuses.length) {
            revert INPUT_ARRAY_MISMATCH();
        }
        for (uint256 idx = 0; idx < contracts.length; idx++) {
            if (contracts[idx] == address(0)) {
                revert ZERO_ADDRESS();
            }
            whitelistedContracts[contracts[idx]] = statuses[idx];
        }
    }

    /// @dev Set whitelist spell status
    /// @param spells list of spells to change status
    /// @param statuses list of statuses to change to
    function whitelistSpells(
        address[] calldata spells,
        bool[] calldata statuses
    ) external onlyOwner {
        if (spells.length != statuses.length) {
            revert INPUT_ARRAY_MISMATCH();
        }
        for (uint256 idx = 0; idx < spells.length; idx++) {
            if (spells[idx] == address(0)) {
                revert ZERO_ADDRESS();
            }
            whitelistedSpells[spells[idx]] = statuses[idx];
        }
    }

    /// @dev Set whitelist token status
    /// @param tokens list of tokens to change status
    /// @param statuses list of statuses to change to
    function whitelistTokens(
        address[] calldata tokens,
        bool[] calldata statuses
    ) external onlyOwner {
        if (tokens.length != statuses.length) {
            revert INPUT_ARRAY_MISMATCH();
        }
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (statuses[idx] && !oracle.support(tokens[idx]))
                revert ORACLE_NOT_SUPPORT(tokens[idx]);
            whitelistedTokens[tokens[idx]] = statuses[idx];
        }
    }

    /**
     * @dev Add a new bank to the ecosystem.
     * @param token The underlying token for the bank.
     * @param cToken The address of the cToken smart contract.
     * @param safeBox The address of safeBox.
     */
    function addBank(
        address token,
        address cToken,
        address safeBox
    ) external onlyOwner {
        Bank storage bank = banks[token];
        if (cTokenInBank[cToken]) revert CTOKEN_ALREADY_ADDED();
        if (bank.isListed) revert BANK_ALREADY_LISTED();
        cTokenInBank[cToken] = true;
        bank.isListed = true;
        if (allBanks.length >= 256) revert BANK_LIMIT();
        bank.index = uint8(allBanks.length);
        bank.cToken = cToken;
        bank.safeBox = safeBox;
        allBanks.push(token);
        emit AddBank(token, cToken);
    }

    /**
     * @dev Update safeBox address of listed bank
     * @param token The underlying token of the bank
     * @param safeBox The address of new SafeBox
     */
    function updateSafeBox(address token, address safeBox) external onlyOwner {
        if (safeBox == address(0)) revert ZERO_ADDRESS();
        Bank storage bank = banks[token];
        if (!bank.isListed) revert BANK_NOT_LISTED(token);
        bank.safeBox = safeBox;
    }

    /**
     * @dev Update bToken address of listed bank
     * @param token The underlying token of the bank
     * @param cToken The address of new SafeBox
     */
    function updateCToken(address token, address cToken) external onlyOwner {
        if (cToken == address(0)) revert ZERO_ADDRESS();
        Bank storage bank = banks[token];
        if (!bank.isListed) revert BANK_NOT_LISTED(token);
        bank.cToken = cToken;
    }

    /// @dev Set the oracle smart contract address.
    /// @param _oracle The new oracle smart contract address.
    function setOracle(IOracle _oracle) external onlyOwner {
        if (address(_oracle) == address(0)) {
            revert ZERO_ADDRESS();
        }
        oracle = _oracle;
        emit SetOracle(address(_oracle));
    }

    /// @dev Set the fee bps value that BlueBerry bank charges.
    /// @param _feeBps The new fee bps value.
    function setFeeBps(uint256 _feeBps) external onlyOwner {
        if (_feeBps > 10000) {
            revert FEE_TOO_HIGH(_feeBps);
        }
        feeBps = _feeBps;
        emit SetFeeBps(_feeBps);
    }

    /// @dev Withdraw the reserve portion of the bank.
    /// @param amount The amount of tokens to withdraw.
    function withdrawReserve(address token, uint256 amount)
        external
        onlyOwner
        lock
    {
        Bank storage bank = banks[token];
        if (!bank.isListed) revert BANK_NOT_LISTED(token);
        bank.reserve -= amount;
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
        emit WithdrawReserve(msg.sender, token, amount);
    }

    /// @dev Set bank status
    /// @param _bankStatus new bank status to change to
    function setBankStatus(uint256 _bankStatus) external onlyOwner {
        bankStatus = _bankStatus;
    }

    /// @dev Bank borrow status allowed or not
    /// @notice check last bit of bankStatus
    function isBorrowAllowed() public view returns (bool) {
        return (bankStatus & 0x01) > 0;
    }

    /// @dev Bank repay status allowed or not
    /// @notice Check second-to-last bit of bankStatus
    function isRepayAllowed() public view returns (bool) {
        return (bankStatus & 0x02) > 0;
    }

    /// @dev Bank borrow status allowed or not
    /// @notice check last bit of bankStatus
    function isLendAllowed() public view returns (bool) {
        return (bankStatus & 0x04) > 0;
    }

    /// @dev Check whether the oracle supports the token
    /// @param token ERC-20 token to check for support
    function support(address token) external view override returns (bool) {
        return oracle.support(token);
    }

    /// @dev Trigger interest accrual for the given bank.
    /// @param token The underlying token to trigger the interest accrual.
    function accrue(address token) public override {
        Bank storage bank = banks[token];
        if (!bank.isListed) revert BANK_NOT_LISTED(token);
        uint256 totalDebt = bank.totalDebt;
        uint256 debt = ICErc20(bank.cToken).borrowBalanceCurrent(bank.safeBox);
        if (debt > totalDebt) {
            uint256 fee = ((debt - totalDebt) * feeBps) / 10000;
            bank.totalDebt = debt;
            bank.reserve += doBorrow(token, fee);
        } else if (totalDebt != debt) {
            bank.totalDebt = debt;
        }
    }

    /// @dev Convenient function to trigger interest accrual for a list of banks.
    /// @param tokens The list of banks to trigger interest accrual.
    function accrueAll(address[] memory tokens) external {
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            accrue(tokens[idx]);
        }
    }

    /// @dev Return the borrow balance for given position and token without triggering interest accrual.
    /// @param positionId The position to query for borrow balance.
    /// @param token The token to query for borrow balance.
    function borrowBalanceStored(uint256 positionId, address token)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalDebt = banks[token].totalDebt;
        uint256 totalShare = banks[token].totalShare;
        uint256 share = positions[positionId].debtShareOf[token];
        if (share == 0 || totalDebt == 0) {
            return 0;
        } else {
            return (share * totalDebt).divCeil(totalShare);
        }
    }

    /// @dev Trigger interest accrual and return the current borrow balance.
    /// @param positionId The position to query for borrow balance.
    /// @param token The token to query for borrow balance.
    function borrowBalanceCurrent(uint256 positionId, address token)
        external
        override
        poke(token)
        returns (uint256)
    {
        return borrowBalanceStored(positionId, token);
    }

    /// @dev Return bank information for the given token.
    /// @param token The token address to query for bank information.
    function getBankInfo(address token)
        external
        view
        override
        returns (
            bool isListed,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        )
    {
        Bank storage bank = banks[token];
        return (
            bank.isListed,
            bank.cToken,
            bank.reserve,
            bank.totalDebt,
            bank.totalShare
        );
    }

    /// @dev Return position information for the given position id.
    /// @param positionId The position id to query for position information.
    function getPositionInfo(uint256 positionId)
        public
        view
        override
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize,
            uint256 risk
        )
    {
        Position storage pos = positions[positionId];
        return (
            pos.owner,
            pos.collToken,
            pos.collId,
            pos.collateralSize,
            getPositionRisk(positionId)
        );
    }

    /// @dev Return current position information
    function getCurrentPositionInfo()
        external
        view
        override
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize,
            uint256 risk
        )
    {
        if (POSITION_ID == _NO_ID) revert BAD_POSITION(POSITION_ID);
        return getPositionInfo(POSITION_ID);
    }

    /// @dev Return the debt share of the given bank token for the given position id.
    /// @param positionId position id to get debt of
    /// @param token ERC20 debt token to query
    function getPositionDebtShareOf(uint256 positionId, address token)
        external
        view
        returns (uint256)
    {
        return positions[positionId].debtShareOf[token];
    }

    /// @dev Return the list of all debts for the given position id.
    /// @param positionId position id to get debts of
    function getPositionDebts(uint256 positionId)
        external
        view
        returns (address[] memory tokens, uint256[] memory debts)
    {
        Position storage pos = positions[positionId];
        uint256 count = 0;
        uint256 bitMap = pos.debtMap;
        while (bitMap > 0) {
            if ((bitMap & 1) != 0) {
                count++;
            }
            bitMap >>= 1;
        }
        tokens = new address[](count);
        debts = new uint256[](count);
        bitMap = pos.debtMap;
        count = 0;
        uint256 idx = 0;
        while (bitMap > 0) {
            if ((bitMap & 1) != 0) {
                address token = allBanks[idx];
                Bank storage bank = banks[token];
                tokens[count] = token;
                debts[count] = (pos.debtShareOf[token] * bank.totalDebt)
                    .divCeil(bank.totalShare);
                count++;
            }
            idx++;
            bitMap >>= 1;
        }
    }

    /**
     * @dev Return the USD value of total collateral of the given position.
     * @param positionId The position ID to query for the collateral value.
     */
    function getPositionValue(uint256 positionId)
        public
        view
        override
        returns (uint256)
    {
        Position storage pos = positions[positionId];
        uint256 size = pos.collateralSize;
        if (size == 0) {
            return 0;
        } else {
            if (pos.collToken == address(0)) revert BAD_COLLATERAL(positionId);
            return oracle.getCollateralValue(pos.collToken, pos.collId, size);
        }
    }

    /// @dev Return the USD value total debt of the given position
    /// @param positionId The position ID to query for the debt value.
    function getDebtValue(uint256 positionId)
        public
        view
        override
        returns (uint256)
    {
        uint256 value = 0;
        Position storage pos = positions[positionId];
        uint256 bitMap = pos.debtMap;
        uint256 idx = 0;
        while (bitMap > 0) {
            if ((bitMap & 1) != 0) {
                address token = allBanks[idx];
                uint256 share = pos.debtShareOf[token];
                Bank storage bank = banks[token];
                uint256 debt = (share * bank.totalDebt).divCeil(
                    bank.totalShare
                );
                value += oracle.getDebtValue(token, debt);
            }
            idx++;
            bitMap >>= 1;
        }
        return value;
    }

    function getPositionRisk(uint256 positionId)
        public
        view
        returns (uint256 risk)
    {
        Position storage pos = positions[positionId];
        uint256 pv = getPositionValue(positionId);
        uint256 ov = getDebtValue(positionId);
        uint256 cv = oracle.getUnderlyingValue(
            pos.underlyingToken,
            pos.underlyingAmount
        );

        if (pv >= ov) risk = 0;
        else {
            risk = ((ov - pv) * 10000) / cv;
        }
    }

    function isLiquidatable(uint256 positionId)
        public
        view
        returns (bool liquidatable)
    {
        Position storage pos = positions[positionId];
        uint256 risk = getPositionRisk(positionId);
        liquidatable = risk >= oracle.getLiqThreshold(pos.underlyingToken);
    }

    /// @dev Liquidate a position. Pay debt for its owner and take the collateral.
    /// @param positionId The position ID to liquidate.
    /// @param debtToken The debt token to repay.
    /// @param amountCall The amount to repay when doing transferFrom call.
    function liquidate(
        uint256 positionId,
        address debtToken,
        uint256 amountCall
    ) external override lock poke(debtToken) {
        if (amountCall == 0) revert ZERO_AMOUNT();
        if (!isLiquidatable(positionId)) revert NOT_LIQUIDATABLE(positionId);
        Position storage pos = positions[positionId];
        (uint256 amountPaid, uint256 share) = repayInternal(
            positionId,
            debtToken,
            amountCall
        );
        if (pos.collToken == address(0)) revert BAD_COLLATERAL(positionId);

        uint256 liqSize = oracle.convertForLiquidation(
            debtToken,
            pos.collToken,
            pos.collId,
            amountPaid
        );
        liqSize = MathUpgradeable.min(liqSize, pos.collateralSize);
        pos.collateralSize -= liqSize;
        IERC1155Upgradeable(pos.collToken).safeTransferFrom(
            address(this),
            msg.sender,
            pos.collId,
            liqSize,
            ''
        );
        emit Liquidate(positionId, msg.sender, debtToken, amountPaid, share, 0);
    }

    /// @dev Execute the action via BlueBerryCaster, calling its function with the supplied data.
    /// @param positionId The position ID to execute the action, or zero for new position.
    /// @param spell The target spell to invoke the execution via BlueBerryCaster.
    /// @param data Extra data to pass to the target for the execution.
    function execute(
        uint256 positionId,
        address spell,
        bytes memory data
    ) external payable lock onlyEOAEx returns (uint256) {
        if (!whitelistedSpells[spell]) revert SPELL_NOT_WHITELISTED(spell);
        if (positionId == 0) {
            positionId = nextPositionId++;
            positions[positionId].owner = msg.sender;
        } else {
            if (positionId >= nextPositionId) revert BAD_POSITION(positionId);
            if (msg.sender != positions[positionId].owner)
                revert NOT_FROM_OWNER(positionId, msg.sender);
        }
        POSITION_ID = positionId;
        SPELL = spell;

        (bool ok, bytes memory returndata) = SPELL.call{value: msg.value}(data);
        if (!ok) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert('bad cast call');
            }
        }

        if (isLiquidatable(positionId)) revert INSUFFICIENT_COLLATERAL();

        POSITION_ID = _NO_ID;
        SPELL = _NO_ADDRESS;

        return positionId;
    }

    /**
     * @dev Lend tokens to bank as isolated collateral. Must only be called while under execution.
     * @param token The token to deposit on bank as isolated collateral
     * @param amount The amount of tokens to lend.
     */
    function lend(address token, uint256 amount)
        external
        override
        inExec
        poke(token)
    {
        if (!isLendAllowed()) revert LEND_NOT_ALLOWED();
        if (!whitelistedTokens[token]) revert TOKEN_NOT_WHITELISTED(token);

        Position storage pos = positions[POSITION_ID];
        Bank storage bank = banks[token];
        IERC20Upgradeable(token).safeTransferFrom(
            pos.owner,
            address(this),
            amount
        );
        amount = doCutDepositFee(token, amount);
        IERC20Upgradeable(token).approve(bank.safeBox, amount);

        pos.underlyingToken = token;
        pos.underlyingAmount += amount;
        pos.underlyingcTokenAmount += ISafeBox(bank.safeBox).deposit(amount);
        bank.totalLend += amount;

        emit Lend(POSITION_ID, msg.sender, token, amount);
    }

    function withdrawLend(address token, uint256 amount)
        external
        override
        inExec
        poke(token)
    {
        Position storage pos = positions[POSITION_ID];
        Bank storage bank = banks[token];
        if (amount == type(uint256).max) {
            amount = pos.underlyingcTokenAmount;
        }

        ISafeBox(bank.safeBox).approve(bank.safeBox, type(uint256).max);
        uint256 wAmount = ISafeBox(bank.safeBox).withdraw(amount);

        wAmount = wAmount > pos.underlyingAmount
            ? pos.underlyingAmount
            : wAmount;

        pos.underlyingcTokenAmount -= amount;
        pos.underlyingAmount -= wAmount;
        bank.totalLend -= wAmount;

        wAmount = doCutWithdrawFee(token, wAmount);

        IERC20Upgradeable(token).safeTransfer(msg.sender, wAmount);
    }

    /// @dev Borrow tokens from that bank. Must only be called while under execution.
    /// @param token The token to borrow from the bank.
    /// @param amount The amount of tokens to borrow.
    function borrow(address token, uint256 amount)
        external
        override
        inExec
        poke(token)
    {
        if (!isBorrowAllowed()) revert BORROW_NOT_ALLOWED();
        if (!whitelistedTokens[token]) revert TOKEN_NOT_WHITELISTED(token);
        Bank storage bank = banks[token];
        Position storage pos = positions[POSITION_ID];
        uint256 totalShare = bank.totalShare;
        uint256 totalDebt = bank.totalDebt;
        uint256 share = totalShare == 0
            ? amount
            : (amount * totalShare).divCeil(totalDebt);
        bank.totalShare += share;
        uint256 newShare = pos.debtShareOf[token] + share;
        pos.debtShareOf[token] = newShare;
        if (newShare > 0) {
            pos.debtMap |= (1 << uint256(bank.index));
        }
        IERC20Upgradeable(token).safeTransfer(
            msg.sender,
            doBorrow(token, amount)
        );
        emit Borrow(POSITION_ID, msg.sender, token, amount, share);
    }

    /// @dev Repay tokens to the bank. Must only be called while under execution.
    /// @param token The token to repay to the bank.
    /// @param amountCall The amount of tokens to repay via transferFrom.
    function repay(address token, uint256 amountCall)
        external
        override
        inExec
        poke(token)
    {
        if (!isRepayAllowed()) revert REPAY_NOT_ALLOWED();
        if (!whitelistedTokens[token]) revert TOKEN_NOT_WHITELISTED(token);
        (uint256 amount, uint256 share) = repayInternal(
            POSITION_ID,
            token,
            amountCall
        );
        emit Repay(POSITION_ID, msg.sender, token, amount, share);
    }

    /// @dev Perform repay action. Return the amount actually taken and the debt share reduced.
    /// @param positionId The position ID to repay the debt.
    /// @param token The bank token to pay the debt.
    /// @param amountCall The amount to repay by calling transferFrom, or -1 for debt size.
    function repayInternal(
        uint256 positionId,
        address token,
        uint256 amountCall
    ) internal returns (uint256, uint256) {
        Bank storage bank = banks[token];
        Position storage pos = positions[positionId];
        uint256 totalShare = bank.totalShare;
        uint256 totalDebt = bank.totalDebt;
        uint256 oldShare = pos.debtShareOf[token];
        uint256 oldDebt = (oldShare * totalDebt).divCeil(totalShare);
        if (amountCall == type(uint256).max) {
            amountCall = oldDebt;
        }
        uint256 paid = doRepay(token, doERC20TransferIn(token, amountCall));
        if (paid > oldDebt) revert REPAY_EXCEEDS_DEBT(paid, oldDebt); // prevent share overflow attack
        uint256 lessShare = paid == oldDebt
            ? oldShare
            : (paid * totalShare) / totalDebt;
        bank.totalShare = totalShare - lessShare;
        uint256 newShare = oldShare - lessShare;
        pos.debtShareOf[token] = newShare;
        if (newShare == 0) {
            pos.debtMap &= ~(1 << uint256(bank.index));
        }
        return (paid, lessShare);
    }

    /// @dev Transmit user assets to the caller, so users only need to approve Bank for spending.
    /// @param token The token to transfer from user to the caller.
    /// @param amount The amount to transfer.
    function transmit(address token, uint256 amount) external override inExec {
        Position storage pos = positions[POSITION_ID];
        IERC20Upgradeable(token).safeTransferFrom(
            pos.owner,
            msg.sender,
            amount
        );
    }

    /// @dev Put more collateral for users. Must only be called during execution.
    /// @param collToken The ERC1155 token to collateral. (spell address)
    /// @param collId The token id to collateral.
    /// @param amountCall The amount of tokens to put via transferFrom.
    function putCollateral(
        address collToken,
        uint256 collId,
        uint256 amountCall
    ) external override inExec {
        Position storage pos = positions[POSITION_ID];
        if (pos.collToken != collToken || pos.collId != collId) {
            if (!oracle.supportWrappedToken(collToken, collId))
                revert ORACLE_NOT_SUPPORT_WTOKEN(collToken);
            if (pos.collateralSize > 0) revert ANOTHER_COL_EXIST(pos.collToken);
            pos.collToken = collToken;
            pos.collId = collId;
        }
        uint256 amount = doERC1155TransferIn(collToken, collId, amountCall);
        pos.collateralSize += amount;
        emit PutCollateral(POSITION_ID, msg.sender, collToken, collId, amount);
    }

    /// @dev Take some collateral back. Must only be called during execution.
    /// @param amount The amount of tokens to take back via transfer.
    function takeCollateral(uint256 amount) external override inExec {
        Position storage pos = positions[POSITION_ID];
        if (amount == type(uint256).max) {
            amount = pos.collateralSize;
        }
        pos.collateralSize -= amount;
        IERC1155Upgradeable(pos.collToken).safeTransferFrom(
            address(this),
            msg.sender,
            pos.collId,
            amount,
            ''
        );
        emit TakeCollateral(
            POSITION_ID,
            msg.sender,
            pos.collToken,
            pos.collId,
            amount
        );
    }

    /**
     * @dev Internal function to perform borrow from the bank and return the amount received.
     * @param token The token to perform borrow action.
     * @param amountCall The amount use in the transferFrom call.
     * NOTE: Caller must ensure that cToken interest was already accrued up to this block.
     */
    function doBorrow(address token, uint256 amountCall)
        internal
        returns (uint256 borrowAmount)
    {
        Bank storage bank = banks[token]; // assume the input is already sanity checked.
        borrowAmount = ISafeBox(bank.safeBox).borrow(amountCall);
        bank.totalDebt += amountCall;
    }

    /**
     * @dev Internal function to perform repay to the bank and return the amount actually repaid.
     * @param token The token to perform repay action.
     * @param amountCall The amount to use in the repay call.
     * NOTE: Caller must ensure that cToken interest was already accrued up to this block.
     */
    function doRepay(address token, uint256 amountCall)
        internal
        returns (uint256 repaidAmount)
    {
        Bank storage bank = banks[token]; // assume the input is already sanity checked.
        IERC20Upgradeable(token).safeTransfer(bank.safeBox, amountCall);
        uint256 newDebt = ISafeBox(bank.safeBox).repay(amountCall);
        repaidAmount = bank.totalDebt - newDebt;
        bank.totalDebt = newDebt;
    }

    function doCutDepositFee(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (config.treasury() == address(0)) revert NO_TREASURY_SET();
        uint256 fee = (amount * config.depositFee()) / 10000;
        IERC20Upgradeable(token).safeTransfer(config.treasury(), fee);
        return amount - fee;
    }

    function doCutWithdrawFee(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (config.treasury() == address(0)) revert NO_TREASURY_SET();
        uint256 fee = (amount * config.withdrawFee()) / 10000;
        IERC20Upgradeable(token).safeTransfer(config.treasury(), fee);
        return amount - fee;
    }

    /// @dev Internal function to perform ERC20 transfer in and return amount actually received.
    /// @param token The token to perform transferFrom action.
    /// @param amountCall The amount use in the transferFrom call.
    function doERC20TransferIn(address token, uint256 amountCall)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = IERC20Upgradeable(token).balanceOf(
            address(this)
        );
        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            amountCall
        );
        uint256 balanceAfter = IERC20Upgradeable(token).balanceOf(
            address(this)
        );
        return balanceAfter - balanceBefore;
    }

    /// @dev Internal function to perform ERC1155 transfer in and return amount actually received.
    /// @param token The token to perform transferFrom action.
    /// @param id The id to perform transferFrom action.
    /// @param amountCall The amount use in the transferFrom call.
    function doERC1155TransferIn(
        address token,
        uint256 id,
        uint256 amountCall
    ) internal returns (uint256) {
        uint256 balanceBefore = IERC1155Upgradeable(token).balanceOf(
            address(this),
            id
        );
        IERC1155Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            amountCall,
            ''
        );
        uint256 balanceAfter = IERC1155Upgradeable(token).balanceOf(
            address(this),
            id
        );
        return balanceAfter - balanceBefore;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

// Common Errors
error ZERO_AMOUNT();
error ZERO_ADDRESS();
error INPUT_ARRAY_MISMATCH();

// Oracle Errors
error TOO_LONG_DELAY(uint256 delayTime);
error NO_MAX_DELAY(address token);
error PRICE_OUTDATED(address token);
error NO_SYM_MAPPING(address token);

error OUT_OF_DEVIATION_CAP(uint256 deviation);
error EXCEED_SOURCE_LEN(uint256 length);
error NO_PRIMARY_SOURCE(address token);
error NO_VALID_SOURCE(address token);
error EXCEED_DEVIATION();

error TOO_LOW_MEAN(uint256 mean);
error NO_MEAN(address token);
error NO_STABLEPOOL(address token);

error PRICE_FAILED(address token);
error LIQ_THRESHOLD_TOO_HIGH(uint256 threshold);

error ORACLE_NOT_SUPPORT(address token);
error ORACLE_NOT_SUPPORT_LP(address lp);
error ORACLE_NOT_SUPPORT_WTOKEN(address wToken);
error ERC1155_NOT_WHITELISTED(address collToken);
error NO_ORACLE_ROUTE(address token);

// Spell
error NOT_BANK(address caller);
error REFUND_ETH_FAILED(uint256 balance);
error NOT_FROM_WETH(address from);
error LP_NOT_WHITELISTED(address lp);

// Ichi Spell
error INCORRECT_LP(address lpToken);
error INCORRECT_PID(uint256 pid);
error INCORRECT_COLTOKEN(address colToken);
error INCORRECT_UNDERLYING(address uToken);
error NOT_FROM_UNIV3(address sender);

// SafeBox
error BORROW_FAILED(uint256 amount);
error REPAY_FAILED(uint256 amount);
error LEND_FAILED(uint256 amount);
error REDEEM_FAILED(uint256 amount);

// Wrapper
error INVALID_TOKEN_ID(uint256 tokenId);
error BAD_PID(uint256 pid);
error BAD_REWARD_PER_SHARE(uint256 rewardPerShare);

// Bank
error FEE_TOO_HIGH(uint256 feeBps);
error NOT_UNDER_EXECUTION();
error BANK_NOT_LISTED(address token);
error BANK_ALREADY_LISTED();
error BANK_LIMIT();
error CTOKEN_ALREADY_ADDED();
error NOT_EOA(address from);
error LOCKED();
error NOT_FROM_SPELL(address from);
error NOT_FROM_OWNER(uint256 positionId, address sender);
error NOT_IN_EXEC();
error ANOTHER_COL_EXIST(address collToken);
error NOT_LIQUIDATABLE(uint256 positionId);
error BAD_POSITION(uint256 posId);
error BAD_COLLATERAL(uint256 positionId);
error INSUFFICIENT_COLLATERAL();
error SPELL_NOT_WHITELISTED(address spell);
error TOKEN_NOT_WHITELISTED(address token);
error REPAY_EXCEEDS_DEBT(uint256 repay, uint256 debt);
error LEND_NOT_ALLOWED();
error BORROW_NOT_ALLOWED();
error REPAY_NOT_ALLOWED();

// Config
error INVALID_FEE_DISTRIBUTION();
error NO_TREASURY_SET();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface ICErc20 {
    function decimals() external view returns (uint8);

    function underlying() external view returns (address);

    function balanceOf(address user) external view returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import './IProtocolConfig.sol';

interface IBank {
    struct Bank {
        bool isListed; // Whether this market exists.
        uint8 index; // Reverse look up index for this bank.
        address cToken; // The CToken to draw liquidity from.
        address safeBox;
        uint256 reserve; // The reserve portion allocated to BlueBerry protocol.
        uint256 totalDebt; // The last recorded total debt since last action.
        uint256 totalShare; // The total debt share count across all open positions.
        uint256 totalLend; // The total lent amount
    }

    struct Position {
        address owner; // The owner of this position.
        address collToken; // The ERC1155 token used as collateral for this position.
        address underlyingToken;
        uint256 underlyingAmount;
        uint256 underlyingcTokenAmount;
        uint256 collId; // The token id used as collateral.
        uint256 collateralSize; // The size of collateral token for this position.
        uint256 debtMap; // Bitmap of nonzero debt. i^th bit is set iff debt share of i^th bank is nonzero.
        mapping(address => uint256) debtShareOf; // The debt share for each token.
    }

    /// The governor adds a new bank gets added to the system.
    event AddBank(address token, address cToken);
    /// The governor sets the address of the oracle smart contract.
    event SetOracle(address oracle);
    /// The governor sets the basis point fee of the bank.
    event SetFeeBps(uint256 feeBps);
    /// The governor withdraw tokens from the reserve of a bank.
    event WithdrawReserve(address user, address token, uint256 amount);
    /// Someone repays tokens to a bank via a spell caller.
    event Lend(
        uint256 positionId,
        address caller,
        address token,
        uint256 amount
    );
    /// Someone borrows tokens from a bank via a spell caller.
    event Borrow(
        uint256 positionId,
        address caller,
        address token,
        uint256 amount,
        uint256 share
    );
    /// Someone repays tokens to a bank via a spell caller.
    event Repay(
        uint256 positionId,
        address caller,
        address token,
        uint256 amount,
        uint256 share
    );
    /// Someone puts tokens as collateral via a spell caller.
    event PutCollateral(
        uint256 positionId,
        address caller,
        address token,
        uint256 id,
        uint256 amount
    );
    /// Someone takes tokens from collateral via a spell caller.
    event TakeCollateral(
        uint256 positionId,
        address caller,
        address token,
        uint256 id,
        uint256 amount
    );
    /// Someone calls liquidatation on a position, paying debt and taking collateral tokens.
    event Liquidate(
        uint256 positionId,
        address liquidator,
        address debtToken,
        uint256 amount,
        uint256 share,
        uint256 bounty
    );

    /// @dev Return the current position while under execution.
    function POSITION_ID() external view returns (uint256);

    /// @dev Return the current target while under execution.
    function SPELL() external view returns (address);

    /// @dev Return the current executor (the owner of the current position).
    function EXECUTOR() external view returns (address);

    function nextPositionId() external view returns (uint256);

    function config() external view returns (IProtocolConfig);

    /// @dev Return bank information for the given token.
    function getBankInfo(address token)
        external
        view
        returns (
            bool isListed,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        );

    function getDebtValue(uint256 positionId) external view returns (uint256);

    function getPositionValue(uint256 positionId)
        external
        view
        returns (uint256);

    /// @dev Return position information for the given position id.
    function getPositionInfo(uint256 positionId)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize,
            uint256 risk
        );

    /// @dev Return current position information.
    function getCurrentPositionInfo()
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize,
            uint256 risk
        );

    function support(address token) external view returns (bool);

    /// @dev Return the borrow balance for given positon and token without trigger interest accrual.
    function borrowBalanceStored(uint256 positionId, address token)
        external
        view
        returns (uint256);

    /// @dev Trigger interest accrual and return the current borrow balance.
    function borrowBalanceCurrent(uint256 positionId, address token)
        external
        returns (uint256);

    /// @dev Lend tokens from the bank.
    function lend(address token, uint256 amount) external;

    /// @dev Withdraw lent tokens from the bank.
    function withdrawLend(address token, uint256 amount) external;

    /// @dev Borrow tokens from the bank.
    function borrow(address token, uint256 amount) external;

    /// @dev Repays tokens to the bank.
    function repay(address token, uint256 amountCall) external;

    /// @dev Transmit user assets to the spell.
    function transmit(address token, uint256 amount) external;

    /// @dev Put more collateral for users.
    function putCollateral(
        address collToken,
        uint256 collId,
        uint256 amountCall
    ) external;

    /// @dev Take some collateral back.
    function takeCollateral(uint256 amount) external;

    /// @dev Liquidate a position.
    function liquidate(
        uint256 positionId,
        address debtToken,
        uint256 amountCall
    ) external;

    function accrue(address token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IOracle {
    /// @dev Return whether the ERC-20 token is supported
    /// @param token The ERC-20 token to check for support
    function support(address token) external view returns (bool);

    /// @dev Return whether the oracle supports evaluating collateral value of the given address.
    /// @param token The ERC-1155 token to check the acceptence.
    /// @param id The token id to check the acceptance.
    function supportWrappedToken(address token, uint256 id)
        external
        view
        returns (bool);

    /**
     * @dev Return the USD value of the given input for collateral purpose.
     * @param token ERC1155 token address to get collateral value
     * @param id ERC1155 token id to get collateral value
     * @param amount Token amount to get collateral value, based 1e18
     */
    function getCollateralValue(
        address token,
        uint256 id,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Return the USD value of the given input for borrow purpose.
     * @param token ERC20 token address to get borrow value
     * @param amount ERC20 token amount to get borrow value
     */
    function getDebtValue(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Return the USD value of isolated collateral.
     * @param token ERC20 token address to get collateral value
     * @param amount ERC20 token amount to get collateral value
     */
    function getUnderlyingValue(address token, uint256 amount)
        external
        view
        returns (uint256);

    function convertForLiquidation(
        address tokenIn,
        address tokenOut,
        uint256 tokenOutId,
        uint256 amountIn
    ) external view returns (uint256);

    function getLiqThreshold(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IProtocolConfig {
    function depositFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function treasury() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface ISafeBox is IERC20Upgradeable {
    function deposit(uint256 amount) external returns (uint256 ctokenAmount);

    function borrow(uint256 amount) external returns (uint256 borrowAmount);

    function repay(uint256 amount) external returns (uint256 newDebt);

    function withdraw(uint256 amount) external returns (uint256 withdrawAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library BBMath {
    /// @dev Computes round-up division.
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';

contract ERC1155NaiveReceiver is IERC1155Receiver {
    uint256[49] private __gap;

    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}