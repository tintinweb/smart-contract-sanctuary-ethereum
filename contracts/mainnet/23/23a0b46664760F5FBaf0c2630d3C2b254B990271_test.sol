// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test {

    bool enabled = false;
    
    function init() public {
        enabled = !enabled;
    } 

    function pseudo_mint() public payable {
        require(enabled, "Mint is not live");
    }

}