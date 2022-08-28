// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/INFTicket.sol";
import "./interfaces/INFTCert.sol";
import "./libs/NFTCertLib.sol";
import "./libs/StringLib.sol";

contract NFTCert is INFTCert, Ownable, AccessControl {

    using EnumerableSet for EnumerableSet.AddressSet;
    using StringLib for string;

    using NFTCertLib for NFTCertLib.CertsAggregation;
    
    // Core storage data
    NFTCertLib.CertsAggregation certsAggre;
    EnumerableSet.AddressSet private _whitelistSet;


    // Roles
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    // Enums
    mapping(string => bool) public locations;
    mapping(string => bool) public energyTypes;

    event consumePayload(DataSchema);
    event consumeConsumedRecord(ConsumedRecord[]);
    event consumeConsumedPayload(DataRecords);
        
    event consumeEnergyRequest(EnergyRequest);
    event receivedEnergyRequests(EnergyRequest[], uint);
    event deserializeData(string[]);


    constructor() {
        setDefaultVals();
    }

    function registerCerts(EnergyCertInput[] calldata certInputs) external override {
        
        require(_whitelistSet.contains(msg.sender), "Unauthorized Access");

        for (uint i=0; i < certInputs.length; i++) {
            EnergyCertInput calldata certInput = certInputs[i];

            require(locations[certInput.location], "location is not valid.");
            require(energyTypes[certInput.energyType], "energyType is not valid.");
            
            certsAggre.storeCert(certInput);
        }
    }

    /**
        add a consumer for using func consumeEnergy
     */
    function addEnergyConsumer(address consumer) external onlyOwner {
        _setupRole(CONSUMER_ROLE, consumer);
    }

    /*
    *     DataRecords - generic payload coming from NFTicket
    *     DataRecords is translated to local structure
    *     struct EnergyCerts {}
    *      to consume energy in this contract
    */
    ConsumedRecord[] allConsumedRecords;


    /********************
    * 
    * @notice deserialize an array of EnergyRequest[] having been packaged as struct DataRecord 
    * @param DataRecords calldata callDataEnergyRequests
    * @return EnergyRequest[] an array of EnergyRequest
    *
    * enum eDataType{_UNDEF, _UINT,_UINT256,U_STRING}
    * EnergyRequest serialization :
    *  keys = ["location", "energyType", "consumeAmount"];

        eDataType[0] = eDataType._USTRING
        eDataType[1] = eDataType._USTRING
        eDataType[2] = eDataType._UINT

        struct EnergyRequest {
            string location;
            string energyType;
            uint32 consumeAmount; // kWh in Wei
        }
    **********************/
    function deserializeEnergyRequest(DataRecords calldata callDataEnergyRequests)
    internal 
    returns(EnergyRequest[] memory) {

        require(callDataEnergyRequests._schema.size == 3, "energyRequests require three elements");
        string memory cDER = callDataEnergyRequests._schema.keys[0];
        require(keccak256(bytes(cDER)) == keccak256(bytes("location")), "energyRequests first key is not location");
        require(callDataEnergyRequests._data.length > 0, "DataRecords string array is empty");

        uint32 size = callDataEnergyRequests._schema.size;
        uint32 length = uint32(callDataEnergyRequests._data.length);
        EnergyRequest[] memory _ret = new EnergyRequest[](length / size);
        EnergyRequest memory _e;
        uint32 j = 0;
        /****************
        *
        * _data is a "flattened" array of arrays: 
        * each Record is represented by 
        *   $_schema.size attributes/columns each
        * resulting in a 
        *   total of $_schema.size * $_data.length strings 
        *       for actual 
        *   $_data.length data records.
        * e.g. ["FRANCE", "WIND", "200","UK","SOLAR","100"] for 
        * two ( = _data.length ) energyRequests with 3 ( = _schema.size) attributes each
        *   1) ["FRANCE", "WIND", "200"]
        *   2) ["UK","SOLAR","100"]
        *
        *****************/
        for(uint32 i = 0; i < ( length / size); i++)
        {
            // uint32 amount = stringToUint(callDataEnergyRequests._data[j + 2]);
            uint256 amount = uint256(callDataEnergyRequests._data[j + 2].stringToUint());
           _e = EnergyRequest(callDataEnergyRequests._data[j],callDataEnergyRequests._data[j + 1], amount);
           emit consumeEnergyRequest(_e);
           j = j + size;
           _ret[i] = _e;
        }
        return(_ret);
        
    }

    function consumeCredits(Ticket memory _ticket, uint256 credits, DataRecords calldata callDataEnergyRequests) 
    external 
    override 
    onlyRole(CONSUMER_ROLE) 
    returns(uint256 creditsConsumed, DataRecords memory) {
    
        creditsConsumed = 0; // TODO
        EnergyRequest[] memory energyReqs = deserializeEnergyRequest(callDataEnergyRequests);
        emit receivedEnergyRequests(energyReqs, energyReqs.length);
        ConsumedRecord[] memory consumed = consumeEnergy(energyReqs);
        DataRecords memory payloadConsumerRecords = certsAggre.serializeConsumedRecords(consumed);
        emit consumeConsumedRecord(consumed);
        emit consumeConsumedPayload(payloadConsumerRecords);
        creditsConsumed = credits; // we take all remaining credits as the price for the energy Certs
        return (creditsConsumed, payloadConsumerRecords);
    }

    function consumeEnergy(EnergyRequest[] memory energyReqs) 
    internal returns(ConsumedRecord[] memory) {
        delete allConsumedRecords;

        for (uint i=0; i < energyReqs.length; i++) {
            EnergyRequest memory req = energyReqs[i];
            require(locations[req.location], "location is not valid.");
            require(energyTypes[req.energyType], "energyType is not valid.");

            ConsumedRecord[] memory records = certsAggre.consumeEnergy(req);

            for (uint j=0; j < records.length; j++) {
                allConsumedRecords.push(records[j]);
            }
        }

        return allConsumedRecords;
    }

    function consumedRecords() external override view returns(ConsumedRecord[] memory, uint)  {
        return certsAggre.consumedRecordsInLastTransaction();
    }

    function currentConsumeId(string calldata location, string calldata energyType) external view returns(uint) {
        return certsAggre.currentConsumeId(location, energyType);
    }

    function readRemainEnergy(string calldata location, string calldata energyType) external view returns(uint) {
        return certsAggre.readRemainEnergy(location, energyType);
    }

    /**
        add enum for energyTypes
     */
    function addEnergyType(string memory key) external onlyOwner {
        key = key.toUpper();
        require(energyTypes[key] != true, "This energy type already exists.");
        energyTypes[key] = true;
    }

    /**
        add enum for locations
     */
    function addLocation(string memory key) external onlyOwner {
        key = key.toUpper();
        require(locations[key] != true, "This location already exists.");
        locations[key] = true;
    }

    function energyUnit() external pure returns (string memory) {
        return "wh";
    }

    function setDefaultVals() private {
        energyTypes["SOLAR"] = true;
        energyTypes["WIND_ONSHORE"] = true;
        energyTypes["WIND_OFFSHORE"] = true;
        energyTypes["HYDRO_ENERGY"] = true;
        energyTypes["GEOTHERMAL"] = true;
        energyTypes["BIOMASS"] = true;
        energyTypes["RENEWABLE"] = true;

        locations["AFRICA"] = true;
        locations["CONTINENTAL_EUROPE"] = true;
        locations["EAST_ASIA"] = true;
        locations["EASTERN_CENTRAL_EUROPE"] = true;
        locations["LATIN_AMERICA"] = true;
        locations["MEDITERRANEAN_EUROPE"] = true;
        locations["MIDDLE_EAST"] = true;
        locations["NORTH_AMERICA"] = true;
        locations["SCANDINAVIA"] = true;
        locations["SOUTH_ASIA"] = true;
        locations["SOUTH_EAST_ASIA"] = true;
        locations["NIS_RUSSA"] = true;
        locations["NORTH_ASIA"] = true;
        locations["AUSTRALIA_NEW_ZEALAND_POLYNESIA"] = true;   
    }

    function addWhitelist(address _address)
        external
        override
        onlyOwner
    {
        _whitelistSet.add(_address);
    }

    function removeWhitelist(address _address)
        external
        override
        onlyOwner
    {
        _whitelistSet.remove(_address);
    }

    function inWhitelist(address _address)
        external
        view
        override
        returns (bool)
    {
        return _whitelistSet.contains(_address);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTServiceTypes.sol";   
/**
 * Interface of NFTicket
 */

 
interface INFTicket {
    function mintNFTicket(Ticket memory _ticket, buyNFTicketParams memory params)
        external
        payable 
        returns (uint256, uint256, uint256);
    function getTicketData(uint256 _ticketID) external returns(Ticket memory);
    function updateTicketData(uint256 _ticketID, Ticket memory _t) external returns(bool);
    function registerServiceProvider(address serviceProvider, bytes4 serviceDescriptor) 
        external returns(uint16 status);
    function registerResellerServiceProvider(address serviceProvider, address reseller)
        external returns(uint16 status); 
    function consumeCredits(address _a, uint256 _tokenID, uint256 credits, DataRecords calldata _eR) 
        external 
        returns(uint256 creditsConsumed, uint256 creditsRemain, DataRecords memory);
    
    function inWhitelist(address _address) external view returns (bool);
    function addWhitelist(address _address) external;
    function removeWhitelist(address _address) external;


}


/***********************************************
*
* generic schematizable data payload
* allows for customization between reseller and
* service operator while keeping NFTicket agnostic
*
 ***********************************************/

enum eDataType{_UNDEF, _UINT, _UINT256, _USTRING}

struct DataSchema {
    string name;
    uint32 size;
    string [] keys;
    eDataType [] keyTypes;
}

struct DataRecords {
    DataSchema _schema;
    string[] _data; // a one-dimensional array of length [_schema.size * <number of records> ]
}

/************************
*
* NFTicket manages the ticket accounts for each of 
* the Service Providers using the protocol
*
*************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INFTicket.sol";

// Owner: Agent
interface INFTCert {
    function inWhitelist(address _address) external view returns (bool);
    function addWhitelist(address _address) external;
    function removeWhitelist(address _address) external;
    function registerCerts(EnergyCertInput[] calldata certInputs) external;
    function consumedRecords() external view returns(ConsumedRecord[] memory, uint);
    function consumeCredits(Ticket memory ticket, uint256 creditsBefore, DataRecords calldata dataRecords) 
        external returns (uint256 creditsConsumed, DataRecords memory);
}

enum certDataType{_energyRequest,_consumedRecord,_allocation}

/********************
*
* for serialization :
*
*
*  enum eDataType{_UNDEF, _UINT, _UINT256, _USTRING}
*  keys = ["certID, "energyType", "location", "amount"];
*  eDataType[0] = eDataType._UINT
*  eDataType[1] = eDataType._USTRING
*  eDataType[2] = eDataType._USTRING
*  eDataType[3] = eDataType._UINT
*
**********************/

struct ConsumedRecord {
    uint32 certId;
    string energyType;
    string location;
    uint256 amount;
}

/********************
*
* for serialization :
*  keys = ["location", "energyType", "consumeAmount"];
*  eDataType[0] = eDataType._USTRING
*  eDataType[1] = eDataType._USTRING
*  eDataType[2] = eDataType._UINT
*
**********************/
struct EnergyRequest {
  string location;
  string energyType;
  uint256 consumeAmount; // Watt
}


struct EnergyCertInput {
    string certId;
    string issuer;
    string URI;
    string energyType;
    string location;
    uint32 amount; // TODO make uint256
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INFTCert.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library NFTCertLib {

    using SafeMath for uint;
    event deserializeData(string[]);


    struct CertsAggregation {
        // location -> energyType -> certsBucket
        mapping(string => mapping(string => CertsBucket)) source;
        ConsumedRecord[] consumedRecords; // for consumeEnergy transaction
    }

    struct CertsBucket {
        uint32 idCounter;
        uint256 total;
        uint256 remainTotal;
        uint32 currentConsumedCertId;
        mapping(uint => EnergyCert) certs; // key: cert id
    }

    struct EnergyCert {
        uint32 id; // start: 1
        string certId;
        string issuer;
        string URI;
        string energyType;
        string location;
        uint256 amount;
        uint256 remainAmount;
    }

    /**
        CertsAggregation - methods
     */
    function storeCert(CertsAggregation storage certsAggre, EnergyCertInput calldata certInput) internal {
        // validate
        require(certInput.amount > 0, "cert amount must be more than 0.");
        require(bytes(certInput.issuer).length > 0, "issuer is required.");

        // find bucket to store cert
        CertsBucket storage certsBucket = certsAggre.source[certInput.location][certInput.energyType];
        certsBucket.idCounter += 1;

        // set values to cert
        EnergyCert memory cert = EnergyCert({
            id: certsBucket.idCounter,
            certId: certInput.certId,
            issuer: certInput.issuer,
            URI: certInput.URI,
            energyType: certInput.energyType,
            location: certInput.location,
            amount: certInput.amount,
            remainAmount: certInput.amount
        });

        // store cert
        certsBucket.certs[cert.id] = cert;

        // sync total
        certsBucket.total += cert.amount;
        certsBucket.remainTotal += cert.amount;

        // check start consumed cert id
        if (certsBucket.currentConsumedCertId == 0) {
            certsBucket.currentConsumedCertId = cert.id;
        }
    }
    


    function serializeConsumedRecords(CertsAggregation storage certsAggre, ConsumedRecord[] memory _consumedRecord) 
    internal
    returns(DataRecords memory) {
        /********************
        * ConsumedRecord serialization :
        *  keys = ["certId","energyType","location","amount"];
        *  eDataType[0] = eDataType._UINT
        *  eDataType[1] = eDataType._USTRING
        *  eDataType[2] = eDataType._USTRING
        *  eDataType[3] = eDataType._UINT
        struct ConsumedRecord {
            uint32 certId;
            string energyType;
            string location;
            uint32 amount;
        }
        **********************/

        DataRecords memory retPayloadConsumerRecords;
        DataSchema memory schema;
        schema.name = "ConsumedRecord" ;
        schema.size = 4;

        string[] memory keys = new string[](4);
        keys[0] = "certId";
        keys[1] = "energyType";
        keys[2] = "location";
        keys[3] = "amount";
        eDataType[] memory keyTypes = new eDataType[](4);
        keyTypes[0] = eDataType._UINT;
        keyTypes[1] = eDataType._USTRING;
        keyTypes[2] = eDataType._USTRING;
        keyTypes[3] = eDataType._UINT;

        schema.keys = keys;
        schema.keyTypes = keyTypes;

        /*
        struct DataSchema {
            string name;
            uint size;
            string [] keys;
            eDataTpe [] keyTypes;
        }
        */
        /**
        struct ConsumedRecord {
            uint32 certId;
            string energyType;
            string location;
            uint32 amount;
        }
         */
         // we will always use uint32 for serialized numbers in DataRecords
                 

        retPayloadConsumerRecords._data = new string[](_consumedRecord.length * schema.size);
        uint j = 0;
        for(uint i = 0; i < _consumedRecord.length; i++ ) {
            // write certID into a byteBuffer of sizeOfUint(32) (= 4 Bytes)
            string memory uint32String = Strings.toString(_consumedRecord[i].certId);            
            retPayloadConsumerRecords._data[j++]  = uint32String;
            retPayloadConsumerRecords._data[j++]  = _consumedRecord[i].energyType;
            retPayloadConsumerRecords._data[j++]  = _consumedRecord[i].location;
            uint32String = Strings.toString(_consumedRecord[i].amount);
            retPayloadConsumerRecords._data[j++]  = uint32String;
        }
        retPayloadConsumerRecords._schema = schema;
        return retPayloadConsumerRecords;
    }

    function consumeEnergy(CertsAggregation storage certsAggre, EnergyRequest memory energyReq) internal returns (ConsumedRecord[] memory) {
       delete certsAggre.consumedRecords;

        // get main data
        CertsBucket storage certsBucket = certsAggre.source[energyReq.location][energyReq.energyType];

        // validate
        require(certsBucket.remainTotal >= energyReq.consumeAmount, "remain amount in this location/energyType is not enough for this request.");

        // consume process
        while(energyReq.consumeAmount > 0) {
            EnergyCert storage currCert = certsBucket.certs[certsBucket.currentConsumedCertId];

            // consume it up & next cert
            if (energyReq.consumeAmount > currCert.remainAmount) {
                certsAggre.consumedRecords.push(ConsumedRecord({
                    certId: currCert.id,
                    energyType: currCert.energyType,
                    location: currCert.location,
                    amount: currCert.remainAmount
                }));
                energyReq.consumeAmount -= currCert.remainAmount;
                certsBucket.remainTotal -= currCert.remainAmount;
                currCert.remainAmount = 0;
                certsBucket.currentConsumedCertId++;
                continue;
            }

            // consume part of energy in this cert
            certsAggre.consumedRecords.push(ConsumedRecord({
                    certId: currCert.id,
                    energyType: currCert.energyType,
                    location: currCert.location,
                    amount: energyReq.consumeAmount
                }));
            currCert.remainAmount -= energyReq.consumeAmount;
            certsBucket.remainTotal -= energyReq.consumeAmount;
            energyReq.consumeAmount = 0;
        }

        return certsAggre.consumedRecords;
    }

    function currentConsumeId(CertsAggregation storage certsAggre, string calldata location, string calldata energyType) internal view returns (uint32) {
        return certsAggre.source[location][energyType].currentConsumedCertId;
    }

    function readRemainEnergy(CertsAggregation storage certsAggre, string calldata location, string calldata energyType) internal view returns (uint256) {
        return certsAggre.source[location][energyType].remainTotal;
    }

    function consumedRecordsInLastTransaction(CertsAggregation storage certsAggre) internal view returns(ConsumedRecord[] memory, uint) {
        return (certsAggre.consumedRecords, certsAggre.consumedRecords.length);
    }

    function decimals() internal pure returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringLib {
    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Lowercase character...
            if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 122)) {
                // So we subtract 32 to make it uppercase
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        return string(bUpper);
    }

        function stringToUint(string memory s) internal returns (uint32 result) {
        bytes memory b = bytes(s);
        uint i;
        uint32 ii;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                ii = uint32(c);
                result = result * 10 + (ii - 48);
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
    pragma solidity ^0.8.7;

    bytes4 constant POWER = 0x01000000; // 0b1.00000000.00000000.00000000
    bytes4 constant MOBILITY = 0x02000000; // 0b2.00000000.00000000.00000000
    bytes4 constant THG = 0x01010000; //  POWER & 0x01.00
    bytes4 constant REC = 0x01020000; // POWER & 0x02.00
    bytes4 constant CPO = 0x01030000; // POWER & 0x03.00
    bytes4 constant NRVERSE = 0x01000100; // POWER & 0x0100
    bytes4 constant eQUOTA = 0x01000200;
    bytes4 constant MITTWEIDA = 0x02010000;
    bytes4 constant NIGERIA = 0x02020000;
    bytes4 constant DutchMaaS = 0x02030000;
    bytes4 constant TIER_MW = 0x02010100;
    bytes4 constant SCOOTER = 0x00000001;
    bytes4 constant eBIKE = 0x00000002;
    bytes4 constant TAXI = 0x00000003;
    bytes4 constant CARSHARE = 0x00000004;
    bytes4 constant PUBLIC = 0x00000005;
    bytes4 constant RAIL = 0x00000006;

    struct Ticket {
        uint256 tokenID;
        address providerContract; // the index to the map where we keep info about serviceProviders
        address issuedTo;
        bytes4 serviceDescriptor;
        uint256 credits;
        uint256 pricePerCredit;
        uint256 serviceFee;
        uint256 resellerFee;
        uint256 transactionFee;
    }

    struct buyNFTicketParams {
        address reseller;
        address serviceProvider;
        address issuer;
        uint256 _value;
        uint256 credits;
        address recipient;
        string tokenURI;
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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