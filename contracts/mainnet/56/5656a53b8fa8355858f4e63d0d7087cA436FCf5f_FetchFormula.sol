/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity ^0.8.11;

/*
1w 1%
2w 2%
1m 5%
2m 15%
3m 50%
6m 125%
1y 200%
2y 350%
3y 500%
4y 800%
*/

contract FetchFormula {
  function bonusPercent(uint _lockTime) external pure returns(uint){
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
      return 15;
    }
    else if(_lockTime >= 90 days && _lockTime < 180 days){
      return 50;
    }
    else if(_lockTime >= 180 days && _lockTime < 365 days){
      return 125;
    }
    else if(_lockTime >= 365 days && _lockTime < 730 days){
      return 200;
    }
    else if(_lockTime >= 730 days && _lockTime < 1095 days){
      return 350;
    }
    else if(_lockTime >= 1095 days && _lockTime < 1460 days){
      return 500;
    }
    else if(_lockTime >= 1460 days){
      return 800;
    }
    else{
      return 0;
    }
  }
}