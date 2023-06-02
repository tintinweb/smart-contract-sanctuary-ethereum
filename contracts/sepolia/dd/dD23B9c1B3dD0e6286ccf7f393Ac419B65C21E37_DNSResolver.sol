/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
interface IDNSResolver {
    event SetDomainManagement(
        address indexed sender,
        address domainManagementProxy
    );
    event SetAddr(
        address indexed sender,
        uint256 chainCode,
        string domain,
        bytes addrByte
    );
    event SetAddrBatch(
        address indexed sender,
        uint256[] chainCodes,
        string domain,
        bytes[] addressList
    );
    event SetText(
        address indexed sender,
        uint256 chainCode,
        string domain,
        string key,
        string value
    );
    event SetTextBatch(
        address indexed sender,
        uint256[] chainCodes,
        string domain,
        string[] keys,
        string[] values
    );

    function setDomainManagement(address domainManagementProxy) external;

    function isAuthorised(
        address account,
        string calldata domain,
        uint256 chainCode
    ) external view returns (bool);

    function addr(
        string calldata domain,
        uint256 chainCode
    ) external view returns (address payable);

    function getAddrByte(
        string calldata domain,
        uint256 chainCode
    ) external view returns (bytes memory);

    function setAddr(
        uint256 chainCode,
        string calldata domain,
        bytes memory addrByte
    ) external;

    function setAddrBatch(
        uint256[] calldata chainCodes,
        string calldata domain,
        bytes[] calldata addressList
    ) external;

    function text(
        uint256 chainCode,
        string calldata domain,
        string calldata key
    ) external view returns (string memory);

    function setText(
        uint256 chainCode,
        string calldata domain,
        string calldata key,
        string calldata value
    ) external;

    function setTextBatch(
        uint256[] calldata chainCodes,
        string calldata domain,
        string[] calldata keys,
        string[] calldata values
    ) external;
}

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


abstract contract ResolverBase {
    function bytesToAddress(
        bytes memory b
    ) internal pure returns (address payable a) {
        require(b.length == 20,"bytes to Address, bytes length should be equal to 20");
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}


contract DNSResolver is
    OwnableUpgradeable,
    UUPSUpgradeable,
    ResolverBase,
    IDNSResolver
{
    using AddressUpgradeable for address;
    // 域名管理合约地址
    address public _dnsManagement;
    //存储地址的数据结构，参考EIP137
    mapping(bytes32 => mapping(uint256 => bytes)) _addresses;
    //存储文本数据的数据结构，参考EIP634
    mapping(bytes32 => mapping(uint256 => mapping(string => string))) texts;

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

    function setDomainManagement(
        address domainManagementProxy
    ) public override onlyOwner {
        _requireContract(domainManagementProxy);
        _dnsManagement = domainManagementProxy;
        emit SetDomainManagement(_msgSender(), domainManagementProxy);
    }

    function isAuthorised(
        address account,
        string calldata domain,
        uint256 chainCode
    ) public view override returns (bool) {
        return
            IDNSManagement(_dnsManagement).isOperator(account) ||
            (keccak256(addressToBytes(account)) ==
                keccak256(
                    IDNSManagement(_dnsManagement).queryAdmin(domain, chainCode)
                )) ||
            (IDNSManagement(_dnsManagement).domainOwner(domain) == account);
    }

    function addr(
        string calldata domain,
        uint256 chainCode
    ) public view override returns (address payable) {
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        return (bytesToAddress(_addresses[domainByte][chainCode]));
    }

    function getAddrByte(
        string calldata domain,
        uint256 chainCode
    ) public view override returns (bytes memory) {
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        return (_addresses[domainByte][chainCode]);
    }

    function setAddr(
        uint256 chainCode,
        string calldata domain,
        bytes memory addrByte
    ) public override {
        _requirePermission(chainCode, domain);
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        _addresses[domainByte][chainCode] = addrByte;
        emit SetAddr(_msgSender(), chainCode, domain, addrByte);
    }

    function setAddrBatch(
        uint256[] calldata chainCodes,
        string calldata domain,
        bytes[] calldata addressList
    ) public override {
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        for (uint256 i = 0; i < chainCodes.length; i++) {
            _requirePermission(chainCodes[i], domain);
            _addresses[domainByte][chainCodes[i]] = addressList[i];
        }
        emit SetAddrBatch(_msgSender(), chainCodes, domain, addressList);
    }

    function text(
        uint256 chainCode,
        string calldata domain,
        string calldata key
    ) external view override returns (string memory) {
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        return texts[domainByte][chainCode][key];
    }

    function setText(
        uint256 chainCode,
        string calldata domain,
        string calldata key,
        string calldata value
    ) public override {
        _requirePermission(chainCode, domain);
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        texts[domainByte][chainCode][key] = value;
        emit SetText(_msgSender(), chainCode, domain, key, value);
    }

    function setTextBatch(
        uint256[] calldata chainCodes,
        string calldata domain,
        string[] calldata keys,
        string[] calldata values
    ) public override {
        require(keys.length == values.length, "DNSResolver:length mismatch");
        _isOperable(domain);
        bytes32 domainByte = keccak256(bytes(domain));
        for (uint256 j = 0; j < chainCodes.length; j++) {
            _requirePermission(chainCodes[j], domain);
            for (uint256 i = 0; i < keys.length; i++) {
                texts[domainByte][chainCodes[j]][keys[i]] = values[i];
            }
        }
        emit SetTextBatch(_msgSender(), chainCodes, domain, keys, values);
    }

    /**
     * @dev Requires contract address on chain.
     *
     * Requirements:
     * - `account` must not be zero address.
     * - `account` must be a contract.
     */
    function _requireContract(address account) private view {
        require(account.isContract(), "DNSResolver:not a contract");
    }

    function _isOperable(string calldata domain) private view {
        require(
            IDNSManagement(_dnsManagement).recordExists(domain),
            "DNSResolver: domain name does not exist"
        );
        require(
            !IDNSManagement(_dnsManagement).isFrozen(domain),
            "DNSResolver: the domain name is frozen"
        );
        require(
            IDNSManagement(_dnsManagement).ttl(domain) >= block.timestamp,
            "DNSResolver: the domain name has expired"
        );
    }

    function _requirePermission(
        uint256 chainCode,
        string calldata domain
    ) private view {
        require(
            IDNSManagement(_dnsManagement).isOperator(_msgSender()) ||
                (keccak256(addressToBytes(_msgSender())) ==
                    keccak256(
                        IDNSManagement(_dnsManagement).queryAdmin(
                            domain,
                            chainCode
                        )
                    )) ||
                (IDNSManagement(_dnsManagement).domainOwner(domain) ==
                    _msgSender()),
            "DNSResolver: sender has no permission"
        );
    }
}