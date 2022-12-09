/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

contract TransferContract {

    address public alice;
    address public bob;
    uint256 public unfreezeTime;

    modifier onlyAlice(){
        require(msg.sender == alice);
        _;
    }

    modifier onlyBob(){
        require(msg.sender == bob);
        _;
    }

    constructor (address _alice, address _bob) {
        alice = _alice;
        bob = _bob;
    }

    function deposit() public payable onlyAlice {
        require(unfreezeTime == 0);
        require(msg.value > 0);
        unfreezeTime = block.timestamp + 1 days;
    }

    function withdraw() public payable onlyBob {
        require(block.timestamp >= unfreezeTime);
        unfreezeTime = 0;
        payable(bob).send(address(this).balance);
    }

}