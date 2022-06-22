//SPDX-License-Identifier:MIT

//Get funds from users
//Withdraw funds
//Set a minimum funding value in USD
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface public priceFeed;
    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //Limit tinkering / triaging to 20 minutes.
    // Take at least 15 minutes yourself -> or be 100% sure
    //you exhausted all options
    //1. Tinker and try to pinpoint exactly what's going on
    //2.goole the exact error
    //2.5 go to course github repo
    //3. ask question on stackoverflow stack exchange etherum

    function fund() public payable {
        //want to be able to minimum funds limit
        //1. how to send ETH to this contract
        // require(msg.value > 1e18, "Didn't Send Enough"); //1e18 = 1*10**18 == 1,000,000,000,000,000,000
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't Send Enough"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner,"Sender is not owner!");
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the array
        funders = new address[](0);
        //actually withdraw the funds
        //transfer if transfer is failed due to increase in gas fees it return error
        //    payable(msg.sender).transfer(address(this).balance);
        //     //send if transfer is faild it return bool value
        //    bool sendScuss = payable(msg.sender).send(address(this).balance);
        //    require(sendScuss,"Send Failed");
        //     //call

        //Recommended to pay through call function
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == owner,"Sender is not owner!"); //check the rules
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _; //doing rest of the code
    }

    //what happend if someone send  this contract without call fundme function

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//1. Enums
//2. Events
//3. Try / Catch
//4. Funciton Selector
//5. abi.encode / decode
//6. Hashing
//7. Yul /  Assembly

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //Address of ETH/USD Rinkeybe 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //Address of ETH/USD Kovan 0x9326BFA02ADD2366b30bacB125260Af641031331
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        //ETH in terms of USD
        return uint256(price * 1e10);
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAomountinUSD = (ethPrice * ethAmount) / 1e18;
        return ethAomountinUSD;
    }
}
//0x393bF0F66B9805a75c03DdA3b150FF46856699f6

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