/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

pragma solidity ^0.4.21;

contract guessnumber{
    bytes32 answer = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
    function hashguess() public returns (uint8){
        for (uint8 i = 0; i < 2^8; i++){
            if (keccak256(i) == answer){
                return i;
        }
    }
    }
    
}