// SPDX-License-Identifier: MIT

/* solidity version -> ^ means this version and above */
pragma solidity ^0.8.15;

contract Contract {
    
    /* constant -> cannot be changed once initialized */
    /* constant's names are usually in caps and different words are separated by an underscore */
    address constant METAMASK_ADDRESS = 0xf421a01557dcA643E724aba1F08a575aE4Cd6790;
    
    /* immutable -> can be set only in the constructor */
    /* immutable's names usually begin with "i_" */
    address immutable i_owner;

    /* constructor is called when the contract is being deployed */
    constructor() {
        i_owner = msg.sender;
    }

    /* receive() is executed when an address tries to send ETH without calling a function */
    /* payable -> allows function to receive ETH when called */
    receive() external payable {
    }

    /* fallback() is executed when is called a function that doesn't match with any of those available in the contract */
    /* payable is optional */
    fallback() external payable {
    }

    /* pure -> variables will not be changed, saved or read */
    /* view -> variables will not be changed or saved but only read */
    function getOwner() public view returns (address) {
        return i_owner;
    }

}