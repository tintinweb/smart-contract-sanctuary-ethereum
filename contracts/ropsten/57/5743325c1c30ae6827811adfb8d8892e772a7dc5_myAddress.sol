/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    contract myAddress {
        function getAddress() public view returns(address) {
            return address(this);
            
        }
    }