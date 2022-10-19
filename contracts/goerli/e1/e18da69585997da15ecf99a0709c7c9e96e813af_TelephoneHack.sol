/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface Telephone {
      function changeOwner(address _owner) external;
}

contract TelephoneHack {
    address payable target = payable(0x96eaeF1632aa884b15a2b634B60547f4BB57e275);

    function attack() public payable {
        
    } 

    function pay() public payable {
        (bool success, ) = msg.sender.call{value: msg.value}("");
       require(success, "Transfer failed.");
    }  
}