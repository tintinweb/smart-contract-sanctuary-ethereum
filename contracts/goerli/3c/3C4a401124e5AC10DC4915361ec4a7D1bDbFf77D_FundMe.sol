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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error notOwner();

contract FundMe{

    uint256 fundsInContract=0;
    uint256 public constant MIN_USD=5 *1e18;

    address[] public funders;
    mapping(address=>uint256) public addressToAmtFunded;

    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner=msg.sender;
        priceFeed=AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        uint256 valueInUSD = getConversionRate(msg.value,priceFeed);
        require(valueInUSD>=MIN_USD,"Not Enough funds sent");//1e18wei==1e9gwei==1ETH
        funders.push(msg.sender);
        addressToAmtFunded[msg.sender]=valueInUSD;
        fundsInContract+=valueInUSD;
    }

    function getPrice(AggregatorV3Interface PriceFeed) public view returns(uint256){
        (,int256 price,,,)=PriceFeed.latestRoundData();
        //the msg.value returns ether in wei units(1ETH==1e18wei)
        // thus we must also return in ans*1e18
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface PriceFeed) public view returns(uint256){
        uint256 ethPrice = getPrice(PriceFeed);
        uint256 ethAmountInUSD = (ethAmount * ethPrice)/1e18;
        return ethAmountInUSD;

    }

    function withdraw() public onlyOwner{
        for(uint256 ind=0;ind<funders.length;ind++){
            address funder = funders[ind];
            addressToAmtFunded[funder]=0;
        }
        // RESETING THE ARRAY
        funders=new address[](0);
        //new address[](x ===> this is the number of elements that already need to be present in the array)
      
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,"Send Failed");
    }

    modifier onlyOwner{
        if(msg.sender!=i_owner)revert notOwner();
        // require(i_owner==msg.sender,"Sender is not i_Owner");
        _;
    }

    receive() external  payable{
        fund();
    }

    fallback() external  payable{
        fund();
    }
}