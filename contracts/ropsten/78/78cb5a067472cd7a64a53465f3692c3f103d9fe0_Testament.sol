/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Testament{

address _trustee;
mapping(address=>address) _heir; //addressตัวแรกเป็นของOwnerเพื่อดูทายาทว่าจะโอนให้เป็นใคร
mapping(address=>uint) _balance; //address Owner ที่ระบุทรัพย์สินในพินัยกรรม
event Create(address indexed owner,address indexed heir,uint amount); //เมื่อมีการสร้างพินัยกรรมให้เก็บข้อมูลเอาไว้ ซึ่งสามารถเรียกดูข้อมูลได้เจ้าของเป็นใคร ทายาทเป็นใคร จำนวนทรัพย์สินมีเท่าไหร่
event Report(address indexed owner,address indexed heir,uint amount); //รายงานการส่งมอบพินัยกรรม
event Cancel(address indexed owner,uint amount); //รายงานการยกเลิกพินัยกรรม

constructor(){
    _trustee = msg.sender;   //ให้ผู้ดูแลเป็นคนจัดเตรียมพินัยกรรมและเก็บข้อมูลไว้
}
//owner create testament
function create(address heir)public payable{  //เจ้าของพินัยกรรมสร้างพินัยกรรมโดยระบุ address ทายาท
    require(msg.value>0,"Please enter money"); //กำหนด require ในการโอนต้องมีค่า >0
    require(_balance[msg.sender]<=0,"Already Testament exists"); //เงินที่กำหนดไว้แล้วให้สร้างได้พินัยกรรมเดียว โดยดูจาก address owner
    _heir[msg.sender] = heir;  //คนที่ทำการเรียกใช้ function มาบันทึกข้อมูลของทายาท
    _balance[msg.sender] = msg.value;  //จำนวนทรัพย์สินของ owner ที่ต้องการนำมาระบุในพินัยกรรม มันจะสร้าง contract มาเก็บจำนวนเงินนี้ไว้
    emit Create(msg.sender,heir,msg.value); //เรียกใช้งาน function event create
}
function getTestament(address owner) public view returns(address heir,uint amount){  //functionเรียกดูพินัยกรรมที่ถูกสร้างขึ้นมา
    return (_heir[owner],_balance[owner]); //ระบุ address ของเจ้าของพินัยกรรมเพื่อจะดูข้อมูลทายาท
}
function reportOfdeath(address owner) public{ //functionมอบมรดกให้ทายาทโดยระบบaddressเจ้าของพินัยกรรม
    require(msg.sender == _trustee,"Unauthorized"); //ตรวจสอบว่าเป็นผู้ดูแลหรือเปล่า
    require(_balance[owner]>0,"No Testament"); //ตรวจสอบว่า owner เคยเขียนพินัยกรรมไว้หรือเปล่า
    emit Report(owner,_heir[owner],_balance[owner]); //เมื่อมีการแจ้งเสียชีวิตจะมีรายงานไว้ตรวจสอบการส่งมอบมรดก

    payable(_heir[owner]).transfer(_balance[owner]); //โอนเงินในพินัยกรรมไปให้ทายาท
    _balance[owner]=0; //พินัยกรรมเป็น 0 ไม่สามารถนำพินัยกรรมมาใช้ใหม่ได้
    _heir[owner] = address(0); //ล้าง address ที่รับเงิน
}
function cancelthetestament(address owner) public{ //functionยกเลิกพินัยกรรมโดยระบบaddressเจ้าของพินัยกรรม
    require(msg.sender == _trustee,"Unauthorized"); //ตรวจสอบว่าเป็นผู้ดูแลหรือเปล่า
    require(_balance[owner]>0,"No Testament"); //ตรวจสอบว่า owner เคยเขียนพินัยกรรมไว้หรือเปล่า
    emit Cancel(owner,_balance[owner]); //เมื่อมีการแจ้งยกเลิกพินัยกรรมจะมีรายงานไว้ตรวจสอบการส่งมอบมรดก

    payable(owner).transfer(_balance[owner]); //โอนเงินในพินัยกรรมไปให้ทายาท
    _balance[owner]=0; //พินัยกรรมเป็น 0 ไม่สามารถนำพินัยกรรมมาใช้ใหม่ได้
    _heir[owner] = address(0); //ล้าง address ที่รับเงิน
}
}