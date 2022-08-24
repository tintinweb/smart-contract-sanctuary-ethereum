// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io ~ Credits: Moneypipe.xyz <3 Funds sharing is a concept brought to life by them

pragma solidity ^0.8.15;

import "./Clones.sol";
import "./StreamTeamWallet.sol";

contract Laboratory {
    event TeamWalledDeployed(address indexed WalletContract);

    address public immutable implementation;
    constructor() {
        implementation = address(new StreamTeamWallet());
    }

    function NewStreamWallet(TeamWalletLibrary.Payee[] calldata team) external returns (address) {
        require(team.length < 100, "Too Many Beneficiaries");
        address payable clone = payable(Clones.clone(implementation));
        StreamTeamWallet teamWallet = StreamTeamWallet(clone);
        teamWallet.initialize(team);
        emit TeamWalledDeployed(clone);
        return clone;
    }
}