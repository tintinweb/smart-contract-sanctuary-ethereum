// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract fundMe {

    using PriceConverter for uint256;
    mapping (address => uint256) public _funders_amount;
    address[] public _funders;
    uint256 public _min_deposit = 10;
    AggregatorV3Interface private _priceFeed;
    address public owner;

    constructor(address priceFeed) {
        _priceFeed = AggregatorV3Interface(priceFeed);
        owner = msg.sender;
    }

    function fund()  public payable {
        require(msg.value.getConversionRate(_priceFeed) >= _min_deposit * 10 ** 18,
        "minimum amount to deposit is $10");
        _funders_amount[msg.sender] = msg.value;
        _funders.push(msg.sender);
    }

    function getUSDToETH(uint256 dollars) public view returns(uint256){
        (,int256 asnwer,,,) = _priceFeed.latestRoundData(); //has 8 decimals
        uint256 price = uint256(asnwer * 10 ** 10);
        dollars = dollars * 10 ** 18;
        return (dollars * 10 ** 18) / price;
    }

    // payable(msg.sender).transfer(deposited );
    // bool sent = payable(msg.sender).send(deposited);
    // require(sent, "sent operation failed");
    function withdraw(uint256 usd) public payable returns(bool){
        uint256 deposited = _funders_amount[msg.sender];
        require(deposited > 0, "You didnt deposit anything to this contract");
        uint256 to_withdraw = getUSDToETH(usd);
        require(to_withdraw <= deposited, "you dont have this amount in your account");
        _funders_amount[msg.sender] = deposited - to_withdraw;
        (bool sentSuccess,) = payable(msg.sender).call{value : to_withdraw }("");
        require(sentSuccess, "sent operation failed");
        return sentSuccess;
    }

    function funderToETH(address funder) public view returns(uint256) {
        return _funders_amount[funder];
    }

    function getFunder(uint256 index) public view returns(address) {
        return _funders[index];
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getVersion() public view returns(uint256){
        return _priceFeed.version();
    }

    function getPriceFeed() public view returns(AggregatorV3Interface){
        return _priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) public view returns(uint256){
        (,int256 asnwer,,,) = priceFeed.latestRoundData(); //has 8 decimals
        return uint256(asnwer * 10 ** 10);
    }

    function getConversionRate(uint256 amount, AggregatorV3Interface priceFeed)
    internal view returns(uint256){
        uint256 ethUSDPrice = getPrice(priceFeed);
        uint256 ethInUSD = (amount * ethUSDPrice) / 10 ** 18;
        return ethInUSD;
    }

    function pureExample(uint256 value) public pure returns(uint256){
        uint256 result = value * 2;
        return result;
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