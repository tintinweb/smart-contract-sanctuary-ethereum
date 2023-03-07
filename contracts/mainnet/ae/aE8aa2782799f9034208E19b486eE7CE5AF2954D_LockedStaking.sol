/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

/// @notice Optimized sorts and operations for sorted arrays.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Sort.sol)
library LibSort {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INSERTION SORT                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on small arrays (32 or lesser elements).
    // - Faster on almost sorted arrays.
    // - Smaller bytecode.
    // - May be suitable for view functions intended for off-chain querying.

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.
            let h := add(a, shl(5, n)) // High slot.
            let s := 0x20
            let w := not(31)
            for { let i := add(a, s) } 1 {} {
                i := add(i, s)
                if gt(i, h) { break }
                let k := mload(i) // Key.
                let j := add(i, w) // The slot before the current slot.
                let v := mload(j) // The value of `j`.
                if iszero(gt(v, k)) { continue }
                for {} 1 {} {
                    mstore(add(j, s), v)
                    j := add(j, w) // `sub(j, 0x20)`.
                    v := mload(j)
                    if iszero(gt(v, k)) { break }
                }
                mstore(add(j, s), k)
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(int256[] memory a) internal pure {
        _convertTwosComplement(a);
        insertionSort(_toUints(a));
        _convertTwosComplement(a);
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(address[] memory a) internal pure {
        insertionSort(_toUints(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTRO-QUICKSORT                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on larger arrays (more than 32 elements).
    // - Robust performance.
    // - Larger bytecode.

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(31)
            let s := 0x20
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.

            // Let the stack be the start of the free memory.
            let stack := mload(0x40)

            for {} iszero(lt(n, 2)) {} {
                // Push `l` and `h` to the stack.
                // The `shl` by 5 is equivalent to multiplying by `0x20`.
                let l := add(a, s)
                let h := add(a, shl(5, n))

                let j := l
                // forgefmt: disable-next-item
                for {} iszero(or(eq(j, h), gt(mload(j), mload(add(j, s))))) {} {
                    j := add(j, s)
                }
                // If the array is already sorted.
                if eq(j, h) { break }

                j := h
                // forgefmt: disable-next-item
                for {} iszero(gt(mload(j), mload(add(j, w)))) {} {
                    j := add(j, w) // `sub(j, 0x20)`.
                }
                // If the array is reversed sorted.
                if eq(j, l) {
                    for {} 1 {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := add(h, w) // `sub(h, 0x20)`.
                        l := add(l, s)
                        if iszero(lt(l, h)) { break }
                    }
                    break
                }

                // Push `l` and `h` onto the stack.
                mstore(stack, l)
                mstore(add(stack, s), h)
                stack := add(stack, 0x40)
                break
            }

            for { let stackBottom := mload(0x40) } iszero(eq(stack, stackBottom)) {} {
                // Pop `l` and `h` from the stack.
                stack := sub(stack, 0x40)
                let l := mload(stack)
                let h := mload(add(stack, s))

                // Do insertion sort if `h - l <= 0x20 * 12`.
                // Threshold is fine-tuned via trial and error.
                if iszero(gt(sub(h, l), 0x180)) {
                    // Hardcode sort the first 2 elements.
                    let i := add(l, s)
                    if iszero(lt(mload(l), mload(i))) {
                        let t := mload(i)
                        mstore(i, mload(l))
                        mstore(l, t)
                    }
                    for {} 1 {} {
                        i := add(i, s)
                        if gt(i, h) { break }
                        let k := mload(i) // Key.
                        let j := add(i, w) // The slot before the current slot.
                        let v := mload(j) // The value of `j`.
                        if iszero(gt(v, k)) { continue }
                        for {} 1 {} {
                            mstore(add(j, s), v)
                            j := add(j, w)
                            v := mload(j)
                            if iszero(gt(v, k)) { break }
                        }
                        mstore(add(j, s), k)
                    }
                    continue
                }
                // Pivot slot is the average of `l` and `h`.
                let p := add(shl(5, shr(6, add(l, h))), and(31, l))
                // Median of 3 with sorting.
                {
                    let e0 := mload(l)
                    let e2 := mload(h)
                    let e1 := mload(p)
                    if iszero(lt(e0, e1)) {
                        let t := e0
                        e0 := e1
                        e1 := t
                    }
                    if iszero(lt(e0, e2)) {
                        let t := e0
                        e0 := e2
                        e2 := t
                    }
                    if iszero(lt(e1, e2)) {
                        let t := e1
                        e1 := e2
                        e2 := t
                    }
                    mstore(p, e1)
                    mstore(h, e2)
                    mstore(l, e0)
                }
                // Hoare's partition.
                {
                    // The value of the pivot slot.
                    let x := mload(p)
                    p := h
                    for { let i := l } 1 {} {
                        for {} 1 {} {
                            i := add(i, s)
                            if iszero(gt(x, mload(i))) { break }
                        }
                        let j := p
                        for {} 1 {} {
                            j := add(j, w)
                            if iszero(lt(x, mload(j))) { break }
                        }
                        p := j
                        if iszero(lt(i, p)) { break }
                        // Swap slots `i` and `p`.
                        let t := mload(i)
                        mstore(i, mload(p))
                        mstore(p, t)
                    }
                }
                // If slice on right of pivot is non-empty, push onto stack.
                {
                    mstore(stack, add(p, s))
                    // Skip `mstore(add(stack, 0x20), h)`, as it is already on the stack.
                    stack := add(stack, shl(6, lt(add(p, s), h)))
                }
                // If slice on left of pivot is non-empty, push onto stack.
                {
                    mstore(stack, l)
                    mstore(add(stack, s), p)
                    stack := add(stack, shl(6, gt(p, l)))
                }
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(int256[] memory a) internal pure {
        _convertTwosComplement(a);
        sort(_toUints(a));
        _convertTwosComplement(a);
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(address[] memory a) internal pure {
        sort(_toUints(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  OTHER USEFUL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // For performance, the `uniquifySorted` methods will not revert if the
    // array is not sorted -- it will simply remove consecutive duplicate elements.

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the length of `a` is greater than 1.
            if iszero(lt(mload(a), 2)) {
                let x := add(a, 0x20)
                let y := add(a, 0x40)
                let end := add(a, shl(5, add(mload(a), 1)))
                for {} 1 {} {
                    if iszero(eq(mload(x), mload(y))) {
                        x := add(x, 0x20)
                        mstore(x, mload(y))
                    }
                    y := add(y, 0x20)
                    if eq(y, end) { break }
                }
                mstore(a, shr(5, sub(x, a)))
            }
        }
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(int256[] memory a) internal pure {
        uniquifySorted(_toUints(a));
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(address[] memory a) internal pure {
        uniquifySorted(_toUints(a));
    }

    /// @dev Returns whether `a` contains `needle`,
    /// and the index of the nearest element less than or equal to `needle`.
    function searchSorted(uint256[] memory a, uint256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(a, needle, 0);
    }

    /// @dev Returns whether `a` contains `needle`,
    /// and the index of the nearest element less than or equal to `needle`.
    function searchSorted(int256[] memory a, int256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint256(needle), 1 << 255);
    }

    /// @dev Returns whether `a` contains `needle`,
    /// and the index of the nearest element less than or equal to `needle`.
    function searchSorted(address[] memory a, address needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint256(uint160(needle)), 0);
    }

    /// @dev Reverses the array in-place.
    function reverse(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(mload(a), 2)) {
                let s := 0x20
                let w := not(31)
                let h := add(a, shl(5, mload(a)))
                for { a := add(a, s) } 1 {} {
                    let t := mload(a)
                    mstore(a, mload(h))
                    mstore(h, t)
                    h := add(h, w)
                    a := add(a, s)
                    if iszero(lt(a, h)) { break }
                }
            }
        }
    }

    /// @dev Reverses the array in-place.
    function reverse(int256[] memory a) internal pure {
        reverse(_toUints(a));
    }

    /// @dev Reverses the array in-place.
    function reverse(address[] memory a) internal pure {
        reverse(_toUints(a));
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := iszero(gt(p, mload(a)))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(int256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := iszero(sgt(p, mload(a)))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(address[] memory a) internal pure returns (bool result) {
        result = isSorted(_toUints(a));
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := lt(p, mload(a))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(int256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := slt(p, mload(a))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(address[] memory a) internal pure returns (bool result) {
        result = isSortedAndUniquified(_toUints(a));
    }

    /// @dev Returns the sorted set difference of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _difference(a, b, 0);
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_difference(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_difference(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _intersection(a, b, 0);
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_intersection(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_intersection(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _union(a, b, 0);
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_union(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set union between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_union(_toUints(a), _toUints(b), 0));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(int256[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(address[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            // As any address written to memory will have the upper 96 bits
            // of the word zeroized (as per Solidity spec), we can directly
            // compare these addresses as if they are whole uint256 words.
            casted := a
        }
    }

    /// @dev Reinterpret cast to an int array.
    function _toInts(uint256[] memory a) private pure returns (int256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an address array.
    function _toAddresses(uint256[] memory a) private pure returns (address[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Converts an array of signed two-complement integers
    /// to unsigned integers suitable for sorting.
    function _convertTwosComplement(int256[] memory a) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := shl(255, 1)
            for { let end := add(a, shl(5, mload(a))) } iszero(eq(a, end)) {} {
                a := add(a, 0x20)
                mstore(a, add(mload(a), w))
            }
        }
    }

    /// @dev Returns whether `a` contains `needle`,
    /// and the index of the nearest element less than or equal to `needle`.
    function _searchSorted(uint256[] memory a, uint256 needle, uint256 signed)
        private
        pure
        returns (bool found, uint256 index)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := 0 // Middle slot.
            let s := 0x20
            let l := add(a, s) // Slot of the start of search.
            let h := add(a, shl(5, mload(a))) // Slot of the end of search.
            for { needle := add(signed, needle) } 1 {} {
                // Average of `l` and `h`.
                m := add(shl(5, shr(6, add(l, h))), and(31, l))
                let t := add(signed, mload(m))
                found := eq(t, needle)
                if or(gt(l, h), found) { break }
                // Decide whether to search the left or right half.
                if iszero(gt(needle, t)) {
                    h := sub(m, s)
                    continue
                }
                l := add(m, s)
            }
            // `m` will be less than `add(a, 0x20)` in the case of an empty array,
            // or when the value is less than the smallest value in the array.
            let t := iszero(lt(m, add(a, s)))
            index := shr(5, mul(sub(m, add(a, s)), t))
            found := and(found, t)
        }
    }

    /// @dev Returns the sorted set difference of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _difference(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    b := add(b, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                a := add(a, s)
            }
            for {} iszero(gt(a, aEnd)) {} {
                k := add(k, s)
                mstore(k, mload(a))
                a := add(a, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _intersection(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    b := add(b, s)
                    continue
                }
                a := add(a, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _union(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    k := add(k, s)
                    mstore(k, v)
                    b := add(b, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                a := add(a, s)
            }
            for {} iszero(gt(a, aEnd)) {} {
                k := add(k, s)
                mstore(k, mload(a))
                a := add(a, s)
            }
            for {} iszero(gt(b, bEnd)) {} {
                k := add(k, s)
                mstore(k, mload(b))
                b := add(b, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }
}

/*///////////////////////////////////////////////////////////////
                                ERRORS
//////////////////////////////////////////////////////////////*/
error MustProlongLock(uint256 oldDuration, uint256 newDuration);
error AmountIsZero();
error TransferFailed();
error NothingToClaim();
error LockStillActive();
error DurationOutOfBounds(uint256 duration);
error UpdateToSmallerMultiplier(uint16 oldMultiplier, uint16 newMultiplier);
error ZeroAddress();
error ZeroPrecision();
error ZeroAmount();
error MaxLocksSucceeded();
error MaxRewardsSucceeded();
error CanOnlyAddFutureRewards();
error NotRewardoor();
error CantAutoCompound();
error AlreadyAutoCompound();
error NotAutoCompoundEnabled();
error RewardStartEqEnd();
error IntervalNotRoundedWithEpoch();
error CantChangePast();
error CantUpdateExpiredLock();

contract LockedStaking is Initializable, OwnableUpgradeable {
    using BitMaps for BitMaps.BitMap;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event LockAdded(address indexed from, uint208 amount, uint32 end, uint16 multiplier);
    event LockUpdated(address indexed from, uint8 index, uint208 amount, uint32 end, uint16 multiplier);
    event Unlock(address indexed from, uint256 amount, uint256 index);
    event Claim(address indexed from, uint256 amount);
    event RewardAdded(uint256 start, uint256 end, uint256 amountPerSecond);
    event RewardUpdated(uint256 index, uint256 start, uint256 end, uint256 amountPerSecond);
    event RewardRemoved(uint256 index);
    event AutoCompoundEnabled(address indexed from, uint256 index, uint256 shares);
    event AutoCompoundDisabled(address indexed from, uint256 index, uint256 amount);
    event AutoCompounded(uint256 compoundAmount);
    event RewardoorSet(address indexed rewardoor, bool value);

    /*///////////////////////////////////////////////////////////////
                             IMMUTABLES & CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAX_LOCK_COUNT = 5;
    uint256 public constant MAX_REWARD_COUNT = 5;
    uint256 public constant MAX_MULTIPLIER = 998;
    uint256 public constant EPOCH_DURATION = 8 * 60 * 60;
    uint256 public constant ALGORITHM_THRESHOLD_IN_EPOCHS = 5;

    /*///////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct Lock {
        uint16 multiplier;
        uint32 end;
        uint208 amount;
    }

    struct Reward {
        uint32 start;
        uint32 end;
        uint192 amountPerSecond;
    }

    struct TotalReward {
        uint256 start;
        uint256 end;
        uint256 epochReward;
    }

    struct CompoundVars {
        uint256 from;
        uint256 to;
        uint256 currentPeriod;
        uint256 compoundClaimable;
        uint256 epochRewards;
        uint256 currCompLastAccRewardWeight;
    }

    /*///////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/
    IERC20 public swapToken;
    uint256 public precision; // no longer used but kept for upgradeability
    Reward[] public rewards;
    mapping(address => Lock[]) public locks;
    mapping(address => uint256) public userLastAccRewardsWeight;

    uint256 public lastRewardUpdate;
    uint256 public totalScore;
    uint256 public accRewardWeight;

    mapping(address => bool) public rewardoors;

    BitMaps.BitMap private lockCompoundedBitMap;
    uint256 public compoundAmount;
    uint256 public compoundShares;
    uint256 public compoundLastAccRewardWeight;

    /*///////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyRewardoor() {
        if (!rewardoors[msg.sender]) revert NotRewardoor();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                             EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function initialize(address _swapToken, uint256 _precision) external initializer {
        if (_swapToken == address(0)) revert ZeroAddress();
        if (_precision == 0) revert ZeroPrecision();

        swapToken = IERC20(_swapToken);
        precision = _precision;

        __Ownable_init();
    }

    /// @notice Adds new reward
    function addReward(
        uint32 start,
        uint32 end,
        uint192 amountPerSecond
    ) external onlyRewardoor {
        if (rewards.length == MAX_REWARD_COUNT) revert MaxRewardsSucceeded();
        if (amountPerSecond == 0) revert AmountIsZero();
        if (start == end) revert RewardStartEqEnd();
        if (start < block.timestamp || end < block.timestamp) revert CanOnlyAddFutureRewards();
        if (start % EPOCH_DURATION != 0) revert IntervalNotRoundedWithEpoch();
        if (end % EPOCH_DURATION != 0) revert IntervalNotRoundedWithEpoch();

        rewards.push(Reward(start, end, amountPerSecond));

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), (end - start) * amountPerSecond))
            revert TransferFailed();

        emit RewardAdded(start, end, amountPerSecond);
    }

    /// @notice Removes existing reward and sends remaining reward to owner
    function removeReward(uint256 index) external onlyRewardoor {
        updateRewardsWeight();

        Reward memory reward = rewards[index];

        rewards[index] = rewards[rewards.length - 1];
        rewards.pop();

        // if rewards are not unlocked completely, send remaining to owner
        if (reward.end > block.timestamp) {
            uint256 lockedRewards = (reward.end - max(block.timestamp, reward.start)) * reward.amountPerSecond;

            if (!IERC20(swapToken).transfer(msg.sender, lockedRewards)) revert TransferFailed();
        }

        emit RewardRemoved(index);
    }

    /// @notice Updates existing reward, cant change reward start if its already started
    function updateReward(
        uint256 index,
        uint256 newStart,
        uint256 newEnd,
        uint256 newAmountPerSecond
    ) external onlyRewardoor {
        if (newStart % EPOCH_DURATION != 0) revert IntervalNotRoundedWithEpoch();
        if (newEnd % EPOCH_DURATION != 0) revert IntervalNotRoundedWithEpoch();
        if (newAmountPerSecond == 0) revert ZeroAmount();

        updateRewardsWeight();

        Reward storage reward = rewards[index];

        uint256 oldEnd = reward.end;
        if (oldEnd < block.timestamp) revert CantChangePast();
        if (newEnd < block.timestamp) revert CanOnlyAddFutureRewards();

        uint256 oldStart = reward.start;
        if ((oldStart < block.timestamp || newStart < block.timestamp) && newStart != oldStart) revert CantChangePast();

        uint256 newTotalRewards = (newEnd - newStart) * newAmountPerSecond;
        uint256 oldTotalRewards = (oldEnd - oldStart) * reward.amountPerSecond;

        if (newStart != oldStart) {
            reward.start = uint32(newStart);
        }

        reward.end = uint32(newEnd);
        reward.amountPerSecond = uint192(newAmountPerSecond);

        if (oldTotalRewards > newTotalRewards) {
            if (!IERC20(swapToken).transfer(msg.sender, oldTotalRewards - newTotalRewards)) revert TransferFailed();
        } else if (oldTotalRewards != newTotalRewards) {
            if (!IERC20(swapToken).transferFrom(msg.sender, address(this), newTotalRewards - oldTotalRewards))
                revert TransferFailed();
        }

        emit RewardUpdated(index, newStart, newEnd, newAmountPerSecond);
    }

    /// @notice Sets address eligibility to add/update rewards
    function setRewardoor(address addr, bool value) external onlyOwner {
        rewardoors[addr] = value;

        emit RewardoorSet(addr, value);
    }

    /// @notice Creates new lock for a user, adds potential claimable amount to it
    function addLock(uint208 amount, uint256 duration) external {
        if (amount == 0) revert AmountIsZero();
        if (locks[msg.sender].length == MAX_LOCK_COUNT) revert MaxLocksSucceeded();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        uint256 addedAmount = claimable + amount;

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        uint32 end = uint32(block.timestamp + duration);
        uint16 multiplier = getDurationMultiplier(duration);

        locks[msg.sender].push(Lock(multiplier, end, uint208(addedAmount)));

        totalScore += multiplier * addedAmount;

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        if (claimable != 0) {
            emit Claim(msg.sender, claimable);
        }

        emit LockAdded(msg.sender, uint208(addedAmount), end, multiplier);
    }

    /// @notice adds claimable to current lock, keeping the same end
    function compound(uint8 index) external {
        uint256 bitMapIndex = getBitMapIndex(index, msg.sender);
        if (lockCompoundedBitMap.get(bitMapIndex)) revert AlreadyAutoCompound();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        if (claimable == 0) revert NothingToClaim();

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        Lock storage lock = locks[msg.sender][index];

        if (lock.end < block.timestamp) revert CantUpdateExpiredLock();

        uint208 newAmount = uint208(lock.amount + claimable);
        uint16 multiplier = lock.multiplier;

        lock.amount = newAmount;
        totalScore += claimable * multiplier;

        emit Claim(msg.sender, claimable);

        emit LockUpdated(msg.sender, index, newAmount, lock.end, multiplier);
    }

    /// @notice adds amount + potential claimable to existing lock, keeping the same end
    /// @dev if lock has auto compound enabled, adjusts the compoundLastAccRewardWeight to have the same current claimable amount
    function updateLockAmount(uint256 index, uint208 amount) external {
        if (amount == 0) revert AmountIsZero();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        uint256 addedAmount = amount + claimable;

        Lock storage lock = locks[msg.sender][index];

        if (lock.end < block.timestamp) revert CantUpdateExpiredLock();

        uint208 newAmount;
        if (lockCompoundedBitMap.get(getBitMapIndex(index, msg.sender))) {
            uint256 oldCompoundAmount = compoundAmount;

            compoundLastAccRewardWeight = calculateCompAccRewardWeightIn(
                oldCompoundAmount,
                addedAmount,
                newAccRewardsWeight,
                compoundLastAccRewardWeight
            );

            uint256 newShares = convertToAutoCompoundShares(addedAmount);

            compoundAmount = oldCompoundAmount + addedAmount;
            compoundShares += newShares;

            newAmount = uint208(lock.amount + newShares);
        } else {
            newAmount = uint208(lock.amount + addedAmount);
        }

        lock.amount = newAmount;

        uint16 multiplier = lock.multiplier;

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        totalScore += addedAmount * multiplier;

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        if (claimable != 0) {
            emit Claim(msg.sender, claimable);
        }

        emit LockUpdated(msg.sender, uint8(index), newAmount, lock.end, multiplier);
    }

    /// @notice claims for current locks and increases duration of existing lock
    function updateLockDuration(uint8 index, uint256 duration) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        Lock storage lock = locks[msg.sender][index];

        uint32 end = uint32(block.timestamp + duration);
        if (lock.end >= end) revert MustProlongLock(lock.end, end);

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        uint16 multiplier = getDurationMultiplier(duration);

        lock.end = end;

        uint16 oldMultiplier = lock.multiplier;

        if (oldMultiplier > multiplier) revert UpdateToSmallerMultiplier(oldMultiplier, multiplier);

        lock.multiplier = multiplier;

        uint208 amount = lock.amount;
        totalScore += (multiplier - oldMultiplier) * amount;

        if (claimable != 0) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();

            emit Claim(msg.sender, claimable);
        }

        emit LockUpdated(msg.sender, index, amount, end, multiplier);
    }

    /// @notice claims for current locks
    function claim() external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        if (claimable == 0) revert NothingToClaim();

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();

        emit Claim(msg.sender, claimable);
    }

    /// @notice returns locked amount + potential claimable to user and deletes lock from array
    function unlock(uint256 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();
        Lock storage lock = locks[msg.sender][index];

        if (lock.end > block.timestamp) revert LockStillActive();

        uint256 bitMapIndex = getBitMapIndex(index, msg.sender);

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        bool isLockAutoCompound = lockCompoundedBitMap.get(bitMapIndex);
        uint256 amount;
        if (isLockAutoCompound) {
            uint256 shares = lock.amount;
            amount = convertToAutoCompoundAssets(shares);
            compoundLastAccRewardWeight = calculateCompAccRewardWeightOut(
                compoundAmount,
                amount,
                newAccRewardsWeight,
                compoundLastAccRewardWeight
            );
            compoundAmount -= amount;
            compoundShares -= shares;
        } else {
            amount = lock.amount;
        }

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        unchecked {
            totalScore -= amount * lock.multiplier;
        }

        uint256 lastLockIndex;
        unchecked {
            lastLockIndex = locks[msg.sender].length - 1;
        }

        if (index == lastLockIndex) {
            if (isLockAutoCompound) {
                lockCompoundedBitMap.unset(bitMapIndex);
            }
        } else {
            locks[msg.sender][index] = locks[msg.sender][lastLockIndex];
            uint256 lastLockBitMapIndex = getBitMapIndex(lastLockIndex, msg.sender);
            if (isLockAutoCompound) {
                if (!lockCompoundedBitMap.get(lastLockBitMapIndex)) {
                    lockCompoundedBitMap.unset(bitMapIndex);
                } else {
                    lockCompoundedBitMap.unset(lastLockBitMapIndex);
                }
            } else if (lockCompoundedBitMap.get(lastLockBitMapIndex)) {
                lockCompoundedBitMap.set(bitMapIndex);
                lockCompoundedBitMap.unset(lastLockBitMapIndex);
            }
        }

        locks[msg.sender].pop();

        if (!IERC20(swapToken).transfer(msg.sender, amount + claimable)) revert TransferFailed();

        if (claimable != 0) {
            emit Claim(msg.sender, claimable);
        }

        emit Unlock(msg.sender, amount, index);
    }

    /// @notice enables auto compound for existing lock, automatically adding all future rewards to principal
    /// @dev adjusts compoundLastAccRewardWeight so that current compound claimable remains the same
    function enableAutoCompound(uint256 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();
        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        Lock storage lock = locks[msg.sender][index];
        if (lock.multiplier != MAX_MULTIPLIER) revert CantAutoCompound();

        uint256 bitMapIndex = getBitMapIndex(index, msg.sender);
        if (lockCompoundedBitMap.get(bitMapIndex)) revert AlreadyAutoCompound();

        lockCompoundedBitMap.set(bitMapIndex);

        uint256 lockAmount = lock.amount + claimable;

        uint256 shares = convertToAutoCompoundShares(lockAmount);

        compoundLastAccRewardWeight = calculateCompAccRewardWeightIn(
            compoundAmount,
            lockAmount,
            newAccRewardsWeight,
            compoundLastAccRewardWeight
        );

        compoundAmount += lockAmount;

        compoundShares += shares;

        lock.amount = uint208(shares);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        if (claimable != 0) {
            totalScore += claimable * MAX_MULTIPLIER;
            emit Claim(msg.sender, claimable);
        }

        emit AutoCompoundEnabled(msg.sender, index, shares);
    }

    /// @notice disables auto compound for existing lock, stops automatically adding all future rewards to principal
    /// @dev adjusts compoundLastAccRewardWeight so that current compound claimable remains the same
    function disableAutoCompound(uint256 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();
        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        Lock storage lock = locks[msg.sender][index];

        uint256 bitMapIndex = getBitMapIndex(index, msg.sender);
        if (!lockCompoundedBitMap.get(bitMapIndex)) revert NotAutoCompoundEnabled();

        lockCompoundedBitMap.unset(bitMapIndex);

        uint256 sharesAmount = lock.amount;

        uint256 assets = convertToAutoCompoundAssets(sharesAmount);

        compoundLastAccRewardWeight = calculateCompAccRewardWeightOut(
            compoundAmount,
            assets,
            newAccRewardsWeight,
            compoundLastAccRewardWeight
        );

        compoundAmount -= assets;

        compoundShares -= sharesAmount;

        lock.amount = uint208(assets);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        if (claimable != 0) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();
            emit Claim(msg.sender, claimable);
        }

        emit AutoCompoundDisabled(msg.sender, index, assets);
    }

    function getRewardsLength() external view returns (uint256) {
        return rewards.length;
    }

    function getUserLocks(address addr) external view returns (Lock[] memory) {
        return locks[addr];
    }

    function getLockLength(address addr) external view returns (uint256) {
        return locks[addr].length;
    }

    function getRewards() external view returns (Reward[] memory) {
        return rewards;
    }

    /// @notice is existing lock enabled for automatically adding all future rewards to principal
    function hasLockAutoCompoundEnabled(address user, uint256 index) external view returns (bool) {
        return lockCompoundedBitMap.get(getBitMapIndex(index, user));
    }

    // gets rewards weight & returns users claimable amount
    function getUserClaimable(address user) external view returns (uint256 claimable) {
        (uint256 accRewardsWeight, , , ) = getRewardWeight();

        return calculateUserClaimable(user, accRewardsWeight);
    }

    /*///////////////////////////////////////////////////////////////
                             PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @notice updates new accrued reward weight, compound accrued reward weight, total score & compound amount
    function updateRewardsWeight() public returns (uint256) {
        (
            uint256 currAccRewardWeight,
            uint256 currCompoundLastAccRewardWeight,
            uint256 currTotalScore,
            uint256 currCompoundAmount
        ) = getRewardWeight();

        lastRewardUpdate = block.timestamp;
        accRewardWeight = currAccRewardWeight;
        compoundLastAccRewardWeight = currCompoundLastAccRewardWeight;
        totalScore = currTotalScore;

        if (currCompoundAmount != compoundAmount) {
            compoundAmount = currCompoundAmount;
            emit AutoCompounded(currCompoundAmount);
        }

        return currAccRewardWeight;
    }

    function convertToAutoCompoundShares(uint256 assets) public view returns (uint256) {
        uint256 supply = compoundShares;

        return supply == 0 ? assets : assets.mulDivDown(supply, compoundAmount);
    }

    function convertToAutoCompoundAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = compoundShares;

        return supply == 0 ? shares : shares.mulDivDown(compoundAmount, supply);
    }

    /*///////////////////////////////////////////////////////////////
                             INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice calculates new accrued reward weight and does auto compound
    /// @dev iterate over all rewards on every epoch to find epoch reward
    function getRewardWeightRegular()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currTotalScore = totalScore;
        if (currTotalScore == 0) {
            return (accRewardWeight, compoundLastAccRewardWeight, currTotalScore, compoundAmount);
        }

        uint256 _lastRewardUpdate = lastRewardUpdate;

        uint256 currAccRewardWeight = accRewardWeight;
        uint256 currCompoundLastAccRewardWeight = compoundLastAccRewardWeight;

        uint256 currCompoundAmount = compoundAmount;

        Reward[] memory rewardsMem = rewards;

        uint256 from;
        uint256 to;
        uint256 epochRewards;
        uint256 compoundClaimable;

        from = _lastRewardUpdate;
        to = getEpoch(_lastRewardUpdate) + EPOCH_DURATION;
        while (to <= block.timestamp) {
            epochRewards = getPeriodRewards(rewardsMem, from, to);
            unchecked {
                currAccRewardWeight += epochRewards.divWadDown(currTotalScore);
                compoundClaimable = (currAccRewardWeight - currCompoundLastAccRewardWeight).mulWadDown(
                    currCompoundAmount * MAX_MULTIPLIER
                );
                currCompoundAmount += compoundClaimable;
                currCompoundLastAccRewardWeight = currAccRewardWeight;
                currTotalScore += compoundClaimable * MAX_MULTIPLIER;

                from = to;
                to += EPOCH_DURATION;
            }
        }

        if (from < block.timestamp) {
            epochRewards = getPeriodRewards(rewardsMem, from, block.timestamp);

            currAccRewardWeight += epochRewards.divWadDown(currTotalScore);
        }

        return (currAccRewardWeight, currCompoundLastAccRewardWeight, currTotalScore, currCompoundAmount);
    }

    /// @notice calculates new accrued reward weight and does auto compound if needed
    /// @dev if we're still in the same epoch as last one, dont do auto compounding
    /// @dev if more than 5 epochs have passed since last update, do the optimized method(find intersections, sort, calculate, apply)
    /// @dev if no more than 5 epochs have passed since last update, do the regular method(iterate over all rewards every epoch)
    /// @return new accRewardWeight, compoundLastAccRewardWeight, totalScore, compoundAmount
    function getRewardWeight()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rewardUpdate = lastRewardUpdate;
        if (rewardUpdate == block.timestamp) {
            return (accRewardWeight, compoundLastAccRewardWeight, totalScore, compoundAmount);
        }

        uint256 lastUpdateEpoch = getEpoch(rewardUpdate);
        uint256 currEpoch = getEpoch(block.timestamp);

        if (lastUpdateEpoch == currEpoch) {
            return (getRewardWeightWithoutAutoComp(), compoundLastAccRewardWeight, totalScore, compoundAmount);
        }

        unchecked { 
            if ((currEpoch - lastUpdateEpoch) / EPOCH_DURATION > ALGORITHM_THRESHOLD_IN_EPOCHS) {
                return getRewardWeightOpt();
            }   
        }

        return getRewardWeightRegular();
    }

    /// @notice calculates new accrued reward weight and does auto compound if needed in an optimized way
    /// @dev first finds intersections of lastRewardUpdate, block.timestamp and reward interval
    /// @dev then sorts them and calculates total reward per epoch for every period
    /// @dev then goes through epochs and compounds claimable amount to principal
    function getRewardWeightOpt()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currTotalScore = totalScore;
        if (currTotalScore == 0) {
            return (accRewardWeight, compoundLastAccRewardWeight, currTotalScore, compoundAmount);
        }

        CompoundVars memory compVars;
        compVars.from = lastRewardUpdate;

        uint256 currAccRewardWeight = accRewardWeight;
        compVars.currCompLastAccRewardWeight = compoundLastAccRewardWeight;
        uint256 currCompoundAmount = compoundAmount;

        Reward[] memory rewardsMem = rewards;
        (uint256[] memory intersections, uint256 emptyIntersections) = getPeriodIntersections(
            compVars.from,
            block.timestamp,
            rewardsMem
        );

        if (intersections.length == emptyIntersections) {
            return (currAccRewardWeight, compVars.currCompLastAccRewardWeight, currTotalScore, compoundAmount);
        }

        LibSort.insertionSort(intersections);
        (TotalReward[] memory periodsTotalReward, uint256 zeroPeriods) = getTotalRewardPeriods(
            intersections,
            rewardsMem,
            emptyIntersections
        );

        compVars.to = getEpoch(compVars.from) + EPOCH_DURATION;

        while (compVars.to <= block.timestamp && compVars.currentPeriod < periodsTotalReward.length - zeroPeriods) {
            // reward period hasnt started, go to next epoch
            if (periodsTotalReward[compVars.currentPeriod].start > compVars.from) {
                (compVars.from, compVars.to) = goToNextEpoch(compVars.to);
                continue;
            }

            // reward period has ended, go to next reward period
            if (periodsTotalReward[compVars.currentPeriod].end < compVars.to) {
                unchecked {
                    ++compVars.currentPeriod;
                }
                continue;
            }

            // reward period has 0 rewards, go to next epoch
            if (periodsTotalReward[compVars.currentPeriod].epochReward == 0) {
                (compVars.from, compVars.to) = goToNextEpoch(compVars.to);
                continue;
            }

            // for first period, epoch rewards might already be accounted for, so take just proportionaly
            if (compVars.currentPeriod == 0 && compVars.to - compVars.from < EPOCH_DURATION) {
                unchecked {
                    compVars.epochRewards = periodsTotalReward[compVars.currentPeriod].epochReward.mulDivDown(
                        compVars.to - compVars.from,
                        EPOCH_DURATION
                    );
                }
            } else {
                compVars.epochRewards = periodsTotalReward[compVars.currentPeriod].epochReward;
            }

            // compound
            unchecked {
                currAccRewardWeight += compVars.epochRewards.divWadDown(currTotalScore);
                compVars.compoundClaimable = (currAccRewardWeight - compVars.currCompLastAccRewardWeight).mulWadDown(
                    currCompoundAmount * MAX_MULTIPLIER
                );
                compVars.currCompLastAccRewardWeight = currAccRewardWeight;
                currCompoundAmount += compVars.compoundClaimable;
                currTotalScore += compVars.compoundClaimable * MAX_MULTIPLIER;
            }

            (compVars.from, compVars.to) = goToNextEpoch(compVars.to);
        }

        // auto compound is over, calculate potential new accrued reward weight
        if (compVars.from < block.timestamp && compVars.currentPeriod < periodsTotalReward.length) {
            // if last reward period ended with last epoch, and new period exist, go to new period
            if (
                periodsTotalReward[compVars.currentPeriod].end < block.timestamp &&
                compVars.currentPeriod < periodsTotalReward.length - zeroPeriods - 1
            ) {
                unchecked {
                    ++compVars.currentPeriod;
                }
            }

            if (periodsTotalReward[compVars.currentPeriod].end >= block.timestamp) {
                unchecked {
                    uint256 newRewards = (periodsTotalReward[compVars.currentPeriod].epochReward *
                        (block.timestamp - compVars.from)) / EPOCH_DURATION;

                    currAccRewardWeight += newRewards.divWadDown(currTotalScore);
                }
            }
        }

        return (currAccRewardWeight, compVars.currCompLastAccRewardWeight, currTotalScore, currCompoundAmount);
    }

    // calculates rewards weight
    function getRewardWeightWithoutAutoComp() internal view returns (uint256) {
        // to avoid div by zero on first lock
        uint256 _totalScore = totalScore;
        if (_totalScore == 0) {
            return accRewardWeight;
        }

        uint256 _lastRewardUpdate = lastRewardUpdate;

        uint256 length = rewards.length;
        uint256 newRewards;
        Reward storage reward;
        for (uint256 rewardId = 0; rewardId < length; ) {
            reward = rewards[rewardId];

            unchecked {
                ++rewardId;
            }

            uint256 start = reward.start;
            uint256 end = reward.end;

            if (block.timestamp < start) continue;
            if (_lastRewardUpdate > end) continue;

            newRewards += (min(block.timestamp, end) - max(start, _lastRewardUpdate)) * reward.amountPerSecond;
        }

        return newRewards == 0 ? accRewardWeight : accRewardWeight + newRewards.divWadDown(_totalScore);
    }

    // returns users score for all locks
    function getUsersNoCompoundScore(address user) internal view returns (uint256 score) {
        uint256 lockLength = locks[user].length;
        Lock storage lock;
        for (uint256 lockId = 0; lockId < lockLength; ++lockId) {
            lock = locks[user][lockId];
            if (lockCompoundedBitMap.get(getBitMapIndex(lockId, user))) {
                continue;
            }
            score += lock.amount * lock.multiplier;
        }
    }

    /// @notice returns users claimable amount, not taking auto compound enabled locks into account
    function calculateUserClaimable(address user, uint256 accRewardsWeight_) internal view returns (uint256 claimable) {
        uint256 userScore = getUsersNoCompoundScore(user);

        unchecked {
            return calculateClaimable(userScore, accRewardsWeight_ - userLastAccRewardsWeight[user]);
        }
    }

    /// @notice calculates claimable amount given score and accrued reward weight difference
    function calculateClaimable(uint256 score, uint256 accRewardWeightDiff) internal pure returns (uint256) {
        return score.mulWadDown(accRewardWeightDiff);
    }

    /// @notice returns smaller of two uint256
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x < y ? x : y;
    }

    /// @notice return bigger of two uint256
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x > y ? x : y;
    }

    // returns multiplier on amount locked for duration in seconds times 100
    // aprox of function (2592000,1),(31536000,2),(94608000,5),(157680000,10)
    // 2.22574×10^-16 x^2 + 2.19094×10^-8 x + 0.993975
    function getDurationMultiplier(uint256 duration) internal pure returns (uint16) {
        if (duration < 30 days || duration > 1825 days) revert DurationOutOfBounds(duration);

        return uint16((222574 * duration * duration + 21909400000000 * duration + 993975000000000000000) / 1e19);
    }

    /// @notice returns uint256 index for bitmap used to indicate whether lock is enabled for auto compound
    /// @dev first 160 bits are address, last 96 bits are index, index is currently never bigger than 5
    function getBitMapIndex(uint256 index, address addr) internal pure returns (uint256) {
        return uint256(index | (uint160(addr) << 96));
    }

    /// @notice calculates new compound accrued reward weight, to have the same claimable amount with added amount
    function calculateCompAccRewardWeightIn(
        uint256 currCompoundAmount,
        uint256 incomingAmount,
        uint256 lastAccRewardWeight,
        uint256 lastCompAccRewardWeight
    ) internal pure returns (uint256) {
        return
            lastAccRewardWeight -
            ((lastAccRewardWeight - lastCompAccRewardWeight) * currCompoundAmount) /
            (currCompoundAmount + incomingAmount);
    }

    /// @notice calculates new compound accrued reward weight, to have the same claimable amount with substracted amount
    function calculateCompAccRewardWeightOut(
        uint256 currCompoundAmount,
        uint256 incomingAmount,
        uint256 lastAccRewardWeight,
        uint256 lastCompAccRewardWeight
    ) internal pure returns (uint256) {
        if (incomingAmount == currCompoundAmount) return lastAccRewardWeight;
        return
            lastAccRewardWeight -
            ((lastAccRewardWeight - lastCompAccRewardWeight) * currCompoundAmount) /
            (currCompoundAmount - incomingAmount);
    }

    function getEpoch(uint256 timestamp) internal pure returns (uint256) {
        unchecked {
            return timestamp - (timestamp % EPOCH_DURATION);
        }
    }

    /// @notice calculates eligible rewards for given time interval
    function getPeriodRewards(
        Reward[] memory rewardsMem,
        uint256 from,
        uint256 to
    ) internal pure returns (uint256 epochRewards) {
        for (uint256 i = 0; i < rewardsMem.length; ) {
            if (to < rewardsMem[i].start) {
                unchecked {
                    ++i;
                }
                continue;
            }
            if (from > rewardsMem[i].end) {
                unchecked {
                    ++i;
                }
                continue;
            }

            unchecked {
                epochRewards +=
                    (min(to, rewardsMem[i].end) - max(rewardsMem[i].start, from)) *
                    rewardsMem[i].amountPerSecond;
                ++i;
            }
        }
    }

    /// @notice calculates total reward per epoch for multiple rewards that change on intersections
    function getTotalRewardPeriods(
        uint256[] memory intersections,
        Reward[] memory rewardsMem,
        uint256 emptyIntersections
    ) internal pure returns (TotalReward[] memory totalRewards, uint256 zeroPeriods) {
        totalRewards = new TotalReward[](intersections.length - emptyIntersections - 1);

        uint256 start;
        uint256 end;
        uint256 epochReward;
        uint256 j;
        uint256 periodsIdx;
        for (uint256 i = emptyIntersections; i < intersections.length - 1; ) {
            start = intersections[i];
            end = intersections[i + 1];
            if (start == end) {
                unchecked {
                    ++zeroPeriods;
                    ++i;
                }

                continue;
            }
            epochReward = 0;
            for (j = 0; j < rewardsMem.length; ) {
                if (rewardsMem[j].start > start) {
                    unchecked {
                        ++j;
                    }
                    continue;
                }
                if (rewardsMem[j].end < end) {
                    unchecked {
                        ++j;
                    }
                    continue;
                }

                unchecked {
                    epochReward += EPOCH_DURATION * rewardsMem[j].amountPerSecond;
                    ++j;
                }
            }

            unchecked {
                ++i;
                totalRewards[periodsIdx++] = TotalReward(start, end, epochReward);
            }
        }

        return (totalRewards, zeroPeriods);
    }

    /// @notice gets intersections of reward intervals and arbitrary interval
    function getPeriodIntersections(
        uint256 from,
        uint256 to,
        Reward[] memory rewardsMem
    ) internal pure returns (uint256[] memory, uint256) {
        // in the worst case where all rewards are eligible we're going to have x2 intersections
        uint256[] memory intersections = new uint256[](rewardsMem.length * 2);
        uint256 emptyIntersections;
        uint256 start;
        uint256 end;
        uint256 intersectionsIdx;

        for (uint256 i; i < rewardsMem.length; ) {
            start = max(from, rewardsMem[i].start);
            end = min(to, rewardsMem[i].end);
            unchecked {
                if (start < end) {
                    intersections[intersectionsIdx++] = start;
                    intersections[intersectionsIdx++] = end;
                } else {
                    emptyIntersections += 2;
                }

                ++i;
            }
        }

        return (intersections, emptyIntersections);
    }

    /// @notice return next epoch start and ending point
    function goToNextEpoch(uint256 to) internal pure returns (uint256, uint256) {
        unchecked {
            return (to, to + EPOCH_DURATION);
        }
    }
}