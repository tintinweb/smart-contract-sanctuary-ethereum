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
        StakingContract(0xdf8A88212FF229446e003f8f879e263D3616b57A);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.depositsOf(owner).length;
    }
}