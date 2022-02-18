/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract Message{
    string data;

    function getter() external view returns (string memory) {
        return data;
    }

    function setter(string memory data_) external {
        data = data_;
    }
}