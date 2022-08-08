/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

/* 新目標
1. 查出goal的單位: wei, 1 ether = 10**18 wei     >done
2. 能領出自己設定數字的錢                         >done
3. 存到goal能自動領出，並銷毀撲滿(能具體知道銷毀了嗎? => contract那邊的bytecode直接消失)
*/
contract PiggyBank{
    uint public goal;    //目標金額，可被查詢，單位wei
    constructor(uint _goal){
        goal = _goal;
    }
    receive() external payable{   //可收ether
        //withdraw();     //大於goal直接selfdistruct
    }     

    function getMyBalance() public view returns(uint){
        return address(this).balance;
    }
    function takeMoney(uint want) public returns (bool) {      //領設定的金額
        msg.sender.transfer(want);
        return true;
    }
    function withdraw() public{
        if(getMyBalance() > goal){        //儲蓄大於目標金額
            selfdestruct(msg.sender);     //摧毀後送錢給msg.sender
        }
    }
    //msg.sender: 最後一個呼叫(操作)contract的address
}