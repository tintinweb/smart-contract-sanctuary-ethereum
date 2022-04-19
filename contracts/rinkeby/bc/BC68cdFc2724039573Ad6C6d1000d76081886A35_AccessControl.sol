// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    uint public time = 5 minutes; 
    mapping(address => uint256) timeBuyersList;
    mapping(bytes32 => mapping(address => bool)) internal roles;

    bytes32 internal ADMIN = keccak256(abi.encodePacked("ADMIN")); // 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 internal TEAM = keccak256(abi.encodePacked("TEAM"));   // 0x9b82d2f38fbdf13006bfa741767f793d917e063392737837b580c1c2b1e0bab3
    bytes32 internal USERS = keccak256(abi.encodePacked("USERS")); // 0x80e5f4d2db32e62ee85b4d06c4355ea22b847c9659454b4b59d5724ae281b12c

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not authorized");
        _;
    }

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role,address _account) external onlyRole(ADMIN){
        _grantRole(_role, _account);
    }

    function hasRole(bytes32 _role, address _account) external view returns(bool){
        return roles[_role][_account];
    }

    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN){
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function buyAccessTime() public payable {
        require(msg.value > 99 wei, "You must send some ether");
        timeBuyersList[tx.origin] = block.timestamp;
    }
   
    function timeBasedAccess() public view returns (bool){
      return (block.timestamp < timeBuyersList[tx.origin] + time);
    }


}