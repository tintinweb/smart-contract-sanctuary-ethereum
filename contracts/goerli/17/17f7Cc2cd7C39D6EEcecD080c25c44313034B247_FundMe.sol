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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5 * 1e18; // rounding to 18 decimal places
    address[] private s_funders; // array of addresses of funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Set Minimum fund amount in USD
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH!!"
        ); // 1e18 = 1*10**18 == 1000000000000000000 == 1 ETH
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
          
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); // new array filled with 0s
        //3 ways to withdraw funds

        // transfer
        /*
        payable(msg.sender.transfer(address(this).balance));
        */

        //send
        /*
        bool sendSuccess = payable(msg.sender.send(address(this).balance)); // send
        require(sendSuccess, "Withdraw failed!!");
        */
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner!!");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function getOwner() public view returns (address){
        return i_owner;
    }
    function getFunder(uint256 index ) public view returns (address){
        return s_funders[index];
    }
    function getAddressToAmountFunded(address funder) public view returns (uint256){
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface){
        return s_priceFeed;
    }
}

//Pending : https://youtu.be/gyMwXuJrbJQ?t=45438

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) public view returns (uint256) {
        // ABI
        //Address - 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // price is returned with total 18 decimal places
    }
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // multiplying 1e18 and 1e18 will give number with 36 decimal places, thus we divide it by 1e18
        return ethAmountInUsd;
    }
}