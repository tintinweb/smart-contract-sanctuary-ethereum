// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;
import "./PriceConverter.sol";
error NotOwner();

contract FundMe {
    using PriceConverter for uint;

    //if a variable is initilize once and never changes you can use constant to save some gas
    uint256 public constant minimumUsd = 50 * 1e18;
    address[] public senders;
    mapping(address => uint) public sentAmount;
    AggregatorV3Interface public priceFeed;
    address public immutable owner;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //msg.value is the amount we are sending to the contract
        //you have to specify the first parameter of the function infront as an object and use dot convextion and if there was a sencond parameter you have to provide that inside the function
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough"
        ); // 1e18 == 1 * 10 * 18 == 1000000000000000000
        senders.push(msg.sender);
        sentAmount[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint senderIndex = 0;
            senderIndex < senders.length;
            senderIndex++
        ) {
            address funders = senders[senderIndex];
            sentAmount[funders] = 0;
        }
        senders = new address[](0);

        //Now to transfer ETH from this contract to an address who call this withdraw function
        // Here msg.sender is of type address which cannot sent ether or anything to anyother address
        // So we are making the address payable type which can sent any crypto from this contract to the callers address
        //also here address(this) refers to the address of this contract address
        /*  payable(msg.sender).transfer(address(this).balance);

    //Now using send method
    bool sendSuccess = payable(msg.sender).send(address(this).balance);
    require(sendSuccess,"send fail"); */

        //Now using call method and it is the most reccommed method
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    //since you are using this in the constructor you have to use immutable i dont know why i cant use contant also its only for the variable you are not changing

    modifier onlyOwner() {
        //require is old way for checking owner and it cost more gas
        //require(msg.sender == owner,"Sorry sir you are not the owner");

        //this is the new method for checking the owner
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    //What happen if someone send eth to this contract without calling the fund fuction
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        //to get the price you need to intreact with the oracle network in the chainlink contract
        //for that you need the ABI and the Contract Address

        (, int price, , , ) = priceFeed.latestRoundData();
        //it the price of the ETH in terms of USD
        //and it will return 8 decimal units
        return uint(price * 1e10);
    }

    /*     function getVersion() internal view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    } */

    function getConversionRate(uint _ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        uint ethPrice = getPrice(priceFeed);
        uint ethPriceInUsd = (ethPrice * _ethAmount) / 1e18;
        return ethPriceInUsd;
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