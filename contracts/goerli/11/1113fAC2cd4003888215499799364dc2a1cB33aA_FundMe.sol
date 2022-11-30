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
pragma solidity 0.8.17;
import "./PriceConverter.sol";

error notOwner();

contract FundMe {
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunder;
    using PriceConverter for uint256;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "You are not eligible yet for donate minimum amount of fund...."
        ); //1e18 = 1 * 10 **18
        funders.push(msg.sender);
        addressToAmountFunder[msg.sender] = msg.value;
    }

    function widraw() public onlyowner {
        for (uint256 i = 0; i < funders.length; i = i + 1) {
            // Reset all Funders Array Valu or Array---------------
            addressToAmountFunder[funders[i]] = 0;
        }
        // Reset array---------------------
        funders = new address[](0);
        // transfer Method
        // change msg.sender to payblre type
        payable(msg.sender).transfer(address(this).balance);
        //send
        bool sucess = payable(msg.sender).send(address(this).balance);
        require(sucess, "Transfer Failed......");
        // call function
        (bool callsucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callsucess, "Transfer Failed......");
    }

    // Declaring modifire for sending all Data with Only modifire
    modifier onlyowner() {
        // require(msg.sender==i_owner,"You are not authrized to take this action.");
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
    }

    // what happens if someone sends this contract eths witout calling fund function.
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFee
    ) internal view returns (uint256) {
        // API
        // Address :- 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e).version();
        // AggregatorV3Interface priceFee = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFee.latestRoundData();
        return uint256(price * 1e10); //1**10=1000000000000
    }

    function getConversionRate(
        uint256 ethamount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethamount) / 1e18;
        return ethAmountInUsd;
    }
}