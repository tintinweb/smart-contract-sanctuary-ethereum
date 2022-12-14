// SPDX-License-Identifier: MIT
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

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
abstract contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __ownable_initialize() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

pragma solidity ^0.8.0;

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

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
abstract contract ReentrancyGuard is Initializable {
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

    function __reentrancy_initialize() internal initializer {
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

pragma solidity >=0.5.0;

interface IBullionFXPair {
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

    function liquidityFee() external view returns (uint256);

    function treasuryFee() external view returns (uint256);

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

pragma solidity >=0.6.2;

interface IBullionFXRouter01 {
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
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
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

interface IBullionFXRouter02 is IBullionFXRouter01 {
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity ^0.8.4;

/*
 * @author Uniswap
 * @notice Library from Uniswap
 */
library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;

        return (r < r1 ? r : r1);
    }
}

/*
 * @author Inspiration from the work of Zapper and Beefy.
 * Implemented and modified by BullionFX teams.
 */
contract BullionFXZapV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Interface for Wrapped ETH (WETH)
    IWETH public WETH;

    // BullionFXRouter interface
    IBullionFXRouter02 public bullionfxRouter;

    // Maximum integer (used for managing allowance)
    uint256 public constant MAX_INT = 2**256 - 1;

    // Minimum amount for a swap (derived from BullionFX)
    uint256 public constant MINIMUM_AMOUNT = 1000;

    // Maximum reverse zap ratio (100 --> 1%, 1000 --> 0.1%)
    uint256 public maxZapReverseRatio;

    // Address BullionFXRouter
    address private bullionfxRouterAddress;

    // Address Wrapped ETH (WETH)
    address private WETHAddress;

    // Owner recovers token
    event AdminTokenRecovery(
        address indexed tokenAddress,
        uint256 amountTokens
    );

    // Owner changes the maxZapReverseRatio
    event NewMaxZapReverseRatio(uint256 maxZapReverseRatio);

    // tokenToZap = 0x00 address if ETH
    event ZapIn(
        address indexed tokenToZap,
        address indexed lpToken,
        uint256 tokenAmountIn,
        uint256 lpTokenAmountReceived,
        address indexed user
    );

    // token0ToZap = 0x00 address if ETH
    event ZapInRebalancing(
        address indexed token0ToZap,
        address indexed token1ToZap,
        address lpToken,
        uint256 token0AmountIn,
        uint256 token1AmountIn,
        uint256 lpTokenAmountReceived,
        address indexed user
    );

    // tokenToReceive = 0x00 address if ETH
    event ZapOut(
        address indexed lpToken,
        address indexed tokenToReceive,
        uint256 lpTokenAmount,
        uint256 tokenAmountReceived,
        address indexed user
    );

    /*
     * @notice Fallback for WETH
     */
    receive() external payable {
        assert(msg.sender == WETHAddress);
    }

    /*
     * @notice Constructor
     * @param _WETHAddress: address of the WETH contract
     * @param _bullionfxRouter: address of the BullionFXRouter
     * @param _maxZapReverseRatio: maximum zap ratio
     */
    function initialize(
        address _WETHAddress,
        address _bullionfxRouter,
        uint256 _maxZapReverseRatio
    ) external initializer {
        __ownable_initialize();
        __reentrancy_initialize();
        WETHAddress = _WETHAddress;
        WETH = IWETH(_WETHAddress);
        bullionfxRouterAddress = _bullionfxRouter;
        bullionfxRouter = IBullionFXRouter02(_bullionfxRouter);
        maxZapReverseRatio = _maxZapReverseRatio;
    }

    /*
     * @notice Zap ETH in a WETH pool (e.g. WETH/token)
     * @param _lpToken: LP token address (e.g. BULL/ETH)
     * @param _tokenAmountOutMin: minimum token amount (e.g. BULL) to receive in the intermediary swap (e.g. ETH --> BULL)
     */
    function zapInETH(address _lpToken, uint256 _tokenAmountOutMin)
        external
        payable
        nonReentrant
    {
        WETH.deposit{value: msg.value}();

        // Call zap function
        uint256 lpTokenAmountTransferred = _zapIn(
            WETHAddress,
            msg.value,
            _lpToken,
            _tokenAmountOutMin
        );

        // Emit event
        emit ZapIn(
            address(0x0000000000000000000000000000000000000000),
            _lpToken,
            msg.value,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap a token in (e.g. token/other token)
     * @param _tokenToZap: token to zap
     * @param _tokenAmountIn: amount of token to swap
     * @param _lpToken: LP token address (e.g. BULL/USDC)
     * @param _tokenAmountOutMin: minimum token to receive (e.g. BULL) in the intermediary swap (e.g. USDC --> BULL)
     */
    function zapInToken(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) external nonReentrant {
        // Transfer tokens to this contract
        IERC20(_tokenToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenAmountIn
        );

        // Call zap function
        uint256 lpTokenAmountTransferred = _zapIn(
            _tokenToZap,
            _tokenAmountIn,
            _lpToken,
            _tokenAmountOutMin
        );

        // Emit event
        emit ZapIn(
            _tokenToZap,
            _lpToken,
            _tokenAmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap two tokens in, rebalance them to 50-50, before adding them to LP
     * @param _token0ToZap: address of token0 to zap
     * @param _token1ToZap: address of token1 to zap
     * @param _token0AmountIn: amount of token0 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address (token0/token1)
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function zapInTokenRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external nonReentrant {
        // Transfer tokens to this contract
        IERC20(_token0ToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _token0AmountIn
        );
        IERC20(_token1ToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _token1AmountIn
        );

        // Call zapIn function
        uint256 lpTokenAmountTransferred = _zapInRebalancing(
            _token0ToZap,
            _token1ToZap,
            _token0AmountIn,
            _token1AmountIn,
            _lpToken,
            _tokenAmountInMax,
            _tokenAmountOutMin,
            _isToken0Sold
        );

        // Emit event
        emit ZapInRebalancing(
            _token0ToZap,
            _token1ToZap,
            _lpToken,
            _token0AmountIn,
            _token1AmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap 1 token and ETH, rebalance them to 50-50, before adding them to LP
     * @param _token1ToZap: address of token1 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function zapInETHRebalancing(
        address _token1ToZap,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external payable nonReentrant {
        WETH.deposit{value: msg.value}();

        IERC20(_token1ToZap).safeTransferFrom(
            msg.sender,
            address(this),
            _token1AmountIn
        );

        // Call zapIn function
        uint256 lpTokenAmountTransferred = _zapInRebalancing(
            WETHAddress,
            _token1ToZap,
            msg.value,
            _token1AmountIn,
            _lpToken,
            _tokenAmountInMax,
            _tokenAmountOutMin,
            _isToken0Sold
        );

        // Emit event
        emit ZapInRebalancing(
            address(0x0000000000000000000000000000000000000000),
            _token1ToZap,
            _lpToken,
            msg.value,
            _token1AmountIn,
            lpTokenAmountTransferred,
            msg.sender
        );
    }

    /*
     * @notice Zap a LP token out to receive ETH
     * @param _lpToken: LP token address (e.g. BULL/WETH)
     * @param _lpTokenAmount: amount of LP tokens to zap out
     * @param _tokenAmountOutMin: minimum amount to receive (in ETH/WETH) in the intermediary swap (e.g. BULL --> ETH)
     */
    function zapOutETH(
        address _lpToken,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external nonReentrant {
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(
            msg.sender,
            address(_lpToken),
            _lpTokenAmount
        );

        // Call zapOut
        uint256 tokenAmountToTransfer = _zapOut(
            _lpToken,
            WETHAddress,
            _tokenAmountOutMin,
            _totalTokenAmountOutMin
        );

        // Unwrap ETH
        WETH.withdraw(tokenAmountToTransfer);

        // Transfer ETH to the msg.sender
        (bool success, ) = msg.sender.call{value: tokenAmountToTransfer}(
            new bytes(0)
        );
        require(success, "ETH: transfer fail");

        // Emit event
        emit ZapOut(
            _lpToken,
            address(0x0000000000000000000000000000000000000000),
            _lpTokenAmount,
            tokenAmountToTransfer,
            msg.sender
        );
    }

    /*
     * @notice Zap a LP token out (to receive a token)
     * @param _lpToken: LP token address (e.g. BULL/USDC)
     * @param _tokenToReceive: one of the 2 tokens from the LP (e.g. BULL or USDC)
     * @param _lpTokenAmount: amount of LP tokens to zap out
     * @param _tokenAmountOutMin: minimum token to receive (e.g. BULL) in the intermediary swap (e.g. USDC --> BULL)
     */
    function zapOutToken(
        address _lpToken,
        address _tokenToReceive,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external nonReentrant {
        // Transfer LP token to this address
        IERC20(_lpToken).safeTransferFrom(
            msg.sender,
            address(_lpToken),
            _lpTokenAmount
        );

        uint256 tokenAmountToTransfer = _zapOut(
            _lpToken,
            _tokenToReceive,
            _tokenAmountOutMin,
            _totalTokenAmountOutMin
        );

        IERC20(_tokenToReceive).safeTransfer(msg.sender, tokenAmountToTransfer);

        emit ZapOut(
            _lpToken,
            _tokenToReceive,
            _lpTokenAmount,
            tokenAmountToTransfer,
            msg.sender
        );
    }

    /**
     * @notice It allows the owner to change the risk parameter for quantities
     * @param _maxZapInverseRatio: new inverse ratio
     * @dev This function is only callable by owner.
     */
    function updateMaxZapInverseRatio(uint256 _maxZapInverseRatio)
        external
        onlyOwner
    {
        maxZapReverseRatio = _maxZapInverseRatio;
        emit NewMaxZapReverseRatio(_maxZapInverseRatio);
    }

    /**
     * @notice It allows the owner to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function getFee(address _lpToken) public view returns (uint256) {
        return
            IBullionFXPair(_lpToken).liquidityFee() +
            IBullionFXPair(_lpToken).treasuryFee();
    }

    /*
     * @notice View the details for single zap
     * @dev Use WETH for _tokenToZap (if ETH is the input)
     * @param _tokenToZap: address of the token to zap
     * @param _tokenAmountIn: amount of token to zap inputed
     * @param _lpToken: address of the LP token
     * @return swapAmountIn: amount that is expected to get swapped in intermediary swap
     * @return swapAmountOut: amount that is expected to get received in intermediary swap
     * @return swapTokenOut: token address of the token that is used in the intermediary swap
     */
    function estimateZapInSwap(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        address token0 = IBullionFXPair(_lpToken).token0();
        address token1 = IBullionFXPair(_lpToken).token1();

        require(
            _tokenToZap == token0 || _tokenToZap == token1,
            "Zap: Wrong tokens"
        );

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IBullionFXPair(_lpToken)
            .getReserves();

        if (token0 == _tokenToZap) {
            swapTokenOut = token1;
            swapAmountIn = _calculateAmountToSwap(
                _tokenAmountIn,
                reserveA,
                reserveB,
                getFee(_lpToken)
            );
            swapAmountOut = bullionfxRouter.getAmountOut(
                swapAmountIn,
                reserveA,
                reserveB,
                getFee(_lpToken)
            );
        } else {
            swapTokenOut = token0;
            swapAmountIn = _calculateAmountToSwap(
                _tokenAmountIn,
                reserveB,
                reserveA,
                getFee(_lpToken)
            );
            swapAmountOut = bullionfxRouter.getAmountOut(
                swapAmountIn,
                reserveB,
                reserveA,
                getFee(_lpToken)
            );
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    /*
     * @notice View the details for a rebalancing zap
     * @dev Use WETH for _token0ToZap (if ETH is the input)
     * @param _token0ToZap: address of the token0 to zap
     * @param _token1ToZap: address of the token0 to zap
     * @param _token0AmountIn: amount for token0 to zap
     * @param _token1AmountIn: amount for token1 to zap
     * @param _lpToken: address of the LP token
     * @return swapAmountIn: amount that is expected to get swapped in intermediary swap
     * @return swapAmountOut: amount that is expected to get received in intermediary swap
     * @return isToken0Sold: whether the token0 is sold (false --> token1 is sold in the intermediary swap)
     */
    function estimateZapInRebalancingSwap(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            bool sellToken0
        )
    {
        require(
            _token0ToZap == IBullionFXPair(_lpToken).token0() ||
                _token0ToZap == IBullionFXPair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == IBullionFXPair(_lpToken).token0() ||
                _token1ToZap == IBullionFXPair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IBullionFXPair(_lpToken)
            .getReserves();

        if (_token0ToZap == IBullionFXPair(_lpToken).token0()) {
            sellToken0 = (_token0AmountIn * reserveB >
                _token1AmountIn * reserveA)
                ? true
                : false;

            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveA,
                reserveB,
                getFee(_lpToken),
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = bullionfxRouter.getAmountOut(
                    swapAmountIn,
                    reserveA,
                    reserveB,
                    getFee(_lpToken)
                );
            } else {
                swapAmountOut = bullionfxRouter.getAmountOut(
                    swapAmountIn,
                    reserveB,
                    reserveA,
                    getFee(_lpToken)
                );
            }
        } else {
            sellToken0 = (_token0AmountIn * reserveA >
                _token1AmountIn * reserveB)
                ? true
                : false;
            // Calculate the amount that is expected to be swapped
            swapAmountIn = _calculateAmountToSwapForRebalancing(
                _token0AmountIn,
                _token1AmountIn,
                reserveB,
                reserveA,
                getFee(_lpToken),
                sellToken0
            );

            // Calculate the amount expected to be received in the intermediary swap
            if (sellToken0) {
                swapAmountOut = bullionfxRouter.getAmountOut(
                    swapAmountIn,
                    reserveB,
                    reserveA,
                    getFee(_lpToken)
                );
            } else {
                swapAmountOut = bullionfxRouter.getAmountOut(
                    swapAmountIn,
                    reserveA,
                    reserveB,
                    getFee(_lpToken)
                );
            }
        }

        return (swapAmountIn, swapAmountOut, sellToken0);
    }

    /*
     * @notice View the details for single zap
     * @dev Use WETH for _tokenToReceive (if ETH is the asset to be received)
     * @param _lpToken: address of the LP token to zap out
     * @param _lpTokenAmount: amount of LP token to zap out
     * @param _tokenToReceive: token address to receive
     * @return swapAmountIn: amount that is expected to get swapped for intermediary swap
     * @return swapAmountOut: amount that is expected to get received for intermediary swap
     * @return swapTokenOut: address of the token that is sold in the intermediary swap
     */
    function estimateZapOutSwap(
        address _lpToken,
        uint256 _lpTokenAmount,
        address _tokenToReceive
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        )
    {
        address token0 = IBullionFXPair(_lpToken).token0();
        address token1 = IBullionFXPair(_lpToken).token1();

        require(
            _tokenToReceive == token0 || _tokenToReceive == token1,
            "Zap: Token not in LP"
        );

        // Convert to uint256 (from uint112)
        (uint256 reserveA, uint256 reserveB, ) = IBullionFXPair(_lpToken)
            .getReserves();
        uint256 fee = getFee(_lpToken);

        if (token1 == _tokenToReceive) {
            // sell token0
            uint256 tokenAmountIn = (_lpTokenAmount * reserveA) /
                IBullionFXPair(_lpToken).totalSupply();

            swapAmountIn = tokenAmountIn;
            swapAmountOut = bullionfxRouter.getAmountOut(
                swapAmountIn,
                reserveA,
                reserveB,
                fee
            );

            swapTokenOut = token0;
        } else {
            // sell token1
            uint256 tokenAmountIn = (_lpTokenAmount * reserveB) /
                IBullionFXPair(_lpToken).totalSupply();

            swapAmountIn = tokenAmountIn;
            swapAmountOut = bullionfxRouter.getAmountOut(
                swapAmountIn,
                reserveB,
                reserveA,
                fee
            );

            swapTokenOut = token1;
        }

        return (swapAmountIn, swapAmountOut, swapTokenOut);
    }

    /*
     * @notice Zap a token in (e.g. token/other token)
     * @param _tokenToZap: token to zap
     * @param _tokenAmountIn: amount of token to swap
     * @param _lpToken: LP token address
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     */
    function _zapIn(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) internal returns (uint256 lpTokenReceived) {
        require(_tokenAmountIn >= MINIMUM_AMOUNT, "Zap: Amount too low");

        address token0 = IBullionFXPair(_lpToken).token0();
        address token1 = IBullionFXPair(_lpToken).token1();

        require(
            _tokenToZap == token0 || _tokenToZap == token1,
            "Zap: Wrong tokens"
        );

        // Retrieve the path
        address[] memory path = new address[](2);
        path[0] = _tokenToZap;

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = IBullionFXPair(_lpToken)
                .getReserves();

            require(
                (reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT),
                "Zap: Reserves too low"
            );

            if (token0 == _tokenToZap) {
                swapAmountIn = _calculateAmountToSwap(
                    _tokenAmountIn,
                    reserveA,
                    reserveB,
                    getFee(_lpToken)
                );
                path[1] = token1;
                require(
                    reserveA / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            } else {
                swapAmountIn = _calculateAmountToSwap(
                    _tokenAmountIn,
                    reserveB,
                    reserveA,
                    getFee(_lpToken)
                );
                path[1] = token0;
                require(
                    reserveB / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            }
        }

        // Approve token to zap if necessary
        _approveTokenIfNeeded(_tokenToZap, swapAmountIn);

        uint256[] memory swapedAmounts = bullionfxRouter
            .swapExactTokensForTokens(
                swapAmountIn,
                _tokenAmountOutMin,
                path,
                address(this),
                block.timestamp
            );

        // Approve other token if necessary
        if (token0 == _tokenToZap) {
            _approveTokenIfNeeded(token1, swapAmountIn);
        } else {
            _approveTokenIfNeeded(token0, swapAmountIn);
        }

        // Add liquidity and retrieve the amount of LP received by the sender
        (, , lpTokenReceived) = bullionfxRouter.addLiquidity(
            path[0],
            path[1],
            _tokenAmountIn - swapedAmounts[0],
            swapedAmounts[1],
            1,
            1,
            msg.sender,
            block.timestamp
        );

        return lpTokenReceived;
    }

    /*
     * @notice Zap two tokens in, rebalance them to 50-50, before adding them to LP
     * @param _token0ToZap: address of token0 to zap
     * @param _token1ToZap: address of token1 to zap
     * @param _token0AmountIn: amount of token0 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function _zapInRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) internal returns (uint256 lpTokenReceived) {
        require(
            _token0ToZap == IBullionFXPair(_lpToken).token0() ||
                _token0ToZap == IBullionFXPair(_lpToken).token1(),
            "Zap: Wrong token0"
        );
        require(
            _token1ToZap == IBullionFXPair(_lpToken).token0() ||
                _token1ToZap == IBullionFXPair(_lpToken).token1(),
            "Zap: Wrong token1"
        );

        require(_token0ToZap != _token1ToZap, "Zap: Same tokens");

        // Initiates an estimation to swap
        uint256 swapAmountIn;

        {
            // Convert to uint256 (from uint112)
            (uint256 reserveA, uint256 reserveB, ) = IBullionFXPair(_lpToken)
                .getReserves();

            require(
                (reserveA >= MINIMUM_AMOUNT) && (reserveB >= MINIMUM_AMOUNT),
                "Zap: Reserves too low"
            );

            if (_token0ToZap == IBullionFXPair(_lpToken).token0()) {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveA,
                    reserveB,
                    getFee(_lpToken),
                    _isToken0Sold
                );
                require(
                    reserveA / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            } else {
                swapAmountIn = _calculateAmountToSwapForRebalancing(
                    _token0AmountIn,
                    _token1AmountIn,
                    reserveB,
                    reserveA,
                    getFee(_lpToken),
                    _isToken0Sold
                );

                require(
                    reserveB / swapAmountIn >= maxZapReverseRatio,
                    "Zap: Quantity higher than limit"
                );
            }
        }

        require(
            swapAmountIn <= _tokenAmountInMax,
            "Zap: Amount to swap too high"
        );

        address[] memory path = new address[](2);

        // Define path for swapping and check whether to approve token to sell in intermediary swap
        if (_isToken0Sold) {
            path[0] = _token0ToZap;
            path[1] = _token1ToZap;
            _approveTokenIfNeeded(_token0ToZap, swapAmountIn);
        } else {
            path[0] = _token1ToZap;
            path[1] = _token0ToZap;
            _approveTokenIfNeeded(_token1ToZap, swapAmountIn);
        }

        // Execute the swap and retrieve quantity received
        uint256[] memory swapedAmounts = bullionfxRouter
            .swapExactTokensForTokens(
                swapAmountIn,
                _tokenAmountOutMin,
                path,
                address(this),
                block.timestamp
            );

        // Check whether to approve other token and add liquidity to LP
        if (_isToken0Sold) {
            _approveTokenIfNeeded(_token1ToZap, swapAmountIn);

            (, , lpTokenReceived) = bullionfxRouter.addLiquidity(
                path[0],
                path[1],
                (_token0AmountIn - swapedAmounts[0]),
                (_token1AmountIn + swapedAmounts[1]),
                1,
                1,
                msg.sender,
                block.timestamp
            );
        } else {
            _approveTokenIfNeeded(_token0ToZap, swapAmountIn);
            (, , lpTokenReceived) = bullionfxRouter.addLiquidity(
                path[0],
                path[1],
                (_token1AmountIn - swapedAmounts[0]),
                (_token0AmountIn + swapedAmounts[1]),
                1,
                1,
                msg.sender,
                block.timestamp
            );
        }

        return lpTokenReceived;
    }

    /*
     * @notice Zap a LP token out to a token (e.g. token/other token)
     * @param _lpToken: LP token address
     * @param _tokenToReceive: token address
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     */
    function _zapOut(
        address _lpToken,
        address _tokenToReceive,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) internal returns (uint256) {
        address token0 = IBullionFXPair(_lpToken).token0();
        address token1 = IBullionFXPair(_lpToken).token1();

        require(
            _tokenToReceive == token0 || _tokenToReceive == token1,
            "Zap: Token not in LP"
        );

        // Burn all LP tokens to receive the two tokens to this address
        (uint256 amount0, uint256 amount1) = IBullionFXPair(_lpToken).burn(
            address(this)
        );

        require(
            amount0 >= MINIMUM_AMOUNT,
            "BullionFXRouter: INSUFFICIENT_A_AMOUNT"
        );
        require(
            amount1 >= MINIMUM_AMOUNT,
            "BullionFXRouter: INSUFFICIENT_B_AMOUNT"
        );

        address[] memory path = new address[](2);
        path[1] = _tokenToReceive;

        uint256 swapAmountIn;

        if (token0 == _tokenToReceive) {
            path[0] = token1;
            swapAmountIn = IERC20(token1).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token1, swapAmountIn);
        } else {
            path[0] = token0;
            swapAmountIn = IERC20(token0).balanceOf(address(this));

            // Approve token to sell if necessary
            _approveTokenIfNeeded(token0, swapAmountIn);
        }

        // Swap tokens
        bullionfxRouter.swapExactTokensForTokens(
            swapAmountIn,
            _tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Return full balance for the token to receive by the sender
        require(
            _totalTokenAmountOutMin <
                IERC20(_tokenToReceive).balanceOf(address(this)),
            "amount is not enough"
        );
        return IERC20(_tokenToReceive).balanceOf(address(this));
    }

    /*
     * @notice Allows to zap a token in (e.g. token/other token)
     * @param _token: token address
     */
    function _approveTokenIfNeeded(address _token, uint256 _swapAmountIn)
        private
    {
        if (
            IERC20(_token).allowance(address(this), bullionfxRouterAddress) <
            _swapAmountIn
        ) {
            // Reset to 0
            IERC20(_token).safeApprove(bullionfxRouterAddress, 0);
            // Re-approve
            IERC20(_token).safeApprove(bullionfxRouterAddress, MAX_INT);
        }
    }

    /*
     * @notice Calculate the swap amount to get the price at 50/50 split
     * @param _token0AmountIn: amount of token 0
     * @param _reserve0: amount in reserve for token0
     * @param _reserve1: amount in reserve for token1
     * @return amountToSwap: swapped amount (in token0)
     */
    function _calculateAmountToSwap(
        uint256 _token0AmountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _fee
    ) private view returns (uint256 amountToSwap) {
        uint256 halfToken0Amount = _token0AmountIn / 2;
        uint256 nominator = bullionfxRouter.getAmountOut(
            halfToken0Amount,
            _reserve0,
            _reserve1,
            _fee
        );
        uint256 denominator = bullionfxRouter.quote(
            halfToken0Amount,
            _reserve0 + halfToken0Amount,
            _reserve1 - nominator
        );

        // Adjustment for price impact
        amountToSwap =
            _token0AmountIn -
            Babylonian.sqrt(
                (halfToken0Amount * halfToken0Amount * nominator) / denominator
            );

        return amountToSwap;
    }

    /*
     * @notice Calculate the amount to swap to get the tokens at a 50/50 split
     * @param _token0AmountIn: amount of token 0
     * @param _token1AmountIn: amount of token 1
     * @param _reserve0: amount in reserve for token0
     * @param _reserve1: amount in reserve for token1
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     * @return amountToSwap: swapped amount in token0 (if _isToken0Sold is true) or token1 (if _isToken0Sold is false)
     */
    function _calculateAmountToSwapForRebalancing(
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _fee,
        bool _isToken0Sold
    ) private view returns (uint256 amountToSwap) {
        bool sellToken0 = (_token0AmountIn * _reserve1 >
            _token1AmountIn * _reserve0)
            ? true
            : false;

        require(sellToken0 == _isToken0Sold, "Zap: Wrong trade direction");

        if (sellToken0) {
            uint256 token0AmountToSell = (_token0AmountIn -
                (_token1AmountIn * _reserve0) /
                _reserve1) / 2;
            uint256 nominator = bullionfxRouter.getAmountOut(
                token0AmountToSell,
                _reserve0,
                _reserve1,
                _fee
            );
            uint256 denominator = bullionfxRouter.quote(
                token0AmountToSell,
                _reserve0 + token0AmountToSell,
                _reserve1 - nominator
            );

            // Calculate the amount to sell (in token0)
            token0AmountToSell =
                (_token0AmountIn -
                    (_token1AmountIn * (_reserve0 + token0AmountToSell)) /
                    (_reserve1 - nominator)) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token0AmountToSell -
                Babylonian.sqrt(
                    (token0AmountToSell * token0AmountToSell * nominator) /
                        denominator
                );
        } else {
            uint256 token1AmountToSell = (_token1AmountIn -
                (_token0AmountIn * _reserve1) /
                _reserve0) / 2;
            uint256 nominator = bullionfxRouter.getAmountOut(
                token1AmountToSell,
                _reserve1,
                _reserve0,
                _fee
            );

            uint256 denominator = bullionfxRouter.quote(
                token1AmountToSell,
                _reserve1 + token1AmountToSell,
                _reserve0 - nominator
            );

            // Calculate the amount to sell (in token1)
            token1AmountToSell =
                (_token1AmountIn -
                    ((_token0AmountIn * (_reserve1 + token1AmountToSell)) /
                        (_reserve0 - nominator))) /
                2;

            // Adjustment for price impact
            amountToSwap =
                2 *
                token1AmountToSell -
                Babylonian.sqrt(
                    (token1AmountToSell * token1AmountToSell * nominator) /
                        denominator
                );
        }

        return amountToSwap;
    }
}