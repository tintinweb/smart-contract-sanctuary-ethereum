// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IDrawBuffer.sol";

/** @title  IDrawBeacon
 * @author Asymetrix Protocol Inc Team
 * @notice The DrawBeacon interface.
 */
interface IDrawBeacon {
    /// @notice Draw struct created every draw
    /// @param drawId The monotonically increasing drawId for each draw
    /// @param timestamp Unix timestamp of the draw. Recorded when the draw is
    ///                  created by the DrawBeacon.
    /// @param beaconPeriodStartedAt Unix timestamp of when the draw started
    /// @param beaconPeriodSeconds Unix timestamp of the beacon draw period for
    ///                            this draw.
    /// @param paid A flag that indicates if prizes for the draw are paid or not.
    struct Draw {
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
        bool paid;
    }

    /**
     * @notice Emit when a new DrawBuffer has been set.
     * @param newDrawBuffer The new DrawBuffer address
     */
    event DrawBufferUpdated(IDrawBuffer indexed newDrawBuffer);

    /**
     * @notice Emit when a draw has opened.
     * @param startedAt Start timestamp
     */
    event BeaconPeriodStarted(uint64 indexed startedAt);

    /**
     * @notice Emit when a draw has started.
     * @param drawId Draw id
     */
    event DrawStarted(uint32 indexed drawId);

    /**
     * @notice Emit when the drawPeriodSeconds is set.
     * @param drawPeriodSeconds Time between draw
     */
    event BeaconPeriodSecondsUpdated(uint32 drawPeriodSeconds);

    /**
     * @notice Returns the number of seconds remaining until the beacon period
     *         can be complete.
     * @return The number of seconds remaining until the beacon period can be
     *         complete.
     */
    function beaconPeriodRemainingSeconds() external view returns (uint64);

    /**
     * @notice Returns beacon period seconds.
     * @return The number of seconds of the beacon period.
     */
    function getBeaconPeriodSeconds() external view returns (uint32);

    /**
     * @notice Returns the time when the beacon period started at.
     * @return The time when the beacon period started at.
     */
    function getBeaconPeriodStartedAt() external view returns (uint64);

    /**
     * @notice Returns the timestamp at which the beacon period ends
     * @return The timestamp at which the beacon period ends.
     */
    function beaconPeriodEndAt() external view returns (uint64);

    /**
     * @notice Calculates the next beacon start time, assuming all beacon
     *         periods have  occurred between the last and now.
     * @return The next beacon period start time
     */
    function calculateNextBeaconPeriodStartTimeFromCurrentTime()
        external
        view
        returns (uint64);

    /**
     * @notice Calculates when the next beacon period will start.
     * @param time The timestamp to use as the current time
     * @return The timestamp at which the next beacon period would start
     */
    function calculateNextBeaconPeriodStartTime(
        uint64 time
    ) external view returns (uint64);

    /**
     * @notice Returns whether the beacon period is over
     * @return True if the beacon period is over, false otherwise
     */
    function isBeaconPeriodOver() external view returns (bool);

    /**
     * @notice Returns whether the draw can start
     * @return True if the beacon period is over, false otherwise
     */
    function canStartDraw() external view returns (bool);

    /**
     * @notice Allows the owner to set the beacon period in seconds.
     * @param beaconPeriodSeconds The new beacon period in seconds. Must be
     *        greater than zero.
     */
    function setBeaconPeriodSeconds(uint32 beaconPeriodSeconds) external;

    /**
     * @notice Starts the Draw process. The previous beacon period must have
     *         ended.
     */
    function startDraw() external;

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the
     *         new DrawBuffer.
     * @param newDrawBuffer DrawBuffer address
     * @return DrawBuffer
     */
    function setDrawBuffer(
        IDrawBuffer newDrawBuffer
    ) external returns (IDrawBuffer);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IDrawBeacon.sol";

/**
 * @title  IDrawBuffer
 * @author Asymetrix Protocol Inc Team
 * @notice The DrawBuffer interface.
 */
interface IDrawBuffer {
    /**
     * @notice Emit when a new draw has been created.
     * @param drawId Draw id
     * @param draw The Draw struct
     */
    event DrawSet(uint32 indexed drawId, IDrawBeacon.Draw draw);

    /**
     * @notice Emit when a new PrizeDistributor contract address is set.
     * @param prizeDistributor A new PrizeDistributor contract address
     */
    event PrizeDistributorSet(address prizeDistributor);

    /**
     * @notice Emit when draw is marked is paid.
     * @param drawId An ID of a draw that was marked as paid
     */
    event DrawMarkedAsPaid(uint32 drawId);

    /**
     * @notice Read a PrizeDistributor contract address.
     * @return A PrizeDistributor contract address.
     */
    function getPrizeDistributor() external view returns (address);

    /**
     * @notice Read a ring buffer cardinality.
     * @return Ring buffer cardinality.
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read a Draw from the draws ring buffer.
     * @dev    Read a Draw using the Draw.drawId to calculate position in the
     *         draws ring buffer.
     * @param drawId Draw.drawId
     * @return IDrawBeacon.Draw
     */
    function getDraw(
        uint32 drawId
    ) external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read multiple Draws from the draws ring buffer.
     * @dev    Read multiple Draws using each drawId to calculate position in
     *         the draws ring buffer.
     * @param drawIds Array of drawIds
     * @return IDrawBeacon.Draw[] array with the draw information of the
     *         requested draw ids
     */
    function getDraws(
        uint32[] calldata drawIds
    ) external view returns (IDrawBeacon.Draw[] memory);

    /**
     * @notice Gets the number of Draws held in the draw ring buffer.
     * @dev    If no Draws have been pushed, it will return 0.
     * @dev    If the ring buffer is full, it will return the cardinality.
     * @dev    Otherwise, it will return the NewestDraw index + 1.
     * @return Number of Draws held in the draw ring buffer.
     */
    function getDrawCount() external view returns (uint32);

    /**
     * @notice Read newest Draw from draws ring buffer.
     * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
     * @return IDrawBeacon.Draw
     */
    function getNewestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read oldest Draw from draws ring buffer.
     * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with
     *         the cardinality.
     * @return IDrawBeacon.Draw
     */
    function getOldestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Push new draw onto draws history via authorized manager or owner.
     * @param draw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function pushDraw(IDrawBeacon.Draw calldata draw) external returns (uint32);

    /**
     * @notice Set existing Draw in draws ring buffer with new parameters.
     * @dev    Updating a Draw should be used sparingly and only in the event an
     *         incorrect Draw parameter has been stored.
     * @param newDraw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function setDraw(
        IDrawBeacon.Draw calldata newDraw
    ) external returns (uint32);

    /**
     * @notice Set a new PrizeDistributor contract address.
     * @param prizeDistributor A new PrizeDistributor contract address
     */
    function setPrizeDistributor(address prizeDistributor) external;

    /**
     * @notice Mark a draw as paid.
     * @dev    It means that the winners of the draw were paid and the draw can
     *         not be paid again.
     * @param drawId An ID of a draw that should be marked as paid
     */
    function markDrawAsPaid(uint32 drawId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IPrizeDistributionSource.sol";

/** @title  IPrizeDistributionBuffer
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributionBuffer interface.
 */
interface IPrizeDistributionBuffer is IPrizeDistributionSource {
    /**
     * @notice Emit when PrizeDistribution is set.
     * @param drawId Draw id
     * @param prizeDistribution IPrizeDistributionBuffer.PrizeDistribution
     */
    event PrizeDistributionSet(
        uint32 indexed drawId,
        IPrizeDistributionBuffer.PrizeDistribution prizeDistribution
    );

    /**
     * @notice Read a ring buffer cardinality
     * @return Ring buffer cardinality
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read newest PrizeDistribution from prize distributions ring
     *         buffer.
     * @dev    Uses nextDrawIndex to calculate the most recently added
     *         PrizeDistribution.
     * @return prizeDistribution
     * @return drawId
     */
    function getNewestPrizeDistribution()
        external
        view
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        );

    /**
     * @notice Read oldest PrizeDistribution from prize distributions ring
     *         buffer.
     * @dev    Finds the oldest Draw by buffer.nextIndex and buffer.lastDrawId
     * @return prizeDistribution
     * @return drawId
     */
    function getOldestPrizeDistribution()
        external
        view
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        );

    /**
     * @notice Gets the PrizeDistributionBuffer for a drawId
     * @param drawId the draw id to retrieve the data from.
     * @return prizeDistribution
     */
    function getPrizeDistribution(
        uint32 drawId
    ) external view returns (IPrizeDistributionBuffer.PrizeDistribution memory);

    /**
     * @notice Gets the number of PrizeDistributions stored in the prize
     *         distributions ring buffer.
     * @dev    If no Draws have been pushed, it will return 0.
     * @dev    If the ring buffer is full, it will return the cardinality.
     * @dev    Otherwise, it will return the NewestPrizeDistribution index + 1.
     * @return Number of PrizeDistributions stored in the prize distributions
     *         ring buffer.
     */
    function getPrizeDistributionCount() external view returns (uint32);

    /**
     * @notice Adds new PrizeDistribution record to ring buffer storage.
     * @dev    Only callable by the owner or manager
     * @param drawId Draw ID linked to PrizeDistribution parameters
     * @param prizeDistribution PrizeDistribution parameters struct
     * @return true if operation is successful
     */
    function pushPrizeDistribution(
        uint32 drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata prizeDistribution
    ) external returns (bool);

    /**
     * @notice Sets existing PrizeDistribution with new PrizeDistribution
     *         parameters in ring buffer storage.
     * @dev    Retroactively updates an existing PrizeDistribution and should be
     *         thought of as a "safety" fallback. If the manager is setting
     *         invalid  PrizeDistribution parameters the Owner can update the
     *         invalid parameters with correct parameters.
     * @param drawId Draw ID to be set
     * @param draw PrizeDistribution information to set on the drawId
     * @return drawId
     */
    function setPrizeDistribution(
        uint32 drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata draw
    ) external returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/** @title IPrizeDistributionSource
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributionSource interface.
 */
interface IPrizeDistributionSource {
    ///@notice PrizeDistribution struct created every draw
    ///@param startTimestampOffset The starting time offset in seconds from
    ///abi                         which Ticket balances are calculated.
    ///@param endTimestampOffset The end time offset in seconds from which
    ///abi                       Ticket balances are calculated.
    ///@param numberOfPicks Number of picks this draw has
    struct PrizeDistribution {
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint104 numberOfPicks;
    }

    /**
     * @notice Gets PrizeDistribution list from array of drawIds
     * @param drawIds drawIds to get PrizeDistribution for
     * @return prizeDistributionList
     */
    function getPrizeDistributions(
        uint32[] calldata drawIds
    ) external view returns (PrizeDistribution[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./IPrizeDistributionBuffer.sol";
import "./IDrawBuffer.sol";

/**
 * @title  IPrizeDistributor
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributor interface.
 */
interface IPrizeDistributor {
    /**
     * @notice Emit when draw is paid.
     * @param drawId       Draw id that was paid out.
     * @param totalPayout  Total paid tokens.
     * @param winners      List of addresses winners of the draw.
     * @param payouts      List of payouts for winners of the draw.
     * @param timestamp    Datetime when the draw was paid.
     */
    event DrawPaid(
        uint32 indexed drawId,
        uint256 totalPayout,
        address[] winners,
        uint256[] payouts,
        uint64 indexed timestamp
    );

    /**
     * @notice Emit when a new DrawBuffer is set.
     * @param drawBuffer A new DrawBuffer that is set.
     */
    event DrawBufferSet(IDrawBuffer drawBuffer);

    /**
     * @notice Emit when a new PrizeDistributionBuffer is set.
     * @param prizeDistributionBuffer A new PrizeDistributionBuffer that is set.
     */
    event PrizeDistributionBufferSet(
        IPrizeDistributionBuffer prizeDistributionBuffer
    );

    /**
     * @notice Emit when a new prizes distribution is set.
     * @param distribution A new prizes distribution that is set.
     */
    event DistributionSet(uint16[] distribution);

    /**
     * @notice Emit when Token is set.
     * @param token  Token address.
     */
    event TokenSet(IERC20Upgradeable indexed token);

    /**
     * @notice Emit when ERC20 tokens are withdrawn.
     * @param token  ERC20 token transferred.
     * @param to     Address that received funds.
     * @param amount Amount of tokens transferred.
     */
    event ERC20Withdrawn(
        IERC20Upgradeable indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice Pay prizes to winners using current prizes distribution.
     * @dev    Only callable by contract owner.
     * @param _drawId   An Id of a draw to pay prizes for.
     * @param _winners  Winners of a draw.
     * @return true if operation is successful.
     */
    function payWinners(
        uint32 _drawId,
        address[] memory _winners
    ) external returns (bool);

    /**
     * @notice Transfer ERC20 tokens out of contract to recipient address.
     * @dev    Only callable by contract owner.
     * @param token  IERC20Upgradeable token to transfer.
     * @param to     Recipient of the tokens.
     * @param amount Amount of tokens to transfer.
     * @return true if operation is successful.
     */
    function withdrawERC20(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Set a DrawBuffer.
     * @param _drawBuffer  A new DrawBuffer to setup.
     */
    function setDrawBuffer(IDrawBuffer _drawBuffer) external;

    /**
     * @notice Set a PrizeDistributionBuffer.
     * @param _prizeDistributionBuffer  A new PrizeDistributionBuffer to setup.
     */
    function setPrizeDistributionBuffer(
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) external;

    /**
     * @notice Set prizes distribution.
     * @param _distribution  Prizes distribution to setup.
     */
    function setDistribution(uint16[] calldata _distribution) external;

    /**
     * @notice Read global Ticket address.
     * @return IERC20Upgradeable.
     */
    function getToken() external view returns (IERC20Upgradeable);

    /**
     * @notice Read global DrawBuffer address. The DrawBuffer contains
     *         information about the draw.
     * @return IDrawBuffer.
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Read global PrizeDistributionBuffer address.
     * @return IPrizeDistributionBuffer.
     */
    function getPrizeDistributionBuffer()
        external
        view
        returns (IPrizeDistributionBuffer);

    /**
     * @notice Read global prizes distribution. Returns an array with the split
     *         percentages in which the prizes will be distributed.
     * @return uint16[].
     */
    function getDistribution() external view returns (uint16[] memory);

    /**
     * @notice Read global prizes distribution length.
     * @return uint16.
     */
    function getNumberOfWinners() external view returns (uint16);

    /**
     * @notice Read global last unpaid draw ID. It increments when the draw is
     *         paid.
     * @return uint32
     */
    function getLastUnpaidDrawId() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IPrizeDistributionBuffer.sol";
import "./interfaces/IPrizeDistributor.sol";
import "./interfaces/IDrawBuffer.sol";

import "../owner-manager/Manageable.sol";

/**
 * @title  Asymetrix Protocol V1 PrizeDistributor
 * @author Asymetrix Protocol Inc Team
 * @notice The PrizeDistributor contract holds Tickets (captured interest) and
           distributes tickets to users with winning draw claims. An admin
           account can indicate the winners that will receive the payment of
           the prizes.
 */
contract PrizeDistributor is IPrizeDistributor, Manageable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ============ Global Variables ============ */

    /// @notice Token address
    IERC20Upgradeable private token;

    /// @notice DrawBuffer that stores all draws info
    IDrawBuffer private drawBuffer;

    /// @notice PrizeDistributionBuffer address
    IPrizeDistributionBuffer private prizeDistributionBuffer;

    /// @notice Distribution of prizes what is used in time of paying
    uint16[] private distribution;

    /// @notice Last unpaid draw ID
    uint32 private lastUnpaidDrawId;

    /// @notice 100% with 2 decimal points (i.s. 10000 == 100.00%)
    uint16 public constant ONE_HUNDRED_PERCENTS = 10000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Initialize PrizeDistributor smart contract.
     * @param _owner Owner address.
     * @param _token Token address.
     * @param _drawBuffer DrawBuffer address.
     * @param _prizeDistributionBuffer Initial distribution of prizes.
     * @param _distribution Initial array with distribution percentages.
     */
    function initialize(
        address _owner,
        IERC20Upgradeable _token,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        uint16[] calldata _distribution
    ) external initializer {
        __PrizeDistributor_init(_owner);
        __PrizeDistributor_init_unchained(
            _token,
            _drawBuffer,
            _prizeDistributionBuffer,
            _distribution
        );
    }

    function __PrizeDistributor_init(address _owner) internal onlyInitializing {
        __Manageable_init_unchained(_owner);
    }

    function __PrizeDistributor_init_unchained(
        IERC20Upgradeable _token,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer,
        uint16[] calldata _distribution
    ) internal onlyInitializing {
        _setToken(_token);
        _setDrawBuffer(_drawBuffer);
        _setPrizeDistributionBuffer(_prizeDistributionBuffer);
        _setDistribution(_distribution);

        lastUnpaidDrawId = 1;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributor
    function payWinners(
        uint32 _drawId,
        address[] memory _winners
    ) external override onlyManagerOrOwner returns (bool) {
        IDrawBeacon.Draw memory _draw = drawBuffer.getDraw(_drawId);

        require(
            _drawId == lastUnpaidDrawId,
            "PrizeDistributor/draw-id-should-be-the-same-as-last-unpaid-draw-id"
        );
        require(
            block.timestamp >
                _draw.beaconPeriodStartedAt + _draw.beaconPeriodSeconds,
            "PrizeDistributor/draw-is-not-finished-yet"
        );
        require(!_draw.paid, "PrizeDistributor/draw-is-already-paid");
        require(
            _winners.length == distribution.length,
            "PrizeDistributor/lengths-mismatch"
        );

        uint256 _totalPayout = token.balanceOf(address(this));

        require(_totalPayout > 0, "PrizeDistributor/prizes-amount-is-zero");

        uint256[] memory _payouts = new uint256[](_winners.length);
        uint16[] memory _distribution = distribution;

        for (uint16 i = 0; i < _winners.length; ++i) {
            require(
                _winners[i] != address(0),
                "PrizeDistributor/winner-is-zero-address"
            );

            uint256 _amount = (_totalPayout * _distribution[i]) /
                ONE_HUNDRED_PERCENTS;

            _awardPayout(_winners[i], _amount);

            _payouts[i] = _amount;
        }

        drawBuffer.markDrawAsPaid(_drawId);

        ++lastUnpaidDrawId;

        emit DrawPaid(
            _drawId,
            _totalPayout,
            _winners,
            _payouts,
            uint32(block.timestamp)
        );

        return true;
    }

    /// @inheritdoc IPrizeDistributor
    function withdrawERC20(
        IERC20Upgradeable _erc20Token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        require(
            _to != address(0),
            "PrizeDistributor/recipient-not-zero-address"
        );
        require(
            address(_erc20Token) != address(0),
            "PrizeDistributor/ERC20-not-zero-address"
        );

        _erc20Token.safeTransfer(_to, _amount);

        emit ERC20Withdrawn(_erc20Token, _to, _amount);

        return true;
    }

    /// @inheritdoc IPrizeDistributor
    function setDrawBuffer(
        IDrawBuffer _drawBuffer
    ) external override onlyOwner {
        _setDrawBuffer(_drawBuffer);
    }

    /// @inheritdoc IPrizeDistributor
    function setPrizeDistributionBuffer(
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) external override onlyOwner {
        _setPrizeDistributionBuffer(_prizeDistributionBuffer);
    }

    /// @inheritdoc IPrizeDistributor
    function setDistribution(
        uint16[] calldata _distribution
    ) external override onlyOwner {
        _setDistribution(_distribution);
    }

    /// @inheritdoc IPrizeDistributor
    function getToken() external view override returns (IERC20Upgradeable) {
        return token;
    }

    /// @inheritdoc IPrizeDistributor
    function getDrawBuffer() external view override returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IPrizeDistributor
    function getPrizeDistributionBuffer()
        external
        view
        override
        returns (IPrizeDistributionBuffer)
    {
        return prizeDistributionBuffer;
    }

    /// @inheritdoc IPrizeDistributor
    function getDistribution()
        external
        view
        override
        returns (uint16[] memory)
    {
        return distribution;
    }

    /// @inheritdoc IPrizeDistributor
    function getNumberOfWinners() external view override returns (uint16) {
        return uint16(distribution.length);
    }

    /// @inheritdoc IPrizeDistributor
    function getLastUnpaidDrawId() external view override returns (uint32) {
        return lastUnpaidDrawId;
    }

    /* ============ Private Functions ============ */

    /**
     * @notice Transfer claimed draw(s) total payout to user.
     * @param _to      User address
     * @param _amount  Transfer amount
     */
    function _awardPayout(address _to, uint256 _amount) private {
        if (_amount > 0) {
            token.safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Set token that is used for prizes payment.
     * @param _token  A token to setup.
     */
    function _setToken(IERC20Upgradeable _token) private {
        require(
            address(_token) != address(0),
            "PrizeDistributor/token-not-zero-address"
        );

        token = _token;

        emit TokenSet(_token);
    }

    /**
     * @notice Set a DrawBuffer.
     * @param _drawBuffer A DrawBuffer to setup.
     */
    function _setDrawBuffer(IDrawBuffer _drawBuffer) private {
        require(
            address(_drawBuffer) != address(0),
            "PrizeDistributor/draw-buffer-not-zero-address"
        );

        drawBuffer = _drawBuffer;

        emit DrawBufferSet(_drawBuffer);
    }

    /**
     * @notice Set a PrizeDistributionBuffer.
     * @param _prizeDistributionBuffer A PrizeDistributionBuffer to setup.
     */
    function _setPrizeDistributionBuffer(
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) private {
        require(
            address(_prizeDistributionBuffer) != address(0),
            "PrizeDistributor/prize-distribution-buffer-not-zero-address"
        );

        prizeDistributionBuffer = _prizeDistributionBuffer;

        emit PrizeDistributionBufferSet(_prizeDistributionBuffer);
    }

    /**
     * @notice Set prizes distribution.
     * @param _distribution  Prizes distribution to setup.
     */
    function _setDistribution(uint16[] calldata _distribution) private {
        uint16 _totalDistribution;

        for (uint16 i = 0; i < _distribution.length; ++i) {
            _totalDistribution += _distribution[i];
        }

        require(
            _totalDistribution == ONE_HUNDRED_PERCENTS,
            "PrizeDistributor/distribution-should-be-equal-to-100%"
        );

        delete distribution;

        distribution = _distribution;

        emit DistributionSet(_distribution);
    }

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * The `owner` is first set by passing the address of the `initialOwner` to the Ownable constructor.
 *
 * The owner account can be transferred through a two steps process:
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifiers
 * `onlyManager`, `onlyOwner` and `onlyManagerOrOwner`, which can be applied to your functions
 * to restrict their use to the manager and/or the owner.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    function __Manageable_init_unchained(
        address _initialOwner
    ) internal onlyInitializing {
        __Ownable_init_unchained(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(
            _newManager != _previousManager,
            "Manageable/existing-manager-address"
        );

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(
            manager() == msg.sender || owner() == msg.sender,
            "Manageable/caller-not-manager-or-owner"
        );
        _;
    }

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The `owner` is first set by passing the address of the `initialOwner` to the Ownable Initialize.
 *
 * The owner account can be transferred through a two steps process:
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {claimOwnership} to accept the ownership transfer
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to the owner.
 */
abstract contract Ownable is Initializable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    function __Ownable_init_unchained(
        address _initialOwner
    ) internal onlyInitializing {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @notice Allows current owner to set the `_pendingOwner` address.
     * @param _newOwner Address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable/pendingOwner-not-zero-address"
        );

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
     * @notice Allows the `_pendingOwner` address to finalize the transfer.
     * @dev This function is only callable by the `_pendingOwner`.
     */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the `pendingOwner`.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }

    uint256[45] private __gap;
}