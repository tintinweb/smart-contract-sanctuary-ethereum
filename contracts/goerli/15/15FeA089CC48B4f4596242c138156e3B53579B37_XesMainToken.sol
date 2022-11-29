// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./helpers/SafeMath.sol";
import "./interfaces/ERC20.sol";

contract StandardToken is ERC20, SafeMath {
    mapping(address => uint) balances; // solhint-disable-line
    mapping(address => mapping(address => uint)) allowed; // solhint-disable-line

    function transfer(address _to, uint _value) public returns (bool success) {// solhint-disable-line
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}


contract XesMainToken is StandardToken {
    string public name = "Proxeus";
    string public symbol = "XES";
    uint public decimals = 18;
    uint public totalSupply = 300 * 1000 * 1000 ether;

    constructor() {
        balances[msg.sender] = totalSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address toAddress, uint value) external returns (bool ok);
    function transferFrom(address fromAddress, address toAddress, uint value) external returns (bool ok);
    function approve(address spender, uint value) external returns (bool ok);
    event Transfer(address indexed fromAddress, address indexed toAddress, uint value); // solhint-disable-line
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SafeMath {
    function safeSub(uint a, uint b) pure internal returns (uint) { // solhint-disable-line
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) { // solhint-disable-line
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}