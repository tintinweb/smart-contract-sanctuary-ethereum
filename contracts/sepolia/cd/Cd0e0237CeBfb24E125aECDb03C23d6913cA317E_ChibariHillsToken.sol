/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChibariHillsToken {
    uint256 _totalSupply;
    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    string _name = "Chibari Hills token";
    string _symbol = "CHI";

    constructor (uint256 _initialSupply) {
        _totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }

    // what's the name and symbol of the token?
    function name() public view returns (string memory) {
        return _name;

    }

    // how to display the token amount human-readable
    function symbol() public view returns (string memory) {
        return _symbol;

    }
    // how many tokens exist? 変数をpublicで定義したら値を返すfunctionは作成しなくても良い！
    function decimals() public pure returns (uint8) {
        return 18;
    }

    // who owns tokens? and how many per person?
    // and how many per person?
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // how to transfer to new owner?
    function transfer(address _to, uint256 _value) public returns (bool successs) {
        // check if the sender has enough tokens
        require(balances[msg.sender] > _value, "Insufficient balance");

        // subtract from the sender
        balances[msg.sender] -= _value;
        // add to the recipient
        balances[_to] += _value;

        // log the transfer event
        emit Transfer(msg.sender, _to, _value);

        return true;
    }


}