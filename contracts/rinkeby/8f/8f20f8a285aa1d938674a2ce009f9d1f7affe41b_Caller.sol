/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Caller {
    function someAction(address contractAdress, address owner) public view returns(uint256) {
        AstrologyClub ac = AstrologyClub(contractAdress);
        return ac.balanceOf(owner);
    }
}

abstract contract AstrologyClub {
    function balanceOf(address owner) public view virtual returns(uint256);
}