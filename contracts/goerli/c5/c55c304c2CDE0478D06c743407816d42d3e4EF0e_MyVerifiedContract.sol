/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-Licence-Identifier : MIT

pragma solidity 0.8.16;


contract MyVerifiedContract {
    mapping (address => uint ) addressBalances;
    address public owner;

    constructor() {
        addressBalances[msg.sender] = 100;
        owner = msg.sender;
    }

    function transfer (address _to, uint _amount) public {
        addressBalances[msg.sender] -= _amount;
        addressBalances[_to] += _amount;
    }

    function aRandomFunctionNamedXYZ() public {
        addressBalances[msg.sender] = 10;
    }
}