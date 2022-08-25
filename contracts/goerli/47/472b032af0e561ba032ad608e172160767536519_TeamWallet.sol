// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io ~ Credits: Moneypipe.xyz <3 Funds sharing is a concept brought to life by them

pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./TeamWalletLibrary.sol";

contract TeamWallet is Initializable {
    mapping(address => TeamWalletLibrary.Payee) internal teamArchive;
    address[] internal index;
    uint256 public totalReceived;

    function initialize(TeamWalletLibrary.Payee[] calldata team) initializer public {
        for (uint i = 0; i < team.length; i++) {
            teamArchive[team[i].walletAddress] = team[i];
            index.push(team[i].walletAddress);
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    error TransferFailed();

    function getTeamInfo(address member) external view returns (TeamWalletLibrary.Payee memory){
        return teamArchive[member];
    }

    receive() external payable {
        totalReceived += msg.value;
        for (uint i = 0; i < index.length; i++) {
            teamArchive[index[i]].totalEarned += (msg.value / 100) * teamArchive[index[i]].shares;
            _transfer(index[i], (msg.value / 100) * teamArchive[index[i]].shares);
        }
    }

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}