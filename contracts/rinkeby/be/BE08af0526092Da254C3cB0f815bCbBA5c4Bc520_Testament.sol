/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Testament {
    address _admin;
    mapping(address => address) _heirs; // address ผู้เขียนพินัยกรรม => address ผู้รับผลประโยชน์
    mapping(address => uint) _balances;
    event Create(address indexed owner, address indexed heir, uint amount);
    event DeathReport(address indexed owner, address indexed heir, uint amount);

    constructor() {
        _admin = msg.sender;
    }

    function create(address heir) public payable {
        require(msg.value > 0, "amount is zero");
        require(_balances[msg.sender] <= 0, "alreadey exists");

        _heirs[msg.sender] = heir;
        _balances[msg.sender] = msg.value;

        emit Create(msg.sender, heir, msg.value);
    }

    function deathReport(address owner) public {
        require(msg.sender == _admin, "unauthorized");
        require(_balances[owner] > 0, "no testament");

        emit DeathReport(owner, _heirs[owner], _balances[owner]);

        payable(_heirs[owner]).transfer(_balances[owner]);
        _heirs[owner] = address(0); // clear address ผู้รับผลประโยชน์
        _balances[owner] = 0;
    }

    function contracts(address owner) public view returns(address heir, uint balance) {
        return(_heirs[owner], _balances[owner]);
    }
}