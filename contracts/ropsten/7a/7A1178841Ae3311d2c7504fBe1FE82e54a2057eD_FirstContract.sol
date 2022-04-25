//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract FirstContract{
    event UpdateAdoptionList(address[16] oldList, address[16] newList);

    address[16] public adopters;
    function adopt(uint petId) public {
        require(petId >=0 && petId <=15);
        address[16] memory oldList = adopters;
        adopters[petId] = msg.sender;
        emit UpdateAdoptionList(oldList, adopters);
    }
}