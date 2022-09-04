/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// Sources flattened with hardhat v2.11.0 https://hardhat.org

// File contracts/Torbellino.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Torbellino {

    mapping(uint => uint) private ordenBook;

    constructor() payable {
    }

    function setDeposit(uint _memo) public payable {
        require(ordenBook[_memo] == 0, "Memo is not valid");
        ordenBook[_memo] = msg.value;
    }

    function setWithdraw(address payable _to, uint _memo) public {
        require(ordenBook[_memo] > 0, "Memo doesn't exists");
 
        uint amount = ordenBook[_memo];
        (bool success, ) = _to.call{value: amount}("");

        require(success, "Failed Withdraw");
    }

    function getTotalBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getMemoBalance(uint _memo) public view returns (uint) {
        require(ordenBook[_memo] > 0, "Memo doesn't exists");
        return ordenBook[_memo];
    }

    function getMemo() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender)));
    }

}