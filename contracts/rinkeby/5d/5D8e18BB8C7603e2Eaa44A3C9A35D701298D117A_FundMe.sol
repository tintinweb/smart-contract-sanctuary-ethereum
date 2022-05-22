// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    // Rinkeby Testnet ETHUSD oracle address
    AggregatorV3Interface internal AggInt = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    mapping(address => uint256) public donorList;
    address[] public donors;
    address private owner;

    constructor() {
        owner = msg.sender;
    }


    function fund() public payable {

        //Minimum $50 ya'll cheap motherfuckers
        uint256 minUSD = 50;
        //require(weiToUSD(msg.value) >= minUSD, "Ya'll dutch or something? Was ist los mit euch?");
        donorList[msg.sender] += msg.value;
        donors.push(msg.sender);
        
    }

    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i<donors.length; i++) {
            donorList[donors[i]] = 0;
        }
        donors = new address[](0);
    }

    function ETHUSD_get() public view returns(uint256) {
        (,int price,,,) = AggInt.latestRoundData();
        return uint256(price) * 10 ** 10; //1 ETH -> 10^-18 USD
    }

    function weiToUSD(uint256 value) public view returns(uint256) {
        return (value * ETHUSD_get()) / (10 ** 36); //get function has 10^18 attached
    }

    modifier onlyOwner {
        require(msg.sender == owner, "stop tryna steal me money u dirty bich");
        _;
    }

}

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