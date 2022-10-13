/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)


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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)


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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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

// File: contracts/interfaces/IAdvancedERC721.sol


interface IAdvancedERC721 {
    function batchMint(address receiver, uint[] calldata tokenIds) external;
}

// File: contracts/lib/LibTransferHelper.sol


library LibTransferHelper {
    function transferETH(address receiver, uint amount) internal {
        (bool ok,) = receiver.call{value : amount}("");
        require(ok, "bad eth transfer");
    }
}

// File: contracts/Distributor.sol


contract Distributor {
    using LibTransferHelper for address;
    using SafeERC20 for IERC20;

    address immutable _OWNER_ADDRESS;
    address _crowdFundingAddress;
    address _royaltyReceiverAddress;
    uint _distributedBasisPoint;

    address[3] _erc20TokenAddresses = [
    // USDT
    0xdAC17F958D2ee523a2206206994597C13D831ec7,
    // USDC
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    // WBTC
    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    ];

    modifier OnlyOwner(){
        require(msg.sender == _OWNER_ADDRESS, "not owner");
        _;
    }

    constructor(
        uint distributedBasisPoint,
        address crowdFundingAddress,
        address royaltyReceiverAddress,
        address ownerAddress
    ){
        require(distributedBasisPoint <= 10000, "invalid bp");
        _distributedBasisPoint = distributedBasisPoint;
        _crowdFundingAddress = crowdFundingAddress;
        _royaltyReceiverAddress = royaltyReceiverAddress;
        _OWNER_ADDRESS = ownerAddress;
    }

    receive() external payable {
        uint ethValue = msg.value;
        if (ethValue > 0) {
            uint receiverValue = ethValue * _distributedBasisPoint / 10000;
            if (receiverValue > 0) {
                // transfer to royalty receiver
                _royaltyReceiverAddress.transferETH(receiverValue);
            }
            // transfer to crowding funding
            _crowdFundingAddress.transferETH(ethValue - receiverValue);
        }
    }

    function getOwnerAddress() external view returns (address){
        return _OWNER_ADDRESS;
    }

    function setDistributedBasisPoint(uint newDistributedBasisPoint) external OnlyOwner {
        require(newDistributedBasisPoint <= 10000, "invalid bp");
        _distributedBasisPoint = newDistributedBasisPoint;
    }

    function setRoyaltyReceiverAddress(address newRoyaltyReceiverAddress) external OnlyOwner {
        _royaltyReceiverAddress = newRoyaltyReceiverAddress;
    }

    // withdraw USDT/USDC/WBTC from Distributor
    function withdraw() external {
        for (uint i; i < 3; ++i) {
            IERC20 token = IERC20(_erc20TokenAddresses[i]);
            uint amount = token.balanceOf(address(this));
            if (amount > 0) {
                token.safeTransfer(_OWNER_ADDRESS, amount);
            }
        }
    }

    function setErc20TokenAddresses(address[3] memory newErc20TokenAddresses) external OnlyOwner {
        _erc20TokenAddresses = newErc20TokenAddresses;
    }

    function getRoyaltyReceiverAddress() external view returns (address){
        return _royaltyReceiverAddress;
    }

    function getCrowdFundingAddress() external view returns (address){
        return _crowdFundingAddress;
    }

    function getDistributedBasisPoint() external view returns (uint){
        return _distributedBasisPoint;
    }
}

// File: contracts/CrowdFunding.sol


contract CrowdFunding is ReentrancyGuard {
    using LibTransferHelper for address;
    using ECDSA for bytes32;

    // address of the crowd funding core
    address immutable _CROWD_FUNDING_CORE_ADDRESS;
    // address for emergency withdrawn
    address immutable _TREASURY_MANAGER_ADDRESS;
    // price of a lot
    uint immutable _LOT_PRICE;
    // total lot number which is set
    uint immutable _TOTAL_LOT_NUMBER;
    // max total supply of target NFT
    uint immutable _NFT_TOTAL_SUPPLY;
    // crowd funding's start time
    uint immutable _START_TIME;
    // crowd funding's end time
    uint immutable _END_TIME;
    // locked duration for fund receiver to withdraw since it's drawn
    uint immutable _LOCKED_DURATION;
    // limited number of lots for an buyer address
    uint immutable _LOT_LIMITED_NUMBER;
    // fund receiver address
    address immutable _FUND_RECEIVER_ADDRESS;

    // target NFT contract address
    address _targetNFTAddress;
    // address to draw and verify signature
    address _verifierAddress;
    uint _lotCounter = 1;
    // locked expiration time for fund receiver to withdraw the crowding fund
    uint _lockedExpirationTime;
    // whether the fund is withdrawn by owner
    bool _isWithdrawn;

    // total royalty amount
    uint256 public totalRoyalty = 0;
    // royalty amount user has claimed per lot
    mapping(address => uint256) public userPerLotClaimed;

    // from lot to the owner
    mapping(uint => address) _lotOwnership;
    // from lot owner to the number of lots owned
    mapping(address => uint) _lotBook;

    event BuyLots(address indexed buyer, uint startLot, uint lotAmount);
    event Refund(address refunder, uint lotAmount);
    event StakeRoyalty(address staker, uint amount);
    event Claim(address indexed claimer, uint amount);
    event WithdrawFund(address payee, uint amount);
    event Draw(uint lotNumberSoldOut);
    event EmergencyWithdraw(uint amount);
    event VerifierAddressChanged(address newVerifierAddress, address preVerifierAddress);

    modifier OnlyTreasuryManager() {
        require(msg.sender == _TREASURY_MANAGER_ADDRESS, "caller is not treasury manager");
        _;
    }

    modifier AlreadyDrawn(){
        require(_lockedExpirationTime != 0, "not drawn");
        _;
    }

    constructor(
        address fundReceiverAddress,
        address treasuryManagerAddress,
        address verifierAddress,
        uint lotPrice,
        uint lotLimitedNumber,
        uint totalLotNumber,
        uint totalSupply,
        uint startTime,
        uint endTime,
        uint lockedDuration
    ){
        _CROWD_FUNDING_CORE_ADDRESS = msg.sender;
        _FUND_RECEIVER_ADDRESS = fundReceiverAddress;
        _TREASURY_MANAGER_ADDRESS = treasuryManagerAddress;
        require(verifierAddress != address(0), "zero verifier address");
        _verifierAddress = verifierAddress;
        require(lotPrice != 0, "zero lot price");
        _LOT_PRICE = lotPrice;
        require(totalLotNumber != 0, "zero total lot number");
        _TOTAL_LOT_NUMBER = totalLotNumber;
        require(totalSupply != 0, "zero total supply");
        require(totalLotNumber >= totalSupply, "total lot number less than total supply");
        _NFT_TOTAL_SUPPLY = totalSupply;
        require(startTime >= block.timestamp, "invalid start time");
        require(endTime > startTime, "invalid end time");
        _START_TIME = startTime;
        _END_TIME = endTime;
        _LOCKED_DURATION = lockedDuration;
        if (lotLimitedNumber == 0) {
            lotLimitedNumber = type(uint).max;
        }
        _LOT_LIMITED_NUMBER = lotLimitedNumber;
    }

    function setTargetNFTAddressByCrowdFundingCore(address targetNFTAddress) external {
        require(msg.sender == _CROWD_FUNDING_CORE_ADDRESS, "unauthorized");
        _targetNFTAddress = targetNFTAddress;
    }

    function buyLots(uint amount) external payable {
        // sanity check
        require(amount != 0, "zero amount");
        uint currentTime = block.timestamp;
        require(currentTime >= _START_TIME, "not start");
        require(currentTime < _END_TIME, "already end");

        uint startLot = _lotCounter;
        uint nextLotCounter = startLot + amount;
        _lotCounter = nextLotCounter;
        require(nextLotCounter - 1 <= _TOTAL_LOT_NUMBER, "exceed max");
        address buyer = msg.sender;
        // check whether the buyer over holds
        uint totalHolding = _lotBook[buyer] + amount;
        require(totalHolding <= _LOT_LIMITED_NUMBER, "over hold");
        // update lot book
        _lotBook[buyer] = totalHolding;
        for (uint i = startLot; i < nextLotCounter; ++i) {
            _lotOwnership[i] = buyer;
        }

        // refund if pay more
        uint refundAmount = msg.value - _LOT_PRICE * amount;
        if (refundAmount > 0) {
            buyer.transferETH(refundAmount);
        }

        emit BuyLots(buyer, startLot, amount);
    }

    function refund() external {
        // sanity check
        require(block.timestamp >= _END_TIME, "crowd funding not ends");
        require(getLotNumberSoldOut() < _NFT_TOTAL_SUPPLY, "crowd funding succeeded");
        address sender = msg.sender;
        uint lotAmount = _lotBook[sender];
        require(lotAmount != 0, "no lot");

        // clear lot book
        delete _lotBook[sender];

        // refund
        sender.transferETH(_LOT_PRICE * lotAmount);
        emit Refund(sender, lotAmount);
    }

    function stakeRoyalty() public payable AlreadyDrawn {
        uint256 amount = msg.value;
        require(amount != 0, "royalty is zero");
        totalRoyalty += amount;
        emit StakeRoyalty(msg.sender, amount);
    }

    function claim() external nonReentrant AlreadyDrawn {
        address sender = msg.sender;
        uint256 perLotRoyalty = perLotRoyalty();
        uint256 reward = (perLotRoyalty - userPerLotClaimed[sender]) * _lotBook[sender];
        require(reward != 0, "no reward");
        userPerLotClaimed[sender] = perLotRoyalty;
        sender.transferETH(reward);
        emit Claim(sender, reward);
    }

    receive() external payable {
        stakeRoyalty();
    }

    function batchMint(
        uint[] calldata lots,
        uint[] calldata tokenIds,
        bytes[] calldata signatures
    )
    external AlreadyDrawn
    {
        uint len = lots.length;
        require(len != 0, "zero length");
        require(len == tokenIds.length, "unmatched token ids length");
        require(len == signatures.length, "unmatched sigs length");
        address sender = msg.sender;
        for (uint i = 0; i < len; ++i) {
            uint lot = lots[i];
            // check ownership
            require(_lotOwnership[lot] == sender, "no ownership");
            // verify signature
            require(
                _verifierAddress == keccak256(
                abi.encodePacked(
                    lot,
                    tokenIds[i],
                    _targetNFTAddress,
                    sender
                )
            ).toEthSignedMessageHash().recover(signatures[i]),
                "invalid sig"
            );
        }

        // call target nft address
        IAdvancedERC721(_targetNFTAddress).batchMint(sender, tokenIds);
    }

    function draw() external {
        require(_verifierAddress == msg.sender, "unauthorized");
        require(_lockedExpirationTime == 0, "already drawn");
        uint currentTime = block.timestamp;
        require(currentTime >= _END_TIME, "crowd funding not ends");
        uint lotNumberSoldOut = getLotNumberSoldOut();
        require(lotNumberSoldOut >= _NFT_TOTAL_SUPPLY, "not reach nft total supply");
        // set locked end time
        _lockedExpirationTime = currentTime + _LOCKED_DURATION;
        emit Draw(lotNumberSoldOut);
    }

    // fund receiver could only withdraw the fund once after the locked expiration
    function withdrawFund() external {
        uint lockedExpirationTime = _lockedExpirationTime;
        require(lockedExpirationTime != 0, "not drawn");
        require(block.timestamp >= lockedExpirationTime, "under locked");
        require(!_isWithdrawn, "withdrawn");

        _isWithdrawn = true;
        address sender = msg.sender;
        require(_FUND_RECEIVER_ADDRESS == sender, "unauthorized");

        uint totalFund = _LOT_PRICE * getLotNumberSoldOut();
        sender.transferETH(totalFund);
        emit WithdrawFund(sender, totalFund);
    }

    // boss can withdraw all of the balance for emergency
    function emergencyWithdraw() external OnlyTreasuryManager {
        uint amount = address(this).balance;
        msg.sender.transferETH(amount);
        emit EmergencyWithdraw(amount);
    }

    function setVerifierAddress(address newVerifierAddress) external OnlyTreasuryManager {
        require(newVerifierAddress != address(0), "zero verifier address");
        address preVerifierAddress = _verifierAddress;
        _verifierAddress = newVerifierAddress;
        emit VerifierAddressChanged(newVerifierAddress, preVerifierAddress);
    }

    function perLotRoyalty() public view returns (uint) {
        return totalRoyalty / getLotNumberSoldOut();
    }

    function getLotNumberSoldOut() public view returns (uint){
        return _lotCounter - 1;
    }

    function isFundWithdrawn() external view returns (bool){
        return _isWithdrawn;
    }

    function getFundReceiverAddress() external view returns (address){
        return _FUND_RECEIVER_ADDRESS;
    }

    function getEndTime() external view returns (uint){
        return _END_TIME;
    }

    function getStartTime() external view returns (uint){
        return _START_TIME;
    }

    function getNFTTotalSupply() external view returns (uint){
        return _NFT_TOTAL_SUPPLY;
    }

    function getLotPrice() external view returns (uint){
        return _LOT_PRICE;
    }

    function getTotalLotNumber() external view returns (uint){
        return _TOTAL_LOT_NUMBER;
    }

    function getAccountLotNumber(address account) external view returns (uint){
        return _lotBook[account];
    }

    function getLotOwner(uint lot) external view returns (address owner){
        owner = _lotOwnership[lot];
        if (_lotBook[owner] == 0) {
            return address(0);
        }
    }

    function getVerifierAddress() external view returns (address){
        return _verifierAddress;
    }

    function getLockedExpirationTime() external view returns (uint){
        return _lockedExpirationTime;
    }

    function getTotalFundRemaining() external view returns (uint totalFund){
        if (_lockedExpirationTime != 0 && block.timestamp >= _lockedExpirationTime && !_isWithdrawn) {
            totalFund = _LOT_PRICE * getLotNumberSoldOut();
        }
    }

    function getLockedDuration() external view returns (uint){
        return _LOCKED_DURATION;
    }

    function getTreasuryManagerAddress() external view returns (address){
        return _TREASURY_MANAGER_ADDRESS;
    }

    function getTargetNFTAddress() external view returns (address){
        return _targetNFTAddress;
    }

    function getCrowdFundingCoreAddress() external view returns (address){
        return _CROWD_FUNDING_CORE_ADDRESS;
    }

    function getLotLimitedNumber() external view returns (uint){
        return _LOT_LIMITED_NUMBER;
    }
}

// File: contracts/lib/LibParams.sol


library LibParams {
    struct Params {
        ParamsForCrowdFundingAndDistributor paramsForCrowdFundingAndDistributor;
        ParamsForAdvancedERC721 paramsForAdvancedERC721;
    }

    struct ParamsForCrowdFundingAndDistributor {
        uint distributedBasisPoint;
        uint lotPrice;
        uint lotLimitedNumber;
        uint totalLotNumber;
        uint totalSupply;
        uint startTime;
        uint endTime;
        uint lockedDuration;
    }

    struct ParamsForAdvancedERC721 {
        string name;
        string symbol;
        string baseUri;
        string contractUri;
        address defaultRoyaltyReceiverAddress;
        uint96 defaultFeeNumerator;
    }
}

// File: contracts/interfaces/IAdvancedERC721Factory.sol


interface IAdvancedERC721Factory {
    function issueAdvancedERC721(
        address crowdFundingAddress,
        uint totalSupply,
        address ownerAddress,
        LibParams.ParamsForAdvancedERC721 memory paramsForAdvancedERC721
    ) external returns (address);
}

// File: contracts/CrowdFundingCore.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract CrowdFundingCore is OwnableUpgradeable {
    // address for advanced erc721 factory
    address _advancedERC721FactoryAddress;
    // address for emergency withdraw
    address _treasuryManagerAddress;
    // address for verifier
    address _verifierAddress;
    // from issuer address to its nonce for next deployment
    mapping(address => uint) _issuerNonces;

    event IssueNFTWithCrowdFunding(address crowdFundingAddress, address distributorAddress, address nftAddress);

    function __CrowdFundingCore_init(
        address treasuryManagerAddress,
        address verifierAddress
    ) external initializer {
        __Ownable_init_unchained();
        _treasuryManagerAddress = treasuryManagerAddress;
        require(verifierAddress != address(0), "zero verifier address");
        _verifierAddress = verifierAddress;
    }

    function issueNFTWithCrowdFunding(LibParams.Params calldata params) external {
        address sender = msg.sender;
        uint currentIssuerNonce = _issuerNonces[sender];
        bytes32 currentSalt = bytes32(currentIssuerNonce);
    unchecked{
        _issuerNonces[sender] = currentIssuerNonce + 1;
    }

        // deploy crowd funding pool with salt
        CrowdFunding crowdFunding = new CrowdFunding{salt : currentSalt}(
            sender,
            _treasuryManagerAddress,
            _verifierAddress,
            params.paramsForCrowdFundingAndDistributor.lotPrice,
            params.paramsForCrowdFundingAndDistributor.lotLimitedNumber,
            params.paramsForCrowdFundingAndDistributor.totalLotNumber,
            params.paramsForCrowdFundingAndDistributor.totalSupply,
            params.paramsForCrowdFundingAndDistributor.startTime,
            params.paramsForCrowdFundingAndDistributor.endTime,
            params.paramsForCrowdFundingAndDistributor.lockedDuration
        );

        // deploy advanced erc721 by AdvancedERC721Factory
        address advancedERC721Address = IAdvancedERC721Factory(_advancedERC721FactoryAddress).issueAdvancedERC721(
            address(crowdFunding),
            params.paramsForCrowdFundingAndDistributor.totalSupply,
            sender,
            params.paramsForAdvancedERC721
        );

        crowdFunding.setTargetNFTAddressByCrowdFundingCore(advancedERC721Address);

        // deploy distributor with salt
        Distributor distributor = new Distributor{salt : currentSalt}(
            params.paramsForCrowdFundingAndDistributor.distributedBasisPoint,
            address(crowdFunding),
            sender,
            owner()
        );

        emit IssueNFTWithCrowdFunding(address(crowdFunding), address(distributor), advancedERC721Address);
    }

    function preCalculateDistributorAddress(
        LibParams.ParamsForCrowdFundingAndDistributor calldata paramsForCrowdFundingAndDistributor,
        address issuerAddress
    ) external view returns (address) {
        bytes32 currentSalt = bytes32(_issuerNonces[issuerAddress]);
        // calculate the contract address of CrowdFunding
        address crowdFundingAddress = _preCalculateCrowdFundingAddress(
            currentSalt,
            issuerAddress,
            paramsForCrowdFundingAndDistributor.lotPrice,
            paramsForCrowdFundingAndDistributor.lotLimitedNumber,
            paramsForCrowdFundingAndDistributor.totalLotNumber,
            paramsForCrowdFundingAndDistributor.totalSupply,
            paramsForCrowdFundingAndDistributor.startTime,
            paramsForCrowdFundingAndDistributor.endTime,
            paramsForCrowdFundingAndDistributor.lockedDuration
        );

        return _preCalculateDistributorAddress(
            currentSalt,
            paramsForCrowdFundingAndDistributor.distributedBasisPoint,
            crowdFundingAddress,
            issuerAddress
        );
    }

    function setTreasuryManagerAddress(address newTreasuryManagerAddress) external onlyOwner {
        _treasuryManagerAddress = newTreasuryManagerAddress;
    }

    function setVerifierAddress(address newVerifierAddress) external onlyOwner {
        require(newVerifierAddress != address(0), "zero verifier address");
        _verifierAddress = newVerifierAddress;
    }

    function setAdvancedERC721FactoryAddress(address newAdvancedERC721FactoryAddress) external onlyOwner {
        _advancedERC721FactoryAddress = newAdvancedERC721FactoryAddress;
    }

    function getTreasuryManagerAddress() external view returns (address){
        return _treasuryManagerAddress;
    }

    function getVerifierAddress() external view returns (address){
        return _verifierAddress;
    }

    function getAdvancedERC721FactoryAddress() external view returns (address){
        return _advancedERC721FactoryAddress;
    }

    function _preCalculateDistributorAddress(
        bytes32 salt,
        uint distributedBasisPoint,
        address crowdFundingAddress,
        address royaltyReceiverAddress
    ) private view returns (address){
        return address(uint160(uint(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        address(this),
                        salt,
                        keccak256(
                            abi.encodePacked(
                                type(Distributor).creationCode,
                                abi.encode(
                                    distributedBasisPoint,
                                    crowdFundingAddress,
                                    royaltyReceiverAddress,
                                    owner()
                                )
                            )
                        )
                    )
                )
            )));
    }

    function _preCalculateCrowdFundingAddress(
        bytes32 salt,
        address issuerAddress,
        uint lotPrice,
        uint lotLimitedNumber,
        uint totalLotNumber,
        uint totalSupply,
        uint startTime,
        uint endTime,
        uint lockedDuration
    ) private view returns (address){
        return address(uint160(uint(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        address(this),
                        salt,
                        keccak256(
                            abi.encodePacked(
                                type(CrowdFunding).creationCode,
                                abi.encode(
                                    issuerAddress,
                                    _treasuryManagerAddress,
                                    _verifierAddress,
                                    lotPrice,
                                    lotLimitedNumber,
                                    totalLotNumber,
                                    totalSupply,
                                    startTime,
                                    endTime,
                                    lockedDuration
                                )
                            )
                        )
                    )
                )
            )));
    }

    uint[46] __gap;
}