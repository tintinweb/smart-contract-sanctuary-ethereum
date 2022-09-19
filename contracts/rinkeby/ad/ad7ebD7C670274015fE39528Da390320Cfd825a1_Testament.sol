/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Testament{

    address _manager; // Set Private ด้วย public Ex. address public _manager;
    mapping(address=>address) _heir; // (address=เจ้าของ => address=ทายาท) _heir=ทายาท
    mapping(address=>uint) _balance; // (address=เจ้าของ => จำนวนเงิน) จำนวนเงิน
    event Create(address indexed owner, address indexed heir, uint amount); // เช็คจำนวนพินัยกรรม
    event Report(address indexed owner, address indexed heir, uint amount); // ปิดพินัยกรรม

    constructor(){ // Deploy Samrt Contract
        _manager = msg.sender; // คนที่ Deploy = manager
    }

    // owner create testament
    function create(address heir) public payable{
        require(msg.value>0,"Please Enter Money Greater then 0"); // เช็คเงินโอนเข้ามากกว่า 0
        require(_balance[msg.sender]<=0,"Already Testament Exists"); // ถ้า _balance ถูกเซ็ตค่าแล้ว จะกำหนดค่าใหม่ไม่ได้
        _heir[msg.sender] = heir; // เลข address
        _balance[msg.sender] = msg.value; // ค่าที่ส่งมา

        emit Create(msg.sender, heir, msg.value); // เรียกเช็คจำนวนพินัยกรรม
    }

    function getTestament(address owner) public view returns(address heir, uint amount){
        return (_heir[owner],_balance[owner]);
    }

    function reportOfDeath(address owner) public{
        require(msg.sender == _manager, "Unauthorized"); // ตรวจสอบว่าใช่ manager หรือไม่
        require(_balance[owner]>0, "No testament"); // ตรวจสอบว่า owner เคยเขียนพินัยกรรมนี้หรือไม่

        emit Report(owner, _heir[owner], _balance[owner]); // แจ้งการเสียชีวิต
        payable(_heir[owner]).transfer(_balance[owner]); // โอนเงินให้ทายาท
        _balance[owner] = 0; // Reset ค่า _balance
        _heir[owner] = address(0); // Reset ค่า _heir
    }
}