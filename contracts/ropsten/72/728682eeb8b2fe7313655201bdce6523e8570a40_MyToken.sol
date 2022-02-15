/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: MIT;
pragma solidity >=0.8.0;

contract MyToken {
    string  constant public name = "[Your Token Name]";
    string  constant public symbol = "EECE571";
    string  constant public standard = "v1.0";
    uint256 immutable public totalSupply;  // immutable: values must be set inside constructor and can no longer be changed
    uint8   immutable public decimal;  // if = 18, we can have 1.000000000000000001 token

    event Transfer(  // event is for front end, browser pop up
        address indexed _from,  // indexed is for filters for subscription
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

    // external means can only be called by users, not smart contracts
    // internal means can only be called by this contract or children and grand-children derived from this contract
    // private means can only be called by this contract
    function transfer(address _to, uint256 _value) external returns (bool success) {  
        require(balanceOf[msg.sender] >= _value, "Insufficient fund in the account.");

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
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}