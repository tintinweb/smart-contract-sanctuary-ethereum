/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity ^0.8.0;


contract OwnerFaucet {

    // owner of this faucet
    address owner;

    // method to receive funds from other accounts.
    receive() external payable {}

    // constructor
    constructor() {
        owner = msg.sender;
    }


    // modifier to restrict access to methods only to owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount, address to_address) public onlyOwner {
        // Limit withdrawal amount
        require(withdraw_amount <= 100_000_000_000_000_000);

        // Send the amount to the address that requested it
        payable(to_address).transfer(withdraw_amount);
    }
}