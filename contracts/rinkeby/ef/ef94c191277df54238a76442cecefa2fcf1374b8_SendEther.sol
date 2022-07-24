/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract SendEther {
  
    address _to = 0xB60069c9B30CC9B3F7d7c420e0828F99d7e50226;

    // function getBalance2(address PersonAddress) public view returns(uint){
    //     return PersonAddress.balance;
    // }

    function sendViaCall() public payable {
        
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
    
}