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
    //Default Private ควรมี _ ด้านหน้า
    //Variable + access_modifier
    bool _status;
    string _name;
    int _amount=100;
    uint _balance; //ไม่สามารถเป็นค่าติดลบ


    constructor(string memory name,uint balance){ 
        require(balance>=500,"balance greater zero (money>0)");
        //Please Input Balance More Than 199!!!!
       // require(name!==null,"Must fill in the name of the depositor.");
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

    // function deposite(uint amount) public {
    //     _balance+=amount;
    // }

}