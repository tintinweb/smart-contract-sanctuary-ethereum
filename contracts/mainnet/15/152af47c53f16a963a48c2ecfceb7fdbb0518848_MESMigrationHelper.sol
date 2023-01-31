/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface iMES { 
    function getYieldRateOfAddress(address address_) external view returns (uint256);
}

interface iCC {
    function getCharacterYieldRate(uint256 tokenId_) external view returns (uint256);
}

interface iCha {
    function walletOfOwner(address address_) external view returns (uint256[] memory);
}

contract MESMigrationHelper {
    iMES private constant MES = iMES(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    iCC private constant CC = iCC(0x53beA59B69bF9e58E0AFeEB4f34f49Fc29D10F55);
    iCha private constant Cha = iCha(0x075854b315F2cd7eC490853Bc5589B09E546449f);

    struct YieldInfo {
        uint256 mesYield;
        uint256 trueYield;
    }

    function getTrueYieldRateOfAddress(address address_) public view 
    returns (uint256 mesYield, uint256 trueYield) {
        uint256[] memory _wallet = Cha.walletOfOwner(address_);
        uint256 l = _wallet.length;
        uint256 i; unchecked { do {
            trueYield += CC.getCharacterYieldRate(_wallet[i]);
        } while(++i < l); }
        mesYield = MES.getYieldRateOfAddress(address_);
    }

    function getTrueYieldRateOfAddressBatch(address[] calldata addresses_) external view
    returns (YieldInfo[] memory) {
        uint256 l = addresses_.length;
        YieldInfo[] memory _YieldInfos = new YieldInfo[] (l);
        uint256 i; unchecked { do {
            (uint256 _mesYield, uint256 _trueYield) = getTrueYieldRateOfAddress(addresses_[i]);  
            _YieldInfos[i] = YieldInfo(_mesYield, _trueYield);
        } while(++i < l); }
        return _YieldInfos;
    }
}