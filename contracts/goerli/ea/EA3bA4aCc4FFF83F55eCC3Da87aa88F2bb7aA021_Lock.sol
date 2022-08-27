// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.9;

// Import this file to use console.log
//import "hardhat/console.sol";

/// @title A timelock for funds
/// @notice This contract can be used to protect funds for a certain period of time
/// @dev Whoever constructs this contract will become the owner and only they can withdraw
/// @custom:gui This could be shown as a time lock in a UI
contract Lock {
    uint256 public unlockTime;
    address payable public owner;

    event Withdrawal(uint256 amount, uint256 when);

    /// @notice This is a `payable` constructor and should be sent a value which will be locked
    /// @param _unlockTime is the epoch (in seconds) that the funds will be unlocked
    // slither-disable-next-line timestamp
    constructor(uint256 _unlockTime) payable {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < _unlockTime, "Unlock time is in the past");

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    /// @notice Will withdraw the user funds if the proper amount of time has passed
    /// @dev The block timestamp is used here, but this is okay in this context
    // slither-disable-next-line timestamp
    function withdraw() external {
        // Uncomment this line to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        // solhint-disable-next-line not-rely-on-time
        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}