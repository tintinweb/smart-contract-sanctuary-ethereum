// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AccessControl {
address[] public authorizedCallers;

function authorizeCaller(address _caller) public {
    authorizedCallers.push(_caller);
}

function onlyAuthorized() internal view returns (bool) {
    return authorizedCallers.length == 0 || authorizedCallers[authorizedCallers.length - 1] == msg.sender;
}

function isAuthorized(address _caller) public view returns (bool) {
    for (uint i = 0; i < authorizedCallers.length; i++) {
    if (authorizedCallers[i] == _caller) {
return true;
}
}
return false;
}
}