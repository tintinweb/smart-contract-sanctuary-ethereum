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
pragma solidity 0.8.8;

import "./PriceConverter.sol";
error InsuffucientFunds();
error notOwner();

contract FundMe {
    using PriceConverter for uint256;

    address public immutable i_owner; // <--saves gas by saving variable in byte code!
    address[] public funders;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed0;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // <--saves gas by saving variable in byte code!
        priceFeed0 = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(priceFeed0) < MINIMUM_USD)
            revert InsuffucientFunds();
        //revert(); <--you can revert basically anywhwere in your code!
        //{revert InsuffucientFunds();}
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be contract owner!");
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    function showpairing() public view returns (string memory) {
        return PriceConverter.getDescription(priceFeed0);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        // require(msg.sender == i_owner, "Must be contract owner!");
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

/* if then revert like this  "if (msg.value.getConversionRate() < MINIMUM_USD)
revert InsuffucientFunds();" or this "if(msg.sender != i_owner) { revert notOwner();}"
with error codes above contract like this "error InsuffucientFunds();" and this "error
notOwner();" are newer methods acheiving the same ting as the "revert" key word

contract constructorExample {
    AggregatorV3Interface public priceFeedX;

    // Constructor method to create an AggregatorV3Interface variable
    constructor(address priceFeedAddressX) public {
        priceFeedX = AggregatorV3Interface(priceFeedAddressX);
    }
} */

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed0
    ) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed0 = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed0.latestRoundData();
        return uint256(price * 1e10);
        /* 
        WE CREATE A PRICE VARIABLE "priceFeed0" OF TYPE AGGREGATORV3INTERFACE, 
        WHICH WE IMPORTED FROM THE CHAINLINK REPO RIGHT HERE BELOW IN THE NEXT LINE,
        import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 
        WHICH IS AN INTERFACE OBJECT THAT GETS COMPILED DOWN TO THE ABI AND WHEN YOU 
        MATCH AN ABI WITH AN ADDRESS(WHICH HAS THE BIN, I THINK?!?!) YOU GET A CONTRACT 
        YOU CAN INTERACT WITH 
        */
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed0
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed0);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getDescription(
        AggregatorV3Interface priceFeed0
    ) internal view returns (string memory) {
        return priceFeed0.description();
    }
}