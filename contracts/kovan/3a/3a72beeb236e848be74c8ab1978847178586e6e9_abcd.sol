/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
interface testmsg{
    function check() external view returns (address);
}

contract abcd {
    function check() external view returns (address) {
        return msg.sender;
    }
}