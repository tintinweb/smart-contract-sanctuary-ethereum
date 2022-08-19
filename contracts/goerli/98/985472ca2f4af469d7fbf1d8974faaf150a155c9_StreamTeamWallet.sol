// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io ~ Credits: Moneypipe.xyz <3 Funds sharing is a concept brought to life by them
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./TeamWalletLibrary.sol";

contract StreamTeamWallet is Initializable, ReentrancyGuard {
    TeamWalletLibrary.Payee[] private _team;
    uint256 public totalReceived;
    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    error TransferFailed();

    function initialize(TeamWalletLibrary.Payee[] calldata team, bytes32 _root) initializer public {
        root = _root;
        for (uint i = 0; i < team.length; i++) {
            _team.push(team[i]);
        }
    }

    receive() external payable {
        totalReceived += msg.value;
        for (uint i = 0; i < _team.length; i++) {
            TeamWalletLibrary.Payee memory payee = _team[i];
            payee.totalWithdrawn += (msg.value / 100) * payee.shares;
            _transfer(payee.walletAddress, (msg.value / 100) * payee.shares);
        }
    }

    function SaveOurAces(bytes32[] calldata proof) external callerIsUser {
        require(ValidateProof(proof), "Not authorized");
        uint256 balance = address(this).balance;
        for (uint i = 0; i < _team.length; i++) {
            TeamWalletLibrary.Payee memory payee = _team[i];
            payee.totalWithdrawn += (balance / 100) * payee.shares;
            _transfer(payee.walletAddress, (balance / 100) * payee.shares);
        }
    }

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }

    function ValidateProof(bytes32[] calldata merkleProof)
    internal
    view
    returns (bool)
    {
        return
        MerkleProof.verify(
            merkleProof,
            root,
            keccak256(abi.encodePacked(msg.sender))
        );
    }
}