// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";

error notOwner();

contract FundMe{
    using PriceConverter for uint256;
    address public immutable i_owner; // save gas using variable you'll define only once
    uint public constant MINIMUM_USD = 50 * 1e18; // multiply by 1e18 to have the same units as eth/ constant with same idea as above
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;


    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //eth-converter.com
    // use above to convert eth amount to Wei to input in value section

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Don't be cheap");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        for(uint funderIndex =0; funderIndex<funders.length ; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // 3 ways to withdraw
        // wrap address in payable keyword

        // transfer
        //payable(msg.sender).transfer(address(this).balance);

        // send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send type Withdrawal failed");

        // call - the recommended way to withdraw
        // bytes is an array so declare with memory
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "Call type Withdrawal failed");
    }

    modifier onlyOwner(){
        require(msg.sender == i_owner, "You are NOT the owner of this contract!");
        if(msg.sender != i_owner){revert notOwner();}
        _; // do the rest of the code - make sure it's after the require function
    }
    
    receive() external payable {
        fund();
    }

    fallback() external payable{
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint){
        // Goerli ETH/USD address
        // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData(); // returns 8 decimals
        return uint(price * 1e10); // convert to Wei

    }

    function getDecimals(AggregatorV3Interface priceFeed) internal view returns (uint8){
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.decimals(); //gives us 8 decimals
    }

    function getConversionRate(uint256 _ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        // Only accepts whole numbers
        // https://eth-converter.com/
        // will have to calculate to wei from here
 
        uint256 ethPrice = getPrice(priceFeed); //ETH in USD * 10^18
        uint256 ethAmountinUSD = (ethPrice*_ethAmount) /1e18; // convert back from Wei to readable USD
        return ethAmountinUSD;
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