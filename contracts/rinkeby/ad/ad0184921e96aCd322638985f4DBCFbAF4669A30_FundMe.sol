// SPDX-License-Identifier: MIT

// Get funds from users
// Witdraw funds
// Set a minimum funding value in USD

pragma solidity ^0.8.7;

error NotOwner();

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
	// 940419 
    	// 962892
import "./PriceConverter.sol";

contract FundMe {
    

    using PriceConverter for uint256;

    // uint256 public minimumUsd = 50 * 1e18; // 1 * 10 ** 18

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] public funders;
    mapping (address => uint256) public addressToAmount;

    // address public owner;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    
    function fund() public payable{
        // Set minimum of fund amount
        
        require (msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough"); // 1e18 == 1 * 10 ** 18 wei ==1 eth
        funders.push(msg.sender); //msg.sender == address
        addressToAmount[msg.sender] = msg.value;
    }

    function witdraw() public onlyOwnerTest{
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmount[funder] = 0;
        }
        // reset array
        funders = new address[](0);
        
        // accually witdraw the funds

        // transfer
        // send
        // call

        // msg.sender = address
        
        // payable
        // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool senSuccess = payable(msg.sender).send(address(this).balance);
        // require(senSuccess,"Send failed");
        // // call
        // // (bool callSuccess, bytes memory dataReturned)

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwnerTest {
        // require(msg.sender == i_owner, "Sender is not owner!");

        // Save more GAS but must declare error first (at the top)
        if(msg.sender != i_owner) { revert NotOwner();}
        _;
        // _; mean code in function that we want to work to be first ot last condition require
    }

    // What happens if someone sends this contract ETH without calling the fund function

    // receive()
    // fallback()

    // Go to fund() function
    receive() external payable {
        fund();
    }

    fallback() external payable{
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // rinkeby
        // ABI
        // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10); //1**10
    }

    // function getVersion() internal view returns (uint256) {
    //     return AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).version();
    // }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        // 3000.000000000000000000 ETH/USD
        // 1.000000000000000000 ETH
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18; 
        return ethAmountInUsd;
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