/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Smart1 {

    string private word;

    function setWord(string memory newWord) public {
        word = newWord;
    }

    function getWord() public view returns (string memory){
        return word;
    }
}