/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Test {

    event redeem(uint ID, uint time);

    function redeemed(uint nftID) public{

        // update st var
        emit redeem(nftID,block.timestamp);
    }
    
}