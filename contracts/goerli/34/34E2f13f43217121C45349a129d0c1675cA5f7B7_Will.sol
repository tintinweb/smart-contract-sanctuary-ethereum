/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Will {
    address _admin;
    //Will handle only one heirs
    mapping(address => address) _heirs;
    mapping(address => uint) _balances;

    event Create(address indexed owner, address indexed heir, uint amount);
    event Deceased(address indexed owner, address indexed heir, uint amount);

    constructor() {
        _admin = msg.sender;
    }

    function create(address heir) public payable {
        require(msg.value > 0, "balance is zero");
        require(_balances[msg.sender] <= 0, "already exists");

        _heirs[msg.sender] = heir;
        _balances[msg.sender] = msg.value;

        emit Create(msg.sender, heir, msg.value);
    }

    function deceased(address owner) public {
        require(msg.sender == _admin, "unauthorized");
        require(_balances[owner] > 0, "no testament");

        emit Deceased(owner, _heirs[owner], _balances[owner]);

        payable(_heirs[owner]).transfer(_balances[owner]);
        _heirs[owner] = address(0);
        _balances[owner] = 0;
    }

    function getContracts (address owner) public view returns (address heir, uint amount) {
        return (_heirs[owner], _balances[owner]);
    }
}