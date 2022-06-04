/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Adoption {
    address[50] public adopters;

    function adopt(uint petId) public returns(uint) {
        require(petId >= 0 && petId <= 50);

        adopters[petId] = msg.sender;

        return petId;
    }

    function getAdopters() public view returns(address[50] memory) {
        return adopters;
    }

}