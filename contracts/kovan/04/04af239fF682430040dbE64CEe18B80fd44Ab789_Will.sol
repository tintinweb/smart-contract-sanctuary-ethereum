/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// พินัยกรรม
contract Will {
    address _admin;
    struct Heir {
        address heir;
        uint amount;
    }
    uint _balance;
    mapping(address => Heir) _will;
    event Create(address indexed owner, address indexed heir, uint amount);
    event Tranfer(address indexed owner, address indexed heir, uint amount);

    constructor() { // เรียกครั้งเดียวตอน deploy
        _admin = msg.sender;
    }

    modifier isAdmin() {
        require(msg.sender == _admin, "you not admin");
        _;
    }

    modifier isHadWill(address willBuilder) {
        require(_will[willBuilder].amount > 0, "the person who said it did not had will");
        _;
    }

    modifier isAlreadyCreate() {
        require(msg.value > 0, "amount is zero"); // ต้องให้ทายาทมากว่า 0
        require(_will[msg.sender].amount <= 0, "already exits"); //  check ว่ามียอดฝากให้ทายาทแล้วรึมั้ย
        _;
    }
    function createWill(address heir) public payable isAlreadyCreate {
        _will[msg.sender].heir = heir;
        _will[msg.sender].amount = msg.value;
        emit Create(msg.sender, heir, msg.value);
        _balance += msg.value;
    }

    function checkWill(address willBuilder) public view isHadWill(willBuilder) returns (address heir,uint amount) {
        return (_will[willBuilder].heir, _will[willBuilder].amount);
    }

    function tranferForDie(address whoDie) public payable isAdmin isHadWill(whoDie) {
        payable(_will[whoDie].heir).transfer(_will[whoDie].amount);
         emit Tranfer(whoDie, _will[whoDie].heir, _will[whoDie].amount);
        _balance -= _will[whoDie].amount;
        
        _will[whoDie].heir = address(0); // clear ทิ้ง
        _will[whoDie].amount = 0;
    }

    function checkTotal() public view isAdmin returns (uint Balance) {
        return _balance;
    }

    function checkAdmin() private view returns (address admin) {
        return _admin;
    }
}