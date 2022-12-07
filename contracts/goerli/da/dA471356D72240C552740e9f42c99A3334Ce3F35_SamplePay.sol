/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SamplePay {
    // The address that deployed the contract will be able to access the funds
    address public deployer;

    // The constructor is executed when the contract is deployed
    constructor(){
        // Set the deployer address to the address that deployed the contract
        deployer = msg.sender;
    }

    // The samplePay function accepts a payment of 0.01 ETH
    function samplePay() public payable {
        // Require that the payment is 0.01 ETH
        require(msg.value == 0.01 ether, "Incorrect payment amount");
    }

    // The withdraw function allows the deployer to withdraw the funds
    function withdraw() public {
        // Require that the caller is the deployer
        require(msg.sender == deployer, "Only the deployer can withdraw funds");

        // Transfer all of the contract's funds to the deployer
        payable(deployer).transfer(address(this).balance);
    }

    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }
}