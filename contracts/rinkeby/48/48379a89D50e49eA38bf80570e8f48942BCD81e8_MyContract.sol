/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract{
    /*
        นิยามตัวแปร
        โครงสร้างการนิยามตัวแปร
        type access_modifier name;
        type public access_modifier name; กรณีอยากให้คนอื่นดูได้
        string public name; // public
        unit private _private; //private
    */
    /*
        ปุ่ม deploy
        สีส้ม เสียค่า GAS
        สีฟ้า ไม่เสียค่า GAS
    */
    /*
        KEY Deploy MyContract 0x48379a89D50e49eA38bf80570e8f48942BCD81e8
    */

    // bool status = false;
    // string public name = "bigponzue";
    // int amount = 10000000; // เต็มบวก เต็มลบ เต็มศูนย์
    // uint balance = 100; // uint เต็มบวก


    string _name;
    uint _balance;

    constructor(string memory name,uint balance){
        require(balance >= 500,"balance greater and equal 500");

        _name = name;
        _balance = balance;
    }

    // pure ค่าคงที่
    // view ค่าใน storage หรือ ดูอย่างเดียว
    // payble มีการเรียกเก็บเงิน

    function getBalance() public view returns(uint balance){
        return _balance;
    }

    function deposit(uint amount) public {
        require(amount > 0,"amount greater zero");
        _balance += amount;


    }
    


}