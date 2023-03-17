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
import "./PriceConverter.sol";

//get funcds from users
//withdraw funds

error notOwner();

//constant and immutable to reduce cost
//835,893 gas cost before constant
//816,351 gas cost after constant
//792,868 gas cost after constant and immutable
contract FundMe {
    //library to add functionality to uint256
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // calling constant cost 351 gas
    // calling cost without constant 2451 gas

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    // calling owner without immutable is 2558 gas, 444 gas with immutable

    constructor(address priceFeedAddress) {
        //immutable can only be declared in a constant
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //want to be able to set a minumum amount in USD
        //require(getConversionRate(msg.value)>= minimumUsd, "didnt sent enough"); //1e18 = 1 * 10^18
        // call oracle or chainlink data feeds
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "didnt sent enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        //reset the index
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
        }
        // reset the array
        funders = new address[](0);
        // withdraw

        /*
        //1 transfer
        // transfer is capped at 2300 gas, or it fails with error
        //payable address vs address ( wrap it to cast it as payable type address
        payable(msg.sender).transfer(address(this).balance);
        
        
        // capped to 2300 gas, and it fails with a boolean
        //2 send
        bool sendSccess = payable(msg.sender).send(address(this).balance);
        require(sendSccess,"send failed");
        */

        //3 call
        // send or set add gas
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
        //767859 gas after using "if" instead of "require"
        //require(msg.sender == i_owner,"Sender is not the owner!");
        //_;
        /*
        _; is the code, run before or after the check or whatever logic you are adding to improve functionality
        */
    }

    //what happened if someone send eth without calling fund function
    //special functions
    // receive()
    // fallback()

    receive() external payable {
        fund();
    }

    // called when calldata is not blank
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI from npm interface
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountiInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountiInUsd;
    }
}