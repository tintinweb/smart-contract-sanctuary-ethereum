/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
// contract 是建立合约
contract pig {
    uint public goal;
    // 开始需要一个储蓄的目标
    constructor(uint _goal){
        goal = _goal;
        // 把目前的目标给到希望设定的目标上
    }

   receive() external payable {}
//   这句话代表这个合约可以接收以太

  function getMybalence() public view returns (uint){
    //   创建一个我的现金金额的函数，让他是可被读取的，并且回传一个目前的金额
      return address(this).balance;
    //   把当前的金额回传给uint
  }

  function withdrow() public {
      if(getMybalence() > goal){
        //   提现的时候，我的现金的金额要大于我的目前设定的目标，才会进行销毁
          selfdestruct(msg.sender);
        //   当我结束之后需要摧毁合约的时候要把值传给（）里面的内容
      }
  }
}