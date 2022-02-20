//SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

/*
Interfaces compiles down to an ABI(Application Binary Interface)
The ABI tells solidity and other programming languages how it can
interact with another contract.
Anytime you want to interact with an already deployed smart contract 
you will need an ABI.
*/

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToTotalFund;
    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    //payable keyword means the function can be used to pay for things
    //1 ETH = 1,000,000,000,000,000,000 wei = 1,000,000,000 Gwei

    function fund() public payable {
        uint256 minUSD = 50 * 10**18;
        require(getConversionRate(msg.value) >= minUSD, "below $50");
        addressToTotalFund[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //answer has 8 decimal places
        return uint256(answer) * 10000000000;
    }

    function getConversionRate(uint256 ethWei) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 convert = (ethPrice * ethWei) / 1000000000000000000;
        return convert;
    }

    //A modifier is used to change the behavior of a function in a declarative way.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // execute the following code
    }

    function withdraw() public payable onlyOwner {
        //this refers to the contract you are currently in
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 index = 0; index < funders.length; index++) {
            addressToTotalFund[funders[index]] = 0;
        }

        //iniitalize funders array to 0
        funders = new address[](0);
    }
}

/*
A library is similar to contracts, but their purpose is that they are
deployed only once at a specific address and their code is reused.
Using keyword:
The directive using A for B can be used to attach library functions
(from the libray A) to any type(B) in the context of a contract.
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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