/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RandomGeneration {

    uint256 public totalStakers;
    mapping(uint256 => mapping(uint256 => bool)) is_mandator;
    uint256[] public selectedIndexes;
    mapping(uint256 =>  uint256)nextaddress;
    uint256 counter;
    uint256 firstNumber;
    uint256 secondNumber;

    uint256 public uniqueAddress;
    constructor () {
        setConfiguration( 1000, 232325353,21253546454);
    }

    function setConfiguration(
        uint256 _totalStakers,
        uint256 firstRandom,
        uint256 secondRandom
    ) public {
        totalStakers = _totalStakers;
        firstNumber = firstRandom;
        secondNumber = secondRandom;
    }

    function generateRandom(uint256 users ) public {
        _generateRandom( users, firstNumber, secondNumber);
    }

    function _generateRandom( 
        uint256 users, 
        uint256 one, 
        uint256 two
    ) internal {

        uint256 _totalUsers = totalStakers;
        uint256 value = two;
        uint[] memory random = new uint[](users);
        for(uint256 i = 0; i < users ;) {

            value = uint(keccak256(abi.encodePacked(one, value))) % _totalUsers;
            random[i] = value;
            i++; 
        }
        counter++;
        selectedIndexes = random;
    }

    function selectUsers() public {
        
        uint256 usersToSelect = selectedIndexes.length;
        uint256 i = 0;
        uint256[] memory user = new uint256[](usersToSelect);
        uint256 index;
        uint arrayIterator = 0;
        while( i < usersToSelect ) {
            index = selectedIndexes[i];

            if(!is_mandator[counter][index]) {
                is_mandator[counter][index] = true;
                user[arrayIterator] = index;
                arrayIterator++;
            }
            i++;
        }
        uniqueAddress = arrayIterator;
    }
}