/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyNFT {
    uint256 public constant MAX_NFT_SUPPLY = 1000;

    mapping(address => bool) private _hasMinted;
    uint256 private _nftSupply;

    event NFTMinted(address indexed owner, uint256 indexed tokenId);

    function mintNFT() public payable {
        require(msg.value == 0.001 ether, "Insufficient payment");
        require(!_hasMinted[msg.sender], "You have already minted an NFT");
        require(_nftSupply < MAX_NFT_SUPPLY, "NFTs have sold out");

        _hasMinted[msg.sender] = true;
        _nftSupply++;

        // create NFT
        emit NFTMinted(msg.sender, _nftSupply);
    }
}