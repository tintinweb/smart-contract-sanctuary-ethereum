/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Defigenetics {
    uint randNonce = 0;
    uint256[10] private geneIds = [10,  20, 30, 40, 50];
	mapping(uint256 => DefimonStats) public tokenIdToDefimonStats;

    struct DefimonStats {
        uint256 geneId;
	    uint256 healthPoints;
	    uint256 attack;
	    uint256 defence;
	    uint256 specialAttack;
	    uint256 specialDefence;
	    uint256 specialEvade;
	}

    function generateStats(uint256 _tokenId) external returns (DefimonStats memory)  {
		DefimonStats memory baseStats;
        baseStats.geneId = geneIds[_tokenId];
		baseStats.healthPoints = randMod(100);
        baseStats.attack = randMod(31);
        baseStats.defence = randMod(51);
        baseStats.specialAttack = randMod(25);
        baseStats.specialDefence = randMod(25);
        baseStats.specialEvade = randMod(12);
        return baseStats;
    }

    function randMod(uint range) internal returns(uint) {
	// increase nonce
	randNonce++;
	return (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100) % range;
	}
}