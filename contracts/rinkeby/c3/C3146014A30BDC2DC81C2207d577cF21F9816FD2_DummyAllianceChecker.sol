//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DummyAllianceChecker {
    function canDisband(uint256 _allianceId) pure external returns(bool) {
        require(_allianceId >= 0, "bad alliance id");
        return true;
    }
}