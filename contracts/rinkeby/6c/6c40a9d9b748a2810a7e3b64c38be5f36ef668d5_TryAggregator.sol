pragma solidity 0.8.12;

import "./AggregatorV3Interface.sol";

contract TryAggregator {

    function getRoundData(address oracle, uint80 _roundId) external view returns (int256, uint256) {
        try AggregatorV3Interface(oracle).getRoundData(_roundId) returns (
            uint80 ,
            int256 _price,
            uint256 ,
            uint256 _timestamp,
            uint80
        ) {
            return (_price, _timestamp);
        } catch {}
        return (0, 0);
    }

}