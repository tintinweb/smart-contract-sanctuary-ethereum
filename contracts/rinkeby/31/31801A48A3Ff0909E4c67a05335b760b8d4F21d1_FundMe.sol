// get funds from users
// withdraw funds
// set minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

/* error NotOwner(); */
//used for bottom if()

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant minimumUsd = 50 * 1e18; //1 * 10 ** 18
    // constant used for variables only used once in code in order to reduce gas

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public /* immutable */ owner;

    AggregatorV3Interface public priceFeed; //modulaized depeding on chain we are on 

    constructor(address priceFeedAddress) {  //'adress priceFeed' is used to "mock" the chain so we can get a conversion without going to testnet
        //gets called when contract is deployed
        //will set up who owner is, so that only owner can withdraw funds
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a min fund amount in USD
        // 1. how do we send ETH to this contract
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough!"
        ); //must convert from ETH to USD
        //18 decimals
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;

        // what is reverting?
        // when do a require statement, if not met, gas will be returned back
    }

    function withdraw() public onlyOwner {
        // for loop
        //[a, b, c, d]
        //0. 1. 2. 3.
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex++ /* ++ same as + 1 */
        ) {
            //code
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset array
        funders = new address[](0);
        //actually withdraw

        //3 different ways
        //transfer
        /*  payable(msg.sender).transfer(address(this).balance); */
        //if fails, will error then will revert tx

        //send
        /*  bool sendSuccess = payable(msg.sender).send(address(this).balance); */
        /*  require(sendSuccess, "Send failed"); */
        //if fails, returns bool if it was succesful or not

        //call
        (
            bool callSuccess, /* bytes memory dataReturned */

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        //does not have capped gas like transder and send
        //if fails, returns bool if it was succesful or not

        //for the most part, call is recomended way to send and recieve token
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner!"); //== --> checking for equivlence
        /* if(msg.sender != owner) { revert NotOwner(); } */
        //allows to save gas instead of "sender is not owner!", calls error at top of code
        _; //_ represents doing rest of code
    }

    // what happens if someone sends this contract ETH without calling fund?
    // receive() and fallback()
    // see example in fallbackExample.sol

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        /* AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); */
        //no longer need above because of adding priceFeed to mock the price
        (, int256 price, , , ) = priceFeed.latestRoundData(); //only wanted int price so leave commas to not show other data
        //ETH in terms of USD
        //3000.00000000
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        //3000_000000000000000000 = ETH / USD price
        //1_000000000000000000 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        //299.999999999999999999 but in solidity will return 3000
        return ethAmountInUsd;
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