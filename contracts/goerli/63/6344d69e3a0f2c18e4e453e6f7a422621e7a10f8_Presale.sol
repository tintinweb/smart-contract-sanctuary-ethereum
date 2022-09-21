/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

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

// File: contracts/ERCpresale.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface Erc20_SD
{
function name() external view  returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);

function totalSupply() external view returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);

}

contract Presale{

      Erc20_SD token;
      address public Owner;
      AggregatorV3Interface internal priceFeed;
      constructor(address _token, address _owner){
          token = Erc20_SD(_token);
          Owner = _owner; 
          priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
      }


      function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

      uint256 tokenPrice =500;
      
    function buy() payable public{
        require(msg.value>0,"Pay the Required price");
        // uint value = tokenPrice*10**token.decimals()*msg.value/10**18;
        // // // uint value = msg.value*tokenPrice*token.decimals();
        // token.transferFrom(Owner,msg.sender,value);
        uint tokenPriceInDollar= 2;
        uint value = (msg.value*uint(getLatestPrice()))/1 ether*tokenPriceInDollar/8;
        token.transferFrom(Owner,msg.sender,value);

    }

    function sell(uint value) public{
        require(value>0,"please enter some amount of tokens");
        uint _value =value*10**18/10**token.decimals()/tokenPrice; 
        token.transferFrom(msg.sender,Owner,value);
        payable (msg.sender).transfer(_value);
    }
}