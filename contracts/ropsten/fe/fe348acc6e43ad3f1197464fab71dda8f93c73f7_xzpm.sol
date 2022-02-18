/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract xzpm{
    //查询储蓄目标
    uint public goal;
    address private owner;

    constructor(uint _goal){
        goal = _goal;
        // owner = msg.sender;
    }

    event eventBan(uint balance,string hint);

    receive() external payable{
        //eth发送时会触发
        emit eventBan(getMyBalance(),"haha hint"); 
    }
    
    // modifier vl(){
    //     require(msg.sender == ownera ,"checked error");
    //     _;
    // }

     //地址中的余额
    function getMyBalance()  public view  returns(uint) {
        return address(this).balance;
    }
    
    function extractGoal()  public {
        if(getMyBalance() > goal){
            //销毁合约
            selfdestruct(msg.sender);
        }
    }


}