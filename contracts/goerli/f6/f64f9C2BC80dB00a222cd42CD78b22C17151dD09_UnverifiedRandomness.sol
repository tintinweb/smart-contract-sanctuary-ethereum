// SPDX-License-Identifier: UNLICENSED

import {IUnverifiedRandomness} from '../interfaces/IUnverifiedRandomness.sol';
import {IPseudoGenerator} from '../interfaces/IPseudoGenerator.sol';

pragma solidity ^0.8.13;

contract UnverifiedRandomness is IUnverifiedRandomness {
    mapping(address => uint256) private userValues;
    IPseudoGenerator public magicGenerator;

    constructor(IPseudoGenerator _magicGenerator) {
        magicGenerator = _magicGenerator;
    }

    function callMeFirst(uint256 _value) external {
        if (_value == 0) revert ZeroIsBoring();
        userValues[msg.sender] = _value;
    }

    function canYouUnlockMe(uint256 _password) external {
        uint256 _userValue = userValues[msg.sender];
        if (_userValue == 0) revert CallMeFirst();
        uint256 _truePassword = magicGenerator.generatePassword(_userValue);
        if (_password != _truePassword) revert F();
        emit CrackedSuccessfully(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IPseudoGenerator} from './IPseudoGenerator.sol';
interface IUnverifiedRandomness {
    error F();
    error ZeroIsBoring();
    error CallMeFirst();

    event CrackedSuccessfully(address);
    
    function magicGenerator() external view returns(IPseudoGenerator _pseudoGenerator);

    function callMeFirst(uint256 _value) external;

    function canYouUnlockMe(uint256 _password) external;
}

interface IPseudoGenerator {
    function generatePassword(uint256 _userValue) external returns (uint256 _password);
}