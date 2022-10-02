// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConvertor.sol";

contract FundMe {
    // fund me contract
    using PriceConvertor for uint256;
    uint256 public minimumUsd = 50;

    address[] public funders; /// to keep the address of funders who are donating to our contract
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        // making the function payable by adding this keyword payable now it can get value of value button in the ide

        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd * 1e18,
            "Didn't send enough"
        ); // if minimumUSD<50 then it will revert the changes changes i.e. if we have done any computation before require function then revert will undo the change
        funders.push(msg.sender); // just like msg.value gives the amount of money msg.sender gives the address of sender
        addressToAmountFunded[msg.sender] = msg.value;
    }

    address public owner;
    AggregatorV3Interface public priceFeed;

    // making constructor to get owner address because it will give you the deployer address when it is deployed.
    constructor(address priceFeedAddress) {
        owner = msg.sender; // i.e. your wallet address
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // creating a withdraw function to reset the amount to 0 which is sent by funder

    function withdraw() public onlyOwner {
        // here

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmountFunded[funders[funderIndex]] = 0;
        }
        // Reseting the funders array
        funders = new address[](0); // 0 elements to start with i.e. totally reseting the array
        (bool sendSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sendSuccess, "Transaction Failed");
    }

    // modifier is basically a piece a code which is basically used to modify function i.e. in this modifier first the require statement will run and check whether it is the real owner or not
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _; // it represents the whole code
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Address of the contract ---> It can be found in the chain-link doc in the data feed section of current addresses
        // Address ----> 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // ABI (Application Binary Interface) ---> When you need to use the Code of another contract to use some of it's functions then you copy the interface of that contract into your contract to fetch those functionalities
        // For that interface either you can copy the whole Interface or can just import it using the import keyword along with the path
        //this is the most easy way to interact with contract that are outside i.e. we use the ABI with address to get the whole contract.
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // 1316059946540000000000 it will return this much value so conversion will be ans/1e18;
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     ); //this is the most easy way to interact with contract that are outside i.e. we use the ABI with address to get the whole contract.
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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