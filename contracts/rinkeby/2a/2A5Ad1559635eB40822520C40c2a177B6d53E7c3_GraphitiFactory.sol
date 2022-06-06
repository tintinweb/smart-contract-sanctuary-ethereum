// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract GraphitiFactory {
    // Save the owner address
    address public owner;

    // Contract to get accurate pricing data
    AggregatorV3Interface public priceFeed;

    // Client Object
    struct Client {
        address clientAddress;
    }

    // Phaestus Object
    struct Phaestus {
        address phaestusAddress;
    }

    // Session Request Object:
    struct SessionRequest {
        uint8 numCPUs;
        uint8 numGPUs;
        uint16 totalTime;
    }

    // Mappings for user addresses to Clients or Phaestus nodes.
    mapping(address => Client) addressToClient;
    mapping(address => Phaestus) addressToPhaestus;

    //Storing Clients and Phaestus Nodes in arrays
    Client[] clients;
    Phaestus[] phaestusNodes;

    // Constructor
    // constructor(address _priceFeed) public {
    //     priceFeed = AggregatorV3Interface(_priceFeed);
    //     owner = msg.sender;
    // }

    // Returns collateral amount to be fronted for mallicious behaviour.
    // Will be returned to the user after the session is over.
    function calculateCollateral(SessionRequest memory sessionRequest)
        public
        pure
        returns (uint256)
    {
        return sessionRequest.totalTime;
    }

    // Testing function, might get rid of it later
    function getNumberOfClients() public view returns (uint256) {
        return clients.length;
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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