/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Global {
    function readBlockHash(uint blockNumber) public view returns (bytes32) {
        return blockhash(blockNumber);
    }

    function readBlockVariables() public view returns (
        uint, uint, address payable, uint, uint, uint, uint) {
        return (
            block.basefee,
            block.chainid,
            block.coinbase,
            block.difficulty,
            block.gaslimit,
            block.number,
            block.timestamp
        );
    }

    function readBlockNumber() public view returns (uint) {
        return block.number;
    }

    function readGasLeft() public view returns (uint) {
        return gasleft();
    }

    function readMsgVariables() public payable returns (
        bytes calldata, address, bytes4, uint) {
        return (
            msg.data,
            msg.sender,
            msg.sig,
            msg.value
        );
    }

    function readTxVariables() public view returns (uint, address) {
        return (
            tx.gasprice,
            tx.origin
        );
    }
}