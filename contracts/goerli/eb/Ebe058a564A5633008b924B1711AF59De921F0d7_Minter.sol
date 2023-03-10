/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: UNLISENCED

/**
 * @title NTP Collabs
 * @author 0xSumo 
 */

pragma solidity ^0.8.0;

abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    mapping(address => bool) public admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    modifier onlyAdmin { require(admin[msg.sender], "Not Admin"); _; }
    function setAdmin(address address_, bool bool_) external onlyOwner { admin[address_] = bool_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface iToken { function mintToken(address to, uint256 id, uint256 amount, bytes memory data) external; }

contract Minter is OwnControll {

    iToken public Token = iToken(0x58F9A445A42912d1774de94864609345cf745807);
    uint256 public numberOfToken;
    uint256 constant public mintPrice = 0.015 ether;
    mapping(address => uint256) private minted;
    modifier onlySender() { require(msg.sender == tx.origin, "No smart contract");_; }
    bool public active;
    function setActive() public onlyOwner { active = !active; }

    function mintMany(bytes memory data) external payable onlySender {
        require(minted[msg.sender] == 0, "Exceed max per addy and tx");
        require(msg.value == mintPrice, "Value sent is not correct");
        require(active, "Inactive");
        require(numberOfToken < 100, "Exceed max token");
        numberOfToken++;
        minted[msg.sender]++;
        Token.mintToken(msg.sender, 5, 1, data);
    }

    function withdraw() public onlyAdmin {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}