/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/PriceConverter.sol



pragma solidity ^0.8.0;

// Cannot contain state variables
// Cannot send Ether
// Must be internal functions


library PriceConverter {
    
    // Returns price of ETH in USD
    function getPrice() internal view returns (uint) {
        // ABI --> Provided by an interface
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function getConversionRate(uint256 _ethAmount) internal view returns (uint) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

}
// File: contracts/FundMe.sol



pragma solidity ^ 0.8.0;


contract FundMe {

    using PriceConverter for uint256;

    uint256 public minimumDeposit = 50 * 1e18;

    address public owner;    
    address[] public funders;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function updateMinimumDeposit(uint256 _newDepositMinimum) public {
        minimumDeposit = _newDepositMinimum;
    }

    function fund() public payable {
        // favouriteNumber = 10; --> This change will get reverted back to the original value of 0
        // Set minimum fund amount in USD
        require(msg.value.getConversionRate() >= minimumDeposit, "Minimum deposit must be greater than $50");
        // Only consumes gas up to the require(), any computation costs after the require() are saved
        funders.push(msg.sender);
        balances[msg.sender] += msg.value;

    }

    function withdraw() public onlyOwner {

        // Unable to loop through the mapping, iterate through the array to get the keys for the mapping
        // Starting index, ending index, step amount or increment amount
        for(uint i; i < funders.length; i++) {
            address funder = funders[i];
            balances[funder] = 0;
        }

        // Reset the array
        funders = new address[](0);

        // Sending funds back to users

        // Transfer - must cast address as payable
        payable(msg.sender).transfer(address(this).balance);
        // Send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Ether transfer via send has failed");
        // Call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Ether transfer via call has failed");
    }

    receive() external payable {

    }
}