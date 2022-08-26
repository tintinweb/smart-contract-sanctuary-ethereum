//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract fundMe {
    using PriceConverter for uint256;

    uint256 public usdMin = 11 * 1e18;
   
    address public immutable i_owner;
    address[] public funders;
    mapping(address => uint256) funderToEA;
 
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    
//fund function
    function fund() public payable{
    //   what `1 eth is equal to in gwei
    //    1e18 == 1 * 10 ** 18 == 1000000000000000000
     

        require(msg.value.getConversionRate(priceFeed) >= usdMin, "not so fast");
        funders.push(msg.sender);
        funderToEA[msg.sender] = msg.value;
    }

//withdraw function
    function withdraw() public onlyOwner {
        
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            funderToEA[funder] = 0;
        }

        funders = new address[](0);

        //transer
        // payable(msg.sender).transfer(address(this).balance)
        //send
        bool didSucceed = payable(msg.sender).send(address(this).balance);
        require(didSucceed, "oops, that didnt work");
        //call
        (bool callTransaction, ) = payable(msg.sender).call{value:address(this).balance}("");
        require(callTransaction, "oops again");
    }


    modifier onlyOwner () {
        // require(msg.sender == owner, "you are not authorized");
        if(msg.sender != i_owner){
            revert NotOwner();
        }
        _;
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//cannot create any State variables and cannot send or store ETH.
library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        //we need
        //address of contract 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //ABI
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        (, int256 price,,,) = priceFeed.latestRoundData();
        // ^will return
        //price of ETH in USD
        //will return as a number with no decimal 
        return uint256(price * 1e10);

    }



    function getConversionRate (uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256){
        //eth = .5
        //usd minimum = $11
        //is .5 eth === $11
        uint256 ethPrice = getPrice(priceFeed);
       
        uint256 currentPrice = ( ethPrice * ethAmount) / 1e18;
        return currentPrice;
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