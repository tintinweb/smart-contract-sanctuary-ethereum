/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

    //นิยามตัวแปร

    /*
    โครงสร้างการนิยามตัวแปร
    type access_modifier name;
    */

    /*
    private  คือ ให้คนเข้ามาดูไม่ได้ ดูได้แค่คนใน
    public   คือ 
    */

    //private 
    //bool _status = false;
    //string _name = "terapong potisuwan";
    //int _amount = 500;
    //เป็น + อย่างเดียวเท่านั้น
    //uint _balance = 1000;

    //private 
    string _name;
    uint _balance;

    //ถูก run แค่ ครั้งเดียว เท่านั้น
    constructor(string memory name, uint balance) {
        //require(balance > 0, "balance greater zero (money > 0)");
        //require(balance >= 500, "balance greater and equal 500");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balance) {
        return _balance;
    }

    // function deposite(uint amount) public {
    //     _balance += amount;
    // }

}