/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DummyPlatform {
    /// >>>>>>>>>>>>>>>>>>>>>>>    EVENTS    <<<<<<<<<<<<<<<<<<<<<< ///

    event ContractDeployed(address contractAddress);

    /// >>>>>>>>>>>>>>>>>>>>>>     STATE     <<<<<<<<<<<<<<<<<<<<<< ///

    uint private nonce;

    /// >>>>>>>>>>>>>>>>>>>>>>   EXTERNAL    <<<<<<<<<<<<<<<<<<<<<< ///

    function deployContract(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address owner
    ) external {
        address randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce, blockhash(block.number))))));
        nonce++;
        emit ContractDeployed(randomish);
    }
}