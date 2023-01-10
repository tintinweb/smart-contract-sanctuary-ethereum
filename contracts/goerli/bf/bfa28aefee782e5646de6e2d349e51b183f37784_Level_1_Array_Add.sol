// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface Isolution {
    function solution(uint256 [2] calldata firstArray, uint256 [2] calldata secondArray) external returns (uint256 [2] calldata finalArray);
}


contract Level_1_Array_Add {

    function rand(uint256 n) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % n;
    }

    function completeLevel(address studentContract) public payable returns (uint8){
        uint256 startGas = gasleft();
        Isolution Solution = Isolution(studentContract);
        uint256 [2] memory firstArray = [rand(10), rand(10)];
        uint256 [2] memory secondArray = [rand(10), rand(10)];
        uint256 [2] memory answer = [(firstArray[0]+ secondArray[0]), (firstArray[1]+ secondArray[1])];
        uint256 [2] memory solution = Solution.solution(firstArray, secondArray);(firstArray, secondArray);
        require(solution[0] == answer[0] && solution[1] == answer[1]);
        return uint8(2); 
    }	
}