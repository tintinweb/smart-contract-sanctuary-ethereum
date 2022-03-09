/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface INftSquid {
    // player can buy before startTime
    function claimApeXNFT(uint256 userSeed) external payable;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view  returns (uint256);
}

contract MultiMintForUsers {
    address public nftAddress;

    constructor(address nft) {
        nftAddress = nft;
    }

    function multiMint(uint256 amount) external payable  {
        require(amount <= 20, "mint amount exceed!");
        require(amount * 0.45 ether == msg.value, "amount not match");
        address to = msg.sender ; 
        for (uint256 i = 0; i < amount; i++) {
            INftSquid(nftAddress).claimApeXNFT{value: 0.45 ether}(i);
            uint256 id = INftSquid(nftAddress).tokenOfOwnerByIndex( address(this),0 );
            INftSquid(nftAddress).transferFrom(address(this), to, id);
        }
    }
}