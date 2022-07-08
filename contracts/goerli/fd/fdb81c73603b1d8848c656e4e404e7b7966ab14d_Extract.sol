/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Extract {

    address payable wallet;
    constructor (address payable w) payable {
        wallet = w;
    }

    function extract() public {
        wallet.transfer(address(this).balance);
    }
}