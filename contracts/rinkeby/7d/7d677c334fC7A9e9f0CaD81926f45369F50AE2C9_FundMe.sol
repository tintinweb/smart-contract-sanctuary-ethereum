/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    //using SafemAthChainlink for uint256; -->

    // interfaces are minimal view from the contracts you call
    //interfaces compile down to an ABI
    //ABI Application Binary INterface,
    //tells solidity and other programming languages how it can interact with another contract.

    // anytime you want to interact with an alreadt deployed smart contract, you will need an ABI

    mapping(address => uint256) public addressToAmoutFunded;

    address[] public funders;

    address owner;

    constructor() public {
        owner = msg.sender; // insta gives you ownership
    }

    function fund() public payable {
        //payable thingy function can be used to pay for things

        uint256 minimumusd = 50 * 10 * 18; // for gwei

        require(getConversionRate(msg.value) >= minimumusd, "you cheap fuck: "); //just like an if , can even add a text if fault

        addressToAmoutFunded[msg.sender] += msg.value; // sender is the sender, and value the value.. key words
        // what the eth -> usd conversion rate? .. so need an oracle

        funders.push(msg.sender);
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
        /*
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )= priceFeed.latestRoundData();*/
        //  latestrounddate returns 5 datas if you see the interface, so we can do the same..
        // tuple is a list of potentially different types whose nuber is a costant at compile time.
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // we can leave blank what we dont use, no warnings and cleaner

        return uint256(answer * 10000000000);

        //  latestrounddate returns 5 datas if you see the interface, so we can do the same..
        // tuple is a list of potentially different types whose nuber is a costant at compile time.
    }

    function getConversionRate(uint256 ethamount)
        public
        view
        returns (uint256)
    {
        uint256 ethprice = getPrice();
        uint256 ethamountinusd = (ethprice * ethamount) / 1000000000000000000;

        return ethamountinusd;
    }

    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyowner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmoutFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    //SOLIDITY pit falls, lower than v 0.8 .. problems with overflow.. carefull with big numbers
    // we can importsafe math from openzepp
}