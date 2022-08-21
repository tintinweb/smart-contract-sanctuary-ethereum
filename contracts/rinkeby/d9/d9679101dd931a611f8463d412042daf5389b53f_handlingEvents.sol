/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



contract handlingEvents {

   event addresses(
    address indexed one,
    address indexed two, 
    address indexed three,
    address indexed four
    )anonymous;

    function emitEvent() public  {
        emit addresses(
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
            0x617F2E2fD72FD9D5503197092aC168c91465E7f2

        );
    }

}