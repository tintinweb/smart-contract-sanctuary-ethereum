// SPDX-License-Identifier: asas

pragma solidity ^0.8.0;

import "chainlink.sol";

contract fundme {
    mapping(address => uint256) public record;
//  check when we can send value while deloying 
// access transactionhash info, can you find address of deployed contract from the transaction data

    address owner;
    price chain;
    constructor() payable {
        chain = new price();
        owner = msg.sender;
    }
    
    modifier onlyowner {
        require(owner == msg.sender , "No eth");
        _;
    }

    function fund() external payable {
        // msg.value in wei -> to dollar
        uint256 newprice = this.convert(msg.value);
        // check if the value is greater than $50
        require(newprice > 50 , "Need more eth");
        // store amount in dollar
        record[msg.sender] += newprice;
    }
    
    function withdraw() external payable onlyowner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getbalance() external view returns(uint256){
        return address(this).balance;
    }

    function myaddress() external view returns(address){
        return address(this);
    }

    function convert(uint256 amount) external view returns(uint256){
        // convert 'amount'(in wei) to usd
        // rate is value of 1 eth in usd*10**8
        uint256 rate = chain.getprice();
        // because the rate is for 1 eth , and we are passing 'amount' in wei 
        uint256 converted_price = (amount * rate) / (10 ** 18);
        //uint256 ret = converted_price / 10 ** 8;
        return converted_price / (10 ** 8);
        //converted price is the amount in usd * 10**8. converted_price/10**8 is the converted price in usd.
        // returned is the amount in usd
    }

    //receive() external payable {} 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract price {
    // kovan network
    AggregatorV3Interface x = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    function getprice() external view returns(uint256){
        (,int256 answer,,,) = x.latestRoundData();
        /*  
        (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = x.latestRoundData();
    */
        // returns 1 eth (or 10**18 wei) in amount of answer/10**8 usd, 
        // 1 wei is answer/(10**26) usd , 
        return uint(answer);
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