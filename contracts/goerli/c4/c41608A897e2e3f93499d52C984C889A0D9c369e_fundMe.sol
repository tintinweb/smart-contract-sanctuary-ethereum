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

// SPDX-License-Identifier:MIT

pragma solidity 0.8.1;

import "./priceCalculator.sol"; //we can store all libraries in the library file and use it by making it "internal"

// error notOwner();

contract fundMe {
    using priceCalculator for uint256; //declare that we are using library for uint256

    uint256 public constant minimumUSD = 2 * 1e18; //constant is used to decrease gas fee
    address[] public funder; // for storing who send us funds
    mapping(address => uint256) public AddressToFund;
    address public immutable owner; //same o decrease gas fee

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversion(priceFeed) >= minimumUSD,
            "Minimum ether worth 2 USD can be send"
        ); //1e18=1*10**18 (Wei)=1 ether
        funder.push(msg.sender); //msg.sender gets address of sender
        AddressToFund[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funder.length;
            funderIndex++
        ) {
            address f = funder[funderIndex];
            AddressToFund[f] = 0; //setting address of funder to 0;
        }

        funder = new address[](0); //reset funder array with 0 elements in it

        //Three types to retrive funds
        //1.Transfer->if gas limit>2300 transaction will fail
        //2.Send -> if gas limit>2300 it will show error by returning boolean
        //3.Call -> no limit, returns 2 value->1.boolean,2.bytes

        (bool callSuccesss, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccesss, "Transaction Failed");
    }

    modifier onlyOwner() {
        //  require(msg.sender==owner,"Tere baap ka paisa hai kya");
        if (msg.sender != owner) {
            // revert notOwner(); // use to save gas
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

// SPDX-License-Identifier:MIT

pragma solidity 0.8.1;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceCalculator {
    //ADDRESS:0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //ETH Price in terms of USD
        return uint256(answer * 1e10); //we multiply it by 10^10 because our msg.value is of 18 decimal places and our answer is of 8 decimal places
    }

    function getConversion(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethinUSD = (ethPrice * ethAmount) / 1e18; //ethPrice=18 decimal  ethAmount=18 decimal So we divide it by 10^18 as multiplication will result in 36 decimal
        return ethinUSD;
    }
}