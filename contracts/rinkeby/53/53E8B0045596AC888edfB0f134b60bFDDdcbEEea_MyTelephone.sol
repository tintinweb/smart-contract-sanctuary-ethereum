/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract MyTelephone {
    Telephone mt = Telephone(0xd9145CCE52D386f254917e481eB44e9943F39138);

    address public _a;
    address public _b;

    function changeTelephoneOwner() public {
        mt.changeOwner(0xd9145CCE52D386f254917e481eB44e9943F39138);
    }
}