//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVoterData.sol";

contract Voting {

    struct Candidate {
        uint candidateId;
        uint votes;
    }

    struct Detail {
        uint duration;
        Candidate[] candidates;
        uint startTime;
        uint roomId;
    }

    struct History {
        uint votingId;
        uint candidateId;
    }

    uint votingCount = 1;
    IERC20 ballotInterface;
    IVoterData voterDataInterface;
    mapping(uint => Detail) public votingDetails;
    mapping(address => uint) public voterToCandidate;
    mapping(uint => address[]) public candidateToVoter;
    mapping(address => bool) public voterVerified;

    function setInterface(address _ballotToken, address _voterData) public {
        ballotInterface = IERC20(_ballotToken);
        voterDataInterface = IVoterData(_voterData);
    }

    function startSession(uint _votingId, uint _duration) public{
        Detail storage details = votingDetails[_votingId];
        details.duration = _duration;
        details.startTime = block.timestamp;
    }

    function createVoting(uint _duration, uint _startTime, uint _roomId, uint[] calldata _candidates) public{
        Detail storage details = votingDetails[votingCount];
        details.duration = _duration;
        for(uint i; i < _candidates.length; i++) {
            details.candidates.push(Candidate(_candidates[i], 0));
        }
        details.startTime = (_startTime * 1 hours) + block.timestamp;
        details.roomId = _roomId;
        votingCount ++;
    }

    function vote(uint _votingId, address _voter, uint _candidate) public {
        Detail storage details = votingDetails[_votingId];
        uint duration = details.startTime + (details.duration * 1 hours);
        require(voterVerified[_voter] == true, "You are not verified");
        require(voterToCandidate[_voter] == 0, "You already voted to one of the candidates");
        // require(details.startTime < block.timestamp, "Voting session has not started");
        // require(duration > block.timestamp, "Duration of the voting session is over");
        uint index = getCandidateIndex(_votingId, _candidate);
        ballotInterface.approve(_voter, 1);
        ballotInterface.transfer(address(this), 1);
        Candidate[] storage  candidates= votingDetails[_votingId].candidates;
        candidates[index].votes = candidates[index].votes + 1;
        voterToCandidate[_voter] = _candidate;

        candidateToVoter[_candidate].push(_voter);
    }


    function getCandidateIndex(uint _votingId, uint _candidate) internal view returns(uint) {
        uint index;
        Candidate[] memory  candidates= votingDetails[_votingId].candidates;
        for(uint i; i < candidates.length; i++) {
            if(candidates[i].candidateId == _candidate) {
                index = i;
            }
        }
        
        return index;   
    }

    function getCandidates(uint _votingId) public view returns(Candidate[] memory) {
        Candidate[] memory  candidates= votingDetails[_votingId].candidates;
        return candidates;
    }

    function verifyVoter(uint _votingId, bytes32[] calldata proof, bytes32 leaf) public {
        bool verified = voterDataInterface.verify(_votingId, proof, leaf);
        require(verified == true, "You are not a verified voter");
        voterVerified[msg.sender] = true;
        ballotInterface.approve(address(this), 1);
        ballotInterface.transferFrom(address (this), msg.sender, 1);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./VoterDataMerkle.sol";
interface IVoterData {
    function verify(uint _votingId, bytes32[] calldata proof, bytes32 leaf) external view returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract VoterDataMerkle {
    uint rootId;
    mapping(uint => bytes32) public votingToRoot;

    function setRoot(bytes32 _root) public {
        votingToRoot[rootId] = _root;
        rootId ++;
    }
    
    function verify(uint _votingId, bytes32[] calldata proof, bytes32 leaf) public view returns(bool){
        bytes32 root = votingToRoot[_votingId];
        return MerkleProof.verify(proof, root, leaf);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}