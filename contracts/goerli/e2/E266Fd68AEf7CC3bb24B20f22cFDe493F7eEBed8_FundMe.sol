//Get funds from users
//withdraw funds
//set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        ); //1e18 == 1 * 10 ** 18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the array
        funders = new address[](0);

        //transfer, send, call
        //payable(msg.sender).transfer(address(this).balance);
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //receive, fallback
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//Chainlink Price Feeds (Data Feeds) Chainlink Data Feeds are the quickest way to connect your smart contracts to the real-world market prices of assets.
//Chainlink VRF Chainlink VRF (Verifiable Random Function) is a provably fair and verifiable random number generator (RNG) that enables smart contracts to access random values without compromising security or usability.
//Chainlink Keepers Chainlink Keepers enable conditional execution of your smart contracts functions through a hyper-reliable and decentralized automation platform that uses the same external network of node operators that secures billions in value.
// ^ for example => every 10minutes, do something

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI와 Address가 필요함.
        //Address 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10); //1*10**10
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000
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