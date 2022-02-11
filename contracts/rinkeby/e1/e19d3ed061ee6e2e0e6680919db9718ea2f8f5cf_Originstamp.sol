/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: UNLICENSED
// File: contracts/Originstamp.sol



pragma solidity ^0.8.7;

contract Originstamp {
    address public owner;
    mapping(bytes32 => bytes32) public docHashTx;
    mapping(bytes32 => uint256) public docHashTime;
    mapping(bytes32 => bytes32) public newVersions;

    event Registered(bytes32 indexed docHash);
    event NewVersionRegistered(bytes32 indexed docHash, bytes32 indexed expiredDocHash);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register(bytes32 _docHash) public onlyOwner() {
        docHashTime[_docHash] = block.timestamp;
        emit Registered(_docHash);
    }

    function register(bytes32 _docHash, bytes32 _expiredDocHash) public onlyOwner() {
        docHashTime[_docHash] = block.timestamp;
        newVersions[_expiredDocHash] = _docHash;
        emit NewVersionRegistered(_docHash, _expiredDocHash);
    }

    function setTransactionHash(bytes32 _docHash, bytes32 _txHash)  public onlyOwner() {
        docHashTx[_docHash] = _txHash;
    }
}