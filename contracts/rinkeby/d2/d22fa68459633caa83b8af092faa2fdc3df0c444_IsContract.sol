/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract IsContract {
    function isContract(address addr) public view returns(bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size != 0;
    }
}