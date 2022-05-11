/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Fomo3D {

    receive() external payable {}
    fallback() external payable {}

    mapping (address => uint) keyBalance;
    
    address owner;
    bool isActive;
    uint endTime = 3 minutes;
    uint addTime = 30 seconds;
    uint keyPrice = 0.01 ether;
    
    constructor(address _owner) {
        owner = _owner;
        isActive = false;
    } 

    modifier onlyOwner {
        require (msg.sender == owner, "Permission Error.");
        _;
    }
    
    function startGame() public onlyOwner {
        isActive = true; 
    }
    
    function buyKey(uint amount) public payable {
        (bool sent, ) = address(this).call{value: msg.value}("");
        if (msg.value <= amount*keyPrice) 
            revert("not enough");

        require(sent, "Failed to send Ether");
        keyBalance[msg.sender] += amount;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getKey() public view returns (uint) {
        return keyBalance[msg.sender];
    }


}