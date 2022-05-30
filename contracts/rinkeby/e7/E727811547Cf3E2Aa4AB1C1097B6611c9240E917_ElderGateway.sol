/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/quests-skills/ElderGateway.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFT {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract ElderGateway {

    struct Details {
        address user; // owner of tokenId
        uint256 blockNo; // block.number when locked
    }
    mapping(address => mapping(uint256 => Details)) public lockedData;

    event Locked(address indexed user, address indexed nft, uint256[] tokenIds);
    event Unlocked(address indexed user, address indexed nft, uint256[] tokenIds);

    /**
    * @dev Locks multiple tokenIds from multiple collections.
    * @param nfts list of collection addresses.
    * @param tokenIds list of tokenIds from collections. First dimension index has to match `nfts` index.
    */
    function lock(address[] calldata nfts, uint256[][] calldata tokenIds) external {
        require(nfts.length == tokenIds.length, "NFTs addresses & tokenIds length mismatch.");

        for (uint8 i = 0; i < nfts.length; i++) {
            for (uint8 j = 0; j < tokenIds[i].length; j++) {
                INFT(nfts[i]).transferFrom(msg.sender, address(this), tokenIds[i][j]);
                lockedData[nfts[i]][tokenIds[i][j]].user = msg.sender;
                lockedData[nfts[i]][tokenIds[i][j]].blockNo = block.number;
            }
            emit Locked(msg.sender, nfts[i], tokenIds[i]);
        }
    }

    /**
    * @dev Unlocks multiple tokenIds from multiple collections.
    * @param nfts list of collection addresses.
    * @param tokenIds list of tokenIds from collections. First dimension index has to match `nfts` index.
    */
    function unlock(address[] calldata nfts, uint256[][] calldata tokenIds) external {
        require(nfts.length == tokenIds.length, "NFTs addresses & tokenIds length mismatch.");

        for (uint8 i = 0; i < nfts.length; i++) {
            for (uint8 j = 0; j < tokenIds[i].length; j++) {
                require(msg.sender == lockedData[nfts[i]][tokenIds[i][j]].user, "Invalid tokenId.");
                require(block.number > lockedData[nfts[i]][tokenIds[i][j]].blockNo, "Unlock too fast.");

                INFT(nfts[i]).transferFrom(address(this), msg.sender, tokenIds[i][j]);
                delete lockedData[nfts[i]][tokenIds[i][j]];
            }
            emit Unlocked(msg.sender, nfts[i], tokenIds[i]);
        }
    }

}