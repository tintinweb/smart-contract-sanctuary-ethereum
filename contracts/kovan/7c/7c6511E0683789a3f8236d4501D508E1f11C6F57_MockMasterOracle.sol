// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract MockMasterOracle {
    uint256 private constant PRICE_PRECISION = 1e18;
    uint256 public usdcPrice = 1e18;
    uint256 public dollarPrice = 1e18;
    uint256 public sharePrice;
    uint256 public dollarTwapPrice;
    uint256 public shareTwapPrice;

    function getUsdcPrice() public view returns (uint256) {
        return usdcPrice;
    }

    function getDollarPrice() public view returns (uint256) {
        return dollarPrice;
    }

    function getDollarTWAP() public view returns (uint256) {
        return dollarTwapPrice;
    }

    function getSharePrice() public view returns (uint256) {
        return sharePrice;
    }

    function getShareTWAP() public view returns (uint256) {
        return shareTwapPrice;
    }

    function getSpotPrices()
        external
        view
        returns (
            uint256 _sharePrice,
            uint256 _dollarPrice,
            uint256 _usdcPrice
        )
    {
        _sharePrice = getSharePrice();
        _dollarPrice = getDollarPrice();
        _usdcPrice = getUsdcPrice();
    }

    function setPrice(
        uint256 _usdcPrice,
        uint256 _dollarPrice,
        uint256 _sharePrice
    ) external {
        usdcPrice = _usdcPrice;
        dollarPrice = _dollarPrice;
        sharePrice = _sharePrice;
    }

    function setTWAPPrice(uint256 _dollarPrice, uint256 _sharePrice) external {
        dollarTwapPrice = _dollarPrice;
        shareTwapPrice = _sharePrice;
    }
}