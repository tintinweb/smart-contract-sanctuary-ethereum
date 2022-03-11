// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./SystemContext.sol";

contract CollectionsRegistry is ICollectionRegistry {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Record {
        address owner;
        address addr;
        string userName;
        string contractName;
        uint16 contractVersion;
    }

    // mapping from collectionId into collection address
    mapping(bytes32 => Record) public records;
    // mapping from address into collection id
    mapping(address => bytes32) public collections;
    // allows to iterate over records
    mapping(address => EnumerableSet.Bytes32Set) internal userCollections;

    // mapping for non-native original addresses to collection IDs;
    mapping(address => bytes32) public externalToCollection;

    SystemContext public systemContext;

    constructor(SystemContext systemContext_) {
        systemContext = systemContext_;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.getAccessControlList().checkRole(role_, msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRecordOwner(bytes32 collectionId_) {
        require(records[collectionId_].owner == msg.sender, "Ownable: caller is not the record owner");
        _;
    }

    modifier onlyFactoryRole() {
        AccessControlList acl = systemContext.getAccessControlList();
        acl.checkRole(acl.CONTRACT_FACTORY_ROLE(), msg.sender);
        _;
    }

    /**
     * @dev Adds a new record for a collection.
     * @param collectionId_ The new collection to set.
     * @param owner_ The address of the owner.
     * @param collectionAddress_ The address of the collection contract.
     */
    function registerCollection(
        bytes32 collectionId_, string calldata userName_, address owner_, address collectionAddress_,
        string calldata contractName_, uint16 contractVersion_
    ) onlyFactoryRole external virtual override {
        require(!recordExists(collectionId_), "Collection already exists");
        require(collections[collectionAddress_] == bytes32(0x0), "Address already in collection");
        _setOwner(collectionId_, owner_);
        _setAddress(collectionId_, collectionAddress_);
        records[collectionId_].userName = userName_;
        records[collectionId_].contractName = contractName_;
        records[collectionId_].contractVersion = contractVersion_;
        collections[collectionAddress_] = collectionId_;
        emit NewCollection(collectionId_, userName_, owner_, collectionAddress_, contractName_, contractVersion_);
    }

    /**
    * @dev Registers mapping from non-native address into collection.
     * @param collectionId_ Id of existing collection.
     * @param originalAddress_ The address of the original NFT contract.
     */
    function registerOriginalAddress(bytes32 collectionId_, address originalAddress_) onlyFactoryRole external virtual override {
        require(externalToCollection[originalAddress_] == bytes32(0), "External collection already registered");
        externalToCollection[originalAddress_] = collectionId_;
    }

    /**
     * @dev Transfers ownership of a collection to a new address. May only be called by the current owner of the node.
     * @param collectionId_ The collection to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(bytes32 collectionId_, address owner_) external virtual override onlyRecordOwner(collectionId_) {
        _setOwner(collectionId_, owner_);
        emit TransferOwnership(collectionId_, owner_);
    }

    /**
    * @dev Returns the address that owns the specified node.
    * @param collectionId_ The specified node.
    * @return address of the owner.
    */
    function ownerOf(bytes32 collectionId_) external virtual override view returns (address) {
        address addr = records[collectionId_].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
    * @dev Returns the collection address for the specified collection.
    * @param collectionId_ The specified collection.
    * @return address of the collection.
    */
    function addressOf(bytes32 collectionId_) external virtual override view returns (address) {
        return records[collectionId_].addr;
    }

    /**
    * @dev Returns whether a record has been imported to the registry.
    * @param collectionId_ The specified node.
    * @return Bool if record exists.
    */
    function recordExists(bytes32 collectionId_) public virtual override view returns (bool) {
        return records[collectionId_].owner != address(0x0);
    }

    struct RecordWithId {
        address addr;
        string name;
        bytes32 id;
    }

    /**
    * @dev Returns a list of owned user collections.
    * @param userAddress_ The specified user.
    * @return A list of RecordWithId
    */
    function listCollectionsPerOwner(address userAddress_) external view returns (RecordWithId[] memory) {
        bytes32[] memory _collectionIds = userCollections[userAddress_].values();
        RecordWithId[] memory _recordsResult = new RecordWithId[](_collectionIds.length);
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _recordsResult[i].addr = records[_collectionIds[i]].addr;
            _recordsResult[i].name = records[_collectionIds[i]].userName;
            _recordsResult[i].id = _collectionIds[i];
        }
        return _recordsResult;
    }

    function getCollectionIds(address[] memory collectionAddresses_) external view returns(bytes32[] memory) {
        bytes32[] memory _collectionIds = new bytes32[](collectionAddresses_.length);
        for(uint256 i = 0; i < _collectionIds.length; i++) {
            _collectionIds[i] = collections[collectionAddresses_[i]];
            if (_collectionIds[i] == bytes32(0)) {
                _collectionIds[i] = externalToCollection[collectionAddresses_[i]];
            }
        }

        return _collectionIds;
    }

    function _setOwner(bytes32 collectionId_, address owner_) internal virtual {
        address prevOwner = records[collectionId_].owner;
        if (prevOwner != address(0x0)) {
            userCollections[prevOwner].remove(collectionId_);
        }

        userCollections[owner_].add(collectionId_);
        records[collectionId_].owner = owner_;
    }

    function _setAddress(bytes32 collectionId_, address collectionAddress_) internal {
        records[collectionId_].addr = collectionAddress_;
    }

    function getRecord(bytes32 collectionId_) public view returns(Record memory) {
        return records[collectionId_];
    }

    function setSystemContext(SystemContext systemContext_) public onlyRole(systemContext.getAccessControlList().COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()) {
        systemContext = systemContext_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollectionRegistry {

    // Logged when new record is created.
    event NewCollection(bytes32 indexed collectionId, string name, address owner, address addr, string contractName, uint16 contractVersion);

    // Logged when the owner of a node transfers ownership to a new account.
    event TransferOwnership(bytes32 indexed collectionId, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(bytes32 indexed collectionId, address addr);

    function registerCollection(bytes32 collectionId_, string calldata name_, address owner_, address collectionAddress_, string calldata contractName_, uint16 contractVersion_) external;
    function registerOriginalAddress(bytes32 collectionId_, address originalAddress_) external;
    function setOwner(bytes32 collectionId_, address owner_) external;
    function ownerOf(bytes32 collectionId_) external view returns (address);
    function addressOf(bytes32 collectionId_) external view returns (address);
    function recordExists(bytes32 collectionId_) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LayerZeroBridge.sol";
import "./ContractFactory.sol";
import "./CollectionsRegistry.sol";
import "./AccessControlList.sol";
import "./OwnerVerifier.sol";
import "./SystemContextSubscribable.sol";

/**
 * @dev This contract stores information about system contract names
 *
 * Provides shared context for all contracts in our network
 */
contract SystemContext is SystemContextSubscribable {

    LayerZeroBridge internal bridgeContract;
    ContractFactory internal contractFactory;
    CollectionsRegistry internal collectionRegistry;
    AccessControlList internal accessControlList;
    OwnerVerifier internal ownerVerifier;
    uint16 public chainId;

    constructor (AccessControlList accessControlList_, uint16 chainId_) {
        accessControlList = accessControlList_;
        chainId = chainId_;
    }

    modifier onlyRole(bytes32 role_) {
        accessControlList.checkRole(role_, msg.sender);
        _;
    }

    function getBridge() external view returns(LayerZeroBridge) {
        return bridgeContract;
    }

    function setBridge(LayerZeroBridge bridgeContract_, bool triggerCallbacks) external onlyRole(accessControlList.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE()) {
        if (triggerCallbacks) {
            _handleAddressChange(address(bridgeContract), address(bridgeContract_));
        }

        bridgeContract = bridgeContract_;
        accessControlList.grantRole(accessControlList.BRIDGE_ROLE(), address(bridgeContract_));
    }

    function getContractFactory() external view returns(ContractFactory) {
        return contractFactory;
    }

    function setContractFactory(ContractFactory contractFactory_, bool triggerCallbacks) external onlyRole(accessControlList.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE()) {
        if (triggerCallbacks) {
            _handleAddressChange(address(contractFactory), address(contractFactory_));
        }

        contractFactory = contractFactory_;
        accessControlList.grantRole(accessControlList.CONTRACT_FACTORY_ROLE(), address(contractFactory_));
    }

    function getCollectionRegistry() external view returns(CollectionsRegistry) {
        return collectionRegistry;
    }

    function setCollectionRegistry(CollectionsRegistry collectionRegistry_, bool triggerCallbacks) external onlyRole(accessControlList.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE()) {
        if (triggerCallbacks) {
            _handleAddressChange(address(collectionRegistry), address(collectionRegistry_));
        }

        collectionRegistry = collectionRegistry_;
        accessControlList.grantRole(accessControlList.COLLECTION_REGISTRY_ROLE(), address(collectionRegistry_));
    }

    function getAccessControlList() external view returns(AccessControlList) {
        return accessControlList;
    }

    function setAccessControlList(AccessControlList accessControlList_, bool triggerCallbacks) external onlyRole(accessControlList.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE()) {
        if (triggerCallbacks) {
            _handleAddressChange(address(accessControlList), address(accessControlList_));
        }

        accessControlList = accessControlList_;
        accessControlList.grantRole(accessControlList.ACCESS_CONTROL_ROLE(), address(accessControlList_));
    }

    function getOwnerVerifier() external view returns(OwnerVerifier) {
        return ownerVerifier;
    }

    function setOwnerVerifier(OwnerVerifier ownerVerifier_, bool triggerCallbacks) external onlyRole(accessControlList.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE()) {
        if (triggerCallbacks) {
            _handleAddressChange(address(ownerVerifier), address(ownerVerifier_));
        }

        ownerVerifier = ownerVerifier_;
        accessControlList.grantRole(accessControlList.OWNER_VERIFIER_ROLE(), address(ownerVerifier_));
    }

    function setChainId(uint16 chainId_) external onlyRole(accessControlList.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE()){
        chainId = chainId_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./tokens/ERC721Mintable.sol";
import "./layer0/interfaces/ILayerZeroReceiver.sol";
import "./layer0/interfaces/ILayerZeroEndpoint.sol";
import "./SystemContext.sol";
import "./ContractFactory.sol";
import "./CollectionsRegistry.sol";

interface IBridge {

    enum Operation {
        CALL,
        DEPLOY,
        MULTI_CALL,
        ERC721_BRIDGE
    }

    struct Data {
        Operation operation;
        uint256 apiVersion;
        bytes rawData;
    }

    struct CallData {
        bytes32 collectionId;
        bytes packedData;
    }

    struct MultiCallData {
        address[] destinationContracts;
        bytes[] packedData;
    }

    struct DeployData {
        bytes32 bytecodeHash;
        bytes ctorParams;
        bytes32 collectionId;
        string collectionName;
        address owner;
    }

    event SendEvent(uint16 destChainId, bytes destBridge, uint64 nonce);
    event ReceiveEvent(uint16 chainId, bytes _fromAddress, uint64 nonce, Operation operation);
    event CallSuccess(uint16 indexed chainId, bytes indexed fromAddress, uint64 indexed nonce, address calledContract, bytes returnData, uint16 index);
    event CallFailed(uint16 indexed chainId, bytes indexed fromAddress, uint64 indexed nonce, address calledContract, uint16 index);
    event ContractDeployed(uint16 indexed chainId, bytes indexed fromAddress, uint64 indexed nonce, address newContract);
    event ContractNotDeployed(uint16 indexed chainId, bytes indexed fromAddress, uint64 indexed nonce);
    event UndefinedCall(uint16 indexed chainId, bytes indexed fromAddress, uint64 indexed nonce, Operation operation, uint256 apiVersion, bytes rawData);

    struct DeploymentParams {
        uint16 chainId;
        bytes bridgeAddress;
        bytes params;
        uint256 value;
    }
}

contract LayerZeroBridge is ILayerZeroReceiver, IBridge {
    using Address for address;

    // required: the LayerZero endpoint which is passed in the constructor
    ILayerZeroEndpoint public endpoint;
    SystemContext public systemContext;
    uint256 public apiVersion;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // required: the LayerZero endpoint
    constructor(ILayerZeroEndpoint endpoint_, SystemContext systemContext_) {
        endpoint = endpoint_;
        apiVersion = 0;
        systemContext = SystemContext(systemContext_);
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.getAccessControlList().checkRole(role_, msg.sender);
        _;
    }

    function setEndpoint(address endpoint_) external onlyRole(systemContext.getAccessControlList().BRIDGE_DEFAULT_ADMIN_ROLE()) {
        endpoint = ILayerZeroEndpoint(endpoint_);
    }

    function _handleCall(CallData memory callData, uint16 srcChainId, bytes memory fromAddress, uint64 nonce) internal returns (bytes memory) {
        address target = systemContext.getCollectionRegistry().addressOf(callData.collectionId);
        (bool success, bytes memory returnData) = target.call(callData.packedData);
        if (success) {
            emit CallSuccess(srcChainId, fromAddress, nonce, target, returnData, 0);
        } else {
            emit CallFailed(srcChainId, fromAddress, nonce, target, 0);
        }
        return returnData;
    }

    function _handleMultiCall(MultiCallData memory multiCallData, uint16 srcChainId, bytes memory fromAddress, uint64 nonce) internal returns (bytes[] memory) {
        bytes[] memory multipleReturnData = new bytes[](10);
        for (uint256 i = 0; i < multiCallData.destinationContracts.length; i++) {
            address target = multiCallData.destinationContracts[i];
            (bool success, bytes memory returnData) = target.call(multiCallData.packedData[i]);
            if (success) {
                emit CallSuccess(srcChainId, fromAddress, nonce, target, returnData, uint16(i));
                multipleReturnData[i] = returnData;
            } else {
                emit CallFailed(srcChainId, fromAddress, nonce, target, uint16(i));
                break;
            }
        }
        return multipleReturnData;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _deployNonNativeWrapper(DeployExternalParams memory deployData, bytes32 collectionId) internal {
        ContractFactory factory = systemContext.getContractFactory();
        factory.createContractInstanceByHash(
            deployData.wrapperBytecodeHash, abi.encode(systemContext, deployData.originalCollection), collectionId, deployData.collectionName, deployData.owner
        );
        factory.registerOriginalContract(collectionId, deployData.originalCollection);
    }

    function _handleDeploy(DeployData memory deployData, uint16 srcChainId, bytes memory fromAddress, uint64 nonce) internal {
        ContractFactory contractFactory = systemContext.getContractFactory();

        bytes memory rawCallData = abi.encodeWithSelector(
            contractFactory.createContractInstanceByHash.selector, deployData.bytecodeHash,
            deployData.ctorParams, deployData.collectionId, deployData.collectionName, deployData.owner
        );

        (bool success, bytes memory returnData) = address(contractFactory).call(rawCallData);
        if(success) {
            emit ContractDeployed(srcChainId, fromAddress, nonce, abi.decode(returnData, (address)));
        } else {
            emit ContractNotDeployed(srcChainId, fromAddress, nonce);
        }
    }

    function _handleUndefined(Data memory data, uint16 srcChainId, bytes memory fromAddress, uint64 nonce) internal {
        // some handler that error happened
        emit UndefinedCall(srcChainId, fromAddress, nonce, data.operation, data.apiVersion, data.rawData);
    }

    function handleAllEstimate(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        uint startGas = gasleft();
        _handleAll(_srcChainId, _fromAddress, _nonce, _payload);
        require(false, Strings.toString(startGas - gasleft()));
    }

    function _handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        Data memory data = abi.decode(_payload, (Data));

        emit ReceiveEvent(_srcChainId, _fromAddress, _nonce, data.operation);
        if (data.operation == Operation.CALL) {
            CallData memory callData = abi.decode(data.rawData, (CallData));
            _handleCall(callData, _srcChainId, _fromAddress, _nonce);
        } else if (data.operation == Operation.DEPLOY) {
            DeployData memory deployData = abi.decode(data.rawData, (DeployData));
            _handleDeploy(deployData, _srcChainId, _fromAddress, _nonce);
        } else if (data.operation == Operation.MULTI_CALL) {
            MultiCallData memory callData = abi.decode(data.rawData, (MultiCallData));
            _handleMultiCall(callData, _srcChainId, _fromAddress, _nonce);
        } else {
            _handleUndefined(data, _srcChainId, _fromAddress, _nonce);
        }
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function estimateLzReceiveGas(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload) external returns(string memory) {
        bool success;
        bytes memory revertMsg;
        (success, revertMsg) = address(this).call(abi.encodeWithSelector(this.handleAllEstimate.selector, _srcChainId, _fromAddress, _nonce, _payload));

        return _getRevertMsg(revertMsg);
    }


    // overrides lzReceive function in ILayerZeroReceiver.
    // automatically invoked on the receiving chain after the source chain calls endpoint.send(...)
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));

        _handleAll(_srcChainId, _fromAddress, _nonce, _payload);
    }

    function _sendMessageWithValue(uint16 chainId_, bytes calldata bridge_, bytes memory buffer_, address refundAddress_, uint256 value_, uint256 gasAmount_) internal {
        endpoint.send{value : value_}(
            chainId_,
            bridge_,
            buffer_,
            payable(refundAddress_),
            address(this),
            abi.encodePacked(uint16(1), uint256(gasAmount_))
        );

        emit SendEvent(chainId_, bridge_, endpoint.getOutboundNonce(chainId_, address(this)));
    }

    function _sendMessage(uint16 chainId_, bytes calldata bridge_, bytes memory buffer_, address refundAddress_, uint256 gasAmount_) internal {
        _sendMessageWithValue(chainId_, bridge_, buffer_, refundAddress_, msg.value, gasAmount_);
    }

    function mintOnTargetChainEncode(
        bytes32 collectionId_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) public view returns (bytes memory) {
        return abi.encode(
            Data({
                operation: Operation.CALL,
                apiVersion: apiVersion,
                rawData: abi.encode(CallData({
                    collectionId: collectionId_,
                    packedData: abi.encodeWithSelector(ITokenBridgeable.mintToWithUri.selector, owner_, mintId_, tokenUri_)
                }))
            })
        );
    }

    function mintOnTargetChain (
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) public payable {
        CollectionsRegistry registry = systemContext.getCollectionRegistry();
        bytes32 collectionId_ = registry.collections(msg.sender);
        require(collectionId_ != bytes32(0), "Only collection contract can call");
        _sendMessage(chainId_, bridge_, mintOnTargetChainEncode(collectionId_, owner_, mintId_, tokenUri_), refundAddress_, gasAmount_);
    }

    function callOnTargetChainEncode(bytes32 collectionId_, bytes calldata callData_) public view returns (bytes memory) {
        return abi.encode(
            Data({
                operation: Operation.CALL,
                apiVersion: apiVersion,
                rawData: abi.encode(CallData({collectionId: collectionId_, packedData: callData_}))
            })
        );
    }

    function callOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        bytes32 collectionId_,
        address refundAddress_,
        bytes calldata callData_,
        uint256 gasAmount_
    ) public payable {
        require(systemContext.getCollectionRegistry().addressOf(collectionId_) == msg.sender, "Only collection contract can call");
        _sendMessage(chainId_, bridge_, callOnTargetChainEncode(collectionId_, callData_), refundAddress_, gasAmount_);
    }

    function deployContractEncode(bytes32 bytecodeHash_, bytes32 collectionId_, bytes calldata ctorParams_, string calldata collectionName_, address owner_) public view returns (bytes memory) {
        return abi.encode(
            Data({
                operation: Operation.DEPLOY,
                apiVersion: apiVersion,
                rawData: abi.encode(DeployData({
                    bytecodeHash: bytecodeHash_,
                    ctorParams: ctorParams_,
                    collectionId: collectionId_,
                    collectionName: collectionName_,
                    owner: owner_
                }))
            })
        );
    }

    struct DeployExternalParams {
        bytes32 bytecodeHash;
        bytes32 wrapperBytecodeHash;
        address originalCollection;
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    function deployExternalCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable returns (bytes32) {
        bytes32 collectionId_ = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        // TODO check if `params.originalCollection` supports interface ERC721
        _deployNonNativeWrapper(params, collectionId_);

        uint256 totalValue = msg.value;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow
            require(deploymentParams_[i].chainId != systemContext.chainId(), "Cannot deploy locally");

            _sendMessageWithValue(
                deploymentParams_[i].chainId,
                deploymentParams_[i].bridgeAddress,
                deployContractEncode(params.bytecodeHash, collectionId_, deploymentParams_[i].params, params.collectionName, params.owner),
                params.refundAddress,
                deploymentParams_[i].value,
                params.gasAmount
            );
        }

        return collectionId_;
    }

    struct DeployNativeParams {
        bytes32 bytecodeHash;
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    function deployNativeCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) public payable returns (bytes32) {
        bytes32 collectionId_ = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        uint256 totalValue = msg.value;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow

            if(deploymentParams_[i].chainId == systemContext.chainId()) {
                systemContext.getContractFactory().createContractInstanceByHash(
                    params.bytecodeHash, deploymentParams_[i].params, collectionId_, params.collectionName, params.owner
                );
            } else {
                _sendMessageWithValue(
                    deploymentParams_[i].chainId,
                    deploymentParams_[i].bridgeAddress,
                    deployContractEncode(params.bytecodeHash, collectionId_, deploymentParams_[i].params, params.collectionName, params.owner),
                    params.refundAddress,
                    deploymentParams_[i].value,
                    params.gasAmount
                );
            }
        }
        return collectionId_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SystemContext.sol";
import "./AccessControlList.sol";
import "./interfaces/ICollectionRegistry.sol";

/**
 * @dev This contract enables creation of assets smart contract instances
 */
contract ContractFactory {
    event NewContractRegistered(bytes32 indexed hash, string name, bool isNative);
    event ContractVersionRegistered(bytes32 indexed hash, string name, uint16 version);

    mapping (bytes32 => bytes) public contractsBytecode;
    mapping (bytes32 => bool) public hashRegistered;
    mapping (bytes32 => string) public contractName;
    mapping (bytes32 => uint16) public contractVersion;

    mapping (string => bool) public contractNative;
    mapping (string => uint16) public latestContractVersion;
    SystemContext public systemContext;

    constructor(address systemContext_) {
        systemContext = SystemContext(systemContext_);
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.getAccessControlList().checkRole(role_, msg.sender);
        _;
    }

    modifier onlyBridgeRole() {
        AccessControlList acl = systemContext.getAccessControlList();
        acl.checkRole(acl.BRIDGE_ROLE(), msg.sender);
        _;
    }

    /**
    * @dev Registers a new whitelisted bytecode at its hash.
     * @param bytecode - contract bytecode to whitelist.
     * @param name - human readable name of contract.
     * @param isNative - if it is 'native' collection.
     */
    function registerNewContract(bytes memory bytecode, string memory name, bool isNative) external onlyRole(systemContext.getAccessControlList().CONTROL_LIST_ADMIN_ROLE()) {
        bytes32 hash = keccak256(bytecode);

        require(latestContractVersion[name] == 0 && !hashRegistered[hash], "Contract already registered");

        contractsBytecode[hash] = bytecode;
        hashRegistered[hash] = true;
        contractName[hash] = name;
        contractVersion[hash] = 1;
        contractNative[name] = isNative;
        latestContractVersion[name] = 1;

        emit NewContractRegistered(hash, name, isNative);
    }

    /**
    * @dev Registers a new version of whitelisted contract.
     * @param bytecode - contract bytecode to whitelist.
     * @param name - human readable name of contract.
     * @param version - next iterative version.
     */
    function registerNewVersionOfContract(bytes memory bytecode, string memory name, uint16 version) external onlyRole(systemContext.getAccessControlList().CONTROL_LIST_ADMIN_ROLE()) {
        bytes32 hash = keccak256(bytecode);

        require(latestContractVersion[name] != 0, "Contract doesn't exist");
        require(version == latestContractVersion[name] + 1, string(
                abi.encodePacked("Next '", name, "' should have version '", latestContractVersion[name] + 1, "'")
            ));
        require(keccak256(abi.encodePacked(contractName[hash])) == keccak256(abi.encodePacked(name)), string(
                abi.encodePacked("Contract '", name, "' registered with name '", contractName[hash], "'")
            ));

        contractsBytecode[hash] = bytecode;
        hashRegistered[hash] = true;
        contractName[hash] = name;
        contractVersion[hash] = version;
        latestContractVersion[name] = version;

        emit ContractVersionRegistered(hash, name, version);
    }

    /**
    * @dev Removes bytecode from whitelist.
     * @param bytecode - contract bytecode in whitelist.
     */
    function deregisterContact(bytes memory bytecode) external onlyRole(systemContext.getAccessControlList().CONTROL_LIST_ADMIN_ROLE()) {
        bytes32 hash = keccak256(bytecode);
        _deregisterContractByHash(hash);
    }

    /**
    * @dev Removes bytecode from whitelist using it's hash.
     * @param hash - hash of a contract bytecode in whitelist.
     */
    function deregisterContactByHash(bytes32 hash) external onlyRole(systemContext.getAccessControlList().CONTROL_LIST_ADMIN_ROLE()) {
        _deregisterContractByHash(hash);
    }

    // TODO make it smarter, in final version we can allow to remove only the last version or all contracts for particular name
    function _deregisterContractByHash(bytes32 hash) internal {
        delete contractsBytecode[hash];
        delete hashRegistered[hash];
        delete contractVersion[hash];
        delete latestContractVersion[contractName[hash]];
        delete contractNative[contractName[hash]];
        delete contractName[hash];
    }

    /**
    * @dev Deploys smart contract using given params.
     * @param bytecode - bytecode of a contract to deploy.
     * @param constructorParams - abi packed constructor params.
     * @param salt - data used to ensure that a new contract address is unique.
     */
    function _deploy(bytes memory bytecode, bytes memory constructorParams, bytes32 salt) internal returns(address) {
        bytes memory creationBytecode = abi.encodePacked(bytecode, constructorParams);

        address addr;
        assembly {
            addr := create2(0, add(creationBytecode, 0x20), mload(creationBytecode), salt)
        }

        require(isContract(addr), "Contract was not been deployed. Check contract bytecode and contract params");
        return addr;
    }

    /**
    * @dev Creates native contract instance for whitelisted byteCode.
     * @param bytecodeHash - hash of a contract bytecode.
     * @param constructorParams - encoded constructor params.
     * @param collectionId - unique collection identifier.
     * @param name - human readable collection name.
     * @param owner - owner of the collection.
     */
    function createContractInstanceByHash(bytes32 bytecodeHash, bytes memory constructorParams, bytes32 collectionId, string calldata name, address owner) external onlyBridgeRole returns(address) {
        require (hashRegistered[bytecodeHash], "Contract not registered");

        address newContract = _deploy(contractsBytecode[bytecodeHash], constructorParams, collectionId);

        if (contractNative[contractName[bytecodeHash]]) {
            systemContext.getAccessControlList().grantNativeTokenRole(newContract);
            _registerNativeToken(newContract, bytecodeHash, collectionId, name, owner);
        } else {
            systemContext.getAccessControlList().grantNonNativeTokenRole(newContract);
            _registerNonNativeToken(newContract, bytecodeHash, collectionId, name, owner);
        }
        return newContract;
    }

    function registerOriginalContract(bytes32 collectionId, address originalAddress) external onlyBridgeRole {
        systemContext.getCollectionRegistry().registerOriginalAddress(collectionId, originalAddress);
    }

    function _registerNonNativeToken(address newContract, bytes32 bytecodeHash, bytes32 collectionId, string calldata name, address owner) internal {
        systemContext.getCollectionRegistry().registerCollection(collectionId, name, owner, newContract, contractName[bytecodeHash], contractVersion[bytecodeHash]);
    }

    function _registerNativeToken(address newContract, bytes32 bytecodeHash, bytes32 collectionId, string calldata name, address owner) internal {
        systemContext.getCollectionRegistry().registerCollection(collectionId, name, owner, newContract,
            contractName[bytecodeHash], contractVersion[bytecodeHash]);
    }

    /**
     * @dev Returns True if provided address is a contract.
     * @param account Prospective contract address.
     * @return True if there is a contract behind the provided address.
     */
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract AccessControlList is AccessControlEnumerable {

    bytes32 public constant CONTROL_LIST_ADMIN_ROLE = keccak256("CONTROL_LIST_ADMIN_ROLE");
    bytes32 public constant BRIDGE_DEFAULT_ADMIN_ROLE = keccak256("BRIDGE_DEFAULT_ADMIN_ROLE");
    bytes32 public constant SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE = keccak256("SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE = keccak256("COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE");

    bytes32 public constant SYSTEM_CONTEXT_ROLE = keccak256("SYSTEM_CONTEXT_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant CONTRACT_FACTORY_ROLE = keccak256("CONTRACT_FACTORY_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_ROLE = keccak256("COLLECTION_REGISTRY_ROLE");
    bytes32 public constant ACCESS_CONTROL_ROLE = keccak256("ACCESS_CONTROL_ROLE");
    bytes32 public constant OWNER_VERIFIER_ROLE = keccak256("OWNER_VERIFIER_ROLE");
    bytes32 public constant NATIVE_TOKEN_ROLE = keccak256("NATIVE_TOKEN_ROLE");
    bytes32 public constant NON_NATIVE_TOKEN_ROLE = keccak256("NON_NATIVE_TOKEN_ROLE");

    constructor(address admin) {

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(CONTROL_LIST_ADMIN_ROLE, admin);
        _setupRole(SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ACCESS_CONTROL_ROLE, address(this));

        // CONTROL_LIST_ADMIN_ROLE is an admin of other administration roles
        _setRoleAdmin(SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(BRIDGE_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(SYSTEM_CONTEXT_ROLE, CONTROL_LIST_ADMIN_ROLE);

        // SYSTEM_CONTEXT_ROLE is an admin of other system contract roles
        _setRoleAdmin(BRIDGE_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(CONTRACT_FACTORY_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(COLLECTION_REGISTRY_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(ACCESS_CONTROL_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(OWNER_VERIFIER_ROLE, SYSTEM_CONTEXT_ROLE);

        // Contract factory is an admin of NATIVE_TOKEN_ROLE and NON_NATIVE_TOKEN_ROLE
        _setRoleAdmin(NATIVE_TOKEN_ROLE, CONTRACT_FACTORY_ROLE);
        _setRoleAdmin(NON_NATIVE_TOKEN_ROLE, CONTRACT_FACTORY_ROLE);
    }

    function checkRole(bytes32 role, address account) external view {
        return _checkRole(role, account);
    }

    function grantNativeTokenRole(address addr) external {
        grantRole(NATIVE_TOKEN_ROLE, addr);
    }

    function grantNonNativeTokenRole(address addr) external {
        grantRole(NON_NATIVE_TOKEN_ROLE, addr);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(CONTROL_LIST_ADMIN_ROLE){
        _setRoleAdmin(role, adminRole);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnerVerifier {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant OMNIPAD_ADMIN_ROLE = keccak256("OMNIPAD_ADMIN_ROLE");
    function isOwner(address contractAddress, address caller) public view returns (bool){
        return getOwnerOrEmpty(contractAddress) == caller
                || hasRole(contractAddress, caller, DEFAULT_ADMIN_ROLE)
                || hasRole(contractAddress, caller, OMNIPAD_ADMIN_ROLE);
    }

    function readOptional(address addr, bytes memory data) public view returns (bytes memory result) {
        bool success;
        bytes memory retData;
        (success, retData) = addr.staticcall(data);
        if (success) {
            return retData;
        } else {
            return abi.encode(0x0);
        }
    }

    function getOwnerOrEmpty(address addr) public view returns (address) {
        return bytesToAddress(readOptional(addr, abi.encodeWithSignature("owner()")));
    }

    function hasRole(address contractAddr, address caller, bytes32 role) public view returns (bool) {
        return toUint256(readOptional(contractAddr, abi.encodeWithSignature("hasRole(bytes32,address)", role, caller))) > 0;
    }

    function toUint256(bytes memory _bytes)
    internal
    pure
    returns (uint256 value) {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function bytesToAddress(bytes memory source) public pure returns (address addr) {
        assembly {
            addr := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SystemContextSubscribable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 internal subscriptionId = 0;
    mapping(address => EnumerableSet.UintSet) internal subscriptionIds;
    mapping(uint256 => bytes4) public callbackFunctions;
    mapping(uint256 => address) public callbackAddress;
    mapping(address => mapping(address => uint256)) public callbackRegistered;

    /**
    * @dev Adds a callback which will be called when `watchAddress` changes
    */
    function subscribeToAddressChange(address watchAddress, bytes4 callbackFunc) external {
        return _subscribeToAddressChange(msg.sender, watchAddress, callbackFunc);
    }

    /**
    * @dev Adds a callback which will be called when `watchAddress` changes - for internal contract purpose.
    */
    function _subscribeToAddressChange(address sender, address watchAddress, bytes4 callbackFunc) internal {
        require(callbackRegistered[sender][watchAddress] == 0, "Already subscribed");

        subscriptionIds[watchAddress].add(++subscriptionId);
        callbackFunctions[subscriptionId] = callbackFunc;
        callbackAddress[subscriptionId] = msg.sender;
        callbackRegistered[sender][watchAddress] = subscriptionId;
    }

    /**
    * @dev Removes a callback of `msg.sender` on address `watchAddress`
    */
    function removeSubscription(address watchAddress) external {
        _removeSubscription(msg.sender, watchAddress);
    }

    /**
    * @dev Removes a callback of `msg.sender` on address `watchAddress` - for internal contract purpose.
    */
    function _removeSubscription(address sender, address watchAddress) internal {
        uint256 id = callbackRegistered[sender][watchAddress];
        require(id != 0, "Not subscribed");

        subscriptionIds[sender].remove(id);
        delete callbackFunctions[id];
        delete callbackAddress[id];
        delete callbackRegistered[sender][watchAddress];
    }

    /**
    * @dev Calls all registered callbacks for a particular address `currentAddress`. Sets callbacks for `newAddress` as well.
    */
    function _handleAddressChange(address currentAddress, address newAddress) internal {
        EnumerableSet.UintSet storage ids = subscriptionIds[currentAddress];
        uint256 subscribedCnt = ids.length();
        for (uint256 i = 0; i < subscribedCnt; i++) {
            bytes4 subscribedSig = callbackFunctions[ids.at(i)];
            address subscriber = callbackAddress[ids.at(i)];
            subscriber.call(abi.encodeWithSelector(subscribedSig, newAddress));
            _subscribeToAddressChange(subscriber, newAddress, subscribedSig);
            _removeSubscription(subscriber, currentAddress);
        }
    }

    /**
    * @dev Returns ids of particular user subscriptions for address `watchedAddress`.
    */
    function subscriptionsForAddress(address watchedAddress) view external returns (uint256[] memory) {
        return subscriptionIds[watchedAddress].values();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../SystemContext.sol";
import "../interfaces/ITokenBridgeable.sol";

/**
 * @title ERC721Mintable
 * ERC721Mintable - ERC721 contract that allows to mint tokens
 */
contract ERC721Mintable is ERC721Enumerable, ITokenBridgeable {

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    address public owner;

    event Fallback(bytes data);

    SystemContext public system;

    modifier onlyBridgeRole() {
        system.getAccessControlList().checkRole(BRIDGE_ROLE, _msgSender());
        _;
    }

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_, address owner_, SystemContext system_) ERC721(name_, symbol_) {
        system = system_;
        owner = owner_;
    }

    /**
    * @dev Returns collection identifier`
     */
    function collectionId() public view override returns (bytes32) {
        return system.getCollectionRegistry().collections(address(this));
    }

    /**
     * @dev Mints a token to an address.
     * @param _to address of the future owner of the token
     * @param _tokenId new token id
     */
    function mintTo(address _to, uint256 _tokenId) public {
        if (system.getAccessControlList().hasRole(BRIDGE_ROLE, msg.sender)) {
            if (isOwner(address(this), _tokenId)) {
                this.transferFrom(address(this), _to, _tokenId);
            }
            else {
                _mint(_to, _tokenId);
            }
        } else {
            _validateMintForNonBridgeCaller(_tokenId);
            _mint(_to, _tokenId);
        }
    }

    /**
    * @dev Mints a token to an address.
     * @param _to address of the future owner of the token
     * @param _tokenId new token id
     * @param _tokenURI new token uri
     */
    function mintToWithUri(address _to, uint256 _tokenId, string memory _tokenURI) external override {
        mintTo(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
    * @dev override to add additional validation before minting the token when the caller is not the bridge
    */
    function _validateMintForNonBridgeCaller(uint256 tokenId) internal virtual {
    }

    /**
     * @dev Burns a token of msg.signer.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function moveTo(uint16 _l0ChainId, bytes calldata _destinationBridge, uint256 _tokenId, uint256 _gasAmount) external override payable {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        transferFrom(msg.sender, address(this), _tokenId);

        system.getBridge().mintOnTargetChain{value : msg.value}(_l0ChainId, _destinationBridge, msg.sender, msg.sender, _tokenId, _tokenURIs[_tokenId], _gasAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function isOwner(address _address, uint256 _tokenId) public view returns (bool){
        uint256 balance = balanceOf(_address);
        for (uint256 i = 0; i < balance; i++) {
            if (tokenOfOwnerByIndex(_address, i) == _tokenId) {
                return true;
            }
        }
        return false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
    * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    // the method which your contract needs to implement to receive messages
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroEndpoint {
    // the send() method which sends a bytes payload to a another chain
    function send(uint16 _chainId, bytes calldata _destination, bytes calldata _payload, address payable refundAddress, address _zroPaymentAddress,  bytes calldata txParameters ) external payable;

    function estimateFees(uint16 chainId, address userApplication, bytes calldata payload, bool payInZRO, bytes calldata adapterParams) external view returns (uint nativeFee, uint zroFee);

    function getInboundNonce(uint16 _chainId, bytes calldata _srcAddress) external view returns(uint64);
    function getOutboundNonce(uint16 _chainId, address _srcAddress) external view returns(uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

interface ITokenBridgeable {
    function collectionId() external returns(bytes32);
    function moveTo(uint16 _l0ChainId, bytes calldata _destinationBridge, uint256 _tokenId, uint256 _gasAmount) external payable;
    function mintToWithUri(address _to, uint256 _tokenId, string memory _tokenURI) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}