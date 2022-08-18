/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

/*
Che y si escribimos en OP_RETURN la fundación de 0xNonce?
*/

contract nonce {

    address public owner;
    constructor () {
        owner = msg.sender;
    }

    struct Record {
        uint256 createdAt;
        string abstract_;
    }
    Record [] public records;


    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }

    function createRecord(string memory _abstract_) public {
        records.push (Record(
            block.timestamp,
            _abstract_
        ));
    }



}