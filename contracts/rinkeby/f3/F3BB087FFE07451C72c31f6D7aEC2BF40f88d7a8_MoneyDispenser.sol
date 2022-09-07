/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MoneyDispenser{

function  withdraw(uint256 amount) public{

    require(amount<=10000000000000000);//0.01 ether
    payable(msg.sender).transfer(amount);


}
receive() external payable{}

}