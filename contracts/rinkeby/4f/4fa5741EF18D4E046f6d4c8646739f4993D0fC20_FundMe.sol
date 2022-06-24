// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.8;

import "./PriceConverter.sol";

/*
In this contract we are going to accomplish three things
1. Get funds from users
2. Withdraw funds
3. Set a minimum funding value in USD
*/
error NotOwner();

contract FundMe{
    using PriceConverter for uint256; // Allows us to attach/extend uint data type with the functions defined in PriceConversion library as if the data is an object with junctions.

    // Minimum fund abound required
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1*10**18

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // 'payable' keyword allows a function to receive and hold funds.
    function fund() public payable {
        // How do I send ETH to this contract?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!"); //1 ETH = 1e18 = 1*10^18 = 1000000000000000000 Wei
        // The 'require' keyword is a checker and essentialy means, 
        // if msg.value is not greater than msg.value (or its deriative), display the given message 
        // and roleback any changes.
        // Note: Any unused gas when the require failed is returned to the sender.
        // The unit of msg.value depends of the unit selected for the transaction value.
        // Note: msg.value is the value of the blockchen native token value. ETH in our case.

        // We want to keep track of all addresses from which we have been sent fund.
        funders.push(msg.sender); // msg.sender is the address of whoever calls the fund function.
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        
        for(uint idx = 0; idx < funders.length; idx++){
            address funder = funders[idx];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders =  new address[](0);

        // actually withdraw the fund
        // // a. trasfer
        // payable(msg.sender).transfer(address(this).balance);
        // // b. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // c. call: This is the recommended way for sending and receiving fund. Not gas limit.
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        //require(msg.sender == i_owner, "You are not the owner!. \nOnly the owner can withdraw fund.");
        if(msg.sender != i_owner) {revert NotOwner();} // This is more gas efficient than using 'require' keyword.
        _; // this means continue with the rest of the codes
    }

    // What happens if someone send this contract ETH without calling the fund function?
    // 'receive' intercepts payments sent to the contract address without using a function, 'fund()' in this case.
    receive() external payable{
        fund();
    }

    // 'fallback' is triggered whenever a call is made to the contact to a non existing feature.
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface _priceFeed) internal view returns(uint256) {
        (, int256 price,,,) = _priceFeed.latestRoundData();
        //ETH in terms of USD, to 18 decimal places (e.g. 3000000000000000000000 = 3000.000000000000000000 = 3000e18)
        // 300000000000 == 3000.00000000
        return uint256(price * 1e10); // (price ** 10) == (price * 10000000000); 
    }

    function getVersion() internal view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface _priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(_priceFeed); // Get the price of ETH, in USD, with the last 18 numbers representing the decimal numbers.
        uint256 ethAmountInUSD = (ethPrice * _ethAmount) / 1e18;
        return ethAmountInUSD;
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