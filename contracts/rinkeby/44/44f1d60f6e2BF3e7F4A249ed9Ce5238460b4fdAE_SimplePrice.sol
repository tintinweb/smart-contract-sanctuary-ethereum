// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "Price.sol";
import "ERC20.sol";
contract SimplePrice is Price {
    mapping(address => uint) prices;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);
    function _getUnderlyingAddress(Token token) private view returns (address) {
        address asset;
        if (compareStrings(token.symbol(), "ETH")) {
            asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            asset = address(ERC20(address(token)).underlying());
        }
        return asset;
    }
    function getUnderlyingPrice(Token token) public view override returns (uint) {
        return prices[_getUnderlyingAddress(token)];
    }
    function setUnderlyingPrice(Token token, uint underlyingPriceMantissa) public {
        address asset = _getUnderlyingAddress(token);
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }
    function setDirectPrice(address asset, uint price) public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }
    // v1 price  interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}