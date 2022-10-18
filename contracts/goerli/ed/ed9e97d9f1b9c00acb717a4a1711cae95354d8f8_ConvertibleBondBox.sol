// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
      returns (uint256[] memory arr)
    {
      uint256 offset = _getImmutableArgsOffset();
      uint256 el;
      arr = new uint256[](arrLen);
      for (uint64 i = 0; i < arrLen; i++) {
        assembly {
          // solhint-disable-next-line no-inline-assembly
          el := calldataload(add(add(offset, argOffset), mul(i, 32)))
        }
        arr[i] = el;
      }
      return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

struct TrancheData {
    ITranche token;
    uint256 ratio;
}

/**
 * @dev Controller for a ButtonTranche bond system
 */
interface IBondController {
    event Deposit(address from, uint256 amount, uint256 feeBps);
    event Mature(address caller);
    event RedeemMature(address user, address tranche, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event FeeUpdate(uint256 newFee);

    function collateralToken() external view returns (address);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function feeBps() external view returns (uint256 fee);

    function maturityDate() external view returns (uint256 maturityDate);

    function isMature() external view returns (bool isMature);

    function creationDate() external view returns (uint256 creationDate);

    function totalDebt() external view returns (uint256 totalDebt);

    /**
     * @dev Deposit `amount` tokens from `msg.sender`, get tranche tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amount` collateral tokens to this contract
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Matures the bond. Disables deposits,
     * fixes the redemption ratio, and distributes collateral to redemption pools
     * Redeems any fees collected from deposits, sending redeemed funds to the contract owner
     * Requirements:
     *  - The bond is not already mature
     *  - One of:
     *      - `msg.sender` is owner
     *      - `maturityDate` has passed
     */
    function mature() external;

    /**
     * @dev Redeems some tranche tokens
     * Requirements:
     *  - The bond is mature
     *  - `msg.sender` owns at least `amount` tranche tokens from address `tranche`
     *  - `tranche` must be a valid tranche token on this bond
     */
    function redeemMature(address tranche, uint256 amount) external;

    /**
     * @dev Redeems a slice of tranche tokens from all tranches.
     *  Returns collateral to the user proportionally to the amount of debt they are removing
     * Requirements
     *  - The bond is not mature
     *  - The number of `amounts` is the same as the number of tranches
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function redeem(uint256[] memory amounts) external;

    /**
     * @dev Updates the fee taken on deposit to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */
    function setFee(uint256 newFeeBps) external;
}

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @dev ERC20 token to represent a single tranche for a ButtonTranche bond
 *
 */
interface ITranche is IERC20 {
    /**
     * @dev returns the BondController address which owns this Tranche contract
     *  It should have admin permissions to call mint, burn, and redeem functions
     */
    function bond() external view returns (address);

    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically creating tokens upon deposit
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically burning tokens upon redemption
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from` and return the proportional
     * value of the collateral token to `to`
     * @param from The address to burn tokens from
     * @param to The address to send collateral back to
     * @param amount The amount of tokens to burn
     */
    function redeem(
        address from,
        address to,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../../utils/CBBImmutableArgs.sol";
import "../interfaces/IConvertibleBondBox.sol";

/**
 * @dev Convertible Bond Box for a ButtonTranche bond
 *
 * Invariants:
 *  - initial Price must be <= $1.00
 *  - penalty ratio must be < 1.0
 *  - safeTranche index must not be Z-tranche
 *
 * Assumptions:
 * - Stabletoken has a market price of $1.00
 * - ButtonToken to be used as collateral in the underlying ButtonBond rebases to $1.00
 *
 * While it is possible to deploy a bond without the above assumptions enforced, it will produce faulty math and repayment prices
 */

contract ConvertibleBondBox is
    OwnableUpgradeable,
    CBBImmutableArgs,
    IConvertibleBondBox
{
    // Set when reinitialized
    uint256 public override s_startDate;
    uint256 public s_initialPrice;

    uint256 public override s_repaidSafeSlips;

    // Changeable by owner
    uint256 public override feeBps;

    uint256 public constant override s_trancheGranularity = 1000;
    uint256 public constant override s_penaltyGranularity = 1000;
    uint256 public constant override s_priceGranularity = 1e8;

    // Denominator for basis points. Used to calculate fees
    uint256 public constant override BPS = 10_000;
    uint256 public constant override maxFeeBPS = 50;

    modifier afterReinitialize() {
        if (s_startDate == 0) {
            revert ConvertibleBondBoxNotStarted({
                given: 0,
                minStartDate: block.timestamp
            });
        }
        _;
    }

    modifier beforeBondMature() {
        if (block.timestamp >= maturityDate()) {
            revert BondIsMature({
                currentTime: block.timestamp,
                maturity: maturityDate()
            });
        }
        _;
    }

    modifier afterBondMature() {
        if (block.timestamp < maturityDate()) {
            revert BondNotMatureYet({
                maturityDate: maturityDate(),
                currentTime: block.timestamp
            });
        }
        _;
    }

    modifier validAmount(uint256 amount) {
        if (amount < 1e6) {
            revert MinimumInput({input: amount, reqInput: 1e6});
        }
        _;
    }

    function initialize(address _owner) external initializer beforeBondMature {
        require(
            _owner != address(0),
            "ConvertibleBondBox: invalid owner address"
        );

        // Revert if penalty too high
        if (penalty() > s_penaltyGranularity) {
            revert PenaltyTooHigh({
                given: penalty(),
                maxPenalty: s_penaltyGranularity
            });
        }

        // Set owner
        __Ownable_init();
        transferOwnership(_owner);

        emit Initialized(_owner);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function reinitialize(uint256 _initialPrice)
        external
        reinitializer(2)
        onlyOwner
        beforeBondMature
    {
        if (_initialPrice > s_priceGranularity)
            revert InitialPriceTooHigh({
                given: _initialPrice,
                maxPrice: s_priceGranularity
            });
        if (_initialPrice == 0)
            revert InitialPriceIsZero({given: 0, maxPrice: s_priceGranularity});

        s_initialPrice = _initialPrice;

        //set ConvertibleBondBox Start Date to be time when init() is called
        s_startDate = block.timestamp;

        emit ReInitialized(_initialPrice, block.timestamp);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function lend(
        address _borrower,
        address _lender,
        uint256 _stableAmount
    )
        external
        override
        afterReinitialize
        beforeBondMature
        validAmount(_stableAmount)
    {
        uint256 price = _currentPrice();

        uint256 safeSlipAmount = (_stableAmount *
            s_priceGranularity *
            trancheDecimals()) /
            price /
            stableDecimals();

        uint256 zTrancheAmount = (safeSlipAmount * riskRatio()) / safeRatio();

        _atomicDeposit(
            _borrower,
            _lender,
            _stableAmount,
            safeSlipAmount,
            zTrancheAmount
        );

        emit Lend(_msgSender(), _borrower, _lender, _stableAmount, price);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function borrow(
        address _borrower,
        address _lender,
        uint256 _safeTrancheAmount
    )
        external
        override
        afterReinitialize
        beforeBondMature
        validAmount(_safeTrancheAmount)
    {
        uint256 price = _currentPrice();

        uint256 zTrancheAmount = (_safeTrancheAmount * riskRatio()) /
            safeRatio();
        uint256 stableAmount = (_safeTrancheAmount * price * stableDecimals()) /
            s_priceGranularity /
            trancheDecimals();

        _atomicDeposit(
            _borrower,
            _lender,
            stableAmount,
            _safeTrancheAmount,
            zTrancheAmount
        );

        emit Borrow(
            _msgSender(),
            _borrower,
            _lender,
            _safeTrancheAmount,
            price
        );
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function currentPrice()
        public
        view
        override
        afterReinitialize
        returns (uint256)
    {
        return _currentPrice();
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function repay(uint256 _stableAmount)
        external
        override
        afterReinitialize
        validAmount(_stableAmount)
    {
        //Load into memory
        uint256 price = _currentPrice();

        //calculate inputs for internal redeem function
        uint256 stableFees = (_stableAmount * feeBps) / BPS;
        uint256 safeTranchePayout = (_stableAmount *
            s_priceGranularity *
            trancheDecimals()) /
            price /
            stableDecimals();
        uint256 riskTranchePayout = (safeTranchePayout * riskRatio()) /
            safeRatio();

        _repay(_stableAmount, stableFees, safeTranchePayout, riskTranchePayout);
        emit Repay(_msgSender(), _stableAmount, riskTranchePayout, price);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function repayMax(uint256 _riskSlipAmount)
        external
        override
        afterReinitialize
        validAmount(_riskSlipAmount)
    {
        // Load params into memory
        uint256 price = _currentPrice();

        // Calculate inputs for internal repay function
        uint256 safeTranchePayout = (_riskSlipAmount * safeRatio()) /
            riskRatio();
        uint256 stablesOwed = (safeTranchePayout * price * stableDecimals()) /
            s_priceGranularity /
            trancheDecimals();
        uint256 stableFees = (stablesOwed * feeBps) / BPS;

        _repay(stablesOwed, stableFees, safeTranchePayout, _riskSlipAmount);

        //emit event
        emit Repay(_msgSender(), stablesOwed, _riskSlipAmount, price);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function redeemRiskTranche(uint256 _riskSlipAmount)
        external
        override
        afterBondMature
        validAmount(_riskSlipAmount)
    {
        //transfer fee to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            uint256 feeSlip = (_riskSlipAmount * feeBps) / BPS;
            riskSlip().transferFrom(_msgSender(), owner(), feeSlip);
            _riskSlipAmount -= feeSlip;
        }

        uint256 zTranchePayout = (_riskSlipAmount *
            (s_penaltyGranularity - penalty())) / (s_penaltyGranularity);

        //transfer Z-tranches from ConvertibleBondBox to msg.sender
        riskTranche().transfer(_msgSender(), zTranchePayout);

        riskSlip().burn(_msgSender(), _riskSlipAmount);

        emit RedeemRiskTranche(_msgSender(), _riskSlipAmount);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function redeemSafeTranche(uint256 _safeSlipAmount)
        external
        override
        afterBondMature
        validAmount(_safeSlipAmount)
    {
        //transfer fee to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            uint256 feeSlip = (_safeSlipAmount * feeBps) / BPS;
            safeSlip().transferFrom(_msgSender(), owner(), feeSlip);
            _safeSlipAmount -= feeSlip;
        }

        uint256 safeSlipSupply = safeSlip().totalSupply();

        //burn safe-slips
        safeSlip().burn(_msgSender(), _safeSlipAmount);

        //transfer safe-Tranche after maturity only
        safeTranche().transfer(_msgSender(), _safeSlipAmount);

        uint256 zPenaltyTotal = riskTranche().balanceOf(address(this)) -
            riskSlip().totalSupply();

        //transfer risk-Tranche penalty after maturity only
        riskTranche().transfer(
            _msgSender(),
            (_safeSlipAmount * zPenaltyTotal) /
                (safeSlipSupply - s_repaidSafeSlips)
        );

        emit RedeemSafeTranche(_msgSender(), _safeSlipAmount);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function redeemStable(uint256 _safeSlipAmount)
        external
        override
        validAmount(_safeSlipAmount)
    {
        //transfer safeSlips to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            uint256 feeSlip = (_safeSlipAmount * feeBps) / BPS;
            safeSlip().transferFrom(_msgSender(), owner(), feeSlip);
            _safeSlipAmount -= feeSlip;
        }

        uint256 stableBalance = stableToken().balanceOf(address(this));

        //transfer stables
        TransferHelper.safeTransfer(
            address(stableToken()),
            _msgSender(),
            (_safeSlipAmount * stableBalance) / (s_repaidSafeSlips)
        );

        //burn safe-slips
        safeSlip().burn(_msgSender(), _safeSlipAmount);
        s_repaidSafeSlips -= _safeSlipAmount;

        emit RedeemStable(_msgSender(), _safeSlipAmount, _currentPrice());
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function setFee(uint256 newFeeBps)
        external
        override
        onlyOwner
        beforeBondMature
    {
        if (newFeeBps > maxFeeBPS)
            revert FeeTooLarge({input: newFeeBps, maximum: maxFeeBPS});

        feeBps = newFeeBps;
        emit FeeUpdate(newFeeBps);
    }

    /**
     * @inheritdoc IConvertibleBondBox
     */
    function transferOwnership(address newOwner)
        public
        override(IConvertibleBondBox, OwnableUpgradeable)
        onlyOwner
    {
        _transferOwnership(newOwner);
    }

    function _atomicDeposit(
        address _borrower,
        address _lender,
        uint256 _stableAmount,
        uint256 _safeSlipAmount,
        uint256 _riskSlipAmount
    ) internal {
        //Transfer safeTranche to ConvertibleBondBox
        safeTranche().transferFrom(
            _msgSender(),
            address(this),
            _safeSlipAmount
        );

        //Transfer riskTranche to ConvertibleBondBox
        riskTranche().transferFrom(
            _msgSender(),
            address(this),
            _riskSlipAmount
        );

        // //Mint safeSlips to the lender
        safeSlip().mint(_lender, _safeSlipAmount);

        // //Mint riskSlips to the borrower
        riskSlip().mint(_borrower, _riskSlipAmount);

        // // Transfer stables to borrower
        if (_msgSender() != _borrower) {
            TransferHelper.safeTransferFrom(
                address(stableToken()),
                _msgSender(),
                _borrower,
                _stableAmount
            );
        }
    }

    function _repay(
        uint256 _stablesOwed,
        uint256 _stableFees,
        uint256 _safeTranchePayout,
        uint256 _riskTranchePayout
    ) internal {
        // Update total repaid safe slips
        s_repaidSafeSlips += _safeTranchePayout;

        // Transfer fees to owner
        if (feeBps > 0 && _msgSender() != owner()) {
            TransferHelper.safeTransferFrom(
                address(stableToken()),
                _msgSender(),
                owner(),
                _stableFees
            );
        }

        // Transfers stables to CBB
        TransferHelper.safeTransferFrom(
            address(stableToken()),
            _msgSender(),
            address(this),
            _stablesOwed
        );

        // Transfer safeTranches to msg.sender (increment state)
        safeTranche().transfer(_msgSender(), _safeTranchePayout);

        // Transfer riskTranches to msg.sender
        riskTranche().transfer(_msgSender(), _riskTranchePayout);

        // Burn riskSlips
        riskSlip().burn(_msgSender(), _riskTranchePayout);
    }

    function _currentPrice() internal view returns (uint256) {
        if (block.timestamp < maturityDate()) {
            uint256 price = s_priceGranularity -
                ((s_priceGranularity - s_initialPrice) *
                    (maturityDate() - block.timestamp)) /
                (maturityDate() - s_startDate);

            return price;
        } else {
            return s_priceGranularity;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "../../utils/ICBBImmutableArgs.sol";

/**
 * @dev Convertible Bond Box for a ButtonTranche bond
 */

interface IConvertibleBondBox is ICBBImmutableArgs {
    event Lend(
        address caller,
        address borrower,
        address lender,
        uint256 stableAmount,
        uint256 price
    );
    event Borrow(
        address caller,
        address borrower,
        address lender,
        uint256 stableAmount,
        uint256 price
    );
    event RedeemStable(address caller, uint256 safeSlipAmount, uint256 price);
    event RedeemSafeTranche(address caller, uint256 safeSlipAmount);
    event RedeemRiskTranche(address caller, uint256 riskSlipAmount);
    event Repay(
        address caller,
        uint256 stablesPaid,
        uint256 riskTranchePayout,
        uint256 price
    );
    event Initialized(address owner);
    event ReInitialized(uint256 initialPrice, uint256 timestamp);
    event FeeUpdate(uint256 newFee);

    error PenaltyTooHigh(uint256 given, uint256 maxPenalty);
    error BondIsMature(uint256 currentTime, uint256 maturity);
    error InitialPriceTooHigh(uint256 given, uint256 maxPrice);
    error InitialPriceIsZero(uint256 given, uint256 maxPrice);
    error ConvertibleBondBoxNotStarted(uint256 given, uint256 minStartDate);
    error BondNotMatureYet(uint256 maturityDate, uint256 currentTime);
    error MinimumInput(uint256 input, uint256 reqInput);
    error FeeTooLarge(uint256 input, uint256 maximum);

    //Need to add getters for state variables

    /**
     * @dev Sets startdate to be block.timestamp, sets initialPrice, and takes initial atomic deposit
     * @param _initialPrice the initialPrice for the CBB
     * Requirements:
     *  - `msg.sender` is owner
     */

    function reinitialize(uint256 _initialPrice) external;

    /**
     * @dev Lends StableTokens for SafeSlips when provided with matching borrow collateral
     * @param _borrower The address to send the RiskSlip and StableTokens to 
     * @param _lender The address to send the SafeSlips to 
     * @param _stableAmount The amount of StableTokens to lend
     * Requirements:
     *  - `msg.sender` must have `approved` `_stableAmount` stable tokens to this contract
        - CBB must be reinitialized
     */

    function lend(
        address _borrower,
        address _lender,
        uint256 _stableAmount
    ) external;

    /**
     * @dev Borrows with tranches of CollateralTokens when provided with a matching amount of StableTokens
     * Collateral tokens get tranched and any non-convertible bond box tranches get sent back to borrower 
     * @param _borrower The address to send the RiskSlip and StableTokens to 
     * @param _lender The address to send the SafeSlips to 
     * @param _safeTrancheAmount The amount of SafeTranche being borrowed against
     * Requirements:
     *  - `msg.sender` must have `approved` appropriate amount of tranches of tokens to this contract
        - CBB must be reinitialized
        - must be enough stable tokens inside convertible bond box to borrow 
     */

    function borrow(
        address _borrower,
        address _lender,
        uint256 _safeTrancheAmount
    ) external;

    /**
     * @dev returns time-weighted current price for SafeSlip, with final price as $1.00 at maturity
     */

    function currentPrice() external view returns (uint256);

    /**
     * @dev allows repayment of loan in exchange for proportional amount of SafeTranche and Z-tranche
     * @param _stableAmount The amount of stable-Tokens to repay with
     * Requirements:
     *  - `msg.sender` must have `approved` `stableAmount` of stable tokens to this contract
     */

    function repay(uint256 _stableAmount) external;

    /**
     * @dev allows repayment of loan in exchange for proportional amount of SafeTranche and Z-tranche
     * @param _riskSlipAmount The amount of riskSlips to be repaid
     * Requirements:
     *  - `msg.sender` must have `approved` appropriate amount of stable tokens to this contract
     */

    function repayMax(uint256 _riskSlipAmount) external;

    /**
     * @dev allows lender to redeem SafeSlips for SafeTranches
     * @param _safeSlipAmount The amount of safe-slips to redeem
     * Requirements:
     *  - can only be called after Bond is Mature
     *  - `msg.sender` must have `approved` `safeSlipAmount` of SafeSlip tokens to this contract
     */

    function redeemSafeTranche(uint256 _safeSlipAmount) external;

    /**
     * @dev allows borrower to redeem RiskSlips for tranches (i.e. default)
     * @param _riskSlipAmount The amount of RiskSlips to redeem
     * Requirements:
     *  - can only be called after Bond is Mature
     *  - `msg.sender` must have `approved` `_riskSlipAmount` of RiskSlip tokens to this contract
     */

    function redeemRiskTranche(uint256 _riskSlipAmount) external;

    /**
     * @dev allows lender to redeem SafeSlips for StableTokens
     * @param _safeSlipAmount The amount of SafeSlips to redeem
     * Requirements:
     *  - `msg.sender` must have `approved` `safeSlipAmount` of safe-Slip tokens to this contract
     *  - can only be called when StableTokens are present inside CBB
     */

    function redeemStable(uint256 _safeSlipAmount) external;

    /**
     * @dev Updates the fee taken on redeem/repay to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */

    function setFee(uint256 newFeeBps) external;

    /**
     * @dev Gets the start date
     */
    function s_startDate() external view returns (uint256);

    /**
     * @dev Gets the total repaid safe slips to date
     */
    function s_repaidSafeSlips() external view returns (uint256);

    /**
     * @dev Gets the tranche granularity constant
     */
    function s_trancheGranularity() external view returns (uint256);

    /**
     * @dev Gets the penalty granularity constant
     */
    function s_penaltyGranularity() external view returns (uint256);

    /**
     * @dev Gets the price granularity constant
     */
    function s_priceGranularity() external view returns (uint256);

    /**
     * @dev Gets the fee basis points
     */
    function feeBps() external view returns (uint256);

    /**
     * @dev Gets the basis points denominator constant. AKA a fee granularity constant
     */
    function BPS() external view returns (uint256);

    /**
     * @dev Gets the max fee basis points constant.
     */
    function maxFeeBPS() external view returns (uint256);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Gets the initialPrice of SafeSlip.
     */
    function s_initialPrice() external view returns (uint256);
}

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev ERC20 token to represent a single slip for a bond box
 *
 */
interface ISlip is IERC20 {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev returns the bond box address which owns this slip contract
     *  It should have admin permissions to call mint, burn, and redeem functions
     */
    function boxOwner() external view returns (address);

    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner.
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner.
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev allows owner to transfer ownership to a new owner. Implemented so that factory can transfer minting/burning ability to CBB after deployment
     * @param newOwner The address of the CBB
     */
    function changeOwner(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "clones-with-immutable-args/Clone.sol";
import "../src/interfaces/ISlip.sol";
import "./ICBBImmutableArgs.sol";

/**
 * @notice Defines the immutable arguments for a CBB
 * @dev using the clones-with-immutable-args library
 * we fetch args from the code section
 */
contract CBBImmutableArgs is Clone, ICBBImmutableArgs {
    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function bond() public pure override returns (IBondController) {
        return IBondController(_getArgAddress(0));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function safeSlip() public pure override returns (ISlip) {
        return ISlip(_getArgAddress(20));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function riskSlip() public pure override returns (ISlip) {
        return ISlip(_getArgAddress(40));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function penalty() public pure override returns (uint256) {
        return _getArgUint256(60);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function collateralToken() public pure override returns (IERC20) {
        return IERC20(_getArgAddress(92));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function stableToken() public pure override returns (IERC20) {
        return IERC20(_getArgAddress(112));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */
    function trancheIndex() public pure override returns (uint256) {
        return _getArgUint256(132);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function maturityDate() public pure override returns (uint256) {
        return _getArgUint256(164);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function safeTranche() public pure override returns (ITranche) {
        return ITranche(_getArgAddress(196));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function safeRatio() public pure override returns (uint256) {
        return _getArgUint256(216);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function riskTranche() public pure override returns (ITranche) {
        return ITranche(_getArgAddress(248));
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function riskRatio() public pure override returns (uint256) {
        return _getArgUint256(268);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function trancheDecimals() public pure override returns (uint256) {
        return _getArgUint256(300);
    }

    /**
     * @inheritdoc ICBBImmutableArgs
     */

    function stableDecimals() public pure override returns (uint256) {
        return _getArgUint256(332);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/ISlip.sol";
import "@buttonwood-protocol/tranche/contracts/interfaces/IBondController.sol";

interface ICBBImmutableArgs {
    /**
     * @notice The bond that holds the tranches
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The underlying buttonwood bond
     */
    function bond() external pure returns (IBondController);

    /**
     * @notice The safeSlip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeSlip Slip object
     */
    function safeSlip() external pure returns (ISlip);

    /**
     * @notice The riskSlip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskSlip Slip object
     */
    function riskSlip() external pure returns (ISlip);

    /**
     * @notice penalty for zslips
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The penalty ratio
     */
    function penalty() external pure returns (uint256);

    /**
     * @notice The rebasing collateral token used to make bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The rebasing collateral token object
     */
    function collateralToken() external pure returns (IERC20);

    /**
     * @notice The stable token used to buy bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The stable token object
     */
    function stableToken() external pure returns (IERC20);

    /**
     * @notice The tranche index used to pick a safe tranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The index representing the tranche
     */
    function trancheIndex() external pure returns (uint256);

    /**
     * @notice The maturity date of the underlying buttonwood bond
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The timestamp for the bond maturity
     */

    function maturityDate() external pure returns (uint256);

    /**
     * @notice The safeTranche of the Convertible Bond Box
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeTranche tranche object
     */

    function safeTranche() external pure returns (ITranche);

    /**
     * @notice The tranche ratio of the safeTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the safeTranche
     */

    function safeRatio() external pure returns (uint256);

    /**
     * @notice The riskTranche of the Convertible Bond Box
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskTranche tranche object
     */

    function riskTranche() external pure returns (ITranche);

    /**
     * @notice The tranche ratio of the riskTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the riskTranche
     */

    function riskRatio() external pure returns (uint256);

    /**
     * @notice The decimals of tranche-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of tranche-tokens
     */

    function trancheDecimals() external pure returns (uint256);

    /**
     * @notice The decimals of stable-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of stable-tokens
     */

    function stableDecimals() external pure returns (uint256);
}