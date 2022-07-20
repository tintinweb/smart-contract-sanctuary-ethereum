/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Trace {

    struct Relationship {
        address buyer;
        address supplier;
        string parts;
    }
    Relationship[] public traceDB;
    uint public count;

    function store(address  _supplier,  string memory _parts) public {
        traceDB.push(Relationship(tx.origin,_supplier,_parts));
        count += 1;
    }

}