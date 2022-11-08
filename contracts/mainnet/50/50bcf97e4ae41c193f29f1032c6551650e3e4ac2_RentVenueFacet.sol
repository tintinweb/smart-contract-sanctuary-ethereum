/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/facets/RentVenueFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract RentVenueFacet {

    event RentVenue(address from, uint128 value, uint8 currency);

    /**
    @notice Rent venue with blockchain coin
     */
    function rentVenue() external payable {
        emit RentVenue(msg.sender, uint128(msg.value), 0);
    }

    /**
    @notice Rent venue with MNFT
     */
    function rentVenueWithMNFT(uint256 amount) external {
        emit RentVenue(msg.sender, uint128(amount), 1);
    }
}