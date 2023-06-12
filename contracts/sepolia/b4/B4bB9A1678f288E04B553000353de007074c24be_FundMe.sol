// Get funds from user
// Withdraw
// Set minimum funding value in usd

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "contracts/PriceConverter.sol";
// 797258
// 777952
// 755061
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    /* CONStANT,Immutable */
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    int256 public Pprice;
    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    // 422
    address public immutable i_owner;
    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be able to send a minimum fund amount in usd
        // 1. How do we send ETH to this contract

        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "didn,t send enough"
        ); // 1e18 === 1*10*18 == 1000000000000000000
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
        // What is reverting?
        // undo any action before & send remaining gas back
    }

    function withdraw() public payable onlyOwner {
        // for loop
        // [1,2,3,4]
        for (
            uint256 s_fundersIndex = 0;
            s_fundersIndex < s_funders.length;
            s_fundersIndex++
        ) {
            address funder = s_funders[s_fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // actually withdraw the funds

        /* 1 Transfer */
        /* 2 Send */
        /* 3 Call */
        // msg.sender = address
        // payable(msg.sender) = payable address

        // payable (msg.sender).transfer(address(this).balance);
        // // Send
        // bool sendSuccess =  payable (msg.sender).send(address(this).balance);
        // require(sendSuccess,"send failed");
        // Call

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "callfailed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mapping can notbe in memory
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /* MODIFIER _______________=============_______________ */
    modifier onlyOwner() {
        require(msg.sender == i_owner, "sender is not owner!");
        //    if(msg.sender != i_owner){revert NotOwner();}
        /* underscore means do rest of the code */
        _;
    }

    /* MODIFIER _______________=============_______________ */

    function setPrice() public {
        // ABI
        // ADDRESS 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // AggregatorV3Interface s_priceFeed = AggregatorV3Interface(
        //     0x694AA1769357215DE4FAC081bf1f309aDC325306
        // );
        (
            ,
            /* uint80 roundID */ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = s_priceFeed.latestRoundData();
        // Eth in terms of USD
        // 3000.0000000
        Pprice = price;
    }

    // Receive()
    // fallback()
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
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // ADDRESS 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x694AA1769357215DE4FAC081bf1f309aDC325306
        // );
        (
            ,
            /* uint80 roundID */ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        // Eth in terms of USD
        // 3000.0000000
        return uint256(price * 1e10);
    }
}