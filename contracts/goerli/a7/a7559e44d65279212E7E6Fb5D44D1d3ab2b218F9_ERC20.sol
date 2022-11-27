/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ERC20 {
    mapping(address => uint) balances;
    mapping(bytes32 => uint) allowances;
    uint totalSupply;
    address owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        bytes32 key = keccak256(abi.encodePacked(_owner, _spender));
        return allowances[key];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value <= balanceOf(msg.sender));

        // NOTE: This may be a security flaw: preimage attack.
        // Theoretically I could find (msg.sender, _spender) combo that
        // clashes with existing allowance, and change it
        bytes32 key = keccak256(abi.encodePacked(msg.sender, _spender));
        allowances[key] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;        
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balanceOf(msg.sender));

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);

        bytes32 key = keccak256(abi.encodePacked(_from, msg.sender));
        uint _allowance = allowances[key];

        require(_allowance >= _value);

        allowances[key] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address recipient, uint256 amount) public payable returns (bool) {
        require(msg.sender == owner);

        totalSupply += amount;
        balances[recipient] += amount;
        return true;
    }

    function burn(address recipient, uint256 amount) public returns (bool) {
        if (amount > balances[recipient]) {
            amount = balances[recipient];
        }

        uint eth = amount * address(this).balance / totalSupply;
        recipient.call{value: eth}("");

        // change state after sending funds to the recipient: THIS allows reentrancy.
        balances[recipient] -= amount;

        return true;
    }

    receive() external payable {}
}