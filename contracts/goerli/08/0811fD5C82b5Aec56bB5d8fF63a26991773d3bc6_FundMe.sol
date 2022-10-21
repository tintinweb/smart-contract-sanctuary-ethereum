// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();


contract FundMe{
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;
    address[] public funders;
    mapping (address => uint256) public adress2AmountOfFunders;
    
    address public immutable i_owner;
    
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        adress2AmountOfFunders[msg.sender] += msg.value;
    }

   

    function Withdraw() public onlyOwner {
        // Starting INdex, ending Index, step amount
        for (uint256 fundersIndex=0; fundersIndex < funders.length; fundersIndex ++){
            address funder = funders[fundersIndex];
            adress2AmountOfFunders[funder] = 0;
        }
        // Resest the Array
        funders = new address[](0);
        // Withdraw the funds
        
        //Transfer  returns error
            //  msg.sender = address
            //  payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);

        //send returns Bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        //call 
        (bool callSuccess,) = payable (msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
        revert();
    }
   
    
    modifier onlyOwner{
        // require(msg.sender == i_owner, "Sender is not the Owner");
        if(msg.sender != i_owner){ revert NotOwner();}
        _;
    }
    // What haooens if someone sends this ETH withhout fund() ?

    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    
     function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // ABI : 
        // ADDRESS : 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    (,int256 answer,,,) = priceFeed.latestRoundData();
    // ETH in USD
    return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

}

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