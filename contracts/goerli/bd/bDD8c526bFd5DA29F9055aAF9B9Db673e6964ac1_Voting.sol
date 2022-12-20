// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Candidate {
        uint candidateId;
        bytes32 name;
        uint votes;
        
    }

    struct sectionDetail {
        bytes32 title;
        uint duration;
        uint startTime;
        uint roomId;
        Candidate[] candidates;
        address proposer;
    }

    struct sessionHistory {
        address voter;
        uint candidateId;
        uint timeStamp;
    }
    
    uint public sectionIndex = 1;
    mapping (uint => uint) public roomIdToSectionIndex;
    mapping(uint => sectionDetail) public votingDetails;
    mapping(uint => sessionHistory[]) public votingHistory;

    function createVoting(bytes32 _title, uint _duration, uint _startTime, uint _roomId, bytes32[] calldata _candidates) external onlyOwner{
        sectionDetail storage details = votingDetails[sectionIndex];
        details.title = _title;
        details.duration = _duration;
        details.startTime = (_startTime * 1 hours) + block.timestamp;
        details.roomId = _roomId;

        for(uint i; i < _candidates.length; ++i) {
            details.candidates.push(Candidate(i + 1, _candidates[i], 0));
        }
        details.proposer = msg.sender;

        roomIdToSectionIndex[_roomId] = sectionIndex;
        sectionIndex ++;
    }

    function vote(address _voter, uint _candidateId, uint _roomId) public {
        uint _sectionIndex = roomIdToSectionIndex[_roomId];
        sectionDetail storage details = votingDetails[_sectionIndex];
        
        // --- verify the voter and vote session ----
        //bool verified = checkVerifiedVoter(_roomId, _voter);
        bool validate = checkVoterVote(_sectionIndex, _voter);
        uint SessionDuration = details.startTime + (details.duration * 1 hours);

        //require(verified == true , "You are not a verified voter");
        require(validate == false , "You already voted");
        require(details.startTime < block.timestamp, "Voting hasn't started yet");
        require(SessionDuration > block.timestamp, "Voting Session is over");

        //---- vote for the choosen candidates ----
        uint index = getCandidateIndex(_sectionIndex, _candidateId);
        Candidate[] storage  candidates= votingDetails[_sectionIndex].candidates;
        candidates[index].votes = candidates[index].votes + 1;

        //---- store and update the result to voting and voter history ----
        votingHistory[_sectionIndex].push(sessionHistory(_voter, _candidateId, block.timestamp));
    }

    function checkVoterVote(uint _sectionIndex, address _voter) public view returns(bool) {
        bool result;

        sessionHistory[] memory votes = votingHistory[_sectionIndex];
        for(uint i; i < votes.length; i++){
            if(votes[i].voter == _voter){
                result = true;
            } else {
                result = false;
            }
        }
        return result;
    }
    
    //--------------- get function --------------------

    function getCandidateIndex(uint _sectionIndex, uint _candidate) internal view returns(uint) {
        uint index;
        Candidate[] memory  candidates= votingDetails[_sectionIndex].candidates;
        for(uint i; i < candidates.length; ++i) {
            if(candidates[i].candidateId == _candidate) {
                index = i;
            }
        }
        
        return index;   
    }

     function getCandidates(uint _roomId) public view returns(Candidate[] memory) {
        uint _sectionIndex = roomIdToSectionIndex[_roomId];
        Candidate[] memory  candidates = votingDetails[_sectionIndex].candidates;
        return candidates;
    }

    function getSecDetail(uint256 _roomId) external view returns (sectionDetail memory) {
    uint _sectionIndex = roomIdToSectionIndex[_roomId];
    return votingDetails[_sectionIndex]; 
    }

    function getVotingHistory(uint _roomId) public view returns(sessionHistory[] memory) {
        uint _sectionIndex = roomIdToSectionIndex[_roomId];
        sessionHistory[] memory history = votingHistory[_sectionIndex];
        return history;
    }

}