/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Keyboards {
    enum KeyboardKind {
        SixtyPercent,
        SeventFivePercent,
        EightyPercent,
        Iso105
    }
    struct Keyboard {
        KeyboardKind kind;
        bool isPBT; //BAS = false, PBT = true
        string filter; //tailwind filters to layer over
    }

    Keyboard[] public createdKeyboards;

    function getKeyboards() view public returns(Keyboard[] memory) {
        return createdKeyboards;
    }

    function create(KeyboardKind _kind, bool _isPBT, string calldata _filter) external {
        Keyboard memory newKeyboard = Keyboard({
            kind : _kind,
            isPBT : _isPBT,
            filter : _filter
        });
        createdKeyboards.push(newKeyboard);
    }
}