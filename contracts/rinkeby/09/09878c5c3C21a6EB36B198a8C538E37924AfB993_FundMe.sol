//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

//keyword - constant and immutable those variables cannot be changed and gas fees will be smaller

//error NotOwner(); //Custom errors, those makes gas fees smaller, cause instead of keeping an error string in the memory
// we simply store a variable of error

contract FundMe {
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    using PriceConverter for uint256;

    AggregatorV3Interface private sPriceFeed;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable iOwner;

    constructor(address priceFeed) {
        //called when we deploy this contract
        iOwner = msg.sender;
        sPriceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        //Smart contract can hold funds same as wallets
        require(
            msg.value.getConversionRate(sPriceFeed) >= MINIMUM_USD,
            "Did not send enough!"
        ); //1 parametr = X => vykonani druheho parametru, a zaroven se prerusi transakce
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 founderIndex = 0;
            founderIndex < funders.length;
            founderIndex++
        ) {
            //nulovani mapy
            address addressFounder = funders[founderIndex];
            addressToAmountFunded[addressFounder] = 0;
        }

        funders = new address[](0); //reseting array
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");

        /*//transfer
        payable(msg.sender).transfer(address(this).balance);

        //send
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Too much gas fee! Send failed!");*/
    }

    modifier onlyOwner() {
        require(msg.sender == iOwner, "You cant't withdraw !");
        /*if(msg.sender != i_owner){
            revert NotOwner();
        }*/
        _; //the underscore means when will the rest of the code happen
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
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
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
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