/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

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

// File: contracts/Ethprice.sol


//npm install @chainlink/contracts
//tutorial= https://docs.chain.link/getting-started/consuming-data-feeds/

// Address for interfaces, diferent pairs= https://docs.chain.link/data-feeds/price-feeds/addresses/

// deployed at: 0x680E6AE23421Bf2ef20f746f86C16935dE9d903b
contract Ethprice{
    AggregatorV3Interface internal precioEth;
    address constant goerliAggrAddr=0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
    string public pair;

    constructor(){
        precioEth = AggregatorV3Interface(goerliAggrAddr);
    }

    function lastPrice() external view returns (int256){
        (, int256 answer, , , ) = precioEth.latestRoundData();
        return answer;
    }

    function changePair(address _addr, string calldata _pair) external{
        pair=_pair;
        precioEth = AggregatorV3Interface(_addr);
    }

}