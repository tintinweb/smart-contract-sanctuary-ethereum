/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
   ______  ______               ______     ______  
 .' ___  ||_   _ `.           .' ____ \  .' ___  | 
/ .'   \_|  | | `. \  ______  | (___ \_|/ .'   \_| 
| |         | |  | | |______|  _.____`. | |        
\ `.___.'\ _| |_.' /          | \____) |\ `.___.'\ 
 `.____ .'|______.'            \______.' `.____ .' 
   ChubiDuracell                 smart contract
*/

contract FaucetCWT {

    IERC20 public token = IERC20(0x9fa7096177A9eDC1547cCA1345B6a9C9e3A7eA6D);

    uint public tokensOnce = 5;
    uint public requestAmount = 10;
    uint public lockTime = 7 hours;

    uint public totalAmountRequest;

    event Requests(uint when, address who);
    
    struct RequestInfo{
        uint16 requestCount;
        uint256 lastRequest;
    }

    mapping(address => RequestInfo) public requestList;

    function requestTokens() public {
        require(msg.sender != address(0), "Opps, no Zero account here!");
        require(token.balanceOf(address(this)) >= tokensOnce, "No more toekns here");
        require(block.timestamp >= requestList[msg.sender].lastRequest + lockTime, "Yo yo, you just got tokens, try again later.");
        require(requestAmount >= requestList[msg.sender].requestCount, "Sorry but you can use this faucet only 10 times");

        requestList[msg.sender].requestCount ++;
        requestList[msg.sender].lastRequest = block.timestamp;

         token.transfer(msg.sender, tokensOnce);

         totalAmountRequest++;

         emit Requests(block.timestamp, msg.sender);
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    receive() external payable {}
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}