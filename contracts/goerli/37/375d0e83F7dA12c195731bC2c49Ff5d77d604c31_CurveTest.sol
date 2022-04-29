// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract CurveTest {
    function getEtherPriceOf(
        uint256 startingPrice,
        uint256 slope,
        uint256 maxSupply,
        uint256 tokenId
    ) public pure returns (uint256) {
        return (startingPrice * slope) / (((maxSupply - tokenId)**2) * 1 ether);
    }

    function getWeiPriceOf(
        uint256 startingPrice,
        uint256 slope,
        uint256 maxSupply,
        uint256 tokenId
    ) public pure returns (uint256) {
        return (startingPrice * slope) / ((maxSupply - tokenId)**2);
    }
}