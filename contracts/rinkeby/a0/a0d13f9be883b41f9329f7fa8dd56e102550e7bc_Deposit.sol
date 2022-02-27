/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Deposit{

    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function transfer(address payable addr) public {
        if(msg.sender == owner) {
            addr.transfer(getBalance());
        }
    }
}

// Consider the solution from the previous challenge.

// Add a new immutable state variable called admin and initialize it with the address
// of the account that deploys the contract;

// Add a restriction so that only the admin can transfer the balance of the contract to another address;

// Deploy and test the contract on Rinkeby Testnet.

// contract Deposit{

//     receive() external payable {
//     }

//     function getBalance() public view returns(uint) {
//         return address(this).balance;
//     }
//     function transfer(address payable addr) public {
//         uint balance = getBalance();
//         addr.transfer(balance);
//     }
    
// }