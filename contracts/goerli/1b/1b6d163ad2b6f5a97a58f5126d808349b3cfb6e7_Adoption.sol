/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

contract Adoption {
    address[16] public adopters;

    // Adopting a pet
    function adopt(uint petId) public returns (uint) {
    require(petId >= 0 && petId <= 15);

    adopters[petId] = msg.sender;

    return petId;
    }

    // Retrieving the adopters
    function getAdopters() public view returns (address[16] memory){
        return adopters;
    }
}