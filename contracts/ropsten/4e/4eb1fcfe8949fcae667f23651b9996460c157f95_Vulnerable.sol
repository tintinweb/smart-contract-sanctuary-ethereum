/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

pragma solidity ^0.8.7;

contract Vulnerable { 
    function example() external pure returns (bytes memory) {
        bytes10 x = 0xa2646970667358221220;
        bytes16 y = 0x62f1517052fdb79a290bf48281e91cfb;
        bytes25 z = 0x0ac6230cb457b51aa15e05e66663b7fd64736f6c6343000807;

        return abi.encodePacked(x, y, z);
    }
}