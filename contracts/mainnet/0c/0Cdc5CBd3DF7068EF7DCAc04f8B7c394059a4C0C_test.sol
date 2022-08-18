/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract test {


    mapping(uint16 => uint8) public genesisType;

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(_types[i] != 0 , "Invalid nft type - cannot be 0");
            genesisType[tokenIds[i]] = _types[i];
        }
    }

    // mass update the nftType mapping
    function setBatchNFTTypeSame(uint16[] calldata tokenIds, uint8 _type) external {
        require(_type != 0 , "Invalid nft type - cannot be 0");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            genesisType[tokenIds[i]] = _type;
        }
    }

}