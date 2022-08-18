/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract GlobalVariables {
    function blockVariables() external view returns(uint, uint, uint, bytes32, address, uint, uint, uint) {
        uint _chainid = block.chainid;
        uint _number = block.number;
        uint _difficulty = block.difficulty;
        bytes32 _blockhash = blockhash(_number);
        address _coinbase = block.coinbase;
        uint _gaslimit = block.gaslimit;
        uint _basefee = block.basefee;
        uint _timestamp = block.timestamp;
        return (_chainid, _number, _difficulty, _blockhash, _coinbase, _gaslimit, _basefee, _timestamp);
    }

    function transactionVariables() public view returns(bytes memory, bytes4, uint256, uint256, address, uint, address) {
        bytes memory _data = msg.data;
        bytes4 _sig = msg.sig;
        uint256 _gasleft = gasleft();
        uint256 _value = 1;
        address _sender = msg.sender;
        uint _gasprice = tx.gasprice;
        address _origin = tx.origin;
        return (_data, _sig, _gasleft, _value, _sender, _gasprice, _origin);
    }
}