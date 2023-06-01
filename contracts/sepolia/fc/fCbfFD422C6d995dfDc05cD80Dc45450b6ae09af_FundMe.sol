// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();
error CallFailed();
error NotEnoughEth();

contract FundMe {
    // type declarations
    using PriceConverter for uint256;

    //state variables
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 15 * 1e18;
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    AggregatorV3Interface public s_priceFeed;

    modifier OnlyOwner() {
        // require(msg.sender == i_owner, "caller not owner");
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /// @notice funds the contract
    /// @dev implements price feeds
    function fund() public payable {
        // require(msg.value.getConversionRate() >= MINIMUM_USD, "Not enough eth");
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD)
            revert NotEnoughEth();
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable OnlyOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            delete s_addressToAmountFunded[funders[i]];
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // returns success boolean and any return bytes data from the called contract
        // require(callSuccess, "call failed");
        if (!callSuccess) revert CallFailed();
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (ethAmount * uint256(price * 1e10)) / 1e18;
    }
}