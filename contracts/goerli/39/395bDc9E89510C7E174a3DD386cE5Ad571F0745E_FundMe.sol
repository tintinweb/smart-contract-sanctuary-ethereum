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

//Get Fund From Users
//WithDraw Funds
//Set A minimum Funding Value in USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // You can use other version See Slides for more info

/* interface AggregatorV3Interface {                     // We are importing it by Link because this a an                                                   //
  function decimals() external view returns (uint8);    // an ugly practice

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
    } */

import "./PriceConverter.sol";

// Constant, immutable
//	841840 gas
//  822310 gas
//-------------
//error NotOwner();// for revert use which is ga efficient

contract FundMe {
    using PriceConverter for uint256;
    //uint256 public number; // For Now Commented it
    uint256 public constant minimumUsd = 50 * 1e18; //1*10**18
    //	21371 gas, for constant in view function
    //23,400 gas , for non-constant in view function

    address[] public funders; // All the addreses who funded
    mapping(address => uint256) public addressToAmountFounded; // map to specific address

    address public immutable owner; //a global variable

    // 21508 gas, immutable
    //23644 gas, without immutable
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function Fund() public payable {
        //Want to be able to Send a minimum fund amount in USD
        //1.  How do we send ETH to this conaract
        //number=5;  // For Now Commented it
        //require(msg.value > minimumUsd, "Donot Send Enough");

        //require(getConversionRate(msg.value) >= minimumUsd, "Donot Send Enough"); //1e18 == 1*10**18= 1000000000000000000
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "You need to spend more ETH!"
        ); //value paramter pass to function in Library

        //a Ton of computation
        // What is Reverting
        //Undo any action before, and send ramaining gas back
        funders.push(msg.sender); // sender address
        addressToAmountFounded[msg.sender] += msg.value; // how much a specific adress send
    }

    function Withdraw() public onlyOwner {
        //require(msg.sender == owner, "Sender is not owner");/*May be other function in this contract need
        // this rquire statement therefore our focus is modifier.                                                        //
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFounded[funder] = 0;
        }
        //reset the address
        funders = new address[](0);
        // actually withdraw the fund

        /*
      // transfer
      payable(msg.sender).transfer(address(this).balance);   // Call is used today so comment the other
      // send
      bool sendSuccess=payable(msg.sender).send(address(this).balance);
      require(sendSuccess, "Send failed"); */

        //call
        (bool callSuccess /* byte memory storedata */, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Send failed");

        //msg.sender=address
        //payable(msg.sender)=payable address
        //payable(msg.sender).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner"); //NotOwner());
        //if(msg.sender !=owner){revert NotOwner();}
        _;
    }

    // what happen if some one send eth without calling the fund function
    // recieve()
    //fallback()
    receive() external payable {
        Fund();
    }

    fallback() external payable {
        Fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // You can use other version See Slides for more info

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //ABI
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
        // ETH in term of USD
        // 1,218.00000000
        return uint256(price * 10000000000); //1**10=10000000000
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; //// 1 * 10 ** 18 == 1000000000000000000=1e18 //36 zeros but we want 18 zeros
        return ethAmountInUsd;
    }
}