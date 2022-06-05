/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    uint256[] public selectedIndexes;
    uint256 public counter;
    mapping(uint256 => uint256) public stakerId;
    mapping(uint256 => mapping(uint256 => bool)) is_mandator;
    uint256 public randomThreshold;
    bool public isGenerationStarted;
    uint256[] public allNumber;
    uint256 firstNumber;
    uint256 secondNumber;

    constructor() {

    }

    function resetCondition(
        uint256 _counter, 
        uint256 _randomThreshold, 
        uint256 firstrandom, 
        uint256 secondrandom
    ) public {
        counter = _counter;
        // for(uint256 i=1; i<=counter; i++){
        //     stakerId[i] = i;
        //     is_mandator[0][i] = false;
        // }
        randomThreshold = _randomThreshold;
        uint256[] memory blankArray;
        allNumber = blankArray;
        selectedIndexes = blankArray;
        firstNumber = firstrandom;
        secondNumber = secondrandom;
    }
    function allNumberLength() public view returns(uint256){
        return allNumber.length;
    }
    function selectedIndexesLength() public view returns(uint256){
        return selectedIndexes.length;
    }

    function randomSelectUsers(uint16 numberOfUsers) external {
        _randomSelectUsers(
            numberOfUsers,
            firstNumber,
            secondNumber
        );
    }

    function _randomSelectUsers(
        uint256 numberOfUsers,
        uint256 one,
        uint256 two
    ) internal {
        uint256 _totalUsers = counter;

        uint256 tmpNumber = selectedIndexes.length;
        uint256 i = tmpNumber;
        uint256 value = two;
        numberOfUsers +=tmpNumber;
        while( i < numberOfUsers && selectedIndexes.length < randomThreshold ) {
            value =
                uint256(keccak256(abi.encodePacked(one, value))) %
                _totalUsers;
            if (
                !is_mandator[0][value] &&
                value <= counter
            ) {
                is_mandator[0][value] = true;
                selectedIndexes.push(value+1);
                i += 1;
            }
        }
        secondNumber = value;

        if(selectedIndexes.length == randomThreshold){
            isGenerationStarted = false;
        }
    }

    // function _randomSelectUsers(
    //     uint16 numberOfUsers,
    //     uint256 one,
    //     uint256 two
    // ) internal {
    //     uint256 _totalUsers = counter;
    //     uint256 tmpNumber = selectedIndexes.length;
    //     uint256 i = tmpNumber;
    //     uint256 value = two;
    //     while (i < (tmpNumber+numberOfUsers) && selectedIndexes.length < randomThreshold) {
    //         value =
    //             uint256(keccak256(abi.encodePacked(one,address(this), value))) %
    //             _totalUsers;
    //         allNumber.push(value);
    //         if (
    //             !is_mandator[0][value] &&
    //             stakerId[value] != 0
    //         ) {
    //             is_mandator[0][value] = true;
    //             selectedIndexes.push(value+1);
    //             i += 1;
    //         }
    //     }
    //     if(selectedIndexes.length == randomThreshold){
    //         isGenerationStarted = false;
    //     }
    // }
}