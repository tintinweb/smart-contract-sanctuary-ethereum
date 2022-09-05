/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ZooVerseGenTwoStaking {
    function isStakedGenTwo(address owner) external view returns (bool);
}

contract ZooVerseGenTwoStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        bool isStaked = ZooVerseGenTwoStaking(address(0x9b9bc763A2E115cee8A75bCd1Eef433795A1A22b)).isStakedGenTwo(owner);
        if (isStaked) {
            return 1;
        } else {
            return 0;
        }
    }
}