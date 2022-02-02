/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract FunTypes {
    uint256 _tokenId;
    bool _didPublicMintStart; //Did the drop happen yet? 
    uint myUnsignedInteger = 100;
    uint x = 5 ** 2;
    uint y = 10 / 2;

    struct Person {
        uint age;
        string name;
    }

    // Array with a fixed length of 2 elements:
uint[2] fixedArray;
// another fixed Array, can contain 5 strings:
string[5] stringArray;
// a dynamic Array - has no fixed size, can keep growing:
uint[] dynamicArray;

Person[] public people; // dynamic Array, we can keep adding to it

// create a New Person:
Person satoshi = Person(172, "Satoshi");

address payable z;

enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }

    ActionChoices choice;
    ActionChoices constant defaultChoice = ActionChoices.GoStraight;

    function setGoStraight() public {
        choice = ActionChoices.GoStraight;
    }

uint[] numbers;

function _addToArray(uint _number) private {
  numbers.push(_number);
}

}