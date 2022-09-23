/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;


contract Caller {
    function someUnsafeAction(address addr, uint256 nonce) public {
            bytes memory payload = abi.encodeWithSignature("cancelERC1155Order(uint256)", nonce);
            (bool success, bytes memory returnData) = address(addr).call(payload);
            require(success);
        }

}