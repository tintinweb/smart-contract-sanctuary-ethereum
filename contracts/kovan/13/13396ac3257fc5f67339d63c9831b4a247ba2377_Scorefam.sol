/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
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
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }
}

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

    function __ERC1967Upgrade_init_unchained() internal initializer {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
        StorageSlotUpgradeable.BooleanSlot
            storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(
                _ROLLBACK_SLOT
            );
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(
                oldImplementation == _getImplementation(),
                "ERC1967Upgrade: upgrade breaks further upgrades"
            );
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            ),
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
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    uint256[50] private __gap;
}

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

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    uint256[50] private __gap;
}

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is
    Initializable,
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of BEP20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IBEP20Upgradeable
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __BEP20_init(string memory name_, string memory symbol_)
        internal
        initializer
    {
        __Context_init_unchained();
        __BEP20_init_unchained(name_, symbol_);
    }

    function __BEP20_init_unchained(string memory name_, string memory symbol_)
        internal
        initializer
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "BEP20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "BEP20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "BEP20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}

/**
 * @dev Extension of {BEP20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract BEP20BurnableUpgradeable is
    Initializable,
    ContextUpgradeable,
    BEP20Upgradeable
{
    function __BEP20Burnable_init() internal initializer {
        __Context_init_unchained();
        __BEP20Burnable_init_unchained();
    }

    function __BEP20Burnable_init_unchained() internal initializer {}

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {BEP20-_burn} and {BEP20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "BEP20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    uint256[50] private __gap;
}


interface IScorefamConsumer {
    function gameScoreRequestID(uint _fixtureID) external returns (bytes32);
    function requestIdData(bytes32 _requestId) external returns (bytes memory);
    function requestGameScore(bytes32 _jobId, uint256 _fixtureID) external returns (bytes32);
}



library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}


contract Scorefam is
    Initializable,
    BEP20Upgradeable,
    BEP20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using BytesLib for bytes;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    event PlayedGame(
        address sender,
        uint256 amount,
        uint256 fixtureID,
        uint256 outcomeID
    );
    event PlayedSlip(
        address sender,
        uint256 amount,
        uint256 gameType
    );
    event Claimed(address sender, uint256 amount);


    struct GameType {
        uint256 gameTypeStakedPool;
        uint256 gameLockTime;
    }
    //Define the Three Game Types: 1 = Flexible; 2 = Multi-Flex; 3 = Locked
    //Mapping the GameTypes with their properties
    mapping(uint256 => GameType) private _gameTypeOptions;

    //Total Staked Tokens
    uint256 public _totalStakedSupply;


    //Game Stake Details
    struct Game {
        uint256 amount; // Amount staked
        uint256 fixtureID; // Unique fixtureID
        uint256 outcomeType; // The Predicted Winning Outcome
        uint256 oddPoint; // The point to multiply reward with.
        uint256 gameType; // GameType defining the type of Game
        uint256 gameStartTime; // Fixture StartTime
        bool    gameActive; // Tracks whether a stake is still active
    }
    //Each game owned by an address
    //Mapping <PlayerAddress, GameCount> <IndividualGame>
    mapping(address => mapping(uint256 => Game)) private _gaming;


    //For Flexible and Multi-Flex Games
    struct SlipCut {
        uint256 fixtureID; // Unique fixtureID
        uint256 outcomeType; // The Predicted Winning Outcome
        uint256 gameStartTime; // Fixture StartTime
    }
    struct Slip {
        SlipCut[] slips;
        uint256 amount; // Amount staked
        uint256 oddPoint; // The point to multiply reward with.
        uint256 gameType; // GameType defining the type of Game
        bool    gameActive; // Tracks whether a stake is still active
    }

    // Mapping <PlayerAddress, SlipCount> <GameSlip>
    mapping(address => mapping(uint256 => Slip)) private _gamingSlip;


    //Number of games staked by an address
    mapping(address => uint256) public _gamesCount;
    //Number of slips staked by an address
    mapping(address => uint256) public _slipsCount;

    //Amount of claimed rewards a user has.
    mapping(address => uint256) public _totalAmountClaimed;

    //Number of claimed games a user has.
    mapping(address => uint256) public _totalGamesClaimed;
    
    //Address that holds fees from withdrawals
    address private fee;
    //Consumer Oracle Address
    address private consumer;
    

    //Deployment Time
    uint256 private _deploymentTime;

    //Mapping a FixtureID to its Result status.
    struct GameResult {
        bytes  status;
        uint256  homeScore;
        uint256  awayScore;
        bool retrieved;
    }
    mapping(uint256 => GameResult) public gameResult;


    bytes32 requestScore;



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __BEP20_init("Scorefam", "SFT");
        __BEP20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        //Setting up different address roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        //Game Type Options
        //Flexible Game Type
        _gameTypeOptions[1].gameTypeStakedPool = 0;
        _gameTypeOptions[1].gameLockTime = 120 minutes;

        //Multi-Flex Game Type
        _gameTypeOptions[2].gameTypeStakedPool = 0;
        _gameTypeOptions[2].gameLockTime = 120 minutes;

        //Locked Game Type
        _gameTypeOptions[3].gameTypeStakedPool = 0;
        _gameTypeOptions[3].gameLockTime = 120 minutes;


        _totalStakedSupply = 0;
        _deploymentTime = block.timestamp;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function setFeeAddress(address _fee) public onlyRole(MINTER_ROLE) {
        fee = _fee;
    }

    function setConsumerAddress(address _consumer) public onlyRole(MINTER_ROLE) {
        consumer = _consumer;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    
    /* Set the token contract for which to call for the stake reward
     *
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply().add(_totalStakedSupply);
    }

    /* Get available tokens
     *
     */
    function getMyBalance() external view returns (uint256) {
        return balanceOf(_msgSender());
    }

    /* Get all tokens including staked
     *
     */
    function getMyFullBalance() external view returns (uint256) {
        uint256 balance = balanceOf(_msgSender());
        for (uint256 i = 1; i <= _gamesCount[_msgSender()]; i++) {
            balance += _gaming[_msgSender()][i].amount;
        }
        return balance;
    }


    function getGameRemainingLockTime(uint256 game_) external view returns(uint256) {
        return block.timestamp.sub(_gaming[_msgSender()][game_].gameStartTime.add(
            _gameTypeOptions[_gaming[_msgSender()][game_].gameType].gameLockTime));
    }

    //Fetch Stake History
    /* Get all locked game stakes an address holds
     */
    function getGames() external view returns (uint256[7][] memory) {
        uint256[7][] memory tempStakeList = new uint256[7][](_gamesCount[_msgSender()] + 1);
        for (uint256 i = 1; i <= _gamesCount[_msgSender()]; i++) {
            tempStakeList[i][0] = _gaming[_msgSender()][i].amount;
            tempStakeList[i][1] = _gaming[_msgSender()][i].fixtureID;
            tempStakeList[i][2] = _gaming[_msgSender()][i].outcomeType;
            tempStakeList[i][3] = _gaming[_msgSender()][i].gameType;
            tempStakeList[i][4] = _gaming[_msgSender()][i].gameStartTime;
            tempStakeList[i][5] = calculateGameReward(i);
            tempStakeList[i][6] = _gaming[_msgSender()][i].gameActive ? 0 : 1;
        }
        return tempStakeList;
    }

    /* Get all slips a address holds
     */
    function getSlipCut() external view returns (SlipCut[] memory) {
            SlipCut[] memory temp;
            for (uint256 i = 1; i <= _slipsCount[_msgSender()]; i++) {
                temp = _gamingSlip[_msgSender()][i].slips;
            }
            return temp;
    }


    function getSlips() external view returns (uint256[5][] memory) {
        uint256[5][] memory temp = new uint256[5][](_slipsCount[_msgSender()] + 1);

        for (uint256 i = 1; i <= _slipsCount[_msgSender()]; i++) {
            temp[i][0] = _gamingSlip[_msgSender()][i].amount;
            temp[i][1] = _gamingSlip[_msgSender()][i].oddPoint;
            temp[i][2] = _gamingSlip[_msgSender()][i].gameType;
            temp[i][3] = calculateSlipReward(i);
            temp[i][4] = _gamingSlip[_msgSender()][i].gameActive ? 0 : 1;
        }
        return temp;
    }
   



    /* Calculates the halved reward of a staking.
     */
    function getHalvedReward(uint256 _amount) internal view returns (uint256) {
        uint256 reward;

        if (block.timestamp <= _deploymentTime + 26 weeks) {
            if(_amount < 74900000000){
                reward = 5;
            } else if(_amount >= 75000000000 && _amount < 149900000000){
                reward = 10;
            } else if(_amount >= 150000000000 && _amount < 249900000000){
                reward = 15;
            } else if(_amount >= 250000000000){
                reward = 20;
            } else {
                reward = 0;
            }
        } 
        else if (
            (block.timestamp > _deploymentTime + 26 weeks) &&
            (block.timestamp <= _deploymentTime + 78 weeks)
        ) {
            //first halvening in 6months
            if(_amount < 74900000000){
                reward = 3;
            } else if(_amount >= 75000000000 && _amount < 149900000000){
                reward = 6;
            } else if(_amount >= 150000000000 && _amount < 249900000000){
                reward = 9;
            } else if(_amount >= 250000000000){
                reward = 12;
            } else {
                reward = 0;
            }
        } 
        else if (
            (block.timestamp > _deploymentTime + 78 weeks) &&
            (block.timestamp <= _deploymentTime + 130 weeks)
        ) {
            //second halvening in 18months
            if(_amount < 74900000000){
                reward = 2;
            } else if(_amount >= 75000000000 && _amount < 149900000000){
                reward = 4;
            } else if(_amount >= 150000000000 && _amount < 249900000000){
                reward = 6;
            } else if(_amount >= 250000000000){
                reward = 8;
            } else {
                reward = 0;
            }
        } 
        else if (
            (block.timestamp > _deploymentTime + 130 weeks) &&
            (block.timestamp <= _deploymentTime + 182 weeks)
        ) {
            //third halvening in 30months
            if(_amount < 74900000000){
                reward = 4;
            } else if(_amount >= 75000000000 && _amount < 149900000000){
                reward = 8;
            } else if(_amount >= 150000000000 && _amount < 249900000000){
                reward = 11;
            } else if(_amount >= 250000000000){
                reward = 15;
            } else {
                reward = 0;
            }
        } 
        else if (
            (block.timestamp > _deploymentTime + 182 weeks) &&
            (block.timestamp <= _deploymentTime + 234 weeks)
        ) { 
            //fourth halvening in 42months
            if(_amount < 74900000000){
                reward = 2;
            } else if(_amount >= 75000000000 && _amount < 149900000000){
                reward = 4;
            } else if(_amount >= 150000000000 && _amount < 249900000000){
                reward = 6;
            } else if(_amount >= 250000000000){
                reward = 9;
            } else {
                reward = 0;
            }
        } 
        else if (block.timestamp > _deploymentTime + 234 weeks) {
            //fifth halvening in 54months
            if(_amount < 74900000000){
                reward = 2;
            } else if(_amount >= 75000000000 && _amount < 149900000000){
                reward = 3;
            } else if(_amount >= 150000000000 && _amount < 249900000000){
                reward = 4;
            } else if(_amount >= 250000000000){
                reward = 5;
            } else {
                reward = 0;
            }
        }  
        else {
            reward = 0;
        }

        return reward;
    }




    /* Calculates the Daily Reward of the of a particular stake
     *
     */
    function calculateGameReward(uint256 game_)
        internal
        view
        returns (uint256)
    {
        uint256 gameType = _gaming[_msgSender()][game_].gameType;
        uint256 amount = _gaming[_msgSender()][game_].amount;

        uint256 reward;

        //LOCKED Game Type(HOME: 1; DRAW: 2; AWAY: 3)
        require(gameType == 3, "Scorefam: Invalid Game Type");
            //Base
            uint256 outcomeType = _gaming[_msgSender()][game_].outcomeType;
            uint256  homeScore = gameResult[_gaming[_msgSender()][game_].fixtureID].homeScore;
            uint256  awayScore = gameResult[_gaming[_msgSender()][game_].fixtureID].awayScore;
            if ( 
                ( (outcomeType == 1 && (homeScore > awayScore)) || 
                (outcomeType == 2 && (homeScore == awayScore)) ||
                (outcomeType == 3 && (homeScore < awayScore)) ) && (amount < 74900000000) ) 
            {
                reward = (getHalvedReward(amount).mul(amount).div(100)).add(amount);
            } 
            //Bronze
            else if (
                ( (outcomeType == 1 && (homeScore > awayScore)) || 
                (outcomeType == 2 && (homeScore == awayScore)) ||
                (outcomeType == 3 && (homeScore < awayScore)) ) && (amount >= 75000000000 && amount < 149900000000) ) 
            {
                reward = (getHalvedReward(amount).mul(amount).div(100)).add(amount);
            }
            //Gold
            else if (
                ( (outcomeType == 1 && (homeScore > awayScore)) || 
                (outcomeType == 2 && (homeScore == awayScore)) ||
                (outcomeType == 3 && (homeScore < awayScore)) ) && (amount >= 150000000000 && amount < 249900000000) ) 
            {
                reward = (getHalvedReward(amount).mul(amount).div(100)).add(amount);
            }
            //VIP
            else if (
                ( (outcomeType == 1 && (homeScore > awayScore)) || 
                (outcomeType == 2 && (homeScore == awayScore)) ||
                (outcomeType == 3 && (homeScore < awayScore)) ) && (amount >= 250000000000) ) 
            {
                reward = (getHalvedReward(amount).mul(amount).div(100)).add(amount);
            }
            else {
                reward = amount;
            }

        return reward;
    }


    function calculateSlipReward(uint256 game_)
        internal
        view
        returns (uint256)
    { 

        uint256 gameType = _gamingSlip[_msgSender()][game_].gameType;
        require(gameType == 1 || gameType == 2, "Scorefam: Invalid Game Type");
        uint256 amount = _gamingSlip[_msgSender()][game_].amount;
        uint256 oddPoint = _gamingSlip[_msgSender()][game_].oddPoint;
        uint256 reward;

         // Outcome Types {
            // home: 1; draw: 2; away: 3; 
            
            // bts: 4; odd: 5; even: 6;

            // over1: 7; under1: 8; 
            // over2: 9; under2: 10;
            // over3: 11; under3: 12;
            // over4: 13; under4: 14;
            // over5: 15; under5: 16;    
            
            // ng0: 17; ng1: 18; ng2: 19;
            // ng3: 20; ng4: 21; ng5: 22;
            // ng6: 23; ng7: 24; ng8: 25;
            // ng9: 26; ng10: 27;
        // }

        // FLEXIBLE Game Type
        if (gameType == 1) {

            for(uint256 i = 0; i < _gamingSlip[_msgSender()][game_].slips.length; i++ ){
                uint256 outcomeType = _gamingSlip[_msgSender()][game_].slips[i].outcomeType;
                uint256  homeScore = gameResult[_gamingSlip[_msgSender()][game_].slips[i].fixtureID].homeScore;
                uint256  awayScore = gameResult[_gamingSlip[_msgSender()][game_].slips[i].fixtureID].awayScore;

                //Reward Winners Flexibly
                if( ( outcomeType == 1 && (homeScore > awayScore) ) ){
                    continue;
                } else if( ( outcomeType == 2 && (homeScore == awayScore) ) ){
                    continue;
                }
                else if( ( outcomeType == 3 && (homeScore < awayScore) ) ){
                    continue;
                }
                else if( ( outcomeType == 4 && (homeScore > 0 && awayScore > 0) ) ){
                    continue;
                }
                else if( ( outcomeType == 5 && ((homeScore + awayScore) % 2) != 0 )  ){
                    continue;
                }
                else if( ( outcomeType == 6 && ((homeScore + awayScore) % 2) == 0 )  ){
                    continue;
                }
                else if( ( outcomeType == 7 && (homeScore + awayScore) > 1 )  ){
                    continue;
                }
                else if( ( outcomeType == 8 && (homeScore + awayScore) < 2 )  ){
                    continue;
                }
                else if( ( outcomeType == 9 && (homeScore + awayScore) > 2 )  ){
                    continue;
                }
                else if( ( outcomeType == 10 && (homeScore + awayScore) < 3 )  ){
                    continue;
                }
                else if( ( outcomeType == 11 && (homeScore + awayScore) > 3 )  ){
                    continue;
                }
                else if( ( outcomeType == 12 && (homeScore + awayScore) < 4 )  ){
                    continue;
                }
                else if( ( outcomeType == 13 && (homeScore + awayScore) > 4 )  ){
                    continue;
                }
                else if( ( outcomeType == 14 && (homeScore + awayScore) < 5 )  ){
                    continue;
                }
                else if( ( outcomeType == 15 && (homeScore + awayScore) > 5 )  ){
                    continue;
                }
                else if( ( outcomeType == 16 && (homeScore + awayScore) < 6 )  ){
                    continue;
                }
                else if( ( outcomeType == 17 && (homeScore + awayScore) == 0 )  ){
                    continue;
                }
                else if( ( outcomeType == 18 && (homeScore + awayScore) == 1 )  ){
                    continue;
                }
                else if( ( outcomeType == 19 && (homeScore + awayScore) == 2 )  ){
                    continue;
                }
                else if( ( outcomeType == 20 && (homeScore + awayScore) == 3 )  ){
                    continue;
                }
                else if( ( outcomeType == 21 && (homeScore + awayScore) == 4 )  ){
                    continue;
                }
                else if( ( outcomeType == 22 && (homeScore + awayScore) == 5 )  ){
                    continue;
                }
                else if( ( outcomeType == 23 && (homeScore + awayScore) == 6 )  ){
                    continue;
                }
                else if( ( outcomeType == 24 && (homeScore + awayScore) == 7 )  ){
                    continue;
                }
                else if( ( outcomeType == 25 && (homeScore + awayScore) == 8 )  ){
                    continue;
                }
                else if( ( outcomeType == 26 && (homeScore + awayScore) == 9 )  ){
                    continue;
                }
                else if( ( outcomeType == 27 && (homeScore + awayScore) == 10 )  ){
                    continue;
                }
                //Compensate Other Winners Flexibly
                else {
                    reward = (2 * amount).div(10);
                    break;
                }
            }//For Loop
            
            reward = amount.mul(oddPoint); 
        }

        // MULTI-FLEX Game Type
        else if (gameType == 2) {

            for(uint256 i = 0; i < _gamingSlip[_msgSender()][game_].slips.length; i++ ){
                uint256 outcomeType = _gamingSlip[_msgSender()][game_].slips[i].outcomeType;
                uint256  homeScore = gameResult[_gamingSlip[_msgSender()][game_].slips[i].fixtureID].homeScore;
                uint256  awayScore = gameResult[_gamingSlip[_msgSender()][game_].slips[i].fixtureID].awayScore;
                //Reward Winners Flexibly
                 if( ( outcomeType == 1 && (homeScore > awayScore) ) ){
                    continue;
                } else if( ( outcomeType == 2 && (homeScore == awayScore) ) ){
                    continue;
                }
                else if( ( outcomeType == 3 && (homeScore < awayScore) ) ){
                    continue;
                }
                else if( ( outcomeType == 4 && (homeScore > 0 && awayScore > 0) ) ){
                    continue;
                }
                else if( ( outcomeType == 5 && ((homeScore + awayScore) % 2) != 0 )  ){
                    continue;
                }
                else if( ( outcomeType == 6 && ((homeScore + awayScore) % 2) == 0 )  ){
                    continue;
                }
                else if( ( outcomeType == 7 && (homeScore + awayScore) > 1 )  ){
                    continue;
                }
                else if( ( outcomeType == 8 && (homeScore + awayScore) < 2 )  ){
                    continue;
                }
                else if( ( outcomeType == 9 && (homeScore + awayScore) > 2 )  ){
                    continue;
                }
                else if( ( outcomeType == 10 && (homeScore + awayScore) < 3 )  ){
                    continue;
                }
                else if( ( outcomeType == 11 && (homeScore + awayScore) > 3 )  ){
                    continue;
                }
                else if( ( outcomeType == 12 && (homeScore + awayScore) < 4 )  ){
                    continue;
                }
                else if( ( outcomeType == 13 && (homeScore + awayScore) > 4 )  ){
                    continue;
                }
                else if( ( outcomeType == 14 && (homeScore + awayScore) < 5 )  ){
                    continue;
                }
                else if( ( outcomeType == 15 && (homeScore + awayScore) > 5 )  ){
                    continue;
                }
                else if( ( outcomeType == 16 && (homeScore + awayScore) < 6 )  ){
                    continue;
                }
                else if( ( outcomeType == 17 && (homeScore + awayScore) == 0 )  ){
                    continue;
                }
                else if( ( outcomeType == 18 && (homeScore + awayScore) == 1 )  ){
                    continue;
                }
                else if( ( outcomeType == 19 && (homeScore + awayScore) == 2 )  ){
                    continue;
                }
                else if( ( outcomeType == 20 && (homeScore + awayScore) == 3 )  ){
                    continue;
                }
                else if( ( outcomeType == 21 && (homeScore + awayScore) == 4 )  ){
                    continue;
                }
                else if( ( outcomeType == 22 && (homeScore + awayScore) == 5 )  ){
                    continue;
                }
                else if( ( outcomeType == 23 && (homeScore + awayScore) == 6 )  ){
                    continue;
                }
                else if( ( outcomeType == 24 && (homeScore + awayScore) == 7 )  ){
                    continue;
                }
                else if( ( outcomeType == 25 && (homeScore + awayScore) == 8 )  ){
                    continue;
                }
                else if( ( outcomeType == 26 && (homeScore + awayScore) == 9 )  ){
                    continue;
                }
                else if( ( outcomeType == 27 && (homeScore + awayScore) == 10 )  ){
                    continue;
                }
                //Compensate Other Winners Flexibly
                else {
                    reward = 0;
                    break;
                }
            }//For Loop
                
            reward = amount.mul(oddPoint); 
        }

        else {
            return 0;
        }

        return reward;

    }





    /* STAKE */
    function playGame(
        uint256 amount_,
        uint256 fixtureID_,
        uint256 outcomeType_,
        uint256 oddPoint_,
        uint256 gameType_,
        uint256 gameStartTime_
    ) external returns (bool){
        require(gameType_ == 3,"Scorefam: Incorrect Game Type");
        require(amount_ > 0, "Scorefam: No Stake Amount Provided");
        require(fixtureID_ > 0, "Scorefam: Invalid Fixture ID");
        require(block.timestamp < gameStartTime_, "Scorefam: Game Already Started");        
        require(outcomeType_ > 0 && outcomeType_ < 17, "Scorefam: Invalid Outcome Type");
        
        _burn(_msgSender(), amount_);
        _totalStakedSupply += amount_;

        Game memory temp;
        temp.amount = amount_;
        temp.fixtureID = fixtureID_;
        temp.outcomeType = outcomeType_;
        temp.oddPoint = oddPoint_;
        temp.gameStartTime = gameStartTime_;
        temp.gameType = gameType_;
        temp.gameActive = true;
        _gamesCount[_msgSender()]++;
        _gaming[_msgSender()][_gamesCount[_msgSender()]] = temp;

        _gameTypeOptions[gameType_].gameTypeStakedPool += amount_;
        emit PlayedGame(_msgSender(), amount_, fixtureID_, outcomeType_);

        return true;
    }


    function playSlip(SlipCut[] memory _slipCuts, uint256 amount_, uint256 gameType_, uint256 oddPoint_) external returns (bool) {
        require(amount_ > 0, "Scorefam: No Stake Amount Provided");
        require(gameType_ == 1 || gameType_ == 2, "Scorefam: Incorrect Game Type");
        require(oddPoint_ > 0, "Scorefam: Invalid Odd Point");

        //Flexible Game
        if(gameType_ == 1){
            require(_slipCuts.length <= 3, "Scorefam: Max games exceeded");
            _slipsCount[_msgSender()]++;

            Slip storage temp = _gamingSlip[_msgSender()][_slipsCount[_msgSender()]];

            for(uint256 i = 0; i < _slipCuts.length; i++){
                require(_slipCuts[i].gameStartTime > 0 && block.timestamp < _slipCuts[i].gameStartTime, "Scorefam: Game Already Started"); 
                require(_slipCuts[i].fixtureID > 0, "Scorefam: Invalid Fixture ID");
                require(_slipCuts[i].outcomeType > 0 && _slipCuts[i].outcomeType < 17, "Scorefam: Invalid Outcome Type");
                
                temp.slips[i] = _slipCuts[i];
            }

                _burn(_msgSender(), amount_);
                _totalStakedSupply += amount_;

                temp.amount = amount_;
                temp.oddPoint = oddPoint_;
                temp.gameType = gameType_;
                temp.gameActive = true;


                _gameTypeOptions[gameType_].gameTypeStakedPool += amount_;
                emit PlayedSlip(_msgSender(), amount_, gameType_);


        } 
        //Multi-flex Game
        else if(gameType_ == 2) {
            require(_slipCuts.length <= 10, "Scorefam: Max games exceeded");
            _slipsCount[_msgSender()]++;
            Slip storage temp = _gamingSlip[_msgSender()][_slipsCount[_msgSender()]];
            
            for(uint256 i = 0; i < _slipCuts.length; i++){
                require(_slipCuts[i].gameStartTime > 0 && block.timestamp < _slipCuts[i].gameStartTime, "Scorefam: Game Already Started"); 
                require(_slipCuts[i].fixtureID > 0, "Scorefam: Invalid Fixture ID");
                require(_slipCuts[i].outcomeType > 0 && _slipCuts[i].outcomeType < 17, "Scorefam: Invalid Outcome Type");
                
                temp.slips[i] = _slipCuts[i];
            }

                _burn(_msgSender(), amount_);
                _totalStakedSupply += amount_;

                temp.amount = amount_;
                temp.oddPoint = oddPoint_;
                temp.gameType = gameType_;
                temp.gameActive = true;


                _gameTypeOptions[gameType_].gameTypeStakedPool += amount_;
                emit PlayedSlip(_msgSender(), amount_, gameType_);
        } 

        return true;
    }



  //Convert String to Uint
    function strToNum(string memory numString) internal pure returns(uint) {
        uint  val=0;
        bytes memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
    
    //Slice Bytes returned from Oracle
    function sliceBytes(uint256 _fixtureID, bytes memory _bytes) internal {
        uint256 bytesLen = _bytes.length;
        bytes memory status;
        uint256  homeScore;
        uint256  awayScore;
        status = _bytes.slice(2,8);
        if(bytesLen == 16){
            
            homeScore = strToNum(string(_bytes.slice(12,1)));
            awayScore = strToNum(string(_bytes.slice(14,1)));

            gameResult[_fixtureID] = GameResult(status, homeScore, awayScore, true);
        } else if(bytesLen == 17){
            if(_bytes.slice(13,1).equal(hex"2c")){

                homeScore = strToNum(string(_bytes.slice(12,1)));
                awayScore = strToNum(string(_bytes.slice(14,2)));

                gameResult[_fixtureID] = GameResult(status, homeScore, awayScore, true);
            } else {
       
                homeScore = strToNum(string(_bytes.slice(12,2)));
                awayScore = strToNum(string(_bytes.slice(15,1)));

                gameResult[_fixtureID] = GameResult(status, homeScore, awayScore, true);
            }
        } else if (bytesLen == 18) {
      
            homeScore = strToNum(string(_bytes.slice(12,2)));
            awayScore = strToNum(string(_bytes.slice(15,2)));

            gameResult[_fixtureID] = GameResult(status, homeScore, awayScore, true);
        }


      
    }


    



    //WITHDRAWALS
    /* Withdraw the staked reward delegated
     */

    function getGameScoreRequestID(uint256 fixtureID) public returns(bool){
        if(IScorefamConsumer(consumer).gameScoreRequestID(fixtureID).length == 0){
            return true;
        }
        else {
            return false;
        }
    }

    function updateGameScore(uint256 fixtureID) public {
        //Update Game Status, Home and Away Scores from the Oracle

        if(getGameScoreRequestID(fixtureID)){
            bytes32 JOB_ID = bytes32("7a1ade57c05f49f1bd5c25241acdb107");        
            IScorefamConsumer(consumer).requestGameScore(JOB_ID, fixtureID);
        }
    }


    function updateGameResult(uint256 fixtureID) public {
        IScorefamConsumer sc = IScorefamConsumer(consumer);
        sliceBytes(fixtureID, sc.requestIdData(sc.gameScoreRequestID(fixtureID)));
    }


    function claimGameReward(uint256 game_) external returns (bool){
        require(
            block.timestamp >
                (_gaming[_msgSender()][game_].gameStartTime +
                    _gameTypeOptions[_gaming[_msgSender()][game_].gameType]
                        .gameLockTime),
            "Scorefam: Reward not yet available"
        );
        require(
            _gaming[_msgSender()][game_].gameActive,
            "Scorefam: Game is no longer ACTIVE"
        );


        if(!gameResult[_gaming[_msgSender()][game_].fixtureID].retrieved){
            updateGameResult(_gaming[_msgSender()][game_].fixtureID);
        }
        
        require(gameResult[_gaming[_msgSender()][game_].fixtureID].retrieved, "Scorefam: Game Details Not Retrieved");
        require(gameResult[_gaming[_msgSender()][game_].fixtureID].status.equal(hex"66696e6973686564"), "Scorefam: Game Not Ended");
        uint256 amount_ = calculateGameReward(game_);
        uint256 onePercent = amount_.div(100);
        _totalStakedSupply -= amount_;
        _gameTypeOptions[_gaming[_msgSender()][game_].gameType]
            .gameTypeStakedPool -= amount_;
        _gaming[_msgSender()][game_].gameActive = false;
        _totalAmountClaimed[_msgSender()] += amount_;
        _totalGamesClaimed[_msgSender()]++;
        _mint(fee, onePercent); //Charging 1% Fee
        _mint(_msgSender(), amount_.sub(onePercent));
        emit Claimed(_msgSender(), amount_);

        return true;
    }





    function updateSlipScore(uint256 game_) internal {
        //Update Game Status, Home and Away Scores from the Oracle

        IScorefamConsumer sc = IScorefamConsumer(consumer);

        for(uint256 i = 0; i <= _slipsCount[_msgSender()]; i++){
            require(block.timestamp > (_gamingSlip[_msgSender()][game_].slips[i].gameStartTime + _gameTypeOptions[_gamingSlip[_msgSender()][game_].gameType].gameLockTime),
            "Scorefam: Reward not yet available");
            uint256 fixtureID = _gamingSlip[_msgSender()][game_].slips[i].fixtureID;
            //Update Game Status, Home and Away Scores from the Oracle
            if(!gameResult[fixtureID].retrieved && sc.gameScoreRequestID(fixtureID).length > 0){
                bytes32 JOB_ID = bytes32("7a1ade57c05f49f1bd5c25241acdb107");       
                sc.requestGameScore(JOB_ID, fixtureID);            
                sliceBytes(fixtureID, sc.requestIdData(sc.gameScoreRequestID(fixtureID)));
            } else {
                sliceBytes(fixtureID, sc.requestIdData(sc.gameScoreRequestID(fixtureID)));
            }
        }

    }

    function updateSlipResult(uint256 fixtureID) internal {
        IScorefamConsumer sc = IScorefamConsumer(consumer);
        sliceBytes(fixtureID, sc.requestIdData(sc.gameScoreRequestID(fixtureID)));
    }
    
    function claimSlipReward(uint256 game_) external returns (bool){
        require(_gamingSlip[_msgSender()][game_].gameActive,"Scorefam: Game is no longer ACTIVE");

        
        updateSlipResult(game_);
        require(gameResult[_gaming[_msgSender()][game_].fixtureID].retrieved, "Scorefam: Game Details Not Retrieved");
        require(gameResult[_gaming[_msgSender()][game_].fixtureID].status.equal(hex"66696e6973686564"), "Scorefam: Game Not Ended");
        uint256 amount_ = calculateGameReward(game_);
        uint256 onePercent = amount_.div(100);
        _totalStakedSupply -= amount_;
        _gameTypeOptions[_gamingSlip[_msgSender()][game_].gameType].gameTypeStakedPool -= amount_;
        _gamingSlip[_msgSender()][game_].gameActive = false;
        _totalAmountClaimed[_msgSender()] += amount_;
        _totalGamesClaimed[_msgSender()]++;
        _mint(fee, onePercent); //Charging 1% Fee
        _mint(_msgSender(), amount_.sub(onePercent));
        emit Claimed(_msgSender(), amount_);

        return true;
    }



}