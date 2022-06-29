// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 *   @title A contract for crowdfunding
 *   @author Patrick Collins
 *   @notice This is a demo contract
 *   @dev This implements price feeds as our library
 */

contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 1 * 1e18; //
    uint256 private s_AmountInDollar;
    uint256 private s_AmountInEuro;
    uint256 private s_Value = msg.value;

    AggregatorV3Interface private s_ethUsdPriceFeed;
    AggregatorV3Interface private s_eurUsdPriceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address ethUsdPriceFeedAddress, address eurUsdPriceFeedAddress)
    {
        i_owner = msg.sender;
        s_ethUsdPriceFeed = AggregatorV3Interface(ethUsdPriceFeedAddress);
        s_eurUsdPriceFeed = AggregatorV3Interface(eurUsdPriceFeedAddress);
    }

    function fund() public payable {
        // require value to be at least 1ETH
        require(
            msg.value.getConversionRate(s_ethUsdPriceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function getEuroPrice() public returns (uint256) {
        s_AmountInDollar = s_Value.getConversionRate(s_ethUsdPriceFeed);
        s_AmountInEuro = s_AmountInDollar.getConversionRate(s_eurUsdPriceFeed);
        return s_AmountInEuro;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //code
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // actually withdraw funds - there are three ways

        // transfer
        // payable(msg.sender) = payable address
        //payable(msg.sender).transfer(address(this).balance);

        // send (will only revert with require statement)
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // the above array once written to memory is MUCH cheaper!
        // mappings can't be in memory!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            //code
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    // View / Pure Functions

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getEthUsdPriceFeed() public view returns (AggregatorV3Interface) {
        return s_ethUsdPriceFeed;
    }

    function getEurUsdPriceFeed() public view returns (AggregatorV3Interface) {
        return s_eurUsdPriceFeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        // The wrapped uint256 is a typecaster that changes int256 to uint256
        return uint256(answer * 1e10); // 1**10 == 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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