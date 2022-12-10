/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Roleable {
    address public owner;

    mapping(address => bool) public admins;
    mapping(address => bool) public managers;
    mapping(address => bool) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can call this function");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Only manager can call this function");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || admins[msg.sender],
            "Only owner or admin can call this function"
        );
        _;
    }

    modifier onlyAdminOrManager() {
        require(
            admins[msg.sender] || managers[msg.sender],
            "Only admin or manager can call this function"
        );
        _;
    }

    modifier ownerOrAdminOrManager() {
        require(
            msg.sender == owner || admins[msg.sender] || managers[msg.sender],
            "Only owner, admin or manager can call this function"
        );
        _;
    }

    function checkOwner(address _address) public view returns (bool) {
        return owner == _address;
    }

    function checkAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    function checkManager(address _address) public view returns (bool) {
        return managers[_address];
    }

    function checkAdminOrManager(address _address) public view returns (bool) {
        return (admins[_address] || managers[_address]);
    }

    function checkOwnerOrAdminOrManager(address _address)
        public
        view
        returns (bool)
    {
        return (owner == _address || admins[_address] || managers[_address]);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function addAdmin(address _address, string memory name) public onlyOwner {
        admins[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        admins[_address] = false;
    }

    function addManager(address _address, string memory name)
        public
        onlyOwnerOrAdmin
    {
        managers[_address] = true;
    }

    function removeManager(address _address) public onlyOwnerOrAdmin {
        managers[_address] = false;
    }

    function addUser(address _address, string memory name)
        public
        ownerOrAdminOrManager
    {
        users[_address] = true;
    }

    function removeUser(address _address) public ownerOrAdminOrManager {
        users[_address] = false;
    }
}