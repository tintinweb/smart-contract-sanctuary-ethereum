/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 ;

contract Sand {

    uint liczba = 0 ;

    function returnSender() public view returns(address) {
        return msg.sender;
    }

    function returnLiczba() public view returns(uint) {
        return liczba;
    }

    function incrementLiczba() public {
        liczba += 1;
    }

}