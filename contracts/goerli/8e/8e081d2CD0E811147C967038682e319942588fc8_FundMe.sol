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
 

import "./PriceConverter.sol";



contract FundMe{
    using PriceConverter for uint256;

    uint256 public minUSD= 50 * 1e18;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public owner;
    AggregatorV3Interface public priceFeed;
    constructor(address x){
        owner= msg.sender;
        priceFeed = AggregatorV3Interface(x);
    }

     modifier onlyOwner{
        require(owner == msg.sender, "don't try to scam me buddy");
        _;
     }
    

    function fund() public payable{


        require(msg.value.getConversionRate(priceFeed)>=minUSD, "Plz send enough");// here the msg.value is tghe first input for the function getConversionrate
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]= msg.value;
    }

    function withdraw() public{
        for(uint256 fi =0; fi <funders.length; fi++){
            address funder = funders[fi];
            addressToAmountFunded[funder] =0;
        }
        funders = new address[](0);
    // it returns error if crosses the gas cost of 2300 
    //     payable(msg.sender).transfer(address(this).balance);// msg.sender = address

    //     //send() it throws bool over 2300 gas
    //    bool success =  payable(msg.sender).send(address(this).balance);
    //    require(success,"Error in sending the token"); // it will revert back

        // call returns the byte code and bool and often used more than others
        (bool success, ) = payable(msg.sender).call{value: address(this).balance }("");
        require(success, "call failed");

    }

    receive() external payable {
        fund();
    } 
     fallback() external payable{
         fund();
     }

   
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


// interface AggregatorV3Interface {
//   function decimals() external view returns (uint8);

//   function description() external view returns (string memory);

//   function version() external view returns (uint256);

//   // getRoundData and latestRoundData should both raise "No data present"
//   // if they do not have data to report, instead of returning unset values
//   // which could be misinterpreted as actual reported values.
//   function getRoundData(uint80 _roundId)
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );
// }


// we can't declare any state varibles and aslo cant send ether in the library
library PriceConverter{


     function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        // ABI
        // ADDRESS - 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e // ETH-USD

      
       (,int256 price,,,)= priceFeed.latestRoundData(); 
        // 
        //1000.00000000
        return uint256(price* 1e10);

    }


// not really needed 
    //  function getVersion() internal view returns (uint256){
    //     // ETH/USD price feed address of Goerli Network.
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    //     return priceFeed.version();
    // }

    function getConversionRate(
      uint256 ethAmt, 
      AggregatorV3Interface priceFeed
      
      ) internal view returns(uint256){
            uint256 ethPrice = getPrice(priceFeed);

            // convert in usd
            uint256 ethUSD = (ethPrice*ethAmt) / 1e18;
            return ethUSD;
    }

}