/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue { 
    bool open; //ปกติก็จะ F ปิด ถ้าเราสั่งก็จะเป็นเปิด
    mapping(address => bool) voted; //ใครเลือกตั้งแล้ว โหวตแล้วโหวตไม่ได้อีก โหวตเสร็จเป็น T
    mapping(address => uint) ballots; //เลือกเลขอะไรไป
    uint[] scores; //เลขอะไรได้คะแนนเท่าไหร่
}

contract Election{
    address _admin;
    mapping(uint => Issue) _issues; //บันทึกไว้ของแต่ละคนที่โหวต
    uint _issueId; //บันทึกไว้เป็นid เป็นตัวรัน
    uint _min;
    uint _max;

    event StatusChange(uint indexed issuedId, bool open);
    event Vote(uint indexed issueId, address voter, uint indexed option); //ถ้าสงสัยว่าทำไมเราไม่เคยตั้งคำว่า voter มาก่อนแล้วมันใช้ได้ไง คือเราไปตั้งตรงที่ emit แล้วว่าเราจะเอาไรบ้าง


    constructor(uint min, uint max){
        _admin = msg.sender;
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unauthorized");
        _;
    }
    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "election opening");//เช็คว่าอันปัจจุบันไม่ได้เปิดอยู่นะ

        _issueId++;
        _issues[_issueId].open = true; //เปิดคูหา
        _issues[_issueId].scores = new uint[](_max+1); // สร้างarray
        emit StatusChange(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open,"election closed"); //คูหาต้องเปิดอยู่นะ เราถึงจะปิดได้

        _issues[_issueId].open = false; //ปิดคูหา
        emit StatusChange(_issueId, false); //เรซอีเว้น
    }

    function vote(uint option) public {
        require(_issues[_issueId].open, "election closed"); //จะโหวตได้ เช็คก่อนคูหาเปิดอยู่ไหม
        require(!_issues[_issueId].voted[msg.sender], "you are voted");//เช็คว่ายังไม่ได้โหวตนะ
        require(option >= _min && option <= _max, "incorrect option");//เลือกให้อยู่ใน min max

         _issues[_issueId].scores[option]++;//อาเรย์ที่มี option เป็น index ที่ส่งเข้ามา บอกว่าได้คะแนนเท่าไหร่
         _issues[_issueId].voted[msg.sender] = true;
         _issues[_issueId].ballots[msg.sender] = option; //ดูว่าโหวตอะไรไป
         emit Vote(_issueId, msg.sender, option); //บอกว่าเราจะส่งไรมั่ง
    }

    function status() public view returns(bool open_) {
        return _issues[_issueId].open; //เช็คว่าเปิดหรือปิด
    }

    function ballot() public view returns(uint option) {
        require(_issues[_issueId].voted[msg.sender], "you are not vote"); //เช็คว่าโหวตยัง

        return _issues[_issueId].ballots[msg.sender]; //ให้ดูได้แค่ของตัวเอง ดูของคนอื่นไม่ได้
    }

    function scores() public view returns(uint[] memory){
        return _issues[_issueId].scores; // รีเทินเป็นอาเรย์เลย
    }

}