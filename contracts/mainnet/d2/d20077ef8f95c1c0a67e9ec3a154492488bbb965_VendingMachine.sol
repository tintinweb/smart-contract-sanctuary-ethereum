/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
/**
Hex Bear Free Claim
*/

pragma solidity ^0.6.12;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract VendingMachine {
    uint256 constant public tokenAmount = 1000e18;
    uint256 constant public waitTime = 129600 minutes;

    ERC20 public HexBear;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _HexBear) public {
        require(_HexBear != address(0));
        HexBear = ERC20(_HexBear);
    }

    function gimme() public {
        require(allowedToWithdraw(msg.sender));
        HexBear.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}