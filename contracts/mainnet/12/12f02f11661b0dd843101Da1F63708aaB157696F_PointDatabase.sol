/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Point Database
 * @author 0xSumo
 *
 * Description:
 * This smart contract implements a simple point system that can serve as a 
 * foundation for a variety of applications.
 *
 * Features:
 * - Increase points for a specific address
 * - Decrease points from a specific address
 * - Transfer points from one address to another
 *
 * Note:
 * This contract does not include any tokenization features or integrations 
 * with ERC standards. Points do not represent a form of currency or value 
 * outside of the specific system in which they are used. Please ensure 
 * legal compliance in your jurisdiction when using this contract.
 */

/// OwnControll by 0xSumo
abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminSet(bytes32 indexed controllerType, bytes32 indexed controllerSlot, address indexed controller, bool status);
    address public owner;
    mapping(bytes32 => mapping(address => bool)) internal admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    modifier onlyAdmin(string memory type_) { require(isAdmin(type_, msg.sender), "only admin");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
    function setAdmin(string calldata type_, address controller, bool status) external onlyOwner { bytes32 typeHash = keccak256(abi.encodePacked(type_)); admin[typeHash][controller] = status; emit AdminSet(typeHash, typeHash, controller, status); }
    function isAdmin(string memory type_, address controller) public view returns (bool) { bytes32 typeHash = keccak256(abi.encodePacked(type_)); return admin[typeHash][controller]; }
}

contract PointDatabase is OwnControll {

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function _getPoints(address address_, uint256 amount_) internal {
        balanceOf[address_] += amount_;
    }

    function _losePoints(address address_, uint256 amount_) internal {
        balanceOf[address_] -= amount_;
    }

    function transferFrom(address from_, address to_, uint256 amount_) public returns (bool) {
        require(msg.sender == from_, "Only the sender can transfer points");
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }

    function getPoints(address address_, uint256 amount_) external onlyAdmin("GET") {
        _getPoints(address_, amount_);
    }

    function losePoints(address address_, uint256 amount_) external onlyAdmin("LOSE") {
        _losePoints(address_, amount_);
    }
}