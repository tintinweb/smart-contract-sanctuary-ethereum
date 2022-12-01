//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.9;
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        // Cuanto ETH > USD
        uint256 minimumUSD = 1 * 10 * 18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more eth"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        (
            ,
            // (uint80 roundID,
            int256 price, // uint startedAt, // uint timeStamp, // uint80 answeredInRound
            ,
            ,

        ) = priceFeed.latestRoundData();

        // return uint256(price);
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSDT = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSDT;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede retirar fondos");
        _; // significa que el resto del código lo ejecute ahí
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // el (0) es para inicializarlo y es necesario
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