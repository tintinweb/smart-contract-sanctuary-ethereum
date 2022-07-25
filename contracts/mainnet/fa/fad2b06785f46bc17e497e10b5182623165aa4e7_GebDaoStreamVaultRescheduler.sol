/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity ^0.6.7;

abstract contract TokenLike {
    function balanceOf(address) public virtual view returns (uint256);
}

abstract contract StreamVaultLike {
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external virtual;
    function cancelStream() external virtual;
}

contract GebDaoStreamVaultRescheduler {

    // @notice Cancels current stream and creates a new stream with all tokens available in the streamVault
    function reschedule(address target, address recipient, address tokenAddress, uint256 startTime, uint256 stopTime) external {
        // cancel previous stream
        StreamVaultLike(target).cancelStream();

        // rounding the value for Sablier
        uint256 balance = TokenLike(tokenAddress).balanceOf(target);
        uint256 deposit = balance - (balance % (stopTime - startTime));

        // create new stream
        StreamVaultLike(target).createStream(recipient, deposit, tokenAddress, startTime, stopTime);
    }
}