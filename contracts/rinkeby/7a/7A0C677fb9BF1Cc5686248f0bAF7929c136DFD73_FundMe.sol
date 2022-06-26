// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__InsufficientETH();

contract FundMe {
    //using priceConverter library
    using PriceConverter for uint256;

    //init owner
    address private immutable i_owner;

    //min USD
    uint256 public constant MIN_USD = 50 * 1e18;

    //funders array and mapping
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    AggregatorV3Interface private s_priceFeed;

    //constructor: called immediately when contract is deployed
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //sends funds to contract
    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MIN_USD) {
            revert("Insufficient ETH");
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    //withdraw funds from contract
    function withdraw() public onlyOwner {
        //setting every funders "amount funded" to '0'
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        //clearing funders list
        s_funders = new address[](0);
        //withdrawing the money
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert("call failed");
        }
    }

    //requires the sender to == the owner before the remaining code is run
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings cant be memory

        for (uint256 fI = 0; fI < funders.length; fI++) {
            address funder = funders[fI];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if (!success) {
            revert();
        }
    }

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

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 p, , , ) = priceFeed.latestRoundData();
        uint256 price = uint256(p * 1e10);
        return (ethAmount * price) / 1e18;
    }
}