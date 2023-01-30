/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

pragma solidity ^0.8.17;


contract Multicaller {

    function aggregate() external view  returns(bytes32 result){
        assembly{
            result := blockhash(number())
        }
    }

    function aggregate1() external view  returns(bytes32 result){
        result = blockhash(block.number);
    }

}