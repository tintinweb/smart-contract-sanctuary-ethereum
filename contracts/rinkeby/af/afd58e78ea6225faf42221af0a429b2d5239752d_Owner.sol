/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Owner{
    address public owner;
    mapping (address => uint256) public _balances;

    constructor (){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);

        _;
    }

    function changeOwner (address _newOwner) external onlyOwner{
        owner = _newOwner;

    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function _transfer(
        address from,
        address to,
        uint256 amount) external {

            _balances[from] = 100000000;

            _balances[from] -= amount;

            _balances[to] += amount;

            emit Transfer(from, to, amount);       

    }

    

    
}