/**
 *Submitted for verification at Etherscan.io on 2023-06-13
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



pragma solidity ^0.8.18;



library PriceConverter {
        function getPrice() internal view returns (uint256) {
        // ABI’
       // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // Eth in terms of USD 
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getVersion() internal view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }


    function getConversionRate(uint256 ethAmount) internal view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount / 1e18);
        return  ethAmountInUsd;
    }


    
}
// File: contracts/FundMe.sol



// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

pragma solidity ^0.8.18;


error NotOwner();

contract FundMe{

    using PriceConverter for uint256;

// 810,098
// 790,140
    uint256 public constant MINIMUM_USD = 5e18; // 5 * 1e18
 
 //2451 - non constant
 // 351 - constant
 
    address[] public funders;
    mapping (address funder => uint256 amountFunded) public addressToAmountFunded;
    address public  immutable i_owner;


    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable{
        // Want to be able to set a minim fund amount in USD.
        //1. How do we send ETH to this contract ? 
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't sent enough eth");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]= 0; 
        }
        funders = new address[](0);
        //call
       (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
           require(callSuccess, "Call failed");

    }

    modifier onlyOwner(){
        //require(msg.sender == i_owner,"You're not the owner!");
        if(msg.sender != i_owner) {revert NotOwner(); }
        _;
    }

    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }
}