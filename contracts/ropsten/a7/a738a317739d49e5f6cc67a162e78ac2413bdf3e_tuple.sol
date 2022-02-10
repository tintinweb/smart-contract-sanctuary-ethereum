/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract tuple{
    




    struct PresaleInfo {
            address tokenAddress;
            address unsoldTokensDumpAddress;
            address[] whitelistedAddresses;
            uint256 tokenPriceInWei;
            uint256 hardCapInWei;
            uint256 softCapInWei;
            uint256 maxInvestInWei;
            uint256 minInvestInWei;
            uint256 openTime;
            uint256 closeTime;
        }
    
    function tuplePlay(PresaleInfo memory _info) external {
        address a = _info.tokenAddress;
        address b = _info.unsoldTokensDumpAddress;
        address[] memory cAddy = _info.whitelistedAddresses;
        uint256 d = _info.tokenPriceInWei;
        uint256 e = _info.hardCapInWei;
        uint256 f = _info.softCapInWei;
        uint256 g = _info.maxInvestInWei;
        uint256 h = _info.minInvestInWei;
        uint256 i = _info.openTime;
        uint256 j = _info.closeTime;

    }
        
}