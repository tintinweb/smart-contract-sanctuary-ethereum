// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract TransferBatchNFT {
    function TransferBatch(
        address nftAddress,
        address reciever,
        uint256[] calldata tokenIDs
    ) public {
        for (uint i = 0; i < tokenIDs.length; i++) {
            IERC721(nftAddress).transferFrom(msg.sender, reciever,tokenIDs[i]);
        }
    }
}