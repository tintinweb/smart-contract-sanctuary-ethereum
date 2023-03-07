// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
interface Isolution4 {
    function solution(uint256 value) external;
}
*/

contract Assessment_2 {

    function rand(uint256 n) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % n;
    }


    function completeLevel(address studentAddress) public returns(uint8, uint256) {

        uint256 sudoRandomNumber = rand(10000);
        uint256  slot;

        uint256 preGas = gasleft();
        studentAddress.delegatecall(abi.encodeWithSignature("solution(uint256)", sudoRandomNumber));
        uint256 gas = preGas - gasleft();
        
        assembly { slot := sload(3) }
        
        if (slot == sudoRandomNumber) {
            return (3, gas);
        } else {
            return (1, gas);  
        }
    }    
}