/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;

contract SkytradeToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address payable public owner;
    address public presaleWallet;
    address public icoWallet;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address _presaleWallet,
        address _icoWallet
    ) {
        owner = payable(msg.sender);
        presaleWallet = _presaleWallet;
        icoWallet = _icoWallet;
        name = "Skytrade Token";
        symbol = "SKT";
        decimals = 18;
        totalSupply = 1000000 * 10**uint256(decimals);
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function setIcoWallet(address _icoWallet) public {
        require(msg.sender == owner, "Only contract owner can set ico wallet");
        require(_icoWallet != address(0), "Invalid ico wallet address");
        icoWallet = _icoWallet;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient address");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowed[_from][msg.sender] >= _value, "Not allowed to transfer this amount");
        require(_to != address(0), "Invalid recipient address");
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}