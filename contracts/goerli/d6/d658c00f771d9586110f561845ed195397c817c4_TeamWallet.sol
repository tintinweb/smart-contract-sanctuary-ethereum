// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io ~ Credits: Moneypipe.xyz <3 Funds sharing is a concept brought to life by them
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract TeamWallet is Initializable, ReentrancyGuard {
    mapping(address => uint256) public totalWithdrawn;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public availablePerBeneficiary;
    address[] internal beneficiaries;
    uint256 public totalReceived;
    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function initialize(bytes32 _root, address[] calldata _beneficiaries, uint256[] calldata _shares) initializer public {
        root = _root;
        beneficiaries = _beneficiaries;
        for (uint i = 0; i < beneficiaries.length; i++) {
            shares[beneficiaries[i]] = _shares[i];
        }
    }

    receive() external payable {
        totalReceived += msg.value;
        for (uint i = 0; i < beneficiaries.length; i++) {
            availablePerBeneficiary[beneficiaries[i]] += (msg.value / 100) * shares[beneficiaries[i]];
        }
    }

    function withdraw(bytes32[] calldata proof) external callerIsUser nonReentrant {
        require(ValidateProof(proof), "Not authorized");
        totalWithdrawn[msg.sender] += availablePerBeneficiary[msg.sender];
        _transfer(msg.sender, availablePerBeneficiary[msg.sender]);
        availablePerBeneficiary[msg.sender] = 0;
    }

    error TransferFailed();

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