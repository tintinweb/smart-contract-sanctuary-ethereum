/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// File: contracts/Minter.sol

pragma solidity ^0.8.0;

contract FakeMint {
    event Minted(uint256 counter, address recipient);

    uint256 counter = 0;

    function mintNFT(address recipient) public returns (uint256) {
        require(block.timestamp % 1200 >= 600, "Mint not active");

        counter += 1;

        emit Minted(counter, recipient);

        return counter;
    }
}