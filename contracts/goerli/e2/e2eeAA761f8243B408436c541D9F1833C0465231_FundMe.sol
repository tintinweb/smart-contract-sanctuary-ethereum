//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Priceconverter.sol";

error notOwner();

contract FundMe {
    using Priceconverter for uint256;
    uint256 public minUSD = 50 * 1e18;
    address immutable owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funders;
    mapping(address => uint256) public FunderToAmount;

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= minUSD,
            "Didn't send enough"
        );
        FunderToAmount[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public OnlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            FunderToAmount[funders[funderIndex]] = 0;
        }
        funders = new address[](0);
        (bool Callsuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(Callsuccess, "Call Transaction Failure");
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;
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

library Priceconverter {
    function getPrice(AggregatorV3Interface pricefeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface pricefeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = pricefeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion(AggregatorV3Interface pricefeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface pricefeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        return pricefeed.version();
    }

    function getConversionRate(
        uint256 ethamount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethprice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethprice * ethamount) / 1e18;
        return ethAmountInUSD;
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