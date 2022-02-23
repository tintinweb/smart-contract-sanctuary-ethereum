// SPDX-License-Identifier: Unlisenced

pragma solidity ^0.8.0;

interface Target {
    function devMint(uint256) external payable;
}

contract Interaction 
{
    function getCount() external payable{
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
    }
}