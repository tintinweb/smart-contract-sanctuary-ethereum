/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INFT {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract ElderGateway {

    /**
    * @dev Details of locked NFT
    * @param user owner of tokenId
    * @param blockNo block.number when locked
    */
    struct Details {
        address user;
        uint256 blockNo;
    }

    /**
    * @dev mapping holds below values:
    * collectionAddress => tokenId => Details  
    */
    mapping(address => mapping(uint256 => Details)) public lockedData;

    /** 
    * @dev Emits event after nft is successfully locked
    * @param user address which locked nfts (owner of tokens)
    * @param nft collection address
    * @param tokenIds list of tokenIds from `nft` collection
    */
    event Locked(address indexed user, address indexed nft, uint256[] tokenIds);

    /** 
    * @dev Emits event after nft is successfully unlocked
    * @param user address which unlocked nfts (owner of tokens)
    * @param nft collection address
    * @param tokenIds list of tokenIds from `nft` collection
    */
    event Unlocked(address indexed user, address indexed nft, uint256[] tokenIds);

    /**
    * @dev Locks multiple tokenIds from multiple collections.
    * @param nfts list of collection addresses.
    * @param tokenIds list of tokenIds from collections. First dimension index has to match `nfts` index.
    */
    function lock(address[] calldata nfts, uint256[][] calldata tokenIds) external {
        require(nfts.length == tokenIds.length, "NFTs addresses & tokenIds length mismatch.");

        uint256 nftsLength = nfts.length;
        uint256 tokenIdsLength;
        for (uint8 i = 0; i < nftsLength; i++) {
            tokenIdsLength = tokenIds[i].length;
            if (tokenIdsLength > 0) {
                emit Locked(msg.sender, nfts[i], tokenIds[i]);
                for (uint8 j = 0; j < tokenIdsLength; j++) {
                    lockedData[nfts[i]][tokenIds[i][j]].user = msg.sender;
                    lockedData[nfts[i]][tokenIds[i][j]].blockNo = block.number;
                    INFT(nfts[i]).transferFrom(msg.sender, address(this), tokenIds[i][j]);
                }
            }
        }
    }

    /**
    * @dev Unlocks multiple tokenIds from multiple collections.
    * @param nfts list of collection addresses.
    * @param tokenIds list of tokenIds from collections. First dimension index has to match `nfts` index.
    */
    function unlock(address[] calldata nfts, uint256[][] calldata tokenIds) external {
        require(nfts.length == tokenIds.length, "NFTs addresses & tokenIds length mismatch.");

        uint256 nftsLength = nfts.length;
        uint256 tokenIdsLength;
        for (uint8 i = 0; i < nftsLength; i++) {
            tokenIdsLength = tokenIds[i].length;
            if (tokenIdsLength > 0) {
                emit Unlocked(msg.sender, nfts[i], tokenIds[i]);
                for (uint8 j = 0; j < tokenIdsLength; j++) {
                    require(msg.sender == lockedData[nfts[i]][tokenIds[i][j]].user, "Token does not belong to user.");
                    require(block.number > lockedData[nfts[i]][tokenIds[i][j]].blockNo, "Unlock too fast.");

                    delete lockedData[nfts[i]][tokenIds[i][j]];
                    INFT(nfts[i]).transferFrom(address(this), msg.sender, tokenIds[i][j]);
                }
            }
        }
    }

}