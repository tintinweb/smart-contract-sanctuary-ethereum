// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract FundMe {
    // we can call now priceConverter functions with uint256 values.
    using PriceConverter for uint256;
    // constant and immutable veriables are much gas efficient.
    uint256 public constant MINUMUM_USD = 50 * 10**18;

    address[] public funders;
    mapping(address => uint256) public adressToAmountOfFunded;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // In order to send or withdraw money with function you need to mark the
    // function by payable keyword.
    function fund() public payable {
        // msg.value got used into getConversionRate as firstparameter.
        require(
            msg.value.getConversionRate(priceFeed) >= MINUMUM_USD,
            "You need to spend more ETH"
        );
        funders.push(msg.sender);
        adressToAmountOfFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            adressToAmountOfFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);

        // 3 steps for withdrawing the funds
        // 1.transfering
        // payable(msg.sender).transfer(address(thsi).balance);
        // you need to cast address to payable so you could use transfer functions alike.
        // if transfers fails, program will throw an error and return back the money.
        // 2.sending
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success, "Sending failed");
        // when you use send method, method will return bool then you use it with
        // require function to return back the money.
        // 3.calling (recomended)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only the owner withdraws the funds.");
        // The underscore represents here is the rest of the code.
        _;
    }

    // sending money without fund method.
    receive() external payable {
        fund();
    }

    // receiving money with data.
    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// libraries can't have state variables, functions can't send eth or withdraw it.
// all libraries functions are internal
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmounth,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmounthInUsd = (ethPrice * ethAmounth) / 1e18;
        return ethAmounthInUsd;
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