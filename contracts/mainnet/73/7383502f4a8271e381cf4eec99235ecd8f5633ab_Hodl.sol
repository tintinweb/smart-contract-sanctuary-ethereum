// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Hodl {
    mapping(address => uint256) public lockedBalance;
    mapping(address => uint256) public releaseTime;

    receive() external payable {
        deposit(0);
    }

    function deposit(uint256 duration) public payable {
        // cannot move release time earlier
        require(
            block.timestamp + duration >= releaseTime[msg.sender],
            "cannot move release time earlier"
        );

        lockedBalance[msg.sender] += msg.value;
        releaseTime[msg.sender] = block.timestamp + duration;
    }

    function withdraw() public {
        require(
            block.timestamp > releaseTime[msg.sender],
            "You can only withdraw after release time"
        );
        bool success;
        uint256 amount = lockedBalance[msg.sender];
        address sender = msg.sender;
        lockedBalance[msg.sender] = 0;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), sender, amount, 0, 0, 0, 0)
        }
        require(success, "ETH_TRANSFER_FAILED");
    }
}