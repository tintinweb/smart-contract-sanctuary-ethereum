/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract SolidityContractWallet {
    mapping(address => uint) public addressStorage;
    function getEther () public payable {
        address addressOwner = tx.origin;
        uint amount = msg.value;
        addressStorage[addressOwner] = amount;
    }
    function sendWithdraw (uint etherAmount) public {
        if (addressStorage[msg.sender] > etherAmount) {
            revert("You do not have enought $ETH!");
        }
        payable(msg.sender).transfer(etherAmount);
    }
    function getBalance (address addressOwner) public view returns (uint) {
       return addressStorage[addressOwner];
    }
}