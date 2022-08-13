// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Box1 {
    uint public votes;
    function init(uint _votes) external {
        votes = _votes;
    }
}