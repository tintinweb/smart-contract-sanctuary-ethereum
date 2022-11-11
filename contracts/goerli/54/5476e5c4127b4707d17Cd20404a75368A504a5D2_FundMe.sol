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
pragma solidity ^0.8.8;

// Importing a library
import "./PriceConverter.sol";

// Custom error

error NotOwner();

// Creating this contract before the changes costs 	837.321
contract FundMe {

    // Using a library
    using PriceConverter for uint256;

    // we need the keyword payable
    // Smart contracts can hold funds just like how wallets can

    // uint256 public minimumUsd = 50 * 1e18; // 1 * 10 **18

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 **18
    // constant / immutable keywords help us save gas


    // Array of funders
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // using immutable 
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;
    // Set owner of contract
    // Solidity constructor
    constructor(address priceFeedAddress){
        // msg.sender will be whoever deploys the contract
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }

    function fund() public payable{
        
            require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You didn't send enough"); 
            // 18 decimals
        
        // msg.sender is available in all contracts. It will refer to the wallet address
        funders.push(msg.sender);
        // mapping the funders with amounts
        addressToAmountFunded[msg.sender] = msg.value;

    }

// Allows to withdraw funds in this contract
    function withdraw() public onlyOwner {

        for (uint256 funderIndex = 0; funderIndex <funders.length; funderIndex++){
            //code
           address funder = funders[funderIndex];
           addressToAmountFunded[funder] = 0;
        }

        // reset array
        funders = new address[](0);
     
        // Most recormmended method to transfer
       (bool callSuccess, )  = payable(msg.sender).call{value: address(this).balance}("");
       require(callSuccess, "Call failed");
    }

    // A modifier is a keyword we add to our function to modify the execution of the function
    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner");
        if(msg.sender != i_owner) {revert NotOwner();}
        _;
    }

    // What happends if someonse sends this contract ETH without calling fund()

    // receive()

    receive() external payable {
        fund();
    }

    fallback() 
    external payable{
        fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Importing a NPM package
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similiar to contracts but they can't declare any state or send ether

library PriceConverter {

    // functions to get price and covertion rate from a decentralized network. In this case, chainlink

    function getPrice(AggregatorV3Interface priceFeed ) internal view returns(uint256){

       (, int256 price,,,)  = priceFeed.latestRoundData();
       // ETH in terms of USD
       // 1000.00000000

       //Type casting
       return uint256(price * 1e10); // 1**10 = 10000000000

    }


    // This function converts the msg in Wei to USD
        function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
            uint256 ethPrice = getPrice(priceFeed);
            // 3000_000000000000000000 = ETH / USD PRICE
            // 1_000000000000000000 ETH
            // Make sure to multiply inside parenthesis and then divide. 
            uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
            return ethAmountInUsd;
        }

}