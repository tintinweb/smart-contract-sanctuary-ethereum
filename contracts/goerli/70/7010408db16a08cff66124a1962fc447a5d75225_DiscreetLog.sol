/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/DiscreetLog.sol

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


// import "@openzeppelin/contracts/access/AccessControl.sol";

contract DiscreetLog {
    string[] public openUUIDs;
    mapping(string => DLC) public dlcs;

    struct DLC {
        string uuid;
        string asset;
        int256 strikePrice;
        int256 closingPrice;
        uint256 closingTime;
        uint256 actualClosingTime;
        uint256 emergencyRefundTime;
        address feedAddress;
    }

    event CreateDLC(
        string asset,
        int256 strikePrice,
        uint256 closingTime,
        uint256 emergencyRefundTime,
        address creator,
        address callbackContract,
        uint256 nonce,
        address feedAddress
    );

    function createDlc(
        string calldata _asset,
        int256 _strikePrice,
        uint256 _closingTime,
        uint256 _emergencyRefundTime,
        address _callbackContract,
        uint256 _nonce,
        address _feedAddress
    ) external {
        emit CreateDLC(
            _asset,
            _strikePrice,
            _closingTime,
            _emergencyRefundTime,
            msg.sender,
            _callbackContract,
            _nonce,
            _feedAddress
        );
    }

    event CreateDLCInternal(
        string uuid,
        string asset,
        int256 strikePrice,
        uint256 closingTime,
        uint256 emergencyRefundTime,
        address caller,
        address feedAddress
    );

    function createDLCInternal(
        string memory _uuid,
        string memory _asset,
        int256 _strikePrice,
        uint256 _closingTime,
        uint256 _emergencyRefundTime,
        address _creator,
        // address _callbackContract, // to be used when we have the protocol sample contract
        // uint256 _nonce,
        address _feedAddress
    ) external {
        require(dlcs[_uuid].feedAddress == address(0), "DLC already added");
        dlcs[_uuid] = DLC({
            uuid: _uuid,
            asset: _asset,
            strikePrice: _strikePrice,
            closingTime: _closingTime,
            closingPrice: 0,
            actualClosingTime: 0,
            emergencyRefundTime: _emergencyRefundTime,
            feedAddress: _feedAddress
        });
        openUUIDs.push(_uuid);
        emit CreateDLCInternal(
            _uuid,
            _asset,
            _strikePrice,
            _closingTime,
            _emergencyRefundTime,
            _creator,
            _feedAddress
        );
    }

    event CloseDLC(
        string uuid,
        int256 payoutRatio,
        int256 closingPrice,
        uint256 actualClosingTime
    );

    function closeDlc(string calldata _uuid) external {
        DLC storage dlc = dlcs[_uuid];
        require(
            dlc.closingTime <= block.timestamp && dlc.actualClosingTime == 0,
            "Validation failed for closeDlc"
        );

        (int256 price, uint256 timestamp) = getLatestPrice(dlc.feedAddress);
        dlc.closingPrice = price;
        int256 payoutRatio = dlc.strikePrice > price ? int256(0) : int256(1);

        removeClosedDLC(findIndex(_uuid));
        emit CloseDLC(_uuid, payoutRatio, price, timestamp);
    }

    // function closingPriceAndTimeOfDLC(string memory _uuid)
    //     external
    //     view
    //     returns (int256, uint256)
    // {
    //     DLC memory dlc = dlcs[_uuid];
    //     require(
    //         dlc.actualClosingTime > 0,
    //         "The requested DLC is not closed yet"
    //     );
    //     return (dlc.closingPrice, dlc.actualClosingTime);
    // }

    // function allOpenDLC() external view returns (string[] memory) {
    //     return openUUIDs;
    // }

    function getLatestPrice(address _feedAddress)
        internal
        view
        returns (int256, uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_feedAddress);
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();
        return (price, timeStamp);
    }

    // note: this remove not preserving the order
    function removeClosedDLC(uint256 index) private returns (string[] memory) {
        require(index < openUUIDs.length);
        // Move the last element to the deleted spot
        openUUIDs[index] = openUUIDs[openUUIDs.length - 1];
        // Remove the last element
        openUUIDs.pop();
        return openUUIDs;
    }

    function findIndex(string memory _uuid) private view returns (uint256) {
        // find the recently closed uuid index
        for (uint256 i = 0; i < openUUIDs.length; i++) {
            if (
                keccak256(abi.encodePacked(openUUIDs[i])) ==
                keccak256(abi.encodePacked(_uuid))
            ) {
                return i;
            }
        }
        revert("Not Found"); // should not happen just in case
    }
}