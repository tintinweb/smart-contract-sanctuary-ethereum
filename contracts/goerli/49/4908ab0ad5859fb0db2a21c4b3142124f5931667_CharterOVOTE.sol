// SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity 0.8.10;
pragma solidity ^0.6.11;

import './verifier.sol';


// Charter-OAV (OnchainAnonymousVoting) contract.
// Fork from https://github.com/aragonzkresearch/ovote/tree/main/contracts
// WARNING: This code is WIP, in early stages.
/// @title charterovote
/// @author Aragon  
contract CharterOVOTE {
	Verifier    verifier;

	struct Process {
		address creator; // the sender of the tx that created the process
		uint256 censusRoot;
		uint256 charterHash;
		uint256 result;
		mapping(uint256 => bool) nullifiers;
	}

	uint256 public lastProcessID; // initialized at 0
	mapping(uint256 => Process) public processes;


	// Events used to synchronize the ovote-node when scanning the blocks

	event EventProcessCreated(address creator, uint256 id, uint256 censusRoot, uint256 charterHash);

	event EventVote(address publisher, uint256 id, uint256
				   votevalue, uint64 weight);

	constructor( address _verifierContractAddr) public {
		verifier = Verifier(_verifierContractAddr);
	}


	/// @notice stores a new Process into the processes mapping
	/// @param censusRoot MerkleRoot of the CensusTree used for the process, which will be used to verify the zkSNARK proofs of the results
	/// @param charterHash Number of leaves in the CensusTree used for the process
	/// @return id assigned to the created process
	function newProcess(
		uint256 censusRoot,
		uint256 charterHash
		// Note: this method has been simplifyied, it would include the
		// txHash of the tx to be executed once the voting process
		// finishes, and other parameters such as the block at which
		// starts, window of blocks where voters can vote, etc.
	) public returns (uint256) {
		processes[lastProcessID +1] = Process(msg.sender,
				censusRoot, charterHash, 0);

		// assume that we use solidity versiont >=0.8, which prevents
		// overflow with normal addition
		lastProcessID += 1;

		emit EventProcessCreated(msg.sender, lastProcessID, censusRoot,
					 charterHash);

		return lastProcessID;
	}

	/// @notice validates the proposed result during the results-publishing
	/// phase, and if it is valid, it stores it for the process id
	/// @param id Process id
	/// @param nullifier wip
	/// @param votevalue wip
	/// @param weight wip
	// /// @param a Groth16 proof G1 point
	// /// @param b Groth16 proof G2 point
	// /// @param c Groth16 proof G1 point
	function vote(uint256 id,
		uint256 nullifier,
		uint64 votevalue,
		uint64 weight,
		uint[2] memory a, uint[2][2] memory b, uint[2] memory c
        ) public {
		// check that id has a process
		require(id<=lastProcessID, "process id does not exist");

		Process storage process = processes[id];

		// check that the nullifier has not been already used
		require(!process.nullifiers[nullifier], "nullifier already used");
		// store the nullifier
		process.nullifiers[nullifier] = true;

		// build inputs array (using Process parameters from processes mapping)
		uint256[7] memory inputs = [
			5, // chainid (5 for GoerliETH)
			id,
			process.censusRoot,
			weight,
			nullifier,
			votevalue,
			process.charterHash
		];
		// call zk snark verification here when ready
		require(verifier.verifyProof(a, b, c, inputs), "zkProof vote could not be verified");

		process.result += votevalue;

		emit EventVote(msg.sender, id, votevalue, weight);
	}
}