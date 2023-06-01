/**
 *Submitted for verification at Etherscan.io on 2023-06-01
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

contract Lottery {
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
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface ethprice = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer, , , ) = ethprice.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer/10000000);
    }

    function getConversionRate(uint256 usdtoether) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 conversion = (ethPrice * usdtoether);


        // The actual ETH/USD conversation rate, after adjusting the extra 0s
        return conversion;
    }

    function fund() public payable {
        // 18 digit number to be compared with donated amount
        uint256 minimumUSD = 50 * 10**18;
        // Is the donated amount less than 0.1 ETH?
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        // If not, add to mapping and funders array
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

    }

    modifier onlyOwner() {
        // Is the message sender the owner of the contract?
        require(msg.sender == owner);
        _;
    }

    // OnlyOwner modifier will first check the condition inside it
    // and if true, the withdraw function will be executed
   function withdraw() public onlyOwner {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "No funds available for withdrawal");

    // Transfer the contract balance to the owner
    payable(msg.sender).transfer(contractBalance);
}
}