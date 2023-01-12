/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleToken {
    address public minter;
    mapping(address => uint) public getBalance;
    uint public totalSupply;

    constructor() public {
        minter = msg.sender;
    }

    function mint(address _to, uint _amount) external {
        require ( minter == msg.sender, "Can't call mint" );
        getBalance[_to] += _amount;
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require ( getBalance[msg.sender] - _value >= 0, "Not enough balance to transfer" );
        getBalance[msg.sender] -= _value;
        getBalance[_to] += _value;
        return true;
    }
    
}