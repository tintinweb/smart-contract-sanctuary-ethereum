/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

contract Lock {
    uint256 public lockedUntil = 0;
    address private lockOwner;

    modifier onlyOwner() {
        require(msg.sender == lockOwner, "owner");
        _;
    }
    
    constructor() {
        lockOwner = msg.sender;
    }
    
    function lock(uint256 amount, uint256 until) public onlyOwner {
        payable(this).transfer(amount);
        lockedUntil = until;
    }
    
    function unlock(uint256 amount) public {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {
    }
}