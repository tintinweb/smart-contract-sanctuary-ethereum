/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract GoritZalupa {
    string public constant name = "GoritZalupa";
    string public constant symbol = "GZP";
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1000000000 * 10**uint256(decimals);
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        uint256 burnAmount = _value / 1000; // 0.1% of the transfer amount
        balances[msg.sender] -= _value;
        balances[_to] += _value - burnAmount;
        balances[burnAddress] += burnAmount;
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, burnAddress, burnAmount);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        uint256 burnAmount = _value / 1000; // 0.1% of the transfer amount
        balances[_from] -= _value;
        balances[_to] += _value - burnAmount;
        balances[burnAddress] += burnAmount;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, burnAddress, burnAmount);
        return true;
    }
    
    function tryLuck() public returns (bool success) {
        uint256 amountToSend = 10000;
        require(balances[msg.sender] >= amountToSend, "Insufficient balance");
        balances[msg.sender] -= amountToSend;
        uint256 amountToReceive = getRandomAmount();
        if (amountToReceive < 50000) {
            // Burn the remaining tokens if the amount received is less than 50,000
            uint256 amountToBurn = amountToReceive;
            //totalSupply -= amountToBurn;
            emit Transfer(msg.sender, burnAddress, amountToBurn);
        }
        else {
            balances[msg.sender] += amountToReceive;
            emit Transfer(address(0), msg.sender, amountToSend);
            emit Transfer(address(this), msg.sender, amountToReceive);
        }
        return true;
    }

    function getRandomAmount() private view returns (uint256) {
        // Generate a random number between 0 and 100,000
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100000;
        return random;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}