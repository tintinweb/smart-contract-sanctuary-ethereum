// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interface AggregatorV3Interface {
//   function decimals() external view returns (uint8);

//   function description() external view returns (string memory);

//   function version() external view returns (uint256);

//   // getRoundData and latestRoundData should both raise "No data present"
//   // if they do not have data to report, instead of returning unset values
//   // which could be misinterpreted as actual reported values.
//   function getRoundData(uint80 _roundId)
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );
// }

import "AggregatorV3Interface.sol";

contract fundMe {
    address public owner;
    address[] public funders;

    //constructor will get executed immediatly when we deploy the smart contract
    constructor() public {
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunding;

    function fund() public payable {
        uint256 minimumUSD = 1 * 10**14;

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        //msg is the object in smart contract transaction
        addressToAmountFunding[msg.sender] += msg.value;

        funders.push(msg.sender);

        // lets add money to address in usd
        // we need to know what is the ETH -> USD conversion rate

        //interfaces can be imported as below
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        //  (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        //  )=priceFeed.latestRoundData();

        //we can ignore the returned variables/data by leaving them blank and comma seperated
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10**10);
    }

    //1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethUSD = (ethPrice * ethAmount) / 10**18;
        return ethUSD;
        //0.000001180902011770
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract!");
        _;
    }

    function withdraw() public payable onlyOwner {
        //we only want the owner to make withdrawl
        // require
        // msg.sender.transfer(address(this).balance);

        // update in 0.8.0 solidity compiler
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunding[funder] = 0;
        }

        funders = new address[](0);
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