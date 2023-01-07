//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/** @title A contract for crowd funding
 *  @author fatima bijabhai
 *  @notice This contract is to demo a sample for funding contract
 *  @dev This contract implements Price Feeds as our library
 */

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUMUSD = 50 * 1e18;
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    address[] private s_funder;
    mapping(address => uint256) private s_addressToAmountFunded;

    modifier onlyOwner() {
        // require(msg.sender == i_owner,"Sender is not Owner!");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
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

    function fund() public payable {
        require(
            msg.value.getconversationRate(s_priceFeed) >= MINIMUMUSD,
            "Not Paying Enough"
        );
        s_funder.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory funder = s_funder;
        for (
            uint256 funderIndex = 0;
            funderIndex < funder.length;
            funderIndex++
        ) {
            s_addressToAmountFunded[s_funder[funderIndex]] = 0;
        }
        s_funder = new address[](0);

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funder[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrize(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in Usd
        // 1000.00000000
        return uint256(price * 1e10); // so our doller should also have 18 decimal places
    }

    // take the input of eth ==> gives equivalate usd
    function getconversationRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return (ethAmount * getPrize(priceFeed)) / 1e18;
    }
}

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