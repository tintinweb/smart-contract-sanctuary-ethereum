/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract PiggyBank{
    uint public goal;    //目標金額，可被查詢，單位wei
    constructor(uint _goal){
        goal = _goal;
    }
    receive() external payable{
        withdraw();
    }     //可收ether

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

}