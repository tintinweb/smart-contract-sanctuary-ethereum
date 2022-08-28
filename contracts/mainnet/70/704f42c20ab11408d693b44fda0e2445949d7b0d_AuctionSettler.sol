/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface BoredApeYogaClub {
    function settleAuction(uint apeId) external;
}

contract AuctionSettler {
    BoredApeYogaClub private bayc;
    constructor(){
        bayc = BoredApeYogaClub(0x65784d6F23DE30A17122E96c0F0986C378ed6947);
    }

    function settleAuctions(uint256[] memory apeIds) external {
        for(uint256 i = 0; i < apeIds.length;) {
            bayc.settleAuction(apeIds[i]);
            unchecked { i++; }
        }
    }

}