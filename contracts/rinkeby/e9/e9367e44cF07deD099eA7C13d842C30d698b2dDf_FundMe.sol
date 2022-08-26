//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConvertor.sol";
//constant and immutable does get storegd in storage but contract itself.

error FundMe_NotOwner();

/**@title A crowd funding contract
 * @author Rob
 * @notice the Contract is for demo
 * @dev This Implements price feeds as our library
 
 */

contract FundMe {
    //type declaration
    using PriceConvertor for uint256;

    //state variable
    mapping(address => uint256) private s_AddrsstoFunds;
    address[] private s_funders;
    address private immutable i_owner;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    //function order
    ////constructor
    //// receive
    ////fallback
    ////externa;
    ////public
    ////internal
    ////private
    ////view,pure

    modifier OnlyOwner() {
        //require(msg.sender ==i_owner, "not owner");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.GetConversionPrice(s_priceFeed) >= MINIMUM_USD,
            "not enough funds"
        );
        s_funders.push(msg.sender);
        s_AddrsstoFunds[msg.sender] += msg.value;
    }

    function withdrawal() public OnlyOwner {
        // for(starting index, ending index, stepamount)
        //for (0,5,+1)
        //lets say `fundeINdex is 0` and `total funders are 5` and `stepamount is 1`
        // now funderindex is 0 which is true because its less than Total funders which are 5. so it will
        //move further and take stepamount which is `1`.. now fundersIndex is `1` which is still less than
        //totalfunders and take stepamount. it will keep loopig until `INdexamount is 5` and it gets false.
        //staring index culd be aby number where you want to start your index with.
        //ending index could be totalnumber.abi
        //steamount is how many numbers you want to go further
        // < less
        //> more

        for (
            uint256 fundersIndex = 0;
            fundersIndex < s_funders.length;
            fundersIndex++
        ) {
            address funder = s_funders[fundersIndex];
            s_AddrsstoFunds[funder] = 0;
        }

        // reset the s_funders array.
        s_funders = new address[](0);
        //transfer,send and call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "not owner");
    }

    function CheaperWithdrawal() public payable OnlyOwner {
        address[] memory funders = s_funders;
        //mmsping cant be in memory

        for (
            uint256 fundersIndex = 0;
            fundersIndex < s_funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            s_AddrsstoFunds[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //view and pure

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddresstoAmountfunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_AddrsstoFunds[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// address- 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function GetConversionPrice(
        uint256 EthAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 EthPrice = getPrice(priceFeed);
        uint256 EthPriceinUsd = (EthAmount * EthPrice) / 1e18;
        return EthPriceinUsd;
    }
}