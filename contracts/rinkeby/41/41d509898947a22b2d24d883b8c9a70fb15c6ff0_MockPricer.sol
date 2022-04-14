// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

// import {OracleInterface} from "../interfaces/OracleInterface.sol";

contract MockPricer {
    // OracleInterface public oracle;

    uint256 internal price;
    address public asset;

//    constructor(address _asset, address _oracle) public {
//        asset = _asset;
//        oracle = OracleInterface(_oracle);
//    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

//    function setExpiryPriceInOracle(uint256 _expiryTimestamp, uint256 _price) external {
//        oracle.setExpiryPrice(asset, _expiryTimestamp, _price);
//    }
//
//    function getHistoricalPrice(uint80 _roundId) external view returns (uint256, uint256) {
//        return (price, now);
//    }
}