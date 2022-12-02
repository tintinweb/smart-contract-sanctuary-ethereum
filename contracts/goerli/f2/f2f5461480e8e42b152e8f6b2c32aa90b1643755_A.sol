/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


contract A {
    uint public a=2;

    function aa(uint _a, uint _b) public pure returns(uint) {
        return _a+_b;
    }

    function bb(uint _a) public view returns(uint) {
        return _a+a;
    }

    function cc(uint _a) public returns(uint) {
        a = a+_a;
        return a;
    }


}

// // [
// 	{
// 		"inputs": [],
// 		"name": "a",
// 		"outputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "",
// 				"type": "uint256"
// 			}
// 		],
// 		"stateMutability": "view",
// 		"type": "function"
// 	},
// 	{
// 		"inputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "_a",
// 				"type": "uint256"
// 			},
// 			{
// 				"internalType": "uint256",
// 				"name": "_b",
// 				"type": "uint256"
// 			}
// 		],
// 		"name": "aa",
// 		"outputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "",
// 				"type": "uint256"
// 			}
// 		],
// 		"stateMutability": "pure",
// 		"type": "function"
// 	},
// 	{
// 		"inputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "_a",
// 				"type": "uint256"
// 			}
// 		],
// 		"name": "bb",
// 		"outputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "",
// 				"type": "uint256"
// 			}
// 		],
// 		"stateMutability": "view",
// 		"type": "function"
// 	},
// 	{
// 		"inputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "_a",
// 				"type": "uint256"
// 			}
// 		],
// 		"name": "cc",
// 		"outputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "",
// 				"type": "uint256"
// 			}
// 		],
// 		"stateMutability": "nonpayable",
// 		"type": "function"
// 	}
// ]