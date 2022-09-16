// Get funds from user
// Withdraw funds
// Set a minimum fundings value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";

//Error
error FundMe__NotOwner();

contract FundMe {
    //State variables

    //minimum USD in 18Digit
    uint256 public constant MINIMUM_USD = 10 * 1000000000000000000;
    //this array stores addresses of funders
    address[] public funders;
    //Dictionary which shows Amount's been funded based on given address
    mapping(address => uint256) public addressToAmountFunded;
    //owner of this contract is to be assign
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //to send fund
    function fund() public payable {
        //Checks given value either equal or above minimum else revert transaction
        require(
            PriceConverter.getConversionRate(msg.value, priceFeed) >=
                MINIMUM_USD,
            "Did not send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
            //delete funders[funderIndex];
        }
        //reset array
        funders = new address[](0);

        //transfer
        /*payable(msg.sender).transfer(address(this).balance);
    //send
    bool success = payable(msg.sender).send(address(this).balance);
    require(success,"Send fail");
    */
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    //function modifier executes before and/or after funtions intructions
    modifier onlyOwner() {
        //security check ,only owner of this contract can withdraw
        //equire(msg.sender == i_owner,"Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    //special function
    //someone send eth without calling fund()
    receive() external payable {
        fund();
    }

    //special function
    //someone send eth with wrong data calling fund()
    fallback() external payable {
        fund();
    }
}

/* function getPrice()public view returns(uint256)
    {
        //ABI: 
        //Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 //address of Chainlink eth-usd keeper
        AggregatorV3Interface priceFeed = AggregatorV3Interface();
        (,int price,,,) = priceFeed.latestRoundData();


        return uint256(price * 1e10);// 1**10000000000
    }


    function getConversionrate(uint256 ethAmount)public view returns(uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD =(ethPrice * ethAmount) / 1e18;

        return ethAmountInUSD;
    }*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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