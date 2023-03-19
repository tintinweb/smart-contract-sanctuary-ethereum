/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED

/**
 * @title NTP Collabs Minter
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

    iToken public Token = iToken(0x68607266e9118B971901239891e6280a8066fCEb);

    uint256 public activeTime = 1679227200;
    uint256 public endTime = 1680440400;
    uint256 public numberOfToken;
    uint256 public constant TOKEN_ID = 7;
    uint256 public mintPrice = 0.013 ether;
    modifier onlySender { require(msg.sender == tx.origin, "No smart contract");_; }

    function mintMany(uint256 amount, bytes memory data) external payable onlySender {
        require(block.timestamp >= activeTime, "Inactive");
        require(block.timestamp <= endTime, "Past Deadline");
        require(msg.value == mintPrice * amount, "Value sent is not correct");

        numberOfToken+=amount;
        Token.mintToken(msg.sender, TOKEN_ID, amount, data);
    }

    function setPrice(uint256 price_) public onlyAdmin { 
        mintPrice = price_; 
    }

    function setActiveTime(uint256 time_) public onlyOwner { 
        activeTime = time_; 
    }

    function setEndTime(uint256 time_) public onlyOwner { 
        endTime = time_; 
    }
    
    function withdraw() public onlyAdmin {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}