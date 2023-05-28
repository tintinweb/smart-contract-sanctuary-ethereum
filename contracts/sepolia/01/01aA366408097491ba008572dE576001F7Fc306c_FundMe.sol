/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId)
    external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
  function latestRoundData()
    external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract FundMe {
    // Mapping to store which address deposited how much ETH
    mapping(address => uint256) public addressToAmountFunded;
    // Array of addresses who deposited
    address[] public funders;
    // Address of the owner (who deployed the contract)
    address public owner;

    // The first person to deploy the contract is the owner
    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // 18 digit number to be compared with donated amount
        uint256 minimumUSD = 0.1 * 10**18;
        // Is the donated amount less than 0.1 ETH?
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        // If not, add to mapping and funders array
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // The actual ETH/USD conversation rate, after adjusting the extra 0s
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        // Is the message sender the owner of the contract?
        require(msg.sender == owner, "Only the contract owner can withdraw funds");
        _;
    }

    // OnlyOwner modifier will first check the condition inside it
    // and if true, the withdraw function will be executed
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}