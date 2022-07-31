/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

pragma solidity ^0.5.0;
contract Adoption {
    address[16] public adopters;

    function adopt(uint petId) public returns (uint) {
        require(petId >= 0 && petId <= 15);
        adopters[petId] = msg.sender;
        return petId;
    }

    // array getter can only return one element, so to get all elements
    function getAdopters() public view returns (address[16] memory) {
        return adopters;
    }
}