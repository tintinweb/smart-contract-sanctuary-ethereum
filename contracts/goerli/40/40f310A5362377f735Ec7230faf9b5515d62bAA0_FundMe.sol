// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PriceConverter.sol";

// Constant , Immutable
// Constant make varibale gas efficeint
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 10**18;
    uint256 public conversionRate;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // function callMeRightAway(){}

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        //1. How do we send ETH to this contract
        // Nonce, GasPrice,Gas Limit,to, value,data, v,r,s
        // require(getConversionRate(msg.value) >= minimumUsd , "Didn't send enough"); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        // conversionRate = msg.value.getConversionRate();
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        // What is reverting
        // undo any action before, and send remaining gas back
    }

    function withdraw() public onlyOwner {
        // for loop
        // [1, 2, 3, 4]
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // code
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
        // actuallly withdraw fund

        // transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        // (bool callSucess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");

        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // What happens if someone sends this contracts ETH
    // withou calling fund function

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// Limit tinkering / triaging to 20 minutes
// Take at least 15 minutes yourself -> or be 100% sure
// you exhaused all options.

// 1.Tinker and try to pinpoint exactly what's going on
// 2.Google the exact error
// 2.5 Go to our Github repo discussion and/or update
// 3.Ask a question on  forum like stack Exchange eth or Stack overflow

// Advance concept of solidiy
// 1. Enums
// 2. Events
// 3. Try / Catch
// 4. Function Selectors
// 5. abi.encode /decode
// 6. Hashing
// 7. Yul / Assumbly

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // (uint80 roundId, int price, uint startedAt , uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData;
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 1339.00000000
        return uint256(answer * 10000000000); // 1** 10 == 1000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
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