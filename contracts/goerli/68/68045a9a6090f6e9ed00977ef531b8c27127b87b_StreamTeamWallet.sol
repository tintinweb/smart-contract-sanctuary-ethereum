// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io ~ Credits: Moneypipe.xyz <3 Funds sharing is a concept brought to life by them
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract StreamTeamWallet is Initializable, ReentrancyGuard {
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public shares;
    address[] internal beneficiaries;
    uint256 public totalReceived;
    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    error TransferFailed();

    function initialize(address[] calldata _beneficiaries, uint256[] calldata _shares, bytes32 _root) initializer public {
        root = _root;
        beneficiaries = _beneficiaries;
        for (uint i = 0; i < beneficiaries.length; i++) {
            shares[beneficiaries[i]] = _shares[i];
        }
    }

    receive() external payable {
        totalReceived += msg.value;
        withdraw(msg.value);
    }

    function SaveOurAces(bytes32[] calldata proof) external callerIsUser {
        require(ValidateProof(proof), "Not authorized");
        withdraw(0);
    }

    function withdraw(uint256 transactionValue) internal nonReentrant {
        uint256 balance = address(this).balance + transactionValue;
        for (uint i = 0; i < beneficiaries.length; i++) {
            // Take 1 wei out of everyone's transfer to safeguard the contract to get out
            // of funds in the last transfer due to rounding
            totalWithdrawn[beneficiaries[i]] += ((balance / 100) * shares[beneficiaries[i]]) - 1;
            _transfer(beneficiaries[i], ((balance / 100) * shares[beneficiaries[i]]) - 1);
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