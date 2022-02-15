/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract xzpm{
    //查询储蓄目标
    uint public goal;

    constructor(uint _goal){
        goal = _goal;
    }

    receive() external payable{
        //eth发送时会触发
    }

     //地址中的余额
    function getMyBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function extractGoal() public {
        if(getMyBalance() > goal){
            selfdestruct(msg.sender);
        }
    }


}