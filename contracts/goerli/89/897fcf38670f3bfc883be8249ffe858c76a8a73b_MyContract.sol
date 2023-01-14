/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract MyContract {

mapping (address => uint) public addyBalances;
    constructor() {
        addyBalances[msg.sender] = 100;
    }
        function sendMoney(address payable _to, uint _amount) public {
            require(addyBalances[msg.sender] >= _amount, "Insufficient Balance");
            addyBalances[msg.sender] -= _amount;
            addyBalances[_to] += _amount;
        }

        function someCrypticFunction(address _addy) public view returns(uint) {
            return addyBalances[_addy];
        }
    }