/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

struct RoyaltyInfo {
    address beneficiary;
    uint256 bips;
}

contract ERC2981 {

    address public _tokenAddress;

    bool public _initialized;

    mapping(uint256 => RoyaltyInfo) public _tokenRoyaltyInfo;

    function init(address tokenAddress_, uint256[] calldata niftyTypeList, RoyaltyInfo[] calldata royaltyInfoList) public {
        require(!_initialized, "ERC2981: already initialized");
        
        for(uint256 i = 0; i < niftyTypeList.length; i++){
            _tokenRoyaltyInfo[niftyTypeList[i]] = royaltyInfoList[i]; 
        }
        _tokenAddress = tokenAddress_;
        _initialized = true;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 niftyType = _getNiftyType(tokenId);
        require(_tokenRoyaltyInfo[niftyType].beneficiary != address(0), "ERC2981: beneficiary not set");

        RoyaltyInfo memory info = _tokenRoyaltyInfo[niftyType];
        uint256 royaltyAmount = (salePrice * info.bips) / 10000;
        return (info.beneficiary, royaltyAmount);
    }

    function _getNiftyType(uint256 tokenId) private pure returns (uint256) {
        uint256 contractId  = tokenId / 100000000;
        uint256 topLevelMultiplier = contractId * 100000000;
        return (tokenId - topLevelMultiplier) / 10000;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x2a55205a    // ERC2981
        ) {
            return true;
        }
        return false;
    }

}