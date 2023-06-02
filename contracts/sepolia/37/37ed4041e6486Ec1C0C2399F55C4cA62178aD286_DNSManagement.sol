/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



interface IDNSManagement {
    //注册结构所有者，域名名称，到期时间，域名层级，父域名
    struct Record {
        address owner;
        string name;
        uint64 ttl;
        Level level;
        bytes32 parent;
    }

    //顶级域名结构：所有者，域名名称，顶级域名类别
    struct TopLevelDomain {
        TopLevelDomainCategory category;
        bool isOpen;
        bytes32 domainByte;
    }

    struct SubDomains {
        bytes32[] subDomainList;
        // @dev index start 1, use 0 to judge whether func exists.
        mapping(bytes32 => uint256) index;
    }

    enum Level {
        TopLevelDomain,
        FirstLevelDomain,
        SubLevelDomain
    }

    enum TopLevelDomainCategory {
        Business,
        Executive
    }

    event SetOperator(address indexed sender, address operator, bool isTrue);

    event SetTopLevelDomains(
        address indexed sender,
        string domain,
        address owner,
        bool isOpen,
        TopLevelDomainCategory category
    );

    event SetTopLevelDomainsOperate(
        address indexed sender,
        address platformManager,
        bool isOperate
    );
    event SetFirstDomainRecordBatch(
        address indexed sender,
        string[] labels,
        address[] owners,
        uint64[] ttls
    );

    event SetDomainSpecificParser(
        address indexed sender,
        string domain,
        uint256[] chainCodes,
        bytes[] resolvers
    );

    event SetDomainChainAdmin(
        address indexed sender,
        string domain,
        bytes[] admins,
        uint256[] chainCodes
    );

    event SetSubDomainRecordBatch(
        address indexed sender,
        string[] parentDomains,
        string[] labels,
        address[] owners
    );
    event SyncRecord(
        address indexed sender,
        string parentDomain,
        string label,
        address owner,
        uint256 chainCode,
        bytes resolver,
        uint64 ttl,
        bytes admin
    );

    // event SyncRecordBatch(
    //     address indexed sender,
    //     string[] parentDomains,
    //     string[] labels,
    //     address[] owners,
    //     uint256[] chainCodes,
    //     bytes[] resolvers,
    //     uint64[] ttls,
    //     bytes[] admins
    // );

    event SetOwner(
        address indexed sender,
        string domain,
        address newOwner,
        bool isClear
    );

    event SetTTL(address indexed sender, string domain, uint64 ttl);

    event EnterBlacklist(address indexed sender, string domain);

    event ExitBlacklist(address indexed sender, string domain);

    event Burn(address indexed sender, string domain);

    event SetOpenOwnerPower(address indexed sender, bool isOpen);

    function setOperator(address operator, bool isTrue) external;

    function isOperator(address account) external view returns (bool);

    function setTopLevelDomains(
        string calldata domain,
        address owner,
        bool isOpen,
        TopLevelDomainCategory category
    ) external;

    function getTopLevelDomainsInfo()
        external
        view
        returns (string memory domain, address owner, bool isOpen);

    function setTopLevelDomainsOperate(
        address platformManager,
        bool isOperate
    ) external;

    function isTopLevelDomainsOperate(
        address platformManager
    ) external view returns (bool);

    function setFirstDomainRecordBatch(
        string[] calldata labels,
        address[] calldata owners,
        uint64[] calldata ttls
    ) external;

    function setDomainSpecificParser(
        string calldata domain,
        uint256[] calldata chainCodes,
        bytes[] calldata resolvers
    ) external;

    function specificParser(
        string calldata domain,
        uint256 chainCode
    ) external view returns (bytes memory);

    function setDomainChainAdmin(
        string calldata domain,
        bytes[] calldata admins,
        uint256[] calldata chainCodes
    ) external;

    function queryAdmin(
        string calldata domain,
        uint256 chainCode
    ) external view returns (bytes memory);

    function setSubDomainRecordBatch(
        string[] calldata parentDomains,
        string[] calldata labels,
        address[] calldata owners
    ) external;

    // function syncRecordBatch(
    //     string[] calldata parentDomains,
    //     string[] calldata labels,
    //     address[] calldata owners,
    //     uint256[] calldata chainCodes,
    //     bytes[] calldata resolvers,
    //     uint64[] calldata ttls,
    //     bytes[] calldata admins
    // ) external;

    function syncRecord(
        string calldata parentDomain,
        string calldata label,
        address owner,
        uint256 chainCode,
        bytes memory resolver,
        uint64 ttl,
        bytes memory admin
    ) external;

    function querySubRecordByParent(
        string calldata domain
    ) external view returns (string[] memory);

    function setOwner(
        string calldata domain,
        address newOwner,
        bool isClear
    ) external;

    function domainOwner(
        string calldata domain
    ) external view returns (address);

    function setTTL(string calldata domain, uint64 ttl) external;

    function ttl(string calldata domain) external view returns (uint64);

    function recordExists(string calldata domain) external view returns (bool);

    function freeze(string calldata domain) external;

    function unFreeze(string calldata domain) external;

    function isFrozen(string calldata domain) external view returns (bool);

    function burn(string calldata domain) external;

    function setOpenOwnerPower(bool isOpen) external;
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


/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
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

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
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
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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


contract DNSManagement is OwnableUpgradeable, UUPSUpgradeable, IDNSManagement {
    //运行者名单
    mapping(address => bool) private _operatorlist;
    //冻结域名名单
    mapping(bytes32 => bool) private _blacklist;
    //父域名，子域名数组关系
    mapping(bytes32 => SubDomains) private _parentSubRelationship;
    //所有注册：域名，对应的注册信息
    mapping(bytes32 => Record) private _records;
    //域名在指定链上的admin
    mapping(bytes32 => mapping(uint256 => bytes)) private _adminList;
    //域名在指定链上的特定解析器
    mapping(bytes32 => mapping(uint256 => bytes)) private _specificResolvers;
    //本合约的顶级域名
    TopLevelDomain private _topLevelDomain;
    //顶级域名，哪些账户拥有运营权
    mapping(address => bool) private _topLevelDomainResellerAuthorization;
    //是否开启域名Owner自己操作
    bool public ownerPower;

    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setOperator(
        address operator,
        bool isTrue
    ) public override onlyOwner {
        _operatorlist[operator] = isTrue;
        emit SetOperator(_msgSender(), operator, isTrue);
    }

    function isOperator(address account) public view override returns (bool) {
        return _operatorlist[account];
    }

    function setTopLevelDomains(
        string calldata domain,
        address owner,
        bool isOpen,
        TopLevelDomainCategory category
    ) public override onlyOwner {
        // Check if it is an operator account
        bytes32 domainByte = keccak256(bytes(domain));
        if (bytes(_records[_topLevelDomain.domainByte].name).length != 0) {
            require(
                _topLevelDomain.domainByte == domainByte,
                "DNSManagement:not the same as a top-level domain"
            );
        }
        _topLevelDomain.domainByte = domainByte;
        _topLevelDomain.category = category;
        _topLevelDomain.isOpen = isOpen;
        _records[domainByte].owner = owner;
        _records[domainByte].name = domain;
        _records[domainByte].level = Level.TopLevelDomain;

        emit SetTopLevelDomains(_msgSender(), domain, owner, isOpen, category);
    }

    function getTopLevelDomainsInfo()
        public
        view
        override
        returns (string memory domain, address owner, bool isOpen)
    {
        return (
            _records[_topLevelDomain.domainByte].name,
            _records[_topLevelDomain.domainByte].owner,
            _topLevelDomain.isOpen
        );
    }

    function setTopLevelDomainsOperate(
        address platformManager,
        bool isOperate
    ) public override {
        // Check if it is an operator account
        _requireOperator();
        _topLevelDomainResellerAuthorization[platformManager] = isOperate;
        emit SetTopLevelDomainsOperate(
            _msgSender(),
            platformManager,
            isOperate
        );
    }

    function isTopLevelDomainsOperate(
        address platformManager
    ) public view override returns (bool) {
        return _topLevelDomainResellerAuthorization[platformManager];
    }

    function setFirstDomainRecordBatch(
        string[] calldata labels,
        address[] calldata owners,
        uint64[] calldata ttls
    ) public override {
        require(
            _topLevelDomain.isOpen,
            "DNSManagement:the top-level domain is not open"
        );
        require(
            _operatorlist[_msgSender()] ||
                (_topLevelDomainResellerAuthorization[_msgSender()] &&
                    ownerPower),
            "DNSManagement:sender does not have permission"
        );

        require(
            labels.length == owners.length && owners.length == ttls.length,
            "DNSManagement:length mismatch"
        );

        for (uint256 i = 0; i < labels.length; i++) {
            string memory firstDomainName = strConcat(
                strConcat(labels[i], "."),
                _records[_topLevelDomain.domainByte].name
            );
            bytes32 firstDomainByte = keccak256(bytes(firstDomainName));
            _requireUnfrozen(firstDomainByte);
            if (_records[firstDomainByte].owner == address(0)) {
                _parentSubRelationship[_topLevelDomain.domainByte]
                    .subDomainList
                    .push(firstDomainByte);
                _parentSubRelationship[_topLevelDomain.domainByte].index[
                        firstDomainByte
                    ] = _parentSubRelationship[_topLevelDomain.domainByte]
                    .subDomainList
                    .length;
            }
            _records[firstDomainByte].owner = owners[i];
            _records[firstDomainByte].name = firstDomainName;
            _records[firstDomainByte].level = Level.FirstLevelDomain;
            _records[firstDomainByte].parent = _topLevelDomain.domainByte;
            _records[firstDomainByte].ttl = ttls[i];
        }

        emit SetFirstDomainRecordBatch(_msgSender(), labels, owners, ttls);
    }

    function setDomainSpecificParser(
        string calldata domain,
        uint256[] calldata chainCodes,
        bytes[] calldata resolvers
    ) public override {
        require(
            chainCodes.length == resolvers.length,
            "DNSManagement:length mismatch"
        );
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        require(
            _operatorlist[_msgSender()] ||
                (_records[domainByte].owner == _msgSender() && ownerPower),
            "DNSManagement:sender does not have permission"
        );
        _requireUnfrozen(domainByte);
        for (uint256 i = 0; i < chainCodes.length; i++) {
            _specificResolvers[domainByte][chainCodes[i]] = resolvers[i];
        }
        emit SetDomainSpecificParser(
            _msgSender(),
            domain,
            chainCodes,
            resolvers
        );
    }

    function specificParser(
        string calldata domain,
        uint256 chainCode
    ) public view override returns (bytes memory) {
        bytes32 domainByte = keccak256(bytes(domain));
        return _specificResolvers[domainByte][chainCode];
    }

    function setDomainChainAdmin(
        string calldata domain,
        bytes[] calldata admins,
        uint256[] calldata chainCodes
    ) public override {
        require(
            chainCodes.length == admins.length,
            "DNSManagement:length mismatch"
        );
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        require(
            _operatorlist[_msgSender()] ||
                (_records[domainByte].owner == _msgSender() && ownerPower),
            "DNSManagement:sender does not have permission"
        );
        _requireUnfrozen(domainByte);
        for (uint256 i = 0; i < chainCodes.length; i++) {
            _adminList[domainByte][chainCodes[i]] = admins[i];
        }
        emit SetDomainChainAdmin(_msgSender(), domain, admins, chainCodes);
    }

    function queryAdmin(
        string calldata domain,
        uint256 chainCode
    ) public view override returns (bytes memory) {
        bytes32 domainByte = keccak256(bytes(domain));
        return _adminList[domainByte][chainCode];
    }

    function setSubDomainRecordBatch(
        string[] calldata parentDomains,
        string[] calldata labels,
        address[] calldata owners
    ) public override {
        require(
            parentDomains.length == labels.length &&
                parentDomains.length == owners.length,
            "DNSManagement:length mismatch"
        );
        for (uint256 i = 0; i < parentDomains.length; i++) {
            bytes32 firstDomainByte = keccak256(bytes(parentDomains[i]));
            _requireExist(firstDomainByte);
            require(
                _records[firstDomainByte].ttl >= block.timestamp,
                "DNSManagement:the parent domain name has expired"
            );
            require(
                _records[firstDomainByte].level == Level.FirstLevelDomain,
                "DNSManagement:the parent domain name is not a registered first-level domain name"
            );
            require(
                _operatorlist[_msgSender()] ||
                    (_records[firstDomainByte].owner == _msgSender() &&
                        ownerPower),
                "DNSManagement:sender does not have permission"
            );

            string memory subDomainName = strConcat(
                strConcat(labels[i], "."),
                parentDomains[i]
            );
            bytes32 subDomainByte = keccak256(bytes(subDomainName));
            if (_records[subDomainByte].owner == address(0)) {
                _parentSubRelationship[firstDomainByte].subDomainList.push(
                    subDomainByte
                );
                _parentSubRelationship[firstDomainByte].index[
                        subDomainByte
                    ] = _parentSubRelationship[firstDomainByte]
                    .subDomainList
                    .length;
            }
            _records[subDomainByte].owner = owners[i];
            _records[subDomainByte].name = subDomainName;
            _records[subDomainByte].level = Level.SubLevelDomain;
            _records[subDomainByte].parent = firstDomainByte;
            _requireUnfrozen(subDomainByte);
        }

        emit SetSubDomainRecordBatch(
            _msgSender(),
            parentDomains,
            labels,
            owners
        );
    }

    // function syncRecordBatch(
    //     string[] calldata parentDomains,
    //     string[] calldata labels,
    //     address[] calldata owners,
    //     uint256[] calldata chainCodes,
    //     bytes[] calldata resolvers,
    //     uint64[] calldata ttls,
    //     bytes[] calldata admins
    // ) public override {
    //     _requireOperator();
    //     require(
    //         parentDomains.length == labels.length &&
    //             labels.length == owners.length &&
    //             owners.length == chainCodes.length &&
    //             chainCodes.length == resolvers.length &&
    //             resolvers.length == ttls.length &&
    //             ttls.length == admins.length,
    //         "DNSManagement:length mismatch"
    //     );
    //     for (uint256 i = 0; i < parentDomains.length; i++) {
    //         _syncRecord(
    //             parentDomains[i],
    //             labels[i],
    //             owners[i],
    //             chainCodes[i],
    //             resolvers[i],
    //             ttls[i],
    //             admins[i]
    //         );
    //     }

    //     emit SyncRecordBatch(
    //         _msgSender(),
    //         parentDomains,
    //         labels,
    //         owners,
    //         chainCodes,
    //         resolvers,
    //         ttls,
    //         admins
    //     );
    // }

    function syncRecord(
        string calldata parentDomain,
        string calldata label,
        address owner,
        uint256 chainCode,
        bytes memory resolver,
        uint64 ttl,
        bytes memory admin
    ) public override {
        _requireOperator();
        _syncRecord(
            parentDomain,
            label,
            owner,
            chainCode,
            resolver,
            ttl,
            admin
        );

        emit SyncRecord(
            _msgSender(),
            parentDomain,
            label,
            owner,
            chainCode,
            resolver,
            ttl,
            admin
        );
    }

    function _syncRecord(
        string calldata parentDomain,
        string calldata label,
        address owner,
        uint256 chainCode,
        bytes memory resolver,
        uint64 ttl,
        bytes memory admin
    ) private {
        bytes32 parentDomainByte = keccak256(bytes(parentDomain));
        require(
            _records[parentDomainByte].owner != address(0),
            "DNSManagement:the parent domain is not yet synchronized"
        );
        string memory domainName = strConcat(
            strConcat(label, "."),
            parentDomain
        );
        bytes32 domainByte = keccak256(bytes(domainName));
        if (_records[domainByte].owner == address(0)) {
            _parentSubRelationship[parentDomainByte].subDomainList.push(
                domainByte
            );
            _parentSubRelationship[parentDomainByte].index[
                    domainByte
                ] = _parentSubRelationship[parentDomainByte]
                .subDomainList
                .length;
        }
        _records[domainByte].owner = owner;
        _records[domainByte].name = domainName;
        _records[domainByte].parent = parentDomainByte;
        _requireUnfrozen(domainByte);
        if (parentDomainByte == keccak256(bytes(parentDomain))) {
            _records[domainByte].level = Level.FirstLevelDomain;
            _records[domainByte].ttl = ttl;
        } else {
            _records[domainByte].level = Level.SubLevelDomain;
        }
        _specificResolvers[domainByte][chainCode] = resolver;
        _adminList[domainByte][chainCode] = admin;
    }

    function querySubRecordByParent(
        string calldata domain
    ) public view override returns (string[] memory) {
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        string[] memory sub = new string[](
            _parentSubRelationship[domainByte].subDomainList.length
        );
        for (
            uint256 i = 0;
            i < _parentSubRelationship[domainByte].subDomainList.length;
            i++
        ) {
            sub[i] = _records[
                _parentSubRelationship[domainByte].subDomainList[i]
            ].name;
        }
        return sub;
    }

    function setOwner(
        string calldata domain,
        address newOwner,
        bool isClear
    ) public override {
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        require(
            _operatorlist[_msgSender()] ||
                (_records[domainByte].owner == _msgSender() && ownerPower),
            "DNSManagement:sender does not have permission"
        );
        _requireUnfrozen(domainByte);
        _records[domainByte].owner = newOwner;
        if (isClear) {
            require(
                _records[domainByte].level != Level.TopLevelDomain,
                "DNSManagement:cannot clear descendant domains under top-level domains"
            );
        }

        if (isClear && _records[domainByte].level == Level.FirstLevelDomain) {
            for (
                uint256 i = 0;
                i < _parentSubRelationship[domainByte].subDomainList.length;
                i++
            ) {
                delete _records[
                    _parentSubRelationship[domainByte].subDomainList[i]
                ];
            }
            delete _parentSubRelationship[domainByte];
        }
        emit SetOwner(_msgSender(), domain, newOwner, isClear);
    }

    function domainOwner(
        string calldata domain
    ) public view override returns (address) {
        bytes32 domainByte = keccak256(bytes(domain));
        return _records[domainByte].owner;
    }

    function setTTL(string calldata domain, uint64 ttl) public override {
        _requireOperator();
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        _requireUnfrozen(domainByte);
        _records[domainByte].ttl = ttl;
        emit SetTTL(_msgSender(), domain, ttl);
    }

    function ttl(string calldata domain) public view override returns (uint64) {
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        if (_records[domainByte].level == Level.SubLevelDomain) {
            return _records[_records[domainByte].parent].ttl;
        }
        return _records[domainByte].ttl;
    }

    function recordExists(
        string calldata domain
    ) public view override returns (bool) {
        bytes32 domainByte = keccak256(bytes(domain));
        return _records[domainByte].owner != address(0);
    }

    function freeze(string calldata domain) public override {
        _requireOperator();
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        _requireNotTopDomain(domainByte);
        require(
            !_blacklist[domainByte],
            "DNSManagement:the domain name has been frozen"
        );
        _blacklist[domainByte] = true;
        emit EnterBlacklist(_msgSender(), domain);
    }

    function unFreeze(string calldata domain) public override {
        _requireOperator();
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        _requireNotTopDomain(domainByte);
        require(
            _blacklist[domainByte],
            "DNSManagement:domain do not need to be unfrozen"
        );
        _blacklist[domainByte] = false;
        emit ExitBlacklist(_msgSender(), domain);
    }

    function isFrozen(
        string calldata domain
    ) public view override returns (bool) {
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        _requireNotTopDomain(domainByte);
        if (!_blacklist[domainByte]) {
            return _blacklist[_records[domainByte].parent];
        }
        return true;
    }

    function burn(string calldata domain) public override {
        bytes32 domainByte = keccak256(bytes(domain));
        _requireExist(domainByte);
        _requireNotTopDomain(domainByte);
        require(
            _operatorlist[_msgSender()] ||
                (_records[domainByte].owner == _msgSender() && ownerPower),
            "DNSManagement:sender does not have permission"
        );
        _requireUnfrozen(domainByte);
        if (_records[domainByte].level == Level.FirstLevelDomain) {
            for (
                uint256 i = 0;
                i < _parentSubRelationship[domainByte].subDomainList.length;
                i++
            ) {
                delete _records[
                    _parentSubRelationship[domainByte].subDomainList[i]
                ];
                // delete _adminList[domainByte];
                // delete _specificResolvers[domainByte];
            }
            delete _parentSubRelationship[domainByte];
        }

        uint256 index = _parentSubRelationship[_records[domainByte].parent]
            .index[domainByte];
        if (index > 0) {
            // 将数组的最后一位值粘贴到要删除的那一位上
            _parentSubRelationship[_records[domainByte].parent].subDomainList[
                    index - 1
                ] = _parentSubRelationship[_records[domainByte].parent]
                .subDomainList[
                    _parentSubRelationship[_records[domainByte].parent]
                        .subDomainList
                        .length - 1
                ];
            // 将值-索引map中数组最后一位值对应的索引改为要删除值的索引
            _parentSubRelationship[_records[domainByte].parent].index[
                _parentSubRelationship[_records[domainByte].parent]
                    .subDomainList[index - 1]
            ] = index;
            // 将数组最后一位删掉
            _parentSubRelationship[_records[domainByte].parent]
                .subDomainList
                .pop();
            // 将值-索引map中要删除值作为key删掉
            delete _parentSubRelationship[_records[domainByte].parent].index[
                domainByte
            ];
        }
        delete _records[domainByte];
        emit Burn(_msgSender(), domain);
    }

    function setOpenOwnerPower(bool isOpen) public override {
        _requireOperator();
        ownerPower = isOpen;
        emit SetOpenOwnerPower(_msgSender(), isOpen);
    }

    /**
     * @dev Requires a operator role.
     *
     * Requirements:
     * - `sender` must be a available `ddc` account.
     * - `sender` must be a `Operator` role.
     */
    function _requireOperator() private view {
        require(
            _operatorlist[_msgSender()],
            "DNSManagement:sender is not an operator"
        );
    }

    function _requireUnfrozen(bytes32 domainByte) private view {
        require(
            !_blacklist[domainByte],
            "DNSManagement:the domain name is frozen and cannot be operated"
        );
        require(
            !_blacklist[_records[domainByte].parent],
            "DNSManagement:the domain name parent is frozen and cannot be operated"
        );
    }

    function _requireExist(bytes32 domainByte) private view {
        require(
            _records[domainByte].owner != address(0),
            "DNSManagement:unregistered domain name"
        );
    }

    function _requireNotTopDomain(bytes32 domainByte) private view {
        require(
            _records[domainByte].level != Level.TopLevelDomain,
            "DNSManagement:cannot be a top-level domain name"
        );
    }

    function strConcat(
        string memory _a,
        string memory _b
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }
}