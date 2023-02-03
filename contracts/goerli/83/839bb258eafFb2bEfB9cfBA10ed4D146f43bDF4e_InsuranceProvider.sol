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

contract InsuranceConsumer {
    AggregatorV3Interface internal priceFeed;
    address payable public insurer;
    address payable client;
    uint256 startDate;
    uint256 premium;
    uint256 payoutValue;

    constructor(
        address payable _client,
        uint256 _premium,
        uint256 _payoutValue
    ) payable {
        //set ETH/USD Price Feed
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        //first ensure insurer has fully funded the contract
        require(
            msg.value >= _payoutValue / uint256(getLatestPrice()),
            "Not enough funds sent to contract"
        );

        //now initialize values for the contract
        insurer = payable(msg.sender);
        client = _client;
        startDate = block.timestamp; //contract will be effective immediately on creation
        premium = _premium;
        payoutValue = _payoutValue;
    }

    function payOutContract() public {
        //Transfer agreed amount to client
        client.transfer(address(this).balance);
    }

    function refundToInsurer(address payable _insurer) public {
        // Transfer back the amount to insurer
        _insurer.transfer(address(this).balance);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./InsuranceConsumer.sol";

contract InsuranceProvider {
    address payable public insurer;
    AggregatorV3Interface internal priceFeed;

    modifier onlyOwner() {
        require(insurer == msg.sender, "Only Insurance provider can do this");
        _;
    }

    constructor() payable {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        insurer = payable(msg.sender);
    }

    function newContract(
        address payable _client,
        uint256 _premium,
        uint256 _payoutValue
    ) public payable onlyOwner returns (address) {
        //create contract, send payout amount so contract is fully funded plus a small buffer
        InsuranceConsumer i = (new InsuranceConsumer){
            value: ((_payoutValue * 1 ether) / (uint256(getLatestPrice())))
        }(_client, _premium, _payoutValue);

        return address(i);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function payOutContract(address _contract) public onlyOwner {
        // Transfer agreed amount to client
        InsuranceConsumer i = InsuranceConsumer(_contract);
        i.payOutContract();
    }

    function refundToInsurer(address _contract) public onlyOwner {
        // Transfer back the amount to insurer
        InsuranceConsumer i = InsuranceConsumer(_contract);
        i.refundToInsurer(insurer);
    }
}