/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 < 0.9.0;

contract PiggyBank{
    //設定儲蓄目標
    uint public goal;

    //合約一開始執行此目標
    constructor(uint _goal) {
        goal = _goal;
    }

    //收以太幣
    receive() external  payable {}

    //當前address的balance回傳出來
    function getMyBalance() public view returns(uint){
        return address(this).balance;
    } 

    //提領並銷毀合約
    function withdraw() public {
        if(getMyBalance() > goal) {
            //將balance轉給誰
            selfdestruct(payable(msg.sender));
        }
    }
}