// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library AddressArrayUtils {
    function indexOf(address[] memory arr, address key) internal pure returns (int256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == key) return int256(i);
        }
        return -1;
    }

    function contains(address[] memory arr, address key) internal pure returns (bool) {
        return indexOf(arr, key) != -1;
    }

    function remove(address[] storage arr, address key) internal returns (bool) {
        int256 i = indexOf(arr, key);

        if (i == -1) return false;

        address[] memory temp = arr;
        arr[uint256(i)] = temp[temp.length - 1];
        arr.pop();

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library AddToBoolMapping {
    // mapping address => bool
    struct Map {
        address[] keys;
        mapping(address => bool) values;
        mapping(address => uint256) indexOf;
    }

    function get(Map storage map, address key) internal view returns (bool) {
        return map.values[key];
    }

    function getKeys(Map storage map) internal view returns (address[] memory) {
        return map.keys;
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(Map storage map, address key) internal {
        if (map.values[key]) return;

        // add address => true mapping to values
        map.values[key] = true;

        // add index of address to indexOf mapping
        map.indexOf[key] = map.keys.length;

        // add address to keys
        map.keys.push(key);
    }

    function unset(Map storage map, address key) internal {
        if (!map.values[key]) return;

        // remove from values
        delete map.values[key];

        // important backups
        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        // update indexOf last element
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        // remove from keys
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library AddToStrMapping {
    // mapping address => string
    struct Map {
        address[] keys;
        mapping(address => string) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (string memory) {
        return map.values[key];
    }

    function getKeys(Map storage map) internal view returns (address[] memory) {
        return map.keys;
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(Map storage map, address key, string memory val) internal {
        if (!map.inserted[key]) {
            // add index of address to indexOf mapping
            map.indexOf[key] = map.keys.length;

            // make value of address in inserted to true
            map.inserted[key] = true;

            // add address to keys
            map.keys.push(key);
        }

        // add address => true mapping to values
        map.values[key] = val;
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) return;

        // remove from values
        delete map.values[key];
        delete map.inserted[key];

        // important backups
        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        // update indexOf last element
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        // remove from keys
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Roles.sol";
import "./AddressArrayUtils.sol";
import "./AddToBoolMapping.sol";

error Contract__NotAdmin();
error Contract__NotDoctor();
error Contract__NotPatient();
error Contract__PendingDoctorApproval();
error Contract__DoctorPublicKeyMissing();

contract Contract {
    // using methods of Roles for Role struct in Roles
    using Roles for Roles.Role;
    using AddToBoolMapping for AddToBoolMapping.Map;
    using AddressArrayUtils for address[];

    struct MedicalRecord {
        address editor;
        address[] viewers;
        string key_data_hash;
    }

    struct Admin {
        address user;
        string public_key;
        AddToBoolMapping.Map pending_doctors;
    }

    struct Patients {
        Roles.Role users;
        mapping(address => MedicalRecord) records;
    }

    struct Doctors {
        Roles.Role users;
        mapping(address => string) public_keys;
        mapping(address => AddToBoolMapping.Map) docToPatAccess;
    }

    // defining roles - contains hashes
    Admin private admin;
    Doctors private doctors;
    Patients private patients;

    // Initializing admin
    constructor() {
        admin.user = msg.sender;
    }

    // Admin methods
    function getAdmin() public view returns (address) {
        return admin.user;
    }

    function isAdmin(address _address) public view returns (bool) {
        if (admin.user == _address) return true;
        return false;
    }

    function setAdminPubKey(string memory _public_key) public onlyAdmin {
        admin.public_key = _public_key;
    }

    function getAdminPubKey() public view returns (string memory) {
        return admin.public_key;
    }

    // Doctor methods
    function isDoctorRegistered(address _address) public view returns (bool) {
        return doctors.users.has(_address);
    }

    function isPendingDoctor(address _address) public view returns (bool) {
        return admin.pending_doctors.get(_address);
    }

    function isDoctor(address _address) public view returns (bool) {
        if (!doctors.users.has(_address)) return false;
        if (admin.pending_doctors.get(_address)) return false;
        if (bytes(doctors.public_keys[_address]).length == 0) return false;
        return true;
    }

    function addDoctor(string memory _hash) public {
        if (isPatient(msg.sender)) revert("Contract: Address already registered as patient");
        if (bytes(_hash).length == 0) revert("Contract: Empty hash is not allowed!");
        doctors.users.add(msg.sender, _hash);
        admin.pending_doctors.set(msg.sender);
    }

    function approveDoctor(address _address) public onlyAdmin {
        if (isDoctor(_address)) return;
        if (!doctors.users.has(_address)) return;
        admin.pending_doctors.unset(_address);
    }

    function confirmAddDr(string memory _public_key) public {
        if (bytes(_public_key).length == 0) revert("Contract: Empty public key is not allowed!");
        if (!doctors.users.has(msg.sender)) revert Contract__NotDoctor();
        if (admin.pending_doctors.get(msg.sender)) revert Contract__PendingDoctorApproval();
        doctors.public_keys[msg.sender] = _public_key;
    }

    function setDrHash(string memory _hash) public onlyDoctor {
        if (bytes(_hash).length == 0) revert("Contract: Empty hash is not allowed!");
        doctors.users.setHash(msg.sender, _hash);
    }

    function getDrHash(address _address) public view returns (string memory) {
        if (!isDoctorRegistered(_address)) revert Contract__NotDoctor();
        return doctors.users.getHash(_address);
    }

    function getDrPubKey(address _address) public view returns (string memory) {
        return doctors.public_keys[_address];
    }

    function getAllDrs() public view returns (address[] memory) {
        return doctors.users.getMembers();
    }

    function getPendingDrs() public view returns (address[] memory) {
        return admin.pending_doctors.keys;
    }

    function getDocPats() public view onlyDoctor returns (address[] memory) {
        return doctors.docToPatAccess[msg.sender].keys;
    }

    // Patient methods
    function isPatient(address _address) public view returns (bool) {
        return patients.users.has(_address);
    }

    function addPatient(string memory _hash, string memory _key_data_hash) public {
        if (isDoctorRegistered(msg.sender) || isDoctor(msg.sender))
            revert("Contract: Address already registered as doctor");
        if (bytes(_hash).length == 0) revert("Contract: Empty hash is not allowed");
        patients.users.add(msg.sender, _hash);
        patients.records[msg.sender].key_data_hash = _key_data_hash;
    }

    function setPatGeneralHash(string memory _hash) public onlyPatient {
        patients.users.setHash(msg.sender, _hash);
    }

    function getPatGeneralHash(address _address) public view returns (string memory) {
        if (!isPatient(_address)) revert Contract__NotPatient();

        if (
            msg.sender == _address ||
            patients.records[_address].editor == msg.sender ||
            patients.records[_address].viewers.indexOf(msg.sender) != -1
        ) return patients.users.getHash(_address);

        revert("Not Allowed");
    }

    function setPatRecordHash(address _address, string memory _hash) public {
        if (!isPatient(_address)) revert Contract__NotPatient();
        if (!(msg.sender == _address || patients.records[_address].editor == msg.sender))
            revert("Not Allowed");
        patients.records[_address].key_data_hash = _hash;
    }

    function getPatRecordHash(address _address) public view returns (string memory) {
        if (!isPatient(_address)) revert Contract__NotPatient();

        if (
            msg.sender == _address ||
            patients.records[_address].editor == msg.sender ||
            patients.records[_address].viewers.indexOf(msg.sender) != -1
        ) return patients.records[_address].key_data_hash;

        revert("Not Allowed");
    }

    function getAllPats() public view returns (address[] memory) {
        return patients.users.getMembers();
    }

    function changeEditorAccess(address _address) public onlyPatient {
        // pending update - when user changes access, symmetric key S must be changed
        if (!isDoctor(_address)) revert Contract__NotDoctor();

        // remove old editor access
        address old_editor = patients.records[msg.sender].editor;
        doctors.docToPatAccess[old_editor].unset(msg.sender);

        // add new editor access
        patients.records[msg.sender].editor = _address;
        doctors.docToPatAccess[_address].set(msg.sender);
    }

    function removeEditorAccess() public onlyPatient {
        address old_editor = patients.records[msg.sender].editor;
        patients.records[msg.sender].editor = address(0);
        doctors.docToPatAccess[old_editor].unset(msg.sender);
    }

    function getPatDr() public view onlyPatient returns (address) {
        return patients.records[msg.sender].editor;
    }

    function grantViewerAccess(address _address) public onlyPatient {
        if (!isDoctor(_address)) revert Contract__NotDoctor();

        if (!patients.records[msg.sender].viewers.contains(_address)) {
            patients.records[msg.sender].viewers.push(_address);
        }
    }

    function revokeViewerAccess(address _address) public onlyPatient {
        // pending update - when user revokes access, symmetric key S must be changed
        if (!isDoctor(_address)) revert Contract__NotDoctor();

        patients.records[msg.sender].viewers.remove(_address);
    }

    function getPatViewers() public view onlyPatient returns (address[] memory) {
        return patients.records[msg.sender].viewers;
    }

    // modifiers
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert Contract__NotAdmin();
        _;
    }

    modifier onlyDoctor() {
        if (!doctors.users.has(msg.sender)) revert Contract__NotDoctor();
        if (admin.pending_doctors.get(msg.sender)) revert Contract__PendingDoctorApproval();
        if (bytes(doctors.public_keys[msg.sender]).length == 0)
            revert Contract__DoctorPublicKeyMissing();
        _;
    }

    modifier onlyPatient() {
        if (!isPatient(msg.sender)) revert Contract__NotPatient();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AddToStrMapping.sol";

library Roles {
    using AddToStrMapping for AddToStrMapping.Map;

    // This is to keep track of roles
    // Reduces searching cost
    struct Role {
        AddToStrMapping.Map bearer;
    }

    function add(Role storage role, address account, string memory hash) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer.set(account, hash);
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer.remove(account);
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return bytes(role.bearer.get(account)).length != 0;
    }

    function setHash(Role storage role, address account, string memory _hash) internal {
        role.bearer.set(account, _hash);
    }

    function getHash(Role storage role, address account) internal view returns (string memory) {
        return role.bearer.get(account);
    }

    function getMembers(Role storage role) internal view returns (address[] memory) {
        return role.bearer.keys;
    }
}