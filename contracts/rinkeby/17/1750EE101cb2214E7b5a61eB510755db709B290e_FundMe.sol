// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    //attaching the library!
    using PriceConverter for uint256;

    //want to set a minimum fund amount at 50 USD, but msg.value expresses a value
    // in eth / gwei or weis.  Need to convert Eth to Usd, using an Oracle.
    //Usd value to Eth is something set outside of the blockchain, need a descentralized
    //oracle network to provide this data.
    //1e18 equals to 1 ether
    // eth is using 18 decimals

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //after converting eth to usd with the function, we have to adapt the 50 dollars to
    // the decimals we are working with, which are 18.

    address[] public funders;
    //array of funders (addresses) that fund our contract.

    mapping(address => uint256) public addressToAmountFunded;
    //mapping that links the address to the amount funded.

    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "No enough fund"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // if we withdraw all the funds, we should clean the array of funders
    //and the mapping as well
    function withdraw() public onlyOwner {
        for (uint256 x = 0; x < funders.length; x++) {
            address funder = funders[x];
            addressToAmountFunded[funder] = 0;
        }

        //Reseting an array and clearing all data inside.
        funders = new address[](0);

        //send the ether with Call
        (bool callState, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callState, "Call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner);
        //gas efficient change
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //to manage transactions that may arrive to the contract via wallet or other
    // and not via the function fund
    // we are redirecting these transactions to fund function. it will cost more gas to
    //them but at least they will be noted as funders and get registered. (fund logic)
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//importing the interface directly form github / npm package: chainlink/contracts
// this is giving the ABI to interact with.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //Usage of chainlink data feeds (price feed). we ll need to interact with the
    //contract via its address and ABI.

    //Eth data feeds
    //Address ETH/USD in rinkeby network: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //this gonna return the price of ETH in terms of USD
        // have to match the maths between units, the function here is returning
        //price with 8 decimals, so we have to multiply per 10
        //to match 18 decimals of eth.
        //we are also typecasting to unit256 to match the var above.
        return uint256(price * 1e10);
    }

    // this func will convert eth value to usd value
    // first we are getting the price and then we are multiplying for the eth value in
    // wei I guess, the division is for limiting the result to 18 decimals.
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    // function getVersion() public view returns (uint256) {
    //     return
    //         AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
    //             .version();
    // }
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