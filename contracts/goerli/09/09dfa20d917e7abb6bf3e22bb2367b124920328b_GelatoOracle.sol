pragma solidity ^0.8.15;

import "./interfaces/IOracle.sol";

contract GelatoOracle is IOracle {
    PriceData lastPrice;
    /// @notice min price deviation to accept a price update
    uint256 public deviation;
    address public dataProvider;
    uint8 _decimals;
    /// @notice heartbeat duration in seconds
    uint40 public heartBeat;

    modifier onlyDataProvider() {
        require(msg.sender == dataProvider, "onlyDataProvider");
        _;
    }

    modifier ensurePriceDeviation(uint256 newValue) {
        if (_computeDeviation(newValue) > deviation) {
            _;
        }
    }

    function _computeDeviation(uint256 newValue)
        internal
        view
        returns (uint256)
    {
        if (lastPrice.price == 0) {
            return deviation + 1; // return the deviation amount if price is 0, so that the update will happen
        } else if (newValue > lastPrice.price) {
            return ((newValue - lastPrice.price) * 1e20) / lastPrice.price;
        } else {
            return ((lastPrice.price - newValue) * 1e20) / lastPrice.price;
        }
    }

    constructor(
        uint256 deviation_,
        uint8 decimals_,
        uint40 heartBeat_,
        address dataProvider_
    ) {
        _decimals = decimals_;
        deviation = deviation_;
        heartBeat = heartBeat_;
        dataProvider = dataProvider_;
    }

    // to be called by gelato bot to know if a price update is needed
    function isPriceUpdateNeeded(uint256 newValue)
        external
        view
        returns (bool)
    {
        if ((lastPrice.timestamp + heartBeat) < block.timestamp) {
            return true;
        } else if (_computeDeviation(newValue) > deviation) {
            return true;
        }
        return false;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function setPrice(uint256 _value) external onlyDataProvider {
        lastPrice.price = uint128(_value);
        lastPrice.timestamp = uint128(block.timestamp);

        emit NewValue(lastPrice.price, lastPrice.timestamp);
    }

    function getPrice() external view override returns (PriceData memory) {
        return lastPrice;
    }
}

pragma solidity ^0.8.13;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}