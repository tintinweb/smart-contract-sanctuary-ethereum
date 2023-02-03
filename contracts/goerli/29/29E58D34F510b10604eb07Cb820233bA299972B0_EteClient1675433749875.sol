// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol"; // Price converter with chainlink integration to convert prices

error EteClient__NotOwner();
error EteClient__InvalidInput();

/**@title Ete Client
 * @author Ete-services
 * @notice Solidity sample for you to test
 * @dev This implements chainlin price feeds as a library
 */
contract EteClient1675433749875 {
    using PriceConverter for uint256;

    /* AggregatorV3Interface private s_priceConverter; */
    AggregatorV3Interface private s_priceFeed;
    uint256 public constant INVALID_INPUT = 911;
    address private immutable i_owner;
    address[] private s_users;
    uint256 private s_pennyBank;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert EteClient__NotOwner();
        _;
    }

    /* constructor(address _priceConverter) { */
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    /** @notice Add user
     *  @param newUser address of new user
     */
    function addUser(address newUser) public {
        s_users.push(newUser);
    }

    /** @notice List all users
     *  @return array of addresses
     */
    function listUsers() public view returns(address[] memory) {
      return s_users;
    }

    function validate(uint256 input) public pure returns(bool){
        if (input == INVALID_INPUT) revert EteClient__InvalidInput();
        return true;
    }

    function addMoney() public payable {
        s_pennyBank += msg.value;
        s_users.push(msg.sender);
    }

    function onlyOwnerFunction13809858() public onlyOwner view returns(uint256) {
      return 10452;
    }

    function convert(uint256 input) public view returns(uint256) {
      return input.getConversionRate(s_priceFeed); // Convert ETH to USD
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getOwner() public view returns (address) {
        return i_owner;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}