/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Faucet {
    mapping(address=>uint256) public lastWithdrawalTimestamp;

    //Accept any incoming amount
    receive () external payable {} 

    //Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        require((block.timestamp - lastWithdrawalTimestamp[msg.sender]) >= 1 days, "Can withdraw after 24Hours");
        //Limit withdrawal amount
        require(withdraw_amount <= 10000000000000000, "Cannot withdraw more than 0.01 ETH"); //0.01 Ether
        lastWithdrawalTimestamp[msg.sender] = block.timestamp;
        //send the amount to the address that requested it 
        payable(msg.sender).transfer(withdraw_amount);
    }

}