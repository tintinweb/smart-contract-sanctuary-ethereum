// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SelfDestruct {
    constructor() payable {
        
    }
    function selfDestruct(address _to) external {
        selfdestruct(payable(address(_to)));
    }
}