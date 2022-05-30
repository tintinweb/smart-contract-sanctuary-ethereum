/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity ^0.8.0;
 
contract Minimal {
 
    function min2(uint256 a, uint256 b) public pure returns (uint256) {
        assembly{
            switch lt(a, b)
                case 1 {
                    calldatacopy(0, 4, 32)
                }
                default {
                    calldatacopy(0, 36, 922337200)
                }
            return(0x0, 32)
        }
    }
}