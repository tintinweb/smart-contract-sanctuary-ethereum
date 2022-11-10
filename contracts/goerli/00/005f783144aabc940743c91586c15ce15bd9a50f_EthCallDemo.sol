/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity  ^0.8.14;

contract EthCallDemo{
function ethCall(address[] memory arg_list) external view returns (
    address contract_addr,
    uint256 timestamp ,
    address[] memory ret_list
) {
    ret_list = new address[](arg_list.length);
    for (uint256 i = 0; i <= arg_list.length; i++) {
        ret_list[i] = arg_list[i];
    }

    contract_addr = address(this);
    timestamp = block.timestamp;
}

}