/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.17;

//Just a test token for the unit test's
contract TestToken {

    mapping(address => uint256) balances;

    function createTokens(uint256 _amount) public {
        balances[msg.sender] = _amount;
    }

    function buyTokens(uint256 _amount) external payable {
        balances[msg.sender] = _amount;
    }

    function balance(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

}