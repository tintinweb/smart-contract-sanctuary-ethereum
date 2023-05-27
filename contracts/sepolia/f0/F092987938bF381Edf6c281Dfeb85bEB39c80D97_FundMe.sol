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

pragma solidity ^0.8.14;

import "./PriceConverter.sol";

// constant, immutable
error FundMe__NotOwner();

/** @title A contract for fund raising
 * @author Robert Kirwa
 * @notice A contract to sample funding contracts
 * @dev this implements pricefeed as our library
 */

contract FundMe {
      using PriceConverter for uint256;

      mapping(address => uint256) private s_addressToAmountFunded;
      address[] private s_funders;
      address private immutable i_owner;
      uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
      AggregatorV3Interface public priceFeed;

      modifier onlyOwner() {
            if (msg.sender != i_owner) revert FundMe__NotOwner();
            _;
            //require(msg.sender == i_owner, "sender is not owner!");
      }

      constructor(address priceFeedAddress) {
            i_owner = msg.sender;
            priceFeed = AggregatorV3Interface(priceFeedAddress);
      }

      //receiving funds without calling
      receive() external payable {
            fund();
      }

      fallback() external payable {
            fund();
      }

      function fund() public payable {
            require(
                  msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
                  "Didn't send Enough!"
            );
            s_addressToAmountFunded[msg.sender] += msg.value;
            s_funders.push(msg.sender);
      }

      function withdraw() public onlyOwner {
            /*starting index, ending index, step amount */
            for (
                  uint256 funderIndex = 0;
                  funderIndex < s_funders.length;
                  funderIndex++
            ) {
                  address funder = s_funders[funderIndex];
                  s_addressToAmountFunded[funder] = 0;
            }
            //reset the array
            s_funders = new address[](0);
            (bool callsuccess, ) = payable(msg.sender).call{
                  value: address(this).balance
            }("");
            require(callsuccess, "call failed");
      }

      function cheaperWithdraw() public payable onlyOwner {
            address[] memory funders = s_funders;
            for (
                  uint256 funderIndex = 0;
                  funderIndex < funders.length;
                  funderIndex++
            ) {
                  address funder = funders[funderIndex];
                  s_addressToAmountFunded[funder] = 0;
            }
            s_funders = new address[](0);
            (bool success, ) = i_owner.call{value: address(this).balance}("");
            require(success);
      }

      function getOwner() public view returns (address) {
            return i_owner;
      }

      function getFunder(uint256 index) public view returns (address) {
            return s_funders[index];
      }

      function getAddressToAmountFunded(
            address funder
      ) public view returns (uint256) {
            return s_addressToAmountFunded[funder];
      }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
      function getPrice(
            AggregatorV3Interface priceFeed
      ) internal view returns (uint256) {
            (, int256 price, , , ) = priceFeed.latestRoundData();
            return uint256(price * 1e10); //1**10 == 10000000000
      }

      function getConversionRate(
            uint256 ethAmount,
            AggregatorV3Interface priceFeed
      ) internal view returns (uint256) {
            uint256 ethPrice = getPrice(priceFeed);
            //2794_900000000000000000 ETH/USD
            //1_000000000000000000 ETH
            uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
            return ethAmountInUsd;
      }
}