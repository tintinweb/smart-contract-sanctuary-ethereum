/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract ABITest {
    function enc(uint param1, address addr, string memory param2) external pure returns (bytes memory){
        return abi.encode(param1,addr,param2);
    }
    function dec(bytes calldata data) external pure returns (uint param1, address addr, string memory param2){
        (param1,addr,param2) = abi.decode(data, (uint,address,string));
    }
}