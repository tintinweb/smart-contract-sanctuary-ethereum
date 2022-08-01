// Send funds to contract
// Withdraw funds from contract
// Fix minimum value of fund to send to contract

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// 822,736
// 800,890
error FundMe__NotOwner();

/** @title A contract for crowd funding
    @author Lawal Habeebullahi
    @notice This is just a demo
    @dev This implements price feeds as our library
 */
contract FundMe {
    uint256 public constant MINIMUM_FUND = 5 * 10**18;
    using PriceConverter for uint256;

    AggregatorV3Interface public s_priceFeed;

    address public immutable i_Owner;

    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    modifier admin() {
        // require(msg.sender == i_Owner, "Administrator only");
        if (msg.sender != i_Owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_Owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // require(convertToDollars(msg.value) > MINIMUM_FUND, "Didn't send enough funds.");
        require(
            msg.value.convertToDollars(s_priceFeed) > MINIMUM_FUND,
            "Not enough funds"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function Withdraw() public admin {
        // reset s_funders mapping
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset s_funders array
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable admin {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Unable to send funds to admin");
    }

    // function getAddressToAmountFunded(address _address)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return (s_addressToAmountFunded[_address]);
    // }
}
// send funds to another address
// funds can only be sent to payable address types
// Three means of sending funds:
// // > transfer
// payable(msg.sender).transfer(address(this).balance);
// // > send
// bool sendSuccess = payable(msg.sender).send(address(this).balance);
// require(sendSuccess, "Send failed");
// > call

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getEthInDollars(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // interact with the ORACLE to get latest market eth value in dollars
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 ethValueInDollars, , , ) = priceFeed.latestRoundData();

        return uint256(ethValueInDollars * 1e10);
    }

    function convertToDollars(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethInDol = getEthInDollars(priceFeed);
        return (ethAmount * ethInDol) / 1e18;
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