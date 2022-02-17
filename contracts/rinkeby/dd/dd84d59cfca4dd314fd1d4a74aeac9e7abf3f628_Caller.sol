/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAstrologyClub {
    function balanceOf(address owner) external view returns(uint256);
}

contract Caller {
    function someAction(address contractAdress, address owner) public view returns(uint256) {
        return IAstrologyClub(contractAdress).balanceOf(owner);
    }
}