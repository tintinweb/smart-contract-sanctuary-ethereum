// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract ReceiveEther {
    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract SendEther {
    function sendViaTransfer(address payable _to) public payable {
        _to.transfer(msg.value);
    }
}

contract FundingWithDollars {
    AggregatorV3Interface internal priceFeed;
    mapping(uint256 => address) public addressToAmountFunded;
    uint256 public fundingIndex;
    address public owner;
    address payable[] public players;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        owner = msg.sender;
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        //0.0000016151267820800
    }

    function fund() public payable {
        //uint256 fiveDollars = amountInWeiNeeded();
        uint256 fiveDollars = 5 * 10**18;
        require(
            getConversionRate(msg.value) >= fiveDollars,
            "You need to spend more ETH!!"
        );

        players.push(payable(msg.sender));
        addressToAmountFunded[fundingIndex] = players[fundingIndex];
        fundingIndex++;
    }

    function LocalFund() public payable {
        require(msg.value > 0.1 ether, "You need to spend at least 0.1 Eth!!");
        players.push(payable(msg.sender));
        addressToAmountFunded[fundingIndex] = players[fundingIndex];
        fundingIndex++;
    }

    function getRandomNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function withdraw() public payable onlyOwner {
        uint256 index = getRandomNumber() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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