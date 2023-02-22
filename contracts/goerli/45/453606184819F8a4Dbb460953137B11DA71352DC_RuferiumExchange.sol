/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Ruferium {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract RuferiumExchange {
    Ruferium public token;
    address public owner;
    uint public rate;
    
    event Bought(address buyer, uint amount);
    
    constructor() {
        owner = msg.sender;
        token = Ruferium(0xdE952Dd98a04Ec9152DDB9f4B37C2a81A31E88b2);
        rate = 50000;
    }
    
    function buy() payable public {
        uint amountTobuy = msg.value * rate;
        uint tokenBalance = token.balanceOf(address(this));
        
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= tokenBalance, "Not enough tokens in the reserve");
        
        token.transfer(msg.sender, amountTobuy);
        emit Bought(msg.sender, amountTobuy);
    }
    
    function withdraw() public {
        require(msg.sender == owner, "You are not authorized to perform this action");
        payable(msg.sender).transfer(address(this).balance);
    }
}