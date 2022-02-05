/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: MIT 

pragma solidity 0.8.11;

contract GASTEST {
    uint256 public lastBaseFee;
    uint256 public lastGasPrice;
    uint256 public lastRemainingGas;
    uint256 public lastBlockNum;
    uint256 public lastBlockTime;

    constructor()  {}

    function currentBlockTime() external view returns (uint256) {
        return block.timestamp;
    }

    function currentBlockNum() external view returns (uint256) {
        return block.timestamp;
    }

    function setValues(uint16 gasBonus) external {
        require(tx.gasprice < block.basefee + gasBonus, "Gas price too high");
        lastBaseFee = block.basefee;
        lastGasPrice = tx.gasprice;
        lastRemainingGas = gasleft();
        lastBlockNum = block.number;
        lastBlockTime = block.timestamp;
    }
}