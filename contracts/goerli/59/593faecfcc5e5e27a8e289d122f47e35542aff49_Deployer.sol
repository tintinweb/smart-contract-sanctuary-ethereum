/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Deployed {
    constructor() payable {}
    function kill() external {
        selfdestruct(payable(address(this)));
    }
}

contract Deployer {
    address public addr;
    bytes32 public constant _salt = 0xba562df0bb22df42d725bad49f1bee2e0d6e98c1becce1ad5bcf138859a87702;
    function deploy() payable external {
        addr = address(new Deployed{value:msg.value, salt: _salt}());
    }
}