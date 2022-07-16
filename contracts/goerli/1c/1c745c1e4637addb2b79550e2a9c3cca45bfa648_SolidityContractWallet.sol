/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract SolidityContractWallet {
    mapping(address => uint) private addressStorage;
    function topUpEther () public payable {
        address addressOwner = tx.origin;
        uint amount = msg.value;
        addressStorage[addressOwner] += amount;
    }
    function withdrawWei (uint weiAmount) public {
        require(addressStorage[msg.sender] > weiAmount, "You do not have enought balance!");
        require(weiAmount > 0, "Amount should be more than zero!");
        addressStorage[msg.sender] -= weiAmount;
        payable(msg.sender).transfer(weiAmount/(10**18));
    }
    function getBalance (address addressOwner) public view returns (uint) {
       return addressStorage[addressOwner];
    }
}