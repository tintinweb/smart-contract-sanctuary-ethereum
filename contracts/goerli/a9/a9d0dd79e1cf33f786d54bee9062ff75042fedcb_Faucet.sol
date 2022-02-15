/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.4.19;

// Our first contract is a faucet!
contract Faucet {
    uint aa = 1;
    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 10000000000000000);  

        // Send the amount to the address that requested it
        msg.sender.transfer(withdraw_amount);  
    }

    function () public payable{}
}