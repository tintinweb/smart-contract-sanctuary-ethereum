/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Token__InsufficientBalance();
error Token__TransferringZeroAddress();
error Token__ApprovingZeroAddress();
error Token__InsufficientAllowance();

contract Token {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(
        address indexed from, 
        address indexed to, 
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
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balance[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        if (balance[msg.sender] < _value) {
            revert Token__InsufficientBalance();
        }
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        if (_spender == address(0)) {
            revert Token__ApprovingZeroAddress();
        }
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 currentAllowance = allowance[_from][msg.sender];
        if (balance[_from] < _value) {
            revert Token__InsufficientBalance();
        }
        if (currentAllowance < _value) {
            revert Token__InsufficientAllowance();
        }
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        if (_to == address(0)) {
            revert Token__TransferringZeroAddress();
        }
        balance[_from] -= _value;
        balance[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}