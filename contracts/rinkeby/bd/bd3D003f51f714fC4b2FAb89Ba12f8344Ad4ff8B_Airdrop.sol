// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
contract Airdrop {
    struct Data {
        address receipent;
        uint256 amount;
    }

    ERC721Partial public nft;
    uint airdropedAmount;

    constructor(ERC721Partial _nft) {
        nft = _nft;
    }

    function batchTransfer(Data[] memory data) external {
        for (uint i = 0 ; i < data.length; i ++) {
            _transfer(data[i].receipent, data[i].amount);
            airdropedAmount += data[i].amount;
        }
    }

    function _transfer(address receipent, uint amount) internal {
        for (uint i = 0; i < amount; i ++) {
            uint tokenId = nft.tokenOfOwnerByIndex(msg.sender, airdropedAmount + i);
            nft.transferFrom(msg.sender, receipent, tokenId);
        }
    }
}