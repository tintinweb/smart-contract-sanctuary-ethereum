// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface StakingContract {
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory);
}

contract CollabFaker {
    StakingContract public stakingContract =
        StakingContract(0x401cEe9353466B3d249701c3EBCBf26452EE61b5);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.depositsOf(owner).length;
    }
}