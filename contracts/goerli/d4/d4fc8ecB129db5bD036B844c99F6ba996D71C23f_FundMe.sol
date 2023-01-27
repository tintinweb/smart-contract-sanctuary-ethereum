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

// s_   is used to denote stotrage variable

pragma solidity ^0.8.8;

import "./PriceConverter.sol";


contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; //  1 * 10 ** 18
    
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeedAddress){
        //  msg.sender of constructor is the person who is deploying the contract
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);

    }

    // public specify anyone can call it...
    // payable make this function to red 
    function fund() public payable{
        // want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract ?

        require(msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD, "Didn't send enough!"); // 1e18 == 1 * 10 ** 18
        // msg.value  has 18  decimal places
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {

        // require(msg.sender == owner, "Sender is not owner!")

        for(uint256 funderIndex = 0 ; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array 
        s_funders = new address[](0); // brand new address array with 0 objects in it

        // actually withdraw the fund
                // msg.sender is of address type
                // payable(msg.sender) is of payable type i.e here we have done typecasting


        // transfer  -> if fail will throw error and will revert this transaction
            // payable(msg.sender).transfer(address(this).balance);


        // send -> if faill with return boolean and will not revert thte transaction
            // bool sendSuccess = payable(msg.sender).send(address(this).balance);
            // require(sendSuccess, "Send failed");

        // call
            (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); // this return 2 arguments we need only one so we had left the space for one 
            require(callSuccess, "call failed");

        // here in this function we uses s_funders oftenly in loop which will cost more gas 
        // to avoid this we will create cheaper withdraw function  
    
    }

    // Gas efficient version of withdraw function

    function cheaperWithdraw() public payable onlyOwner {
        // copying the s_funders array in memory local variables so that we don't have to call s_funder stotrage variable again and again which helps to make more gas efficient. (memory is very cheaper locall storage)

        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry !

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    modifier onlyOwner {
        require(msg.sender == i_owner, "Sender is not owner!");
        _;
    }

    // what happens if someone sends this contract ETH without calling  the fund function 
        // for this we have 2 function in solidiy i). receive()  ii). fallback() 

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface){
        return s_priceFeed;
    }

    // Above are the some getter function there benifits are that 
        // i) help us to get rid of the variable starting with s_ convention for the user sake
        // ii) declared above variable private from public which help us to save some gas (and we are accessing that variable using gettrer function.)

}


// 0x11f31dd6E0BF077767A276De91f7Ef8B64a7A864

//0xD52AC6B3988650DCB1377c118BacED9F23fC346C   -> has list of transactio performed

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price of ETH IN TERMS OF USD
        // 3000.0000 0000 (8 decimal places)

        return uint256(price * 1e10); // will convert to 18 decimal places  price is in int256 and we are converting it into uint256 using type casting
    }

    function getConversionRate(
        uint256 ethAmount, AggregatorV3Interface PriceFeed 
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(PriceFeed);
        // 3000_000000000000000000
        // 1_000000000000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // both are of 18 decimal places to get rid of 1 18 places we had dvidede by 18
        return ethAmountInUsd;
    }
}