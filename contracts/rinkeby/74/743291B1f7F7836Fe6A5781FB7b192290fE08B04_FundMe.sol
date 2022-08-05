// Get Funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*  importing AggregatorV3Interface dirctly from github or 
 what it is call an NPM package.
 NPM is a package manager use to store different versions
  contracts for us to directly import into our code
  */
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

// 898,251
// 878,949
// 855,986

contract FundMe {
    using PriceConverter for uint256;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    // 23,400 if not immutable
    // 21,200 if immutable.
    address public immutable i_owner;

    /* hold address of funders  */
    address[] public funders;
    /* map address of funders to how many ether they sent */
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "only owner can call");

        // alternative and gas efficient (save gas cost) way of requir().
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    /* what happened if someone sends this contract ETH without caling the fund function
    
    -> receive()
    -> fallback()
    */
    uint256 public constant minimumUsd = 50 * 1e18;

    function fund() public payable {
        // getConversionRate(msg.value);
        //want to be able to set a minimum fund amount in USD
        //1. How to we send ETh to this Contract?
        require(
            PriceConverter.getConversionRate(msg.value, priceFeed) >=
                minimumUsd,
            "Funds are not Enough! "
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
        //what is reverting ?
        // undo any action before, and send reamining gas back.
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);
        //actually withdraw the funds
        // payable(msg.sender).transfer(address(this).balance);

        // transfer
        payable(msg.sender).transfer(address(this).balance);
        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");

        require(callSuccess, "Call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

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

/* Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.

A library is embedded into the contract if all library functions are internal.

Otherwise the library must be deployed and then linked before the contract is deployed. */

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        /* to get the price we have to interacte 
        with the off chain contract to interacting with the
        external contract data we need the other's contract
        ABI and Address we can get from data feed on docs.chain.link site */

        // ABI
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     /* 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e */
        //     priceFeed
        // );

        /* -> this will be the latest price of ETH in 
       terms of USD 
       -> solidity does not deal with the 
       decimal numbes so the price that will be return 
       have eight decimal i.e 
       1 ETH = 3000.00000000 this is just for example
       it is not the actual value but every value have 
       eight decimals in it.*/
        (
            ,
            /* uint80 roundID */
            int256 price, /* uint startedAt */ /* uint timeStamp */ /* uint80 answeredInRound */
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    function getVersion(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.version();
    }

    /* this function take the eth amount as parameter
    and returns USD amount */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        /* for example we send 1 eth as parameter
        1 ETH = 1000000000000000000 has 18 zeros
        before the getprice() function call
        */
        uint256 ethPrice = getPrice(priceFeed);
        /* After getprice() function call 
        ethPrice = 3000_000000000000000000  18 decimal values at end of USD amount
        */
        /* When USD amount gets multiplied with the ethAmount(parameter value)
        it have 36 zeros at end we divide with 18 zeros to cancel 
        extra zeros to get actual amount */
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd;
    }
}

/* // Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice() internal view returns (uint256) {
        // Rinkeby ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
} */