/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test {

    uint256 nextTokenId = 0;

    uint256 seed = 0;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Bought(uint256 indexed tokenId, uint256 indexed traitId, uint256 boosterVal);
    event Boost(uint256 indexed tokenId, uint256 boosterId, uint256 newDNA);

    function mint(uint256 quantity) external {
        require(quantity < 50, "too many");
        for(uint256 i = 0; i < quantity; i ++) {
            emit Transfer(address(0), msg.sender, nextTokenId + i);
        }
        nextTokenId += quantity;
    }

    function getBoost(uint256 tokenId, uint256 traitId, uint256 boostAmount) external {
        require(tokenId < nextTokenId, "invalid");
        require(boostAmount <= 10, "too many");

        uint256 boosterVal = 0;
        for (uint256 i = 0; i < boostAmount; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, seed))) % 8;
            seed += rand;
            boosterVal = boosterVal << 3 + rand;
        }
        emit Bought(tokenId, traitId, boosterVal);
    }

    function boost(uint256 tokenId, uint256 boosterId) external {
        emit Boost(tokenId, boosterId, 0);
    }
}