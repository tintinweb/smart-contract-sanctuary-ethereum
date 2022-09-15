/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContent_sec2 {
    //single line comment
    //นิยามตัวแปร

    //multiple line comment
    /*
    โครงสร้างการนิยามตัวแปร
    type access_modifier name;


    */
//private
 
    bool status = false;
    string name = "manoon what the f";
    int amount = 0;
    uint balance = 1000; //ไม่สามารถเป็นค่าติดลบ

    //Variable + access modifier : 

    string _name;
    uint _balance;

    constructor(string memory name,uint balance){ // แอทริบิวต์ตัวหนึ่งต้องเก็บเป็น Key
    require(balance>0,"balance greater zero (money>0)");
     _name = name;
     _balance = balance;

     }
    //ดึงค่า _balance จาก storage
    function getBalance() public view returns(uint balance){
        return _balance;
    }
    //ค่าคงที่
    function getStatic() public pure returns(uint balance){
        return 50;
    }

   /* function deposite(uint amount) public {
        _balance+=amount;
    }
*/


}