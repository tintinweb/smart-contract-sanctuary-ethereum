// Get funds from user
// Withdraw
// Minimum funding value in usd.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //solidity version
import "./PriceConverter.sol";
//custom errors
error FundMe_NotOwner();
contract FundMe{
    //using libraryr and this is library syntax
    using PriceConverter for uint256;
    AggregatorV3Interface public priceFeed;
    //min usd raise to 18 to match solidity standard cause no points
    uint256 constant usd = 50*1e18;
    address public immutable owner ;
    // receive() external payable{

    // }
    // fallback() external payable{
        
    // }
    constructor(address priceFeedAddress)
    {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    function fund() public payable{
        // require(msg.value.getConversionRate(priceFeed) >= usd, "Didn;t sent enough eth");

    }

    //concept of modifier and owner
    modifier onlyOwner() {
        //gas efficient way to handle than require
        if(msg.sender != owner){
            // custom errors like this are more gas efficient than the require thingy somehow 
            revert FundMe_NotOwner();
        }
        // require(msg.sender == owner, "Only owner can call this function! NIKAL L");
        _;
    }
    function withdraw() public onlyOwner {
      
        //call , best one and recommended one allows calling a function on contract without the ABI
        //In empty bracket a function to be called can be called and return will go to data on left
        (bool successCall, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(successCall, "Transaction failed");
    }

    



    // function withdraw()
    // {

    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //solidity version
// import "./tests/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface priceFeed  = AggregatorV3Interface(priceFeedAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountPrice = (ethPrice * ethAmount) / 1e18;

        return ethAmountPrice;
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