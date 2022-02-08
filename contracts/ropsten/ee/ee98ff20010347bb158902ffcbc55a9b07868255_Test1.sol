/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface Test{
  function setAge(uint x) external;
  function getAge() external returns(uint);
}

contract Test1 is Test {

  uint  age;

  function  setAge(uint x ) override  public{
      age=x;
  }
  function  getAge() override  public view returns(uint)   {
      return age;
  }

}