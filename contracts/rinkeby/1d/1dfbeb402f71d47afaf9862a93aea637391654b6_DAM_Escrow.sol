/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

/**
 *Submitted for verification at kovan-optimistic.etherscan.io on 2022-04-01
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity >=0.8.0 <0.9.0;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)


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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)


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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)


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


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)





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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)


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


// File contracts/DAM_escrow.sol



interface IERC20 {
        function transfer(address _to, uint256 _amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
        function ownerOf(uint tokenId) external returns (address);
        function tokenId() external view returns (uint);
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign() or signMessage()
   */
  function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
  {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
          return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
          r := mload(add(signature, 0x20))
          s := mload(add(signature, 0x40))
          v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
          v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
          return (address(0));
        } else {
          // solium-disable-next-line arg-overflow
          return ecrecover(hash, v, r, s);
        }
  }

  /**
        * toEthSignedMessageHash
        * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
        * and hash the result
        */
  function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
  {
        return keccak256(
          abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
  }
}

contract DAM_Escrow is UUPSUpgradeable {

        struct marketData{
                address owner;
                address delegate; // address of delegate/minion
                address assayerNFT; //ERC721
                uint[] otherMarkets; // list of IDs of other markets - assayers
                uint16 feePercent;// = 100; //1%
                uint auditTimeExtension;// = 5760; // 1 day
        }

        struct transactionData{
                address buyer;
                address seller;
                bytes32 spec;
                address paymentTokenAddress;
                uint paymentAmount;
                uint expiry; //block number
                bytes buyerSignature;
                bytes sellerSignature;
                uint[] auditIDs; //list od audits - auditIDs
                bool finished; //placeholder for when buyer/seller withdraw funds or for partial order execution
                uint marketID;
        }

        struct assayerInput{
                address assayerNFT;
                uint tokenID; // NFT token ID with which assayer is participating - assayers can hold / and partiipate with multiple NFT tokens
                bytes32 commit;
                bool revealed;
                bool paid;
        }

        struct auditData{
                bytes32 buyerEvidence;
                bytes32 sellerEvidence;
                uint expiry; //block number
                uint price;
                address paymentTokenAddress;
                bool resolved; // set true if delegate/minion decides
                bool refund; // direction of releasing funds - TRUE for buyer, FALSE for seller
                bool resolvedByVerdict; //resolved by unanimous decision of assayers
                assayerInput[] commits;
                bool[] verdicts; // false in favor of seller, true in favor of buyer - refund
                uint marketID;
        }

        marketData[] markets;
        mapping(uint => mapping(uint => bool)) public banned; // marketID => assayerNFT# - true if banned
        mapping(uint => mapping(uint => uint)) partialOrder; //marketID => partial order transactionID => open order transactionID
        transactionData[] transactions;
        auditData[] audits;
        bytes32[] public receipts;

        event Transaction(uint transactionID);
        event Audit(uint auditID);
        event CommittedAssay(address indexed assayer, uint auditID, uint assayID);
        event RevealedAssay(address indexed assayer, uint auditID, uint assayID, bool refund);
        event NewMarket(uint marketID);
        event TransactionReceipt(uint transactionID, uint receiptID);
        event OtherMarketID(uint marketID, uint otherMarketID);
        event PartialOrder(uint transactionID);

        function initialize(address _owner, address _assayerNFT, uint16 _feePercent, uint _auditTimeExtension) initializer public {
                __UUPSUpgradeable_init();
                createMarket(_owner, _assayerNFT, _feePercent, _auditTimeExtension);
        }

        function _authorizeUpgrade(address newImplementation) internal override onlyOwner(0) {}

        function createMarket(address _owner, address _assayerNFT, uint16 _feePercent, uint _auditTimeExtension) public {
                emit NewMarket(markets.length);
                markets.push();
                markets[markets.length-1].owner=_owner; //multisig contract / gnosis safe
                markets[markets.length-1].assayerNFT=_assayerNFT;
                markets[markets.length-1].feePercent=_feePercent;
                markets[markets.length-1].auditTimeExtension=_auditTimeExtension;
        }

        function takeOrder(uint transactionID, bytes32 receipt) external {
                require(transactions[transactionID].seller == address(0) && !transactions[transactionID].finished , "26");
                emit TransactionReceipt(transactionID, receipts.length);
                receipts.push(receipt);
                transactions[transactionID].seller=msg.sender;
                transactions[transactionID].expiry+=block.number;
        }

        function takePartialOrder(uint transactionID, bytes32 spec, uint offerAmount) external {
                require(transactions[transactionID].seller == address(0) && !transactions[transactionID].finished && offerAmount < transactions[transactionID].paymentAmount, "26");
                transactionData memory temp;
                temp=transactions[transactionID];
                temp.seller=msg.sender;
                temp.spec=spec;
                temp.paymentAmount=offerAmount;
                temp.finished = true; // locking the transaction untill, buyer confirms
                emit Transaction(transactions.length);
                emit PartialOrder(transactions.length);
                partialOrder[transactions[transactionID].marketID][transactions.length]=transactionID;
                transactions.push(temp);
        }

        function confrmPartialOrder(uint transactionID) external {
                require(msg.sender==transactions[ partialOrder[transactions[transactionID].marketID][transactionID] ].buyer, "13");
                transactions[ partialOrder[transactions[transactionID].marketID][transactionID] ].paymentAmount -= transactions[transactionID].paymentAmount;
                transactions[transactionID].finished = false;
                transactions[transactionID].expiry+=block.number;
                emit Transaction(transactionID);
        }

        function createTransaction(address buyer, address seller, bytes32 spec, address _paymentTokenAddress, uint paymentAmount, uint blocks, bytes memory  buyerSignature, bytes memory  sellerSignature, uint marketID) public {
                require(IERC20(_paymentTokenAddress).transferFrom(buyer, address(this), paymentAmount), "1");

                transactionData memory temp;

                if(seller != address(0)) { // messageHash = keccak256(abi.encodePacked( SPEC, PAYMENT TOKEN ADDRESS, PAYMENT AMOUNTH, BLOCKS - TIME )
                        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(spec, _paymentTokenAddress, paymentAmount, blocks ))), sellerSignature)==seller, "2");
                        if(buyer != markets[marketID].owner) require(ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(spec, _paymentTokenAddress, paymentAmount, blocks ))), buyerSignature)==buyer, "3");
                        temp.expiry = block.number + blocks;
                }
                else temp.expiry = blocks;

                temp.buyer = buyer;
                temp.seller = seller;
                temp.spec = spec;
                temp.paymentTokenAddress = _paymentTokenAddress;
                temp.paymentAmount = paymentAmount;
                temp.buyerSignature = buyerSignature;
                temp.sellerSignature = sellerSignature;
                temp.finished = false;
                emit Transaction(transactions.length);
                transactions.push(temp);
        }

        function createTransactions(bytes32[] memory spec, address[] memory _paymentTokenAddress, uint[] memory paymentAmount, uint[] memory blocks, uint marketID) external {//assuming array parameters are all in the same size - reading from .csv
                bytes memory empty;
                for(uint i; i < spec.length; i++){
                        createTransaction(msg.sender, address(0), spec[i], _paymentTokenAddress[i], paymentAmount[i], blocks[i], empty, empty, marketID);
                }
        }


        function cancelTransaction(uint transactionID) external { //only transaction without specified buyer can be withdrawn
                require(transactions[transactionID].seller==address(0),"23");
                require(!transactions[transactionID].finished, "24");
                require(transactions[transactionID].buyer==msg.sender,"25");
                IERC20(transactions[transactionID].paymentTokenAddress).transfer(msg.sender, transactions[transactionID].paymentAmount);
                transactions[transactionID].finished = true;
        }

        function payWithFee(uint transactionID) internal {
                if(transactions[transactionID].buyer==markets[transactions[transactionID].marketID].owner) //without fee if buyer is market owner
                        IERC20(transactions[transactionID].paymentTokenAddress).transfer(msg.sender, transactions[transactionID].paymentAmount);
                else {
                        IERC20(transactions[transactionID].paymentTokenAddress).transfer(msg.sender, transactions[transactionID].paymentAmount - transactions[transactionID].paymentAmount/10000*markets[transactions[transactionID].marketID].feePercent);
                        IERC20(transactions[transactionID].paymentTokenAddress).transfer(markets[transactions[transactionID].marketID].owner, transactions[transactionID].paymentAmount/10000*markets[transactions[transactionID].marketID].feePercent);
                }
                transactions[transactionID].finished = true;
        }

        function withdraw(uint transactionID) external {
                require(transactions[transactionID].expiry < block.number, "4");
                require(!transactions[transactionID].finished, "5");
                if (msg.sender == transactions[transactionID].seller) { //checking if withdraw was called by seller
                        if (transactions[transactionID].auditIDs.length == 0) { //checking if no audits were called
                                payWithFee(transactionID);
                        } else { //checking if all audits were resolved and in favor of seller
                                uint resolved;
                                for (uint i; i < transactions[transactionID].auditIDs.length; i++) { // first we check if audit was ruled by delegate / minion
                                        if (audits[transactions[transactionID].auditIDs[i]].resolved && !audits[transactions[transactionID].auditIDs[i]].refund)
                                                resolved++;
                                        else { //then we check if all assayers voted in the favor of the seller
                                                require(audits[transactions[transactionID].auditIDs[i]].expiry < block.number, "6");
                                                require(audits[transactions[transactionID].auditIDs[i]].commits.length == audits[transactions[transactionID].auditIDs[i]].verdicts.length , "7");
                                                uint verdicts;
                                                for(uint j; j < audits[transactions[transactionID].auditIDs[i]].verdicts.length; j++){
                                                        if (!audits[transactions[transactionID].auditIDs[i]].verdicts[j])
                                                                verdicts++;
                                                }
                                                if (verdicts != 0 && verdicts == audits[transactions[transactionID].auditIDs[i]].verdicts.length){
                                                        resolved++;
                                                        audits[transactions[transactionID].auditIDs[i]].resolvedByVerdict = true;
                                                }
                                        }
                                }
                                require(resolved == transactions[transactionID].auditIDs.length, "8");
                                payWithFee(transactionID);
                        }
                }
                else if (msg.sender == transactions[transactionID].buyer && transactions[transactionID].auditIDs.length > 0) {// checking if withdraw was called by buyer
                        uint resolved;//checking if all audits were resolved and in favor of seller
                        for (uint i; i < transactions[transactionID].auditIDs.length; i++) { // first we check if audit was ruled by delegate / minion
                                if (audits[transactions[transactionID].auditIDs[i]].resolved && audits[transactions[transactionID].auditIDs[i]].refund)
                                        resolved++;
                                else { //then we check if all assayers voted in the favor of the buyer
                                        require(audits[transactions[transactionID].auditIDs[i]].expiry < block.number, "6");
                                        require(audits[transactions[transactionID].auditIDs[i]].commits.length == audits[transactions[transactionID].auditIDs[i]].verdicts.length , "7");
                                        uint verdicts;
                                        for(uint j; j < audits[transactions[transactionID].auditIDs[i]].verdicts.length; j++){
                                                if (audits[transactions[transactionID].auditIDs[i]].verdicts[j])
                                                        verdicts++;
                                        }
                                        if (verdicts != 0 && verdicts == audits[transactions[transactionID].auditIDs[i]].verdicts.length) {
                                                resolved++;
                                                audits[transactions[transactionID].auditIDs[i]].resolvedByVerdict = true;
                                        }
                                }
                        }
                        require(resolved == transactions[transactionID].auditIDs.length, "8");
                        payWithFee(transactionID);
                }
        }

        modifier auditNotExpired(uint _auditID) {
                require(audits[_auditID].expiry > block.number, "10");
                _;
        }

        function audit(uint transactionID, uint blocks,address paymentTokenAddress, uint auditPrice)
        external {
                require(IERC20(paymentTokenAddress).transferFrom(msg.sender, address(this),auditPrice), "1");
                require(transactions[transactionID].expiry > block.number, "9");
                transactions[transactionID].auditIDs.push(audits.length);
                emit Audit(audits.length);
                audits.push();
                audits[audits.length-1].expiry = block.number + blocks;
                audits[audits.length-1].paymentTokenAddress = paymentTokenAddress;
                audits[audits.length-1].price = auditPrice;
                audits[audits.length-1].marketID = transactions[transactionID].marketID;
        }

        function fillEvidence(uint transactionID, uint _auditID, bytes32 evidence)
        auditNotExpired(_auditID)
        external {
                if(transactions[transactionID].buyer == msg.sender) audits[_auditID].buyerEvidence = evidence;
                else if(transactions[transactionID].seller == msg.sender) audits[_auditID].sellerEvidence = evidence;
                else revert("13");
        }

        function resolveAudit(uint _auditID, bool refund) external onlyOwner(audits[_auditID].marketID) {
                require(!audits[_auditID].resolvedByVerdict && !audits[_auditID].resolved, "15");
                audits[_auditID].resolved = true;
                audits[_auditID].refund = refund;
                IERC20(audits[_auditID].paymentTokenAddress).transfer(msg.sender, audits[_auditID].price);
        }

        function commitAssay(uint _auditID, bytes32 saltedCommit, address assayerNFT, uint tokenID)
        auditNotExpired(_auditID)
        external {
                require(IERC721(assayerNFT).ownerOf(tokenID)==msg.sender, "25"); // confirm assayerNFT ownership
                if(assayerNFT == markets[audits[_auditID].marketID].assayerNFT) require( !banned[audits[_auditID].marketID][tokenID] ,"16"); // assayer with "default" assayerNFT - must not be banned
                else { // assayer with otherMarkets assayerNFT
                        bool otherMarketNFT;
                        uint otherMarketID;
                        for(; otherMarketID < markets[audits[_auditID].marketID].otherMarkets.length; otherMarketID++)
                                if(markets[ markets[audits[_auditID].marketID].otherMarkets[otherMarketID] ].assayerNFT == assayerNFT) {
                                        otherMarketNFT = true;
                                        break;
                                }
                        require(otherMarketNFT && !banned[ markets[audits[_auditID].marketID].otherMarkets[otherMarketID] ][tokenID], "17");
                }
                for(uint i; i < audits[_auditID].commits.length; i++){
                        require(!(audits[_auditID].commits[i].assayerNFT == assayerNFT && audits[_auditID].commits[i].tokenID == tokenID),"18");
                }
                emit CommittedAssay(msg.sender, _auditID, audits[_auditID].commits.length);
                audits[_auditID].commits.push(assayerInput(assayerNFT, tokenID, saltedCommit, false, false));
        }

        modifier trueAssayer(uint _auditID, uint assayID) {//verifying if caller is the true owner of assay in question
                require(IERC721( audits[_auditID].commits[assayID].assayerNFT ).ownerOf( audits[_auditID].commits[assayID].tokenID )==msg.sender, "19");
                _;
        }

        function revealAssay(uint _auditID, bool refund, bytes32 salt, uint assayID)
        trueAssayer(_auditID, assayID)
        auditNotExpired(_auditID)
        external {
                require(!audits[_auditID].commits[assayID].revealed, "21");
                require(getSaltedHash(refund,salt)==audits[_auditID].commits[assayID].commit,"22");
                audits[_auditID].commits[assayID].revealed=true;
                audits[_auditID].verdicts.push(refund);
                emit RevealedAssay(msg.sender, _auditID, assayID, refund);
                if(audits[_auditID].expiry < (block.number + markets[audits[_auditID].marketID].auditTimeExtension))
                        audits[_auditID].expiry = block.number + markets[audits[_auditID].marketID].auditTimeExtension;
        }

        function assayerWithdrawFee(uint _auditID, uint assayID)
        trueAssayer(_auditID, assayID)
        public {
                require(audits[_auditID].resolvedByVerdict, "23");
                require(!audits[_auditID].commits[assayID].paid, "24");
                IERC20(audits[_auditID].paymentTokenAddress).transfer(msg.sender, audits[_auditID].price / audits[_auditID].verdicts.length);
                audits[_auditID].commits[assayID].paid = true;
        }

        function assayerWithdrawFees(uint[2][] memory assays) external {
                for(uint i; i<assays.length; i++)
                        assayerWithdrawFee(assays[i][0], assays[i][1]);
        }

        function assignDelegate(address _delegate, uint marketID) external onlyOwner(marketID){// assign delegate / minion address
                markets[marketID].delegate=_delegate;
        }

        function getSaltedHash(bool refund,bytes32 salt) public view returns(bytes32){
                return keccak256(abi.encodePacked(address(this), refund, salt));
        }

        modifier onlyOwner(uint marketID) {
                require(msg.sender == markets[marketID].owner, "25");
                _;
        }
        modifier onlyOwnerOrDelegate(uint marketID) {
                require(msg.sender == markets[marketID].owner || msg.sender == markets[marketID].delegate , "25");
                _;
        }
        function transferOwnership(address newowner, uint marketID) external onlyOwner(marketID) {
                markets[marketID].owner = newowner;
        }

        function updateAuditTimeExtension(uint _auditTimeExtension, uint marketID) external onlyOwner(marketID){
                markets[marketID].auditTimeExtension = _auditTimeExtension;
        }

        function updateOtherMarkets(uint[] memory newSet, uint marketID) external onlyOwner(marketID){
                markets[marketID].otherMarkets = newSet;
                for(uint i; i<newSet.length; i++)
                emit OtherMarketID(marketID, newSet[i]);
        }

        function addOtherMarket(uint newMarket, uint marketID) external onlyOwner(marketID){
                emit OtherMarketID(marketID, newMarket);
                markets[marketID].otherMarkets.push(newMarket);
        }

        function setAssayerNFT(address _assayerNFT, uint marketID) external onlyOwner(marketID){
                markets[marketID].assayerNFT=_assayerNFT;
        }

        function banTokenID(uint[] memory tokenBanList, uint marketID) external onlyOwnerOrDelegate(marketID){
                for(uint i; i<tokenBanList.length; i++)
                        banned[marketID][tokenBanList[i]]=true;
        }

        function getMarket(uint marketID) external view returns(marketData memory) {
        return markets[marketID];
    }

        function getTransaction( uint transcationID) external view returns(transactionData memory) {
        return transactions[transcationID];
    }

        function getAudit(uint auditID) external view returns(auditData memory) {
        return audits[auditID];
    }
}