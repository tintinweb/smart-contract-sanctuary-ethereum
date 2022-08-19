/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract UserParticipationList{
    mapping(address => address[]) public getJoinUnion;
    constructor() {}

    function add(address user, address union) external {
        getJoinUnion[user].push(union);
    }

    function get(address user) public view returns(address[] memory union) {
        return getJoinUnion[user];
    } 
}