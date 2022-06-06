/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RandomNumberGenerator {

    uint256[] public selectedIndexes;
    uint256 public counter;
    mapping(uint256 => uint256) public stakerId;
    mapping(uint256 => mapping(uint256 => bool)) is_mandator;
    uint256 public randomThreshold;
    bool public isGenerationStarted;
    uint256[] public allNumber;
    uint256 public _firstNumber;
    uint256 public value;

    constructor() {

    }

    function resetCondition(uint256 _counter, uint256 _randomThreshold, uint256 firstNumber, uint256 second) external{
        addUsers(0, _counter);
        randomThreshold = _randomThreshold;
        uint256[] memory blankArray;
        allNumber = blankArray;
        selectedIndexes = blankArray;
        _firstNumber = firstNumber;
        value = second;
    }
    function updateRandomNumber(uint256 firstNumber, uint256 second) external{
        _firstNumber = firstNumber;
        value = second;
    }
    function addUsers(uint256 startIndex,uint256 endIndex) public {
        for(uint256 i=startIndex; i<=endIndex; i++){
            stakerId[i] = i;
            is_mandator[0][i] = false;
        }
        counter = endIndex;
    }
    
    function selectedIndexesLength() public view returns(uint256){
        return selectedIndexes.length;
    }

    function _randomSelectUsersForLoop(uint256 loopCount) external {
        for(uint256 i=0; i< loopCount; i++){
            value =
                uint256(keccak256(abi.encodePacked(_firstNumber, value)));
            uint256 tmpValue = value % counter;
            uint256 reps = value % 10;
            uint256 gap = uint256(keccak256(abi.encodePacked(_firstNumber, reps)))%10;
            for (uint256 j = 0; j< reps; j++){
            if (
                !is_mandator[0][tmpValue] &&
                stakerId[tmpValue] != 0 &&
                selectedIndexes.length < randomThreshold &&
                tmpValue < counter
            ) {
                is_mandator[0][tmpValue] = true;
                selectedIndexes.push(tmpValue);
            }
            tmpValue = tmpValue + gap;
            }

        }
        if(selectedIndexes.length == randomThreshold){
            isGenerationStarted = false;
        }
    }
}