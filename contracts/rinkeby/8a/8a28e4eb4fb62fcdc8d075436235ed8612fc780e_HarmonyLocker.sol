/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// File: MockBridge.sol


pragma solidity 0.8.13;

contract HarmonyLocker {
    uint256 id;

    event Locked(
        address indexed src,
        address indexed dest,
        uint256 indexed id,
        uint256 timestamp,
        uint256 cheeseLocked,
        uint256 miceLocked,
        uint256 catsLocked,
        uint256 trapsLocked,
        uint256 passesLocked
    );

    function bridge(
        address dest,
        uint256 cheeseLocked,
        uint256 miceLocked,
        uint256 catsLocked,
        uint256 trapsLocked,
        uint256 passesLocked
    ) external {
        emit Locked(
            msg.sender,
            dest,
            id++,
            block.timestamp,
            cheeseLocked,
            miceLocked,
            catsLocked,
            trapsLocked,
            passesLocked
        );
    }
}