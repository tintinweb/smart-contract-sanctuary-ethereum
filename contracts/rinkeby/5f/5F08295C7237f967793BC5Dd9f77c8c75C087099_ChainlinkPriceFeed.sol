// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceFeed {
    mapping(string => address) public oracleAddress;
    address private owner;

    constructor(string memory _token, address _address) {
        oracleAddress[_token] = _address;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Ownable: Only owner is authorized to perform this action"
        );
        _;
    }

    function getLatestPrice(string memory _token)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            oracleAddress[_token]
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return (uint256(price) * 10**10);
    }

    function addNewTokenOracleAddress(string memory _token, address _address)
        public
        onlyOwner
    {
        oracleAddress[_token] = _address;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
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