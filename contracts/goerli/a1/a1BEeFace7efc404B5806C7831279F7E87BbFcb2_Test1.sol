// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IStorage {
    function store(uint256 num) external;
    function retrieve() external view returns (uint256);
}



contract Test1{
event log(bytes);
event logint(uint);
IStorage s;
 

constructor(address ss)
{
 s = IStorage(ss);
   
}
function test1() public returns (uint256){
           s.store(3);
           uint result = s.retrieve();
           emit logint(result);
           return result;
   }
  

}