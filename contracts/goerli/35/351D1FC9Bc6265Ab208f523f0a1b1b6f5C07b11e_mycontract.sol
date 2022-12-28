/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract mycontract{

    //private
    string _name;
    uint _amount;

    //   กำหดค่าเริ่มต้นในตัวแปร
    constructor(string memory name,uint amount){
       // require(amount>=500,"amount >= 500");
        _name = name;
        _amount = amount;
    }

    //ดูยอดคงเหลือ
    function getAmount() public view returns(uint amount){
        return _amount;
    }

    //ฝากเงินเพิ่ม
  /*  function deposite(uint balance) public {
        _amount+=balance;
    }

/*การนิยามตัวแปร 
โครงสร้างการนิยามตัวแปร
type access_modifier name;
*/

}