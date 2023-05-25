/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/TokenPreSale.sol


pragma solidity >=0.8.0 <0.9.0;









contract TokenPreSale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    struct Presale {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 tokensToSell;
        uint256 inSale;
    }

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //  State
    //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 public presaleId;
    address public fundsReceiver;
    uint256 public referralBonusPercentage;
    uint256 public buyerBonusPercentage;

    IERC20 token;
    bool hasEnded;
    IERC20Upgradeable public USDTInterface;
    IERC20Upgradeable public USDCInterface;
    AggregatorV3Interface internal ethOracleAggregatorInterface; // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;
    mapping(address => mapping(uint256 => Vesting)) public userVesting;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //  Events
    //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event TokensBought(
        address indexed user,
        uint256 indexed id,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event PresaleCreated(uint256 indexed _id, uint256 _totalTokens, uint256 _startTime, uint256 _endTime);
    event PresaleUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);
    event PresaleUpdatedBool(bytes32 indexed key, bool prevValue, bool newValue, uint256 timestamp);
    event TokensClaimed(address indexed user, uint256 indexed id, uint256 amount, uint256 timestamp);
    event UserVestingUpdated(address indexed user, uint256 amount, bool isWithdrawal);
    event Finalized(address by);
    event PresalePaused(uint256 indexed id, uint256 timestamp);
    event PresaleUnpaused(uint256 indexed id, uint256 timestamp);

    /**
     * @dev Initializes the contract and sets key parameters
     * @param _oracle Oracle contract to fetch ETH/USD price
     * @param _usdt USDT token contract address
     * @param _usdc USDC token contract address
     */
    constructor(address _oracle, address _usdt, address _usdc, address _token)  Ownable() ReentrancyGuard() {
        require(_oracle != address(0), "TokenPreSale#constructor: zero aggregator address");
        require(_usdt != address(0), "TokenPreSale#constructor: zero usd address");
        require(_usdc != address(0), "TokenPreSale#constructor: zero usc address");
        require(_token != address(0), "TokenPreSale#constructor: zero token address");

        token = IERC20(_token);
        ethOracleAggregatorInterface = AggregatorV3Interface(_oracle);
        USDTInterface = IERC20Upgradeable(_usdt);
        USDCInterface = IERC20Upgradeable(_usdc);

        fundsReceiver = _msgSender();
    }

    /**
     * @dev Creates a new presale
     * @param _startTime start time of the sale
     * @param _endTime end time of the sale
     * @param _price Per token price multiplied by (10**18)
     * @param _tokensToSell No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     */
    function createPresale(uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _tokensToSell) external onlyOwner {
        require(_startTime > block.timestamp, "TokenPresale#createPresale: startTime is below block.timestamp");
        require(_endTime > _startTime, "TokenPresale#createPresale: endTime < startTime");
        require(_price > 0, "TokenPresale#createPresale: price can't be zero");
        require(_tokensToSell > 0, "TokenPresale#createPresale: tokens to sell cant be zero");

        presaleId++;

        presale[presaleId] = Presale(
            _startTime,
            _endTime,
            _price,
            _tokensToSell,
            _tokensToSell
        );

        emit PresaleCreated(presaleId, _tokensToSell, _startTime, _endTime);
    }

    /**
     * @dev To update the sale times
     * @param _id Presale id to update
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(uint256 _id, uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_id > 0 && _id <= presaleId, "TokePreSale#changeSaleTimes: invalid presale id");
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            require(
                block.timestamp < presale[_id].startTime,
                "Sale already started"
            );
            require(block.timestamp < _startTime, "Sale time in past");
            uint256 prevValue = presale[_id].startTime;
            presale[_id].startTime = _startTime;
            emit PresaleUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }

        if (_endTime > 0) {
            require(
                block.timestamp < presale[_id].endTime,
                "Sale already ended"
            );
            require(_endTime > presale[_id].startTime, "Invalid endTime");
            uint256 prevValue = presale[_id].endTime;
            presale[_id].endTime = _endTime;
            emit PresaleUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    /**
     * @dev To update the referral bonus percentage
     * @param newValue New referral bonus percentage
     */
    function changeReferralBonusPercentage(uint256 newValue) external onlyOwner {
        uint256 prevValue = referralBonusPercentage;
        referralBonusPercentage = newValue;
        emit PresaleUpdated(
            bytes32("REFERRAL_BONUS_PERCENTAGE"),
            prevValue,
            newValue,
            block.timestamp
        );
    }

    /**
     * @dev To update the referral bonus percentage
     * @param newValue New referral bonus percentage
     */
    function changeBuyerBonusPercentage(uint256 newValue) external onlyOwner {
        uint256 prevValue = buyerBonusPercentage;
        buyerBonusPercentage = newValue;
        emit PresaleUpdated(
            bytes32("BUYER_BONUS_PERCENTAGE"),
            prevValue,
            newValue,
            block.timestamp
        );
    }

    /**
     * @dev Change ETH Oracle Address
     * @param newValue New oracle address
     */
    function changeEthOracleAddress(address newValue) external onlyOwner {
        ethOracleAggregatorInterface = AggregatorV3Interface(newValue);
    }

    /**
     * @dev Change USDT Contract Address
     * @param newValue New USDT contract address
     */
    function changeUsdtContractAddress(address newValue) external onlyOwner {
        USDTInterface = IERC20Upgradeable(newValue);
    }

    /**
     * @dev Change USDC Contract Address
     * @param newValue New USDC contract address
     */
    function changeUsdcContractAddress(address newValue) external onlyOwner {
        USDCInterface = IERC20Upgradeable(newValue);
    }

    /**
     * @dev To pause the presale
     * @param _id Presale id to update
     */
    function pausePresale(uint256 _id) external onlyOwner {
        require(!paused[_id], "TokePreSale#pausePresale: presale already paused");
        paused[_id] = true;
        emit PresalePaused(_id, block.timestamp);
    }

    /**
     * @dev To unpause the presale
     * @param _id Presale id to update
     */
    function unPausePresale(uint256 _id) external onlyOwner {
        require(paused[_id], "TokePreSale#pausePresale: presale not  paused");
        paused[_id] = false;
        emit PresaleUnpaused(_id, block.timestamp);
    }

    /**
     * @dev Change funds wallet receiver
     * @param _wallet Wallet address of new funds receiver
     */
    function changeFundsWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Invalid parameters");
        fundsReceiver = _wallet;
    }

    /**
     * @dev Finalize all presales
     */
    function finalize() external onlyOwner {
        hasEnded = true;
        emit Finalized(msg.sender);
    }

    /**
     * @dev To buy into a presale using USDT
     * @param _id Presale id
     * @param amount No of tokens to buy
     * @param referralAddress Referral Address
     */
    function buyWithUSDT(uint256 _id, uint256 amount, address referralAddress) external returns (bool){
        return buyWithUSD(_id, amount, USDTInterface, referralAddress);
    }

    /**
    * @dev To buy into a presale using USDC
     * @param _id Presale id
     * @param amount No of tokens to buy
     * @param referralAddress Referral Address
     */
    function buyWithUSDC(uint256 _id, uint256 amount, address referralAddress) external returns (bool) {
        return buyWithUSD(_id, amount, USDCInterface, referralAddress);
    }

    /**
     * @dev To buy into a presale using USD
     * @param _id Presale id
     * @param amount No of tokens to buy
     * @param referralAddress Referral Address
     */
    function buyWithUSD(uint256 _id, uint256 amount, IERC20Upgradeable usdToken, address referralAddress) private returns (bool) {
        _checkPresaleState(_id, amount);

        uint256 totalPriceUSD = amount.mul(presale[_id].price);
        // tether has 6 decimals, the price is denominated with 8 decimals
        totalPriceUSD = totalPriceUSD.div(1e2);
        _updatePresaleStatus(_id, amount, referralAddress);

        uint256 ourAllowance = usdToken.allowance(_msgSender(), address(this));
        require(totalPriceUSD <= ourAllowance, "TokenPreSale#buyWithUSD: not enough USDC/T token allowed");
        (bool success,) = address(usdToken).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                fundsReceiver,
                totalPriceUSD
            )
        );
        require(success, "Token payment failed");
        emit TokensBought(_msgSender(), _id, amount, totalPriceUSD, block.timestamp);
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param _id Presale id
     * @param amount No of tokens to buy
     * @param referralAddress Referral Address
     */
    function buyWithEth(uint256 _id, uint256 amount, address referralAddress)
    external payable nonReentrant returns (bool) {
        _checkPresaleState(_id, amount);

        uint256 usdPrice = amount.mul(presale[_id].price);
        uint256 ethAmount = usdPrice.mul(1e18).div(ethUSD_dec8());

        require(msg.value >= ethAmount, "TokenPresale#buyWithEth: not enough funds");
        uint256 excess = msg.value - ethAmount;
        _updatePresaleStatus(_id, amount, referralAddress);

        _sendValue(payable(fundsReceiver), ethAmount);
        if (excess > 0) {
            _sendValue(payable(_msgSender()), excess);
        }

        emit TokensBought(_msgSender(), _id, amount, ethAmount, block.timestamp);

        return true;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param user User address
     * @param _id Presale id
     */
    function claim(address user, uint256 _id) public returns (bool) {
        require(hasEnded, "TokenPreSale#claim: token sale has not ended yet");
        require(_id > 0 && _id <= presaleId, "TokePreSale#claim: invalid presale id");
        uint256 amount = claimableAmount(user, _id);
        require(amount > 0, "TokenPreSale#claim: zero claim amount");
        require(
            amount <=
            token.balanceOf(
                address(this)
            ),
            "TokenPreSale#claim: not enough tokens in the contract"
        );
        userVesting[user][_id].claimedAmount += amount;
        bool status = token.transfer(
            user,
            amount
        );
        require(status, "TokenPreSale#claim: token transfer failed");
        emit TokensClaimed(user, _id, amount, block.timestamp);
        return true;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param users Array of user addresses
     * @param _id Presale id
     */
    function claimMultiple(address[] calldata users, uint256 _id) external returns (bool){
        require(users.length > 0, "Zero users length");
        for (uint256 i; i < users.length; i++) {
            require(claim(users[i], _id), "Claim failed");
        }
        return true;
    }

    /**
     * @dev Manually withdraw stuck tokens
     * @param _token Token address
     * @param amount Amount of tokens to transfer
     */
    function WithdrawTokens(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(fundsReceiver, amount);
    }

    /**
     * @dev Manually withdraw stuck ethers
     * @param amount Amount of ethers to transfer
     */
    function WithdrawContractFunds(uint256 amount) external onlyOwner {
        _sendValue(payable(fundsReceiver), amount);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //  Internal
    //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @dev To buy into a presale using ETH
     * @param _presaleId Presale id
     * @param amount No of tokens to buy
     * @param referralAddress Referral Address
     */
    function _updatePresaleStatus(uint256 _presaleId, uint256 amount, address referralAddress) private {
        uint256 buyerBonus = getBonusAmount(referralAddress, amount, true);
        _updateUserVesting(_presaleId, amount + buyerBonus, _msgSender());

        uint256 referralBonus = getBonusAmount(referralAddress, amount, false);
        if (referralBonus > 0) {
            _updateUserVesting(_presaleId, referralBonus, referralAddress);
        }

        presale[_presaleId].inSale -= (amount + buyerBonus + referralBonus);
    }

    /**
     * @dev To buy into a presale using ETH
     * @param _presaleId Presale id
     * @param amount No of tokens to buy
     * @param beneficiary Buyer or Referral Address
     */
    function _updateUserVesting(uint256 _presaleId, uint256 amount, address beneficiary) private {
        Presale memory _presale = presale[_presaleId];

        uint256 amount18Dec = amount.mul(1e18);

        if (userVesting[beneficiary][_presaleId].totalAmount > 0) {
            userVesting[beneficiary][_presaleId].totalAmount += amount18Dec;
        } else {
            userVesting[beneficiary][_presaleId] = Vesting(amount18Dec, 0);
        }

        emit UserVestingUpdated(beneficiary, amount18Dec, false);
    }

    function _sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "TokenPreSale#_sendValue: low balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "TokenPreSale#_sendValue: payment failed");
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //  Views
    //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Helper function to get claimable tokens for a given presale.
     * @param user User address
     * @param _id Presale id
     */
    function claimableAmount(address user, uint256 _id) public view returns (uint256){
        Vesting memory _user = userVesting[user][_id];
        require(_user.totalAmount > 0, "TokenPreSale#claimableAmount: nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "TokenPreSale#claimableAmount: already claimed");
        return amount;
    }

    function _checkPresaleState(uint256 _id, uint256 amount) internal view {
        require(!hasEnded, "TokePreSale#checkPresaleState:all token presales have ended");
        require(_id > 0 && _id <= presaleId, "TokePreSale#checkPresaleState: invalid presale id");
        require(block.timestamp >= presale[_id].startTime, "TokenPreSale#checkPresaleState: startTime is above block time");
        require(block.timestamp <= presale[_id].endTime, "TokenPreSale#checkPresaleState: endTime is below block time");
        require(amount > 0 && amount <= presale[_id].inSale, "TokenPreSale#checkPresaleState: invalid sale amount");
        require(!paused[_id], "TokenPresale#checkPresaleState: presale paused");
    }

    /**
     * @dev Calculate bonus amount
     * @param referralAddress: Referral Address
     * @param baseAmount: Base amount
     * @return isBuyer true: Buyer - false: Referral
     */
    function getBonusAmount(address referralAddress, uint256 baseAmount, bool isBuyer) public view returns (uint256) {
        if (referralAddress == address(0) || referralAddress == _msgSender()) {
            return 0;
        }

        uint256 bonusPercentage = (isBuyer) ? buyerBonusPercentage : referralBonusPercentage;
        uint256 percentageValue = baseAmount.mul(bonusPercentage).div(100);
        return percentageValue;
    }

    /**
     * @dev Calculate percentage
     * @param value: Value
     * @param percentage: Percentage
     * @return uint256 Result of Percentage of value
     */
    function calculatePercentage(uint256 value, uint256 percentage) public pure returns (uint256) {
        require(percentage <= 100, "Percentage must be between 0 and 100");
        uint256 percentageValue = value.mul(percentage).div(100);
        return percentageValue;
    }

    function priceInEth(uint256 _id, uint256 amount) external view returns (uint256) {
        uint256 usdPrice = amount.mul(presale[_id].price);
        return usdPrice.mul(1e18).div(ethUSD_dec8());
    }

    function priceInUSD(uint256 _id, uint256 amount) external view returns (uint256){
        return amount.mul(presale[_id].price);
    }

    function amountFromETH(uint256 _id, uint256 amount) external view returns (uint256) {
        return ethUSD_dec8().mul(amount).div(presale[_id].price).div(1e18);
    }

    function amountFromUSD(uint256 _id, uint256 usd) external view returns (uint256) {
        return usd.div(presale[_id].price);
    }

    /**
        * @dev To get latest ethereum price in 10**8 format
     */
    function ethUSD_dec8() public view returns (uint256) {
        (, int256 price,,,) = ethOracleAggregatorInterface.latestRoundData();
        return uint256(price);
    }

}