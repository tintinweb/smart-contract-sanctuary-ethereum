/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract MNFTSpecialSaleFacet {

    event SpecialSale(address from, uint32 quantity, uint32 saleId);

    /** 
    @notice Presale ETH
     */
    function presale() external payable {
        require(msg.value >= (10851 gwei), "msg.value too low for presale");
        emit SpecialSale(msg.sender, uint32(msg.value / (10851 gwei)), 1);
    }
}