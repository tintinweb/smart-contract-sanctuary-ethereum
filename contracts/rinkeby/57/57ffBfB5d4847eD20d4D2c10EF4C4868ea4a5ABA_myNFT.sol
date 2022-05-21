// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface X {
    function emitTransfer(address from, address to, uint256 tokenId) external;
    function emitMint(address to, uint256 tokenId) external;
}


contract myNFT {
    X burningnft;
    constructor(X nft) {
        burningnft = nft;
    }

    function emitTransfer(address from, address to, uint256 tokenId) public {
        burningnft.emitTransfer(from, to, tokenId);
    }

    function emitMint(address to, uint256 tokenId) public {
        burningnft.emitMint(to, tokenId);
    }
}