// SPDX-License-Identifier: UNLICENSED
interface IPseudoGenerator {
    function generatePassword(uint256 _seed) external returns(uint256 _password);
}

pragma solidity ^0.8.13;

contract UnverifiedRandomness {
    event CrackedSuccessfully(address);
    error F();
    error SmallNumbersAreBoring(); 

    IPseudoGenerator public pseudoGenerator;

    constructor(IPseudoGenerator _pseudoGenerator) {
        pseudoGenerator = _pseudoGenerator;
    }

    function canYouUnlockMe(uint256 _password, uint256 _seed) external {
        if (_seed < 111111111111111111111) revert SmallNumbersAreBoring();
        uint256 _truePassword = pseudoGenerator.generatePassword(_seed);
        if (_password != _truePassword) revert F();
        emit CrackedSuccessfully(msg.sender);
    }
}