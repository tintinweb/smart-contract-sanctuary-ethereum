/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

struct HashStampInfo {
    uint blockEth;
    uint timestamp;
}

contract TSAContract {
    address private Owner;
    uint256 private _currentID;

    error NotOwner(address owner, address caller);

    constructor() {
        _currentID = 0;
        Owner = msg.sender;
    }

    function isOwner(address caller) private view returns (bool) {
        return caller == Owner;
    }

    function StampHash(bytes32 hash) public {
        bool test = isOwner(msg.sender);
  
        if(!test) {
            revert NotOwner({
                owner: Owner,
                caller: msg.sender
            });
        }
        _currentID = hash.length;
    }

   
}