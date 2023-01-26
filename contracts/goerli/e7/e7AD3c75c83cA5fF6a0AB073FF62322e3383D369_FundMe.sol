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

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

// 840005   gas cost with usig constant 
// 816528   gas cost with using immmutable and const
pragma solidity ^0.8.8;

import "./PriceConverter.sol";


contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; //  1 * 10 ** 18
    
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        //  msg.sender of constructor is the person who is deploying the contract
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }

    // public specify anyone can call it...
    // payable make this function to red 
    function fund() public payable{
        // want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract ?

        require(msg.value.getConversionRate(priceFeed) > MINIMUM_USD, "Didn't send enough!"); // 1e18 == 1 * 10 ** 18
        // msg.value  has 18  decimal places
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {

        // require(msg.sender == owner, "Sender is not owner!")

        for(uint256 funderIndex = 0 ; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array 
        funders = new address[](0); // brand new address array with 0 objects in it

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


}


// 0x11f31dd6E0BF077767A276De91f7Ef8B64a7A864

//0xD52AC6B3988650DCB1377c118BacED9F23fC346C   -> has list of transactio performed












// deploying this will cost 859553 gas



// pragma solidity ^0.8.8;

// import "./PriceConverter.sol";


// contract fundMe {

//     using PriceConverter for uint256;

//     uint256 public minimumUsd = 50 * 1e18; //  1 * 10 ** 18
    
//     address[] public funders;
//     mapping(address => uint256) public addressToAmountFunded;

//     address public owner;

//     constructor(){
//         //  msg.sender of constructor is the person who is deploying the contract
//         owner = msg.sender;
//     }

//     // public specify anyone can call it...
//     // payable make this function to red 
//     function fund() public payable{
//         // want to be able to set a minimum fund amount in USD
//         // 1. How do we send ETH to this contract ?

//         require(msg.value.getConversionRate() > minimumUsd, "Didn't send enough!"); // 1e18 == 1 * 10 ** 18
//         // msg.value  has 18  decimal places
//         funders.push(msg.sender);
//         addressToAmountFunded[msg.sender] += msg.value;
//     }

//     function withdraw() public onlyOwner {

//         // require(msg.sender == owner, "Sender is not owner!")

//         for(uint256 funderIndex = 0 ; funderIndex < funders.length; funderIndex++){
//             address funder = funders[funderIndex];
//             addressToAmountFunded[funder] = 0;
//         }
//         // reset the array 
//         funders = new address[](0); // brand new address array with 0 objects in it

//         // actually withdraw the fund
//                 // msg.sender is of address type
//                 // payable(msg.sender) is of payable type i.e here we have done typecasting


//         // transfer  -> if fail will throw error and will revert this transaction
//             // payable(msg.sender).transfer(address(this).balance);


//         // send -> if faill with return boolean and will not revert thte transaction
//             // bool sendSuccess = payable(msg.sender).send(address(this).balance);
//             // require(sendSuccess, "Send failed");

//         // call
//             (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); // this return 2 arguments we need only one so we had left the space for one 
//             require(callSuccess, "call failed");

//     }

//     modifier onlyOwner {
//         require(msg.sender == owner, "Sender is not owner!");
//         _;
//     }

// }

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