/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.11;

interface IPayment {
    function initClaim(address _payee, uint256 _amount) external payable;
}

contract depositHandler{

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event Claimed(uint256 indexed amount, address indexed payee);

    mapping(bytes32 => mapping(address => bool)) public roles;

    //0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    //0xe713da41157afd626765d8624ce6aa2e2cda0e788972dce0d6620ef0d5983efa
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));

    address payable public owner;    // current owner of the contract

    constructor() {
        owner = payable(msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    receive() external payable {}
    /// @notice Initiates Pool participition in batches.
    function initPool(uint _amount, address _payee) external onlyRole(ADMIN) {
        require(msg.sender == owner, "Only owner can call this method.");
        payable(_payee).transfer(_amount);
    }

    /// @notice Initiates claim for specific address.
    function broadcastClaim(address payable _claimContract, address payable _payee, uint256 _amount) external payable onlyRole(EXEC) {
        IPayment(_claimContract).initClaim{value: msg.value}(_payee, _amount);
        emit Claimed(_amount, _payee);
        
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not Authorized");
        _;
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role,_account);
    }

    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
        _grantRole(_role, _account);
    }
}