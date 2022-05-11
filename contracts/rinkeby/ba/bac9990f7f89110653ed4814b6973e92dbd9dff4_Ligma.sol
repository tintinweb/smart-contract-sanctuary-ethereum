/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.7;

contract Ligma {
    
    constructor(uint256 ownerBalance) {
        _totalSupply = ownerBalance;
        _balanceOf[msg.sender] = ownerBalance;
        emit Transfer(address(0), msg.sender, ownerBalance);
    }

    function name() public pure returns (string memory) {
        return "Ligma";
    }

    function symbol() public pure returns (string memory) {
        return "BALLZ";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balanceOf[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] > _value);
        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_allowanceOf[_from][msg.sender] > _value);
        require(_balanceOf[_from] > _value);
        _allowanceOf[_from][msg.sender] -= _value;
        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowanceOf[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowanceOf[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) _balanceOf;
    mapping(address => mapping(address => uint256)) _allowanceOf;
    uint256 _totalSupply;
}