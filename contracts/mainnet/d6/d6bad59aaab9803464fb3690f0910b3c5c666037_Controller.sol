/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GNU GPLv3


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}



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
library StorageSlotUpgradeable {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

pragma solidity ^0.8.2;


/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

pragma solidity 0.8.4;

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        require(
            newImplementation != address(0),
            "Address should not be a zero address"
        );
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
        require(
            newImplementation != address(0),
            "Address should not be a zero address"
        );
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    uint256[50] private __gap;
}


pragma solidity 0.8.4;

/// @title TimestampToDateLibrary library for vesting
/// @author Capx Team
/// @notice The TimestampToDateLibrary is the library used to convert timestamp to date,month,year
/// @dev This contract uses mathematical algorithm to calculate the date from timestamp
library TimestampToDateLibrary {
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 internal constant OFFSET19700101 = 2440588;

    /// @notice Function of TimestampToDateLibrary used to convert timestamp to year,month,day
    /// @dev Uses mathematical algorithm to calculate this
    /// @param timestamp Timestamp which is needed to be converted to date
    /// Returns three variables with year,month,day values

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 L = int256((timestamp / SECONDS_PER_DAY)) +
            68569 +
            OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }
}


pragma solidity 0.8.4;

interface ERC20Properties {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity 0.8.4;

interface ERC20Clone {
    function mintbyControl(address _to, uint256 _amount) external;

    function burnbyControl(address _to, uint256 _amount) external;
}

interface Master {
    function getFactory() external view returns (address);

    function getProposal() external view returns (address);
}

pragma solidity 0.8.4;

interface AbsERC20Factory {
    function createStorage(
        string memory _wrappedTokenName,
        string memory _wrappedTokenTicker,
        uint8 _wrappedTokenDecimals,
        uint256 _vestTime
    ) external returns (address);
}

pragma solidity 0.8.4;

/// @title Controller contract for creating WVTs
/// @author Capx Team
/// @notice User can interact with the Controller contract only through Master contract.
/// @dev This contract uses openzepplin Upgradable plugin. https://docs.openzeppelin.com/upgrades-plugins/1.x/
contract Controller is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant DAY = 86400;
    uint256 internal constant _ACTIVE = 2;
    uint256 internal constant _INACTIVE = 1;

    uint256 public lastVestID;
    uint256 internal _locked;
    uint256 internal _killed;
    uint256 internal _limitOfDerivatives;
    address internal masterContract;

    mapping(uint256 => address) public derivativeIDtoAddress;
    mapping(address => uint256) public vestingTimeOfTokenId;
    mapping(address => uint256) public totalDerivativeForAsset;
    mapping(address => address) public assetAddresstoProjectOwner;
    mapping(address => address) public derivativeAdrToActualAssetAdr;

    struct derivativePair {
        address sellable;
        address nonsellable;
    }

    mapping(address => mapping(uint256 => derivativePair))
        public assetToDerivativeMap;
    mapping(address => mapping(address => uint256))
        public assetLockedForDerivative;

    event ProjectInfo(
        address indexed tokenAddress,
        string tokenTicker,
        address creator,
        uint256 tokenDecimal
    );

    event CreateVest(
        address indexed assetAddress,
        address creator,
        address userAddress,
        uint256 userAmount,
        uint256 unlockTime,
        address wrappedERC20Address,
        string wrappedAssetTicker,
        bool transferable
    );

    event TransferWrapped(
        address userAddress,
        address indexed wrappedTokenAddress,
        address receiverAddress,
        uint256 amount
    );

    event Withdraw(
        address indexed userAddress,
        uint256 amount,
        address wrappedTokenAddress
    );

    modifier noReentrant() {
        require(_locked != _ACTIVE, "ReentrancyGuard: Re-Entrant call");
        _locked = _ACTIVE;
        _;
        _locked = _INACTIVE;
    }

    function isKilled() internal view {
        require(_killed != _ACTIVE, "FailSafeMode: ACTIVE");
    }

    /// @notice Disables the WVT Creation & Withdraw functionality of the contract.
    function kill() external onlyOwner {
        _killed = _ACTIVE;
    }

    /// @notice Enables the WVT Creation & Withdraw functionality of the contract.
    function revive() external onlyOwner {
        _killed = _INACTIVE;
    }

    function initialize(address _masterContract) public initializer {
        __Ownable_init();
        lastVestID = 0;
        _killed = _INACTIVE;
        _locked = _INACTIVE;
        require(_masterContract != address(0), "Invalid Address");
        masterContract = _masterContract;
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Using this function a user can vest their project tokens till a specific date
    /// @dev Iterates over the vesting sheet received in params for
    /// @param _tokenAddress Address of the project token
    /// @param _amount Amount of tokens the user wants to vest
    /// @param _distAddress Array of Addresses to whom the project owner wants to distribute derived tokens.
    /// @param _distTime Array of Integer timestamps at which the derived tokens will be eligible for exchange with project tokens
    /// @param _distAmount Array of amount which determines how much of each derived tokens should be distributed to _distAddress
    /// @param _transferable Array of boolean determining which asset is sellable and which is not
    /// @param _caller Address calling this function through controller
    function createBulkDerivative(
        address _tokenAddress,
        uint256 _amount,
        address[] calldata _distAddress,
        uint256[] memory _distTime,
        uint256[] memory _distAmount,
        bool[] memory _transferable,
        address _caller
    ) external virtual noReentrant {
        require(msg.sender == masterContract, "Only master can call");
        isKilled();
        // Function variable Declaration
        uint256 totalAmount = 0;
        uint256 i = 0;
        _limitOfDerivatives = 20;

        require(
            (_distAddress.length == _distTime.length) &&
                (_distTime.length == _distAmount.length) &&
                (_distTime.length == _transferable.length) &&
                _distTime.length != 0 &&
                _amount != 0 &&
                _tokenAddress != address(0) &&
                _caller != address(0) &&
                _distTime.length <= 300,
            "Invalid Input"
        );

        // Registering the Project Asset to it's owner.
        if (assetAddresstoProjectOwner[_tokenAddress] == address(0)) {
            assetAddresstoProjectOwner[_tokenAddress] = _caller;
        }

        emit ProjectInfo(
            _tokenAddress,
            ERC20Properties(_tokenAddress).symbol(),
            assetAddresstoProjectOwner[_tokenAddress],
            ERC20Properties(_tokenAddress).decimals()
        );

        // Minting wrapped tokens by iterating on the vesting sheet
        for (i = 0; i < _distTime.length; i++) {
            _distTime[i] = (_distTime[i] / DAY) * DAY;

            require(
                _distTime[i] > ((block.timestamp / DAY) * DAY),
                "Not a future Vest End Time"
            );
            // Checking if the distribution of tokens is in consistent with the total amount of tokens.
            totalAmount += _distAmount[i];

            address _wrappedTokenAdr;
            if (_transferable[i]) {
                _wrappedTokenAdr = assetToDerivativeMap[_tokenAddress][
                    _distTime[i]
                ].sellable;
            } else {
                _wrappedTokenAdr = assetToDerivativeMap[_tokenAddress][
                    _distTime[i]
                ].nonsellable;
            }
            string memory _wrappedTokenTicker = "";
            if (_wrappedTokenAdr == address(0)) {
                //function call to deploy new ERC20 derivative
                lastVestID += 1;
                require(_limitOfDerivatives > 0, "Derivative limit exhausted");
                _limitOfDerivatives -= 1;
                (_wrappedTokenAdr, _wrappedTokenTicker) = _deployNewERC20(
                    _tokenAddress,
                    _distTime[i],
                    _transferable[i]
                );

                //update mapping
                _updateMappings(
                    _wrappedTokenAdr,
                    _tokenAddress,
                    _distTime[i],
                    _transferable[i]
                );
            } else {
                _wrappedTokenTicker = ERC20Properties(_wrappedTokenAdr).symbol();
            }
            assert(
                _mintWrappedTokens(
                    _tokenAddress,
                    _distAddress[i],
                    _distAmount[i],
                    _wrappedTokenAdr
                )
            );

            totalDerivativeForAsset[_tokenAddress] += _distAmount[i];

            emit CreateVest(
                _tokenAddress,
                assetAddresstoProjectOwner[_tokenAddress],
                _distAddress[i],
                _distAmount[i],
                _distTime[i],
                _wrappedTokenAdr,
                _wrappedTokenTicker,
                _transferable[i]
            );
        }

        require(totalAmount == _amount, "Inconsistent amount of tokens");
        assert(
            IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) >=
                totalDerivativeForAsset[_tokenAddress]
        );
    }

    /// @notice Helper function to update the mappings.
    /// @dev Updates the global state variables.
    /// @param _wrappedTokenAdr Address of the WVT to be updated.
    /// @param _tokenAddress Address of the Project Token of which the WVT is created.
    /// @param _vestTime Time of unlock of the project token.
    /// @param _transferable Boolean to determine if this asset is sellable or not.
    function _updateMappings(
        address _wrappedTokenAdr,
        address _tokenAddress,
        uint256 _vestTime,
        bool _transferable
    ) internal {
        derivativeIDtoAddress[lastVestID] = _wrappedTokenAdr;

        if (_transferable) {
            assetToDerivativeMap[_tokenAddress][_vestTime]
                .sellable = _wrappedTokenAdr;
        } else {
            assetToDerivativeMap[_tokenAddress][_vestTime]
                .nonsellable = _wrappedTokenAdr;
        }

        vestingTimeOfTokenId[_wrappedTokenAdr] = _vestTime;

        derivativeAdrToActualAssetAdr[_wrappedTokenAdr] = _tokenAddress;
    }

    /// @notice Helper function to transfer the corresponding token.
    /// @dev Uses the IERC20Upgradable to transfer the asset from one user to another.
    /// @param _tokenAddress The asset of which the transfer is to take place.
    /// @param _from The address from which the asset is being transfered.
    /// @param _to The address to whom the asset is being transfered.
    /// @param _amount The quantity of the asset being transfered.
    function _safeTransferERC20(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // transfering ERC20 tokens from _projectOwner (msg.sender) to contract
        if (_from == address(this)) {
            IERC20Upgradeable(_tokenAddress).safeTransfer(_to, _amount);
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransferFrom(
                _from,
                _to,
                _amount
            );
        }
    }

    /// @notice Function called by createBulkDerivative to spawn new cheap copies which make delegate call to ERC20 Model Contract
    /// @dev Uses the AbsERC20Factory interface object to call createStorage method of the factory contract
    /// @param _tokenAddress Token address for which a WVT is being created
    /// @param _vestTime The timestamp after which the token deployed can be exchanged for the project token
    /// @param _transferable The new deployed ERC20 is sellable or not
    /// @return Returns a tupple of address which contains the address of newly deployed ERC20 contract and its token ticker
    function _deployNewERC20(
        address _tokenAddress,
        uint256 _vestTime,
        bool _transferable
    ) internal virtual returns (address, string memory) {
        // Getting ERC20 token information
        string memory date = _timestampToDate(_vestTime);

        address currentContractAddress;
        string memory _wrappedTokenTicker;
        if (_transferable) {
            _wrappedTokenTicker = string(
                abi.encodePacked(
                    ERC20Properties(_tokenAddress).symbol(),
                    ".",
                    date
                    
                )
            );
            string memory wrappedTokenName = string(
                abi.encodePacked(
                    ERC20Properties(_tokenAddress).name(),
                    ".",
                    date
                )
            );
            uint8 wrappedTokenDecimals = ERC20Properties(_tokenAddress)
                .decimals();

            currentContractAddress = AbsERC20Factory(
                Master(masterContract).getFactory()
            ).createStorage(
                    wrappedTokenName,
                    _wrappedTokenTicker,
                    wrappedTokenDecimals,
                    0
                );
        } else {
            _wrappedTokenTicker = string(
                abi.encodePacked(
                    ERC20Properties(_tokenAddress).symbol(),
                    ".",
                   date,
                    "-NT"
                )
            );
            string memory wrappedTokenName = string(
                abi.encodePacked(
                    ERC20Properties(_tokenAddress).name(),
                    ".",
                    date,
                    "-NT"
                )
            );
            uint8 wrappedTokenDecimals = ERC20Properties(_tokenAddress)
                .decimals();

            currentContractAddress = AbsERC20Factory(
                Master(masterContract).getFactory()
            ).createStorage(
                    wrappedTokenName,
                    _wrappedTokenTicker,
                    wrappedTokenDecimals,
                    _vestTime
                );
        }

        // Creating new Wrapped ERC20 asset

        return (currentContractAddress, _wrappedTokenTicker);
    }

    /// @notice Function called by createBulkDerivative to mint new Derived tokens.
    /// @dev Uses the ERC20Clone interface object to instruct derived asset to mint new tokens.
    /// @param _tokenAddress Token address for which a WVT is being minted
    /// @param _distributionAddress The address to whom derived token is to be minted.
    /// @param _distributionAmount The amount of derived assets to be minted.
    /// @param _wrappedTokenAddress The address of the derived asset which is to be minted.
    function _mintWrappedTokens(
        address _tokenAddress,
        address _distributionAddress,
        uint256 _distributionAmount,
        address _wrappedTokenAddress
    ) internal virtual returns (bool _flag) {
        assetLockedForDerivative[_tokenAddress][
            _wrappedTokenAddress
        ] += _distributionAmount;

        // Minting Wrapped ERC20 token
        ERC20Clone(_wrappedTokenAddress).mintbyControl(
            _distributionAddress,
            _distributionAmount
        );
        _flag = (IERC20Upgradeable(_wrappedTokenAddress).totalSupply() ==
            assetLockedForDerivative[_tokenAddress][_wrappedTokenAddress]);
    }

    /// @notice Function called by derived asset contract when they are transferred.
    /// @param _from The address from which the token is being transferred.
    /// @param _to The address to which the token is being transferred.
    /// @param _amount The amount of tokens being transferred.
    function tokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external virtual {
        // This function can only be called by wrapped ERC20 token contract which are created by the controller
        require(derivativeAdrToActualAssetAdr[msg.sender] != address(0));
        emit TransferWrapped(_from, msg.sender, _to, _amount);
    }

    /// @notice Using this function a user can withdraw vested tokens in return of derived tokens held by the user address after the vest time has passed
    /// @dev This function burns the derived erc20 tokens and then transfers the project tokens to the msg.sender
    /// @param _wrappedTokenAddress Takes the address of the derived token
    /// @param _amount The amount of derived tokens the user want to withdraw
    /// @param _caller Address calling this function through controller
    function withdrawToken(
        address _wrappedTokenAddress,
        uint256 _amount,
        address _caller
    ) external virtual noReentrant {
        require(msg.sender == masterContract, "Only master can call");
        isKilled();

        require(
            derivativeAdrToActualAssetAdr[_wrappedTokenAddress] != address(0)
        );

        require(
            vestingTimeOfTokenId[_wrappedTokenAddress] <= block.timestamp,
            "Cannot withdraw before vest time"
        );

        address _tokenAddress = derivativeAdrToActualAssetAdr[
            _wrappedTokenAddress
        ];

        //Transfer the Wrapped Token to the controller first.
        _safeTransferERC20(
            _wrappedTokenAddress,
            _caller,
            address(this),
            _amount
        );

        totalDerivativeForAsset[_tokenAddress] -= _amount;

        // Burning wrapped tokens
        ERC20Clone(_wrappedTokenAddress).burnbyControl(address(this), _amount);

        assetLockedForDerivative[_tokenAddress][
            _wrappedTokenAddress
        ] -= _amount;

        _safeTransferERC20(_tokenAddress, address(this), _caller, _amount);
        assert(
            IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) >=
                totalDerivativeForAsset[_tokenAddress]
        );

        emit Withdraw(_caller, _amount, _wrappedTokenAddress);
    }

    /// @notice This function is used by _deployNewERC20 function to set Ticker and Name of the derived asset.
    /// @dev This function uses the TimestampToDateLibrary.
    /// @param _timestamp tiemstamp which needs to be converted to date.
    /// @return finalDate as a string which the timestamp represents.
    function _timestampToDate(uint256 _timestamp)
        internal
        pure
        returns (string memory finalDate)
    {
        // Converting timestamp to Date using timestampToDateLibrary
        _timestamp = (_timestamp / DAY) * DAY;
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = TimestampToDateLibrary.timestampToDate(_timestamp);
        string memory mstring;

        // Converting month component to String
        if (month == 1) mstring = "Jan";
        else if (month == 2) mstring = "Feb";
        else if (month == 3) mstring = "Mar";
        else if (month == 4) mstring = "Apr";
        else if (month == 5) mstring = "May";
        else if (month == 6) mstring = "Jun";
        else if (month == 7) mstring = "Jul";
        else if (month == 8) mstring = "Aug";
        else if (month == 9) mstring = "Sep";
        else if (month == 10) mstring = "Oct";
        else if (month == 11) mstring = "Nov";
        else if (month == 12) mstring = "Dec";

        // Putting data on finalDate
        finalDate = string(
            abi.encodePacked(_uint2str(day), mstring, _uint2str(year))
        );
    }

    /// @notice This function is used by _timestampToDate function to convert number to string.
    /// @param _i an integer.
    /// @return str which is _i as string.
    function _uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }
}