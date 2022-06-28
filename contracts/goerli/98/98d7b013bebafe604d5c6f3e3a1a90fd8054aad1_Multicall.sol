/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.7.6;
pragma abicoder v2;

contract Multicall {
    constructor(address _target){
        target = _target;
    }
    address target;
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory ret) =
                target.call(abi.encode(data[i]));
            if (success) {
                results[i] = ret;
            }
        }
    }
}