// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice imported contracts from openzepplin to pause, verify proof and upgrade contract
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @author Wande for Team Unicorn
/// @title ZuriElection
/// @notice You can use this contract for election amongst known stakeholders
/// @dev All function calls are currently implemented without side effects
contract ZuriElection is Pausable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(bytes32 merkleRoot) {
        chairman = msg.sender;
        Active = false;
        Ended = false;
        Created = false;
        candidatesCount = 0;
        root = merkleRoot;
        publicState = false;
    }

    /// =================== VARIABLES ================================

    ///@notice address of chairman
    address public chairman;

    ///@notice name of the position candidates are vying for
    string public position;

    ///@notice description of position vying for
    string public description;

    ///@dev root of the MerkleTree
    bytes32 public root;

    ///@notice count of candidates
    ///@dev count to keep track of number of candidates
    uint256 public candidatesCount;
    ///@notice variable to track number of election held
    uint256 electionCount;
    ///@notice variable to track time
    uint256 public startTimer;
    ///@dev mapping of address for teachers
    ///@notice list of teachers
    mapping(address => bool) public teachers;

    ///@notice list of stakeholders that have voted
    ///@dev mapping of address to bool to keep track of votes
    mapping(address => bool) public voted;

    ///@notice list of candidates
    ///@dev mapping to unsigned integers to struct of candidates
    mapping(uint256 => Candidate) public candidates;

    ///@notice variable to track winning candidate
    ///@dev an array that returns id of winning candidate(s)
    uint256 public winnerId;

    ///@notice variable to track winning candidate
    ///@dev an array that returns id of winning candidate(s)
    mapping(uint256 => Election) public winners;

    

    ///@notice count of vote of winning id
    ///@dev variable to track to vote count of items in winnerids array
    uint256 public winnerVoteCount;

    ///@notice boolean to track status of election
    bool public Active;
    ///@notice boolean to track status of election
    bool public Ended;

    ///@notice boolean to track if election has been created
    bool public Created;

    ///@notice boolean to keep track of whether result should be public or not
    bool internal publicState;

    ///@dev struct of candidates with variables to track name , id and voteCount
    struct Candidate {
        uint256 id;
        string name;
        string candidateHash;
        string candidateManifesto;
        uint256 voteCount;
    }

    struct Election {
        string position;
        string description;
        Candidate winner;
    }

    
    ///================== PUBLIC FUNCTIONS =============================

    function getCandidates() public view  returns (Candidate[] memory) {
        Candidate[] memory contestants = new Candidate[] (candidatesCount);
        for(uint i=0; i < candidatesCount; i++){
            Candidate storage candidate = candidates[i];
            contestants[i] = candidate;

        }
        return contestants;
    }

    ///@notice function that allows stakeholders vote in an election
    ///@param _candidateId the ID of the candidate and hexProof of the voting address
    ///@dev function verifies proof
    function vote(uint256 _candidateId)
        public
        electionIsStillOn
        electionIsActive
    {
        // require(
        //     isValid(hexProof, keccak256(abi.encodePacked(msg.sender))),
        //     "sorry, only stakeholders are eligible to vote"
        // );

        _vote(_candidateId, msg.sender);
    }

    /// @notice function to start an election
    ///@param _prop which is an array of election information
    function setUpElection(string[] memory _prop)
        public
        whenNotPaused
    {
        require(!Active, "Election is Ongoing");
        require(_prop.length > 0, "atleast one person should contest");
        require(
            chairman == msg.sender || teachers[msg.sender] == true,
            "only teachers/chairman can call this function"
        );
        

        position = _prop[0];
        description = _prop[1];
        Created = true;
        electionCount++;
    }

    function makeResultPublic()
        public
    {
        require(Ended, "Sorry, the Election has not ended");
        require(
            chairman == msg.sender || teachers[msg.sender] == true,
            "only teachers/chairman can make results public"
        );
        publicState = true;
    }

    function getWinner() public view  returns (uint256, uint256){
        require(publicState, "The Results must be made public");
        return (winnerVoteCount, winnerId);
    }

    function getWinners() public view returns (Election[] memory){
         Election[] memory elections = new Election[] (electionCount);
        for(uint i=0; i < electionCount; i++){
            Election storage winner = winners[i];
            elections[i] = winner;

        }
        return elections;
    }

    

    /// ==================== INTERNAL FUNCTIONS ================================
    ///@notice internal function that allows users vote
    ///@param _candidateId and voter's address

    function _vote(uint256 _candidateId, address _voter)
        internal
        whenNotPaused
        onlyValidCandidate(_candidateId)
    {
        require(!voted[_voter], "Voter has already Voted!");
        voted[_voter] = true;
        candidates[_candidateId].voteCount++;

        emit VoteForCandidate(_candidateId, candidates[_candidateId].voteCount);
    }

    ///@notice internal function to add candidate to election
    ///@param _name of candidate
    ///@dev function creates a struct of candidates
    function addCandidate(string memory _name, string memory _candidateHash, string memory _candidateManifesto) public whenNotPaused {
        require(!Active, "Election is Ongoing");
        require(
            chairman == msg.sender || teachers[msg.sender] == true,
            "only teachers/chairman can call this function"
        );
        candidates[candidatesCount] = Candidate({
            id: candidatesCount,
            name: _name,
            candidateHash : _candidateHash,
            candidateManifesto : _candidateManifesto,
            voteCount: 0
        });
        emit CandidateCreated(candidatesCount, _name);
        candidatesCount++;
    }

    ///@notice internal function that calculates the election winner
    ///@return vote count and winning ID
    function _calcElectionWinner()
        internal
        whenNotPaused
        returns (uint256, uint256)
    {
        
        for (uint256 i; i < candidatesCount; i++) {
            ///@notice this handles the winner vote count
            if (candidates[i].voteCount >= winnerVoteCount) {
                winnerVoteCount = candidates[i].voteCount;
                winnerId = candidates[i].id;
            }
        }


        winners[electionCount] = Election({
            position: position,
            description : description,
            winner: candidates[winnerId]
        });
        return (winnerVoteCount, winnerId);

    }

    /// @notice function to start election
    ///@dev function changes the boolean value of the ACTIVE variable
    function startElection() public whenNotPaused onlyChairman {
        Active = true;
    }

    /// @notice function to end election
    ///@dev function changes the boolean value of the ENDED variable
    function endElection() public whenNotPaused onlyChairman {
        Ended = true;
        _calcElectionWinner();
        emit ElectionEnded(winnerId, winnerVoteCount);
    }

    ///@notice function to verify stakeholders
    ///@return it returns a boolean value
    ///@dev function verifies the MerkleProof of the user and asserts that they are stakeholders
    ///@param proof and leaf
    function isValid(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    ///@notice function to add teachers to mapping
    ///@param _newTeacher is the address of a new teacher
    function addTeacher(address _newTeacher) public whenNotPaused {
        require(
            chairman == msg.sender || teachers[msg.sender] == true,
            "only teachers/chairman can call this function"
        );
        teachers[_newTeacher] = true;
    }

    ///@notice function to add teachers to mapping
    ///@param _teacher is the address of teacher to be removed
    function removeTeacher(address _teacher) public whenNotPaused {
        require(
            chairman == msg.sender || teachers[msg.sender] == true,
            "only teachers/chairman can call this function"
        );
        teachers[_teacher] = false;
    }

    ///@notice function to pause the contract
    function pause() public onlyChairman {
        _pause();

        emit Paused(_msgSender());
    }

    ///@notice function to unpause the contract
    function unpause() public onlyChairman {
        _unpause();
        emit Unpaused(_msgSender());
    }

    ///@notice function to change chairman
    /// @param  _newChairman is the new chairman
    function changeChairman(address _newChairman)
        public
        whenNotPaused
        onlyChairman
    {
        chairman = _newChairman;
    }

    ///@notice function to close the election
    function closeElection() public onlyChairman{
        Created = false;
         chairman = msg.sender;
        Active = false;
        Ended = false;
        Created = false;
        candidatesCount = 0;
        publicState = false;
        winnerVoteCount = 0;
    }

    ///@notice to check If election has been created
    function isCreated() public view returns(bool){
        return Created;
    }

    ///@notice function to check if election has been started
    function isStarted() public view returns (bool){
        return Active;
    }

    ///@notice function to check if election has been ended
    function isEnded() public view returns (bool){
        return Ended;
    }

    ///@notice function to check if addr is chairman
    function isChairman() public view  returns (bool){
        return chairman == msg.sender;
    }

    ///@notice function to check if election has been started
    function isTeacher() public view  returns (bool){
        return teachers[msg.sender];
    }


    /// ======================= MODIFIERS =================================
    ///@notice modifier to specify only the chairman can call the function
    modifier onlyChairman() {
        require(msg.sender == chairman, "only chairman can call this function");
        _;
    }

    ///@notice modifier to specify that election has not ended
    modifier electionIsStillOn() {
        require(!Ended, "Sorry, the Election has ended!");
        _;
    }
    ///@notice modifier to check that election is active
    modifier electionIsActive() {
        require(Active, "Please check back, the election has not started!");
        _;
    }

    
    ///@notice modifier to ensure only specified candidate ID are voted for
    ///@param _candidateId of candidates
    modifier onlyValidCandidate(uint256 _candidateId) {
        require(
            _candidateId < candidatesCount && _candidateId >= 0,
            "Invalid candidate to Vote!"
        );
        _;
    }

    ///======================= EVENTS & ERRORS ==============================
    ///@notice event to emit when the contract is unpaused
    event ElectionEnded(uint256 _winnerId, uint256 _winnerVoteCount);
    ///@notice event to emit when candidate has been created
    event CandidateCreated(uint256 _candidateId, string _candidateName);
    ///@notice event to emit when a candidate us voted for
    event VoteForCandidate(uint256 _candidateId, uint256 _candidateVoteCount);

    ///@notice error message to be caught when conditions aren't fufilled
    error ElectionNotStarted();
    error ElectionHasEnded();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}