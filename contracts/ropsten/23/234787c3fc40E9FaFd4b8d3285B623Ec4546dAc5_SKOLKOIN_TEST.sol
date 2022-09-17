/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.0;
 
contract SKOLKOIN_TEST
{
    string public constant name = "SkolCoin";
    string public constant symbol = "SKOT";
    uint8 public constant decimals = 3;
    uint public totalSupply = 0;
    mapping(address => uint) internal balances;

    address internal owner;
    mapping(address => mapping(address => uint)) internal allowed;

    event Transfer(address from, address to, uint value);
    event Approval(address from, address to, uint value);

    constructor() {
        owner = msg.sender;
    }

    function mint(address to, uint how) public {
        require(msg.sender == owner, "Not IGC owner");

        totalSupply += how;
        balances[to] += how;
    }

    function balanceOf(address hwo) public view returns(uint) {
        return balances[hwo];
    }

    function balanceOf() public view returns(uint) {
        return balances[msg.sender];
    }

    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value, "NO such more money");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public {
        require(allowance(_from, _to) >= _value, "You cant");
        require(balances[_from] >= _value, "NO such more money");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][_to] -= _value;

        emit Approval(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] += _value;

        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _from, address _spender) public view returns(uint) {
        return allowed[_from][_spender];
    }
}