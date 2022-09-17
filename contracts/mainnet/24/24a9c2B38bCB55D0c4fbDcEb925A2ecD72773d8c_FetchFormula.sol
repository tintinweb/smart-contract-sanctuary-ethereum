/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity ^0.8.11;

contract FetchFormula {
  function bonusPercent(uint _lockTime) external pure returns(uint){
    if(_lockTime >= 90 days && _lockTime < 180 days){
      return 50;
    }
    else if(_lockTime >= 180 days && _lockTime < 365 days){
      return 75;
    }
    else if(_lockTime >= 365 days && _lockTime < 730 days){
      return 100;
    }
    else if(_lockTime >= 730 days && _lockTime < 1095 days){
      return 100;
    }
    else if(_lockTime >= 1095 days && _lockTime < 1460 days){
      return 100;
    }
    else if(_lockTime >= 1460 days){
      return 100;
    }
    else{
      return 0;
    }
  }
}