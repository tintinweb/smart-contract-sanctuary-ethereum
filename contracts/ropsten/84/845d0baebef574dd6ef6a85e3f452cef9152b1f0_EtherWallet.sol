/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
//anyone can send ETH. 
//Only the owner can withdraw
contract EtherWallet {
    address payable public owner;

    //at deployment of contract, msg.sender is owner
    constructor() {
        //note you can make a function or an address payable
        owner = payable(msg.sender);
    }

    //contract can receive ether (it's a wallet)
    receive() external payable {}

    //only owner can withdraw. probably would be good to have a 
    //throwback message upon failure if amount listed exceeds amount
    //in contract
    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

}