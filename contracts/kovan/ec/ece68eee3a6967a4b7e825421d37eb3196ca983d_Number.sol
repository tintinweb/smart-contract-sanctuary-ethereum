/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Number{

    uint public number = 1;

    function incrementNumber() external {
        number += 1;
    }
    
    function emitevent() external{

        emit myevent(msg.sender, 99);
    }

    function deposit() external payable {}

    function getbalance() external view returns(uint256){
        return address(this).balance;
    }

    event myevent(address indexed from, uint indexed randomnumber);
}