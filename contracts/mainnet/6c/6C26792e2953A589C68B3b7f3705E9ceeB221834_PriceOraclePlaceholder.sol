// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract PriceOraclePlaceholder {
    mapping(address => uint256) assetPrices;

    function getAssetPrice(address asset) external view returns (uint256 price) {
        price = assetPrices[asset];
        if (price == 0) price = 1 ether;
    }

    function setAssetPrice(address asset, uint256 price) external {
        assetPrices[asset] = price;
    }
}