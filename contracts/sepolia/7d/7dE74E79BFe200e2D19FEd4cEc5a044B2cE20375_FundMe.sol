// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConversion.sol";

//764,498
//757,885

error notOwner();

contract FundMe {
    using PriceConversion for uint256;

    uint256 public constant MIMIMUM_USD = 50 * 1e18;
    //329 - constant
    //2429 - non-constant

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunders;
    address public immutable i_owner;

    //444  gas execution - immutable
    //2580  gas execution - non-immutable

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionPrice(priceFeed) >= MIMIMUM_USD,
            "didn't enough send"
        );
        funders.push(msg.sender);
        addressToAmountFunders[msg.sender] += msg.value;
    }

    function withdraw() public {
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunders[funder] = 0;
        }

        //reseting the array
        funders = new address[](0);

        //Transfer
        // msg.sender = address
        // Payable(mag.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);

        // //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess , "send failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call faild");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner ,  notOwner());
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
    }

    //two special function
    //fallback - recevie
    receive() external payable {
        fund();
    }

    fallback() external payable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConversion {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //ABI
        //Address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //terms of ETH
        //1800,00000000
        return uint256(price * 1e10);
    }

    function getConversionPrice(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUSD;
    }
}