/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.1;
contract array{
    uint256[] a;
    int size;
    uint256 id=0;
    function addData(uint256 _value) public {
        a.push(_value);id++;
    }
    function getsize() public view returns(uint256){
        return a.length;
    }
    function getValue(uint256 _id) public view returns(uint256){
          require(_id>=0);
         require(_id<id);
         return a[_id];
    }
    function arraySum() public view returns(uint256){
      uint i;
      uint256 sum=0;
      for(i=0;i<a.length;i++){
          sum+=a[i];
      }
      return sum;
    }
    function searchValue(uint256 _value) public view returns(bool){
        uint i;
      for(i=0;i<a.length;i++){
          if(a[i]==_value){
              return true;
          }
      }
      return false;
    }
}