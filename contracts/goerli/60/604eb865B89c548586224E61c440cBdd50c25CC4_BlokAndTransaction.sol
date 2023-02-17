/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract BlokAndTransaction {

    uint256 public x;
    uint256 public y;

    // базовая стоимость газа в блоке
    uint256 public basefee;
    // id сети
    uint256 public chainid;
    // сложность блока
    uint256 public difficulty;
    // лимит газа в блоке
    uint256 public gaslimit;
    // номер блока
    uint256 public number;
    // временная метка блока
    uint256 public timestamp;
    // адрес валидатора, создавшего блок
    address public coinbase;

    // хеш блока
    bytes32 public blockHash;

    // адрес источника транзакции
    address public origin;

    function getBlock()public{
        basefee = block.basefee;
        chainid = block.chainid;
        difficulty = block.difficulty;
        gaslimit = block.gaslimit;
        number = block.number;
        timestamp = block.timestamp;
        coinbase = block.coinbase;
        blockHash = blockhash(block.number - 1);
    }

    function getTransaction()public {
        origin = tx.origin;
    }

    function setNumbers(uint256 _x, uint256 _y)public returns(uint256, uint256, uint256){
        uint256 gas1 = gasleft();
        x = _x;
        uint256 gas2 = gasleft();
        y = _y;
        uint256 gas3 = gasleft();
        return (gas1, gas2, gas3);
    }

    function func() public {}
}