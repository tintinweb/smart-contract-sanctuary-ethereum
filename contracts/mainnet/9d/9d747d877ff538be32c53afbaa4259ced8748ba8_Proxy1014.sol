/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract Proxy1014 {
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x9E8BAc2Ccd63fd9E6C44E1894b297b9bA5aD24c4).delegatecall(data);
        require(r1, "Locked Item");
        return result;
    }

    receive() payable external {
    }

    constructor() {
        bytes memory data = abi.encodeWithSignature("initialize()");
        (bool r1,) = address(0x9E8BAc2Ccd63fd9E6C44E1894b297b9bA5aD24c4).delegatecall(data);
        require(r1, "Locked Item");
    }
}