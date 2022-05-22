/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

// Version of Solidity compiler this program was written for
pragma solidity^ 0.6.4;

// Our first contract is a faucet!
contract Faucet {

    uint256 public _balance;

    function faucet() public {
        _balance = 0;
    }

    // Accept any incoming amount
    receive() external payable{
        _balance = address(this).balance;
    }

    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 100000000000000000);

        // Send the amount to the address that requested it
        payable(msg.sender).transfer(withdraw_amount);
    }

    function test() external {

    }
}