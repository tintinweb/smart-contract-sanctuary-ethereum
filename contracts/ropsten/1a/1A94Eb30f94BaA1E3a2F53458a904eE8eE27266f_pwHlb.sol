/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract HlbInterface {
    function getMoney(uint256 numTokens) virtual public;
    function reset() virtual public;
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function enterHallebarde() virtual public;
    function getMembershipStatus(address memberAddress) virtual external view returns (bool);
}


contract pwHlb {

    address ckAddress = 0xb8c77090221FDF55e68EA1CB5588D812fB9f77D6;

    HlbInterface hlbInterface = HlbInterface(ckAddress);

    function hallebarde() public {
        hlbInterface.enterHallebarde();
    }
}