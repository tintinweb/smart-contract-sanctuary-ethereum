// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Daughter.sol";

contract MomContract {
 string public name;
 uint public age;

 DaughterContract public daughter;

    constructor(
        string memory _momsName, uint _momsAge
    )
    {
        name = _momsName;
        age = _momsAge;
    }

    function createChild (string memory _daughtersName, uint _daughtersAge) public {
        daughter = new DaughterContract(_daughtersName, _daughtersAge);
    }
}