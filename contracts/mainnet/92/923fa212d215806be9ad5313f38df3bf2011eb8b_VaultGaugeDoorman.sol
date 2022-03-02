/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVF {
    function deployVault(address) external returns(address);
}
interface IVIM {
    function initializeVault(address) external;
}
interface IVoter {
    function whitelistAsAuth(address) external;
    function createGauge(address) external returns(address);
}
contract VaultGaugeDoorman {

    address immutable self;

    modifier ensureDelegateCall() {
        require(address(this) != self);
        _;
    }

    constructor() {
        self = address(this);
    }
    //must be delegate called
    function deployAndInitAsAuth(
        address underlying,
        address vf,
        address vim,
        address voter
    ) ensureDelegateCall external {
        address newVault = address(IVF(vf).deployVault(underlying));
        IVIM(vim).initializeVault(newVault);
        IVoter(voter).whitelistAsAuth(newVault);
        IVoter(voter).createGauge(newVault);
    }
}