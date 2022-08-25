/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: No License
pragma solidity ^0.8.9;

contract Memberships {
    // used for onlyOwner modifier
    address public owner;

    // events
    event membershipCreated(uint256 id, uint256 startDate, uint256 endDate, address memberWallet, string username);
    event membershipDeleted(uint256 id, address memberWallet, string username);
    event usernameChanged(uint256 id, string oldUsername, string newUsername);
    event membershipUpdated(uint256 id, uint256 oldEndDate, uint256 newEndDate);

    // Membership struct
    struct Membership {
        uint256 startDate;
        uint256 endDate;
        address memberWallet;
        string username;
    }
    Membership[] public members;

    // allow easy lookup of membership IDs
    mapping(address => uint256) public ADDRESS_TO_ID;

    // prevent duplicate usernames
    mapping(string => bool) public USERNAME_IS_TAKEN;

    // protects memberships from being updated by anyone except the membership owner
    modifier membershipOwner(uint256 id) {
        require(msg.sender == members[id].memberWallet, "Sender is not holder of this membership");
        _;
    }

    // protects certain functions from being called by non contract owners
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;
    }

    constructor () {
        owner = msg.sender;

        // initialize 0 index
        members.push(Membership(0,0,owner,"owner"));
        ADDRESS_TO_ID[owner] = 0;
        USERNAME_IS_TAKEN["owner"] = true;

    }

    // starts membership, initializes ID automatically based on length of members array
    function startMembership(string memory _username) external {
        require(!USERNAME_IS_TAKEN[_username], "Username already taken");
        require(ADDRESS_TO_ID[msg.sender] == 0, "Sender already has a membership");

        uint256 id = members.length;
        uint256 endDate = (block.timestamp + (30 * 86400)); // 30 days * 86400 seconds per day

        ADDRESS_TO_ID[msg.sender] = id;
        USERNAME_IS_TAKEN[_username] = true;

        members.push(Membership(block.timestamp, endDate, msg.sender, _username));

        emit membershipCreated(id, block.timestamp, endDate, msg.sender, _username);
    }

    function changeUsername(string memory _username, uint256 _id) external membershipOwner(_id) {
        require(!USERNAME_IS_TAKEN[_username], "Username already taken");
        USERNAME_IS_TAKEN[_username] = true;

        string memory oldUsername = members[_id].username;
        
        // open former username
        USERNAME_IS_TAKEN[oldUsername] = false;

        members[_id].username = _username;

        emit usernameChanged(_id, oldUsername, members[_id].username);
    }

    function deleteMembership(uint256 _id) external membershipOwner(_id) {
        string memory username = members[_id].username;

        // open username
        USERNAME_IS_TAKEN[username] = false;

        delete(members[_id]);

        emit membershipDeleted(_id, msg.sender, username);
    }

    // only owner function, can be used to extend end date of a membership
    function updateMembership(uint256 _id, uint256 _endDate) external onlyOwner {
        uint256 oldEndDate = members[_id].endDate;
        members[_id].endDate = _endDate;

        emit membershipUpdated(_id, oldEndDate, _endDate);
    }

    // returns whether a membership is currently active
    function isActive(uint256 id) external view returns(bool) {
        return block.timestamp < members[id].endDate;
    }

}