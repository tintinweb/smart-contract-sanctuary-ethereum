/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {/*

                   MEOW ?
             /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)
    

*/
    address owner;
    constructor() {
        owner = msg.sender;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function withdrawlAll() external {
        payable(owner).transfer(address(this).balance);
    }


}