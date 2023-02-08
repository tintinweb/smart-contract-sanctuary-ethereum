// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract C00L {

    function sorrow() public pure returns(string memory){
        assembly{
            mstore(0x20,0x20)
            mstore(0x4c,0x0ce788b1e4b88ae5b182e6a5bc)
            return(0x20,0x60)
        }
    }

}