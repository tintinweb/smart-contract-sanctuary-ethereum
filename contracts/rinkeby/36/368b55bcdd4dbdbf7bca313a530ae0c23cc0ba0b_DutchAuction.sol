/**
 *Submitted for verification at Etherscan.io on 2022-02-09
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
    address _nft = 0xa2a4e0a1d1e32ABd17b77E7119F5BA3A1e52db63;
    constructor() {
        nft = IERC721(_nft);
    }

    function buy() external payable {
        nft.DutchAuctionMint(1, msg.sender);
    }
}