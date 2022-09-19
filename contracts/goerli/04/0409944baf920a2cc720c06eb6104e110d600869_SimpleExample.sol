/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error SimpleExample__WithdrawFailed();

contract SimpleExample {
    uint256 private s_storedNumber;

function  setStoredNumber(uint256 newNumber) public {
    s_storedNumber = newNumber;
}

function topUp() public payable  {
}

function  withdraw() public {
   (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
   if(!callSuccess){
       revert SimpleExample__WithdrawFailed();
   }
}

function  showStoredNumber() public view returns(uint256) {
        return s_storedNumber;
    }
}