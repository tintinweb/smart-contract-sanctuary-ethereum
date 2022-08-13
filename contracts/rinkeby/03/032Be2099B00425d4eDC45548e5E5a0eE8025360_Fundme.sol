pragma solidity ^0.8.5;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./priceConverter.sol";

contract Fundme {
    event funded(address sender, uint msg);
    using priceConvert for uint256;
    uint256 public constant MINIMUM_USD = 20 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToamountFunded;
    address owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            // here msg.value is first param that is defined in getConversion() function and 2nd param will be passed in paranthesis of this function
            msg.value.getConversion(priceFeed) >= MINIMUM_USD,
            "not sufficient amount please check also"
        );

        funders.push(msg.sender);
        addressToamountFunded[msg.sender] = msg.value;
        emit funded(msg.sender, msg.value);
    }

    modifier checkOwner() {
        require(msg.sender == owner, "not authorised");
        _;
    }

    function withdraw() public checkOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToamountFunded[funders[funderIndex]] = 0;

            funders = new address[](0);

            // send ether

            (bool status, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");

            require(status, "transaction failed");
        }
    }

    // if someone send ether to this address then fund function will call automatically by recieve

    receive() external payable {
        fund();
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

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceConvert {
    // to get the value of eth in usd  we need to interact with other address
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // get address of the conract that give price of eth ==> 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
        // return price of eth lets assume 1200 dollar follower by 18 digit
    }

    function getConversion(uint256 amounteth, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed); // eprice 1500 dollar followed  by 18 digit
        // amount of eth also follwod by 18 zeros
        // then multiply price with amout of th
        /*3000000000000000000000*1000000000000000000/1000000000000000000
        3e+21
       
 
        */

        uint256 ethUSD = (amounteth * ethPrice) / 1e18;
        return ethUSD;
    }
}