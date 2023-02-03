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

// import interface from github repository
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import library
import "./PriceConverter.sol";

// declare errors
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddr) {
        // whoever is deploying the contract is the owner of it
        owner = msg.sender;

        // priceFeed depending on which network we are working on
        // ETH/USD
        // etc.
        priceFeed = AggregatorV3Interface(priceFeedAddr);
    }

    // sends money
    function fund() public payable {
        // want to be able to set a minimum fund amount in USD
        // if value is > 1 ETH, accept it, else show error message
        // msg.value is detected as the first variable in the call getConversionRate()
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // withdraw/retires money
    function withdraw() public onlyOwner {
        // we get each address and update its value to 0
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // reset array (another way easier than the for loop)
        funders = new address[](0);

        // msg.sender = address
        // payable(msg.sender) = payable address
        // transfer
        payable(msg.sender).transfer(address(this).balance);

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "Sender is not the owner!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        // continue with the rest of the code of the function
        _;
    }

    // What happens if someone sends this contract ETH without calling the fund function?
    //

    // receive()
    receive() external payable {
        fund();
    }

    // fund()
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

// import interface from github repository
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // returns the price of ETH in terms of USD with all decimals
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // int256 answer is the ETH in terms of USD (price)
        // 3000.00000000 -> 8 decimals but we need 18
        return uint256(answer * 1e10);
    }

    // returns the ETH amount in USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}