//Get Funds from users
// withdrawal funds
// set a minimum funding value in USD
/**
Sources:
https://docs.chain.link/docs/ethereum-addresses/
https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
https://docs.chain.link/docs/get-the-latest-price/

**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error notOwner();
// If it's assigned at compile time, add constant so gas prices are cheaper. Before 856301, after 836711
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; 

    address[] public funders;
    address public immutable i_owner;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        //  immediately called after contract creation
        // whoever deployed the contract 
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); 
    }

    function fund() public payable { // Makes the contract able to hold funds
        // require(getConversionRate(msg.value) > minimumUsd, "Not enough ether"); // 1e18 is the equivalent to one ether == 1*10*18 = 1000000000
        // hook up the library PriceConverter.sol
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value; 
    }


    function withdraw() public onlyOwner {
        
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex ++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
        // actually withdraw funds (3 ways)
        // call() lowerlevel command
        (bool callSuccess,) = payable(msg.sender).call{ value: address(this).balance }(""); // withdraw everything
        require(callSuccess, "Call failed");

        // // transfer()
        // // msg.sender = address
        // payable(msg.sender) = payable - only payables can recieve ethereum
        // payable(msg.sender.transfer(address(this).balance));

        // // send()
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    }

    modifier onlyOwner {
        // require(msg.sender == owner, "Caller is not owner!");
        if(i_owner != msg.sender){
            revert notOwner();
        }
        _;
    }

    // What happens if someone sends this contract ETH without calling the fund function?? 
    // recieve()
    // fallback() 

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// $ npm install @chainlink/contracts --save
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter {
    
    // Oracles allow us to interact with external assets such as USD to AUD (outside the blockchain)
    // Chainlink helps us with this problem (ie. chainlink datafeeds) 

    function getPrice(AggregatorV3Interface agPriceFeed) internal view returns(uint256) {
        // ABI of contract  
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(agPriceFeed);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 etherAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * etherAmount) / 1e18;
        return ethAmountInUsd; 
    }

    function getVersion() internal view returns(uint256) { 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
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