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
        StakingContract(0x8D8A3e7EAdA138523c2dcB78FDbbF51A63A3faAD);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.depositsOf(owner).length;
    }
}