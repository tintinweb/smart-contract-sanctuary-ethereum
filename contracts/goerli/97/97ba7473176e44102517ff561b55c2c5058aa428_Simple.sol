/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title Simple
 * @dev Simple contract example
 * @custom:dev-run-script simple.sol
 */
contract Simple {
    string public message = "hoge2";
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}