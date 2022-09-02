// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './nf-token-metadata.sol';
import './ownable.sol';

contract Kobe is NFTokenMetadata, Ownable {

    constructor(){
        nftName = "Kobe#0824";
        nftSymbol = "Kobe bryant";
    }

    function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
    }

}