/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.4.16;

library Set {
  // 定义了一个结构体，保存主调函数的数据（本身并未实际存储的数据）。
  struct Data { mapping(uint => bool) flags; }

  // self是一个存储类型的引用（传入的会是一个引用，而不是拷贝的值），这是库函数的特点。
  // 参数名定为self 也是一个惯例，就像调用一个对象的方法一样.
  function insert(Data storage self, uint value)
      public
      returns (bool)
  {
      if (self.flags[value])
          return false; // 已存在
      self.flags[value] = true;
      return true;
  }

  function remove(Data storage self, uint value)
      public
      returns (bool)
  {
      if (!self.flags[value])
          return false; 
      self.flags[value] = false;
      return true;
  }

  function contains(Data storage self, uint value)
      public
      view
      returns (bool)
  {
      return self.flags[value];
  }
}