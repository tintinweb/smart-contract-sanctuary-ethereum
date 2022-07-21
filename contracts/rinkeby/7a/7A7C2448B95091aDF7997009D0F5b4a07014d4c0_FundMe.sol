//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotEnoughEther();
error WithdrawFailedSend();
error WithdrawFailedCall();
error NotContractOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address public immutable i_owner;

    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    AggregatorV3Interface public immutable i_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOnwer() {
        if (msg.sender != i_owner) {
            revert NotContractOwner();
        }
        _;
    }

    function fund() public payable {
        if (msg.value.getConversionRate(i_priceFeed) >= MINIMUM_USD) {
            revert NotEnoughEther();
        }
        if (s_addressToAmountFunded[msg.sender] == 0) {
            s_funders.push(msg.sender);
        }
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOnwer {
        for (uint256 index = 0; index < s_funders.length; index++) {
            s_addressToAmountFunded[s_funders[index]] = 0;
        }
        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance);
        bool sendSuccess = payable(msg.sender).send(address(this).balance);

        if (!sendSuccess) {
            revert WithdrawFailedSend();
        }

        //call
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!callSuccess) {
            revert WithdrawFailedCall();
        }
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
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
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        int256 multi = int256(1**(18 - decimals));
        return uint256(price * multi);
    }

    // function getVersion(AggregatorV3Interface priceFeed)
    //     internal
    //     view
    //     returns (uint256)
    // {
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
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