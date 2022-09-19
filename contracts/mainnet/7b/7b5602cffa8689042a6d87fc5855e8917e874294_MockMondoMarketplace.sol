/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract MockMondoMarketplace {

    function getForSaleCount(uint256 tokenID, address owner) external view returns (uint256) {
        return IERC1155(0xA3A5C1fa196053D5DE78AcFb98238276E546064d).balanceOf(owner, tokenID);
    }

    function cancelSaleToTransfer(address, uint256, uint8) external pure {
        return;
    }

}