// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

import "AggregatorV3Interface.sol";

contract FundMe {
    // To keep track of who sent what amount
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;

    // Using a constructor(fxn that gets called instantly we deploy contract) to immediately define owner
    constructor() public {
        owner = msg.sender;
    }

    function Fund() public payable {
        // / $50 threshold
        //uint256 minimumUSD = 50; // * 10**18;
        //require(getConversionRate(msg.value) >= minimumUSD, "You need to spend atleast $50! ");
        // / To append the value(amount in eth) to the sender
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // what is the ETH -> USD conversion rate? Oracles needed...
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // 1000000000
    // to convert whatever value user sends to eth amount
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // Using 10^7 iststead of 10^8, find out why? and why I didn't get many zeros
        uint256 ethAmountinUSD = (ethPrice * ethAmount) / 100000000000000000;
        return ethAmountinUSD;
    }

    modifier onlyOwner() {
        // To require msg.sender == owner
        // we add "_;" to run the rest of the code. It can be before modifier
        require(msg.sender == owner, "funds are safu boi");
        _;
    }

    // Transfer is a fxn in solidity that we can call on any address to send eth
    function withdraw() public payable onlyOwner {
        // we send money to address of "this"(contract that we're already in)
        // wrap the msg.sender in the payable keyWord argument.
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // To get the address of each funder to put into the mapping and reset it.
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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