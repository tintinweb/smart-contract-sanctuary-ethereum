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

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    // constant and immutable keywords save gas
    address public immutable owner;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    mapping(address => uint256) addressToAmount;
    address[] public funders;

    AggregatorV3Interface priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not Authorized");
        _;
    }

    function fund() public payable {
        // want to set minimum value

        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "amount should be greater than 1"
        );
        funders.push(msg.sender);
        addressToAmount[msg.sender] += msg.value;
        // want to send ether
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmount[funder] = 0;
        }
        funders = new address[](0);

        // withdraw money

        // //transfer
        // payable(msg.sender).transfer(address(this).balance);

        // //send
        // bool success =  payable(msg.sender).send(address(this).balance);
        // require(success,"send failed");

        // call

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    // if the transaction is done without msg.data then recieve function will be triggered

    // else fallback

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getUSDPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 amount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getUSDPrice(priceFeed);
        uint256 totalAmount = (ethPrice * amount) / 1e18;
        return totalAmount;
    }
}