// get funds from users
// withdraw funds
// set a minimum funding value is USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256; //associate the PriceConverter library with uint256

    //variables assigned at compile time that don't change can be constants and they will cost less gas,
    //constant variables don't take up a storage spot
    uint256 public constant MINIMUM_USD = 1 * 1e18; //need to add the decimals

    address[] public funders; //array of addresses who have funded the contract
    mapping(address => uint256) public addressToAmountFunded; //hashmap of ammount funded by address

    //variables that are set one time but outside of the line that they're declare should be set as immutable
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed; //AggregatorV3Interface type

    // there's no msg.sender in the global scope, msg.sender is only in a function (constructor is a function)
    // constructor gets called when a contract gets deployed
    constructor(address priceFeedAddress) {
        //pass it the ETH/USD price feed address depending on what chain were on
        i_owner = msg.sender; //msg.sender of the constructor function is whomever is delpoying the contract
        priceFeed = AggregatorV3Interface(priceFeedAddress); // pass the price feed address to create a contract
    }

    //both wallets and contracts can hold crypto like ethereum
    //payable makes the function payable
    function fund() public payable {
        //money math is done in terms of wei so 1 ETH needs to be set as 1e18 value
        //is value > 1 eth ? if not display error message
        //require(msg.value >= 1e18, "Didn't send enough!"); //1e18 == 1 * 10 ** 18 == 1000000000000000000
        //if require isn't met function is reverted and sends gas back
        //operations before a failed require get reverted but gas does not get sent back
        //operations after a failed require get reverted and their gas gets sent back

        //second example
        //value is in terms of ethereum so if we want to use USD we need to change
        //require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough!");
        //18 decimals

        //third (library way)
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );

        // the current functionality doesn't check if the address is already in the array
        funders.push(msg.sender); //msg.sender is the address which calls the fund function,
        //msg.value is the value provided by that address
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        //verify that the withdraw is executed by the owner only
        //require(msg.sender == owner, "Sender is not owner!"); //it's better to use a modifier instead of require for this

        // reset funded mapping - default is zero for any address?
        for (uint256 i = 0; i < funders.length; ++i) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // reset funders array
        funders = new address[](0); //"(0)" means initialize new array with zero elements

        // 3 ways of withdrawing - case by cases
        // 1- TRANSFER - returns error on fail and reverts
        // msg.sender = address type
        // payable(msg.sender) = payable address type
        //payable(msg.sender).transfer(address(this).balance); //"this" is the current contract
        // 2- SEND - returns boolean, but doesn't revert automatically if send fails
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed!"); //require makes send revert on a fail
        // 3- CALL - returns 2 values: bool (for call success) and a bytes object - RECOMMENDED
        // bytes onjects are array so data returns need to be memory
        // (bool callSuccess, bytes memory dataReturned) //bytes isn't needed in this case because no function is being called
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); //"("")" is where we put function information we want to call on another contract,
        // but we don't here so we leave it blank
        //returns get passed to the bytes object
        require(callSuccess, "Call failed!");
    }

    //modifiers added to a function modify the way function contents can be executed
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!"); //require first
        // instead of require use an if with a revert, revert does the same thing as arequire without the conditional
        // is more gas efficient than require since the error message array in the require doesn't need to be stored
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // underscore represents executing the function code in the function where the modifier is used,
        // if the underscore was above the require then the function code would be executed before the require
    }

    //what happens if someone sends this contract ETH without calling the fund function
    // receive and fallback are special functions in the same sense of the constructor function
    // 1- receive
    receive() external payable {
        fund();
    }

    // 2- fallback
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//functions in a library need to be internal
//this library will be different functions that can be called with uint256
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // remaining code can be moved to getConversionRate

        // ABI
        // Address  	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e https://docs.chain.link/docs/data-feeds/price-feeds/addresses/#Goerli%20Testnet
        // aggregator is an interface object which gets compiled down to the ABI, if you match an ABI to an address you get a contract
        // replaced hard code with parameter
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e //address of the price feed
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData(); //int256 because some price feeds can be negative
        //(uint80 roundID, int256 price, uint startedAt, uint timeStamp, uint80 answeredInRound)
        //we only need price
        //eth in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); //1**10 == 10000000000 //match up with eth(gwei) decimals, then type cast into uint256 (msg.sender's type)
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    //with library functions, the first parameter that gets passed to the function is the object it's called on,
    //if the function has a second argument, it needs to be passed in the parenthesis of the function call
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD price
        //    1_000000000000000000 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; //without the division there would be an addition 36 zeros at the end
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