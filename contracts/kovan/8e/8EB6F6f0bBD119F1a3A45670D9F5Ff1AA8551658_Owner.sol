/**
 *Submitted for verification at Etherscan.io on 2022-06-03
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

    constructor() {

    }

    function resetCondition(uint256 _counter, uint256 _randomThreshold) public{
        counter = _counter;
        for(uint256 i=1; i<=counter; i++){
            stakerId[i] = i;
        }
        randomThreshold = _randomThreshold;
        uint256[] memory blankArray;
        selectedIndexes = blankArray;
    }

    function randomSelectUsers(uint16 numberOfUsers, uint256 firstNumber, uint256 second) external {
        _randomSelectUsers(
            numberOfUsers,
            firstNumber,
            second
        );
    }
    function _randomSelectUsers(
        uint16 numberOfUsers,
        uint256 one,
        uint256 two
    ) internal {
        uint256 _totalUsers = counter;
        uint256 i = selectedIndexes.length;
        uint256 value = two;
        while (i < (selectedIndexes.length+numberOfUsers) && selectedIndexes.length < randomThreshold) {
            value =
                uint256(keccak256(abi.encodePacked(one, value))) %
                _totalUsers;
            if (
                !is_mandator[0][value] &&
                stakerId[value] != 0
            ) {
                is_mandator[0][value] = true;
                selectedIndexes.push(value+1);
                i += 1;
            }
        }
        if(selectedIndexes.length == randomThreshold){
            isGenerationStarted = false;
        }
    }
}