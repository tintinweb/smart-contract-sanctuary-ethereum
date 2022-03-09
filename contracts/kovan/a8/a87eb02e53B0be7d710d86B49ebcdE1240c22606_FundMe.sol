// SPDX-License-Identifier: MIT

// Declaration of Solidity version.
pragma solidity >=0.7.0 <0.9.0;

// importing chainlink price feeds to contract.
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        // Allow funding in dollars with minimum at $50
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversationRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!!!"
        );
        addressToAmountFunded[msg.sender] += msg.value;

        // push funder each time they fund an address
        funders.push(msg.sender);

        // In other to send funds in USD we need to know the Conversation rate from Eth => USD
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        // we can return the tuple without initializing the var to make code cleaner and remove console warnings
        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();

        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function getConversationRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * _ethAmount) / 1000000000000000000;

        return ethAmountInUSD;
    }

    /**
        Modifies are used to change the behaviour of a function in a declarative way.
    **/
    modifier onlyOwner() {
        require(msg.sender == owner, "Admin user");
        _;
    }

    // withdraw funds
    function withdraw() public payable onlyOwner {
        payable(owner).transfer(address(this).balance);

        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }

        // set funders to a new array after update

        funders = new address[](0);
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