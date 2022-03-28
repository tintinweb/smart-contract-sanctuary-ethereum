/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Whitelist {

    constructor(){
        maxAddress = 10;
    }
    
   uint public maxAddress;
    mapping(address => bool) whitelisted;
    uint public numbers;

    function addAddressToWhitelist() public {
        require(numbers < maxAddress, "sorry, no more slots available");
        require(!whitelisted[msg.sender], "sorry you can only be enter once");

        whitelisted[msg.sender] = true;

        numbers += 1;
    }
}