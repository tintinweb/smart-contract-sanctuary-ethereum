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
pragma solidity ^0.8.7;
import "./PriceConverter.sol";
//Get funds from users
//withdraw funds
//set a minimum funding value

//custom errors are stated outside of the contracts
error FundMe__Brokie();

contract FundMe {
    using PriceConverter for uint256;
    //minimum ethUSD value that can be sent to the contract
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //an array of all funders
    address[] public funders;
    //a mapping of all funder addresses to amount they funded.
    mapping(address => uint256) public funderToAmount;
    //use immutable on a constructor variable name that doesn't change.
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    //constructor to set the owner when deploying the contract. the "i_" shows immutability which is on the variable name during declaration.
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //a modi fier that checks to make sure the person about to call a function is the owner of the contract
    modifier onlyOwner() {
        require(i_owner == msg.sender, "you're not the owner dawg");
        _;
    }

    //function to fund the contract
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "get your money up"
        );
        funders.push(msg.sender);
        funderToAmount[msg.sender] = msg.value;
    }

    //function to withdraw from the contract only by the owner.
    function withdraw(address _to) public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            funderToAmount[funder] = 0;
        }
        funders = new address[](0);
        //this line withdraws the funds to the _to address
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        //revert is used here to save gas and error brokie is declared already outside of the contract
        if (!success) {
            revert FundMe__Brokie();
        }
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//the math here is weird even though i understand
library PriceConverter {
    //get the price from the chainlink datafeed
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        //Eth in terms of USD
        // convert this price 3000.00000000 to msg.value(1^18)
        //also consider the decimal so multiply by 1e10
        //also wrap in uint256 to typecast price cos price is int and msg.value is uint

        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return
            AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
                .version();

        //simplified this to that-->
        // AggregatorV3Interface aggversion = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        // return aggversion.version();
    }
}