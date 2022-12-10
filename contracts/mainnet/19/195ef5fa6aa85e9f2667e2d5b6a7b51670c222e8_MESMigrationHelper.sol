/**
 *Submitted for verification at Etherscan.io on 2022-12-10
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

    function getTrueYieldRateOfAddress(address address_) external view 
    returns (uint256 mesYield, uint256 trueYield) {
        uint256[] memory _wallet = Cha.walletOfOwner(address_);
        uint256 l = _wallet.length;
        uint256 i; unchecked { do {
            trueYield += CC.getCharacterYieldRate(_wallet[i]);
        } while(++i < l); }
        mesYield = MES.getYieldRateOfAddress(address_);
    }
}