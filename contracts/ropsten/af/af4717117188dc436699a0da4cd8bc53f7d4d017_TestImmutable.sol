/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.8.7;

contract TestImmutable {

    uint256 immutable ImmutableTest;

    constructor(uint256 theImmutable) {
        ImmutableTest = theImmutable;
    }
}