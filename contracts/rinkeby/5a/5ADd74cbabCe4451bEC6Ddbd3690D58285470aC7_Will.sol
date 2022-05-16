/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Will {
    address _admin;
    mapping(address => address) _heirs;
    mapping(address => uint) _balances;
    event Create(address indexed owner, address indexed heir, uint amount);
    event Deceased(address indexed owner, address indexed heir, uint amount);

    constructor() { //ถูกเรียกใช้งานครั้งแรกและครั้งเดียว ก็คือตอนที่ deploy ขึ้นไป
        _admin = msg.sender; //คนที่ deploy
    }

    function create(address heir) public payable { //ตอนที่สร้างพินัยกรรมให้โอนเงินเข้ามาด้วย
        require(msg.value > 0, "amount is zero");
        require(_balances[msg.sender] <= 0, "already exists"); //ให้หนึ่งคนมีได้อันเดียว
        
        _heirs[msg.sender] = heir;
        _balances[msg.sender] = msg.value;
        emit Create(msg.sender, heir, msg.value);
    }

    function deceased(address owner) public {
        require(msg.sender == _admin, "unauthorized");
        require(_balances[owner] > 0, "no testament");

        emit Deceased(owner, _heirs[owner], _balances[owner]);

        payable(_heirs[owner]).transfer(_balances[owner]);
        _heirs[owner] = address(0); //โอนแล้วให้เคลียค่า ไม่มีตัวตน
        _balances[owner] = 0;
    }

    function contracts(address owner) public view returns(address heir, uint balance){
        return (_heirs[owner], _balances[owner]);
    }
}