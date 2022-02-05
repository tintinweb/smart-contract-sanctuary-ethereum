/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract materialBalance {
    mapping(address => uint256) public material1;
    mapping(address => uint256) public material2;
    mapping(address => uint256) public material3;
    mapping(address => uint256) public material4;

    // Add materials
    function addMaterial1(address userAddress, uint256 _amountToAdd) public {
        material1[userAddress] = material1[userAddress] + _amountToAdd;
    }

    function addMaterial2(address userAddress, uint256 _amountToAdd) public {
        material2[userAddress] = material1[userAddress] + _amountToAdd;
    }

    function addMaterial3(address userAddress, uint256 _amountToAdd) public {
        material3[userAddress] = material1[userAddress] + _amountToAdd;
    }

    function addMaterial4(address userAddress, uint256 _amountToAdd) public {
        material4[userAddress] = material1[userAddress] + _amountToAdd;
    }

    // Spend materials
    function spendMaterial1(address userAddress, uint256 _amountToSpend) public {
        material1[userAddress] = material1[userAddress] - _amountToSpend;
    }

    function spendMaterial2(address userAddress, uint256 _amountToSpend) public {
        material2[userAddress] = material1[userAddress] - _amountToSpend;
    }

    function spendMaterial3(address userAddress, uint256 _amountToSpend) public {
        material3[userAddress] = material1[userAddress] - _amountToSpend;
    }

    function spendMaterial4(address userAddress, uint256 _amountToSpend) public {
        material4[userAddress] = material1[userAddress] - _amountToSpend;
    }

}