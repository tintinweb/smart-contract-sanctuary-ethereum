/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// File: contracts/Token.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract Token {

    // private means only the contract can call the variable, name is the variable

    string private _name;

    string private _symbol;

    uint8 private _decimals = 18;

    uint private _totalSupply;



    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    

    constructor(string memory name_, string memory symbol_) {

        _name = name_;

        _symbol = symbol_;

        // msg.sender = the address of who called the function to be executed

        _totalSupply = 1000000 * (10 ** _decimals);

        _balances[msg.sender] = _totalSupply;

    }

    

    function name() public view returns (string memory) {

        return _name;

    }



    function symbol() public view returns (string memory) {

        return _symbol;

    }

    

    function decimals() public view returns (uint8) {

        return _decimals;

    }



    function totalSupply() public view returns (uint) {

        return _totalSupply;

    }



    function balanceOf(address _owner) external view returns (uint) {

        return _balances[_owner];

    }



    function _transfer(address _from, address _to, uint _value) internal {

        // Makes sure the recipient is valid

        require(_to != address(0));

        // Subtract senders balance

        _balances[_from] -= _value; 

        /*

            ^^ means the same thing as 👇🏾`

            _balances[_from] = _balances[_from] - _value; 

         */

        // Add _value of the _to

        _balances[_to] += _value;

        // Call event

        emit Transfer(_from, _to, _value);

    }



    function transfer(address _to, uint _value) public returns (bool) {

        // Makes sure deployer only sends what they have

        require(_balances[msg.sender] >= _value);

        _transfer(msg.sender, _to, _value);

        return true;

    }



    function transferFrom(address _from, address _to, uint _value) public returns (bool){

        require(_value <= _balances[_from]);

        require(_value <= _allowance[_from][msg.sender]);

        _allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }



    function approve(address _spender, uint _value) public returns (bool) {

        require(_spender != address(0));

        _allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }



    function allowance(address _owner, address _spender) public view returns (uint) {

        return _allowance[_owner][_spender];

    }

}