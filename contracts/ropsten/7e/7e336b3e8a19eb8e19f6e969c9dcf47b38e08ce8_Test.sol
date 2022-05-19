/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    address[] public addressList;
    address public addr = 0x80907DFd22EE6B57dAd6F2253410Ad7aB2870291;

    function listLenght() public view returns (uint256) {
        return addressList.length;
    }

    function addList(uint256 cnt) public {
        for (uint256 i = 0; i < cnt; i++) {
            addressList.push(addr);
        }
    }

    function getList() public view returns (address[] memory) {
        return addressList;
    }
}