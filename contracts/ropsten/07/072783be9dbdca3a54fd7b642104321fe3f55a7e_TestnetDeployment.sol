/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestnetDeployment{

    string public message = "Greetings, My name is Sofian and today I am going to deploy this smart contract on the Ropsten Testnet! I have worked on numerous smart contracts but for this one, I'll keep it simple. I'll just add a few simple functions to this smart contract which are used very frequently. Thank you!";
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}
    
    function displayMessage() public view returns(string memory) {
        return message;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender == owner);
        payable(owner).transfer(getBalance());
    }

}