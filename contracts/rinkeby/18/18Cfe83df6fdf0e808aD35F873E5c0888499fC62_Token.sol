/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 _wei; // 1 Ether = 1000000000000000000 Wei
    address payable public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        _wei = 1000000000000000000;
        totalSupply = _initialSupply * _wei;

        owner = payable(msg.sender);

        balanceOf[owner] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function mint(uint256 _amount) public returns (bool success) {
        require(msg.sender == owner, "Operation unauthorised");

        totalSupply += (_amount * _wei);
        balanceOf[msg.sender] += (_amount * _wei);

        emit Transfer(address(0), msg.sender, _amount * _wei);
        return true;
    }

    function burn(uint256 _amount) public returns (bool success) {
        require(msg.sender != address(0), "Invalid burn recipient");
        require(totalSupply > _amount, "Burn amount exceeds balance");

        totalSupply -= (_amount * _wei);
        balanceOf[msg.sender] -= (_amount * _wei);

        emit Transfer(msg.sender, address(0), _amount * _wei);
        return true;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(_to != address(0), "Receiver address invalid");
        require(_value >= 0, "Value must be greater or equal to 0");
        require(balanceOf[msg.sender] > _value, "Not enough balance");

        balanceOf[msg.sender] -= (_value * _wei);
        balanceOf[_to] += (_value * _wei);

        emit Transfer(msg.sender, _to, _value * _wei);
        return true;
    }

    // TODO: stake
    // function stake(uint256 _amount) public returns (bool success) {
    //     return true;
    // }
}