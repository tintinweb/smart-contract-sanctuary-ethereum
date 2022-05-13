/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

interface IRegistry {
   function isValidNiftySender(address sender) external view returns (bool);
}

struct RoyaltyInfo {
    address beneficiary;
    uint256 bips;
}

contract ERC2981 {

    address public _registry;

    address public _tokenAddress;

    bool public _initialized;

    mapping(uint256 => RoyaltyInfo) public _tokenRoyaltyInfo;

    function init(address registry_, address tokenAddress_) public {
        require(!_initialized, "ERC2981: already initialized");
        _registry = registry_;
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

    function assignRoyaltyInfo(uint256[] calldata niftyType, RoyaltyInfo[] calldata tokenRoyaltyInfo_) external {
        require(IRegistry(_registry).isValidNiftySender(msg.sender), "ERC2981: invalid msg.sender");

        for(uint256 i = 0; i < niftyType.length; i++){
            _tokenRoyaltyInfo[niftyType[i]] = tokenRoyaltyInfo_[i]; 
        }
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