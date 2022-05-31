/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EtherBucket {
    mapping(address => uint) deposits;

    receive() external payable {
        deposits[msg.sender] += msg.value;
    }

    bool lock;
    modifier mutex {
        require(lock == false);
        lock = true;
        _;
        lock = false;
    }
    
    event EtherWithdrawal(uint _numberOfEther);

    function withdraw(uint _amount) external mutex {
        (bool success,) = msg.sender.call{ value: _amount }("");
        require(success);

        uint numEther = _amount / 1 ether;
        emit EtherWithdrawal(numEther);
        deposits[msg.sender] -= numEther * 1 ether;
    }
}