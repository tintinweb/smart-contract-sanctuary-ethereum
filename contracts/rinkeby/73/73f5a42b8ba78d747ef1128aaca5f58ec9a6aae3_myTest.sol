/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
contract myUni
{
    uint256 a;
}
contract myTest
{
    bytes public myByte;
    bytes32 public mySalt;
    address public pair2;
    function PCreate() public   
    {
        address pair;
        bytes memory bytecode = type(myUni).creationCode;        
        myByte=bytecode;
        address token0=0xa418f4566Ef6b65423d3DE9e05689414AeD66Ea1;
        address token1=0xc778417E063141139Fce010982780140Aa0cD5Ab;
         bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        mySalt=salt;
         assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        pair2=pair;
    }
}