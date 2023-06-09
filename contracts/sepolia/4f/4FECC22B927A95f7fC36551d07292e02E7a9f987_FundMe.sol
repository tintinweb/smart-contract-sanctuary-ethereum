//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
// Fund me function
// Withdraw function
// minimum fund capacity
import "./PriceConverter.sol";
error NotOwner();
error CallFailed();
error NotMinimum();
contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD=50*1e18;
    mapping (address => uint256) public addressToAmountFunded;
    address[] public funders;
    function fund () public payable {
        if(msg.value.getConversionRate(pricefeed)<MINIMUM_USD){revert NotMinimum();}
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]=msg.value;
    }
    address public immutable owner;
    AggregatorV3Interface public pricefeed;
    constructor(address priceFeedAddress){
        owner=msg.sender;
        pricefeed = AggregatorV3Interface(priceFeedAddress);
    }

    function withdraw() public onlyowner {
        for(uint256 funderindex=0;funderindex<funders.length;funderindex++){
            address funder=funders[funderindex];
            addressToAmountFunded[funder]=0;
        }
        funders=new address[](0);
        // // transfer
        // //msg.sender = address
        // // payable = payable address
        // payable(msg.sender).transfer(address(this).balance);
        // //send
        // bool sendsuccess=payable(msg.sender).send(address(this).balance);
        // require(sendsuccess,"not sended");
        //call 
        (bool callsuccess,)=payable(msg.sender).call{value: address(this).balance}("");
        if(!callsuccess){revert CallFailed();}

    }   
    modifier onlyowner {
        // require( msg.sender==owner,"sender is not owner ");
        if(msg.sender!=owner){revert NotOwner();}
        _;
    }
    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
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

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
        function getPrice(AggregatorV3Interface priceFeedAddress) internal view returns (uint256){
        AggregatorV3Interface priceFeed = priceFeedAddress;
        (,int256 price,,,)=priceFeed.latestRoundData();
        return uint256(price*1e10);
    }

    function getConversionRate(uint256 _ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 value=(_ethAmount*getPrice(priceFeed))/1e18;
        return value;
    }
}