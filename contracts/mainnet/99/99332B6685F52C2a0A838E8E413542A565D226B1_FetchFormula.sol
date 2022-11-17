/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

pragma solidity ^0.8.11;

/*
1d 2
1w 5
2w 10
1m 20
3m 50

6m 100
1y 100
2y 100
3y 100
4y 100
*/


contract FetchFormula {
  function bonusPercent(uint _lockTime) external pure returns(uint){
    if(_lockTime >= 1 days && _lockTime < 7 days){
      return 1;
    }
    else if(_lockTime >= 7 days && _lockTime < 14 days){
      return 5;
    }
    else if(_lockTime >= 14 days && _lockTime < 30 days){
      return 10;
    }
    else if(_lockTime >= 30 days && _lockTime < 90 days){
      return 20;
    }
    else if(_lockTime >= 90 days && _lockTime < 180 days){
      return 50;
    }
    else if(_lockTime >= 180 days && _lockTime < 365 days){
      return 100;
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