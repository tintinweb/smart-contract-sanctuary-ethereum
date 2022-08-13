/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: UNLICENSED
interface IPseudoGenerator {
    function unknown0d8b674d(uint256 _userValue) external returns (uint256 _pw1);
}

pragma solidity ^0.8.13;

contract UnverifiedRandomness {
    uint256 private constant _version = 1;
    event CrackedSuccessfully(address, uint256);
    error F();
    error SmallNumbersAreBoring();
    error NotYourTeamAccount();

    IPseudoGenerator public pseudoGenerator;

    address private immutable _your_team_account;

    constructor(IPseudoGenerator _pseudoGenerator) payable {
        pseudoGenerator = _pseudoGenerator;
        _your_team_account = msg.sender;
    }

    function canYouUnlockMe(uint256 _password, uint256 _seed) external {
        if (msg.sender != _your_team_account) revert NotYourTeamAccount();
        if (_seed < 111111111111111111111) revert SmallNumbersAreBoring();
        uint256 _pw1 = pseudoGenerator.unknown0d8b674d(_seed);
        if (_pw1 != _password) revert F();
        emit CrackedSuccessfully(msg.sender, _pw1 << 20);
        payable(msg.sender).transfer(address(this).balance);
    }
}