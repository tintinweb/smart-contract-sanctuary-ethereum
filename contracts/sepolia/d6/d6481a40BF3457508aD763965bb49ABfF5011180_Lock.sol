// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

error CannotWithdrawYet();
error NotOwner();
error CouldNotSend();
error NotFutureUnlockTime();

contract Lock {
    uint256 public immutable i_unlockTime;
    address payable public immutable i_owner;

    event Withdrawal(
        uint256 amount, 
        uint256 when
    );

    constructor(uint256 _unlockTime) payable {
        if(block.timestamp >= _unlockTime)
            revert NotFutureUnlockTime();

        i_unlockTime = _unlockTime;
        i_owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        if(block.timestamp < i_unlockTime)
            revert CannotWithdrawYet();
        if(msg.sender!=i_owner)
            revert NotOwner();

        emit Withdrawal(address(this).balance, block.timestamp);

        //i_owner.transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if(!success)
            revert CouldNotSend();
    }

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getUnlockTime() public view returns(uint256) {
        return i_unlockTime;
    }
}