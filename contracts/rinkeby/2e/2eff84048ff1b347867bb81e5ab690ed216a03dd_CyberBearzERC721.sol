/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract CyberBearzERC721 {
    uint[] public nftIdRandomList = [1];
    uint[] public nftRankList = [1];

    uint[] public nft2IdRandomList = [1];
    uint[] public nft2RankList = [1];

    function add(uint[] memory _arrayId, uint[] memory _arrayRank) public {
        nftIdRandomList = _arrayId;
        nftRankList = _arrayRank;
    }

    function add4(uint[] memory _arrayId, uint[] memory _arrayRank, uint[] memory _array2Id, uint[] memory _array2Rank) public {
        nftIdRandomList = _arrayId;
        nftRankList = _arrayRank;
        nft2IdRandomList = _array2Id;
        nft2RankList = _array2Rank;
    }
}