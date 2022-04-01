/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0
// Contract practiced by 108820003, NTUT.
pragma solidity ^0.8;

contract Student {
    // The Strut of the student profile.
    struct StudentProfile {
        address account;
        string id;
        string phone;
        string email;
    }

    // The owner of this contract.
    address immutable private _owner;

    // Stores all student profiles.
    StudentProfile[] private _profiles;

    // A map that stores the index of the student profile corresponding to the unique account address in its storage array (_profiles).
    mapping (address => uint) private _profileAccountIndexes;

    // A map that stores the index of the student profile corresponding to the unique user ID in its storage array (_profiles).
    mapping (string => uint) private _profileIdIndexes;

    constructor() {
        // setup the contract owner.
        _owner = msg.sender;
    }

    // modifier to check if caller is the contract owner.
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    // Record the index of the student profile corresponding to the unique account address in its storage array.
    function _saveAccountIndex(uint index, address account) private {
        _profileAccountIndexes[account] = index;
    }

    // Record the index of the student profile corresponding to the unique user ID in its storage array.
    function _saveIdIndex(uint index, string calldata id) private {
        _profileIdIndexes[id] = index;
    }

    // Use the given account address to find the index of its corresponding student profile's array index.
    // Note that the returned index starts from 1 here.
    function getIndexByAccount(address account) public view returns (uint) {
        return _profileAccountIndexes[account];
    }

    // Use the given user ID to find the index of its corresponding student profile's array index.
    // Note that the returned index starts from 1 here.
    function getIndexById(string calldata id) public view returns (uint) {
        return _profileIdIndexes[id];
    }

    // To get the student profile by its array index.
    // Note that the index starts from 0 here.
    function getProfileByIndex(uint index) public view returns (address account, string memory id, string memory phone, string memory email) {
        StudentProfile memory expectedProfile = _profiles[index];
        account = expectedProfile.account;
        id = expectedProfile.id;
        phone = expectedProfile.phone;
        email = expectedProfile.email;
    }

    // To get the student profile by its user ID.
    function getProfileById(string calldata targetId) public view returns (address account, string memory id, string memory phone, string memory email) {
        uint index = getIndexById(targetId);
        require(index != 0);
        return getProfileByIndex(index - 1);
    }

    // To get the student profile by its account address.
    function getProfileByAccount(address _account) public view returns (address account, string memory id, string memory phone, string memory email) {
        uint index = getIndexByAccount(_account);
        require(index != 0);
        return getProfileByIndex(index - 1);
    }
    
    // Save a new profile into its storage array.
    // The account address and user id should both unique for the currently stored profiles.
    function saveNewProfileOf(address _account, string calldata _id, string calldata _phone, string calldata _email) public {
        require(_account == address(_account));
        require(getIndexByAccount(_account) == 0);
        require(getIndexById(_id) == 0);

        StudentProfile memory newProfile = StudentProfile({
            account: _account,
            id: _id,
            phone: _phone,
            email: _email
        });

        _profiles.push(newProfile);

        // Since the return value will be 0 which is not the true index when the index is not found in mapping,
        // We use the index starts from 1 for saving.
        uint newIndex = _profiles.length;

        _saveAccountIndex(newIndex, _account);
        _saveIdIndex(newIndex, _id);
    }

    // Comapre if the provided string is same.
    // Using keccak256 hash to compare.
    function strEq(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        }

        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }   

    // Try to modify the user profile saved here.
    // User can only modify their own data.
    // TODO: handle the invalid address problem.
    function editSelfProfileOf(address _account, string calldata _id, string calldata _phone, string calldata _email) public {
        uint index;

        if (_account != address(0x0)) {
            index = getIndexByAccount(_account);
        } else {
            index = getIndexById(_id);
        }

        require(index != 0);

        StudentProfile memory targetProfile = _profiles[index - 1];

        if (_account != address(0x0)) {
            targetProfile.account = _account;
            _saveAccountIndex(index, _account);
        }

        string memory emptyStr = "";

        if (!strEq(_id, emptyStr)) {
            targetProfile.id = _id;
            _saveIdIndex(index, _id);
        }

        if (!strEq(_phone, emptyStr)) {
            targetProfile.phone = _phone;
        }

        if (!strEq(_email, emptyStr)) {
            targetProfile.email = _email;
        }

        _profiles[index - 1] = targetProfile;
    }
}