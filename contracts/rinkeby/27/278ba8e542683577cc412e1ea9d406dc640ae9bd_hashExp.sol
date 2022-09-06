/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract hashExp 
{
    function hashReturn(string memory _string1, string memory _string2, uint amount, address receiver) public pure returns(bytes32)
    {
        return keccak256(abi.encode(_string1, _string2, amount, receiver));
    }
    
    
}