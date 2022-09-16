/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity ^0.8.11;

/*
1w 1%
2w 2%
1m 5%
2m 10%
3m 20%
6m 40%
1y 120% = 2x
2y 200% = 3x
3y 300% = 4x
4y 400% = 5x
*/

contract FetchFormula {
  function bonusPercent(uint _lockTime) external view returns(uint){
    if(_lockTime >= 7 days && _lockTime < 14 days){
      return 1;
    }
    else if(_lockTime >= 14 days && _lockTime < 30 days){
      return 2;
    }
    else if(_lockTime >= 30 days && _lockTime < 60 days){
      return 5;
    }
    else if(_lockTime >= 60 days && _lockTime < 90 days){
      return 10;
    }
    else if(_lockTime >= 90 days && _lockTime < 180 days){
      return 20;
    }
    else if(_lockTime >= 180 days && _lockTime < 365 days){
      return 40;
    }
    else if(_lockTime >= 365 days && _lockTime < 730 days){
      return 120;
    }
    else if(_lockTime >= 730 days && _lockTime < 1095 days){
      return 200;
    }
    else if(_lockTime >= 1095 days && _lockTime < 1460 days){
      return 300;
    }
    else if(_lockTime >= 1460 days){
      return 400;
    }
    else{
      return 0;
    }
  }
}