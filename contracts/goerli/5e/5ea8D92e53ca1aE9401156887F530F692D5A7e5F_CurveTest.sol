// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract CurveTest {
    function getWeiPrice(
        uint256 startingPrice,
        uint256 maxSupply,
        uint256 tokenId
    ) public pure returns (uint256) {
        return (startingPrice * maxSupply**2) / ((maxSupply - tokenId)**2);
    }
}