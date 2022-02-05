/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: MIT 

pragma solidity 0.8.11;

contract GASTEST3 {
    uint256 public lastMaxGasPrice;
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

    function _setVals(uint16 gasBonusGwei) internal {
        lastMaxGasPrice = block.basefee + (gasBonusGwei * 10**9);
        lastBaseFee = block.basefee;
        lastGasPrice = tx.gasprice;
        lastRemainingGas = gasleft();
        lastBlockNum = block.number;
        lastBlockTime = block.timestamp;
    }
    function setValsConditional(uint16 gasBonusGwei) external {
        require(tx.gasprice < block.basefee + (gasBonusGwei * 10**9), "Gas price too high");
        _setVals(gasBonusGwei);
    }

    function setValsNoConditions(uint16 gasBonusGwei) external {
        _setVals(gasBonusGwei);
    }
}