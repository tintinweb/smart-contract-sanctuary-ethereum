/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

//SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

contract MDumb {

    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
    bytes32 _hash, 
    bytes memory _signature)
    public
    view 
    returns (bytes4 magicValue) {
        return MAGICVALUE;
    }
}