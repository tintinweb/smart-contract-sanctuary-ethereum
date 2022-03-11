/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract RedeemBlacklist {
    constructor() {
        owner = msg.sender;
    }

    IERC721 nftContract = IERC721(0xA8cf84dD46e59428a468E5267979a3400B785F33);

    address public owner;
    
    uint256 public iterator;
    
    mapping (address => uint256) public howMany;

    function addClaim(address[] memory _addresses, uint256[] memory _howMany) public {
        require(msg.sender == owner, "You are not the owner");
        for(uint i = 0; i < _addresses.length; i++){
            howMany[_addresses[i]] = _howMany[i];
        }
    }

    function setIterator(uint256 _iterator) public {
        require(msg.sender == owner, "You're not the owner");
        iterator = _iterator;
    }

    function claimNFT(uint256 numNFTs) public {
        require(msg.sender == tx.origin, "Only direct calls allowed");
        require(numNFTs <= howMany[msg.sender], "You can't claim that many");

        for(uint256 i = 0; i < numNFTs; i++) {
            nftContract.transferFrom(owner, msg.sender, iterator + i);
        }

        howMany[msg.sender] -= numNFTs;
        iterator += numNFTs;
    }
}