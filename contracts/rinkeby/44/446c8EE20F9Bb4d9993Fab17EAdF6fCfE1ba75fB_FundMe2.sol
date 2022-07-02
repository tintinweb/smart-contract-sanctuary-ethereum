// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter2.sol";
error FundMe2__notowner(); // Custom error
/**
@title A contract for Crowd funding
@author Shaan
@notice I am learing blockchain with chobeee
@dev Note to developers
*/
contract FundMe2{
    using PriceConverter2 for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address [] private s_funders; 
    mapping(address => uint256) private s_addressToFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    modifier onlyowner{
        if(msg.sender != i_owner){revert FundMe2__notowner();}
        _;
    }
    constructor(address s_priceFeedAddres){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddres);
    }
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD , "Insufficient Funds");
        s_funders.push(msg.sender);
        s_addressToFunded[msg.sender] += msg.value;
    }
    function withdraw() public onlyowner{
        for(uint8 i = 0 ; i < s_funders.length ; i++){
            address j = s_funders[i];
            s_addressToFunded[j] = 0;
        }
        s_funders = new address[](0);
        // //transfer  error if gas < 2300
        // payable(msg.sender).transfer(address(this).balance);
        // //send  returns boolean false if gas < 2300 else true
        // bool sendSucces = payable(msg.sender).send(address(this).balance);
        // require(sendSucces,"Send Failed");
        // //call   returns 2 variables ist boolean and 2nd data
        (bool callSucces,) = payable(msg.sender).call{value : address(this).balance}("");
        require(callSucces,"Call Failed");
    }
    function cheaperWithdraw() public payable onlyowner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success,"Success");
    }
    uint256 public flag;
    receive() external payable{fund(); flag = 1;}
    //fallback() external payable{fund(); flag = 2;}
    function getAddressToFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        return s_addressToFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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
library PriceConverter2{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }
    function getVersion() internal view returns  (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    function getConversionRate(uint256 ethAmount , AggregatorV3Interface priceFeed) internal view returns ( uint256) {
        uint256 ethPrice= getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice*ethAmount)/1000000000000000000;
        return ethAmountInUsd;
    }
}