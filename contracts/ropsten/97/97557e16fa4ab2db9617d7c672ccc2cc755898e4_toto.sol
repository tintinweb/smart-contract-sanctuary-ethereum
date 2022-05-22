/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.7;


contract toto {

    function result( bytes memory input) public returns(address){
            return address(uint160(uint256(keccak256(input))));
        }
}