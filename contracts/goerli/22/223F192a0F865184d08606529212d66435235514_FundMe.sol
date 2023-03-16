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

error NotOwner();

//contract to raise funds for a project
contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 10 * 1e18;
    address[] public funders;
    mapping(address => uint) public funderAmount;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    //  1. where people can fund the project 2. to enable the project to raise funds.
    function fundRaising() public payable {
        //set a minimum amount to fund
        require(
            msg.value.convertedPriceRate(priceFeed) >= MINIMUM_USD,
            "the amount is not enough..."
        );

        //list of funders
        funders.push(msg.sender);

        //map funders with amount funded
        funderAmount[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        //only owner can withdraw
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function withdrawal() public onlyOwner {
        //possibility to withdraw funds
        //3 variables allow to withdraw money call, send transfer. we will use the call variable
        (bool tokenWithdrawn, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(tokenWithdrawn, "You are not the contract Owner...");

        //set funders amount to zero once withdrawal done
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            funderAmount[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //need 3 functions 1. to get the ETH price 2. price version giving by the oracle 3. convert the eth price in dollar
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function convertedPriceRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}