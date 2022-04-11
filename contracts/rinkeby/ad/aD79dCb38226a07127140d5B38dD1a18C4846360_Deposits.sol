/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract Deposits{
    receive() external payable{
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function sendEther() public payable{
        uint x;
        x++;
    }
}