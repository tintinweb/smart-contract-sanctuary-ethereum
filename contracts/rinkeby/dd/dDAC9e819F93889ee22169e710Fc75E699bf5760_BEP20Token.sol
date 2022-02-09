// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract BEP20Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    uint256 public initialSupply;
    string public name;
    string public symbol;
    uint256 public decimals = 18;

    event Transfer(
        address indexed sender,
        address indexed receiver,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        initialSupply = _initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function transfer(address _receiver, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Balance is too low.");
        balances[_receiver] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _receiver, _value);
        return true;
    }

    function transferFrom(
        address _sender,
        address _receiver,
        uint256 _value
    ) public returns (bool) {
        require(balances[_sender] >= _value, "Balance is too low.");
        require(
            allowances[_sender][msg.sender] >= _value,
            "Allowance is too low."
        );
        balances[_receiver] += _value;
        balances[_sender] -= _value;
        emit Transfer(_sender, _receiver, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}