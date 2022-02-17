/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    event Address(address indexed user, address to, address[] indexed users, address[] tos);
    event Number(uint128 indexed amount, uint128 balance, uint128[] indexed amounts, uint128[] balances);
    event String(string indexed text, string message, string[] indexed texts, string[] messages);
    event Boolean(bool indexed isTrue, bool isFalse, bool[] indexed isTrues, bool[] isFalses);

    function EmitAddress(address _user, address[] calldata _users) public {
        emit Address(_user, _user, _users, _users);
    }

    function EmitNumber(uint128 _amount, uint128[] calldata _amounts) public {
        emit Number(_amount, _amount, _amounts, _amounts);
    }

    function EmitString(string calldata _text, string[] calldata _texts) public {
        emit String(_text, _text, _texts, _texts);
    }

    function EmitBoolean(bool _isTrue, bool[] calldata _isTrues) public {
        emit Boolean(_isTrue, _isTrue, _isTrues, _isTrues);
    }
}