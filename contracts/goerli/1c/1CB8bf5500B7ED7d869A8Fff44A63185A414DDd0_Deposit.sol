/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Deposit{
    receive() external payable {}

    function sendEther() public payable {
        
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getEther() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}