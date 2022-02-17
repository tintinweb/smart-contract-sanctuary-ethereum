/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

//SPDX-License-Identifier: MIT;
pragma solidity >=0.8.0;

contract MyToken {
    string  public name = "571";
    string  public symbol = "EECE";
    string  public standard = "v1.0";
    uint256 public totalSupply;
    uint8 public decimal = 18;

    event Transfer(
        // indexed 作用是filter
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply, uint8 _decimal) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        decimal = _decimal;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        // default 没看懂 behavior if we do not have to here
        //balanceOf[msg.sender] += _value;

        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}