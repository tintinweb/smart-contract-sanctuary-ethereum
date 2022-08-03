/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract keca {

function Stop() public view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }
   
}