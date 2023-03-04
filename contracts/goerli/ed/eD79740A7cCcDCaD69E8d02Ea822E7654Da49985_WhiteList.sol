/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract WhiteList{
    uint8 maxWhiteListAddress;
    mapping(address=>bool) public whiteListAddress;

    uint whiteListCount = 0;


    constructor(uint8 _maxWhiteListAddress){
        maxWhiteListAddress = _maxWhiteListAddress;
    }

    function addAddressInwhiteList() public{
        require(!whiteListAddress[msg.sender], "Address already in whiteList" );
        require(whiteListCount < maxWhiteListAddress, "Limit already reacherd");
        whiteListAddress[msg.sender] = true;
        whiteListCount++;

    }




}