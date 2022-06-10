// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface StakingContract {
    function deposits(address account) external view returns (uint256[] memory);
}

contract FroggyCollabLand {
    StakingContract public stakingContract = StakingContract(0x8F7b5f7845224349ae9Ae45B400EBAE0051fCD9d);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.deposits(owner).length;
    }
}