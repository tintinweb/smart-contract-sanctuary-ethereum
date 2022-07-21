// Purpose of this smart contract is to:
// Get funds from the users
// Set a minimum funding value in USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "contracts/PriceConverter.sol";
// gas 966,342
// gas 943,891 after constant
// gas 916,913 after immutable
// gas 888,041 after replacing 1 require for error

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;

    address[] public founders;
    mapping(address => uint256) public addressToAmountFunded;

    // immutable should be used when you not assigning a variable in the same place as declaring it
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // when we deploy this contract we automatically assign creator to be an owner --> important when withdraw()
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // we are not passing any value to getConverionRate because msg.value is considered as a first parameter
        // if we had second parameter in getConversionRate we would have to pass it
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough"
        );
        founders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //using modifier here; we want to make sure that only owner can withdraw
        // for loop very similar to C++ loop (starting point, ending point, incremental)
        for (
            uint256 founderIndex = 0;
            founderIndex < founders.length;
            founderIndex = founderIndex + 1
        ) {
            address founder = founders[founderIndex];
            addressToAmountFunded[founder] = 0;
        }
        //completely resetting the founders array
        founders = new address[](0);
        //actually withdrawing the funds
        // there are 3 ways of withdrawing the funds: 1) transfer 2) send 3) call
        // transfer from different contract to each other
        //payable(msg.sender).transfer(address(this).balance);
        // if not sufficient gas it will revert and throw an error
        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send faild");
        // you need to add require in order to revert the transaction in case of error. Without it transaction will not be reverted
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // returns 2 variables
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        } // this saves a lot of gas because we don't have to store string as an array
        _; // _ represents doing the rest of the code in modified function
    }

    // What happens if someone sends this contract eth without calling the fund function

    // receive()
    receive() external payable {
        fund();
    }

    // fallback()
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Rinkeby ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
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