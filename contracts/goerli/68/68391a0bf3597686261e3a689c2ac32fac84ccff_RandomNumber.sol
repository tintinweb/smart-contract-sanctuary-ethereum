/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT

/*
 * Per generare un numero semi-casuale in Solidity,
 * sfrutterò la keccak256()funzione hash, 
 * che trasforma un input in un numero esadecimale a 256 bit.
 */

pragma solidity 0.8.17;

contract RandomNumber {
    
    function _generateRandomNumber(uint256 _number) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % _number;
    }

    function Play(uint256 _num) public view returns(string memory) {
        if(_generateRandomNumber(_num) == 77) return "Win";
        return "try again";
        
    }
}