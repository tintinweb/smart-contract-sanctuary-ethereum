/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface FiveOutOfNine {
    function mintMove(uint256 move, uint256 depth) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @author 0age
contract MateInEight {
    FiveOutOfNine fiveOutOfNine = FiveOutOfNine(0xB543F9043b387cE5B3d1F0d916E42D8eA2eBA2E0);
    constructor() {
        uint256[8] memory moves = [uint256(1372), 1437, 798, 1949, 1909, 942, 3436, 2858];
        for (uint256 i = 0; i < 8; i++) {
            fiveOutOfNine.mintMove(moves[i], 3);
        }
        for (uint256 tokenId = 111; tokenId < 119; tokenId++) {
            fiveOutOfNine.transferFrom(address(this), msg.sender, tokenId);
        }
    }
}