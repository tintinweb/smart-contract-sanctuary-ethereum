/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract testVerify {

    uint private counter;

    function incCounter() public {
        counter++;
    }

    function getCounter() public view returns(uint) {
        return counter;
    }
}