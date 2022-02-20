/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Mycontract {
//ทุกตัวที่ไม่ได้ประกาL public คือเป็น private อัตโนมัติ
//private ปิดการเข้าถึงตัวเเปรต่างๆ ใน contract ไม่ให้คนอื่นมาเห็น
// bool _status = false;
// string public name = "Ronnakon";
// int _amount = 0;
// uint _balance = 1000;

//นิยามเเค่ชื่อ ยังไม่กำหนดค่า
string _name;
uint _balance;

// ถูกทำงานในการเริ่มต้นครั้งเดียว โดยรับค่าก่อน deploy /  memory จำชื่อของเจ้าของบัญชี
constructor(string memory name, uint balance){
    //กำหนดกฏเกณฑ์
    // require(balance >= 500 ,"balance grater zero and equal 500");
    _name = name;
    _balance = balance;

}
//ระบุคีย์ view บอกว่าเราจะเข้าไปอ่าน เฉยๆนะ ไม่ขอทำอะไร ไม่เสียค่า Gas
function getBalance() public view returns(uint balance){
    return _balance;
}

//รีเทินค่าคงที่ที่อยากให้ดู ไม่ไปยุ่งกับข้อมูลด้านใน
// function getBalancePure() public pure returns(uint balance){
//     return 50;
// }

//เเบบเสียเงิน กรณีอยากฝากเงินเพิ่ม
// function desposite(uint amount) public {
//     _balance+=amount;
// }

}