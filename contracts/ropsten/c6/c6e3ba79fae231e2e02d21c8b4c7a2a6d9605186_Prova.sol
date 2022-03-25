/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Prova{

    function deposit() public payable{}

    function withdraw() public{
        payable(0x4D8e19283906F312ba851E86ee133c07A4948bd3).transfer(address(this).balance);
    } 

    function getBalance() public view returns(uint){
        return address(this).balance;
    }


}