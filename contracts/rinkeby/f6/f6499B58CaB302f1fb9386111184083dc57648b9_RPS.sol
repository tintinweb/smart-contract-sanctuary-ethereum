/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// rock - 1
// paper - 2
// scissors - 3
// won - 1
// lost - 2
// tie - 3
contract RPS {
    int256 private _lastPlayed;
    int256 private _outcome;

    event newMessage(address indexed from, int256 hand, int256 outcome);

    function play(int256 hand) public returns (bool) {
        if (_lastPlayed == 0) _outcome = 3;
        else if (hand == _lastPlayed) _outcome = 3;
        else if (hand - _lastPlayed == 1) _outcome = 1;
        else if (hand - _lastPlayed == -1) _outcome = 2;
        else if (hand - _lastPlayed == -2) _outcome = 1;
        else if (hand - _lastPlayed == 2) _outcome = 2;
        _lastPlayed = hand;
        emit newMessage(msg.sender, hand, _outcome);
        return true;
    }

    function getMessage() public view returns (int256 outcome) {
        outcome = _outcome;
    }
}