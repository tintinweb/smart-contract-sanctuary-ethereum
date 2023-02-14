// SPDX-License-Identifier: MIT

//Get FUnds froms users
//Widthreaw Funds
//set aminimum funding value in USD

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//Error Code

error FundeMe__NotOwner(); 


contract FundMe {
    
    // Type Declaration
    using PriceConverter for uint256;
    
    // State Variable
    uint256 minUSD=50 * 1e18;
    address[] public founders;
    mapping (address => uint256) public addressToAmount;
    address owner;
    AggregatorV3Interface public priceFeed;
    
    // Modifiers
     modifier onlyOwner{
       // require(msg.sender == owner , "You are not the owener of this contract");
        if(msg.sender == owner) revert FundeMe__NotOwner();
        _;
    }
    // Functions
    /// constructor
    /// recieve
    /// fallback
    /// external
    /// public
    /// internal
    /// private
    /// view / pure


    constructor(address priceFeedAddress){
        owner=msg.sender;
        priceFeed=AggregatorV3Interface(priceFeedAddress);
    }
    receive() external payable{
        fund();
    }
    fallback() external payable{
        fund();
    }
    
    
    function fund() public payable  {
       require(msg.value.getConversionRate(priceFeed)>=minUSD,"you need to spend more ETH");
       addressToAmount[msg.sender]+=msg.value;
       founders.push(msg.sender);
    }

    
   function withdraw() public onlyOwner{  
       for(uint256 i=0 ; i>founders.length;i++){
           addressToAmount[founders[i]] = 0;
       }
       //reset the array
       founders= new address[](0);
       //withdraw the funds


        //msg.sender=address
        //payable(msg.sender)=payable address

        //transfer
        //payable(msg.sender).transfer(address(this).balance) ;
        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance) ;
        //(sendSuccess,"Send Faild");
        //call
       (bool callSuccess,)= payable(msg.sender).call{value:address(this).balance}("") ;
        require(callSuccess , "Call failed");
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

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) public view returns (uint256){
        // ETH/USD price feed address of Goerli Network.
      //  AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 price,,,)=priceFeed.latestRoundData();
        return uint256(price * 1e10);
     } 

     function getVersion() public view returns (uint256){
        // ETH/USD price feed address of Goerli Network.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
     } 

     function getConversionRate(uint256 _ethAmount,AggregatorV3Interface priceFeed)internal  view returns(uint256){
         uint256 ethPrice=getPrice(priceFeed);
         uint256 ethAmountInUSD=(ethPrice * _ethAmount) /1e18;
         return ethAmountInUSD;
     }
}