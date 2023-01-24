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

//SPDX-License-Identifier: MTI
pragma solidity ^0.8.0;
import "./PriceConverter.sol";

error FundMe_NotOwnerError();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    mapping(address => uint256) private s_addressToAmountFunded;

    modifier isOwner {
        if(msg.sender != i_owner) {
            revert FundMe_NotOwnerError();
        }
        _; 
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;    
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Did not send enough (1ETH)"); 
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;  
    }

    function withdraw() public payable isOwner {

        for(uint256 i = 0; i < s_funders.length; i++){
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool success, ) 
            = payable(msg.sender).call{value: address(this).balance}("");

        require(success, "Call failed");
    }

    function cheperWithdraw() public isOwner {
        address[] memory funders = s_funders;

        for(uint256 i = 0; i < funders.length; i++){
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool success, ) 
            = payable(msg.sender).call{value: address(this).balance}("");

        require(success, "Call failed");
    }

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address){
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MTI
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        (,int256 price,,,) = priceFeed.latestRoundData();

        return uint256(price * 1e10); 
    }
    
    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;

        return ethAmountInUsd;
    }
}