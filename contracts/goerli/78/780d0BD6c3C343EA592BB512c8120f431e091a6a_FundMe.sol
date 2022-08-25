// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // constant && immutable

    // ADDRESS => 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // CONTRACT => 0x61E3DD57f1c65Ed59d625d253A2373E331FCc3BC

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Only Owner Can Withdraw");
        if(msg.sender != i_owner) {
            revert FundMe__NotOwner(); // SAVE GAS
        }
        _; // _; means DO REST OF CODE
    }

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        // REQUIRE => Revert if Condition is not Fulfilled
        require(msg.value.getConversionRate(s_priceFeed)  > MINIMUM_USD, "Not Enough Fund");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }



    function withdraw() public payable onlyOwner{
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // RESET ARRAY
        s_funders = new address[](0);

        // TRANSFER THROW ERROR IF FAIL + REVERT
        // payable(msg.sender).transfer(address(this).balance);

        // SEND RETURN BOOL + NOT REVERT
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // CALL
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");

    }

    function cheaperWithdraw() public payable onlyOwner{
        address[] memory funders = s_funders;
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // CALL
        (bool callSuccess,) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getFunderByIndex(uint256 index) public view returns (address) {
        return s_funders[index];
    }
    function getAddressToAmountFunded(address funderAddress) public view returns (uint256) {
        return s_addressToAmountFunded[funderAddress];
    }

    // receive && fallback
    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// NPM LIBRARY == REMIX DOWNLOAD PACKAGE AUTO
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        // LEAVE COMMAS!!!
        (,int256 price,,,) = priceFeed.latestRoundData(); // ETH IN DOLLAR WITH 8 DECIMALS
        return uint256(price * 1e10); // WEI FORMAT
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice*ethAmount) / 1e18;
        return ethAmountInUsd;
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