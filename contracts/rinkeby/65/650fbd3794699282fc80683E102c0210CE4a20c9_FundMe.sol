//SPDX-License-Identifier: MIT
//pragma
pragma solidity >=0.6.0 <0.9.0;

//701,962 gas price without immutable and constant keywords
//657501  gas price with immutable and constant keywords

//imports
import "./PriceConverter.sol";
// error codes
error FundeMe_Notowner();

//Interfaces , libraries , contract
/**
 * @title A contract for crwod funding
 * @author Ahmad Fareed Khan
 * @notice This contract is to demo a simple funding contract
 * @dev  This implements price feed as our library
 */

contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    address[] public s_funders;
    mapping(address => uint256) public s_AddressToAmountFunded;

    uint256 public constant MINIMUM_USD = 50 * 10**18;
    //23471 * 42520000000 gas price without constant
    //21415 gas price with constant

    //address public immutable i_i_owner;
    address public immutable i_owner;

    //23622 gas price without immutable
    //21508 gas price with immutable

    // Modifiers
    modifier onlyi_owner() {
        //require (msg.sender == i_i_owner , "Sender is not a i_owner");
        //657513
        if (msg.sender != i_owner) {
            revert FundeMe_Notowner();
        }
        //632402
        _; //rest of code represent with _
    }

    // Funtions Order:
    // constructor
    // receive
    // fallback
    // external
    // public
    // internal
    // private
    // view/pure
    AggregatorV3Interface public s_priceFeed;

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev  This implements price feed as our library
     */

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );

        s_funders.push(msg.sender);

        s_AddressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyi_owner {
        // for loop
        for (
            uint256 s_fundersIndex = 0;
            s_fundersIndex < s_funders.length;
            s_fundersIndex++
        ) {
            address Funder = s_funders[s_fundersIndex];
            s_AddressToAmountFunded[Funder] = 0;
        }
        //reset an Array
        s_funders = new address[](0);

        //Different ways to send Ethereum

        //  transfer
        //  payable(msg.sender).transfer (address(this).balance);

        //  send
        // bool sendSuccess = payable(msg.sender).send (address(this).balance);
        // require(sendSuccess,"Send Failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    // function cheaperWithdraw() public onlyi_owner {
    //     address[] memory s_funders = s_funders;
    //     // mappings can't be in memory, sorry!
    //     for (
    //         uint256 funderIndex = 0;
    //         funderIndex < s_funders.length;
    //         funderIndex++
    //     ) {
    //         address funder = s_funders[funderIndex];
    //         s_AddressToAmountFunded[funder] = 0;
    //     }
    //     s_funders = new address[](0);
    //     // payable(msg.sender).transfer(address(this).balance);
    //     (bool success, ) = i_owner.call{value: address(this).balance}("");
    //     require(success);
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        //ABI
        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e18);
    }

    // function getVersion() public view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e10;
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