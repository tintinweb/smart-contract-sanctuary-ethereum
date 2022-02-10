/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function DutchAuctionMint(
        uint _amount,
        address _to
    ) external;
}

contract DutchAuction {
    IERC721 public immutable nft;
    address _nft = 0xb2ee1e8Ec7634488008c6c23d7B274f4a4a5eBE6;
    constructor() {
        nft = IERC721(_nft);
    }

    function buy() external payable {
        nft.DutchAuctionMint(1, msg.sender);
    }
}