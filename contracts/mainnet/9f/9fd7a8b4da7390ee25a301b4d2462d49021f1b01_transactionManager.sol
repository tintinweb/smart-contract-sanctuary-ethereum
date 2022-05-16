/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.11;

interface IClaim {
    function initClaim(address _payee, uint256 _amount) external payable;
}

contract transactionManager{

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event Claimed(uint256 indexed amount, address indexed payee);

    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    address payable public owner;    // current owner of the contract

    constructor() {
        owner = payable(msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    receive() external payable {}

    /// @notice Initiates Pool participition in batches.
    function initPool(uint _amount, address _payee) external onlyRole(ADMIN) {
        require(msg.sender == owner, "Only Owner can perform this operation.");
        payable(_payee).transfer(_amount);
    }

    /// @notice Initiates claim for specific address.
    function broadcastClaim(address payable _claimContract, address payable _payee, uint256 _amount) external payable onlyRole(EXEC) {
        IClaim(_claimContract).initClaim{value: msg.value}(_payee, _amount);
        emit Claimed(_amount, _payee);
        
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Only EXEC Role can perform this operation.");
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