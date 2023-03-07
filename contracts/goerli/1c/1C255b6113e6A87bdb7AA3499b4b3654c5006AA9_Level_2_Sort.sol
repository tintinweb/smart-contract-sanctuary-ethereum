// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface Isolution2 {
    function solution(uint256[10] calldata unsortedArray) external returns (uint256[10] memory sortedArray);
}


contract Level_2_Sort {

    function rand(uint256 n) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % n;
    }

  function sort(uint[10] memory data) internal returns(uint[10] memory) {
       quickSort(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSort(uint[10] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }


    
    // do it in two parts. one tst solutuon other tests gas. 
    function completeLevel(address studentContract) public returns(uint8, uint256) {
        Isolution2 Solution = Isolution2(studentContract);
        uint256[10] memory constantTimeArray = [uint256(99), 4, 7, 1, 8, 14, 1, 90, 3, 55];
        uint256 preGas = gasleft();
        Solution.solution(constantTimeArray);
        uint256 gas = preGas - gasleft();
        uint256[10] memory unsorted = [rand(70),rand(18),rand(25),rand(5),rand(50),rand(49),rand(100),rand(47),rand(45),rand(10)];
        uint256[10] memory solution = Solution.solution(unsorted);
        uint256[10] memory answer = sort(unsorted);
        uint8 score =3;
        for(uint i=0; i<10; i++) {
                if (answer[i] != solution[i]) {
                    score = 1;
                    break;
                } else {
                    score = 5;
                }
            }
        return (score, gas);
    }   
}