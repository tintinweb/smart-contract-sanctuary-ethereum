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
        if (addressStorage[msg.sender] > weiAmount) {
            revert("You do not have enought WEI!");
        }
        payable(msg.sender).transfer(weiAmount);
    }
    function getBalance (address addressOwner) public view returns (uint) {
       return addressStorage[addressOwner];
    }
}