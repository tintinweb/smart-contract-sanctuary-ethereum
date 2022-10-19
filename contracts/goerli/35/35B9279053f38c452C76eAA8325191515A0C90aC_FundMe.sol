// Get funds from users
// Withdraw funds
// Set a minimum value in USD

// SPDX-License-Identifier: MIT

import "./PriceConverter.sol";
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
error NotOwner();

contract FundMe {
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAdd) {
        // gets called when deployed
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAdd);
    }

    using PriceConverter for uint256;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    function fund() public payable {
        // require -> if condition match or else revert
        // revert -> undo any action that happen befire and send the remaining gas back
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send enough funds"
        ); // 1e18 == 1 * 10 ** 18 = 1000000000000000000 wei = 1 eth
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] =
            msg.value +
            addressToAmountFunded[msg.sender];
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
            funders = new address[](0);

            // Transfering Eth
            //1. transfer
            payable(msg.sender).transfer(address(this).balance);
            //2. send
            bool sendSuccess = payable(msg.sender).send(address(this).balance);
            require(sendSuccess, "Send Failed"); //revert

            //3. call
            //lower level command
            (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
                .call{value: address(this).balance}("");
            require(callSuccess, "Call Failed");
        }
    }

    modifier onlyOwner() {
        // require (msg.sender==i_owner , "Sender is not an owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

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
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmmountInUSD = (ethPrice * ethAmmount) / 1e18;
        return ethAmmountInUSD;
    }

    function getVersion(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        return priceFeed.version();
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