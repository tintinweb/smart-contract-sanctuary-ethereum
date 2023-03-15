/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//call function
//we are going to create another write function and include the contract address parameter
// for the contract A and include the parameter we want to change
//we use this call function on a write function
//the state of this contarct B does not change
contract B {
    bytes public data;
    function thecarB (address contractAaddress, string memory _car) external {
     (bool success, bytes memory _data) = contractAaddress.call(abi.encodeWithSignature("thecarA(string)", _car));
    data = _data;
    require (success, "transaction failed");
    }
}