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

//Get Funds from Users
//Withdraw Funds
//Set Minimum Funding Values in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConvertor.sol";

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant minimumUSD = 50 * 1e18;

    address[] public funders; 
    mapping(address => uint256) public addressToAmountFunder;

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //function to send money
    function fund() public payable{
        require(msg.value.getConversionRate(priceFeed)>= minimumUSD, "Didn't Send Enough");
        funders.push(msg.sender);
        addressToAmountFunder[msg.sender] = msg.value;
    }

    

    function withdraw() public onlyOwner{
        

        for(uint256 funderIndex = 0; funderIndex <funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunder[funder] = 0;

        }

        funders = new address[] (0);

        //msg.sender -> address
        //payable(msg.sender) -> payable address
        // payable(msg.sender).transfer(address(this).balance);

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");    
        require(callSuccess, "Call Failed");

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not Owner");
        _; // do rest of the code
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConvertor{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        //ABI
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (,int256 price,,,) = priceFeed.latestRoundData(); // Price of ETH in term of USD;
        return uint256(price);
    }

    function getVersion() internal view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return(priceFeed.version());
    }
    
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmounInUSD = (ethPrice*ethAmount) / 1e8;
        return ethAmounInUSD;
    }
}